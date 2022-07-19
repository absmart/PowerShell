param(
    [parameter(mandatory=$true)]
    $tenantId,
    [parameter(mandatory=$false)]
    $outputCsvPath
)

if(!$outputCsvPath)
{
    $tenantName = (Get-AzTenant -TenantId $tenantId).Name
    $tenant = $tenantName -replace " ", ""
    $outputCsvPath = ".\" + $tenant + $tenantId + ".csv"
}

try{$subscriptions = Get-AzSubscription -TenantId $tenantId}
catch{
    Write-Output "Failed to pull subscriptions from tenant ID '$tenantId'. Are you signed in? Use Login-AzAccount -TenantId to sign-in."
    Write-Output $_
}

# Pull the latest Move Support CSV from Git and get non-supported values
$moveCSV = "https://raw.githubusercontent.com/tfitzmac/resource-capabilities/master/move-support-resources.csv"
$unsupportedMoveCSV = (Invoke-WebRequest -Uri $moveCSV).Content | ConvertFrom-Csv
$unsupportedMove = ($unsupportedMoveCSV | Where-Object {$_.'Move Subscription' -eq 0}).Resource

$output = @()

foreach($subscription in $subscriptions)
{
    Select-AzSubscription -SubscriptionId $subscription.Id -TenantId $tenantId | Out-Null
    $resources = Get-AzResource
    $unsupported_resources = $resources | Where-Object { $unsupportedMove -contains $_.ResourceType }

    foreach ($resource in $unsupported_resources) {
        $result = [PSCustomObject][ordered] @{
            Name                = $resource.Name
            ResourceGroupName   = $resource.ResourceGroupName
            ResourceType        = $resource.ResourceType
            Location            = $resource.Location
            ResourceId          = $resource.ResourceId
            SubscriptionName    = $subscription.Name
            SubscriptionId      = $subscription.Id
        }
        $output += $result
    }
}

$output | Export-Csv -NoTypeInformation $outputCsvPath