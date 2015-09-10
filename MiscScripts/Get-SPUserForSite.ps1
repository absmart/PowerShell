$CentralAdminServer = "ServerName"
$Credentials = Get-Credential -UserName "$env:USERDOMAIN\$env:USERNAME"

$User = "US12345"
$Web = "http://team.gt.com/sites/ApplicationOperations/applicationsupport"

Invoke-Command -ComputerName $CentralAdminServer -Authentication Credssp -Credential $Credentials -ArgumentList $User,$Web -ScriptBlock{
    param(
        $User,
        $Web
    )

    Import-Module (Join-Path $ENV:SCRIPTS_HOME "Libraries\SharePoint2010_Functions.ps1")

    $SPUser = Get-SPUser -Web $Web -Limit All | Where {$_.UserLogin -imatch $User }
    
    return $SPUser
    #Remove-SPUser -Identity $SPUser -Web $Web -Confirm:$False # Used to remove SPUsers from sites to resolve an infrequent authentication issue.

}