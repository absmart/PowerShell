# Variables - Change these to your preferences.

$DnsName = "Dsc Credential Certificate"
$PfxPassword = ConvertTo-SecureString -String "SUPERCOMPLEXEPASSWORDHERE" -Force -AsPlainText
$PrivateOutPath = "E:\temp\PrivateDscCertificate.pfx"
$PublicOutPath = "E:\temp\PublicDscCertifiace.pfx"
$DscUserCredentials = Get-Credential -Message "Enter the password desired for the DscUser account." -UserName "DscUser" # Password is defined here as the User resource requires the input var to be a pscredential object.

# IIS Vars
$DscIisPhysPath = "$env:SystemDrive\Web\DscPullServer"

# Create certificate to encrypt and decrypt credentials in the MOF configuration files.
# See https://technet.microsoft.com/en-us/%5Clibrary/Hh848633(v=WPS.630).aspx for more information on the New-SelfSignedCertificate cmdley.

New-SelfSignedCertificate -DnsName $DnsName -CertStoreLocation Cert:\LocalMachine\my # This cmdlet is only included in WMF 5.0 or Windows 2012 R2 / 8.1 WMF 4.0
$Certificate = Get-ChildItem -Path Cert:\LocalMachine\My | Where {$_.Subject -match $DnsName }
Export-PfxCertificate -Cert $Certificate -FilePath $PrivateOutPath -Password $PfxPassword
Export-Certificate -Cert $Certificate -FilePath $PublicOutPath

$CertInfo = Get-PfxCertificate $PublicOutPath

# ConfigurationData

$ConfigData= @{
    AllNodes = @(
        @{
            # The name of the node we are describing (or guid)
            NodeName = $Guid

            # Public certificate file used to encrypt the $Credential variable
            CertificateFile = "\\PullServer\D$\DSC\DSCCredentialCertificate_Public.cer"
                        
            # The thumbprint of the Encryption Certificate used to decrypt the credentials on target node
            Thumbprint = "ABC123" # Thumbprint of DSC Credential Certificate            
        }
    )
}

# Pull Server configuration

Configuration PullServer
{
    param(
        [ValidateNotNullOrEmpty()]
        [string] $CertificateThumbprint
        )
        
    Import-DscResource -ModuleName cSmbShare
    Import-DscResource -ModuleName xPSDesiredStateConfiguration

    Node localhost
    {

        User DscShareAccess
        {
            UserName = "DscUser"
            FullName = "DscUser"
            Description = "This user account is utilized by DSC nodes to access the DSC fileshare on the Pull Server (read-only)."
            Ensure = "Present"
            Disabled = $false
            Password = [PSCredential] $DscUserCredentials
            PasswordChangeNotAllowed = $true
            PasswordNeverExpires = $true
        }

        File DscFolder
        {
            DestinationPath = "D:\DSC"
            Ensure = "Present"
            Type = "Directory"
        }

        cSmbShare DscShare
        {
            Name = "DSC"
            Path = "D:\DSC"
            ReadAccess = "DscUser"
            Ensure = "Present"
            DependsOn = "[File]DscFolder","[User]DscShareAccess"
        }

        WindowsFeature DscFeatures
        {
            Ensure = "Present"
            Name = "Dsc-Service"
        }

        xDscWebService DscPullServer
        {
            Ensure = "Present"
            EndpointName = "DscPullServer"
            Port = "8080"
            PhysicalPath = $DscIisPhysPath
            State = "Started"
            CertificateThumbPrint = $CertificateThumbprint
            ModulePath = "$env:ProgramFiles\WindowsPowerShell\DscService\Modules"
            ConfigurationPath = "$env:ProgramFiles\WindowsPowerShell\DscService\Configuration"
            DependsOn = "[WindowsFeature]DscFeatures"
        }

    }
}