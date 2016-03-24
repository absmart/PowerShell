function Create-DomainForest {
    param(
        [string]$DomainName,
        [string]$DomainNetbiosName,
        [string]$DomainMode,
        [string]$ForestMode,
        $DsrmPass
    )
    
    Import-Module ServerManager

    Add-WindowsFeature AD-Domain-Services
    Import-Module ADDSDeployment

    $SecureDsrmPass = ConvertTo-SecureString -String $DsrmPass -AsPlainText -Force
    $LogPath = ('C:\Logs\DomainForestCreation' + (Get-Date -Format MMddyyyy_hmmss) + '.log')

    [hastable]$ForestDomainParams =@{
        DomainName = $DomainName
        DomainMode = 'Win2012R2'
        DomainNetbiosName = ''
        ForestMode = 'Win2012R2'    
        LogPath = $LogPath
    }

    Install-ADDSForest -DomainName $DomainName -DomainMode $DomainMode -DomainNetbiosName $DomainNetbiosName -ForestMode -InstallDns -LogPath $LogPath -SafeModeAdministratorPassword $SecureDsrmPass
}

function Create-AdRemoteAppUser {
    param(
        $Password
    )
    
    $Password = ConvertTo-SecureString '@8&asY]xa9[' -AsPlainText -Force # This is not a password I use, honest!
    New-ADUser -SamAccountName RemoteAppAuthUser -PasswordNeverExpires -AccountPassword
}