param(
    [ValidateSet("CS","PS")]$ServerMode,
    $InstallPath = "$env:SystemDrive\Program Files (x86)\Microsoft Azure Site Recovery",
    $MySQLCredFilePath,
    $VaultCredFilePath,
    [ValidateSet("VMware","NonVMware")] $EnvType,
    $ProcessServerIPAddress,
    $ConfigurationServerIPAddress,
    $PassphraseFilePath = "$InstallPath\ASR_Passphrase.txt",
    [switch]$ByPassProxy,
    $ProxySettingsFilePath
)

UnifiedSetup.exe /ServerMode

if($ByPassProxy){
    UnifiedSetup.exe /ServerMode $ServerMode /InstallDrive $InstallPath /MySQLCredsFilePath $MySQLCredFilePath /VaultCredsFilePath $VaultCredFilePath /EnvType $EnvType /PSIP $ProcessServerIPAddress /CSIP $ConfigurationServerIPAddress /PassphraseFilePath $PassphraseFilePath
}
elseif($ProxySettingsFilePath){
    UnifiedSetup.exe /ServerMode $ServerMode /InstallDrive $InstallPath /MySQLCredsFilePath $MySQLCredFilePath /VaultCredsFilePath $VaultCredFilePath /EnvType $EnvType /PSIP $ProcessServerIPAddress /CSIP $ConfigurationServerIPAddress /PassphraseFilePath $PassphraseFilePath /ProxySettingsFilePath $ProxySettingsFilePath
}