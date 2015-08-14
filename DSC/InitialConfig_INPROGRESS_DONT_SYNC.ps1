Set-Location $env:DSC_HOME\LCMConfigurations

configuration cConfiguration
{
    LocalConfigurationManager
    {
        AllowModuleOverwrite = $true
        CertificateID = "aec59442276e898faf63859dd94d2ee5e2d33071"; # DSC Credential Certificate
        ConfigurationID = "9ff9baff-2aeb-4c77-9b9f-9ac6685618ee"; # dotNetFarm_UAT GUID
        RefreshMode = "PULL";
        DownloadManagerName = "WebDownloadManager";
        RebootNodeIfNeeded = $false;
        RefreshFrequencyMins = 15;
        ConfigurationModeFrequencyMins = 30;
        ConfigurationMode = "ApplyAndAutoCorrect";
        DownloadManagerCustomData = @{ServerUrl = "http://$PullServer/DSC/PSDSCPullServer.svc"; AllowUnsecureConnection = "TRUE"}
    }
}
#cConfiguration -Output $OutFilePath
# End LCM Configuration



$ConfigData= @{
    AllNodes = @(
        @{
            # The name of the node we are describing (or guid)
            NodeName = "5c2ffe35-f804-4315-9254-a4e7d1ae3698"

            # Public certificate file used to encrypt the $Credential variable
            CertificateFile = "\\PullServer\D$\DSC\DSCCredentialCertificate_Public.cer"
        }
    )
}

configuration cConfiguration
{
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullorEmpty()]
        [PsCredential] $Credential 
        )
}