param (
	[string] $server,
	[string] $partition,
	[string] $imageName,
	[string] $list = "Trending",
	[string] $view = $null,
	[int] $dataPoints = 30
)

. (Join-Path $ENV:SCRIPTS_HOME "Libraries\Standard_Functions.ps1")
. (Join-Path $ENV:SCRIPTS_HOME "Libraries\SharePoint_Functions.ps1")

Set-Variable -option constant -Name Url -Value "http://teamadmin.gt.com/sites/ApplicationOperations/"
Set-Variable -option constant -Name Library -Value "Pages/Images/"

$title = "{0} - {1} Free Space Trending" -f $server, $partition

$values = @{}
get-SPListViaWebService -list $List -Url $Url -View $view | Select Date, FreeDiskSpace -First $dataPoints | % { $values[$_.Date] = $_.FreeDiskSpace }

UploadTo-Sharepoint ($Url + $Library) (Get-GoogleGraph -ht $values -title $title -file $imageName)
