<#
.SYNOPSIS 
 
 This script is used to perform initial configuration for a server to download and install the DSC private certificate, LCM and configure the LCM accordingly.
 Select the appropriate Environment and ServerType from the set of options. Updates to the script are required if additional options are required.
 StartDSCConfiguration can be toggled to True or False to immediately enable the DSC configuration by intiating the Consistency scheduled task.

 This script must be run directly on the server in which you want DSC to be configured on. Use Setup-LocalConfigurationManager if the system is already configured.

.EXAMPLE
 
 .\Start-cConfiguration.ps1 -Environment Test -ServerType ApplicationServer -StartDSCConfiguration True

 In this example DSC will be configured for an application server, and it will be assigned to the Test environment group. 
 The StartDSCConfiguration variable is True, which means the Consistency scheduled task will be run immediately after the LCM is configured.

#>
param(
    [ValidateSet("Production","UAT","Development","QA","Test")] $Environment,
    [ValidateSet("CitrixServer","SharePointServer","ApplicationServer","WebServer","dotNetFarm")] $ServerType,
    [ValidateSet($True,$False)] $StartDSCConfiguration = $False
)

Import-Module (Join-Path $env:PowerShell_Home "\Libraries\General_Variables.psm1") # Used to source the PullServer variable.

Set-Variable -Name CertPath -Value $dsc_environment.PullServer.CertificatePath
Set-Variable -Name ModulesPath -Value $dsc_environment.PullServer.ModulesPath
Set-Variable -Name ConfigurationPath -Value $dsc_environment.PullServer.ConfigurationPath

# Prompt for the user account to download the certificate and LCM files.
$Credentials = Get-Credential -Message "Enter your user ID:"

# Prompt for the private certificate password.
$PfxPass = Read-Host "Enter the DSC Certificate passphrase:" -AsSecureString

# Create mapped drive and copy Pfx file to C:\DSC
Write-Host "Copying DSCCredentialCertificate_Private from $CertPath to C:\DSC\"
New-PSDrive -Name P -PSProvider FileSystem -Root $CertPath -Credential $Credentials

$DSCPath = Test-Path C:\DSC
if($DSCPath -eq $False)
{
    New-Item -Path C:\DSC -ItemType Directory -Force
}
$CertificatePath = "C:\DSC\DSCCredentialCertificate_Private.cer.pfx"
Copy-Item -Path "P:\DSCCredentialCertificate_Private.cer.pfx" -Destination $CertificatePath

# Import the Pfx Certificate
Write-Host "Installing certificate to $env:COMPUTERNAME\$StoreLocation\$StoreName"
try{
    # Use the new Import-PfxCertificate cmdlet (only works on Windows 8 or Server 2012).
    Import-PfxCertificate -FilePath $CertificatePath -CertStoreLocation Cert:\LocalMachine\My -Password $PfxPass -Confirm 
}
catch
{
    # If Import-PfxCertificate fails, try the .NET class method
    $StoreName = 'My'
    $StoreLocation= 'LocalMachine'

    $CertificateObject = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
    $CertificateObject.Import($CertificatePath,$PfxPass)

    Write-Host "Installing certificate to $env:COMPUTERNAME\$StoreLocation\$StoreName"

    $CertStore  = New-Object System.Security.Cryptography.X509Certificates.X509Store($StoreName,$StoreLocation)
    $CertStore.Open('MaxAllowed')
    $CertStore.Add($CertificateObject)
}

$Source = ("P:\LCMConfigurations\" + $ServerType + "_" + $Environment + "\" + "localhost.meta.mof")
$Destination = "C:\DSC\LCM\localhost.meta.mof"

Write-Host "Copying LCM file to C:\DSC\LCM."

# Check to make sure the LCM folder exists, create if not.
$LCMPath = Test-Path C:\DSC\LCM
if($LCMPath -eq $False)
{
    New-Item -Path C:\DSC\LCM -ItemType Directory -Force
}
Copy-Item -Path $Source -Destination $Destination -Recurse

# Set the LCM to use the localhost.meta.mof file.
Set-DscLocalConfigurationManager -ComputerName localhost -Path C:\DSC\LCM\ -Verbose

# Manually execute the Consistency scheduled task.
if($StartDSCConfiguration -eq $True)
{
    schtasks /run /TN "Microsoft\Windows\Desired State Configuration\Consistency"
}

# Cleanup
Remove-PSDrive -Name P
Remove-Item C:\DSC -Force -Confirm -Recurse