<#
.SYNOPSIS 
 
 This script is used to remotely configure a system for a specific environment and server type based on pre-created LCM schema MOF configurations. This script is
 used with the assumption that a system is already on a domain, has remote PowerShell enabled, CredSSP enabled, and other considerations.

 Use this script to add existing systems to DSC. Do not use this script for a system that has not undergone previous automations to configure an AppOps system.

.EXAMPLE
 
 .\Setup-LocalConfigurationManager.ps1 -Computers NetServer01 -Environment UAT -ServerType -WebServer -StartDscConfiguration True

 In this example DSC will be configured for a UAT web server.

 The StartDscConfiguration variable is True, which means the Consistency scheduled task will be run immediately after the LCM is configured
 and any configurations specific to that system and environment type will be immediately applied to the system.
 
#>
param(
    $Computers,
    [ValidateSet("Production","UAT","Development","Test","QA")] $Environment,
    [ValidateSet("CitrixServer","SharePointServer","ApplicationServer","dotNetFarm","WebServer")] $ServerType,
    $DscCertificatePass = $null,
    [ValidateSet($True,$False)] $StartDscConfiguration = $False    
    )

$Credentials = Get-Credential -UserName ($env:USERDOMAIN + "\" +$env:USERNAME) -Message "Please enter administrative credentials:"

if($DscCertificatePass -eq $null)
{
    # This script assumes we're using a private certificate to share with all PCs using DSC
    $DscCertificatePass = Read-Host "Enter the passphrase for the DSCCredentialCertificate_Private.cer.pfx file:"
}

Invoke-Command -ComputerName $Computers -Authentication Credssp -Credential $Credentials -ArgumentList $Environment,$ServerType,$DscCertificatePass,$StartDSCConfiguration -ScriptBlock{
    param(
        $Environment,
        $ServerType,
        $DscCertificatePass,
        $StartDSCConfiguration
    )

    $CertificateThumbprint = "" # Add the Thumbprint of the private certificate here
    $SecurePfxPass = ConvertTo-SecureString $DscCertificatePass -AsPlainText -Force
    $Cert = "" # Add the location of the Pfx file here
    
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