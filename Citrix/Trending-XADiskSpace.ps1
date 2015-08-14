Import-Module (Join-Path $env:POWERSHELL_HOME "Libraries\General_Functions.psm1")
Import-Module (Join-Path $env:POWERSHELL_HOME "Libraries\General_Variables.psm1")
Import-Module (Join-Path $env:POWERSHELL_HOME "Libraries\SharePoint_Functions.ps1")
Import-Module (Join-Path $env:POWERSHELL_HOME "Citrix\Citrix_Functions.ps1")

# Define variables

$Date = Get-Date -Format g
$SharePointUrl = $citrix_environment.Logging.SharePointUrl
$SharePointList = $citrix_environment.Logging.SharePointEventLogList
$XAservers = $citrix_environment.Farm01.XENAPP_SERVERS
$XAservers += $citrix_environment.Farm02.XENAPP_SERVERS

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
    
    WriteTo-SPListViaWebService -url $SharePointUrl -list $SharePointList -Item (Convert-ObjectToHash $Items) -Title $Hash.Title
}