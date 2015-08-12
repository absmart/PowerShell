param(
    $XAServer = "XaServerName",
    $SharePointUrl = "sharepoint.fqdn.tld/sites/Department/",
    $SharePointList = "Citrix - Windows Event Logs"
)

. (Join-Path $env:POWERSHELL_HOME "Libraries\Standard_Functions.ps1")
. (Join-Path $env:POWERSHELL_HOME "Libraries\Standard_Variables.ps1")
. (Join-Path $env:POWERSHELL_HOME "Libraries\SharePoint_Functions.ps1")
. (Join-Path $env:POWERSHELL_HOME "Citrix\Citrix_Functions.ps1")

# Define variables

$XAservers = $citrix_environment.cdc_6.XENAPP_SERVERS
$XAservers += $citrix_environment.cdc_76.XENAPP_SERVERS

# Get event logs from list of servers

$Results = $null

$Results += Invoke-Command -ComputerName $XAServers -ScriptBlock{
    $YDate = (Get-Date).AddDays(-1)
    $TDate = (Get-Date)
    $Events += Get-EventLog -LogName System -Source IMAService -After $YDate -Before $TDate -EntryType Warning -ErrorAction SilentlyContinue
    $Events += Get-EventLog -LogName System -Source IMAService -After $YDate -Before $TDate -EntryType Error -ErrorAction SilentlyContinue
    $Events += Get-EventLog -LogName System -Source CitrixHealthMon -After $YDate -Before $TDate -EntryType Warning -ErrorAction SilentlyContinue
    $Events += Get-EventLog -LogName System -Source CitrixHealthMon -After $YDate -Before $TDate -EntryType Error -ErrorAction SilentlyContinue
    $Events += Get-EventLog -LogName System -Source Metaframe -After $YDate -Before $TDate -EntryType Warning -ErrorAction SilentlyContinue
    $Events += Get-EventLog -LogName System -Source Metaframe -After $YDate -Before $TDate -EntryType Error -ErrorAction SilentlyContinue
    return $Events
}

# Iterate through all XAServers to define Hash and upload individual records to the SPList

foreach($XAServer in $XAServers)
{
    $Events = $Results | Where {$_.PSComputerName -eq $XAServer}
    
    foreach($Event in $Events)
    {

        # Create hashtable to upload to SPList for Events
    
        $Hash = @{
            Date = $Event.TimeGenerated;
            Level = $Event.EntryType
            EventID = $Event.EventID
            Source = $Event.Source
            Message = $Event.Message
            Title = $XAServer
        }
    
        $HashObject = New-Object PSObject -Property $Hash
        $Items = $HashObject | Select Date, Level, EventID, Source, Message, Title

        # Upload information to SPList
    
       WriteTo-SPListViaWebService -url $url -list $list -Item (Convert-ObjectToHash $Items) -title $Title
    }
}