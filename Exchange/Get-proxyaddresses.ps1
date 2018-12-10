Get-ADUser -Filter * -SearchBase 'ou=testou,dc=iammred,dc=net' -Properties proxyaddresses |

select name, @{L='ProxyAddress_1'; E={$_.proxyaddresses[0]}},

@{L='ProxyAddress_2';E={$_.ProxyAddresses[1]}} |

Export-Csv -Path c:\fso\proxyaddresses.csv -NoTypeInformation