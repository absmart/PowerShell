function Get-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	param
	(
		[ValidateSet("true","false")]
		[System.String]
		$AllowRemoteShellAccess = "true"
	)

    $returnValue = @{}    
    $returnValue.AllowRemoteShellAccess = Get-Item WSMan:\localhost\Shell\AllowRemoteShellAccess | Select Value -ExpandProperty Value
    $returnValue.IdleTimeout = Get-Item WSMan:\localhost\Shell\IdleTimeout | Select Value -ExpandProperty Value
    $returnValue.MaxConcurrentUsers = Get-Item WSMan:\localhost\Shell\MaxConcurrentUsers | Select Value -ExpandProperty Value
    $returnValue.MaxProcessesPerShell = Get-Item WSMan:\localhost\Shell\MaxProcessesPerShell | Select Value -ExpandProperty Value
    $returnValue.MaxMemoryPerShellMB = Get-Item WSMan:\localhost\Shell\MaxMemoryPerShellMB | Select Value -ExpandProperty Value
    $returnValue.MaxShellsPerUser = Get-Item WSMan:\localhost\Shell\MaxShellsPerUser | Select Value -ExpandProperty Value

    $returnValue
}


function Set-TargetResource
{
	[CmdletBinding()]
	param
	(
		[parameter(Mandatory = $true)]
		[ValidateSet("true","false")]
		[System.String]
		$AllowRemoteShellAccess = "true",

		[System.String]
		$IdleTimeout,

		[System.String]
		$MaxConcurrentUsers,

		[System.String]
		$MaxProcessesPerShell,

		[System.String]
		$MaxMemoryPerShellMB,

		[System.String]
		$MaxShellsPerUser
	)

    Write-Verbose "Configuring Wsman provider AllowRemoteShellAccess value to $AllowRemoteShellAccess."
    Set-Item WSMan:\localhost\Shell\AllowRemoteShellAccess -Value $AllowRemoteShellAccess

    if($IdleTimeout)
    {
        Write-Verbose "Configuring Wsman provider IdleTimeout value to $IdleTimeout."
        Set-Item WSMan:\localhost\Shell\IdleTimeout -Value $IdleTimeout 
    }
    if($MaxConcurrentUsers)
    {
        Write-Verbose "Configuring Wsman provider MaxConcurrentUsers value to $MaxConcurrentUsers."
        Set-Item WSMan:\localhost\Shell\MaxConcurrentUsers -Value $MaxConcurrentUsers 
    }
    if($MaxProcessesPerShell)
    {
        Write-Verbose "Configuring Wsman provider MaxProcessesPerShell value to $MaxProcessesPerShell."
        Set-Item WSMan:\localhost\Shell\MaxProcessesPerShell -Value $MaxProcessesPerShell 
    }
    if($MaxMemoryPerShellMB)
    {
        Write-Verbose "Configuring Wsman provider MaxMemoryPerShellMB value to $MaxMemoryPerShellMB."
        Set-Item WSMan:\localhost\Shell\MaxMemoryPerShellMB -Value $MaxMemoryPerShellMB 
    }
    if($MaxShellsPerUser)
    {
        Write-Verbose "Configuring Wsman provider MaxShellsPerUser value to $MaxShellsPerUser."
        Set-Item WSMan:\localhost\Shell\MaxShellsPerUser -Value $MaxShellsPerUser 
    }
}


function Test-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Boolean])]
	param
	(
		[parameter(Mandatory = $true)]
		[ValidateSet("true","false")]
		[System.String]
		$AllowRemoteShellAccess = "true",

		[System.String]
		$IdleTimeout,

		[System.String]
		$MaxConcurrentUsers,

		[System.String]
		$MaxProcessesPerShell,

		[System.String]
		$MaxMemoryPerShellMB,

		[System.String]
		$MaxShellsPerUser
	)


    $Value = Get-TargetResource

    $ResultValues = @{}

    if($Value.AllowRemoteShellAccess -eq $AllowRemoteShellAccess)
    {
        $ResultValues.AllowRemoteShellAccess = $true
    } 
    else 
    { 
        $ResultValues.AllowRemoteShellAccess = $false
    }
    
    if($IdleTimeout)
    {
        if($Value.IdleTimeout -eq $IdleTimeout)
        {
            $ResultValues.IdleTimeout = $true
        }
        else
        {
            $ResultValues.IdleTimeout = $false
        }
    }
    else{ $ResultValues.IdleTimeout = $true }

    if($MaxConcurrentUsers)
    {
        if($Value.MaxConcurrentUsers -eq $MaxConcurrentUsers)
        {
            $ResultValues.MaxConcurrentUsers = $true
        }
        else
        {
            $ResultValues.MaxConcurrentUsers = $false
        }
    }
    else{ $ResultValues.MaxConcurrentUsers = $true }

    if($MaxProcessesPerShell)
    {
        if($Value.MaxProcessesPerShell -eq $MaxProcessesPerShell)
        {
            $ResultValues.MaxProcessesPerShell = $true
        }
        else
        {
            $ResultValues.MaxProcessesPerShell = $false
        }
    }
    else{ $ResultValues.MaxProcessesPerShell = $true }

    if($MaxMemoryPerShellMB)
    {
        if($Value.MaxMemoryPerShellMB -eq $MaxMemoryPerShellMB)
        {
            $ResultValues.MaxMemoryPerShellMB = $true
        }
        else
        {
            $ResultValues.MaxMemoryPerShellMB = $false
        }
    }
    else{ $ResultValues.MaxMemoryPerShellMB = $true }

    if($MaxShellsPerUser)
    {
        if($Value.MaxShellsPerUser -eq $MaxShellsPerUser)
        {
            $ResultValues.MaxShellsPerUser = $true
        }
        else
        {
            $ResultValues.MaxShellsPerUser = $false
        }
    }
    else{ $ResultValues.MaxShellsPerUser = $true }



    if(        
        $ResultValues.AllowRemoteShellAccess -eq $false -or
        $ResultValues.IdleTimeout -eq $false -or
        $ResultValues.MaxConcurrentUsers -eq $false -or
        $ResultValues.MaxProcessesPerShell -eq $false -or
        $ResultValues.MaxMemoryPerShellMB -eq $false -or
        $ResultValues.MaxShellsPerUser -eq $false
    )
    {
        Write-Verbose "One or more tests failed."
        [System.Boolean]$Result = $False
    }
    else
    {
        Write-Verbose "All tests passed!"
        [System.Boolean]$Result = $True
    }
}


Export-ModuleMember -Function *-TargetResource

