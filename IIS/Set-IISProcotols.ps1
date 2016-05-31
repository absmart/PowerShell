# Disable insecure RC4 ciphers

foreach($KeyName in @(
        "RC4 128/128"
        "RC4 40/128"
        "RC4 56/128"
    )
)
{
    reg add HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\$KeyName /f
    reg add HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\$KeyName /v Enabled /d 0 /t REG_DWORD /f
}

# Disable SSLv3

New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0\Client" -ItemType Directory -Force
New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0\Server" -ItemType Directory -Force

New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0\Client" -PropertyType DWORD -Name DisabledByDefault -Value 1 -Force
New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0\Server" -PropertyType DWORD -Name Enabled -Value 0 -Force

# Disable SSLv2

New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 2.0\Client" -ItemType Directory -Force
New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 2.0\Server" -ItemType Directory -Force

New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 2.0\Client" -PropertyType DWORD -Name DisabledByDefault -Value 1 -Force
New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 2.0\Server" -PropertyType DWORD -Name Enabled -Value 0 -Force