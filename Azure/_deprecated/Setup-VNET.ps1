# https://azure.microsoft.com/en-us/documentation/articles/vpn-gateway-create-site-to-site-rm-powershell/

param(
    $SubscriptionId,
    $ClientAbbreviation = "ABS",
    $ResourceGroupName = "ABS-Cloud-01",
    [ValidateSet("RouteBased","PolicyBased")]$VpnType = "RouteBased"
)

Import-AzureRM
try{Get-AzureRmSubscription}
catch{Login-AzureRmAccount}
Select-AzureRmSubscription -Subscriptionid $SubscriptionId

if(!($ResourceGroupName)){
    $ResourceGroupName = ($ClientAbbreviation + "-AzureResGrp")
}

$Location = 'North Central US'
$GatewayIpAddress = '199.68.241.160'
$LocalNetworkGatewayName = ($ClientAbbreviation + "-LocalGateway")
$AddressPrefix = '10.50.0.0/16','10.222.0.0/16','172.25.0.0/16','10.250.99.0/24','192.168.50.0/24','192.168.60.0/24','10.60.0.0/16','172.28.0.0/16','172.26.0.0/16'

$AzureAddressPrefix = "10.55.30.0/24"
$AzureVMSubnetName = "DJGUSA-Sql1-Subnet"
$AzureVMSubnet = "10.55.30.0/25"
$GatewaySubnetAddressPrefix = "10.55.30.248/29"

$PublicIpAddressName = ($ClientAbbreviation + "-AzurePubIp")

# Azure Network

$AzureVNetName = ($ClientAbbreviation + "-AzureVNet")
$AzureGwCfgName = ($ClientAbbreviation + "-AzureGWCfg")
$AzureVpnGw = ($ClientAbbreviation + "-AzureVpnGw")
$AzureVpnName = ($ClientAbbreviation + "-AzureVPN")

if(!(Get-AzureRmResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue)){
    New-AzureRmResourceGroup -Name $ResourceGroupName -Location $Location
}

New-AzureRmLocalNetworkGateway -Name $LocalNetworkGatewayName -ResourceGroupName $ResourceGroupName -Location $Location -GatewayIpAddress $GatewayIpAddress -AddressPrefix $AddressPrefix

$GatewayPublicIpAddress = New-AzureRmPublicIpAddress -Name $PublicIpAddressName -ResourceGroupName $ResourceGroupName -Location $Location -AllocationMethod Dynamic

try{
    $VNet = Get-AzureRmVirtualNetwork -Name $AzureVNetName -ResourceGroupName $ResourceGroupName
}
catch{
    $Vnet = New-AzureRmVirtualNetwork -Name $AzureVNetName -ResourceGroupName $ResourceGroupName -Location $Location -AddressPrefix $AzureAddressPrefix
}
<#
$subnet1 = New-AzureRmVirtualNetworkSubnetConfig -Name 'GatewaySubnet' -AddressPrefix "10.55.30.248/29"
$subnet2 = New-AzureRmVirtualNetworkSubnetConfig -Name 'Subnet1' -AddressPrefix "10.55.30.0/25"
New-AzureRmVirtualNetwork -Name testvnet -ResourceGroupName $ResourceGroupName -Location $Location -AddressPrefix $AzureAddressPrefix -Subnet $subnet1, $subnet2
#>

if(!($GatewaySubnet = Get-AzureRmVirtualNetworkSubnetConfig -Name "GatewaySubnet" -VirtualNetwork $VNet))
{
    
    $GatewaySubnet = Add-AzureRmVirtualNetworkSubnetConfig -Name "GatewaySubnet" -VirtualNetwork $VNet -AddressPrefix $GatewaySubnetAddressPrefix
    
    Add-AzureRmVirtualNetworkSubnetConfig -Name $AzureVMSubnetName -VirtualNetwork $VNet -AddressPrefix $AzureAddressPrefix
}

$GatewayIpCfg = New-AzureRmVirtualNetworkGatewayIpConfig -Name $AzureGwCfgName -SubnetId $GatewaySubnet.Id -PublicIpAddressId $GatewayPublicIpAddress.Id

New-AzureRmVirtualNetworkGateway -Name $AzureVpnGw -ResourceGroupName $ResourceGroupName -Location $Location -IpConfigurations $GatewayIpCfg -GatewayType Vpn -VpnType RouteBased

Do
{
    $Gw = Get-AzureRmVirtualNetworkGateway -Name $AzureVpnGw -ResourceGroupName $ResourceGroupName
    Sleep-Sec
}
While($Gw.ProvisioningState -ne "Succeeded")

# add a do while here, exit on completion of vpn tunnel creation
<#
---
wait 15 min
---
#>

# $PreSharedKey = Get-AzureRmVirtualNetworkGatewayConnectionSharedKey -Name $AzureVpnGw -ResourceGroupName $ResourceGroupName

Get-AzureRmPublicIpAddress -Name $PublicIpAddressName -ResourceGroupName $ResourceGroupName

$gateway1 = Get-AzureRmVirtualNetworkGateway -Name $AzureVpnGw -ResourceGroupName $ResourceGroupName
$local = Get-AzureRmLocalNetworkGateway -Name $LocalNetworkGatewayName -ResourceGroupName $ResourceGroupName

if($PresharedKey)
{
    New-AzureRmVirtualNetworkGatewayConnection -Name $AzureVpnName -ResourceGroupName $ResourceGroupName -Location $Location -VirtualNetworkGateway1 $gateway1 -LocalNetworkGateway2 $local -ConnectionType IPsec -RoutingWeight 10 -SharedKey $PresharedKey
}
else
{
    New-AzureRmVirtualNetworkGatewayConnection -Name $AzureVpnName -ResourceGroupName $ResourceGroupName -Location $Location -VirtualNetworkGateway1 $gateway1 -LocalNetworkGateway2 $local -ConnectionType IPsec -RoutingWeight 10
}

# check to see if connection is there
 Get-AzureRmVirtualNetworkGatewayConnection -Name $AzureVpnName -ResourceGroupName $ResourceGroupName # -Debug