[CmdletBinding()]
param (

    [String] $DatabaseName = $null,
    $SampleInterval = 1,
    $MaxSamples = 3600,
    $ExportPath = "C:\sql-perfmon-log.csv"
)

$ErrorActionPreference = "Stop"
$VerbosePreference = "Continue"

cls

if($DatabaseName -eq $null){ $DatabaseName = "_Total"; Write-Output "Collecting _Total counter for SQLServer:Databases\Log Bytes Flushed/sec"}
Write-Output "Collecting counters..."
Write-Output "Press Ctrl+C to exit."

$counters = @("\Processor(_Total)\% Processor Time", "\LogicalDisk(C:)\Disk Reads/sec", "\LogicalDisk(C:)\Disk Writes/sec", 
    "\LogicalDisk(C:)\Disk Read Bytes/sec", "\LogicalDisk(C:)\Disk Write Bytes/sec", "\SQLServer:Databases($DatabaseName)\Log Bytes Flushed/sec") 

Get-Counter -Counter $counters -SampleInterval $SampleInterval -MaxSamples $MaxSamples | 
    Export-Counter -FileFormat csv -Path $ExportPath -Force