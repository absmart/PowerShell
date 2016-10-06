function Get-ComputerDetail
{
	param(
		$ComputerName = $env:COMPUTERNAME
	)

    foreach($Computer in $ComputerName)
    {
	    $Audit = New-Object System.Object
	    $ComputerSystem = Get-WmiObject Win32_ComputerSystem -ComputerName $Computer
	    $OS = Get-WmiObject Win32_OperatingSystem -ComputerName $Computer
	    $BIOS = Get-WmiObject Win32_BIOS -ComputerName $Computer
	    $NICs = Get-WmiObject Win32_NetworkAdapterConfiguration -ComputerName $Computer
	    $CPU = Get-WmiObject Win32_Processor -ComputerName $Computer | Select-Object -First 1 MaxClockSpeed,NumberOfCores
	    $Disks = Get-WmiObject Win32_LogicalDisk -ComputerName $Computer

	    $UpTime = $OS | select @{LABEL='LastBootUpTime';EXPRESSION={$_.ConverttoDateTime($_.lastbootuptime)}}
        $SysUptime = (Get-Date) - [System.Management.ManagementDateTimeconverter]::ToDateTime($OS.LastBootUpTime)

        $Audit | Add-Member -Type NoteProperty -Name SystemName -Value $ComputerSystem.Name
	    $Audit | Add-Member -Type NoteProperty -Name Domain -Value $ComputerSystem.Domain
	    $Audit | Add-Member -Type NoteProperty -Name Model -Value ($ComputerSystem.Manufacturer + " " + $ComputerSystem.Model.TrimEnd())
	    $Audit | Add-Member -Type NoteProperty -Name Processor -Value ("{0}({1}) x {2} GHz" -f $ComputerSystem.NumberOfProcessors.toString(), $CPU.NumberOfCores.toString(), ($CPU.MaxClockSpeed/1024).toString("#####.#"))
	    $Audit | Add-Member -Type NoteProperty -Name Memory -Value ($ComputerSystem.TotalPhysicalMemory/1gb).tostring("#####.#")
	    $Audit | Add-Member -Type NoteProperty -Name SerialNumber -Value ($BIOS.SerialNumber.TrimEnd())
	    $Audit | Add-Member -Type NoteProperty -Name OperatingSystem -Value ($OS.Caption + " - " + $OS.ServicePackMajorVersion.ToString() + "." + $OS.ServicePackMinorVersion.ToString())

	    $LocalDisks = $Disks | Where-Object { $_.DriveType -eq 3 } | Select DeviceId, @{Name="FreeSpace";Expression={($_.FreeSpace/1mb).ToString("######.#")}},@{Name="TotalSpace";Expression={($_.Size/1mb).ToString("######.#")}}
	    $Audit | Add-Member -type NoteProperty -Name Drives -Value $LocalDisks

	    $IPAddresses = @()
	    $NICs | Where-Object { -not [string]::IsNullorEmpty($_.IPAddress)  -and $_.IPEnabled -eq $true -and $_.IpAddress -ne "0.0.0.0" } | % { $IPAddresses += $_.IPAddress }
	    $Audit | Add-Member -Type NoteProperty -Name IPAddresses -Value $IPAddresses

        $Audit | Add-Member -Type NoteProperty -Name LastBootUpTime -Value $UpTime.LastBootUpTime
        $Audit | Add-Member -Type NoteProperty -Name UpTimeDays -Value $SysUptime.Days
        $Audit | Add-Member -Type NoteProperty -Name UpTimeHr -Value $SysUptime.Hours
        $Audit | Add-Member -Type NoteProperty -Name UpTimeMin -Value $SysUptime.Minutes
        $Audit | Add-Member -Type NoteProperty -Name UpTimeSec -Value $SysUptime.Seconds

	    return $Audit
    }
}

function Get-TopProcesses
{
	param(
        [string] $Computer = $env:COMPUTERNAME,
        [int] $Threshold = 5
    )

    if( !(Test-Connection -Destination $Computer -Count 1) ){
        throw "Could not connect to :: $Computer"
    }

    $Processes = Get-WmiObject -ComputerName $Computer -Class Win32_PerfFormattedData_PerfProc_Process -Property Name, PercentProcessorTime

    $Items = @()
    foreach( $Process in ($Processes | where { $_.Name -ne "Idle"  -and $_.Name -ne "_Total" }) )
	{
        if( $Process.PercentProcessorTime -ge $Threshold )
		{
            $items += (New-Object PSObject -Property @{
				Name = $Process.Name
				CPU = $Process.PercentProcessorTime
			})
        }
    }

    return ( $Items | Sort-Object -Property CPU -Descending)
}

function Get-ScheduledTasks
{
    param(
        $ComputerName = "localhost"
    )

	$Tasks = @()
	$TasksComConnector = New-Object -ComObject("Schedule.Service")
	$TasksComConnector.Connect($ComputerName)

    foreach( $Task in ($TasksComConnector.getFolder("\").GetTasks(0)) ){

		$Xml = [xml] ( $Task.XML )

		$Tasks += (New-Object PSObject -Property @{
			HostName = $ComputerName
			Name = $Tasks.Name
			LastRunTime = $Task.LastRunTime
			LastResult = $Task.LastTaskResult
			NextRunTime = $Task.NextRunTime
			Author = $Xml.Task.RegistrationInfo.Author
			RunAsUser = $Xml.Task.Principals.Principal.UserId
			TaskToRun = $Xml.Task.Actions.Exec.Command
            Arguments = $Xml.Task.Actions.Exec.Arguments
		})
	}

	return $Tasks
}

function Get-Certificate
{
    param(
        $Path
    )
    $Certs = Get-ChildItem -Path Cert:\ -Recurse | Select-Object PSPath,FriendlyName,SubjectName,Subject,Issuer,NotAfter,NotBefore,Thumbprint,Department,HasPrivateKey,PublicKey,PrivateKey,Version
    
    return $Certs | Where-Object {$_.Thumbprint -ne $null}
}

function Get-WindowsUpdateConfiguration
{
    param(
        $ComputerName = "localhost"
    )

    $AutoUpdateNotificationLevels= @{0="Not configured"; 1="Disabled" ; 2="Notify before download"; 3="Notify before installation"; 4="Scheduled installation"}
    $AutoUpdateDays=@{0="Every Day"; 1="Every Sunday"; 2="Every Monday"; 3="Every Tuesday"; 4="Every Wednesday";5="Every Thursday"; 6="Every Friday"; 7="EverySaturday"}
    $AUObj = New-Object -TypeName System.Object
    
    if($ComputerName -eq 'localhost')
    {
        $AUSettings = (New-Object -com "Microsoft.Update.AutoUpdate").Settings
        $AUObj | Add-Member -MemberType NoteProperty -Name "ComputerName" -Value $env:COMPUTERNAME
    }
    else
    {
    	$AuSettings = Invoke-Command -ComputerName $ComputerName -ScriptBlock{(New-Object -com "Microsoft.Update.AutoUpdate").Settings}
        $AUObj | Add-Member -MemberType NoteProperty -Name "ComputerName" -Value $ComputerName
    }
    
	Add-Member -InputObject $AuObj -MemberType NoteProperty -Name "NotificationLevel" -Value $AutoUpdateNotificationLevels[$AUSettings.NotificationLevel]
	Add-Member -InputObject $AuObj -MemberType NoteProperty -Name "UpdateDays"  -Value $AutoUpdateDays[$AUSettings.ScheduledInstallationDay]
	Add-Member -InputObject $AuObj -MemberType NoteProperty -Name "UpdateHour"  -Value $AUSettings.ScheduledInstallationTime
	Add-Member -InputObject $AuObj -MemberType NoteProperty -Name "Recommended updates" -Value $(IF ($AUSettings.IncludeRecommendedUpdates) {"Included"}  else {"Excluded"})
    $WUServer =  (Get-ItemProperty -Path HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate -Name WUServer).WUServer
    $AUObj | Add-Member -MemberType NoteProperty -Name "WUServer" -Value $WUServer
	return $AuObj
}

function Get-LocalAdmins
{
    param(
        [string[]] $ComputerName = $env:COMPUTERNAME
    )

    foreach($Computer in $ComputerName){
	    $Adsi  = [ADSI]("WinNT://" + $Computer + ",computer")
	    $Group = $Adsi.psbase.children.find("Administrators")
	    $Members = $Group.psbase.invoke("Members") | %{$_.GetType().InvokeMember("Name", 'GetProperty', $null, $_, $null)}
	    return $Members
    }
}

function Get-EventLogs
{
    param(
        [string] $type = "Error",
        [string[]] $servers,
        [datetime] $after = (get-date).adddays(-1),
        [datetime] $before = (get-date),
        [string] $logname = "Application",
        [switch] $notype
    )

    $logs = @()
    foreach ($server in $servers) {
	    Write-host "Now looking though server $server"
	    if ($notype) {
	        $events = Get-Eventlog -logname $logname -after ([datetime]$after) -before ([datetime]$before)
	    }
	    else {
	        $events = Get-Eventlog -logname $logname -after ([datetime]$after) -before ([datetime]$before) -entrytype $type
	    }

	    foreach ($event in $events) {
		    $documents = New-EventLog
		    $documents.time = $event.timegenerated
		    $documents.EntryType = $event.EntryType
		    $documents.Source = $event.Source
		    $documents.message = $event | select -expandproperty message
		    $documents.server = $server
		    $logs += $documents
	    }
    }
    return $logs
}

function Get-InstalledSoftware
{
    param(
        $ComputerName = "localhost"
    )

    $Architecture = Get-WmiObject -Class Win32_OperatingSystem | Select OSArchitecture -ExpandProperty OSArchitecture
    
    if($Architecture -eq "64-bit")
    {
        $Path = "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    }
    else
    {
        $Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
    }

    if($ComputerName -eq $env:COMPUTERNAME -or 'localhost'){
        Get-ItemProperty $Path | Where-Object {$_.DisplayName -ne $null} | Select-Object @{Name="ComputerName";EXPRESSION={$env:COMPUTERNAME}}, DisplayName, DisplayVersion, Publisher, InstallDate | Sort-Object -Property DisplayName
    }
    else{
        Invoke-Command -ComputerName $ComputerName -ScriptBlock {
            Get-ItemProperty $Path | Where-Object {$_.DisplayName -ne $null} | Select-Object @{Name="ComputerName";EXPRESSION={$env:COMPUTERNAME}}, DisplayName, DisplayVersion, Publisher, InstallDate | Sort-Object -Property DisplayName
        }
    }
}

function Get-UnInheritedFolders
{
    param(
        $Directory = "C:\Example"
    )

    $directoryChildItems = (Get-ChildItem -Path $Directory -Recurse -Directory)
    $status = @()
    
    foreach($directory in $directoryParse)
    {
        #$inheritance = ($directory | Get-Acl).Access | Where-Object {$_.InheritanceFlags -eq $false}
        $acls = (Get-Acl -Path $Directory.FullName).Access
        foreach ($acl in $acls)
        {
            if($hing)
            {
                $result = [ordered]@{
                    FolderPath = $Folder.FullName;
                    IsInherited = $acl.IsInherited;
                    InheritanceFlags = $acl.InheritanceFlags;
                    PropagationFlags = $acl.PropagationFlags
                }

            $results += (New-Object -TypeName PSObject -Property $result)
            
            }
        }
    }

    return $results
}

$Detail = Get-ComputerDetail -ComputerName $ComputerName | Export-Csv .\ComputerDetail.csv -NoTypeInformation -Append
$Tasks = Get-ScheduledTasks -ComputerName $ComputerName | Export-Csv .\ScheduledTasks.csv -NoTypeInformation -Append
#$Certs = Get-Certificate | Export-Csv .\ComputerDetail.csv -NoTypeInformation -Append
$WUConfig = Get-WindowsUpdateConfiguration -ComputerName $ComputerName | Export-Csv .\WUConfig.csv -NoTypeInformation -Append
$LocalAdmins = Get-LocalAdmins -ComputerName $ComputerName | Export-Csv .\LocalAdmins.csv -NoTypeInformation -Append
$Software = Get-InstalledSoftware -ComputerName $ComputerName | Export-Csv .\Software.csv -NoTypeInformation -Append
