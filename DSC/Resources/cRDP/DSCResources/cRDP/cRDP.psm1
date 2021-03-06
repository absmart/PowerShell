function Get-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.Boolean]
		$AcceptRdpConnection
	)

    $fDenyTSConnections = Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\' -Name fDenyTSConnections | Select -ExpandProperty fDenyTSConnections
    $UserAuthentication = Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name UserAuthentication | Select -ExpandProperty UserAuthentication
    
    try
    {
        $Rules = Get-NetFirewallRule -DisplayGroup "Remote Desktop" | Where {$_.Enabled -eq $true}
        if($Rules.Length -gt 0)
        {
            $AddFirewallRule = $true
        }
        else
        {
            $AddFirewallRule = $false
        }
    }
    catch
    {
        Write-Error "Get-NetFirewallRule not found on the server. The Rdp firewall rule detection is only supported in Windows 2012 R2 and Windows 8.1."
    }

    if($fDenyTSConnections = 1) 
    {
        $AcceptRdpConnection = $true
    }
    else
    {
        $AcceptRdpConnection = $false
    }

    if($UserAuthentication = 1) 
    {
        $EnforceNLAuth = $true
    }
    else
    {
        $EnforceNLAuth = $false
    }

    $returnValue = @{
        AcceptRdpConnection = $AcceptRdpConnection
        EnforeNLAuth = $EnforceNLAuth
        AddFirewallRule = $AddFirewallRule
    }

	$returnValue	
}


function Set-TargetResource
{
	[CmdletBinding()]
	param
	(
		[parameter(Mandatory = $true)]
		[System.Boolean]
		$AcceptRdpConnection = $false,

		[System.Boolean]
		$EnforceNLAuth = $false,

		[System.Boolean]
		$AddFirewallRule = $false
	)

    if($AcceptRdpConnection -eq $false) { $AccetRdpConnectionValue -eq 0 }
    if($AcceptRdpConnection -eq $false) { $AccetRdpConnectionValue -eq 0 }

    if($EnforceNLAuth -eq $false) { $AcceptRdpConnectionValue -eq 0}
    if($EnforceNLAuth -eq $false) { $AcceptRdpConnectionValue -eq 0}

    if($AddFirewallRule -eq $false) { 
        try{
            Disable-NetFirewallRule -DisplayGroup "Remote Desktop" | where {$_.Enabled -eq $false}
        }
        catch
        {
            Write-Error "Disable-NetFirewallRule not found on the server. The firewall cmdlets only supported in Windows 2012 R2 and Windows 8.1."
        }
        else {
            try
            {
                Enable-NetFirewallRule -DisplayGroup "Remote Desktop" | Where {$_.Enabled -ne $true}
            }
            catch
            {
                Write-Error "Enable-NetFirewallRule not found on the server. The firewall cmdlets are only supported in Windows 2012 R2 and Windows 8.1."
            }
        }
    }

    Write-Verbose "Setting fDenyTSConnections value to $AcceptRdpConnectionValue."
    Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server' -Name fDenyTSConnections -Value $RdpConnectionValue

    Write-Verbose "Setting UserAuthentication value to $NLAuthValue."
    Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name UserAuthentication -Value $NLAuthValue
	

}


function Test-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Boolean])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.Boolean]
		$AcceptRdpConnection,

		[System.Boolean]
		$EnforceNLAuth,

		[System.Boolean]
		$AddFirewallRule
	)

    $fDenyTSConnections = Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\' -Name fDenyTSConnections | Select -ExpandProperty fDenyTSConnections
    $UserAuthentication = Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name UserAuthentication | Select -ExpandProperty UserAuthentication
    
    try
    {
        $Rules = Get-NetFirewallRule -DisplayGroup "Remote Desktop" | Where {$_.Enabled -eq $true}
        if($Rules.Length -gt 0)
        {
            $AddFirewallRuleCheck = $true
        }
        else
        {
            $AddFirewallRuleCheck = $false
        }
    }    
    catch
    {
        Write-Error "Get-NetFirewallRule not found on the server. The Rdp firewall rule detection is only supported in Windows 2012 R2 and Windows 8.1."
    }

    if($fDenyTSConnections = 1) 
    {
        $AcceptRdpConnectionCheck = $true
    }
    else 
    {
        $AcceptRdpConnectionCheck = $false
    }

    if($UserAuthentication = 1) 
    {
        $EnforceNLAuthCheck = $true
    }
    else 
    {
        $EnforceNLAuthCheck = $false
    }
    
    if($AcceptRdpConnectionCheck -eq $AcceptRdpConnection)
    { $AcceptRdpConnectionResult -eq $true }
    else
    { $AcceptRdpConnectionResult -eq $false }

    if($EnforceNLAuthCheck -eq $EnforceNLAuth)
    { $EnforceNLAuthResult -eq $true }
    else
    { $EnforceNLAuthResult -eq $false }

    if($AddFirewallRuleCheck -eq $AddFirewallRule)
    { $AddFirewallRuleResult -eq $true }
    else
    { $AddFirewallRuleResult -eq $false }
	
    if(
        $AcceptRdpConnectionResult -eq $false -or
        $EnforceNLAuthResult -eq $false -or
        $AddFirewallRuleResult -eq $false
    )
    {
        Write-Verbose "One or more tests failed."
        [System.Boolean]$Result = $false
    }
    else
    {
        Write-Verbose "All tests passed."
        [System.Boolean]$Result = $true
    }

    return $Result
}


Export-ModuleMember -Function *-TargetResource

