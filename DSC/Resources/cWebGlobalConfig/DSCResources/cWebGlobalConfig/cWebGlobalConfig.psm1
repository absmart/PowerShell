function Get-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	param
	(
		[parameter(Mandatory = $true)]
		[ValidateSet("TraceFailedReqLogDirectory","LogFileDirectory","BinaryLogFileDirectory","W3CLogFileDirectory","LogExtFileFlags","ConfigHistoryPath","AspDiskTemplateCacheDirectory","IisCompressedFilesDirectory","LocalTimeRollover")]
		[System.String]
		$Setting
	)
    
    switch ($Setting)
    {
        "TraceFailedReqLogDirectory"
        {
            $Value = Get-WebConfigurationProperty "/system.applicationHost/sites/siteDefaults" -Name traceFailedRequestsLogging.directory | Select Value -ExpandProperty Value
        }
        "LogFileDirectory"            
        {
            $Value = Get-WebConfigurationProperty "/system.applicationHost/sites/siteDefaults" -Name logfile.directory | Select Value -ExpandProperty Value
        }
        "BinaryLogFileDirectory"
        {
            $Value = Get-WebConfigurationProperty "/system.applicationHost/log" -Name centralBinaryLogFile.directory | Select Value -ExpandProperty Value
        }
        "W3CLogFileDirectory"
        {
            $Value = Get-WebConfigurationProperty "/system.applicationHost/log" -Name centralW3CLogFile.directory | Select Value -ExpandProperty Value
        }
        "LogExtFileFlags"
        {
            $Value = Get-WebConfigurationProperty "/system.applicationHost/sites/siteDefaults" -Name logfile.logExtFileFlags
        }
        "ConfigHistoryPath"
        {
            $Value = Get-WebConfigurationProperty "/system.applicationhost/configHistory" -Name path | Select Value -ExpandProperty Value
        }
        "AspDiskTemplateCacheDirectory"
        {
            $Value = Get-WebConfigurationProperty "/system.webServer/asp" -Name cache.disktemplateCacheDirectory | Select Value -ExpandProperty Value
        }
        "IisCompressedFilesDirectory"
        {
            $Value = Get-WebConfigurationProperty "/system.webServer/httpCompression" -Name directory | Select Value -ExpandProperty Value
        }
        "LocalTimeRollover"
        {
            $Value = Get-WebConfigurationProperty "system.applicationHost/sites/siteDefaults" -Name logfile.localTimeRollover | Select Value -ExpandProperty Value
        }
    }
    
    $returnValue = @{
        Setting = $Setting
        Value = $Value
    }

    $returnValue	
}


function Set-TargetResource
{
	[CmdletBinding()]
	param
	(
		[parameter(Mandatory = $true)]
		[ValidateSet("TraceFailedReqLogDirectory","LogFileDirectory","BinaryLogFileDirectory","W3CLogFileDirectory","LogExtFileFlags","ConfigHistoryPath","AspDiskTemplateCacheDirectory","IisCompressedFilesDirectory","LocalTimeRollover")]
		[System.String]
		$Setting,

		[System.String]
		$Value
	)
    
    switch ($Setting)
    {
        "TraceFailedReqLogDirectory"
        {
            Set-WebConfigurationProperty "/system.applicationHost/sites/siteDefaults" -Name traceFailedRequestsLogging.directory -Value $Value
        }
        "LogFileDirectory"            
        {
            Set-WebConfigurationProperty "/system.applicationHost/sites/siteDefaults" -Name logfile.directory -Value $Value
        }
        "BinaryLogFileDirectory"
        {
            Set-WebConfigurationProperty "/system.applicationHost/log" -Name centralBinaryLogFile.directory -Value $Value
        }
        "W3CLogFileDirectory"
        {
            Set-WebConfigurationProperty "/system.applicationHost/log" -Name centralW3CLogFile.directory -Value $Value
        }
        "LogExtFileFlags"
        {
            Set-WebConfigurationProperty "/system.applicationHost/sites/siteDefaults" -Name logfile.logExtFileFlags -Value $Value
        }
        "ConfigHistoryPath"
        {
            Set-WebConfigurationProperty "/system.applicationhost/configHistory" -Name path -Value $Value
        }
        "AspDiskTemplateCacheDirectory"
        {
            Set-WebConfigurationProperty "/system.webServer/asp" -Name cache.disktemplateCacheDirectory -Value $Value
        }
        "IisCompressedFilesDirectory"
        {
            Set-WebConfigurationProperty "/system.webServer/httpCompression" -Name directory -Value $Value
        }
        "LocalTimeRollover"
        {
            Set-WebConfigurationProperty "system.applicationHost/sites/siteDefaults" -Name logfile.localTimeRollover -Value $Value
        }
    }
    
    Write-Verbose "Set Web Configuration Property $Setting to $Value."

}


function Test-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Boolean])]
	param
	(
		[parameter(Mandatory = $true)]
		[ValidateSet("TraceFailedReqLogDirectory","LogFileDirectory","BinaryLogFileDirectory","W3CLogFileDirectory","LogExtFileFlags","ConfigHistoryPath","AspDiskTemplateCacheDirectory","IisCompressedFilesDirectory","LocalTimeRollover")]
		[System.String]
		$Setting,

		[System.String]
		$Value
	)

    switch ($Setting)
    {
        "TraceFailedReqLogDirectory"
        {
            $GetValue = Get-WebConfigurationProperty "/system.applicationHost/sites/siteDefaults" -Name traceFailedRequestsLogging.directory | Select Value -ExpandProperty Value
            Write-Verbose "TraceFailedReqLogDirectory is configured as '$GetValue'."
            if($GetValue -eq $Value)
            {
                $Result = $true
            }
            else
            {
                $Result = $false
            }
        }

        "LogFileDirectory"            
        {
            $GetValue = Get-WebConfigurationProperty "/system.applicationHost/sites/siteDefaults" -Name logfile.directory | Select Value -ExpandProperty Value
            Write-Verbose "LogFileDirectory is configured as '$GetValue'."
            if($GetValue -eq $Value)
            {
                $Result = $true
            }
            else
            {
                $Result = $false
            }        
        }

        "BinaryLogFileDirectory"
        {
            $GetValue = Get-WebConfigurationProperty "/system.applicationHost/log" -Name centralBinaryLogFile.directory | Select Value -ExpandProperty Value
            Write-Verbose "BinaryLogFileDirectory is configured as '$GetValue'."
            if($GetValue -eq $Value)
            {
                $Result = $true
            }
            else
            {
                $Result = $false
            }
        }

        "W3CLogFileDirectory"
        {
            $GetValue = Get-WebConfigurationProperty "/system.applicationHost/log" -Name centralW3CLogFile.directory | Select Value -ExpandProperty Value
            Write-Verbose "W3CLogFileDirectory is configured as '$GetValue'."
            if($GetValue -eq $Value)
            {
                $Result = $true
            }
            else
            {
                $Result = $false
            }
        }
        "LogExtFileFlags"
        {
            $GetValue = Get-WebConfigurationProperty "/system.applicationHost/sites/siteDefaults" -Name logfile.logExtFileFlags
            Write-Verbose "LogExtFileFlags is configured as '$GetValue'."
            if($GetValue -eq $Value)
            {
                $Result = $true
            }
            else
            {
                $Result = $false
            }
        }
        "ConfigHistoryPath"
        {
            $GetValue = Get-WebConfigurationProperty "/system.applicationhost/configHistory" -Name path | Select Value -ExpandProperty Value
            Write-Verbose "ConfigHistoryPath is configured as '$GetValue'."
            if($GetValue -eq $Value)
            {
                $Result = $true
            }
            else
            {
                $Result = $false
            }
        }
        "AspDiskTemplateCacheDirectory"
        {
            $GetValue = Get-WebConfigurationProperty "/system.webServer/asp" -Name cache.disktemplateCacheDirectory | Select Value -ExpandProperty Value
            Write-Verbose "AspDiskTemplateCacheDirectory is configured as '$GetValue'."
            if($GetValue -eq $Value)
            {
                $Result = $true
            }
            else
            {
                $Result = $false
            }
        }
        "IisCompressedFilesDirectory"
        {
            $GetValue = Get-WebConfigurationProperty "/system.webServer/httpCompression" -Name directory | Select Value -ExpandProperty Value
            Write-Verbose "IisCompressedFilesDirectory is configured as '$GetValue'."
            if($GetValue -eq $Value)
            {
                $Result = $true
            }
            else
            {
                $Result = $false
            }
        }
        "LocalTimeRollover"
        {
            $GetValue = Get-WebConfigurationProperty "system.applicationHost/sites/siteDefaults" -Name logfile.localTimeRollover | Select Value -ExpandProperty Value
            Write-Verbose "LocalTimeRollover is configured as '$GetValue'."
            if($GetValue -eq $Value)
            {
                $Result = $true
            }
            else
            {
                $Result = $false
            }
        }
    }

    $Result	
}