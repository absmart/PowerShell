param(
    $XAServer = "XaServerName",
    $SharePointUrl = "sharepoint.fqdn.tld/sites/Department/",
    $SharePointList = "Citrix - Disk Space"
)

. (Join-Path $env:POWERSHELL_HOME "Libraries\Standard_Functions.ps1")
. (Join-Path $env:POWERSHELL_HOME "Libraries\Standard_Variables.ps1")
. (Join-Path $env:POWERSHELL_HOME "Libraries\SharePoint_Functions.ps1")
. (Join-Path $env:POWERSHELL_HOME "Citrix\Citrix_Functions.ps1")

# Define variables

$Date = Get-Date -Format g
$XAServers += $citrix_environment.CDC_6.XENAPP_SERVERS
$XAServers += $citrix_environment.CDC_76.XENAPP_SERVERS

# Get disk space for all XenApp servers

$Diskspace = $null
$Diskspace = @()

foreach($XAServer in $XAServers)
{
    $Diskspace += Get-XAServerDiskSpace -ComputerName $XAServer -Partition C:\
    $Diskspace += Get-XAServerDiskSpace -ComputerName $XAServer -Partition D:\
}

# Remove drives from the list that do not exist

$Results = $Diskspace | Where {$_.TotalDiskSpace -ne 0}

# Create hashtable to upload to SPList

foreach($Result in $Results)
{
    $Hash = @{
        Date = $Date;
        TotalDiskSpace = $Result.TotalDiskSpace;
        FreeDiskSpace = $Result.FreeDiskSpace;
        Partition = $Result.Partition;
        Server = $Result.Server;
        Title = $Result.Server
    }

    $HashObject = New-Object PSObject -Property $Hash
    $Items = $HashObject | Select Date, TotalDiskSpace, FreeDiskSpace, Partition, Server, Title

    # Upload information to SPList
    
    WriteTo-SPListViaWebService -url $url -list $list -Item (Convert-ObjectToHash $Items) -title $Title
}