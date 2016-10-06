$user = $env:USERNAME

# Get the ID and security principal of the current user account
$myWindowsID = [System.Security.Principal.WindowsIdentity]::GetCurrent();
$myWindowsPrincipal = New-Object System.Security.Principal.WindowsPrincipal($myWindowsID);

# Get the security principal for the administrator role
$adminRole = [System.Security.Principal.WindowsBuiltInRole]::Administrator;

# Check to see if we are currently running as an administrator
if($myWindowsPrincipal.IsInRole($adminRole))
{
    # We are running as an administrator, so change the title and background colour to indicate this
    $Host.UI.RawUI.WindowTitle = $myInvocation.MyCommand.Definition + "(Elevated)";
    $Host.UI.RawUI.BackgroundColor = "DarkBlue";
    Clear-Host;
}else{
    # We are not running as an administrator, so relaunch as administrator

    # Create a new process object that starts PowerShell
    $newProcess = New-Object System.Diagnostics.ProcessStartInfo "PowerShell";

    # Specify the current script path and name as a parameter with added scope and support for scripts with spaces in it's path
    $newProcess.Arguments = "& '" + $script:MyInvocation.MyCommand.Path + "'"

    # Indicate that the process should be elevated
    $newProcess.Verb = "runas";

    # Start the new process
    [System.Diagnostics.Process]::Start($newProcess);

    # Exit from the current, unelevated, process
    Exit;
}

#Write-Host "`n[SELECTION] - Input for script workload." -ForegroundColor Yellow

$input0 = new-object psobject
Add-Member -InputObject $input0 -MemberType NoteProperty -Name Workload -Value "Query storage spaces configuration" -Force
$input1 = new-object psobject
Add-Member -InputObject $input1 -MemberType NoteProperty -Name Workload -Value "Turn off clustered storage spaces" -Force
$input2 = new-object psobject
Add-Member -InputObject $input2 -MemberType NoteProperty -Name Workload -Value "Build new storage spaces configuration optimized for Azure" -Force
$input3 = new-object psobject
Add-Member -InputObject $input3 -MemberType NoteProperty -Name Workload -Value "Clear an existing storage spaces configuration" -Force
$input4 = new-object psobject

[array] $Input += $input0
[array] $Input += $input1
[array] $Input += $input2
[array] $Input += $input3
[array] $Input += $input4

$Work = $Input | Select-Object Workload | Out-GridView -Title "Select workload for script" -PassThru
$SelWork = $Work.Workload

## Turn off Clustered Storage Spaces 
if ($SelWork -eq "Turn off clustered storage spaces")
{
	$StorSub = Get-StorageSubSystem

	foreach ($SubSystem in $StorSub) 
	{
	 	if (($SubSystem.Model -eq "Clustered Storage Spaces") –and ($SubSystem.AutomaticClusteringEnabled -eq $true)) {Set-StorageSubSystem -FriendlyName "$($SubSystem.FriendlyName)" -AutomaticClusteringEnabled $false}
		else {Write-Host "`n `t[ERROR] No clustered storage spaces found" -ForegroundColor Yellow}
	}
}

## Build a new Storage Spaces Configuration optimized for Azure
if ($SelWork -eq "Build new storage spaces configuration optimized for Azure")
{
	[array] $SubSystem = Get-StorageSubSystem
	switch($SubSystem.count)
	{
	"2" {
			Write-Host "Clustered space detected"
		    $compname = [System.Net.Dns]::GetHostByName(($env:computerName)) 
		    $fqdn = $compname.HostName 
		    $ClusSubSystem = Get-StorageSubSystem | where {$_.FriendlyName -like "Clustered*"} 
			$StorageCluster = $ClusSubSystem.FriendlyName
		    foreach ($StorSub in $ClusSubSystem ) 
		    { 
		        if (($StorSub.Model -eq "Clustered Storage Spaces") -and ($StorSub.AutomaticClusteringEnabled -eq $true)) {Set-StorageSubSystem -FriendlyName "$($StorSub.FriendlyName)" -AutomaticClusteringEnabled $false} 
		    } 
		    $Interleave1 = new-object psobject 
		    Add-Member -InputObject $Interleave1 -MemberType NoteProperty -Name Interleave -Value 65536 -Force 
		    Add-Member -InputObject $Interleave1 -MemberType NoteProperty -Name Workload -Value "Normal" -Force 
		    $Interleave2 = new-object psobject 
		    Add-Member -InputObject $Interleave2 -MemberType NoteProperty -Name Interleave -Value 262144 -Force 
		    Add-Member -InputObject $Interleave2 -MemberType NoteProperty -Name Workload -Value "Data Warehousing" -Force 
		    [array] $Interleave += $Interleave1 
		    [array] $Interleave +=  $Interleave2 
		     
		    $SelStripe = $Interleave | Out-GridView  -Title "Select Storage Spaces Stripe Value" -PassThru 
		    $StripeSize = $SelStripe.Interleave 
		    $Workload = $SelStripe.Workload 
		        If ($StripeSize) 
		        { 
		        Write-Host "`n[INFO] - Script will create spaces disk with $($Workload.tolower()) stripe value." -ForegroundColor Yellow 
		        Write-Host "`tSuccess" 
		        }Else{ 
		        Write-Host "`tFailed to set stripe setting" -ForegroundColor Red 
		        Exit 
		        } 
		    try 
		    { 
		    $pool = Get-StorageSubSystem -FriendlyName $StorageCluster | get-storagenode | ?{$_.Name -eq $fqdn} | Get-PhysicalDisk -canpool $true 
		    $DiskCount = $pool.count 
		    If ($DiskCount -lt 2) { Write-Host "`n Exiting. More than $DiskCount disk is required to build a storage pool" -ForegroundColor Red;Exit } 
		    Get-StorageSubSystem $StorageCluster | New-StoragePool -FriendlyName "$($env:computerName)Pool" -PhysicalDisks $pool | New-VirtualDisk -FriendlyName "$($env:computerName)Disk" -Interleave $StripeSize -NumberOfColumns $DiskCount -ResiliencySettingName simple –UseMaximumSize | Initialize-Disk -PartitionStyle GPT -PassThru |New-Partition -AssignDriveLetter -UseMaximumSize | Format-Volume -FileSystem NTFS -NewFileSystemLabel "$($env:computerName)Volume" -AllocationUnitSize 65536 -Confirm:$false 
		    } 
		    catch [System.Exception] 
		    { 
		    Write-host "$_ No disks found to add to pool." -ForegroundColor Red 
		    }
	}
	"1"	{
			Write-Host "Standalone space detected"
			$Interleave1 = new-object psobject 
		    Add-Member -InputObject $Interleave1 -MemberType NoteProperty -Name Interleave -Value 65536 -Force 
		    Add-Member -InputObject $Interleave1 -MemberType NoteProperty -Name Workload -Value "Normal" -Force 
		    $Interleave2 = new-object psobject 
		    Add-Member -InputObject $Interleave2 -MemberType NoteProperty -Name Interleave -Value 262144 -Force 
		    Add-Member -InputObject $Interleave2 -MemberType NoteProperty -Name Workload -Value "Data Warehousing" -Force 
		    [array] $Interleave += $Interleave1 
		    [array] $Interleave +=  $Interleave2 
		     
		    $SelStripe = $Interleave | Out-GridView  -Title "Select Storage Spaces Stripe Value" -PassThru 
		    $StripeSize = $SelStripe.Interleave 
		    $Workload = $SelStripe.Workload 
			      
			$PoolCount = Get-PhysicalDisk -CanPool $True 
			$DiskCount = $PoolCount.count 
			$PhysicalDisks = Get-StorageSubSystem -FriendlyName "Storage Spaces*" | Get-PhysicalDisk -CanPool $True 
			New-StoragePool -FriendlyName "IOData" -StorageSubsystemFriendlyName "Storage Spaces*" -PhysicalDisks $PhysicalDisks |New-VirtualDisk -FriendlyName "DiskIO" -Interleave $StripeSize -NumberOfColumns $DiskCount -ResiliencySettingName simple –UseMaximumSize |Initialize-Disk -PartitionStyle GPT -PassThru |New-Partition -AssignDriveLetter -UseMaximumSize |Format-Volume -FileSystem NTFS -NewFileSystemLabel "IODisk" -AllocationUnitSize 65536 -Confirm:$false 
	}
	default {Write-Host "[ERROR] Something unexpected happened" -ForegroundColor Red}
	}
}

## Clear an existing Storage Spaces Configuration
if ($SelWork -eq "Clear an existing storage spaces configuration")
{
	$a = new-object -comobject wscript.shell 
	$intAnswer = $a.popup("Are you sure you want to continue? On all nodes this function clears any existing storage spaces configuration and erases all data on virtual data drives PERMANENTLY!", ` 
	0,"!!! Warning !!!",4) 
	If ($intAnswer -eq 6)
	{ 
	New-EventLog –LogName Application –Source “Windows PowerShell Script” -ErrorAction Ignore
	write-eventlog -logname Application -source 'Windows PowerShell Script' -eventID 3001 -entrytype Warning -message "User logged in as $($user) clicked Yes to Warning message `"Are you sure you want to continue? On all nodes this function clears any existing storage spaces configuration and erases all data on virtual data drives PERMANENTLY!`" "
	# Remove virtual disks and storage pools
    Write-Host ""
    Write-Host "Removing Virtual Disks and Pools..." -NoNewline -ForegroundColor Cyan
    $storagePools = Get-StoragePool | ? FriendlyName -NE "primordial"
    $storagePools | Set-StoragePool -IsReadOnly:$false
    Get-VirtualDisk | Remove-VirtualDisk -Confirm:$false
    $storagePools | Remove-StoragePool -Confirm:$false
    Write-Host Done.
    Write-Host ""
    }
}
## Build a new Storage Spaces Configuration optimized for Azure
if ($SelWork -eq "Query storage spaces configuration")
{
	If (!(Test-Path "$Env:SystemDrive\WindowsAzure\Logs")) { New-Item "$Env:SystemDrive\WindowsAzure\Logs" -ItemType directory | Out-Null }

	If (!(Test-Path "$Env:SystemDrive\WindowsAzure\Logs\Guest_Storage_Log"))
	{
		New-Item "$Env:SystemDrive\WindowsAzure\Logs\Guest_Storage_Log" -ItemType Directory | Out-Null
	}

	$StampedDirName = Get-Date -Format "yyyy-MM-dd_hh-mm-ss"

	If (!(Test-Path "$Env:SystemDrive\WindowsAzure\Logs\Guest_Storage_Log\$StampedDirName"))
	{
		New-Item "$Env:SystemDrive\WindowsAzure\Logs\Guest_Storage_Log\$StampedDirName" -ItemType Directory | Out-Null
	}

	#guest storage performance checks
	#set up log file
	$GuestStorageLog = "$Env:SystemDrive\WindowsAzure\Logs\Guest_Storage_Log\$StampedDirName\Storage_Info.log"

	#get storage pools - we need at least 1 to return with IsPrimordial = $false in order to have storage spaces configured
	[array]$Pools = Get-StoragePool | Where IsPrimordial -eq $false
	$PoolCount = $Pools.Count

	If ($PoolCount -lt 1)
	{
		#storage spaces is NOT configured. Log it and throw a root cause
		"[WARN] Storage Spaces is not configured (this is supported, but not optimal)" | Out-File $GuestStorageLog -Append
	}
	ElseIf ($PoolCount -gt 1)
	{
		#more than 1 storage space is configured. Log it and throw a root cause
		#"[WARN] More than one storage space is configured (this is supported, but not optimal)" | Out-File $GuestStorageLog -Append
		
	}
	Else
	{
		#loop the storage pools
		ForEach ($Pool in $Pools)
		{
			#pool name
			$PoolName = $Pool.FriendlyName
			#pool id
			$PoolObjectId = $Pool.ObjectId
			#write spaces info to log
			"[INFO] Storage Spaces is configured." | Out-File $GuestStorageLog -Append
			"[INFO] Storage pool name is $PoolName" | Out-File $GuestStorageLog -Append
			"[INFO] Storage pool ObjectID is $PoolObjectId" | Out-File $GuestStorageLog -Append
		}

		#get all physical disks having bus type = SAS, which means it is a data disk
		[array]$AllDataDisks = Get-PhysicalDisk | Where BusType -eq "SAS”
		$DataDisksCount = $AllDataDisks.Count

		If ($DataDisksCount -lt 1)
		{
			#no data disks found. Log it and throw root cause
			"[ERROR] No data disks found" | Out-File $GuestStorageLog -Append
			
		}
		Else
		{
			ForEach ($Disk in $AllDataDisks)
			{
				#this means it is in a pool
				[array]$CannotPoolReasons += $Disk.CannotPoolReason
				#this is not in a pool, but it can be added to a pool
				[array]$CanPoolReasons += $Disk.Canpool
			}

			#count the disks in pool and disks that could be in a pool
			$DisksInPool = $CannotPoolReasons.Count
			$CanPoolDisks = $CanPoolReasons.Count

			If ($DisksInPool -lt 1)
			{
				#no disks are in the pool
				"[WARN] Spaces should be set up on $CanPoolDisks data disks for maxmium I/O in Azure" | Out-File $GuestStorageLog -Append
			}
			ElseIf ($DisksInPool -ne $DataDisksCount)
			{
				#not all available data disks are in the pool
				"[WARN] Not all available data disks are in the storage pool ($DisksInPool of ${DataDisksCount})" | Out-File $GuestStorageLog -Append
			}
			Else
			{
				#all available data disks are in the pool
				"[INFO] All available data disks are in the storage pool ($DisksInPool of ${DataDisksCount})" | Out-File $GuestStorageLog -Append
			}

			#a virtual disk is created when a pool is created, and its resiliencysettingname property will be populated
			[array]$AllVirtualDisks = Get-VirtualDisk | Where { $_.ResiliencySettingName -ne $null }
			$VirtualDisksCount = $AllVirtualDisks.Count

			If ($VirtualDisksCount -lt 1)
			{
				#customer did not set up the virtual disk for the pool
				#log it and throw root cause
				"[ERROR] Storage pool setup is not complete - Missing virtual disk" | Out-File $GuestStorageLog -Append
				
			}
			ElseIf ($VirtualDisksCount -gt 1)
			{
				#customer set up multiple virtual disks, which is not optimal
				#log it and throw root cause
				"[WARN] Storage pool setup is not optimal - Multiple virtual disks found. Recommendation: Use only one virtual disk for storage pool" | Out-File $GuestStorageLog -Append
				
			}
			Else
			{
				#loop all virtual disks
				ForEach ($VirtualDisk in $AllVirtualDisks)
				{
					#vdisksetting
					$VDiskSetting = $VirtualDisk.ResiliencySettingName
					#vdiskcolumns
					$VDiskColumns = $VirtualDisk.NumberOfColumns 
					#vdiskinterleave
					$VDiskInterleave = $VirtualDisk.Interleave
					#vdiskname
					$VDiskName = $VirtualDisk.FriendlyName 
					#vdiskobjectid
					$VdiskObjectId = $VirtualDisk.ObjectId

					#the virtual disk setting should be "Simple"
					If ($VDiskSetting -eq "Simple")
					{
						"[INFO] Virtual disk $VDiskName is correctly configured, $VDiskSetting is the correct setting for maxmium I/O in Azure" | Out-File $GuestStorageLog -Append
					}
					Else
					{
						#the virtual disk is not Simple. log it and throw root cause
						"[ERROR] Virtual disk $VDiskName is incorrectly configured for maxmium I/O in Azure. Recommendation: Rebuild the virtual disk as Simple" | Out-File $GuestStorageLog -Append
						
					}

					If ($VDiskColumns -eq $DisksInPool)
					{
						#vdiskcolumns should match disks in pool
						"[INFO] Virtual disk $VDiskName is correctly configured, $VDiskColumns matches the disks in the pool setting for maxmium I/O in Azure" | Out-File $GuestStorageLog -Append
					}
					Else
					{
						#vdiskcolumns does not match disks in pool. log it and throw root cause
						"[ERROR] Virtual disk $VDiskName has incorrectly configured Disk Columns for maxmium I/O in Azure. Recommendation: Rebuild the virtual disk setting the columns to match the number of disks in the pool" | Out-File $GuestStorageLog -Append
						
					}
					switch ($VDiskInterleave)
					{
					65536 {"[INFO] Virtual disk $VDiskName is correctly configured, the disk interleave $VDiskInterleave matches the best setting for maximum I/O in Azure for normal workloads." | Out-File $GuestStorageLog -Append}
					262144 {"[INFO] Virtual disk $VDiskName is correctly configured, the disk interleave $VDiskInterleave matches the best setting for maximum I/O in Azure for data warehousing workloads." | Out-File $GuestStorageLog -Append}
					Default {"[ERROR] Virtual disk $VDiskName has an incorrectly configured Disk Interleave for maxmium I/O in Azure. Recommendation: Rebuild the virtual disk with an interleave of 65536 (64K)" | Out-File $GuestStorageLog -Append}
					}
					$VDiskGUID = $VDiskObjectId
					#parse the VDiskGUID for VD:
					$StringStart = $VDiskGUID.indexof("VD:")
					#jump to the position where we need to start, which is always 41 chars proceeding the index of VD:
					$StringStart += 41
					#our string of interest is always 38 characters in length
					$StringEnd = 38
					#grab the string of interest and set as $SerialNumber
					$SerialNumber = $VDiskGUID.Substring($StringStart,$StringEnd)
					#get the disk having the matching serial number from the VDiskGUID parsing
					$SpaceDisk = Get-Disk | Where { $_.SerialNumber -eq $SerialNumber }
					#get the disk number from the disk object
					$CurrNum = $SpaceDisk.Number
					#get the partition for the disk number of the disk object we found matching the serial of the vdisk
					$SpacePart = Get-Partition -DiskNumber $CurrNum | Where { $_.Type -eq "Basic" }
					#get access paths for the partition. sort them descending
					$SpacePartAcc = [array]($SpacePart.AccessPaths | Sort-Object -Descending)
					#execute fsutil - get the clsuter size
					$fs = fsutil fsinfo ntfsinfo $SpacePartAcc[0]
					#regex for parsing out cluster size
					$reg = [regex]'(?<=Bytes.*Cluster.*)\d+'
					#execute the regex match to find cluster size
					$SpaceDiskCluster = ($fs | %{$reg.matches($_)}).Value

					#check to ensure cluster size is 65536 (64K)
					If ($SpaceDiskCluster -eq 65536)
					{
						#cluster size is 64K
						"[INFO] Virtual disk $VDiskName is correctly configured, the cluster size matches $SpaceDiskCluster, which is the best setting for maxmium I/O in Azure" | Out-File $GuestStorageLog -Append
					}
					Else
					{
						#cluster size is not 64K. log it and throw root cause
						"[ERROR] Virtual disk $VDiskName has an incorrectly configured cluster size for maxmium I/O in Azure. Recommendation: Reformat the volume to 65536 (64K) cluster size" | Out-File $GuestStorageLog -Append
						
					}


				} #end loop of virtual disks
				
			
			} #end else for has virtual disks
		} #end else for has data disks
	} #end else for pool work
	$cluscheck = Get-StorageSubSystem
	foreach ($sub in $cluscheck)
	{
		If ($sub.AutomaticClusteringEnabled -eq $true) {"[ERROR] $($sub.FriendlyName) is incorrectly configured, clustering is enabled on pool." | Out-File $GuestStorageLog -Append}
		If ($sub.AutomaticClusteringEnabled -eq $false) {"[INFO] $($sub.FriendlyName) is correctly configured, cluster not enabled on pool." | Out-File $GuestStorageLog -Append}
	}
	
	
		#Get info about Automatic Clustering
		Get-StorageSubSystem |Fl FriendlyName, AutomaticClusteringEnabled | Out-File $GuestStorageLog -Append

		#List the storage pool
		$storagepoollist = Get-StoragePool -IsPrimordial $false
		foreach($a in $storagepoollist)
		{
		"======================= Physical Disk Mappying for storage pool $($a.FriendlyName) ==================" | Out-File $GuestStorageLog -Append
		Get-StoragePool $a.FriendlyName | Get-PhysicalDisk | format-table -AutoSize | Out-File $GuestStorageLog -Append
		}

		"" | Out-File $GuestStorageLog -Append
		
			$virtualdisklist = Get-VirtualDisk
		foreach($a in $virtualdisklist)
		{
		 "======================= Virtual Disk $($a.FriendlyName) Information =================="| Out-File $GuestStorageLog -Append
		Get-VirtualDisk $a.FriendlyName | ft FriendlyName, ResiliencySettingName, NumberOfColumns,Interleave, NumberOfAvailableCopies,OperationalStatus | Out-File $GuestStorageLog -Append
		}
		
		"" | Out-File $GuestStorageLog -Append
		
		function GetDiskAllocUnitSizeKB([char[]]$drive = $null)
		{
		    $wql = "SELECT BlockSize FROM Win32_Volume " + `
		           "WHERE FileSystem='NTFS' and DriveLetter = '" + $drive + ":'"
		    $BytesPerCluster = Get-WmiObject -Query $wql -ComputerName '.' `
		                        | Select-Object BlockSize
		    return $BytesPerCluster.BlockSize / 1024;
		}

		"======================= AllocationUnit ==================" | Out-File $GuestStorageLog -Append
		$partitions = Get-Partition
		foreach($p in $partitions)
		{
		   if ($p.DriveLetter.tostring().trim().length -ne 0 -and $p.Type -ne 'Reserved')
		   {
		   
		    $dataSize = GetDiskAllocUnitSizeKB $p.DriveLetter
		    "AllocationUnitSize for Drive Letter $($p.Driveletter) = $($dataSize)" | Out-File $GuestStorageLog -Append
		    }
		}
		"" | Out-File $GuestStorageLog -Append
		"======================= Volume List ==================" | Out-File $GuestStorageLog -Append
		Get-Volume | Out-File $GuestStorageLog -Append

		 Invoke-Item "$Env:SystemDrive\WindowsAzure\Logs\Guest_Storage_Log\$StampedDirName\Storage_Info.log" 
	
}
Write-Host -NoNewLine "Press any key to continue..." -ForegroundColor Green
 $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")