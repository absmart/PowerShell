
# Create certificate to encrypt and decrypt credentials in the MOF configuration files.


$DnsName = "Dsc Credential Certificate 2"
$PfxPassword = ConvertTo-SecureString -String "SUPERCOMPLEXEPASSWORDHERE" -Force -AsPlainText
$PrivateOutPath = "E:\temp\PrivateDscCertificate.pfx"
$PublicOutPath = "E:\temp\PublicDscCertifiace.pfx"

New-SelfSignedCertificate -DnsName $DnsName -CertStoreLocation Cert:\LocalMachine\my
$Certificate = Get-ChildItem -Path Cert:\LocalMachine\My | Where {$_.Subject -match $DnsName }
Export-PfxCertificate -Cert $Certificate -FilePath $PrivateOutPath -Password $PfxPassword
Export-Certificate -Cert $Certificate -FilePath $PublicOutPath



# Pull Server configuration

Configuration PullServer
{
    param(
        [ValidateNotNullOrEmpty()]
        [string] $CertificateThumbprint
        )
        
    Import-DscResource -ModuleName
}