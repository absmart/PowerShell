function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Name
    )

    $Ensure = "Absent"
    $State  = "Stopped"

    Import-Module WebAdministration

    try {
        Write-Verbose "Getting WebAppPool for $Name" 
        $WebAppPool = Get-Item -Path IIS:\AppPools\* | ? {$_.name -eq $Name} }
    catch { $WebAppPool = $null }

    if($WebAppPool -ne $null)
    {
        $Ensure = "Present"
        $State  = $WebAppPool.state
        $IdentityType = (Get-ItemProperty -Path IIS:\AppPools\$Name -Name ProcessModel).identityType
        $Identity = (Get-ItemProperty -Path IIS:\AppPools\$Name -Name ProcessModel).userName
    }
    
    if($IdentityType -eq "ApplicationPoolIdentity")
        {$IdentityResult = "ApplicationPoolIdentity" }
    else
        { $IdentityResult = $Identity }
               
    $returnValue = @{
        Name   = $Name
        Ensure = $Ensure
        State  = $State
        IdentityCredential = $IdentityResult
    }

    return $returnValue
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure = "Present",

        [ValidateSet("Started","Stopped")]
        [System.String]
        $State = "Started",

        [System.Management.Automation.PSCredential[]]
        $IdentityCredential
    )

    Import-Module WebAdministration

    if(!(Get-Module -ListAvailable -Name WebAdministration))
    {
        Throw "Please ensure that WebAdministration module is installed."
    }

    if($Ensure -eq "Absent")
    {
        Write-Verbose("Removing the Web App Pool")
        Remove-WebAppPool $Name
    }
    else
    {

        $WebAppPool = Get-Item -Path IIS:\AppPools\* | ? {$_.name -eq $Name}
        if($WebAppPool.Name -eq $Name)
        {
            $Ensure = "Present"
            $State  = $WebAppPool.state
            $Identity = (Get-ItemProperty -Path IIS:\AppPools\$Name -Name ProcessModel).userName
            
            $AppPool = @{
                Name   = $Name
                Ensure = $Ensure
                State  = $State
                Identity = $Identity
            }
        }

        if($AppPool.Ensure -ne "Present")
        {
            Write-Verbose("Creating the Web App Pool - $Name")
            New-WebAppPool $Name            
        }

        if($AppPool.State -ne $State)
        {
            ExecuteRequiredState -Name $Name -State $State
        }

        if($IdentityCredential)
        {
            $User = $IdentityCredential.GetNetworkCredential().UserName
            $Domain = $IdentityCredential.GetNetworkCredential().Domain
            if($Domain -eq "domain.com")
            {
                $FqdnUserName = ($Domain + "\" + $User)
            }
            else
            {
                $FqdnUserName = $User
            }
            
            $Value = @{
                username = $FqdnUserName;
                password = $IdentityCredential.GetNetworkCredential().Password;
                identityType = 3
            }
                        
            Set-ItemProperty  "IIS:\AppPools\$Name" -Name processModel -Value $Value
        }
    }
}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure  = "Present",

        [ValidateSet("Started","Stopped")]
        [System.String]
        $State = "Started",

        [System.Management.Automation.PSCredential[]]
        $IdentityCredential
    )
     
    Import-Module WebAdministration
    
    $AppPool = Get-Item -Path IIS:\AppPools\* | ? {$_.name -eq $Name}
    
    if($AppPool -ne $null)
    {
        $WebAppPool = @{
            Ensure = "Present"
            State  = $AppPool.state
            Identity = (Get-ItemProperty -Path IIS:\AppPools\$Name -Name ProcessModel).userName
        }
    }
    else
    {        
        $WebAppPool = $null
    }

    if($Ensure -eq "Present" -and $WebAppPool -ne $null)
    {
        if($WebAppPool.Ensure -eq $Ensure -and $WebAppPool.State -eq $state)
        {
            return $true
        }
                
        if($IdentityCredential -and $WebAppPool -ne $null)
        {
            $User = $IdentityCredential.GetNetworkCredential().UserName
            $Domain = $IdentityCredential.GetNetworkCredential().Domain
            $FqdnUserName = ($Domain + "\" + $User)

            $CurrentUsername = Get-ItemProperty "IIS:\AppPools\$Name" -Name processModel | Select username -ExpandProperty username
            $CurrentPassword = Get-ItemProperty "IIS:\AppPools\$Name" -Name processModel | Select password -ExpandProperty password
            $CurrentIdentityType = Get-ItemProperty "IIS:\AppPools\$Name" -Name processModel | Select identityType -ExpandProperty identityType

            if($CurrentUsername -eq $FqdnUserName) { $UsernameResult = $true } else{ $UsernameResult = $false }
            if($CurrentPassword -eq $IdentityCredential.GetNetworkCredential().Password) { $PasswordResult = $true } else{ $PasswordResult = $false }
            if($CurrentIdentityType -eq 3) { $IdentityTypeResult = $true } else{ $IdentityTypeResult = $false }
            
            if($UsernameResult -eq $true -and $PasswordResult -eq $true -and $IdentityTypeResult -eq $true)
            {
                return $true
            }
            else
            {
                return $false
            }            
        }
    }
    elseif($WebAppPool.Ensure -eq $Ensure)
    {
        return $true
    }

    return $false
}


function ExecuteRequiredState([string] $Name, [string] $State)
{
    if($State -eq "Started")
    {
        Write-Verbose("Starting the Web App Pool")
        start-WebAppPool -Name $Name
    }
    else
    {
        Write-Verbose("Stopping the Web App Pool")
        Stop-WebAppPool -Name $Name
    }
}

Export-ModuleMember -Function *-TargetResource