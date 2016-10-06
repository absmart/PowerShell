param(
    $vmName = "SERVER01",
    $vmSize = "Standard_A2",
    $rgName = "dc-rg",
    $asName = "dc-as",
    $vnetName = "vnet",
    $subnetName = "dc-subnet",
    $storageAccountName = "companydc01",
    $vnetRgName = "vnet-rg",
    [ValidateSet("Dynamic","Static")]$publicIpAllocation = "Dynamic",
    $Credential = (Get-Credential -Message "Enter the local administrator account to be used with this VM")
)

Login-AzureRmAccount

$subscriptionId = 
    ( Get-AzureRmSubscription | Out-GridView `
          -Title "Select an Azure Subscription" `
          -PassThru
    ).SubscriptionId
    
if($rgName -eq $null)
{
    $rgName =
        ( Get-AzureRmResourceGroup | Out-GridView `
              -Title "Select an Azure Resource Group" `
              -PassThru
        ).ResourceGroupName
}

$publicIpName = $vmName + "-pip"
$nicName = $vmName + "-nic"

$storageAccount = Get-AzureRmStorageAccount -ResourceGroupName $rgName -Name $storageAccountName
$vnet = Get-AzureRmVirtualNetwork -Name $vnetName -ResourceGroupName $vnetRgName
$subnetId = ($vnet.Subnets | Where {$_.Name -eq $subnetName}).Id

$publicIp = New-AzureRmPublicIpAddress -Name $publicIpName -ResourceGroupName $rgName -Location $Location -AllocationMethod $publicIpAllocation
$nic = New-AzureRmNetworkInterface -Name $nicName -ResourceGroupName $rgName -Location $Location -SubnetId $subnetId -PublicIpAddressId $publicIp.Id

$availabiltiySetId = (Get-AzureRmAvailabilitySet -ResourceGroupName $rgName -Name $asName).Id

$vm = New-AzureRmVMConfig -VMName $vmName -VMSize $vmSize -AvailabilitySetId $availabiltiySetId
$vm = Set-AzureRmVMOperatingSystem -VM $vm -Windows -ComputerName $vmName -Credential $Credential -ProvisionVMAgent -EnableAutoUpdate
$vm = Set-AzureRmVMSourceImage -VM $vm -PublisherName MicrosoftWindowsServer -Offer WindowsServer -Skus 2012-R2-Datacenter -Version "latest"
$vm = Add-AzureRmVMNetworkInterface -VM $vm -Id $nic.Id

$diskName = $vmName + "OSDisk"
$blobPath = "vhds/" + $vmName + "osDisk.vhd"
$osDiskUri = $storageAccount.PrimaryEndpoints.Blob.ToString() + $blobPath
$vm = Set-AzureRmVMOSDisk -VM $vm -Name $diskName -VhdUri $osDiskUri -CreateOption fromImage

New-AzureRmVM -ResourceGroupName $rgName -Location $Location -VM $vm -Verbose