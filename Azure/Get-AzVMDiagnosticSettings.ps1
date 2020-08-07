function Get-AzVMDiagnosticSetting {

    $vms = Get-AzVM -Status

    $results = @()

    foreach ($vm in $vms) {
        $result = [PSCustomObject][ordered] @{
            Name                         = $vm.Name
            ResourceGroupName            = $vm.ResourceGroupName
            BootDiagnosticsEnabled       = $vm.DiagnosticsProfile.BootDiagnostics.Enabled
            BootDiagnosticsStorageUri    = $vm.DiagnosticsProfile.BootDiagnostics.StorageUri
            Id                           = $vm.Id
        }
        $results += $result
    }
    return $results
}

Get-AzVMDiagnosticSetting | Format-Table