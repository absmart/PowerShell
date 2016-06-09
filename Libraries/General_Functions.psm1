function Get-ComputerDetail
{
	param(
		$ComputerName
	)

    foreach($Computer in $ComputerName)
    {
	    $Audit = New-Object System.Object
	    $ComputerSystem = Get-WmiObject Win32_ComputerSystem -ComputerName $Computer
	    $OS = Get-WmiObject Win32_OperatingSystem -ComputerName $Computer
	    $BIOS = Get-WmiObject Win32_BIOS -ComputerName $Computer
	    $NICs = Get-WmiObject Win32_NetworkAdapterConfiguration -ComputerName $Computer
	    $CPU = Get-WmiObject Win32_Processor -ComputerName $Computer | select -first 1 MaxClockSpeed,NumberOfCores
	    $Disks = Get-WmiObject Win32_LogicalDisk -ComputerName $Computer

	    $Audit | add-member -type NoteProperty -name SystemName -Value $ComputerSystem.Name
	    $Audit | add-member -type NoteProperty -name Domain -Value $ComputerSystem.Domain
	    $Audit | add-member -type NoteProperty -name Model -Value ($ComputerSystem.Manufacturer + " " + $ComputerSystem.Model.TrimEnd())
	    $Audit | add-member -type NoteProperty -name Processor -Value ("{0}({1}) x {2} GHz" -f $ComputerSystem.NumberOfProcessors.toString(), $CPU.NumberOfCores.toString(), ($CPU.MaxClockSpeed/1024).toString("#####.#"))
	    $Audit | add-member -type NoteProperty -name Memory -Value ($ComputerSystem.TotalPhysicalMemory/1gb).tostring("#####.#")
	    $Audit | add-member -type NoteProperty -name SerialNumber -Value ($BIOS.SerialNumber.TrimEnd())
	    $Audit | add-member -type NoteProperty -name OperatingSystem -Value ($OS.Caption + " - " + $OS.ServicePackMajorVersion.ToString() + "." + $OS.ServicePackMinorVersion.ToString())

	    $LocalDisks = $Disks | where { $_.DriveType -eq 3 } | Select DeviceId, @{Name="FreeSpace";Expression={($_.FreeSpace/1mb).ToString("######.#")}},@{Name="TotalSpace";Expression={($_.Size/1mb).ToString("######.#")}}
	    $Audit | add-member -type NoteProperty -name Drives -Value $LocalDisks

	    $IPAddresses = @()
	    $NICs | where { -not [string]::IsNullorEmpty($_.IPAddress)  -and $_.IPEnabled -eq $true -and $_.IpAddress -ne "0.0.0.0" } | % { $IPAddresses += $_.IPAddress }
	    $Audit | add-member -type NoteProperty -name IPAddresses -Value $IPAddresses

	    return $Audit
    }
}

function Create-DBConnectionString
{
    param(
         [Parameter(Mandatory = $True)][string]$SqlInstance,
         [Parameter(Mandatory = $True)][string]$Database,
         [Parameter(Mandatory = $False, ParameterSetName="Integrated")][switch] $IntegratedAuthentication,
         [Parameter(Mandatory = $True, ParameterSetName="SQL")][string]$User = [string]::empty,
         [Parameter(Mandatory = $True, ParameterSetName="SQL")][string]$Password = [string]::empty
    )
    $Builder = New-Object System.Data.SqlClient.SqlConnectionStringBuilder
    $Builder['Data Source'] = $SqlInstance
    $Builder['Initial Catalog'] = $Database

    if( $IntegratedAuthentication )  {
        $Builder['Integrated Security'] = $True
    }
    else {
        $Builder['User ID'] = $User
        $Builder['Password'] = $Password
    }

    return $Builder.ConnectionString
}

function Get-DotNetandPSVersion{
    param(
        $Computers
    )

    Invoke-Command -ComputerName $Computers -ScriptBlock {

        if(Test-Path 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Client\')
        {
            $Version = Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Client\' -recurse | Get-ItemProperty -name Version -ErrorAction SilentlyContinue | Select-Object -First 1
        }
        else
        {
            $Version = ".NET < 4.0"
        }

        $PowershellVersion = $PSVersionTable.PSVersion.Major
        $BootTime = Get-WmiObject win32_operatingsystem | select @{LABEL='LastBootUpTime';EXPRESSION={$_.ConverttoDateTime($_.lastbootuptime)}}

        $Results = New-Object PSObject
        $Results | Add-Member NoteProperty ComputerName $env:COMPUTERNAME
        $Results | Add-Member NoteProperty NetVersion $Version.Version
        $Results | Add-Member NoteProperty PowerShellVersion $PowershellVersion
        $Results | Add-Member NoteProperty LastBootUpTime $BootTime.LastBootUpTime

        return $Results
    }
}

function Get-InstalledDotNetVersions
{
    param(
        $ComputerName = "localhost"
    )
    if($ComputerName -eq "localhost"){
        $Path = 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP'
        return (
            Get-ChildItem $Path -recurse |
            Get-ItemProperty -Name Version  -ErrorAction SilentlyContinue |
            Select  -Unique -Expand Version
        )
    }
    else{
        Invoke-Command -ComputerName $ComputerName -ScriptBlock {
            $Path = 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP'
            return (
                Get-ChildItem $Path -recurse |
                Get-ItemProperty -Name Version  -ErrorAction SilentlyContinue |
                Select  -Unique -Expand Version
            )
        }
    }
}

function Get-RemoteDesktopSessions
{
    param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
        [string[]] $ComputerName
    )
    $Users = @()
    $Filter = "name='explorer.exe'"

    foreach( $Computer in $ComputerName ) {
        foreach( $Process in (Get-WmiObject -ComputerName $Computer -Class Win32_Process -Filter $Filter ) ) {
            $Users += (New-Object PSObject -Property @{
                Computer = $Computer
                User = $Process.GetOwner() | Select -Expand User
            })
        }
    }
    return $Users
}

function Get-RemoteSessionsByUsername
{
    param(
        $Username,
        $ComputerName = "localhost"
    )

    foreach($Computer in $ComputerName){

        $Query = $null
        $Result = $null

        $Query = qwinsta /server:$Computer | foreach { (($_.trim() -replace "\s+",","))} | ConvertFrom-Csv
        if($Username -ne $null) { $Q = $Query | where {$_.USERNAME -match $Username} }
        else { $Q = $Query }

        if($Q -ne $null)
        {
            $Result = @{
                SessionName = $Q.SessionName
                Username = $Q.Username
                ID = $Q.ID
                State = $Q.State
                Type = $Q.Type
                Device = $Q.Device
                ComputerName = $Computer
            }
            return $Result
        }
    }
}

function Disable-InternetExplorerESC
{
    $AdminKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
    $UserKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"
    Set-ItemProperty -Path $AdminKey -Name "IsInstalled" -Value 0
    Set-ItemProperty -Path $UserKey -Name "IsInstalled" -Value 0
    Stop-Process -Name Explorer
    Write-Verbose "IE Enhanced Security Configuration (ESC) has been disabled."
}

function Enable-InternetExplorerESC
{
    $AdminKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
    $UserKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"
    Set-ItemProperty -Path $AdminKey -Name "IsInstalled" -Value 1
    Set-ItemProperty -Path $UserKey -Name "IsInstalled" -Value 1
    Stop-Process -Name Explorer
    Write-Verbose "IE Enhanced Security Configuration (ESC) has been enabled."
}

function New-Guid {
	[guid]::NewGuid()
}

function Disable-UserAccessControl
{
    param(
        $ComputerName = "localhost"
    )
    if($ComputerName -eq "localhost"){
        Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorAdmin" -Value 00000000
        Write-Verbose "$ComputerName - User Access Control (UAC) has been disabled."
    }
    else{
        Invoke-Command -ComputerName $ComputerName -ScriptBlock {
            Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorAdmin" -Value 00000000
        }
        Write-Verbose "$Computername - User Access Control (UAC) has been disabled."
    }
}

function Add-GacItem([string] $path)
{
	D:\utils\gacutil.exe /i $path
}

function Get-Url
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [string] $url,
	    [ValidateSet("NTLM", "BASIC", "NONE")]
        [string] $AuthType = "NTLM",
        [ValidateSet("HEAD", "POST", "GET")]
        [string] $Method = "HEAD",
    	[int] $timeout = 8,
        [string] $Server,
        [Management.Automation.PSCredential] $creds
    )

    $request = [System.Net.WebRequest]::Create($url)
    $request.Method = $Method
    $request.Timeout = $timeout * 1000
    $request.AllowAutoRedirect = $false
    $request.ContentType = "application/x-www-form-urlencoded"
    $request.UserAgent = "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.0; .NET CLR 1.1.4322)"

    if ($AuthType -eq "BASIC")
    {
        $network_creds = $creds.GetNetworkCredential()
        $auth = "Basic " + [Convert]::ToBase64String([Text.Encoding]::Default.GetBytes($network_creds.UserName + ":" + $network_creds.Password))
        $request.Headers.Add("Authorization", $auth)
        $request.Credentials = $network_creds
        $request.PreAuthenticate = $true
    }
    elseif( $AuthType -eq "NTLM" )
    {
        $request.Credentials =  [System.Net.CredentialCache]::DefaultCredentials
    }

    if( -not [String]::IsNullorEmpty($Server) )
    {
        #$request.Headers.Add("Host", $HostHeader)
		$request.Proxy = new-object -typename System.Net.WebProxy -argumentlist $Server
    }

    #Wrap this with a measure-command to determine type
    "[{0}][REQUEST] Getting $url ..." -f $(Get-Date)
	try {
		$timing_request = Measure-Command { $response = $request.GetResponse() }
		$stream = $response.GetResponseStream()
		$reader = New-Object System.IO.StreamReader($stream)

		"[{0}][REPLY] Server = {1} " -f $(Get-Date), $response.Server
		"[{0}][REPLY] Status Code = {1} {2} . . ." -f $(Get-Date), $response.StatusCode, $response.StatusDescription
		"[{0}][REPLY] Content Type = {1} . . ." -f $(Get-Date), $response.ContentType
		"[{0}][REPLY] Content Length = {1} . . ." -f $(Get-Date), $response.ContentLength
		"[{0}][REPLY] Total Time = {1} . . ." -f $(Get-Date), $timing_request.TotalSeconds
	}
	catch [System.Net.WebException]
	{
		Write-Error ("The request failed with the following WebException - " + $_.Exception.ToString() )
	}

}

function Get-JsonRequest
{
	[CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [string] $url,
	    [ValidateSet("NTLM", "BASIC", "NONE")]
        [string] $AuthType = "NTLM",
    	[int] $timeout = 8,
        [string] $Server,
        [Management.Automation.PSCredential] $creds
    )

	$request = [System.Net.HttpWebRequest]::Create($url)
    $request.Method = "GET"
    $request.Timeout = $timeout * 1000
    $request.AllowAutoRedirect = $false
    $request.ContentType = "application/x-www-form-urlencoded"
    $request.UserAgent = "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.0; .NET CLR 1.1.4322)"
	$request.Accept = "application/json;odata=verbose"

	if ($AuthType -eq "BASIC") {
        $network_creds = $creds.GetNetworkCredential()
        $auth = "Basic " + [Convert]::ToBase64String([Text.Encoding]::Default.GetBytes($network_creds.UserName + ":" + $network_creds.Password))
        $request.Headers.Add("Authorization", $auth)
        $request.Credentials = $network_creds
        $request.PreAuthenticate = $true
    }
    elseif( $AuthType -eq "NTLM" ) {
        $request.Credentials =  [System.Net.CredentialCache]::DefaultCredentials
    }

    if( $Server -ne [String]::Empty ) {
		$request.Proxy = new-object -typename System.Net.WebProxy -argumentlist $Server
    }

    Write-Verbose ("[{0}][REQUEST] Getting $url ..." -f $(Get-Date))
	try {
		$timing_request = Measure-Command { $response = $request.GetResponse() }
		$stream = $response.GetResponseStream()
		$reader = New-Object System.IO.StreamReader($stream)

		Write-Verbose ("[{0}][REPLY] Server = {1} " -f $(Get-Date), $response.Server)
		Write-Verbose ("[{0}][REPLY] Status Code = {1} {2} . . ." -f $(Get-Date), $response.StatusCode, $response.StatusDescription)
		Write-Verbose ("[{0}][REPLY] Content Type = {1} . . ." -f $(Get-Date), $response.ContentType)
		Write-Verbose ("[{0}][REPLY] Content Length = {1} . . ." -f $(Get-Date), $response.ContentLength)
		Write-Verbose ("[{0}][REPLY] Total Time = {1} . . ." -f $(Get-Date), $timing_request.TotalSeconds)

		return ( $reader.ReadToEnd() | ConvertFrom-Json )
	}
	catch [System.Net.WebException] {
		Write-Error ("The request failed with the following WebException - " + $_.Exception.ToString() )
	}

}

function Get-Clipboard{
	PowerShell -NoProfile -STA -Command { Add-Type -Assembly PresentationCore; [Windows.Clipboard]::GetText() }
}


function Get-Uptime {
	param($ComputerName)
    foreach($Computer in $ComputerName)
    {
	    $LastBootTime = (Get-WmiObject -Class Win32_OperatingSystem -ComputerName $Computer).LastBootUpTime
	    $SysUptime = (Get-Date) - [System.Management.ManagementDateTimeconverter]::ToDateTime($LastBootTime)

	    Write-Host "System ($Computer) has been online since : " $SysUptime.days "days" $SysUptime.hours "hours" $SysUptime.minutes "minutes" $SysUptime.seconds "seconds"
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
        $ComputerName
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

function Import-PfxCertificate
{
    param(
		[String] $CertPath,
		[String] $CertRootStore = "LocalMachine",
		[String] $CertStore = "My",
        [object] $PfxPass = $null,
        [pscredential] $Credential
    )

    if ($pfxPass -eq $null)
	{
		$PfxPass = read-host "Enter the pfx password" -assecurestring
	}

    if($ComputerName){
        Invoke-Command -ComputerName $ComputerName -ArgumentList $CertPath,$CertRootStore,$CertStore,$PfxPass -ScriptBlock{
            param(
                $CertPath,
                $CertRootStore,
                $CertStore,
                $PfxPass
            )
            $Pfx = new-object System.Security.Cryptography.X509Certificates.X509Certificate2
            $Pfx.import($CertPath,$PfxPass,"Exportable,PersistKeySet")

 	        $Store = new-object System.Security.Cryptography.X509Certificates.X509Store($CertStore,$CertRootStore)
 	        $Store.open("MaxAllowed")
 	        $Store.add($Pfx)
 	        $Store.close()
        }
    }
    else{
        $Pfx = new-object System.Security.Cryptography.X509Certificates.X509Certificate2
        $Pfx.import($CertPath,$PfxPass,"Exportable,PersistKeySet")

 	    $Store = new-object System.Security.Cryptography.X509Certificates.X509Store($CertStore,$CertRootStore)
 	    $Store.open("MaxAllowed")
 	    $Store.add($Pfx)
 	    $Store.close()
    }
}

function Get-Certificate
{
    param(
        $Path
    )
    $Cert = Get-ChildItem -Path $Path
    return $Cert
}

function Remove-Certificate
{
 	param(
        $ComputerName,
		[String] $subject,
		[String] $certRootStore = "LocalMachine",
		[String] $certStore = "My"
    )
    if($ComputerName){
        Invoke-Command -ComputerName $ComputerName -ArgumentList $subject,$certRootStore,$certStore -ScriptBlock{
            param(
                $subject,
                $certRootStore,
                $certStore
            )
	        $cert = Get-ChildItem -path cert:\$certRootStore\$certStore | where { $_.Subject.ToLower().Contains($subject) }
	        $store = New-Object System.Security.Cryptography.X509Certificates.X509Store($certStore,$certRootStore)
	        $store.Open("ReadWrite")
	        $store.Remove($cert)
	        $store.Close()
        }
    }
    else{
        $cert = Get-ChildItem -path cert:\$certRootStore\$certStore | where { $_.Subject.ToLower().Contains($subject) }
	    $store = New-Object System.Security.Cryptography.X509Certificates.X509Store($certStore,$certRootStore)
	    $store.Open("ReadWrite")
	    $store.Remove($cert)
	    $store.Close()
    }
}

function Export-Certificate
{
	param(
		[string] $subject,
		[string] $certStore = "My",
		[string] $certRootStore = "LocalMachine",
		[string] $file,
		[object] $pfxPass
	)

	$cert = Get-ChildItem -path cert:\$certRootStore\$certStore | where { $_.Subject.ToLower().Contains($subject) }
	$type = [System.Security.Cryptography.X509Certificates.X509ContentType]::pfx

     if ($pfxPass -eq $null)
	{
		$pfxPass = read-host "Enter the pfx password" -assecurestring
	}

	$bytes = $cert.export($type, $pfxPass)
	[System.IO.File]::WriteAllBytes($file , $bytes)
}

function Pause
{
	#From http://www.microsoft.com/technet/scriptcenter/resources/pstips/jan08/pstip0118.mspx
	Write-Host "Press any key to exit..."
	$null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Get-PreviousMonthRange
{
	$Object = New-Object PSObject -Property @{           
    	last_month_begin = $(Get-Date -Day 1).AddMonths(-1)
		last_month_end = $(Get-Date -Day 1).AddMonths(-1).AddMonths(1).AddDays(-1)
	}
	return $Object
}

function Generate-Password
{
	param (
		[int] $Number = 10,
		[int] $Length = 16,
		[switch] $Hash
	)

	[void][Reflection.Assembly]::LoadWithPartialName("System.Web")
	$Algorithm = 'sha256'

	$Passwords = @()
	for( $i=0; $i -lt $Number; $i++)
	{
		$Pass = [System.Web.Security.Membership]::GeneratePassword($Length,1)
		if( $Hash ) {
			$Hasher = [System.Security.Cryptography.HashAlgorithm]::create($Algorithm)
			$ComputeHash = $Hasher.ComputeHash( [Text.Encoding]::UTF8.GetBytes( $Pass.ToString() ) )
			$Pass = ( ([system.bitconverter]::tostring($ComputeHash)).Replace("-","") )
		}
		$Passwords += $Pass
	}
	return $Passwords
}

function Get-WindowsUpdateConfiguration
{
    $AutoUpdateNotificationLevels= @{0="Not configured"; 1="Disabled" ; 2="Notify before download"; 3="Notify before installation"; 4="Scheduled installation"}
    $AutoUpdateDays=@{0="Every Day"; 1="Every Sunday"; 2="Every Monday"; 3="Every Tuesday"; 4="Every Wednesday";5="Every Thursday"; 6="Every Friday"; 7="EverySaturday"}

	$AUSettings = (New-Object -com "Microsoft.Update.AutoUpdate").Settings
	$AUObj = New-Object -TypeName System.Object
	Add-Member -InputObject $AuObj -MemberType NoteProperty -Name "NotificationLevel" -Value $AutoUpdateNotificationLevels[$AUSettings.NotificationLevel]
	Add-Member -InputObject $AuObj -MemberType NoteProperty -Name "UpdateDays"  -Value $AutoUpdateDays[$AUSettings.ScheduledInstallationDay]
	Add-Member -InputObject $AuObj -MemberType NoteProperty -Name "UpdateHour"  -Value $AUSettings.ScheduledInstallationTime
	Add-Member -InputObject $AuObj -MemberType NoteProperty -Name "Recommended updates" -Value $(IF ($AUSettings.IncludeRecommendedUpdates) {"Included."}  else {"Excluded."})
	return $AuObj
}

function Get-SystemGAC
{
    param(
        [string[]] $ComputerName
    )

	$ScriptBlock = {
		$Assemblies = @()
		$Util = "D:\Utils\gacutil.exe"

		if( Test-Path $Util ) {
			foreach( $Dll in (&$Util /l | where { $_ -imatch "culture" } | Sort) ) {
				$Dll -imatch "(.*),\sVersion=(.*),\sCulture=(.*),\sPublicKeyToken=(.*),\sprocessorArchitecture=(.*)" | Out-Null
				$Assemblies += (New-Object PSObject -Property @{
					DllName = $Matches[1].TrimStart()
					Version = $Matches[2]
					PublicKeyToken = $Matches[3]
					Architecture = $Matches[4]
				})
			}
		}
		else {
			throw "Could not find gacutil.exe"
		}

		return $Assemblies
	}

	if( $ComputerName -imatch $ENV:COMPUTERNAME ) {
		return &$ScriptBlock
	}
	else {
		return ( Invoke-Command -Computer $ComputerName -ScriptBlock $ScriptBlock )
	}
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

function Get-LocalGroup
{
    param(
        [string[]] $ComputerName = $ENV:COMPUTERNAME,
        [string[]] $Group
    )
    foreach($Computer in $ComputerName){
        foreach($Group in $GroupName){
	        $Adsi  = [ADSI]("WinNT://" + $Computer + ",computer")
	        $AdGroup = $Adsi.psbase.children.find($Group)
	        $Members = $AdGroup.psbase.invoke("Members") | %{$_.GetType().InvokeMember("Name", 'GetProperty', $null, $_, $null)}
	        return $Members
        }
    }
}

function Add-DomainGroupToLocalGroup
{
    param(
        [string[]] $ComputerName = $ENV:COMPUTERNAME,
        [string[]] $LocalGroup,
        [string] $DomainGroup
    )
    foreach($Computer in $ComputerName){
        foreach($Group in $LocalGroup){
            $DomainController = ([ADSI]'').name
            $AdsiLocalGroup = [ADSI]"WinNT://$Computer/$Group,group"
            $AdsiLocalGroup.Add("WinNT://$domain_controller/$DomainGroup,group")
        }
    }
}

function Add-GroupToLocalAdmin
{
    param(
        [string[]] $ComputerName = $ENV:COMPUTERNAME,
        [string[]] $Group
    )
    foreach($Computer in $ComputerName){
        foreach($G in $Group){
	        $DomainController = ([ADSI]'').name
            $LocalGroup = [ADSI]"WinNT://$ComputerName/Administrators,group"
            $LocalGroup.Add("WinNT://$DomainController/$G,group")
        }
    }
}

function Add-UserToLocalAdmin
{
    param(
        [string[]] $ComputerName = $ENV:COMPUTERNAME,
        [string[]] $User
    )
    foreach($Computer in $ComputerName){
        foreach($U in $User){
	        $DomainController = ([ADSI]'').name
            $localGroup = [ADSI]"WinNT://$Computer/Administrators,user"
            $localGroup.Add("WinNT://$DomainController/$U,user")
        }
    }
}

function Convert-ObjectToHash( [Object] $obj )
{
	$ht = @{}
	$Keys = $obj | Get-Member -MemberType NoteProperty | select -Expand Name

	foreach( $key in $keys ) {
		if( $obj.$key -is [System.Array] ) {
			$value = [String]::Join(" | ", $obj.$key )
		}
        else {
			$value = $obj.$key
		}
		$ht.Add( $Key, $Value )
	}

	return $ht
}

function Audit-IISServers
{
    param(
        [String[]] $Servers
    )

	Set-Variable -Option Constant -Name WebServerQuery -Value "Select * from IIsWebServerSetting"
	Set-Variable -Option Constant -Name VirtualDirectoryQuery -Value "Select * from IISWebVirtualDirSetting"
	Set-Variable -Option Constant -Name AppPoolQuery -Value "Select * from IIsApplicationPoolSetting"
	Set-Variable -Name iisAudit -Value @()

	foreach( $server in $Servers ) {
		Write-Progress -activity "Querying Server" -status "Currently querying $Server . . . "
		if( Test-Connection -Count 1 -ComputerName $Server ) {

			$wmiWebServerSearcher = [WmiSearcher] $WebServerQuery
			$wmiWebServerSearcher.Scope.Path = "\\{0}\root\microsoftiisv2" -f $Server
			$wmiWebServerSearcher.Scope.Options.Authentication = 6
			$iisSettings = $wmiWebServerSearcher.Get()

			$wmiVirtDirSearcher = [WmiSearcher] $VirtualDirectoryQuery
			$wmiVirtDirSearcher.Scope.Path = "\\{0}\root\microsoftiisv2" -f $Server
			$wmiVirtDirSearcher.Scope.Options.Authentication = 6
			$virtDirSettings = $wmiVirtDirSearcher.Get()

			$wmiAppPoolSearcher = [WmiSearcher] $AppPoolQuery
			$wmiAppPoolSearcher.Scope.Path = "\\{0}\root\microsoftiisv2" -f $Server
			$wmiAppPoolSearcher.Scope.Options.Authentication = 6
			$appPoolSettings = $wmiAppPoolSearcher.Get()

			$iisSettings | Select Name, ServerComment, LogFileDirectory, ServerBindings | % {
				$audit = New-Object System.Object

				$SiteName = $_.Name

				$audit | add-member -type NoteProperty -name ServerName -Value $Server
				$audit | add-member -type NoteProperty -name Name -Value $_.ServerComment
				$audit | add-member -type NoteProperty -name LogFileDirectory -Value $_.LogFileDirectory

				$hostheaders = @()
				$_.ServerBindings | Where {[String]::IsNullorEmpty($_.Hostname) -eq $false } | % {
					$hostheader = New-Object System.Object
					$hostheader | add-member -type NoteProperty -name HostName -Value $_.Hostname
					$hostheader | add-member -type NoteProperty -name IP -Value $_.IP
					$hostheader | add-member -type NoteProperty -name Port -Value $_.Port
					$hostheaders += $hostheader
				}
				$audit | Add-Member -type NoteProperty -Name HostHeaders -Value $hostheaders

				$VirtualDirectories = @()
				$virtDirSettings | where { $_.Name.Contains($SiteName) } | % {
					$VirtualDirectory = New-Object System.Object

					$VirtualDirectory | add-member -type NoteProperty -name Name -Value $_.Name
					$VirtualDirectory | add-member -type NoteProperty -name Path -Value $_.Path
					$VirtualDirectory | add-member -type NoteProperty -name AppFriendlyName -Value $_.AppFriendlyName
					$VirtualDirectory | add-member -type NoteProperty -name AnonymousUserName -Value $_.AnonymousUserName
					$VirtualDirectory | add-member -type NoteProperty -name DefaultDocuments -Value $_.DefaultDoc
					$VirtualDirectory | add-member -type NoteProperty -name AppPoolName -Value $_.AppPoolId
					$VirtualDirectory | add-member -type NoteProperty -name AuthenticationProviders -Value $_.NTAuthenticationProviders
					$VirtualDirectory | add-member -type NoteProperty -Name DotNetFrameworkVersion -Value (Get-FrameworkVersion $_ )

					$AppPoolId = $_.AppPoolId
					$AppPoolAccount = ($appPoolSettings | where { $_.Name.Contains($AppPoolId) } | Select WAMUserName).WAMUserName
					$VirtualDirectory | add-member -type NoteProperty -name AppPoolAccount -Value $AppPoolAccount

					$perms = $nul
					if( $_.AccessRead -eq $true ) { $perms += "R" }
					if( $_.AccessWrite -eq $true ) { $perms += "W" }
					if( $_.AccessExecute -eq $true ) { $perms += "E" }
					if( $_.AccessScript -eq $true ) { $perms += "S" }

					$auth = $Nul
					if( $_.AuthAnonymous -eq $true ) { $auth += "Anonymous|" }
					if( $_.AuthNTLM -eq $true ) { $auth += "Integrated|" }
					if( $_.AuthBasic -eq $true ) { $auth += "Basic|" }

					$VirtualDirectory | add-member -type NoteProperty -name AccessPermissions -Value $perms
					$VirtualDirectory | add-member -type NoteProperty -name Authentication -Value $auth.Trim("|")
					$VirtualDirectories += $VirtualDirectory
				}
				$audit | add-member -type NoteProperty -name VirtualDirectories -Value $VirtualDirectories

				$iisAudit += $audit
			}
		}
        else {
			Write-Host $_ "appears down. Will not continue with audit"
		}
	}

	return $iisAudit
}

function Audit-Server
{
    param(
        [String] $ComputerName
    )

	$audit = New-Object System.Object
	$computerSys = Get-WmiObject Win32_ComputerSystem -ComputerName $Computer
	$os = Get-WmiObject Win32_OperatingSystem -ComputerName $Computer
	$bios = Get-WmiObject Win32_BIOS -ComputerName $Computer
	$nics = Get-WmiObject Win32_NetworkAdapterConfiguration -ComputerName $Computer
	$cpu = Get-WmiObject Win32_Processor -ComputerName $Computer | select -first 1 MaxClockSpeed,NumberOfCores
	$disks = Get-WmiObject Win32_LogicalDisk -ComputerName $Computer

	$audit | add-member -type NoteProperty -name SystemName -Value $computerSys.Name
	$audit | add-member -type NoteProperty -name Domain -Value $computerSys.Domain
	$audit | add-member -type NoteProperty -name Model -Value ($computerSys.Manufacturer + " " + $computerSys.Model.TrimEnd())
	$audit | add-member -type NoteProperty -name Processor -Value ("{0}({1}) x {2} GHz" -f $computerSys.NumberOfProcessors.toString(), $cpu.NumberOfCores.toString(), ($cpu.MaxClockSpeed/1024).toString("#####.#"))
	$audit | add-member -type NoteProperty -name Memory -Value ($computerSys.TotalPhysicalMemory/1gb).tostring("#####.#")
	$audit | add-member -type NoteProperty -name SerialNumber -Value ($bios.SerialNumber.TrimEnd())
	$audit | add-member -type NoteProperty -name OperatingSystem -Value ($os.Caption + " - " + $os.ServicePackMajorVersion.ToString() + "." + $os.ServicePackMinorVersion.ToString())

	$localDisks = $disks | where { $_.DriveType -eq 3 } | Select DeviceId, @{Name="FreeSpace";Expression={($_.FreeSpace/1mb).ToString("######.#")}},@{Name="TotalSpace";Expression={($_.Size/1mb).ToString("######.#")}}
	$audit | add-member -type NoteProperty -name Drives -Value $localDisks

	$IPAddresses = @()
	$nics | where { -not [string]::IsNullorEmpty($_.IPAddress)  -and $_.IPEnabled -eq $true -and $_.IpAddress -ne "0.0.0.0" } | % { $IPAddresses += $_.IPAddress }
	$audit | add-member -type NoteProperty -name IPAddresses -Value $IPAddresses

	return $audit
}

function Audit-Servers([String[]] $Servers, [String] $app, [String] $env)
{
	begin {
		$ErrorActionPreference = "silentlycontinue"
		$serverAudit = @()

	}
	process {
		if ( $_ -ne $null ) { $Servers = $_ }
		foreach( $server in $servers ) {
			Write-Progress -activity "Querying Server" -status "Currently querying $server . . . "

			$audit = Audit-Server $server
			$audit | Add-Member -type NoteProperty -name Farm -Value $app
			$audit | Add-Member -type NoteProperty -name Environment -Value $env
			$serverAudit += $audit
		}
	}
	end {
		return $serverAudit | where { $_.SystemName -ne $null }
	}
}

function Create-WindowsService
{
    param(
        [string[]] $ComputerName,
        [string] $Path,
        [string] $Service,
        [string] $User,
        [string] $Pass
    )

	$class = "Win32_Service"
	$method = "Create"

	foreach( $Computer in $ComputerName ) {
		$mc = [wmiclass]"\\$Computer\ROOT\CIMV2:$class"
		$inparams = $mc.PSBase.GetMethodParameters($method)
		$inparams.DesktopInteract = $false
		$inparams.DisplayName = $Service
		$inparams.ErrorControl = 0
		$inparams.LoadOrderGroup = $null
		$inparams.LoadOrderGroupDependencies = $null
		$inparams.Name = $Service
		$inparams.PathName = $Path
		$inparams.ServiceDependencies = $null
		$inparams.ServiceType = 16
		$inparams.StartMode = "Automatic"

		if( [string]::IsNullOrEmpty( $User ) ) {
			$inparams.StartName = $null # will start as localsystem builtin if null
			$inparams.StartPassword = $null
		}
        else {
			$inparams.StartName = $User
			$inparams.StartPassword = $Pass
		}

		$result += $mc.PSBase.InvokeMethod($method,$inparams,$null)
	}
	return( $result | Format-List )
}

function Get-IPAddress
{
    param(
        [string] $Name
    )
    process {
         try { [System.Net.DNS]::GetHostAddresses($Name) | Select -Expand IPAddressToString  } catch { }
    }
}

function Get-Tail
{
    param(
        [string] $path = $(throw "Path name must be specified."),
        [int] $count = 10,
        [Alias("f")]
        [switch] $wait
    )

    try {
        Get-Content $path -Tail $count -Wait:$wait
    }
    catch {
        throw "An error occur - $_ "
    }

}
Set-Alias -Name Tail -Value Get-Tail

function Query-DatabaseTable ( [string] $server , [string] $dbs, [string] $sql )
{
	$Columns = @()

	$con = "server=$server;Integrated Security=true;Initial Catalog=$dbs"

	$ds = new-object "System.Data.DataSet" "DataSet"
	$da = new-object "System.Data.SqlClient.SqlDataAdapter" ($con)

	$da.SelectCommand.CommandText = $sql
	$da.SelectCommand.Connection = $con

	$da.Fill($ds) | out-null
	$ds.Tables[0].Columns | Select ColumnName | % { $Columns += $_.ColumnName }
	$res = $ds.Tables[0].Rows  | Select $Columns

	$ds.Clear()
	$da.Dispose()
	$ds.Dispose()

	return $res
}

function BulkWrite-ToSQLDatabase([Object] $table)
{
    $bulkCopy = [Data.SqlClient.SqlBulkCopy] $ConnectionString
    $bulkCopy.DestinationTableName = $TableName
    $bulkCopy.WriteToServer($table)
}

function New-EventLog
{
    New-Object PSObject -Property @{
        Time = ''
        EntryType = ''
	    Source = ''
	    Message = ''
	    Server = ''
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

<#
.SYNOPSIS
 Displays the local or remote computer's last boot up time and current total uptime.
.EXAMPLE
 Get-SystemUptime -ComputerName localhost
    csname         : HOSTNAME
    LastBootUpTime : 11/6/2014 8:14:49 AM

    System (localhost) has been online since :  0 days 4 hours 20 minutes 37 seconds
#>
function Get-SystemUptime
{
	param(
		[string] $ComputerName = "localhost"
		)
		# PowerShell 3.0 - Use this if you want to not query WMI.
            #New-CimInstance -ComputerName $ComputerName
			#Get-CimInstance -ClassName win32_operatingsystem | select csname, lastbootuptime
		# PowerShell 2.0
			Get-WmiObject -ComputerName $ComputerName win32_operatingsystem | select csname, @{LABEL='LastBootUpTime';EXPRESSION={$_.ConverttoDateTime($_.lastbootuptime)}} | fl csname, lastbootuptime
			Get-Uptime $ComputerName
}

function Get-InstalledSoftware
{
    param(
        $ComputerName = "localhost"
    )

    $Architecture = Get-WmiObject -Class Win32_OperatingSystem | Select OSArchitecture
    if($Architecture -eq "64-bit"){$Path = "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"}
    else{$Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"}

    if($ComputerName -eq $env:COMPUTERNAME){
        Get-ItemProperty $Path | Select-Object DisplayName, DisplayVersion, Publisher, InstallDate | Format-Table -AutoSize
    }
    else{
        Invoke-Command -ComputerName $ComputerName -ScriptBlock {
            Get-ItemProperty $Path | Select-Object DisplayName, DisplayVersion, Publisher, InstallDate | Format-Table -AutoSize
        }
    }
}

function Enter-PSSessionCredSSP
{
    param(
        [string] $Computer
    )
    Enter-PSSession -ComputerName $Computer -Authentication Credssp -Credential $env:USERDOMAIN\$env:USERNAME
}

function Test-ConnectionUntilUp
{
    param (
        $ComputerName
    )
    do
    {
        $End = "Down"
        $Test = Test-Connection -ComputerName $ComputerName -Count 1 -ErrorAction SilentlyContinue
        if($Test){
            $Date = Get-Date
            Write-Host "$Date - $ComputerName is back up!"
            $End = "Up"
        }
    }
    while ($End = "Down")
}

function Get-ServiceDetail
{
    param(
        $Name = $null,
        $ComputerName = 'localhost',
        [switch] $NotSystemUser
    )
    foreach($Computer in $ComputerName){
        if($NotSystemUser){
            Get-WmiObject -Class Win32_Service -ComputerName $Computer -Filter "Name like '%$Name%'" |
                Where-Object {$_.StartName -notmatch 'LocalSystem' -and $_.StartName -notmatch 'NetworkService' -and $_.StartName -notmatch 'LocalService'} |
                Select PSComputerName, DisplayName, Name, StartName, State, Description, PathName, ProcessId, ServiceType
        }
        else{
            Get-WmiObject -Class Win32_Service -ComputerName $Computer -Filter "Name like '%$Name%'" |
                Select PSComputerName, DisplayName, Name, StartName, State, Description, PathName, ProcessId, ServiceType
        }
    }
}

function Create-SecureCredential
{
	param(
		$Username,
		$Password
	)
	$securePassword = ConvertTo-SecureString -String $Password -AsPlainText -Force
	$Credential = New-Object System.Management.Automation.PSCredential ($Username, $securePassword)
	return $Credential
}

function Get-MyIp
{
    (Invoke-WebRequest -Uri icanhazip.com).Content
}
New-Alias -Name myip -Value Get-MyIp