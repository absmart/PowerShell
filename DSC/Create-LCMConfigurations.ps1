param(
    $Guid,
    $OutFilePath,    
    $CertificateID = "aec59442276e898faf63859dd94d2ee5e2d33071",
    $PullServer,
    $CopyToPullServer
    )

Set-Location $env:DSC_HOME\LCMConfigurations

configuration cConfiguration
{
    LocalConfigurationManager
    {
        AllowModuleOverwrite = $true
        CertificateID = $CertificateID; # DSC Credential Certificate
        ConfigurationID = $Guid; # dotNetFarm_UAT GUID
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