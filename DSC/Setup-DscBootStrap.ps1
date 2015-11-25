<#
.SYNOPSIS 
 
 This script is used to remotely configure a system for a specific environment and server type based on pre-created LCM schema MOF configurations. This script is
 used with the assumption that a system is already on a domain, has remote PowerShell enabled, CredSSP enabled, and other considerations.

 Use this script to add existing systems to DSC. Do not use this script for a system that has not undergone previous automations to configure an AppOps system.

.EXAMPLE
 
 .\Setup-LocalConfigurationManager.ps1 -Computers WebServer01 -Environment UAT -ServerType -WebServer -StartDscConfiguration True

 In this example DSC will be configured for a UAT web server.

 The StartDscConfiguration variable is True, which means the Consistency scheduled task will be run immediately after the LCM is configured
 and any configurations specific to that system and environment type will be immediately applied to the system.
 
.TODO
 - Add pre-flight checks that make sure Posh is > 4.0.
 - Allow passing certificate information (for shared model)
 - Figure out a way to pass individual certs per machine
    - either by using self-signed ones created on the node or from active directory (pki)
    # http://serverfault.com/questions/632390/protecting-credentials-in-desired-state-configuration-using-certificates
 
#>
param(
    $Computers,
    [ValidateSet("Production","UAT","Development","Test","QA")] $Environment,
    [ValidateSet("CitrixServer","SharePointServer","ApplicationServer","dotNetFarm","WebServer")] $ServerType,
    $DscCertificatePass = $null,
    [ValidateSet($True,$False)] $StartDscConfiguration = $False    
    )

$Credentials = Get-Credential -UserName ($env:USERDOMAIN + "\" +$env:USERNAME) -Message "Please enter administrative credentials:"

# Get shared certificate password and convert to secure value.
if($DscCertificatePass -eq $null)
{
    # This script assumes we're using a private certificate to share with all PCs using DSC.
    # An alternative would be to create a self-signed certificate locally, copying/importing to the system authoring the MOF
    # and securing it with the copied certificate. This is something I'll be doing later on as it requires individual GUIDs.
    $DscCertificatePass = Read-Host "Enter the passphrase for the DSCCredentialCertificate_Private.cer.pfx file:"
}
$SecurePfxPass = $DscCertificatePass | ConvertTo-SecureString -AsPlainText -Force
$DscCertificatePass = Get-Random -SetSeed (Get-Random) # Null out the unsecure string to lessen the chance of secure strings in memory.

Invoke-Command -ComputerName $Computers -Authentication Credssp -Credential $Credentials -ArgumentList $Environment,$ServerType,$SecurePfxPass,$StartDSCConfiguration -ScriptBlock{
    param(
        $Environment,
        $ServerType,
        $SecurePfxPass,
        $StartDSCConfiguration
    )

    $CertificateThumbprint = "" # Add the Thumbprint of the private certificate here # need to put into splat
    #$SecurePfxPass = ConvertTo-SecureString $DscCertificatePass -AsPlainText -Force # removed 11/25
    $Cert = "" # Add the location of the Pfx file here # go into a plat


    # does this need to be a whole function?
    function Import-PfxCertificate 
    {    
        param(
		    [String] $certPath,
		    [String] $certRootStore = "LocalMachine",
		    [String] $certStore = "My",
		    [object] $pfxPass
        )

	    $pfx = new-object System.Security.Cryptography.X509Certificates.X509Certificate2    

        $pfx.import($certPath,$pfxPass,"PersistKeySet")

 	    $store = new-object System.Security.Cryptography.X509Certificates.X509Store($certStore,$certRootStore)    
 	    $store.open("MaxAllowed")
 	    $store.add($pfx)
 	    $store.close()  
    } 

	Import-PfxCertificate -certpath $cert -pfxPass $SecurePfxPass
    
    $TempFolder = Test-Path C:\temp
    if($TempFolder -eq $false)
    {
        New-Item -Path C:\Temp -ItemType Directory
    }
    
    # Add the location of your meta.mof file here. In this example a hidden administrative share is used to store these.
    $Source = ("\\PullServer\LCMConfigurations$\" + $ServerType + "_" + $Environment + "\" + "localhost.meta.mof")
    $Destination = "C:\temp\localhost.meta.mof"

    Copy-Item -Path $Source -Destination $Destination -Recurse -Container
    
    Set-DscLocalConfigurationManager -ComputerName localhost -Path C:\Temp\ -Verbose
    
    Remove-Item C:\temp\localhost.meta.mof
    
	if($StartDscConfiguration -eq $True)
    {
        try
        {
            # Try the new Update-DscConfiguration command included in WMF 5.0.
            Update-DscConfiguration -Verbose -Wait
        }
        catch
        {
            # Use the old Consistency scheduled task if Update-DscConfiguration does not work
		    schtasks /run /TN "Microsoft\Windows\Desired State Configuration\Consistency"
        }
    }
}