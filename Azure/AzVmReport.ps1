param(
    $TenantId = "f329fa8a-e153-4a37-b822-f91dcb799aa4",
    $Path = "C:\temp\"
)

Login-AzAccount -TenantId $TenantId

$subscriptions = Get-AzSubscription -TenantId $TenantId

$output = @()

foreach ($subscription in $subscriptions) {
    Select-AzSubscription -SubscriptionId $subscription.Id

    $vms = Get-AzVm -Status

    foreach ($vm in $vms) {
        $result = [PSCustomObject] @{
            Name                        = $vm.Name
            ResourceGroupName           = $vm.ResourceGroupName
            Location                    = $vm.Location
            VmSize                      = $vm.HardwareProfile.VmSize
            PowerState                  = $vm.PowerState
            ImagePublisher              = $vm.StorageProfile.ImageReference.Publisher
            ImageOffer                  = $vm.StorageProfile.ImageReference.Offer
            Sku                         = $vm.StorageProfile.ImageReference.Sku
            Version                     = $vm.StorageProfile.ImageReference.Version
            BootDiagnosticsEnabled      = $vm.DiagnosticsProfile.BootDiagnostics.Enabled
            BootDiagnosticsStorageUri   = $vm.DiagnosticsProfile.BootDiagnostics.StorageUri
            Id                          = $vm.Id
        }
        $output += $result
    }
}

return $output
