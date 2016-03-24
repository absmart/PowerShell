# Install ADDS Role and Setup Domain Services

Import-Module ServerManager

Add-WindowsFeature AD-Domain-Services
Import-Module ADDSDeployment

$DsrmPass = ConvertTo-SecureString -String '' -AsPlainText -Force
$LogPath = ('C:\Logs\DomainForestCreation' + (Get-Date -Format MMddyyyy_hmmss) + '.log')

[hastable]$ForestDomainParams =@{
    DomainName = ''
    DomainMode = 'Win2012R2'
    DomainNetbiosName = ''
    ForestMode = 'Win2012R2'    
    LogPath = $LogPath
}

$DSRMPassPhrase = ConvertTo-SecureString -String '' -AsPlainText -Force

Install-ADDSForest -DomainName abslab.com -DomainMode $DomainMode -DomainNetbiosName $DomainNetbiosName -ForestMode -InstallDns -LogPath $LogPath -SafeModeAdministratorPassword $DSRMPassPhrase

New-ADUser 

Get-Date -Format MMddyyyy_hmmss