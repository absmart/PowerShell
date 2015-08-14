param(
    [string] $DomainName,
    [pscredential] $DscFileCredential = (Get-Credential -Message "Enter credentials for the Dsc File Certificate resource:"),
    [string] $OutPath
)

configuration InitialDscConfig
{
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullorEmpty()]
        [PsCredential] $DomainCredential,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullorEmpty()]
        [PsCredential] $CertificatePfxPass
    )

    Import-DscResource -ModuleName xComputerManagement
    Import-DscResource -ModuleName cSSL
    
    if($DomainName -ne $null){

        xComputerManagement DomainJoin
        {
            Name = $DomainName
            DomainName = $DomainName
            Credential = $Credential
        }
    }

    <#
    File DscCertificate
    {
        Ensure = "Present"
        Force = "True"
        SourcePath = "\\CDC-SPB-P01\DSC\DSCCredentialCertificate_Private.cer.pfx"
        DestinationPath = "C:\Certificates\DSCCredentialCertificate_Private.cer.pfx"
        Type = "File"
        Credential = $DscFileCredential
    }

    cSSL DscCertificate
    {
        Ensure = "Present"
        Name = "DSC Credential Certificate"
        Password = $CertificatePfxPass
        Path = "C:\Certificates\DSCCredentialCertificate_Private.cer.pfx"
        Subject = "DSC Credential Certificate"
        Root = "LocalMachine"
        Store = "My"
        DependsOn = "[File]DscCertificate"
    }
    #>
}

$PfxPass = (Get-Credential -Message "Enter the Pfx Certificate password for `$CertificatePfxPass:")
InitialDscConfig -OutputPath $OutPath -DscFileCredential $DscFileCredential -CertificatePfxPass $PfxPass