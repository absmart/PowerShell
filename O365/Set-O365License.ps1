param(
    $batchCsvPath = ".\NA-MailboxList.csv",
    $batch = 'BR',
    $accountSku = "DeublinGlobal:ENTERPRISEPACK",
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

function Set-O365License {
    param(
        $userPrincipalName,
        $usageLocation,
        $disabledPlans,
        $licensePack,
        $accountSku
    )
    
    Set-MsolUser -UsageLocation $usageLocation -UserPrincipalName $userPrincipalName
    Set-MsolUserLicense -UserPrincipalName $userPrincipalName -AddLicenses $accountSku

    $licenseOptions = New-MsolLicenseOptions -AccountSkuId $accountSku -DisabledPlans $disabledPlans
    Set-MsolUserLicense -UserPrincipalName $userPrincipalName -LicenseOptions $licenseOptions
}

function Get-MsolUserLicenses {
    param(
        $userPrincipalName
    )

    $Exchange = "Disabled"
    $SharePoint = "Disabled"
    $Lync = "Disabled"
    $Office = "Disabled"
    $WebApps = "Disabled"

    ###

    $user = Get-MsolUser -UserPrincipalName $userPrincipalName

    $disabledOptions = @()

    $user.Licenses[0].ServiceStatus | ForEach-Object {

        if($_.ServicePlan.ServiceName -eq "STREAM_O365_E3" –and $_.ProvisioningStatus -ne "Disabled") { $Stream = "Enabled" } else { $Stream = "Disabled"}
        if($_.ServicePlan.ServiceName -eq "Deskless" -and $_.ProvisioningStatus -ne "Disabled") { $Deskless = "Enabled" } else { $Deskless = "Disabled"}
        if($_.ServicePlan.ServiceName -eq "FLOW_O365_P2" -and $_.ProvisioningStatus -ne "Disabled") { $Flow = "Enabled" } else { $Flow = "Disabled"}
        if($_.ServicePlan.ServiceName -eq "POWERAPPS_O365_P2" -and $_.ProvisioningStatus -ne "Disabled") { $PowerApps = "Enabled" } else { $PowerApps = "Disabled"}
        if($_.ServicePlan.ServiceName -eq "PROJECTWORKMANAGEMENT" -and $_.ProvisioningStatus -ne "Disabled") { $Project = "Enabled" } else { $Project = "Disabled"}
        if($_.ServicePlan.ServiceName -eq "SWAY" -and $_.ProvisioningStatus -ne "Disabled") { $Sway = "Enabled" } else { $Sway = "Disabled"}
        if($_.ServicePlan.ServiceName -eq "INTUNE_O365" -and $_.ProvisioningStatus -ne "Disabled") { $Intune = "Enabled" } else { $Skype = "Disabled"}
        if($_.ServicePlan.ServiceName -eq "YAMMER_ENTERPRISE" -and $_.ProvisioningStatus -ne "Disabled") { $Yammer = "Enabled" } else { $Yammer = "Disabled"}
        if($_.ServicePlan.ServiceName -eq "RMS_S_ENTERPRISE" -and $_.ProvisioningStatus -ne "Disabled") { $AzureRightsMgmt = "Enabled" } else { $AzureRightsMgmt = "Disabled"}
        if($_.ServicePlan.ServiceName -eq "OFFICESUBSCRIPTION" –and $_.ProvisioningStatus –ne "Disabled") { $Office365ProPlus = "Enabled" } else { $Office365ProPlus = "Disabled"}
        if($_.ServicePlan.ServiceName -eq "MCOSTANDARD" -and $_.ProvisioningStatus -ne "Disabled") { $OfficeOnline = "Enabled" } else { $OfficeOnline = "Disabled"}
        if($_.ServicePlan.ServiceName -eq "SHAREPOINTWAC" -and $_.ProvisioningStatus -ne "Disabled") { $OfficeOnline = "Enabled" } else { $OfficeOnline = "Disabled"}
        if($_.ServicePlan.ServiceName -eq "SHAREPOINTENTERPRISE" –and $_.ProvisioningStatus -ne "Disabled") { $SharePoint = "Enabled" } else { $SharePoint = "Disabled"}
        if($_.ServicePlan.ServiceName -eq "EXCHANGE_S_ENTERPRISE" –and $_.ProvisioningStatus -ne "Disabled") { $Exchange = "Enabled" } else { $Exchange = "Disabled"}
        
    }



    ###
    # Create disabled options array
    ###

    $DisabledOptions = @()

    if($Exchange -eq "Disabled") { $DisabledOptions += "EXCHANGE_S_ENTERPRISE" }
    if($SharePoint -eq "Disabled") { $DisabledOptions += "SHAREPOINTENTERPRISE" }
    if($Lync -eq "Disabled") { $DisabledOptions += "MCOSTANDARD" }
    if($Office -eq "Disabled") { $DisabledOptions += "OFFICESUBSCRIPTION" }
    if($WebApps -eq "Disabled") { $DisabledOptions += "SHAREPOINTWAC" }

    $licenseOptions = New-MsolLicenseOptions –AccountSkuId $accountSkuId –DisabledPlans $disabledOptions

    return $licenseOptions

}

########### End Functions

#$Office365 = New-Object -TypeName psobject -Property ConnectedMSOnline

$users = Import-Csv -Path $batchCsvPath

$usersToLicense = $users | Where-Object {$_.MigrationGroup -eq $batch}


foreach($user in $usersToLicense){            
    Set-O365License -userPrincipalName $user.UserPrincipalName -usageLocation $user.UsageLocation -accountSku $accountSku -disabledPlans $disabledPlans
    Write-Host "Assigned license $licensePack to user: $user"
}


###
    # Assign the license to the user account
    ###



Set-MsolUserLicense –User $Upn –LicenseOptions $LicenseOptions