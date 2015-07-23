param(
    $ComputerName
)

Invoke-Command -ComputerName $ComputerName -ScriptBlock{

    $NetworkAdapter = Get-WmiObject Win32_NetworkAdapterConfiguration | where { -not [string]::IsNullorEmpty($_.IPAddress)  -and $_.IPEnabled -eq $true -and $_.IpAddress -ne "0.0.0.0" }
    
    $Table = @{
        ServerName = $env:COMPUTERNAME
        IpEnabled = $NetworkAdapter.IPEnabled
        IpAddress = $NetworkAdapter.IPAddress
        IpSubnet = $NetworkAdapter.IPSubnet
        DefaultIpGateway = $NetworkAdapter.DefaultIPGateway
        DhcpEnabled = $NetworkAdapter.DHCPEnabled
        DnsServers = $NetworkAdapter.DNSServerSearchOrder
        DnsDomain = $NetworkAdapter.DNSDomainSuffixSearchOrder
        MacAddress = $NetworkAdapter.MacAddress
    }
    
    $Results = New-Object -TypeName psobject -Property $Table

    return $Results
} | Export-Csv D:\IpInfo.csv -Append -NoTypeInformation