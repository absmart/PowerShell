param(
    $NewComputerName
)

Get-NetFirewallRule -DisplayGroup "Remote Desktop*" | Enable-NetFirewallRule
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server' -Name fDenyTSConnections -Value 0

Rename-Computer -NewName $ComputerName
Restart-Computer