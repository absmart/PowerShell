# This script only supports VMs deployed via the Azure Marketplace.
# This script will add a new tag called Environment with data from the image reference.

$vms = Get-AzureRmVm

foreach($vm in $vms)
{

    $imageRef = $vm.StorageProfile.ImageReference
    $osValue = $imageRef.Offer + "-" + $imageRef.Sku
    
    if($imageRef.OS -ne $osValue){
        $vm.Tags.Add("OS", $osValue)
    }
    else {
        Write-Host "The osValue tag exists, skipping." -ForegroundColor Green
    }
    Set-AzureRmResource -Tag $vm.Tags -ResourceId $vm.Id -Force -ErrorAction SilentlyContinue
}