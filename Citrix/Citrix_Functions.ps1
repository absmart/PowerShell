Import-Module -Name (Join-PATH $env:POWERSHELL_HOME "Citrix\Modules\PvsPSSnapin.dll")
Import-Module -Name (Join-PATH $env:POWERSHELL_HOME "Citrix\Modules\Citrix.Common.Commands.Data.dll")
Import-Module -Name (Join-PATH $env:POWERSHELL_HOME "Citrix\Modules\Citrix.Common.Commands.dll")
Import-Module -Name (Join-PATH $env:POWERSHELL_HOME "Citrix\Modules\BrokerSnapin.dll")
Import-Module -Name (Join-Path $env:POWERSHELL_HOME "Libraries\General_Variables.psm1")

function Get-XAAppReport
{
	param(
		[string] $ApplicationName,
        [ValidateSet("Equals","Matches")] [string] $Match,
		[string] $DataCollector = $citrix_environment.Farm01.DATA_COLLECTOR
	)
	Invoke-Command -ComputerName $DataCollector -ArgumentList $AppName, $Match -Scriptblock{
		param(
			$AppName,
            $Match
		)
		Add-PSSnapin -Name Citrix.XenApp.Commands        
        $Result = $null        
        switch ($Match)
        {
            "Equals"  { $Result = Get-XAApplication | Where-Object {$_.BrowserName -eq $AppName} | Get-XAApplicationReport }
            "Matches" { $Result = Get-XAApplication | Where-Object {$_.BrowserName -match $AppName} | Get-XAApplicationReport }
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
    return $Servers | Sort-Object -Property ServerName | Select-Object ServerName 
}

function Get-XAServerLoadByEnv
{
    param(
		[ValidateSet("7.6","6.0","4.5.1")] [string] $CitrixEnvironment
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
        "4.5.1" {
            [string] $XAServer = $citrix_environment.Farm03.DATA_COLLECTOR
            Invoke-Command -ComputerName $XAServer -ScriptBlock{
                qfarm /load
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
                Select-Object @{Name="Date";Expression={Get-Date -Format s}}, AccountDisplayName, ProcessName, SessionId, ProcessId, ServerName, CreationTime, PercentCPULoad, @{Name="Memory (in MB)";Expression={($_.CurrentWorkingSetSize/1mb)}} | Format-Table
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
		
			#Add-PSSnapIn -Name Citrix.Common.Commands -ErrorAction SilentlyContinue
			Add-PSSnapin -Name Citrix.XenApp.Commands -ErrorAction SilentlyContinue

			$Details = Get-XAApplication $Application | Get-XAAccount | Select AccountDisplayName, AccountType, SearchPath

			return $Details
		}
}


function Get-XASession
{
    param(
        [string] $UserName,
        [string] $ComputerName = $citrix_environment.Farm01.DATA_COLLECTOR,
        [string] $UserDomain = $citrix_environment.Farm01.Domain,
        [string] $Application = $null
    )

    Invoke-Command -ComputerName $ComputerName -ArgumentList $UserName, $UserDomain -ScriptBlock {
        param(
            [string] $UserName,
            [string] $UserDomain
        )

        Add-PSSnapin -Name Citrix.XenApp.Commands

        if($UserName -imatch $UserDomain)
        {
            $Account = $UserName
            $Sessions = Get-XASession -Account $Account
        }
        else
        {
            $Account = Join-Path $UserDomain\ $UserName
            $Sessions = Get-XASession -Account $Account
        }

        return $Sessions | Format-Table
    }
}

function Stop-XASession
{
    param(
        [string] $UserName,
        [string] $ComputerName = $citrix_environment.Farm01.DATA_COLLECTOR,
        [string] $UserDomain = $citrix_environment.Farm01.Domain
    )

    Invoke-Command -ComputerName $ComputerName -ArgumentList $UserName, $UserDomain -ScriptBlock {
        param(
            [string] $UserName,
            [string] $UserDomain
        )

        Add-PSSnapin -Name Citrix.XenApp.Commands

        if($UserName -imatch $UserDomain)
        {
            $Account = $UserName
            $Sessions = Get-XASession -Account $Account
        }
        else
        {
            $Account = Join-Path $UserDomain\ $UserName
            $Sessions = Get-XASession -Account $Account
        }

        try
        {
            $Sessions | Stop-XASession
            Write-Output "The following sessions have been stopped." -ForegroundColor Green
            return $Sessions | Format-Table
        }
        catch
        {
            Write-Output "No sessions found for $Account." -ForegroundColor Yellow
            return $Sessions | Format-Table
        }
    }
}

function Restart-IMAService
{
    param(
        [string] $ComputerName = "localhost"
        
        if($Computer -eq "localhost"){
            Restart-Service -Name IMAService -Force -Verbose
        }
        else{
            Invoke-Command -ComputerName $ComputerName -ScriptBlock{
                Restart-Service -Name IMAService -Force -Verbose
            }
        }
    )
}

function Set-XAServiceRecovery{
    param(
        $ComputerName
    )
    Invoke-Command -ComputerName $ComputerName -ScriptBlock{
        sc.exe failure cpsvc reset= 86400 actions= restart/5000/restart/5000/restart/5000
        sc.exe failure Imaservice reset= 86400 actions= restart/5000/restart/5000/restart/5000
    }
}

function Get-XAWindowsEvent
{
    param(
        $ComputerName,
        [System.Int32] $Days = "1"
    )
    $YDate = (Get-Date.AddDays(-$Days))    
    $Results += Invoke-Command -ComputerName $XAServers -ArgumentList $YDate -ScriptBlock{
        param(
            $YDate
        )    
        $TDate = (Get-Date)        
        $Events += Get-EventLog -LogName System -Source IMAService -After $YDate -Before $TDate -EntryType Warning -ErrorAction SilentlyContinue
        $Events += Get-EventLog -LogName System -Source IMAService -After $YDate -Before $TDate -EntryType Error -ErrorAction SilentlyContinue
        $Events += Get-EventLog -LogName System -Source CitrixHealthMon -After $YDate -Before $TDate -EntryType Warning -ErrorAction SilentlyContinue
        $Events += Get-EventLog -LogName System -Source CitrixHealthMon -After $YDate -Before $TDate -EntryType Error -ErrorAction SilentlyContinue
        $Events += Get-EventLog -LogName System -Source Metaframe -After $YDate -Before $TDate -EntryType Warning -ErrorAction SilentlyContinue
        $Events += Get-EventLog -LogName System -Source Metaframe -After $YDate -Before $TDate -EntryType Error -ErrorAction SilentlyContinue
        return $Events
    }
    return $Results
}

function Get-XATrendingByUser
{
    param(
        $User = $null
    )
    $Columns = @()
    $Server = $citrix_environment.Logging.LoggingServerName
    $Database = $citrix_environment.Logging.XenAppLogging
    if($User -eq $null){
        $tSQL = "SELECT TOP 50 [Date],[AccountDisplayName],[ProcessName],[SessionId],[ProcessId],[XAServer],[CreationTime],[MemoryUsedInMB] FROM [CitrixLogging].[dbo].[SessionProcesses] ORDER BY DATE DESC"
    }
    else{
        $tSQL = "SELECT TOP 50 [Date],[AccountDisplayName],[ProcessName],[SessionId],[ProcessId],[XAServer],[CreationTime],[MemoryUsedInMB] FROM [CitrixLogging].[dbo].[SessionProcesses] WHERE AccountDisplayName LIKE '%$User%' ORDER BY DATE DESC"
    }

    $Connection = "Server=$Server;Integrated Security=true;Initial Catalog=$Database"
    $DataSet = New-Object "System.Data.DataSet" "DataSet"
    $DataAdapter = New-Object "System.Data.SqlClient.SqlDataAdapter" ($Connection)
    $DataAdapter.SelectCommand.CommandText = $tSQL
    $DataAdapter.SelectCommand.Connection = $Connection

    $DataAdapter.Fill($DataSet) | Out-Null
    $DataSet.Tables[0].Columns | Select ColumnName | Foreach-Object { $Columns += $_.ColumnName }
    $Results = $DataSet.Tables[0].Rows | Select $Columns

    $DataSet.Clear()
    $DataAdapter.Dispose()
    $DataSet.Dispose()

    return $Results
}