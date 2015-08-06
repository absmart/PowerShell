<#
.SYNOPSIS
 This is a PowerShell profile used to import many different modules (custom, for specific apps and more!) automatically when PowerShell is started. 
 Place this file in "%USERPROFILE%\Documents\windowsPowerShell" to have it run on PowerShell startup. Don't forget to have the Scripts folder copied beforehand!
#>

# Join paths for the local SCRIPTS_HOME folder and import the PSM1, PS1 and DLLs.

#dir (Join-PATH $ENV:SCRIPTS_HOME "Libraries") | Where { $_.Name -imatch "\.psm1|\.dll" } | % { Write-Host $(Get-Date) " - Import Module " $_.FullName -foreground green ; Import-Module $_.FullName }

Import-Module (Join-Path $ENV:SCRIPTS_HOME "Citrix\Citrix_Functions.ps1")
dir (Join-PATH $ENV:POWERSHELL_HOME "\Libraries") -filter *.ps1 | % { Write-Host $(Get-Date) " - Sourcing " $_.FullName -foreground green ; . $_.FullName }
dir (Join-PATH $ENV:POWERSHELL_HOME "\Libraries") -filter *.psm1 | % { Write-Host $(Get-Date) " - Sourcing " $_.FullName -foreground green ; . $_.FullName }

$MaximumHistoryCount=1024 
$env:EDITOR = "powershell_ise.exe"

New-Alias -name gh -value Get-History 
New-Alias -name i -value Invoke-History
New-Alias -name ed -value $env:EDITOR

$Nas01 = "NasName01"
$Nas01SharePath = "\\nasname01\share1"

if( (Test-Connection $Nas01) -and (Test-Path $Nas01SharePat) )
{
	Write-Host $(Get-Date) " - Setting up Repo to $Nas01SharePath\Repo" -foreground green
	New-PSdrive -name Repo -psprovider FileSystem -root "$Nas01SharePath\Repo" | Out-Null
	Write-Host $(Get-Date) " - Setting up SharePoint  to $Nas01SharePath\SharePoint" -foreground green
	New-PSdrive -name SharePoint -psprovider FileSystem -root $Nas01SharePath\SharePoint | Out-Null
	Write-Host $(Get-Date) " - Setting up NAS  to $Nas01SharePath\NAS" -foreground green
	New-PSdrive -name NAS -psprovider FileSystem -root "$Nas01SharePath\NAS" | Out-Null
}
# Resizes PowerShell window width.
function Resize-Screen
{
	param (
		[int] $width
	)
	$h = get-host
	$win = $h.ui.rawui.windowsize
	$buf = $h.ui.rawui.buffersize
	$win.width = $width # change to preferred width
	$buf.width = $width
	$h.ui.rawui.set_buffersize($buf)
	$h.ui.rawui.set_windowsize($win)
}
# Loads this file in PowerShell
function Load-Profile
{
    . $profile 
}
# Opens this file in ISE.
function Get-Profile
{
	ed $profile
}

function Add-IISFunctions
{
	$lib = (Join-PATH $ENV:SCRIPTS_HOME "Libraries\IIS_Functions.ps1")
	Write-Host $(Get-Date) " - Sourcing $lib"
	. $lib
}
New-Alias -Name iis -Value Add-IISFunctions

function Remove-TempFolder
{
	Remove-Item -Recurse -Force $ENV:TEMP -ErrorAction SilentlyContinue
}

function Add-Cloud-Modules
{
	Write-Host $(Get-Date) " - Importing Azure Module"
	Push-Location $PWD.Path
	Get-ChildItem 'C:\Program Files (x86)\Microsoft SDKs\Windows Azure\PowerShell\Azure\*.psd1' | ForEach-Object {Import-Module $_}
	
	Write-Host $(Get-Date) " - Importing Office 365 Modules"
	Import-Module MSOnline -DisableNameChecking
	Import-Module Microsoft.Online.SharePoint.PowerShell -DisableNameChecking
	Pop-Location 
}
New-Alias -Name cloud -Value Add-Cloud-Modules

function Add-SQLProviders
{
	Add-PSSnapin SqlServerCmdletSnapin100
	Add-PSSnapin SqlServerProviderSnapin100
}
New-Alias -Name sql -Value Add-SQLProviders

# Edit the local system's HOSTS file.
function Edit-HostFile
{
	&$env:editor c:\Windows\System32\drivers\etc\hosts
}
Set-Alias -Name hf -Value Edit-HostFile

function rsh 
{
	param ( [string] $computer )
	Enter-PSSession -ComputerName $computer -Credential (Get-Creds) -Authentication Credssp
}

function rexec
{
	param ( [string[]] $computers = $ENV:ComputerName, [ScriptBlock] $sb = {} )
	Invoke-Command -ComputerName $computers -Credential (Get-Creds) -Authentication Credssp -ScriptBlock $sb
}

function Remove-OfficeLogs
{
	Remove-Item D:\*.log -ErrorAction SilentlyContinue
	Remove-Item C:\*.log -ErrorAction SilentlyContinue
}
Remove-OfficeLogs

function Go-Home
{
	cd $home
}
Set-Alias -Name home -Value Go-Home

function Go-Code
{
	cd $env:POWERSHELL_HOME
}
Set-Alias -Name code -Value Go-Code

function Go-Scripts
{
    cd $ENV:SCRIPTS_HOME
}
Set-Alias -Name SCR -Value Go-Scripts

function Go-DSC
{
    cd $ENV:DSC_HOME
}
Set-Alias -Name DSC -Value Go-DSC

function Go-OneDrive
{
    cd $ENV:USERPROFILE\OneDrive*
}
Set-Alias -Name onedrive -Value Go-OneDrive
Set-Alias -Name od -Value Go-OneDrive

function Go-PowerShellDirectory
{
    cd $ENV:DSC_HOME
}
Set-Alias -Name gpow -Value Go-PowerShellDirectory

Remove-Item alias:cd
function cd
{
	param ( $location )

	if( $location -eq '-' )
	{
		pop-location
	}
	else
	{
		push-location $pwd.path
		Set-location $location
	}
}

function shorten-path([string] $path) { 
   $loc = $path.Replace($HOME, '~') 
   $loc = $loc -replace '^[^:]+::', '' 
   return ($loc -replace '\\(\.?)([^\\])[^\\]*(?=\\)','\$1$2') 
}

function prompt
{
	if($UserType -eq "Admin") {
    	$host.UI.RawUI.WindowTitle = "" + $(get-location) + " : Admin"
       	$host.UI.RawUI.ForegroundColor = "white"
    }
    else {
       $host.ui.rawui.WindowTitle = $(get-location)
    }
    "[$ENV:ComputerName] " + $(shorten-path (get-location)) + "> "
}

& {
    for ($i = 0; $i -lt 26; $i++) 
    { 
        $funcname = ([System.Char]($i+65)) + ':'
        $str = "function global:$funcname { set-location $funcname } " 
        invoke-expression $str 
    }
}

Remove-Item alias:ls
Set-Alias ls Get-ChildItemColor
 
function Get-ChildItemColor {
    $fore = $Host.UI.RawUI.ForegroundColor
 
    Invoke-Expression ("Get-ChildItem $args") |
    %{
      if ($_.GetType().Name -eq 'DirectoryInfo') {
        $Host.UI.RawUI.ForegroundColor = 'White'
        echo $_
        $Host.UI.RawUI.ForegroundColor = $fore
      } elseif ($_.Name -match '\.(zip|tar|gz|rar)$') {
        $Host.UI.RawUI.ForegroundColor = 'DarkGray'
        echo $_
        $Host.UI.RawUI.ForegroundColor = $fore
      } elseif ($_.Name -match '\.(exe|bat|cmd|py|pl|ps1|psm1|vbs|rb|reg)$') {
        $Host.UI.RawUI.ForegroundColor = 'DarkCyan'
        echo $_
        $Host.UI.RawUI.ForegroundColor = $fore
      } elseif ($_.Name -match '\.(txt|cfg|conf|ini|csv|sql|xml|config)$') {
        $Host.UI.RawUI.ForegroundColor = 'Cyan'
        echo $_
        $Host.UI.RawUI.ForegroundColor = $fore
      } elseif ($_.Name -match '\.(cs|asax|aspx.cs)$') {
        $Host.UI.RawUI.ForegroundColor = 'Yellow'
        echo $_
        $Host.UI.RawUI.ForegroundColor = $fore
       } elseif ($_.Name -match '\.(aspx|spark|master)$') {
        $Host.UI.RawUI.ForegroundColor = 'DarkYellow'
        echo $_
        $Host.UI.RawUI.ForegroundColor = $fore
       } elseif ($_.Name -match '\.(sln|csproj)$') {
        $Host.UI.RawUI.ForegroundColor = 'Magenta'
        echo $_
        $Host.UI.RawUI.ForegroundColor = $fore
	   } elseif ($_.Name -match '\.(docx|doc|xls|xlsx|pdf|mobi|epub|mpp|)$') {
        $Host.UI.RawUI.ForegroundColor = 'Gray'
        echo $_
        $Host.UI.RawUI.ForegroundColor = $fore
       }
        else {
        $Host.UI.RawUI.ForegroundColor = $fore
        echo $_
      }
    }
}

Remove-OfficeLogs
Remove-TempFolder