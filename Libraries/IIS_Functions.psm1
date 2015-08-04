Import-Module WebAdministration -ErrorAction Continue
Add-PSSnapin WebFarmSnapin -ErrorAction SilentlyContinue

Set-Variable -Name cert_path -Value 'cert:\LocalMachine\My'

function Set-AlwaysRunning
{
    param(
        [string] $app_pool
    )

    Set-ItemProperty -Path (Join-Path "IIS:\AppPools" $app_pool) -Name startMode -Value "AlwaysRunning"

}

function Set-PreLoad 
{
    param(
        [string] $site
    )

    Set-ItemProperty -Path (Join-Path "IIS:\Sites"  $site) -name applicationDefaults.preloadEnabled -value True
}

function Get-IISAppPoolDetails
{
    param(
        [string] $app_pool
    )

    if( !(Test-Path (Join-Path "IIS:\AppPools" $app_pool) ) ) {
        throw "Could not find " + $app_pool
        return -1
    }

    $details =  Get-ItemProperty -Path (Join-Path "IIS:\AppPools" $app_pool) | Select startMode, processModel, recycling,  autoStart, managedPipelineMode, managedRuntimeVersion , queueLength                                

    return (New-Object PSObject -Property @{
        UserName = $details.processModel.UserName
        IdleTimeOut = $details.processModel.IdleTimeOut
        LoadProfile = $details.processModel.SetProfileEnvironment
        PipelineMode = $details.managedPipelineMode
        DotNetVersion = $details.managedRuntimeVersion
        QueueLength = $details.queueLength
        AutoStart = $details.autoStart
        StartupMode = $details.startMode
        RecyleTimeInHours = $details.recycling.periodicRestart.time.ToString()
        RecyleMemory = $details.recycling.periodicRestart.Memory
        RecyleRequests = $details.recycling.periodicRestart.Requests
    })
}


function Get-AppPool-Requests 
{
    param(
        [string] $appPool
    )
    Set-Location "IIS:\AppPools\$appPool\WorkerProcesses"
    $process = Get-ChildItem "IIS:\AppPools\$appPool\WorkerProcesses" | Select -ExpandProperty ProcessId
    $requests = (Get-Item $process).GetRequests(0).Collection | Select requestId, connectionId, url,verb, timeElapsed

    return $requests 
}

function Get-IISWebState
{
	param(
		[String[]] $computers
	)
	
	Invoke-Command -ComputerName $computers -ScriptBlock { 
		. (Join-Path $ENV:SCRIPTS_HOME "Libraries\IIS_Functions.ps1")
		Get-WebSite | Select Name, @{Name="State";Expression={(Get-WebSiteState $_.Name).Value}}, @{Name="Computer";Expression={$ENV:ComputerName}} 
	} | Select Name, State, Computer
}

function Start-IISSite
{
	param(
		[String[]] $computers,
		[String] $site = "Default Web Site",
		[switch] $record,
		[switch] $sharepoint
		
	)
	
	Get-IISWebState $computers
	$list = "Issues Tracker"
	if ($sharepoint){
		$url = "http://teamadmin.gt.com/sites/ApplicationOperations/"
	}
	else {
		$url = "http://teamadmin.gt.com/sites/ApplicationOperations/ApplicationSupport/"
	}
	Write-Host "`nStarting $site . . . `n" -ForegroundColor blue
	
	Invoke-Command -ComputerName $computers -ScriptBlock { 
		param ( [string] $site )
		. (Join-Path $ENV:SCRIPTS_HOME "Libraries\IIS_Functions.ps1")
		Start-WebSite -name $site
    	$obj = New-Object PSObject -Property @{
        	Title = "Stop IIS " + $_
            User = $ENV:USERNAME
		    Description = "Stopping IIS for CMS WFE" + $_
	    }
	} -ArgumentList $site
	
	Get-IISWebState $computers
}

function Stop-IISSite
{
	param(
		[String[]] $computers,
		[String] $site = "Default Web Site",
		[switch] $record,
		[switch] $sharepoint
	)
	Get-IISWebState $computers
	$list = "Issues Tracker"
	if ($sharepoint){
		$url = "http://teamadmin.gt.com/sites/ApplicationOperations/"
	}
	else
	{
		$url = "http://teamadmin.gt.com/sites/ApplicationOperations/ApplicationSupport/"
	}
	Write-Host "`nStoping $site . . . `n" -ForegroundColor blue
	Invoke-Command -ComputerName $computers -ScriptBlock { 
		param ( [string] $site )
		. (Join-Path $ENV:SCRIPTS_HOME "Libraries\IIS_Functions.ps1")
		Stop-WebSite -name $site
		$obj = New-Object PSObject -Property @{
    	    Title = "Stop IIS " + $_
            User = $ENV:USERNAME
		    Description = "Stopping IIS for CMS WFE" + $_
	    }
	} -ArgumentList $site
	
	Get-IISWebState $computers
}

function Get-CustomHeaders 
{
    return ( Get-WebConfiguration //httpProtocol/customHeaders | Select -Expand Collection | Select Name, Value )
}


function Set-CustomHeader
{
    param (
        [string] $name,
        [string] $value
    )
     Add-WebConfiguration //httpProtocol/customHeaders -Value @{Name=$name;Value=$value}
}

function Add-DefaultDoc
{
	param(
		[String[]] $computers,
		[string] $site,
		[string] $file,
		[int] $pos = 0
	)
	
	Invoke-Command -ComputerName $computers -ScriptBlock { 
		param(
			[string] $site,
			[string] $file,
			[int] $pos = 0
		)
		
		. (Join-Path $ENV:SCRIPTS_HOME "Libraries\IIS_Functions.ps1")
		Add-WebConfiguration //defaultDocument/files "IIS:\sites\$site" -atIndex $pos -Value @{value=$file}
		Get-WebConfiguration //defaultDocument/files "IIS:\sites\$site" | Select -Expand Collection | Select @{Name="File";Expression={$_.Value}}
	} -ArgumentList $site, $file, $pos
}


function Create-IISWebSite
{
	param (
		[string] $site = $(throw 'A site name is required'),
		[string] $path = $(throw 'A physical path is required'),
		[string] $header = $(throw 'A host header must be supplied'),
		[int] $port = 80,
		[Object] $options = @{}
	)
	
	if( -not ( Test-Path $path) )
	{
		throw ( $path + " does not exist " )
	}

	New-WebSite -PhysicalPath $path -Name $site -Port $port  -HostHeader $header @options
}

function Create-IISWebApp
{
	param (
		[string] $site = $(throw 'A site name is required'),
		[string] $app = $(throw 'An application name is required'),
		[string] $path = $(throw 'A physical path is required'),
		[Object] $options = @{}
		
	)	
	New-WebApplication -physicalPath $path -Site $site -Name $app @options
}

function Create-IISVirtualDirectory
{
	param (
		[string] $site = $(throw 'A site name is required'),
		[string] $vdir = $(throw 'An vdir (virtual directory name) is required'),
		[string] $path = $(throw 'A physical path is required'),
		[Object] $options = @{}
	)
	
	New-WebVirtualDirectory -Site $site -Name $vdir -physicalPath $path @options
}

function Create-IISAppPool
{
	param (
		[string] $apppool = $(throw 'An AppPool name is required'),
		[string] $user,
		[string] $pass,
		
		[ValidateSet("v2.0", "v4.0")]
		[string] $version = "v2.0"
	)

	New-WebAppPool -Name $apppool

	if( -not [String]::IsNullOrEmpty($user)  ) 
	{
		if( -not [String]::IsNullOrEmpty($pass) ) 
		{
			Set-ItemProperty "IIS:\apppools\$apppool" -name processModel -value @{userName=$user;password=$pass;identitytype=3}
		}
		else 
		{
			throw ($pass + " can not be empty if the user variable is defined")
		}
	}

	if( -not [String]::IsNullOrEmpty($version) )
	{
		Set-ItemProperty "IIS:\AppPools\$apppool" -name managedRuntimeVersion $version
	}

}

function Create-IIS7AppPool
{
	param (
		[string] $apppool = $(throw 'An AppPool name is required'),
		[string] $user,
		[string] $pass,
		
		[ValidateSet("v2.0", "v4.0")]
		[string] $version = "v2.0"
	)
	$poolname = 'AppPools\'+$apppool
	New-Item $poolname
	if( -not [String]::IsNullOrEmpty($user)  ) 
	{
		if( -not [String]::IsNullOrEmpty($pass) ) 
		{
			Set-ItemProperty $poolname -name processModel -value @{userName=$user;password=$pass;identitytype=3}
		}
		else 
		{
			throw ($pass + " can not be empty if the user variable is defined")
		}
	}

	if( -not [String]::IsNullOrEmpty($version) )
	{
		Set-ItemProperty $poolname -name managedRuntimeVersion $version
	}

}

function Set-IISAppPoolforWebSite
{
	param (
		[string] $apppool = $(throw 'An AppPool name is required'),
		[string] $site = $(throw 'A site name is required'),
		[string] $vdir
	)
	if( [String]::IsNullOrEmpty($vdir) )
	{
		Set-ItemProperty "IIS:\sites\$site" -name applicationPool -value $apppool
	}
	else 
	{
		Set-ItemProperty "IIS:\sites\$site\$vdir" -name applicationPool -value $apppool
	}
}

function Set-SSLforWebApplication
{
	param (
		[string] $name,
		[string] $common_name,
        [string] $ip = "0.0.0.0",
		[Object] $options = @{}
	)

	$cert_thumbprint = Get-ChildItem -path $cert_path | Where { $_.Subject.Contains($common_name) } | Select -Expand Thumbprint

    if( $ip -eq "0.0.0.0" ) {
        New-WebBinding -Name $name -IP "*" -Port 443 -Protocol https @options
    }
    else {
        New-WebBinding -Name $name -IP $ip -Port 443 -Protocol https @options
    }

    $binding = Get-WebBinding -Name $name -Protocol https
    $binding.AddSslCertificate( [string]$cert_thumbprint, "My" )
}

function Update-SSLforWebApplication
{
	param (
		[string] $name,
		[string] $common_name
	)
	
    $cert_thumbprint = Get-ChildItem -path $cert_path | Where { $_.Subject.Contains($common_name) } | Select -Expand Thumbprint
    $binding = Get-WebBinding -Name $name -Protocol https
    $binding.RemoveSslCertificate()
    $binding.AddSslCertificate( [string]$cert_thumbprint, "My" )

}

function Set-IISLogging
{
	param (
		[string] $site = $(throw 'A site name is required'),
		[string] $path = $(throw 'A physical path is required')
	)
	
	Set-ItemProperty "IIS:\Sites\$site" -name LogFile.Directory -value $path
	Set-ItemProperty "IIS:\Sites\$site" -name LogFile.logFormat.name -value "W3C"	
	Set-ItemProperty "IIS:\Sites\$site" -name LogFile.logExtFileFlags -value 131023
}

$global:netfx = @{
	"1.1x86" = "C:\WINDOWS\Microsoft.NET\Framework\v1.1.4322\CONFIG\machine.config"; 
    "2.0x86" = "C:\WINDOWS\Microsoft.NET\Framework\v2.0.50727\CONFIG\machine.config";
	"4.0x86" = "C:\WINDOWS\Microsoft.NET\Framework\v4.0.30319\CONFIG\machine.config";
	"2.0x64" = "C:\WINDOWS\Microsoft.NET\Framework64\v2.0.50727\CONFIG\machine.config";
	"4.0x64" = "C:\WINDOWS\Microsoft.NET\Framework64\v4.0.30319\CONFIG\machine.config"
}


function Get-WebDataConnectionString {
	param ( 
		[string] $computer = ".",
		[string] $site
	)

	$connect_string = { 
		param ( [string] $site	)
		
		. (Join-Path $ENV:SCRIPTS_HOME "Libraries\IIS_Functions.ps1")
	
        if( !(Test-Path "IIS:\Sites\$site" ) ) {
            throw "Could not find $site"
            return
        }

		$connection_strings = @()
        $configs = Get-WebConfiguration "IIS:\Sites\$site" -Recurse -Filter /connectionStrings/* | 
            Select PsPath, Name, ConnectionString  |
            Where { $_.ConnectionString -imatch "data source|server" }

		foreach( $config in $configs ) {
			
            if( [string]::IsNullOrEmpty($config) ) { continue }
		
			$connection_string = New-Object PSObject -Property @{
                Path = $config.PsPath -replace ("MACHINE/WEBROOT/APPHOST")
                Name = $config.Name
                Server = [string]::Empty
                Database = [string]::Empty
                UserId = [string]::Empty
                Password = [string]::Empty
            }

            $parameters = $config.ConnectionString.Split(";")
			foreach ( $parameter in $parameters ) {	 
                $key,$value = $parameter.Split("=")

                switch -Regex ($key) {
                    "Data Source|Server" {
                        $connection_string.Server = $value	
                    }
                    "Initial Catalog|AttachDBFilename" {
                        $connection_string.Database = $value	
                    }
                    "user id" {
                        $connection_string.UserId = $value	
                    }
                    "Integrated Security" {
                        $connection_string.UserId = "ApplicationPoolIdentity"	
                        $connection_string.Password = "*" * 5
                    }
                    "password" {
                        $connection_string.Password = $value	
                    }
                }

			}
			$connection_strings += $connection_string
		}
		return $connection_strings
	}
	
	return ( Invoke-Command -Computer $computer -Scriptblock $connect_string -ArgumentList $site )
	
}

function Get-MachineKey 
{
	param (
		[string] $version = "2.0x64"
	)
	
    Write-Host "Getting machineKey for $version"
    $machineConfig = $netfx[$version]
    
    if( Test-Path $machineConfig ) { 
        $machineConfig = $netfx.Get_Item( $version )
        $xml = [xml]( Get-Content $machineConfig )
        $root = $xml.get_DocumentElement()
        $system_web = $root.system.web

        if ($system_web.machineKey -eq $nul) { 
        	Write-Host "machineKey is null for $version" -fore red
        }
        else {
            Write-Host "Validation Key: $($system_web.SelectSingleNode("machineKey").GetAttribute("validationKey"))" -Fore green
    	    Write-Host "Decryption Key: $($system_web.SelectSingleNode("machineKey").GetAttribute("decryptionKey"))" -Fore green
            Write-Host "Validation: $($system_web.SelectSingleNode("machineKey").GetAttribute("validation"))" -Fore green
        }
    }
    else { 
		Write-Host "$version is not installed on this machine" -Fore yellow 
	}
}

function Set-AppPoolLogging
{
	param (
		[string[]] $Computers = $(throw 'A computer name is required')
	)

	foreach($computer in $Computers) {
		Invoke-Command -computer $computer -script { cscript d:\inetpub\adminscripts\adsutil.vbs Set w3svc/AppPools/LogEventOnRecycle 255 }
	}
}

function Get-AppPoolLogging
{
	param (
		[string[]] $Computers = $(throw 'A computer name is required')
	)

	foreach($computer in $Computers) {
	    Invoke-Command -computer $computer -script { cscript d:\inetpub\adminscripts\adsutil.vbs Get w3svc/AppPools/LogEventOnRecycle }
	}
}

function Install-ToGacAssembly {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
	    [string] $dir
    )

    [System.Reflection.Assembly]::Load("System.EnterpriseServices, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a") | Out-Null

    Import-Module (Join-Path $ENV:SCRIPTS_HOME "Libraries\Standard_Functions.ps1")

    $gac_out_file = ".\gac_install_record.log"

    $publish = New-Object System.EnterpriseServices.Internal.Publish

    foreach( $file in (Get-ChildItem $dir -include *.dll -recurse) ) 
    {
	    $assembly = $file.FullName
	    $fileHash = get-hash1 $assembly

	    Write-Verbose "Installing: $assembly"

	    if ( [System.Reflection.Assembly]::LoadFile( $assembly ).GetName().GetPublicKey().Length -eq 0 )
	    {
		    throw "The assembly '$assembly' must be strongly signed."
	    }

	    "{0},{1},{2},{3},{4}" -f $(Get-Date), $file.Name, $file.LastWriteTime, $file.VersionInfo.ProductVersion, $fileHash | out-file -append -encoding ascii $gac_out_file    
	    $publish.GacInstall( $assembly )
    }
}