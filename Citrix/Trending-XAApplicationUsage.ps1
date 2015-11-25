<#
.SYNOPSIS 
 
 This script was developed to provide a way to schedule a job (in this example every 5min) to get a list of processes and log their utilization to a SQL database.
 These logs were used to understand and better provide information on the frequency and usage on multiple applications in both 6.0 and 7.6 XenApp farms.
 However, this could script could be used to get utilization on any kind of process as long as remote PowerShell is enabled and the executing account has rights to the remote host.
  
#>

Import-Module (Join-Path $env:POWERSHELL_HOME "Libraries\General_Variables.psm1")

$SQLServer = $citrix_environment.Logging.SQLServer
$Database = $citrix_environment.Logging.Database
$TableName = $citrix_environment.Logging.SessionProcesses

$Domain = $domain_information.Domain01.DomainName

$ConnectionString = "Server=$SQLServer;Database=$Database;Integrated Security=True"

$XAServers = $null
$XAServers = $citrix_environment.Farm01.XENAPP_SERVERS
$XAServers += $citrix_environment.Farm02.XENAPP_SERVERS

$Processes = Invoke-Command -ComputerName $XAServers -ScriptBlock{

    # Define $Procs and exclude processes

    $Procs = Get-WmiObject -Class Win32_Process | Where {$_.ProcessName -ne "csrss.exe" -and
        $_.ProcessName -ne "dwm.exe" -and
        $_.ProcessName -ne "dllhost.exe" -and
        $_.ProcessName -ne "splwow64.exe" -and
        $_.ProcessName -ne "winlogon.exe" -and
        $_.ProcessName -ne "taskhost.exe" -and
        $_.ProcessName -ne "ssonsvr.exe" -and
        $_.ProcessName -ne "taskeng.exe" -and
        $_.ProcessName -ne "LogonUI.exe" -and
        $_.ProcessName -ne "wfshell.exe" -and
        $_.ProcessName -ne "winlogon.exe" -and
        $_.ProcessName -ne "wsmprovhost.exe" -and
        $_.GetOwner().domain -match $Domain}
    
    # Format results

    $DateFormat = 'yyyyMMddHHmmss'
    $Results = $Procs | Select @{Name="Date";Expression={Get-Date -Format s}},     
        @{Name="AccountDisplayName";Expression={($_.getowner().domain + "\" + $_.getowner().user)}},
        @{Name="ProcessName";Expression={$_.Name}},
        @{Name="SessionId";Expression={$_.SessionId}},
        @{Name="ProcessId";Expression={$_.ProcessId}},
        @{Name="ServerName";Expression={$_.__SERVER}},
        @{Name="CreationTime";Expression={ $Date = $_.CreationDate | Select-String -Pattern '.{14}' | % {$_.Matches} | % {$_.Value}; 
            [datetime]::ParseExact($Date, $DateFormat, $null)}},
        @{Name="MemoryUsedInMB";Expression={($_.WorkingSetSize/1mb)}}
            
    return $Results | Where {$_.Date -ne $null}

}

# Create table and add columns

$DataTable = New-Object System.Data.DataTable
$DataTable.Columns.Add("Date") | Out-Null
$DataTable.Columns.Add("AccountDisplayName") | Out-Null
$DataTable.Columns.Add("ProcessName") | Out-Null
$DataTable.Columns.Add("SessionID") | Out-Null
$DataTable.Columns.Add("ProcessID") | Out-Null
$DataTable.Columns.Add("XAServer") | Out-Null
$DataTable.Columns.Add("CreationTime") | Out-Null
$DataTable.Columns.Add("MemoryUsedInMB") | Out-Null

# Add data to the columns

$Processes | % { 
    $Row = $DataTable.NewRow();    
    $Row["Date"]=$_.Date;
    $Row["AccountDisplayName"]=$_.AccountDisplayName;
    $Row["ProcessName"]=$_.ProcessName;
    $Row["SessionID"]=$_.SessionID;
    $Row["ProcessID"]=$_.ProcessId;
    $Row["XAServer"]=$_.ServerName;
    $Row["CreationTime"]=$_.CreationTime;
    $Row["MemoryUsedInMB"]=$_.MemoryUsedInMB;
    $DataTable.Rows.Add($Row)
}

# Write rows to SQL table

$bulkCopy = [Data.SqlClient.SqlBulkCopy] $ConnectionString
$bulkCopy.DestinationTableName = $TableName
$bulkCopy.WriteToServer($DataTable)

# Clean-up tasks

$bulkCopy.Close()