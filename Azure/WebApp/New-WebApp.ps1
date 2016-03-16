# https://azure.microsoft.com/en-us/documentation/articles/web-sites-staged-publishing/

$WebAppName = "AzureWebAppTest"
$WebAppResourceGroupName = "WebApp"
$AzureNetworkResourceGroupName = "AzureNetwork"
$Location = "northcentralus"

# Create resource groups for the webapp and network to peer to
$rgWebApp = New-AzureRmResourceGroup -Name $WebAppResourceGroupName -Location $Location
$rgAzureNetwork = New-AzureRmResourceGroup -Name $AzureNetworkResourceGroupName -Location $Location

$ServicePlan = New-AzureRmAppServicePlan -Location $Location `
                                        `-Tier Standard `
                                        `-NumberofWorkers 1 `
                                        `-WorkerSize Small `
                                        `-ResourceGroupName $WebAppResourceGroupName `
                                        `-Name WebAppPlan-Standard

# Create web app
$WebApp = New-AzureRmWebApp -ResourceGroupName $rgWebApp.ResourceGroupName -Name $WebAppName -Location $rgWebApp.Location -AppServicePlan $ServicePlan.Name

# Create a deployment slot for a web app
New-AzureRmWebAppSlot -ResourceGroupName $rgWebApp.ResourceGroupName -Name $WebAppName -Slot "Development" -AppServicePlan $ServicePlan.Name
New-AzureRmWebAppSlot -ResourceGroupName $rgWebApp.ResourceGroupName -Name $WebAppName -Slot "Staging" -AppServicePlan $ServicePlan.Name

# Create a new Traffic Manager profile and assign to site
$TmProfile = New-AzureRmTrafficManagerProfile -Name $WebAppName `
                                -ResourceGroupName $rgWebApp.ResourceGroupName `
                                -RelativeDnsName absazurewebapptest `
                                -TrafficRoutingMethod Performance `
                                -MonitorProtocol HTTP `
                                -RelativeDnsName absazurewebapptest `
                                -Ttl 600 `
                                -MonitorPort 80 `
                                -MonitorPath "/"

# Create endpoint configuration and apply to TM profile
Add-AzureRmTrafficManagerEndpointConfig -EndpointName EndPointPrimary -TrafficManagerProfile $TmProfile -Type AzureEndpoints -TargetResourceId $WebApp.Id -EndpointStatus Enabled
Set-AzureRmTrafficManagerProfile -TrafficManagerProfile $TmProfile
