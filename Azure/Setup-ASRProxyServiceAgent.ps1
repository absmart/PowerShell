param(
    $PortNumb = 9443, # Or the proxy port defined during installation
    $Domain, # The domain used to authenticate with the proxy
    $UserName, # The user on the domain to authenticate with the proxy
    $ProxyUserPassword, # UserName's password
    $ProxyServerURL # URL of the proxy server
)

$pwd = ConvertTo-SecureString -String $ProxyUserPasswordSet-OBMachineSetting -ProxyServer $ProxyServerURL -ProxyPort $PortNumb – ProxyUserName $Domain\$UserName -ProxyPassword $pwdnet stop obengine.exe