# Define variables

$XAservers = $citrix_environment.cdc_6.XENAPP_SERVERS
$XAservers += $citrix_environment.cdc_76.XENAPP_SERVERS

# Get event logs from list of servers

$Results = $null

$Results += Invoke-Command -ComputerName $XAServers -ScriptBlock{
    $YDate = (Get-Date).AddDays(-1)
    $TDate = (Get-Date)
    $Events += Get-EventLog -LogName Application -Source "Application Error" -After $YDate -Before $TDate -EntryType Error -ErrorAction SilentlyContinue #| Where {$_.Message -match "cpsvc.exe"}

    <#
    $Events += Get-EventLog -LogName System -Source IMAService -After $YDate -Before $TDate -EntryType Warning -ErrorAction SilentlyContinue
    $Events += Get-EventLog -LogName System -Source IMAService -After $YDate -Before $TDate -EntryType Error -ErrorAction SilentlyContinue
    $Events += Get-EventLog -LogName System -Source CitrixHealthMon -After $YDate -Before $TDate -EntryType Warning -ErrorAction SilentlyContinue
    $Events += Get-EventLog -LogName System -Source CitrixHealthMon -After $YDate -Before $TDate -EntryType Error -ErrorAction SilentlyContinue
    $Events += Get-EventLog -LogName System -Source Metaframe -After $YDate -Before $TDate -EntryType Warning -ErrorAction SilentlyContinue
    $Events += Get-EventLog -LogName System -Source Metaframe -After $YDate -Before $TDate -EntryType Error -ErrorAction SilentlyContinue
    #>
    return $Events
}
$Results | sort pscomputername