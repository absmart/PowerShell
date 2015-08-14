param (
	[Parameter(Mandatory=$true)]
	[string] $file
)

if( (Get-PSSnapin | Where { $_.Name -eq "StoragePoint.PowershellCmdlets" }) -eq $nul ) {
	Add-PSSnapIn StoragePoint.PowershellCmdlets
}

. (Join-Path $env:POWERSHELL_HOME "Libraries\General_Functions.psm1")
. (Join-Path $env:POWERSHELL_HOME "Libraries\SharePoint_Functions.ps1")

Set-Variable -option constant -Name Url -Value "http://sharepoint.domain.tld/Department/Support/"
Set-Variable -option constant -Name List -Value "Trending"
Set-Variable -option constant -Name Title -Value "Server"

function Get-StoragePointSpace
{
	Begin{
	}
	Process{
		$Server = $_.Server
		$Partition = $_.Partition

		Get-Endpoint $_.Partition | 
			Select @{Name="Server";Expression={$Server}},@{Name="Partition";Expression={$Partition}}, @{Name="TotalDiskSpace";Expression={$_.AvailableSpace/1mb}}, @{Name="FreeDiskSpace";Expression={$_.FreeSpace/1mb}}
	}
	End{
	}
}

function Get-DiskSpace
{
	Begin{
		$Disks = @()
	}
	Process{
		$FreeSpace = New-Object PSObject
		$Farm = $_.Farm
				
		if( $_.Type -eq "Windows" ) { $FreeSpace = $_ | Get-WindowsDiskSpace }
		if( $_.Type -eq "NetApp" ) { $FreeSpace = $_ | Get-StoragePointSpace }
		
		$FreeSpace | add-member -type NoteProperty -name Farm -value $Farm  
		$Disks += $FreeSpace
	}
	End{
		return $Disks
	}
}

Import-CSV $file | Get-DiskSpace | % { WriteTo-SPListViaWebService $url $list (Convert-ObjectToHash $_) $title }





