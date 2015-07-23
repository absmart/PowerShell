param(
    $Guid,
    $OutFilePath,    
    $CertificateID,
    $PullServer,
    $CopyToPullServer
    )

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
cConfiguration -Output $OutFilePath

If($CopyToPullServer)
{
    Copy-Item -Path .\* -Destination \\$PullServer\LCMConfigurations$ -Recurse -Force
}