param(
    [Parameter(Mandatory=$true)]
    [ValidateScript({Test-Path $_})] 
    [string] $config, 
	[switch] $upload
)

. (Join-Path $ENV:SCRIPTS_HOME "Libraries\Standard_Functions.ps1")
. (Join-Path $ENV:SCRIPTS_HOME "Libraries\SharePoint_Functions.ps1")

$cfg =  [xml] ( Get-Content $config )

Set-Variable -Name db_script -Value (Join-Path $ENV:SCRIPTS_HOME "Database\Get-DatabaseFileSize.ps1" )
Set-Variable -Name yesterday -Value $(Get-Date).AddDays(-1)
Set-Variable -Name large_file_size -Value 50mb
Set-Variable -Name yesterday_stats -Value (New-Object PSObject -Property @{
    Date = $yesterday.ToString("MM/dd/yyyy")
    Name = [string]::Empty
    Count = 0
    AverageSize = 0
    MaximumSize = 0
    TotalSize = 0
    LargeFileCount = 0
    LargeFileAverage = 0
    LargeFileTotalSize = 0
})
0 .. 23 | ForEach -Begin { $hours = @() } -Process { $hours += 0 }

#Get Database File Sizes for all Content Databases in this Farm
&$db_script (Join-Path $cfg.Trending.output_path ("Database-File-Size-" + $yesterday.ToString("yyyyMMdd") + ".csv"))

#Get Stats Per Content Source 
ForEach( $content_store in $cfg.Trending.content_Stores.Content_Store ) {
    $full_name = (Join-Path $content_store $yesterday.ToString("yyyy\\MM\\dd"))

    $directory_files = Get-ChildItem -Recurse $full_name
    $directory_stats = $directory_files | Measure -Property Length -Maximum -Sum -Average
    $large_stats = $directory_files | Where { $_.Length -ge $large_file_size } | Measure -Property Length -Sum -Average
    
    $yesterday_stats.Name += $full_name + ";"
    $yesterday_stats.Count += $directory_stats.Count
    $yesterday_stats.AverageSize += $directory_stats.Average/1mb
    $yesterday_stats.MaximumSize += $directory_stats.Maximum/1mb
    $yesterday_stats.TotalSize += $directory_stats.Sum/1mb
    $yesterday_stats.LargeFileCount += $large_stats.Count
    $yesterday_stats.LargeFileAverage += $large_stats.Average/1mb
    $yesterday_stats.LargeFileTotalSize += $large_stats.Sum/1mb

    $directory_files | Group -Property { $_.CreationTime.Hour } -NoElement | ForEach { $hours[$_.Name] += $_.Count }
}

#Update Statistics File
$yesterday_stats | Select Date, Name, Count, AverageSize, MaximumSize, TotalSize, LargeFileCount, LargeFileAverage, LargeFileTotalSize | 
    ConvertTo-Csv -NoTypeInformation | Select -Skip 1 | Add-Content -Encoding ascii (Join-Path $cfg.Trending.output_path $cfg.Trending.stats_file)

#Update Stats Per Hour File
for( $i=0; $i -le 23; $i++ ) {
    "{0},{1},{2}" -f $yesterday.ToShortDateString(), $i, $hours[$i]  | Add-Content -Encoding ascii (Join-Path $cfg.Trending.output_path $cfg.Trending.files_per_hour)
}

#Upload to SharePoint, if required
if( $upload ) {
	UploadTo-Sharepoint -file (Join-Path $cfg.Trending.output_path $cfg.Trending.stats_file) -lib $cfg.Trending.dst
	UploadTo-Sharepoint -file (Join-Path $cfg.Trending.output_path $cfg.Trending.files_per_hour) -lib $cfg.Trending.dst
}	
