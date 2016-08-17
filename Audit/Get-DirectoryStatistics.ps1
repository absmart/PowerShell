param (
	[string] $directory
)

if ( -not ( Test-Path $directory ) ) {
	Write-Host $directory " does not exist"
	return
}

$DirectoryStatistics = @()

Get-ChildItem -Recurse $directory | Where-Object { $_.GetType().Name -eq "DirectoryInfo" }  | % {
	
	$LargeFiles = $nul
	$FullName = $_.FullName
	Write-Progress -Activity "Working on Directory" -Status "Working on $FullName"
	
	$Files = $_.GetFiles()
	
	$Count = $Files.Count
	$Measure = $Files | Measure-Object -Property Length -Maximum -Minimum -Sum
	
	$Large = $Files | Where-Object { $_.Length -gt 52428800 }
	$LargeFileCount = $Large.Count
	$LargeMeasure = $Large | Measure-Object -Property Length -Maximum -Minimum -Sum -Average
	
	$stats = New-Object System.Object 
	$stats | Add-Member -type NoteProperty -Name Directory -Value $FullName
	$stats | Add-Member -type NoteProperty -Name FileCount -Value $Count
	$stats | Add-Member -type NoteProperty -Name MaxFileSize -Value ($Measure.Maximum/1mb)
	$stats | Add-Member -type NoteProperty -Name TotalSize -Value ($Measure.Sum/1mb)
	$stats | Add-Member -type NoteProperty -Name LargeFileCount -Value $LargeFileCount
	$stats | Add-Member -type NoteProperty -Name LargeFileAverageSize -Value ($LargeMeasure.Average/1mb)
	$stats | Add-Member -type NoteProperty -Name LargeFIleTotalSize -Value ($LargeMeasure.Sum/1mb)
	
	
	$DirectoryStatistics += $stats
}

$DirectoryStatistics