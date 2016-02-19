$AzureASRSites = @(
"hypervrecoverymanager.windowsazure.com"
"accesscontrol.windows.net",
"backup.windowsazure.com",
"blob.core.windows.net",
"store.core.windows.net",
"http://cdn.mysql.com/archives/mysql-5.5/mysql-5.5.37-win32.msi",
"http://www.msftncsi.com/ncsi.txt"
)

foreach($Site in $AzureASRSites)
{
    try{
        Invoke-WebRequest $Site
        Write-Host "$Site - Available!" -ForegroundColor Green
    }
    catch{
        Write-Host "$Site - Unavailable! Site is required for Azure Site Recovery functionality." -ForegroundColor Red
    }
}
