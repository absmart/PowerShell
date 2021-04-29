$ResourceGroupName = "7d-rg"
$Location = "eastus2"
$DestinationResourceGroup = "7d-csp-rg"

<#
.SYNOPSIS
Function which validates resource move between resource groups.

.DESCRIPTION
Wrapper function around Azure API https://docs.microsoft.com/en-us/rest/api/resources/resources/validatemoveresources
Function is building all necessary parts to send a properly formated query as a web request via API and validate the resource move between resource groups.
ARM will report if the resources can be migrated or there are dependencies which have to be resolved.

.PARAMETER ApplicationId
ID of the service principal/application which will be used to validate the resource move, keep in mind that it has to have proper rights.

.PARAMETER ApplicationPassword
Password of the service principal/application.

.PARAMETER SourceResourceGroup
Name of the resource group where resources are located.

.PARAMETER TargetResourceGroup
Name of the resource group to where you want to move the resources.

.PARAMETER SourceSubscriptionId
GUID value for the subscription where resources are located

.PARAMETER TargetSubscriptionId
GUID value for the subscription where resources are moved to

.EXAMPLE
 To do
#>

Function Get-AccessToken {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $True,
            ValueFromPipeline = $True,
            ValueFromPipelineByPropertyName = $True,
            HelpMessage = 'Provide Client Id or Application Id from Azure AD or any Microsoft API.')]
        [string]$ClientId,
        [Parameter(Mandatory = $True,
            ValueFromPipeline = $True,
            ValueFromPipelineByPropertyName = $True,
            HelpMessage = 'Provide Client Secret provided from Azure AD or any Microsoft API.')]
        [string]$ClientSecret,
        [Parameter(Mandatory = $True,
            ValueFromPipeline = $True,
            ValueFromPipelineByPropertyName = $True,
            HelpMessage = 'Provide Microsoft Azure API Login URL.')]
        [string]$ApiUri
    )
    process {
        $GrantType = 'client_credentials'
        $TargetResource = 'https://management.core.windows.net/'
        $body = "grant_type=$GrantType&client_id=$ClientId&client_secret=$ClientSecret&resource=$TargetResource"
        $response = Invoke-RestMethod -Method Post -Uri $ApiUri -Body $body -ContentType 'application/x-www-form-urlencoded'
        return $response
    }
}

Function Get-AzResourceMoveValidation {
    [CmdletBinding()]
    param (

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$SourceSubscriptionApplicationId,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$TargetSubscriptionApplicationId,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [securestring]$SourceApplicationPassword,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [securestring]$TargetApplicationPassword,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$SourceResourceGroup,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$SourceSubscriptionId,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$TargetResourceGroup,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$TargetSubscriptionId
    )

    process {
        $TenantId = (Get-AzContext | Select-Object -ExpandProperty Tenant).Id

        $SubscriptionId = (Get-AzContext | Select-Object -ExpandProperty Subscription).Id



        $ApiUrl = "https://login.microsoftonline.com/$TenantId/oauth2/token"
        $TargetUri = "https://management.azure.com/subscriptions/$SubscriptionId/resourceGroups/$SourceResourceGroup/validateMoveResources?api-version=2019-08-01"
        [array]$ResourceList = (Get-AzResource -ResourceGroupName $SourceResourceGroup | Where-Object { $_.ResourceType -match '^[^\/]+\/[^\/]+$' }).ResourceId
        $TargetId = (Get-AzResourceGroup -Name $TargetResourceGroup).ResourceId
        $CustomObject = [PSCustomObject]@{
            resources           = $ResourceList
            targetResourceGroup = $TargetId
        }
        $Body = $CustomObject | ConvertTo-Json
        $TokenSplat = @{
            ClientId     = $ApplicationId
            ClientSecret = $([System.Runtime.InteropServices.marshal]::PtrToStringAuto([System.Runtime.InteropServices.marshal]::SecureStringToBSTR($ApplicationPassword)))
            ApiUri       = $ApiUrl
        }
        $Token = Get-AzAccessToken @TokenSplat
        $Headers = @{ }
        $Headers.Add("Authorization", "$($Token.token_type) $($Token.access_token)")
        $RestSplat = @{
            Uri         = $TargetUri
            Method      = 'Post'
            Headers     = $Headers
            ContentType = 'application/json'
            Body        = $Body
        }
        try {
            $ErrorActionPreference = 'Stop'
            $Capture = Invoke-WebRequest @RestSplat
            if ($Capture.StatusCode -eq 202) {
                $RestSplat.Uri = "$($Capture.Headers.location)"
                $RestSplat.Method = 'Get'
                $RestSplat.Remove('Body')
                $RestSplat.Remove('ContentType')
                $StartCount = 0
                $RetryCount = 3
                $SleepTimer = 60
                while ($StartCount -ne $RetryCount) {
                    $StartCount++
                    Invoke-WebRequest @RestSplat
                    Start-Sleep -Seconds $SleepTimer
                }
            }
            elseif ($Capture.StatusCode -eq 204) {
                Write-Host -ForegroundColor Green 'VALIDATION SUCCEEDED, ALL RESOURCES CAN BE MOVED!'
            }
            else {
                $Capture
            }
        }
        catch {
            Write-Error "$_" -ErrorAction Stop
        }
    }
}


Function Set-RGTag {
    param(
        $ResourceGroupName,
        $Location,
        $DestinationResourceGroup
    )

    $resources = Get-AzResource -ResourceGroupName $ResourceGroupName

    foreach($resource in $resources){
        $tags = @{"BDOCSPMigrateResourceGroup"=$DestinationResourceGroup}
        Update-AzTag -ResourceId $resource.ResourceId -Tag $tags -Operation Merge
    }
}