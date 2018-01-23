<#
# SERVICES
    SWAY = Sway
    INTUNE_O365 = Mobile Device Management for Office 365
    YAMMER_ENTERPRISE = Yammer
    RMS_S_ENTERPRISE = Azure Rights Management (RMS)
    OFFICESUBSCRIPTION = Office Professional Plus
    MCOSTANDARD = Skype for Business Online
    SHAREPOINTWAC = Office Online
    SHAREPOINTENTERPRISE = SharePoint Online
    EXCHANGE_S_ENTERPRISE = Exchange Online Plan 2
#>

param(
    [Parameter(Mandatory = $true, ParameterSetName = 'UserPrincipalName')]
    $userPrincipalName,

    $accountSkuId,
    $ExchangeOnline,
    $SharePointOnline,
    $OfficeProPlus,
    $OfficeOnline,
    $Yammer,
    $AzureRightsManagement,
    $Intune,
    $Sway,
    $Stream,
    $Flow,

    $disabledPlans =@(
            "STREAM_O365_E3",
            "Deskless",
            "FLOW_O365_P2",
            "POWERAPPS_O365_P2",
            "TEAMS1",
            "PROJECTWORKMANAGEMENT",
            "SWAY",
            "YAMMER_ENTERPRISE",
            "RMS_S_ENTERPRISE",
            "OFFICESUBSCRIPTION",
            "MCOSTANDARD",
            "SHAREPOINTWAC",
            "SHAREPOINTENTERPRISE"
    )
)

if($accountSkuId = $null) {
    $accountSkuId = (Get-MsolAccountSku | Where-Object {$_.AccountSkuId -match 'ENTERPRISEPACK'}).AccountSkuId
}

function Set-O365License {
    param(
        $userPrincipalName,
        $usageLocation,
        $disabledPlans,
        $accountSku
    )
    
    Set-MsolUser -UsageLocation $usageLocation -UserPrincipalName $userPrincipalName
    Set-MsolUserLicense -UserPrincipalName $userPrincipalName -AddLicenses $accountSku

    $licenseOptions = New-MsolLicenseOptions -AccountSkuId $accountSku -DisabledPlans $disabledPlans
    Set-MsolUserLicense -UserPrincipalName $userPrincipalName -LicenseOptions $licenseOptions
}

function Get-MsolUserLicenses {
    param(
        $userPrincipalName,
        $accountSkuId
    )
    
    $user = Get-MsolUser -UserPrincipalName $userPrincipalName

    $disabledOptions = @()

    $user.Licenses[0].ServiceStatus | ForEach-Object {

        if($_.ServicePlan.ServiceName -eq "FORMS_PLAN_E3" –and $_.ProvisioningStatus -ne "Disabled") { $Forms = "Enabled" } else { $Forms = "Disabled"}
        if($_.ServicePlan.ServiceName -eq "STREAM_O365_E3" –and $_.ProvisioningStatus -ne "Disabled") { $Stream = "Enabled" } else { $Stream = "Disabled"}
        if($_.ServicePlan.ServiceName -eq "Deskless" -and $_.ProvisioningStatus -ne "Disabled") { $Deskless = "Enabled" } else { $Deskless = "Disabled"}
        if($_.ServicePlan.ServiceName -eq "FLOW_O365_P2" -and $_.ProvisioningStatus -ne "Disabled") { $Flow = "Enabled" } else { $Flow = "Disabled"}
        if($_.ServicePlan.ServiceName -eq "POWERAPPS_O365_P2" -and $_.ProvisioningStatus -ne "Disabled") { $PowerApps = "Enabled" } else { $PowerApps = "Disabled"}
        if($_.ServicePlan.ServiceName -eq "PROJECTWORKMANAGEMENT" -and $_.ProvisioningStatus -ne "Disabled") { $Project = "Enabled" } else { $Project = "Disabled"}
        if($_.ServicePlan.ServiceName -eq "SWAY" -and $_.ProvisioningStatus -ne "Disabled") { $Sway = "Enabled" } else { $Sway = "Disabled"}
        if($_.ServicePlan.ServiceName -eq "INTUNE_O365" -and $_.ProvisioningStatus -ne "Disabled") { $Intune = "Enabled" } else { $Intune = "Disabled"}
        if($_.ServicePlan.ServiceName -eq "YAMMER_ENTERPRISE" -and $_.ProvisioningStatus -ne "Disabled") { $Yammer = "Enabled" } else { $Yammer = "Disabled"}
        if($_.ServicePlan.ServiceName -eq "RMS_S_ENTERPRISE" -and $_.ProvisioningStatus -ne "Disabled") { $AzureRightsMgmt = "Enabled" } else { $AzureRightsMgmt = "Disabled"}
        if($_.ServicePlan.ServiceName -eq "OFFICESUBSCRIPTION" –and $_.ProvisioningStatus –ne "Disabled") { $Office365ProPlus = "Enabled" } else { $Office365ProPlus = "Disabled"}
        if($_.ServicePlan.ServiceName -eq "MCOSTANDARD" -and $_.ProvisioningStatus -ne "Disabled") { $Skype = "Enabled" } else { $Skype = "Disabled"}
        if($_.ServicePlan.ServiceName -eq "SHAREPOINTWAC" -and $_.ProvisioningStatus -ne "Disabled") { $SharePointWac = "Enabled" } else { $OfficeOnline = "Disabled"}
        if($_.ServicePlan.ServiceName -eq "SHAREPOINTENTERPRISE" –and $_.ProvisioningStatus -ne "Disabled") { $SharePoint = "Enabled" } else { $SharePoint = "Disabled"}
        if($_.ServicePlan.ServiceName -eq "EXCHANGE_S_ENTERPRISE" –and $_.ProvisioningStatus -ne "Disabled") { $Exchange = "Enabled" } else { $Exchange = "Disabled"}
        
    }
    
    # Create disabled options array

    $DisabledOptions = @()

    if($Forms -eq "Disabled") { $DisabledOptions += "FORMS_PLAN_E3" }
    if($Stream -eq "Disabled") { $DisabledOptions += "STREAM_O365_E3" }
    if($Deskless -eq "Disabled") { $DisabledOptions += "Deskless" }
    if($Flow -eq "Disabled") { $DisabledOptions += "FLOW_O365_P2" }
    if($PowerApps -eq "Disabled") { $DisabledOptions += "POWERAPPS_O365_P2" }
    if($Project -eq "Disabled") { $DisabledOptions += "PROJECTWORKMANAGEMENT" }
    if($Sway -eq "Disabled") { $DisabledOptions += "SWAY" }
    if($Intune -eq "Disabled") { $DisabledOptions += "INTUNE_O365" }
    if($Yammer -eq "Disabled") { $DisabledOptions += "YAMMER_ENTERPRISE" }
    if($AzureRightsMgmt -eq "Disabled") { $DisabledOptions += "RMS_S_ENTERPRISE" }
    if($OfficeOnline -eq "Disabled") { $DisabledOptions += "OFFICESUBSCRIPTION" }
    if($Skype -eq "Disabled") { $DisabledOptions += "MCOSTANDARD" }
    if($SharePointWac -eq "Disabled") { $DisabledOptions += "SHAREPOINTWAC" }
    if($SharePoint -eq "Disabled") { $DisabledOptions += "SHAREPOINTENTERPRISE" }
    if($Exchange -eq "Disabled") { $DisabledOptions += "EXCHANGE_S_ENTERPRISE" }

    $licenseOptions = New-MsolLicenseOptions –AccountSkuId $accountSkuId –DisabledPlans $disabledOptions

    return $licenseOptions
}
# End Functions

# Add logic to check if MSOnline is connected or not


# Assign the license to the user account

$users = Import-Csv -Path $batchCsvPath

$usersToLicense = $users | Where-Object {$_.MigrationGroup -eq $batch}

foreach($user in $usersToLicense){            
    Set-O365License -userPrincipalName $user.UserPrincipalName -usageLocation $user.UsageLocation -accountSku $accountSku -disabledPlans $disabledPlans
    Write-Verbose "Assigned license to user: $user"
}

Set-MsolUserLicense –User $Upn –LicenseOptions $LicenseOptions