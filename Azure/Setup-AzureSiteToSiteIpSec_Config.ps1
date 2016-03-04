# https://azure.microsoft.com/en-us/documentation/articles/vpn-gateway-create-site-to-site-rm-powershell/

param(
    $SubscriptionId,
    $ClientAbbreviation = "ABS",
    $ResourceGroupName = "ABS-Cloud-01",
    $PresharedKey,
    $ConfigFile = (Join-Path $env:POWERSHELL_HOME "\Azure\Config\SiteToSiteVPNConfig.xml")
)

Import-AzureRM

try{Get-AzureRmSubscription}
catch{Login-AzureRmAccount}

Select-AzureRmSubscription -Subscriptionid $SubscriptionId

[xml] $xml = Get-Content $ConfigFile

$Config = $xml.NetworkConfiguration.VirtualNetworkConfiguration

[System.Collections.ArrayList] $DnsServers = @()
foreach($Server in ($Config.Dns.DnsServers.DnsServer).IPAddress)
{
    $DnsServers.Add($Server)
}

if(!($ResourceGroupName)){
    $ResourceGroupName = ($ClientAbbreviation + "-AzureResGrp")
}

$LocalGatewayIpAddress = $Config.LocalNetworkSites.LocalNetworkSite.VPNGatewayAddress
$LocalNetworkGatewayName = $Config.LocalNetworkSites.LocalNetworkSite.name
[System.Collections.ArrayList] $LocalAddressPrefix = @()
foreach($Subnet in $Config.LocalNetworkSites.LocalNetworkSite.AddressSpace.AddressPrefix){ $LocalAddressPrefix.Add($Subnet) }

$AzureAddressPrefix = $Config.VirtualNetworkSites.VirtualNetworkSite.AddressSpace.AddressPrefix
$AzureVMSubnetName = $Config.VirtualNetworkSites.VirtualNetworkSite.name
$AzureVnetLocation = $Config.VirtualNetworkSites.VirtualNetworkSite.Location
$GatewaySubnetAddressPrefix = ($Config.VirtualNetworkSites.VirtualNetworkSite.Subnets.Subnet | Where-Object {$_.name -eq "GatewaySubnet"}).AddressPrefix

$ConnectionType = $Config.VirtualNetworkSites.VirtualNetworkSite.Gateway.ConnectionsToLocalNetwork.LocalNetworkSiteRef.Connection.type
$RouteType = $Config.VirtualNetworkSites.VirtualNetworkSite.Gateway.ConnectionsToLocalNetwork.LocalNetworkSiteRef.Policy.name

####
$AzureVMSubnet = $Config.VirtualNetworkSites.VirtualNetworkSite.Subnets.Subnet | Where-Object {$_.name -ne "GatewaySubnet"}
####
$AzureVMSubnet
#####

$PublicIpAddressName = ($ClientAbbreviation + "-AzurePubIp")
$AzureVNetName = ($ClientAbbreviation + "-AzureVNet")
$AzureGwCfgName = ($ClientAbbreviation + "-AzureGWCfg")
$AzureVpnGw = ($ClientAbbreviation + "-AzureVpnGw")
$AzureVpnName = ($ClientAbbreviation + "-AzureVPN")

if(!(Get-AzureRmResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue)){
    New-AzureRmResourceGroup -Name $ResourceGroupName -Location $Location
}

New-AzureRmLocalNetworkGateway -Name $LocalNetworkGatewayName -ResourceGroupName $ResourceGroupName -Location $AzureVnetLocation -GatewayIpAddress $LocalGatewayIpAddress -AddressPrefix $AddressPrefix

$GatewayPublicIpAddress = New-AzureRmPublicIpAddress -Name $PublicIpAddressName -ResourceGroupName $ResourceGroupName -Location $AzureVnetLocation -AllocationMethod Dynamic

try{
    $VNet = Get-AzureRmVirtualNetwork -Name $AzureVNetName -ResourceGroupName $ResourceGroupName
}
catch{
    $Vnet = New-AzureRmVirtualNetwork -Name $AzureVNetName -ResourceGroupName $ResourceGroupName -Location $AzureVnetLocation -AddressPrefix $AzureAddressPrefix
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

New-AzureRmVirtualNetworkGateway -Name $AzureVpnGw -ResourceGroupName $ResourceGroupName -Location $AzureVnetLocation -IpConfigurations $GatewayIpCfg -GatewayType Vpn -VpnType $RouteType

Do
{
    $Gw = Get-AzureRmVirtualNetworkGateway -Name $AzureVpnGw -ResourceGroupName $ResourceGroupName
    Sleep-Seconds
}
While($Gw.ProvisioningState -ne "Succeeded")

# $PreSharedKey = Get-AzureRmVirtualNetworkGatewayConnectionSharedKey -Name $AzureVpnGw -ResourceGroupName $ResourceGroupName

Get-AzureRmPublicIpAddress -Name $PublicIpAddressName -ResourceGroupName $ResourceGroupName

$Gateway = Get-AzureRmVirtualNetworkGateway -Name $AzureVpnGw -ResourceGroupName $ResourceGroupName
$Local = Get-AzureRmLocalNetworkGateway -Name $LocalNetworkGatewayName -ResourceGroupName $ResourceGroupName

if($PresharedKey)
{
    New-AzureRmVirtualNetworkGatewayConnection -Name $AzureVpnName -ResourceGroupName $ResourceGroupName -Location $AzureVnetLocation -VirtualNetworkGateway1 $Gateway -LocalNetworkGateway2 $Local -ConnectionType $ConnectionType -RoutingWeight 10 -SharedKey $PresharedKey
}
else
{
    New-AzureRmVirtualNetworkGatewayConnection -Name $AzureVpnName -ResourceGroupName $ResourceGroupName -Location $AzureVnetLocation -VirtualNetworkGateway1 $Gateway -LocalNetworkGateway2 $Local -ConnectionType $ConnectionType -RoutingWeight 10
}

Get-AzureRmVirtualNetworkGatewayConnection -Name $AzureVpnName -ResourceGroupName $ResourceGroupName