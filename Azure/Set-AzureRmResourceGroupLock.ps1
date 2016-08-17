param(
    $resourceGroup = (Get-AzureRmResourceGroup).ResourceGroupName
)

foreach($rg in $resourceGroup){
    New-AzureRmResourceLock -ResourceGroupName $rg -LockName CannotDelete -LockLevel CanNotDelete -Verbose -Force
}