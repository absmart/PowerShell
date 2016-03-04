param(
    $ResourceGroupName,
    $StorageAccountName,
    $Location,
    [PsCredential] $Credential = (Get-Credential)
)

Import-Module (Join-Path $env:POWERSHELL_HOME "Azure\Azure_Functions.psm1")

# Select Azure Subscription

$subscriptionId = 
    ( Get-AzureRmSubscription | Out-GridView `
          -Title "Select an Azure Subscription" `
          -PassThru
    ).SubscriptionId

Select-AzureRmSubscription -SubscriptionId $subscriptionId

# Select Azure Resource Group in which existing VNET is provisioned

$rgName =
    ( Get-AzureRmResourceGroup | Out-GridView `
          -Title "Select an Azure Resource Group" `
          -PassThru
    ).ResourceGroupName

# Select Azure VNET gateway on which to start diagnostics logging

$vnetGwName = 
    ( Get-AzureRmVirtualNetworkGateway `
        -ResourceGroupName $rgName
    ).Name |
    Out-GridView `
        -Title "Select an Azure VNET Gateway" `
        -PassThru

# Select Azure Storage Account on which to send logs



if(!($storageAccountName = Get-AzureRmStorageAccount -ResourceGroupName $rgName -Name $StorageAccountName))
{
    $strgAccountName = (New-AzureRmStorageAccount -ResourceGroupName $rgName -Name $StorageAccountName -Type Standard_LRS -Location $Location).Name
}
else
{
    $strgAccountName = $StorageAccountName.Name
}

$storageAccountKey = (Get-AzureRmStorageAccountKey -Name $strgAccountName -ResourceGroupName $rgName).Key1

Add-AzureAccount -Credential $Credential

# Select same Azure subscription via Azure Service Management

Select-AzureSubscription -SubscriptionId $subscriptionId

# Set Storage Context for storing logs

$storageContext = 
    New-AzureStorageContext `
        -StorageAccountName $storageAccountName `
        -StorageAccountKey $storageAccountKey

# Get Gateway ID for VNET Gateway

$vnetGws = Get-AzureVirtualNetworkGateway 

$vnetGwId = 
    ( $vnetGws | 
        ? GatewayName -eq $vnetGwName 
    ).GatewayId

# Start Azure VNET Gateway logging

$captureDuration = 60

$storageContainer = "vpnlogs"

Start-AzureVirtualNetworkGatewayDiagnostics  `
    -GatewayId $vnetGwId `
    -CaptureDurationInSeconds $captureDuration `
    -StorageContext $storageContext `
    -ContainerName $storageContainer
 
Sleep -Seconds $captureDuration

# Download VNET gateway diagnostics log

$logUrl = 
    ( Get-AzureVirtualNetworkGatewayDiagnostics `
        -GatewayId $vnetGwId
    ).DiagnosticsUrl
 
$logContent = 
    ( Invoke-WebRequest `
        -Uri $logUrl
    ).RawContent
 
$logContent | 
    Out-File `
        -FilePath vpnlog.txt