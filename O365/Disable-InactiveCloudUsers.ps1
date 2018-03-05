param(
    [int]$days = 30,
    [string]$accountSku,
    $testMode,
    [switch]$Verbose
)
function Connect-O365 {
    param(
        $credential,
        [switch]$MSOL,
        [switch]$ExchangeOnline
    )
    if($ExchangeOnline) {
        $session = New-PSSession -ConfigurationName Microsoft.Exchange `
            -ConnectionUri "https://outlook.office365.com/powershell-liveid/" `
            -Credential $Credential -Authentication Basic -AllowRedirection `
            -ErrorAction Stop
        Import-PSSession $session -DisableNameChecking
    }
    if($msol) {
        Connect-MsolService -Credential $Credential
    }
}
<#
$username = "admin@M365x804524.onmicrosoft.com"
$password = ""
$securePassword = ConvertTo-SecureString -String $password -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential ($username, $securePassword)
#>

$credential = Get-AutomationPSCredential -Name 'CheckInactiveUsers'
Connect-O365 -Credential $credential -MSOL -ExchangeOnline

# Finding the Account SKU with Exchange
if(!$accountSku){$exchangeSku = Get-MsolAccountSku | Where-Object {$_.ServiceStatus.ServicePlan.ServiceName -match "EXCHANGE"}}

function main{
    
    # Get all MSOL users that are licensed, have the appropriate account SKU, and are not already blocked from sign-in.
    $allUsers = Get-MsolUser -All | Where-Object {($_.IsLicensed -eq $true) -and ($_.Licenses.AccountSkuId -eq $accountSku) -and ($_.BlockCredential -ne $true)}

    foreach($user in $allUsers)
    {
        $mailbox = Get-Mailbox -Identity $user.UserPrincipalName -ErrorAction SilentlyContinue

        $mailboxStats = $mailbox | Get-MailboxStatistics
        $lastLogonTime = $mailboxStats | Select-Object LastLogonTime -ExpandProperty LastLogonTime
    
        # Output the logon time for logging purposes.
        if($Verbose){Write-Host $user.UserPrincipalName "- LastLogonTime -" $lastLogonTime -ForegroundColor Yellow}
        
        # Check if the LastLogonTime is older than the $days parameter, disable/block sign-ins on the MSOL user if it is.
        if(($lastLogonTime -ne $null) -and $lastLogonTime -lt (Get-Date).AddDays(-$days)){

            Write-Host (Get-Date -Format "yyyy/MM/dd hh:MM:ss") ": LastLogonTime Value older than" $days "days. Disabling access for this account -" $user.UserPrincipalName -ForegroundColor Red
            # If running in test mode, do not disable the user.
            if(!$testmode){Get-MsolUser -UserPrincipalName $user.UserPrincipalName | Set-MsolUser -BlockCredential $true}
        }
    }
}

main

Get-PSSession | Remove-PSSession