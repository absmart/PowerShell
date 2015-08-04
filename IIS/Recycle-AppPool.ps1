param(
    $Site,
    $Environment
    )

Import-Module ($env:SCRIPTS_HOME + "\Libraries\Standard_Variables.ps1")

Invoke-Command $sharepoint_environment.$Environment.WEB -ArgumentList $Site {
    param(
        $Site
    )
    Import-Module WebAdministration
        
    $Pool = (Get-Item "IIS:\Sites\$Site"| Select-Object applicationPool).applicationPool
    Restart-WebAppPool $Pool

    $PoolState = Get-Item IIS:\Sites\$Site    
    return $PoolState
}