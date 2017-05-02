function Connect-O365EO {
    $UserCredential = Get-Credential
    $Session=New-PSSession -ConnectionUri https://ps.outlook.com/Powershell `
        -ConfigurationName Microsoft.Exchange -Credential $UserCredential `
        -Authentication Basic -AllowRedirection
    Import-PSSession $Session
}
New-Alias -Name o365connect -Value Connect-O365EO

function Disconnect-O365 {
  $Session = Get-PSSession | Where-Object {$_.ComputerName -eq 'outlook.office365.com'}

    if ($Session -ne $null) {
      Remove-PSSession $Session
      Write-Verbose "Session $Session.name connected to $Session.ComputerName removed"
    }
    else {
        Write-Verbose "No session found"
    }
}

function Grant-FullAccess {
    param(
        $userPrincipalName,
        $targetPrincipalName,
        $All
    )

    if($All){
        Get-Mailbox -ResultSize Unlimited | Add-MailboxPermission -user $userPrincipalName -AccessRights FullAccess -Automapping $false
    }
    else {
        Get-Mailbox -UserPrincipalName $targetPrincipalName | Add-Mailbox -user $userPrincipalName -AccessRights FullAccess -Automapping $false
    }
    
}

function Remove-FullAccess {
        param(
        $userPrincipalName,
        $targetPrincipalName,
        $All
    )

    if($All){
        Get-Mailbox -ResultSize Unlimited | Add-MailboxPermission -user $userPrincipalName -AccessRights FullAccess
    }
    else {
        Get-Mailbox -UserPrincipalName $targetPrincipalName | Remove-MailboxPermission -user $userPrincipalName -AccessRights FullAccess
    }
}

function Set-O365License { # This script will adjust enabled plan options with all currently license-assigned accounts in the Office 365 tenant
    param(
        $disabledPlans =@(
            "FLOW_O365_P2", 
            "POWERAPPS_O365_P2", 
            "TEAMS1", 
            "PROJECTWORKMANAGEMENT", 
            "SWAY", 
            "YAMMER_ENTERPRISE"
        ),
        $AccountSkuId = "ENTERPRISEPACK"
    )

    $licensedUsers = Get-MsolUser -All | Where-Object { $_.isLicensed -eq "TRUE" } | Select-Object UserPrincipalName

    $accountSku = Get-MsolAccountSku | Where {$_.AccountSkuId -match $AccountSkuId}

    $licenseOptions = New-MsolLicenseOptions -AccountSkuId $accountSku.AccountSkuId -DisabledPlans $disabledPlans

    $licensedUsers | Set-MsolUserLicense -LicenseOptions $licenseOptions
}

function Get-O365SkypeLicenses { # Returns all users that have Skype for Business enabled
    Get-MsolUser -All | where {$_.isLicensed -eq $true -and $_.Licenses[0].ServiceStatus[8].ProvisioningStatus -ne "Disabled"}
}