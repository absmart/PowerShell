

# Sandbox setup

$rgName = "ABSVirtualNetwork"
$location = "northcentralus"

$vNetName = "absvNet"
$vNetPrefix = "172.16.0.0/20"
$subnetName = "absSubnet-161"
$subnetPrefix = "172.16.1.0/24"

$automationAccount = "absAutomation"

# Start process

# Create ResourceGroup
$rg = New-AzureRmResourceGroup -Name $rgName -Location $location

# Create Vnet
$subnet = New-AzureRmVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix $subnetPrefix
$vnet = New-AzureRmVirtualNetwork -Name $vNetName `
    -ResourceGroupName $rgName `
    -Location $location `
    -AddressPrefix $vNetPrefix `
    -Subnet $subnet

# Create automation account
New-AzureRmAutomationAccount -ResourceGroupName $rgName -Name $automationAccount -Location $location -Plan Basic

# Create VM for automation testing; https://msdn.microsoft.com/en-us/library/mt603754.aspx

foreach($vm in ("absVm1","absVm2")){

    $vmName = $vm
    $vmSize = "Standard_A2"
    $storageType = "Standard_LRS"
    $osDiskName = $vmName + "osDisk"
    $storageAccount = New-AzureRmStorageAccount -ResourceGroupName $rgName -Name ($vmName + "storage1") -Type $storageType -Location $location

    # Network
    $publicIp = New-AzureRmPublicIpAddress -Name $InterfaceName -ResourceGroupName $ResourceGroupName -Location $Location -AllocationMethod Dynamic
    $subnetConfig = New-AzureRmVirtualNetworkSubnetConfig -Name $Subnet1Name -AddressPrefix $VNetSubnetAddressPrefix
    $vNet = New-AzureRmVirtualNetwork -Name $VNetName -ResourceGroupName $ResourceGroupName -Location $Location -AddressPrefix $VNetAddressPrefix -Subnet $SubnetConfig
    $interface = New-AzureRmNetworkInterface -Name $InterfaceName -ResourceGroupName $ResourceGroupName -Location $Location -SubnetId $VNet.Subnets[0].Id -PublicIpAddressId $PIp.Id

    # Compute

    ## Setup local VM object
    $credential = Get-Credential
    $virtualMachine = New-AzureRmVMConfig -VMName $vmName -VMSize $vmSize
    $virtualMachine = Set-AzureRmVMOperatingSystem -VM $virtualMachine -Windows -ComputerName $vmName -Credential $credential -ProvisionVMAgent -EnableAutoUpdate
    $virtualMachine = Set-AzureRmVMSourceImage -VM $virtualMachine -PublisherName MicrosoftWindowsServer -Offer WindowsServer -Skus 2012-R2-Datacenter -Version "latest"
    $virtualMachine = Add-AzureRmVMNetworkInterface -VM $virtualMachine -Id $Interface.Id
    $osDiskUri = $storageAccount.PrimaryEndpoints.Blob.ToString() + "vhds/" + $osDiskName + ".vhd"
    $virtualMachine = Set-AzureRmVMOSDisk -VM $virtualMachine -Name $osDiskName -VhdUri $osDiskUri -CreateOption FromImage

    ## Create the VM in Azure
    New-AzureRmVM -ResourceGroupName $ResourceGroupName -Location $Location -VM $VirtualMachine
}
