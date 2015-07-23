<#
.SYNOPSIS 
 This script is used to trend Citrix XenApp server load in the 6.0 farm in the CDC.
 
 Results:

 This script uploads data directly to the SQL database CitrixLogging on CDC-SPB-P01. SharePoint uses this external content source to list the data on the Citrix Dashboard.

#>

Import-Module (Join-Path $ENV:SCRIPTS_HOME "Citrix\Citrix_Functions.ps1")
Import-Module (Join-Path $ENV:SCRIPTS_HOME "Libraries\Standard_Variables.ps1")

# SQL variables

$SQLServer = "SqlServerName"
$Database = "CitrixLogging"
$TableName = "ServerLoad"

$ConnectionString = "Server=$SQLServer;Database=$Database;Integrated Security=True"

# Create table and add columns

$DataTable = New-Object System.Data.DataTable
$DataTable.Columns.Add("Date") | Out-Null
$DataTable.Columns.Add("CitrixServer") | Out-Null
$DataTable.Columns.Add("ServerLoad") | Out-Null
$DataTable.Columns.Add("ServerLoadPercent") | Out-Null

# Add data to the columns

Get-XAServerLoad -CitrixEnvironment 6.0 | % { 
    $Row = $DataTable.NewRow(); 
    $Row["Date"]=$_.Date;
    $Row["CitrixServer"]=$_.XAServer;
    $Row["ServerLoad"]=$_.ServerLoad;
    $Row["ServerLoadPercent"]=$_.ServerLoadPercent;
    $DataTable.Rows.Add($Row)
}

Get-XAServerLoad -CitrixEnvironment 7.6 | % { 
    $Row = $DataTable.NewRow(); 
    $Row["Date"]=$_.Date;
    $Row["CitrixServer"]=$_.XAServer;
    $Row["ServerLoad"]=$_.ServerLoad;
    $Row["ServerLoadPercent"]=$_.ServerLoadPercent;
    $DataTable.Rows.Add($Row)
}

# Write rows to SQL table

$bulkCopy = [Data.SqlClient.SqlBulkCopy] $ConnectionString
$bulkCopy.DestinationTableName = $TableName
$bulkCopy.WriteToServer($DataTable)

# Clean-up tasks

$bulkCopy.Close()