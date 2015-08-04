function Get-DirHash()
{
	begin {
		$ErrorActionPreference = "silentlycontinue"
	}
	process {
		dir -Recurse $_ | where { $_.PsIsContainer -eq $false } | select Name,DirectoryName,@{Name="SHA1 Hash"; Expression={get-hash1 $_.FullName -algorithm "sha1"}}
	}
	end {
	}
}

<#
.SYNOPSIS
This PowerShell Script will synchronize two directories.  It can copy files from one directory or another.

.DESCRIPTION
Version - 1.0.0
The script will copy files from one directory to another based on different MD5 hash values

.EXAMPLE
.\Sync-Directories.ps1 -src c:\SourceFolder -dst d:\DestinationFolder 

.EXAMPLE
.\Sync-Directories.ps1 -src c:\SourceFolder -dst d:\DestinationFolder -ignore_files @("*.xml")

.EXAMPLE
.\Sync-Directories.ps1 -src c:\SourceFolder -dst d:\DestinationFolder -ignore_files @("*.xml", "housekeeping.bat") -logging -log "D:\Logs\Rsync.log"

.PARAMETER Src
Specifies the main directory to copy files from. Mandatory parameter

.PARAMETER Dst
Specifies the main directory to copy files to. Mandatory parameter

.PARAMETER ignore_files
Specifies an array of extensions of files to ignore in the sync process

.PARAMETER logging
Switch to including logging of files copied. Parameter Set = Logging

.PARAMETER log
Full Path to Log file. Parameter Set = Logging

.NOTES
This current version is limited in that it only copies files from one directory to another. It does not completely sync to directories ie remove 
files from the destination. It will also overwrite any existing files in the destination. It does not do conflict detection.

#>
function Sync-Files{
	[CmdletBinding(SupportsShouldProcess=$true)]
	param (
		
		[Parameter(Mandatory=$true)] 
		[string] $src,

		[Parameter(Mandatory=$true)] 
		[string] $dst,

		[string] $ignore_files = [string]::emtpy,

		[switch] $logging,
		[string] $log = [String]::empty
	)	

	function Get-MD5 
	{
		param(
			[string] $file = $(throw 'a filename is required')
		)

		$fileStream = [system.io.file]::openread($file)
		$hasher = [System.Security.Cryptography.HashAlgorithm]::create("md5")
		$hash = $hasher.ComputeHash($fileStream)
		$fileStream.Close()
		$md5 = ([system.bitconverter]::tostring($hash)).Replace("-","")

		Write-Verbose "File - $file - has a MD5 - $md5"

		return ( $md5 ) 
	}

	function Strip-RootDirectory
	{
		param (
			[string] $FullDir,
			[string] $RootDir
		)

		$RootDir = $RootDir.Replace("\","\\")
		return ( $FullDir -ireplace $RootDir, [String]::Empty )
	}

	function Get-DirectoryHash
	{
		param(
			[Parameter(Mandatory=$True,ValueFromPipeline=$True)]
			[string] $root
		)

		begin {
			$ErrorActionPreference = "silentlycontinue"
			$hashes = @()
		}
		process {
			if( -not ( Test-Path $root ) ) {
				throw "Could not find the directory $($root)"
			}

			Write-Verbose "Getting Hashes for $($root) . . ."

			$hashes = @( 
				Get-ChildItem -Recurse $root -Exclude $ignore_files | 
				Where { $_.PsIsContainer -eq $false } | 
				Select Name, @{Name="Directory"; Expression={Strip-RootDirectory -FullDir $_.DirectoryName -RootDir $root}}, @{Name="Hash"; Expression={Get-MD5 $_.FullName}}
			)
		}
		end {
			return $hashes
		}
	}

	function main
	{
		if( $logging -and $log -eq [string]::Empty ) {
			$log = Read-Host "Please enter the file path to the log file"
		}

		if( $logging ) { 
			"[ $(Get-Date) ] -Starting the comparison process . . ." | Out-File -Encoding ascii -Append -FilePath $log
		}

		$ignore_files = $ignore_files.Split(",")
		
		$src_hashes = Get-DirectoryHash -root $src
		$dst_hashes = Get-DirectoryHash -root $dst 

		if( $src_hashes -eq $null -and $dst_hashes -eq $null ) {
			throw "Either $src is empty or both $src and $dst are empty . . ."
		}

		if( $dst_hashes -eq $null ) {
			$diffs = $src_hashes | Select Name, Directory
		}
		else {
			$diffs = Compare-Object -referenceobject $src_hashes -differenceobject  $dst_hashes  -property @("Name","Directory", "Hash") | Where { $_.SideIndicator -eq "<=" } | Select Name, Directory
		}

		foreach( $diff in $diffs ) {
			$new_file_dst_path = (Join-Path $dst $diff.Directory)
			$org_src_file_path = (Join-Path $src $diff.Directory)

			if( -not ( Test-Path $new_file_dst_path ) ) { 
				Write-Verbose "Creating $($new_file_dst_path) . . ."
				New-Item $new_file_dst_path -ItemType Directory | Out-Null 
			}

			if( $logging ) { 
				"[ $(Get-Date) ] - Copying $($diff.Name) from $($org_src_file_path) to $($new_file_dst_path) . . ." | Out-File -Encoding ascii -Append -FilePath $log
			}

			Write-Verbose "Copying $($diff.Name) from $($org_src_file_path) to $($new_file_dst_path) . . ."
			Copy-Item (Join-Path $org_src_file_path $diff.Name) (Join-Path $new_file_dst_path $diff.Name) -Force
		}

		if( $logging ) { 
			"[ $(Get-Date) ] - Finish. . ." | Out-File -Encoding ascii -Append -FilePath $log
		}
	}
	main
}

function Compare-GAC {
	param (
		[string] $ref,
		[string] $dif
	)	

	$rGac = get-SystemGAC -server $ref
	$dGac = get-SystemGAC -server $dif

	Compare-Object $rGac $dGac -SyncWindow $rGac.Length -Property DllName,PublicKeyToken,Version
}

function Compare-Directories {
	param (
		[string] $src,
		[string] $dst
	)	

	Compare-Object $($src | Get-DirHash) $($dst | Get-DirHash) -property @("Name","SHA1 Hash") -includeEqual
}

function Compare-DirectoriesMultiple {
	[CmdletBinding(SupportsShouldProcess=$true)]
	param (
		[Parameter(Mandatory=$true)] [string[]] $computers,
		[Parameter(Mandatory=$true)] [string] $path,
		[switch] $ShowAllFiles,
		[string] $out
	)

	function Reduce-Set
	{
		PARAM (
			[Parameter(ValueFromPipeline=$true)]
			[object] $ht
		)
		
		BEGIN { 
			$differences = @()
		}
		PROCESS {		
			Write-Verbose "Comparing Keys . . ."				
			foreach ( $key in $ht.Keys ) {
				if( $ht[$key].Count -eq 1 ) {		
					$differences += (New-Object PSObject -Property @{
						File = $ht[$key] | Select -ExpandProperty Name
						System = $ht[$key] | Select -ExpandProperty System
						Hash = $ht[$key] | Select -ExpandProperty FileHash
					})
				} 
				elseif( ($ht[$key] | Select -Unique -ExpandProperty FileHash).Count -ne 1 )	{
					foreach( $diff in $ht[$key] ) {
						$differences += (New-Object PSObject -Property @{
							File =  $diff.Name
							System = $diff.System
							Hash = $diff.FileHash
						})
					}
				}
			}
			
		}
		END { 
			return $differences
		}
	}

	$map = {
		param ( [string] $directory )
		
		. (Join-Path $ENV:SCRIPTS_HOME "Libraries\Standard_Functions.ps1")
		$files = @()
		$system = $ENV:COMPUTERNAME
		
		Write-Verbose "Working on - $system"
		foreach( $file in (Get-ChildItem $directory -Recurse | Where { $_.PSIsContainer -eq $false } ) ) {
			$files += New-Object PSObject -Property @{
				Name = $file.FullName
				System = $system
				FileHash = (Get-Hash1 $file.FullName)
			}
		}
		return $files
	} 

	function main
	{
		$results = Invoke-Command -ComputerName $computers -ScriptBlock $map -ArgumentList $path | Select Name, FileHash, System 

		if( !$ShowAllFiles ) {
			$results = $results | Group-Object -Property Name -AsHashTable | Reduce-Set
		}
		
		if( ![string]::IsNullOrEmpty($out) ) {
			$results | Export-Csv -Encoding Ascii -NoTypeInformation $out
			Invoke-Item $out
		}
		else {
			return $results
		}
	}
	main
}

function Compare-RegHive {
	param(
		$regLocation,
		$Computers
	)

	Compare-DirectoriesMultiple -Path $regLocation -Computers $Computers	
}