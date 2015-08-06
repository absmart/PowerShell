param(
    $ComputerName,
    $Name
)

Invoke-Command -ComputerName $ComputerName -ArgumentList $Name -ScriptBlock {
    param(
        $Name
    )
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
        ComputerName = $env:COMPUTERNAME
        Name   = $Name
        Ensure = $Ensure
        State  = $State
        IdentityCredential = $IdentityResult
    }

    return $returnValue
}