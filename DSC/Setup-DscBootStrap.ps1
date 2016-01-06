<#
.SYNOPSIS 
 
 This script is used to remotely configure a system for a specific environment and server type based on pre-created LCM schema MOF configurations. 
 The assumption is that a system is already on a domain, has remote PowerShell enabled, CredSSP enabled, etc.
 The initial vision of this script was to maintain a quick/easy way to bootstrap new DSC nodes by installing a common shared certificate for
 securing PSCredential objects, copying the LCM MOF, configuring the LCM, and starting the DSC engine.
 

.EXAMPLE
 
 .\Setup-LocalConfigurationManager.ps1 -Computers WebServer01 -Environment UAT -ServerType -WebServer -StartDscConfiguration

 The StartDscConfiguration variable is set, which means the Consistency scheduled task will be run immediately after the LCM is configured
 and any configurations specific to that system and environment type will be immediately applied to the system.
 

.TODO
 - Add pre-flight checks that make sure Posh is > 4.0, certificate is installed and remote execution enabled.

 - Allow passing certificate information (for shared model)

 - Figure out a way to pass individual certs per machine, probably will be in a separate script.
    - either by using self-signed ones created on the node or from active directory (pki)
    # http://serverfault.com/questions/632390/protecting-credentials-in-desired-state-configuration-using-certificates
#>

param(
    [System.String[]] $ComputerName,
    [System.String][ValidateSet("Production","UAT","Development","Test","QA")] $Environment,
    [System.String][ValidateSet("CitrixServer","SharePointServer","ApplicationServer","dotNetFarm","WebServer")] $ServerType,
    [System.String]$DscCertificatePass = $null,
    [Switch] $StartDscConfiguration
)

Import-Module (Join-Path $ENV:POWERSHELL_HOME "\DSC\DSC_Functions.ps1")
Import-Module (Join-Path $ENV:POWERSHELL_HOME "\Libraries\General_Variables.psm1")

$SharedCertificateRemotePath = $dsc_environment.SharedCertificate.RemotePath
$SharedCertificateLocalPath = $dsc_environment.SharedCertificate.StorePath
$SharedCertificateThumbprint = $dsc_environment.SharedCertificate.Thumbprint

# This script assumes we're using a private certificate to share with all PCs using DSC.
# An alternative would be to create a self-signed certificate locally, copying/importing to the system authoring the MOF
# and securing it with the copied certificate. This is something I'll be doing later on as it requires a significant amount of code changes.

if($DscCertificatePass -eq $null)
{ $DscCertificatePass = Read-Host "Enter the passphrase for the DSCCredentialCertificate_Private.cer.pfx file:" }
$SecurePfxPass = $DscCertificatePass | ConvertTo-SecureString -AsPlainText -Force
$DscCertificatePass = Get-Random -SetSeed (Get-Random) # Null out the unsecure string later to lessen the chance of secure strings in memory.

# Get credentials so we don't need to request it for every foreach in the script.

$Credentials = Get-Credential -UserName ($env:USERDOMAIN + "\" +$env:USERNAME) -Message "Please enter administrative credentials:"



######### Pre-flight checks! ##########

foreach($Computer in $ComputerName){

    $ValidComputers = @()

    # Check remote access to the system, enable if needed.

    $RemoteResult = Test-RemoteExecution -ComputerName $Computer -Enable

    # Check if the shared certificate is installed, install if missing.

    $CertResult = Test-DscSharedCertificate -ComputerName $Computer -Thumbprint $SharedCertificateThumbprint

    foreach($Cert in $CertResult | Where-Object {$_.CertificateInstalled -eq $False}){

        $CertificateParams =@{
            ComputerName = $Cert.ComputerName
            CertificateRemotePath = $SharedCertificateRemotePath
            PfxPass = $DscCertificatePass
            Credentials = $Credentials
        }
        Install-DscSharedCertificate @CertificateParams
    }

    # Check powershell 4.0 or greater
    $PSVersions = Get-PowerShellVersion -ComputerName $ComputerName

}





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

<#
# Not used just yet!
configuration Localhost
{
    LocalConfigurationManager
    {
        AllowModuleOverwrite = $true
        CertificateID = $ThumbPrint;
        ConfigurationID = $Guid
        RefreshMode = "PULL";
        DownloadManagerName = "WebDownloadManager";
        RebootNodeIfNeeded = $false;
        RefreshFrequencyMins = 30;
        ConfigurationModeFrequencyMins = 30;
        ConfigurationMode = "ApplyAndAutoCorrect";
        DownloadManagerCustomData = @{ServerUrl = "http://$PullServer/DSC/PSDSCPullServer.svc"; AllowUnsecureConnection = "FALSE"}
    }
}
#>