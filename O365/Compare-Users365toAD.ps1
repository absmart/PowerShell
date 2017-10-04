if(!(Get-Module ActiveDirectory)){Import-Module ActiveDirectory}

$users = Get-Mailbox -Result Unlimited | Select UserPrincipalName, EmailAddresses

foreach($user in $users)
{
    $upn = $user.UserPrincipalName
    $a = $user
    $b = Get-ADUser -LDAPFilter "(UserPrincipalName=$upn)" -Properties proxyAddresses | Select UserPrincipalName, @{Name="EmailAddresses";Expression={$_.proxyAddresses}}
    try{
    Compare-Object -ReferenceObject $a.EmailAddresses -DifferenceObject $b.EmailAddresses -Verbose -ErrorAction SilentlyContinue | `
        Where-Object {$_.InputObject -notlike 'x500*' -and $_.InputObject -notlike 'x400*' -and $_.InputObject -notlike '*.onmicrosoft.com' -and $_.InputObject -notlike '*C3000' -and $_.InputObject -notlike 'SPO*' -and $_.InputObject -notlike 'SIP*'}
    }
    catch
    {
        Write-Host "Failed to compare " $a.UserPrincipalName -ForegroundColor Red
    }
}