param(
    [Parameter(Mandatory=$true)]
    $apiKey
)

# Enforce TLS 1.2. This is a requirement for the Meraki API.
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$headers = @{
    'X-Cisco-Meraki-API-Key' = $apiKey
}

# Get the organization Ids
$orgId = (Invoke-RestMethod -Method Get -Uri https://api.meraki.com/api/v0/organizations/ -Headers $headers).Id
Invoke-RestMethod -Method Get -Uri https://api.meraki.com/api/v0/organizations/ -Headers $headers | ConvertTo-Json | Out-File .\$orgId-organization.json

# Get all organization networks
Invoke-RestMethod -Method Get -Uri https://api.meraki.com/api/v0/organizations/$orgId/networks -Headers $headers | ConvertTo-Json | Out-File .\$orgId-networks.json

# Get all org-level properties
Invoke-RestMethod -Method Get -Uri https://api.meraki.com/api/v0/organizations/$orgId/admins -Headers $headers | ConvertTo-Json | Out-File .\$orgId-admins.json
Invoke-RestMethod -Method Get -Uri https://api.meraki.com/api/v0/organizations/$orgId/licenseState -Headers $headers | ConvertTo-Json | Out-File .\$orgId-licenseState.json
Invoke-RestMethod -Method Get -Uri https://api.meraki.com/api/v0/organizations/$orgId/inventory -Headers $headers | ConvertTo-Json | Out-File .\$orgId-inventory.json

# Get all networks and network-level properties, export to JSON
$networks = Invoke-RestMethod -Method Get -Uri https://api.meraki.com/api/v0/organizations/$orgId/networks -Headers $headers

foreach($network in $networks){
    $networkId = $network.Id

    # Network
    Invoke-RestMethod -Method Get -Headers $headers -Uri https://api.meraki.com/api/v0/networks/$networkId | ConvertTo-Json | Out-File .\$networkId-network.json
    Invoke-RestMethod -Method Get -Headers $headers -Uri https://api.meraki.com/api/v0/networks/$networkId/accessPolicies | ConvertTo-Json | Out-File .\$networkId-accessPolicies.json
    Invoke-RestMethod -Method Get -Headers $headers -Uri https://api.meraki.com/api/v0/networks/$networkId/staticRoutes | ConvertTo-Json | Out-File .\$networkId-staticRoutes.json
    Invoke-RestMethod -Method Get -Headers $headers -Uri https://api.meraki.com/api/v0/networks/$networkId/ssids | ConvertTo-Json | Out-File .\$networkId-ssids.json
    Invoke-RestMethod -Method Get -Headers $headers -Uri https://api.meraki.com/api/v0/networks/$networkId/syslogServers | ConvertTo-Json | Out-File .\$networkId-syslogServers.json
    Invoke-RestMethod -Method Get -Headers $headers -Uri https://api.meraki.com/api/v0/networks/$networkId/vlans | ConvertTo-Json | Out-File .\$networkId-vlans.json
    Invoke-RestMethod -Method Get -Headers $headers -Uri https://api.meraki.com/api/v0/networks/$networkId/siteToSiteVpn | ConvertTo-Json | Out-File .\$networkId-siteToSiteVpn.json
    Invoke-RestMethod -Method Get -Headers $headers -Uri https://api.meraki.com/api/v0/networks/$networkId/firewalledServices | ConvertTo-Json | Out-File .\$networkId-firewalledServices.json
    Invoke-RestMethod -Method Get -Headers $headers -Uri https://api.meraki.com/api/v0/networks/$networkId/contentFiltering | ConvertTo-Json | Out-File .\$networkId-contentFiltering.json

    # Switch
    Invoke-RestMethod -Method Get -Headers $headers -Uri https://api.meraki.com/api/v0/networks/$networkId/switch/accessControlLists | ConvertTo-Json | Out-File .\$networkId-switch-accessControlLists.json
    Invoke-RestMethod -Method Get -Headers $headers -Uri https://api.meraki.com/api/v0/networks/$networkId/switch/settings/dhcpServerPolicy | ConvertTo-Json | Out-File .\$networkId-switch-dhcpServerPolicy.json
    Invoke-RestMethod -Method Get -Headers $headers -Uri https://api.meraki.com/api/v0/networks/$networkId/switch/settings/dhcpServerPolicy | ConvertTo-Json | Out-File .\$networkId-switch-accessControlLists.json

    # Firewall
    Invoke-RestMethod -Method Get -Headers $headers -Uri https://api.meraki.com/api/v0/networks/$networkId/l3FirewallRules | ConvertTo-Json | Out-File .\$networkId-l3FirewallRules.json

    # SSIDs
    Invoke-RestMethod -Method Get -Headers $headers -Uri https://api.meraki.com/api/v0/networks/$networkId/ssids | ConvertTo-Json | Out-File .\$networkId-ssids.json
}