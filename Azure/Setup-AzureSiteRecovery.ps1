param(
    $UserName = "",
    $Password = "",
    $AzureSubscriptionName = "",
    $VaultName = "ASR-Vault-01",
    $VaultLocation = "Central US",
    $OutputPathForSettingsFile = "C:\",
    $StorageAccountName = "ASR-StorageAccount-01",
    $StorageAccountLocation = "Central US"
)

# ASR Setup

#Invoke-WebRequest http://aka.ms/downloaddra - # URI for Azure Site Recovery Provider used for VMM and Hyper-V.

# Subscription

$UserName = "<user@live.com>"
$Password = "<password>"
$AzureSubscriptionName = "prod_sub1"
# Login-AzureRmAccount -Tenant "fabrikam.com"  # If we're logging into a tenant account via partner

$SecurePassword = ConvertTo-SecureString -AsPlainText $Password -Force
$Cred = New-Object System.Management.Automation.PSCredential -ArgumentList $UserName, $securePassword
Add-AzureAccount -Credential $Cred;
$AzureSubscription = Select-AzureSubscription -SubscriptionName $AzureSubscriptionName

# Site Recovery Vault

New-AzureSiteRecoveryVault -Location $VaultGeo -Name $VaultName;
$vault = Get-AzureSiteRecoveryVault -Name $VaultName;

# Generate a vault registration key

$VaultSetingsFile = Get-AzureSiteRecoveryVaultSettingsFile -Location $VaultGeo -Name $VaultName -Path $OutputPathForSettingsFile;

$VaultSettingFilePath = $vaultSetingsFile.FilePath 
$VaultContext = Import-AzureSiteRecoveryVaultSettingsFile -Path $VaultSettingFilePath -ErrorAction Stop

# Create a storage account

New-AzureStorageAccount -StorageAccountName $StorageAccountName -Label $StorageAccountName -Location $StorageAccountGeo;