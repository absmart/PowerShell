function Fix-HyperV
{
    # Remove IP Address from NAT vSwitch
    $IPAddress = (Get-NetIPAddress -InterfaceAlias "vEthernet (Default Switch)").IPAddress
    Remove-NetIPAddress -IPAddress $IPAddress -Confirm:$false
    Start-Sleep -Seconds 5

    # Assign IP Address to NAT vSwitch
    New-NetIPAddress -InterfaceAlias "vEthernet (Default Switch)" -IPAddress "192.168.149.1" -PrefixLength 24
    Start-Sleep -Seconds 5

    if (-not (Get-NetNat).Active) {
        New-NetNAT -Name HVNAT -InternalIPInterfaceAddressPrefix 192.168.149.0/24
        Start-Sleep -Seconds 5
    } else {
        Remove-NetNat -Name HVNAT -Confirm:$false
        Start-Sleep -Seconds 10
        New-NetNAT -Name HVNAT -InternalIPInterfaceAddressPrefix 192.168.149.0/24
        Start-Sleep -Seconds 5
    }

    #Start-VM -Name "VM01"
}
