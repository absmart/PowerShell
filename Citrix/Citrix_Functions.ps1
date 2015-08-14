Import-Module (Join-PATH $env:POWERSHELL_HOME "Citrix\Modules\PvsPSSnapin.dll")
Import-Module (Join-PATH $env:POWERSHELL_HOME "Citrix\Modules\Citrix.Common.Commands.Data.dll")
Import-Module (Join-PATH $env:POWERSHELL_HOME "Citrix\Modules\Citrix.Common.Commands.dll")
Import-Module (Join-PATH $env:POWERSHELL_HOME "Citrix\Modules\BrokerSnapin.dll")
Import-Module (Join-Path $env:POWERSHELL_HOME "Libraries\General_Variables.psm1")

function Get-XAAppReport
{
	param(
		[string] $AppName,
        [ValidateSet("Equals","Matches")] [string] $Match,
		[string] $DataCollector = $citrix_environment.Farm01.DATA_COLLECTOR
	)
	Invoke-Command -ComputerName $DataCollector -ArgumentList $AppName, $Match -Scriptblock{
		param(
			$AppName,
            $Match
		)
		Add-PSSnapin Citrix.XenApp.Commands

        switch ($Match)
        {
            "Equals"  { $Result = Get-XAApplication | Where {$_.BrowserName -eq $AppName} | Get-XAApplicationReport }
            "Matches" { $Result = Get-XAApplication | Where {$_.BrowserName -match $AppName} | Get-XAApplicationReport }
        }
        return $Result
	}
}

function Get-XAServers
{
    param(
        [string] $ComputerName = $citrix_environment.Farm01.DATA_COLLECTOR
    )
    $Servers = Invoke-Command -ComputerName $ComputerName -ScriptBlock {
        Add-PSSnapin Citrix.XenApp.Commands
        Get-XAServer
    }
    return $Servers | Sort -Property ServerName | Select ServerName 
}

function Get-XAServerLoadByEnv
{
    param(
		[ValidateSet("7.6","6.0")] [string] $CitrixEnvironment
    )
	switch ($CitrixEnvironment)
	{
		"7.6" {
            $ServerLoad = Get-BrokerMachine -AdminAddress $citrix_environment.Farm02.WEBSERVICEURL -DeliveryType AppsOnly -Property 'DNSName','LoadIndex','SessionCount'
            return $ServerLoad | Select @{Name="XAServer";Expression={$_.DNSName.TrimEnd("domain.com")}},@{Name="Date";Expression={Get-Date}},@{Name="ServerLoad";Expression={($_.LoadIndex)}},@{Name="ServerLoadPercent";Expression={($_.LoadIndex/10000)*100}} | Sort-Object XAServer
        }
	
        "6.0" {
			[string] $XAServer = $citrix_environment.Farm01.DATA_COLLECTOR
			Invoke-Command -ComputerName $XAServer -ScriptBlock{
				Add-PSSnapin Citrix.XenApp.Commands
				$Results = Get-XAServerLoad | Select @{Name="XAServer";Expression={$_.ServerName}},@{Name="Date";Expression={Get-Date}},@{Name="ServerLoad";Expression={$_.Load}},@{Name="ServerLoadPercent";Expression={($_.Load/10000)*100}} | Sort-Object XAServer
				return $Results
            }
		}
    }
}
Set-Alias -Name XALoad -Value Get-XAServerLoadByEnv

function Get-XAServerDiskSpace
{
    param(
        [string] $ComputerName,
        [string] $Partition
    )
    Get-WmiObject -Class "Win32_Volume" -Namespace "root\cimv2" -ComputerName $ComputerName |
	    where { $_.Name -eq $Partition } | 
        Select @{Name="Server";Expression={$ComputerName}},@{Name="Partition";Expression={$_.Name}}, @{Name="TotalDiskSpace";Expression={$_.Capacity/1mb}}, @{Name="FreeDiskSpace";Expression={$_.FreeSpace/1mb}}
}

function Get-XASessionCount
{
    param(
        [string] $ComputerName = $citrix_environment.Farm01.DATA_COLLECTOR
    )

    Invoke-Command -ComputerName $ComputerName -ScriptBlock{
        Add-PSSnapin Citrix.XenApp.Commands
        $Sessions = Get-XASession
        return $Sessions.Count
    }
}

function Get-XAApplicationUsage
{
    param(
        [string] $ProcessName,
        [string] $XAServer = $citrix_environment.Farm01.DATA_COLLECTOR
    )

    Invoke-Command -ComputerName $XAServer -ArgumentList $ProcessName -ScriptBlock {

        param(
            [string] $Processname
        )

        Add-PSSnapin Citrix.Common.Commands -EA SilentlyContinue
        Add-PSSnapin Citrix.XenApp.Commands -EA SilentlyContinue
    
        $Servers = Get-XAServer

        foreach($Server in $Servers){
            Get-XASessionProcess -ServerName $Server | 
                Where {$_.ProcessName -match $ProcessName} |
                Select @{Name="Date";Expression={Get-Date -Format s}}, AccountDisplayName, ProcessName, SessionId, ProcessId, ServerName, CreationTime, PercentCPULoad, @{Name="Memory (in MB)";Expression={($_.CurrentWorkingSetSize/1mb)}} | FT
        }
    }
} 

function Get-XAAssignedUsersForApplication
{
    param(
        [string] $ComputerName = $citrix_environment.Farm01.DATA_COLLECTOR,
        [string] $Application
    )
	
    Invoke-Command -ComputerName $ComputerName -ArgumentList $Application -ScriptBlock {
		param(
				[string] $Application
			)
		
			Add-PSSnapIn Citrix.Common.Commands -EA SilentlyContinue
			Add-PSSnapin Citrix.XenApp.Commands -EA SilentlyContinue
		
			$Details = Get-XAApplication $Application | Get-XAAccount | Select AccountDisplayName, AccountType, SearchPath
		
			return $Details
		}
}