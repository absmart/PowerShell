<#
.SYNOPSIS 
 This script is used to trend filesystem usage of a particular application. Supply the script with a XML config
 with the appropriate information contained.

 Example XML Config:

	<Trending>
		<dst>http://sharepoint.domain.tld/Department/Support/</dst>
		<output_path>D:\LogFiless\ContentGrowth</output_path>
		<content_stores>
			<content_store>\\nas01\share01\</content_store>
			<content_store>\\nas01\share02</content_store>
		</content_stores>
		<stats_file>NAS-Stats.csv</stats_file>
		<files_per_hour>NAS-By-Hour-Stats.csv</files_per_hour>
	</Trending>

 .EXAMPLE
 
 In this example, a test is run interatively via a PowerShell window to return results of usage on a test path.

 .\Trending-UNCShare.ps1 -Config .\Config\trending-rcs.xml
 
 Results:

 There are no results, this guy uploads to SharePoint! Check the XML config for locations of what list in SharePoint that is being updated.
 
#>

param (
    [Parameter(Mandatory=$true)]
        [string] $Config
    )

$XML =  [xml] (Get-Content $Config)

. (Join-Path $env:POWERSHELL_HOME "Libraries\Standard_Functions.ps1")
. (Join-Path $env:POWERSHELL_HOME "Libraries\SharePoint_Functions.ps1")

# SharePoint variables

Set-Variable -option constant -Name Url -Value $XML.Trending.URL
Set-Variable -option constant -Name List -Value $XML.Trending.List
Set-Variable -option constant -Name Title -Value $XML.Trending.Title

# Re-iterate through all ContentStores from XML

foreach($Path in $XML.Trending.ContentStores.ContentStore)
{
    # Define working variables

    $Date = (Get-Date).AddDays(-1)
    $YesterdayDate = $Date.ToString("MM/dd/yyyy")
    $Folders = Get-Item -Path $Path
	$Stats = Get-ChildItem -Path $Folders | Where {$_.LastWriteTime -match $YesterdayDate} | Get-ChildItem -Recurse | Where {$_.LastWriteTime -match $YesterdayDate} | Measure-Object -Property Length -Sum
    
    # Create PSDrive to get more information on non-Windows UNC shares

    $PSDrive = New-PSDrive -Name X -PSProvider FileSystem -Root $Path -Persist
    $TotalStats = Get-PSDrive -Name X

    # Create hashtable to upload to SPList for TotalStats

    $Hash = @{
        Count = $Stats.Count;
        Sum = $Stats.Sum/1MB;
        FreeDiskSpace = $TotalStats.Free/1MB;
        TotalDiskSpace = $TotalStats.Used/1MB;
        Partition = $Path;
        Date = $YesterdayDate
        Title = $Title
        }

    $HashObject = New-Object PSObject -Property $Hash

    $Items = $HashObject | Select Title, Count, Sum, FreeDiskSpace, Date, Partition, TotalDiskSpace

    # Upload information to SPList
    
    WriteTo-SPListViaWebService -url $url -list $list -Item (Convert-ObjectToHash $Items) -title $Title
    
    # Cleanup tasks
    
    Remove-PSDrive -Name X -PSProvider FileSystem -Force
}