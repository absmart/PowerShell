<#
.SYNOPSIS 
 This script is used to trend Citrix XenApp application usage in the 6.0 and 7.6 Citrix farms in the CDC.
 
 Results:

 This script uploads data directly to the SQL database CitrixLogging on CDC-SPB-P01. SharePoint uses this external content source to list the data on the Citrix Dashboard.

#>

$Domain = "fqdn.tld"

Import-Module (Join-Path $ENV:SCRIPTS_HOME "Citrix\Citrix_Functions.ps1")
Import-Module (Join-Path $ENV:SCRIPTS_HOME "Libraries\Standard_Variables.ps1")

$SQLServer = "SqlServer"
$Database = "CitrixLogging"
$TableName = "SessionProcesses"

$ConnectionString = "Server=$SQLServer;Database=$Database;Integrated Security=True"

$XAServers = $null
$XAServers = $citrix_environment.CDC_6.XENAPP_SERVERS
$XAServers += $citrix_environment.CDC_76.XENAPP_SERVERS

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