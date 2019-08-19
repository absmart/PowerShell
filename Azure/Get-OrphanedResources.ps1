function orphanedDisks {
    Get-AzDisk | Where-Object {$null -eq $_.ManagedBy}
}

function orphanedNics {
    Get-AzNetworkInterface | Where-Object {$null -eq $_.VirtualMachine}
}
