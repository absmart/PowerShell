param(
    $Site,
    $Environment
    )

Import-Module ($env:POWERSHELL_HOME + "\Libraries\Standard_Variables.ps1")

Invoke-Command $dotnetfarm.$Environment.WEB -ArgumentList $Site {
    param(
        $Site
    )
    Import-Module WebAdministration
        
    $Pool = (Get-Item "IIS:\Sites\$Site"| Select-Object applicationPool).applicationPool
    Restart-WebAppPool $Pool

    $PoolState = Get-Item IIS:\Sites\$Site    
    return $PoolState
}