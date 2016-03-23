# https://azure.microsoft.com/en-us/documentation/articles/vpn-gateway-create-site-to-site-rm-powershell/

param(
    $ResourceGroupName = "AzureNetwork",
    $Location = "northcentralus"
)

$VirtualNetworkName = "AzureNetwork"

$subnet1 = New-AzureRmVirtualNetworkSubnetConfig -Name 'vm-priv-01' -AddressPrefix '10.0.0.0/24'
New-AzureRmVirtualNetwork -Name $VirtualNetworkName -ResourceGroupName $ResourceGroupName -Location $Location -AddressPrefix 10.0.0.0/20 -Subnet $subnet1

$privRg = New-AzureRmResourceGroup -Name "PrivateNetwork" -Location $Location
$subnet2 = New-AzureRmVirtualNetworkSubnetConfig -Name 'vm-priv-02' -AddressPrefix '172.16.0.0/24'
$vnet = New-AzureRmVirtualNetwork -Name "PrivateNetwork" -ResourceGroupName "PrivateNetwork" -Location $Location -AddressPrefix 172.16.0.0/20 -Subnet $subnet2

$vnet = Get-AzureRmVirtualNetwork -ResourceGroupName "AzureNetwork" -Name "AzureNetwork"
Add-AzureRmVirtualNetworkSubnetConfig -Name 'GatewaySubnet' -AddressPrefix 10.0.3.0/28 -VirtualNetwork $vnet
