function Audit-Server( [String] $Server )
{
	$audit = New-Object System.Object
	$computer = Get-WmiObject Win32_ComputerSystem -ComputerName $Server
	$os = Get-WmiObject Win32_OperatingSystem -ComputerName $Server
	$bios = Get-WmiObject Win32_BIOS -ComputerName $Server
	$nics = Get-WmiObject Win32_NetworkAdapterConfiguration -ComputerName $Server
	$cpu = Get-WmiObject Win32_Processor -ComputerName $Server | select -first 1 MaxClockSpeed,NumberOfCores
	$disks = Get-WmiObject Win32_LogicalDisk -ComputerName $Server
	
	$audit | add-member -type NoteProperty -name SystemName -Value $computer.Name
	$audit | add-member -type NoteProperty -name Domain -Value $computer.Domain		
	$audit | add-member -type NoteProperty -name Model -Value ($computer.Manufacturer + " " + $computer.Model.TrimEnd())
	$audit | add-member -type NoteProperty -name Processor -Value ("{0}({1}) x {2} GHz" -f $computer.NumberOfProcessors.toString(), $cpu.NumberOfCores.toString(), ($cpu.MaxClockSpeed/1024).toString("#####.#"))
	$audit | add-member -type NoteProperty -name Memory -Value ($computer.TotalPhysicalMemory/1gb).tostring("#####.#")
	$audit | add-member -type NoteProperty -name SerialNumber -Value ($bios.SerialNumber.TrimEnd())
	$audit | add-member -type NoteProperty -name OperatingSystem -Value ($os.Caption + " - " + $os.ServicePackMajorVersion.ToString() + "." + $os.ServicePackMinorVersion.ToString())
	
	$localDisks = $disks | where { $_.DriveType -eq 3 } | Select DeviceId, @{Name="FreeSpace";Expression={($_.FreeSpace/1mb).ToString("######.#")}},@{Name="TotalSpace";Expression={($_.Size/1mb).ToString("######.#")}}
	$audit | add-member -type NoteProperty -name Drives -Value $localDisks
	
	$IPAddresses = @()
	$nics | where { -not [string]::IsNullorEmpty($_.IPAddress)  -and $_.IPEnabled -eq $true -and $_.IpAddress -ne "0.0.0.0" } | % { $IPAddresses += $_.IPAddress }
	$audit | add-member -type NoteProperty -name IPAddresses -Value $IPAddresses

	return $audit
}

function Create-DBConnectionString 
{
    param(
         [Parameter(Mandatory = $True)][string]$sql_instance,
         [Parameter(Mandatory = $True)][string]$database,

         [Parameter(Mandatory = $False, ParameterSetName="Integrated")][switch] $integrated_authentication,
         [Parameter(Mandatory = $true, ParameterSetName="SQL")][string]$user = [string]::empty,
         [Parameter(Mandatory = $true, ParameterSetName="SQL")][string]$password = [string]::empty
    )
    $builder = New-Object System.Data.SqlClient.SqlConnectionStringBuilder
    $builder['Data Source'] = $sql_instance
    $builder['Initial Catalog'] = $database

    if( $integrated_authentication )  { 
        $builder['Integrated Security'] = $true
    }
    else { 
        $builder['User ID'] = $user
        $builder['Password'] = $password
    }

    return $builder.ConnectionString
}


function Get-dotNetandPSVersion{
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

function Get-Installed-DotNet-Versions 
{
    $path = 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP'

    return (
        Get-ChildItem $path -recurse | 
        Get-ItemProperty -Name Version  -ErrorAction SilentlyContinue | 
        Select  -Unique -Expand Version
    )
}


function Get-RemoteDesktopSessions
{
    param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
        [string[]] $computers
    )
     
    begin {
        $users = @()
        $filter = "name='explorer.exe'"
    }
    process {
        foreach( $computer in $computers ) {
            foreach( $process in (Get-WmiObject -ComputerName $computer -Class Win32_Process -Filter $filter ) ) {
                $users += (New-Object PSObject -Property @{
                    Computer = $computer
                    User = $process.getOwner() | Select -Expand User
                })                     
            }
        }
    }
    end {
        return $users
    }
}

function Disable-InternetExplorerESC 
{
    $AdminKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
    $UserKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"
    Set-ItemProperty -Path $AdminKey -Name "IsInstalled" -Value 0
    Set-ItemProperty -Path $UserKey -Name "IsInstalled" -Value 0
    Stop-Process -Name Explorer
    Write-Host "IE Enhanced Security Configuration (ESC) has been disabled." -ForegroundColor Green
}

function Enable-InternetExplorerESC 
{
    $AdminKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
    $UserKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"
    Set-ItemProperty -Path $AdminKey -Name "IsInstalled" -Value 1
    Set-ItemProperty -Path $UserKey -Name "IsInstalled" -Value 1
    Stop-Process -Name Explorer
    Write-Host "IE Enhanced Security Configuration (ESC) has been enabled." -ForegroundColor Green
}

function New-Guid{
	[guid]::NewGuid()
}

function Disable-UserAccessControl
{
    Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorAdmin" -Value 00000000
    Write-Host "User Access Control (UAC) has been disabled." -ForegroundColor Green    
} 

function Add-GacItem([string] $path) 
{
	d:\utils\gacutil.exe /i $path
    	
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
	param($computer)
	
	$lastboottime = (Get-WmiObject -Class Win32_OperatingSystem -computername $computer).LastBootUpTime
	$sysuptime = (Get-Date) - [System.Management.ManagementDateTimeconverter]::ToDateTime($lastboottime)
	
	Write-Host "System ($computer) has been online since : " $sysuptime.days "days" $sysuptime.hours "hours" $sysuptime.minutes "minutes" $sysuptime.seconds "seconds"
}

function Get-TopProcesses
{
	param(
        [string] $computer = $env:COMPUTERNAME,
        [int] $threshold = 5
    )
 
    # Test connection to computer
    if( !(Test-Connection -Destination $computer -Count 1) ){
        throw "Could not connect to :: $computer"
    }
 
    # Get all the processes
    $processes = Get-WmiObject -ComputerName $computer -Class Win32_PerfFormattedData_PerfProc_Process -Property Name, PercentProcessorTime
  
    $items = @()
    foreach( $process in ($processes | where { $_.Name -ne "Idle"  -and $_.Name -ne "_Total" }) )
	{
        if( $process.PercentProcessorTime -ge $threshold )
		{
            $items += (New-Object PSObject -Property @{
				Name = $process.Name
				CPU = $process.PercentProcessorTime
			})
        }
    }
  
    return ( $items | Sort-Object -Property CPU -Descending)
}

function Get-ScheduledTasks([string] $server) 
{
	$tasks = @()
	$tasks_com_connector = New-Object -ComObject("Schedule.Service")
	$tasks_com_connector.Connect($server)
	
    foreach( $task in ($tasks_com_connector.getFolder("\").GetTasks(0)) ){
	
		$xml = [xml] ( $task.XML )
		
		$tasks += (New-Object PSObject -Property @{
			HostName = $server
			Name = $task.Name
			LastRunTime = $task.LastRunTime
			LastResult = $task.LastTaskResult
			NextRunTime = $task.NextRunTime
			Author = $xml.Task.RegistrationInfo.Author
			RunAsUser = $xml.Task.Principals.Principal.UserId
			TaskToRun = $xml.Task.Actions.Exec.Command
            Arguments = $xml.Task.Actions.Exec.Arguments 
		})
	}
	
	return $tasks
}

function Import-PfxCertificate 
{    
    param(
		[String] $certPath,
		[String] $certRootStore = "LocalMachine",
		[String] $certStore = "My",
		[object] $pfxPass = $null
    )
    
	$pfx = new-object System.Security.Cryptography.X509Certificates.X509Certificate2    
   
    if ($pfxPass -eq $null) 
	{
		$pfxPass = read-host "Enter the pfx password" -assecurestring
	}
   
    $pfx.import($certPath,$pfxPass,"Exportable,PersistKeySet")    
   
 	$store = new-object System.Security.Cryptography.X509Certificates.X509Store($certStore,$certRootStore)    
 	$store.open("MaxAllowed")    
 	$store.add($pfx)    
 	$store.close()    
 } 
  
 function Remove-Certificate 
 {
 	param(
		[String] $subject,
		[String] $certRootStore = "LocalMachine",
		[String] $certStore = "My"
    )

	$cert = Get-ChildItem -path cert:\$certRootStore\$certStore | where { $_.Subject.ToLower().Contains($subject) }

	$store = new-object System.Security.Cryptography.X509Certificates.X509Store($certStore,$certRootStore)
	
	$store.Open("ReadWrite")
	$store.Remove($cert)
	$store.Close()
	
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

function Gen-Passwords
{
	param (
		[int] $number = 10,
		[int] $length = 16,
		[switch] $hash
	)

	[void][Reflection.Assembly]::LoadWithPartialName("System.Web")
	$algorithm = 'sha256'

	$passwords = @()
	for( $i=0; $i -lt $number; $i++)
	{
		$pass = [System.Web.Security.Membership]::GeneratePassword($length,1)
		if( $hash ) {
			$hasher = [System.Security.Cryptography.HashAlgorithm]::create($algorithm)
			$computeHash = $hasher.ComputeHash( [Text.Encoding]::UTF8.GetBytes( $pass.ToString() ) )
			$pass = ( ([system.bitconverter]::tostring($computeHash)).Replace("-","") )
		}
		$passwords += $pass
	}
	return $passwords
}


$AutoUpdateNotificationLevels= @{0="Not configured"; 1="Disabled" ; 2="Notify before download"; 3="Notify before installation"; 4="Scheduled installation"}
$AutoUpdateDays=@{0="Every Day"; 1="Every Sunday"; 2="Every Monday"; 3="Every Tuesday"; 4="Every Wednesday";5="Every Thursday"; 6="Every Friday"; 7="EverySaturday"}
function Get-WindowsUpdateConfig
{

	$AUSettings = (New-Object -com "Microsoft.Update.AutoUpdate").Settings
	$AUObj = New-Object -TypeName System.Object
	Add-Member -inputObject $AuObj -MemberType NoteProperty -Name "NotificationLevel" -Value $AutoUpdateNotificationLevels[$AUSettings.NotificationLevel]
	Add-Member -inputObject $AuObj -MemberType NoteProperty -Name "UpdateDays"  -Value $AutoUpdateDays[$AUSettings.ScheduledInstallationDay]
	Add-Member -inputObject $AuObj -MemberType NoteProperty -Name "UpdateHour"  -Value $AUSettings.ScheduledInstallationTime 
	Add-Member -inputObject $AuObj -MemberType NoteProperty -Name "Recommended updates" -Value $(IF ($AUSettings.IncludeRecommendedUpdates) {"Included."}  else {"Excluded."})
	return $AuObj
} 

function Get-SystemGAC( [string[]] $servers )
{
	$sb = {
		$assemblies = @()
		$util = "D:\Utils\gacutil.exe"
		
		if( Test-Path $util ) {
			foreach( $dll in (&$util /l | where { $_ -imatch "culture" } | Sort) ) {
				$dll -imatch "(.*),\sVersion=(.*),\sCulture=(.*),\sPublicKeyToken=(.*),\sprocessorArchitecture=(.*)" | Out-Null				
				$assemblies += (New-Object PSObject -Property @{	
					DllName = $matches[1].TrimStart()
					Version = $matches[2]
					PublicKeyToken = $matches[3]
					Architecture = $matches[4]
				})
			}
		}
		else {
			throw "Could not find gacutil.exe"
		}
		
		return $assemblies
	}
	
	if( $servers -imatch $ENV:COMPUTERNAME ) {
		return &$sb
	}
	else {
		return ( Invoke-Command -Computer $servers -ScriptBlock $sb )
	}
}

function Get-LocalAdmins( [string] $computer )
{
	$adsi  = [ADSI]("WinNT://" + $computer + ",computer") 
	$Group = $adsi.psbase.children.find("Administrators") 
	$members = $Group.psbase.invoke("Members") | %{$_.GetType().InvokeMember("Name", 'GetProperty', $null, $_, $null)} 
	
	return $members
}

function Get-LocalGroup( [string] $computer,[string] $Group )
{
	$adsi  = [ADSI]("WinNT://" + $computer + ",computer") 
	$adGroup = $adsi.psbase.children.find($group) 
	$members = $adGroup.psbase.invoke("Members") | %{$_.GetType().InvokeMember("Name", 'GetProperty', $null, $_, $null)} 
	
	return $members
}

function Add-ToLocalGroup( [string] $computer, [string] $LocalGroup, [string] $DomainGroup )
{
    $domain_controller = ([ADSI]'').name
    $aslocalGroup = [ADSI]"WinNT://$computer/$LocalGroup,group"
    $aslocalGroup.Add("WinNT://$domain_controller/$DomainGroup,group")
}

function Add-LocalAdmin( [string] $computer, [string] $Group )
{
	$domain_controller = ([ADSI]'').name
    $localGroup = [ADSI]"WinNT://$computer/Administrators,group"
    $localGroup.Add("WinNT://$domain_controller/$Group,group")
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


function Audit-IISServers([String[]] $Servers )
{
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


function Audit-Server( [String] $server )
{
	$audit = New-Object System.Object
	$computer = Get-WmiObject Win32_ComputerSystem -ComputerName $server
	$os = Get-WmiObject Win32_OperatingSystem -ComputerName $server
	$bios = Get-WmiObject Win32_BIOS -ComputerName $server
	$nics = Get-WmiObject Win32_NetworkAdapterConfiguration -ComputerName $server
	$cpu = Get-WmiObject Win32_Processor -ComputerName $server | select -first 1 MaxClockSpeed,NumberOfCores
	$disks = Get-WmiObject Win32_LogicalDisk -ComputerName $server
	
	$audit | add-member -type NoteProperty -name SystemName -Value $computer.Name
	$audit | add-member -type NoteProperty -name Domain -Value $computer.Domain		
	$audit | add-member -type NoteProperty -name Model -Value ($computer.Manufacturer + " " + $computer.Model.TrimEnd())
	$audit | add-member -type NoteProperty -name Processor -Value ("{0}({1}) x {2} GHz" -f $computer.NumberOfProcessors.toString(), $cpu.NumberOfCores.toString(), ($cpu.MaxClockSpeed/1024).toString("#####.#"))
	$audit | add-member -type NoteProperty -name Memory -Value ($computer.TotalPhysicalMemory/1gb).tostring("#####.#")
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

function Create-WindowsService([string[]] $Servers, [string] $Path, [string] $Service, [string] $User, [string] $Pass)
{
	$class = "Win32_Service"
	$method = "Create"
	
	foreach( $server in $servers ) {
		$mc = [wmiclass]"\\$server\ROOT\CIMV2:$class"
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

function Get-IPAddress ( [string] $name )
{
    process { 
         try { [System.Net.DNS]::GetHostAddresses($name) | Select -Expand IPAddressToString  } catch { } 
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


function Add-UsersToServer {
    param
    (
        [String[]] $servers = $(throw ' You must input at least one server'),
        [string] $username = $(throw ' You must enter a username to check for')
    )

    $creds = Get-Credential -Credential $username
    $user = $creds.UserName.Split("\")[1]
    
    foreach ( $server in $servers) {
        if( -not ( Get-LocalAdmins -Computer $server | ? { $_ -imatch $user } ) ) {
			Write-Host "Adding $user to " $_
			Add-LocalAdmin -Computer $_ -Group $user
		}
        else {
            Write-Host "$user already exists"
		}
    }

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
    csname         : OAKL-PBN4CLC
    LastBootUpTime : 11/6/2014 8:14:49 AM
        
    System (localhost) has been online since :  0 days 4 hours 20 minutes 37 seconds
#>
function Get-SystemUptime
{	
	param(
		[string] $ComputerName = "localhost"
		)
		# PowerShell 3.0 - Use this if you want to not query WMI.
			#Get-CimInstance -ClassName win32_operatingsystem | select csname, lastbootuptime
		# PowerShell 2.0
			Get-WmiObject -ComputerName $ComputerName win32_operatingsystem | select csname, @{LABEL='LastBootUpTime';EXPRESSION={$_.ConverttoDateTime($_.lastbootuptime)}} | fl csname, lastbootuptime
			Get-Uptime $ComputerName
}
<#
.SYNOPSIS
 Gets the installed software on a x64 host.
.EXAMPLE
 There are no examples yet. :(
#>
function Get-InstalledSoftware_x64
{
    param(
        [Parameter(Mandatory=$true)]
        [string] $Computer = "localhost"
        )
        #Get-ItemProperty HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Select-Object DisplayName, DisplayVersion, Publisher, InstallDate | where {$_.DisplayName -like "*$softwaretitle*"} | ft -AutoSize
        Get-ItemProperty HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Select-Object DisplayName, DisplayVersion, Publisher, InstallDate | ft -AutoSize
}
function Get-InstalledSoftware_multihosts
{
    param(
        [String] $Computers = "localhost",
        [String] $SoftwareTitle = "*"
        )    
        Invoke-Command -ComputerName $Computers -ScriptBlock {
            $Applications = Get-ItemProperty HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*
            $SpecificApplication = $Applications | where {$_.DisplayName -like "$SoftwareTitle"}
            $Results = "$Applications | Select-Object DisplayName, DisplayVersion, Publisher, InstallDate | ft autosize"
            Write-Host "$Results"
        }
}

function Enter-PSSessionCredSSP
{
    param(
        [string] $Computer
    )
    Enter-PSSession -ComputerName $Computer -Authentication Credssp -Credential $env:USERDOMAIN\$env:USERNAME
}
