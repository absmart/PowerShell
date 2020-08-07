#Requires -Modules Az.RecoveryServices, Az.Resources

param(
    $tenantId,
    $subscriptionId,
    $recoveryServicesVaultName,
    $recoveryServicesVaultResourceGroup,
    $sourceVm,
    $targetVm
)
$logFile = ".\Restore-AzureBackupSQLVm.log"

# All dataases in array to be refreshed on targetVm
$databases = @(
    ""
)

# Authenticate to Azure and set subscription
Import-Module -Name Az.Resources # Imports the PSADPasswordCredential object
Import-Module -Name Az.RecoveryServices
# SPN Method to Auth
# $secureSpSecret = ConvertTo-SecureString -String $spSecret -AsPlainText -Force
# $pscredential = New-Object System.Management.Automation.PSCredential $spApplicationId, $secureSpSecret
#Connect-AzAccount -ServicePrincipal -Credential $pscredential -Tenant $tenantId

# If no SPN, authenticate interactively
Connect-AzAccount

Select-AzSubscription -Subscription $subscriptionId

(Get-Date -Format "yyyy/MM/dd hh:MM:ss") + " : Beginning restore process." | Add-content $logfile

$vault = Get-AzRecoveryServicesVault -ResourceGroupName $recoveryServicesVaultResourceGroup -Name $recoveryServicesVaultName

foreach ($database in $databases) {
    Write-Host "$database : BEGIN" -ForegroundColor Yellow
    $databaseBackupName = "SQLDataBase;MSSQLSERVER;" + $database

    # Get the recovery point for the restore
    $backupItemSplat = @{
        BackupManagementType = "AzureWorkload"
        WorkloadType         = "MSSQL"
        VaultId              = $vault.ID
    }

    $bkpItem = Get-AzRecoveryServicesBackupItem @backupItemSplat -Name $databaseBackupName | Where-Object { $_.ServerName -eq $sourceVm -and $_.Name -eq $databaseBackupName }

    $startDate = (Get-Date).AddDays(-7).ToUniversalTime()
    $endDate = (Get-Date).ToUniversalTime()
    $recoveryPoints = Get-AzRecoveryServicesBackupRecoveryPoint -Item $bkpItem -VaultId $vault.ID -StartDate $startdate -EndDate $endDate

    $recoveryPoint = $recoveryPoints | Sort-Object -Property RecoveryPointTime -Descending | Select-Object -First 1

    # Get the MSSQL registered target server
    $targetInstance = Get-AzRecoveryServicesBackupProtectableItem -WorkloadType MSSQL -VaultId $vault.ID -ServerName $targetVm

    # Setup recovery configuration and update to in-place restore
    $AnotherInstanceWithFullConfig = Get-AzRecoveryServicesBackupWorkloadRecoveryConfig -RecoveryPoint $recoveryPoint -TargetItem $targetInstance -AlternateWorkloadRestore -VaultId $vault.ID

    # Set the restore configuration to overwrite existing database
    $AnotherInstanceWithFullConfig.RestoredDBName = $database
    $AnotherInstanceWithFullConfig.targetPhysicalPath[0].TargetPath = $AnotherInstanceWithFullConfig.targetPhysicalPath[0].SourcePath
    $AnotherInstanceWithFullConfig.targetPhysicalPath[1].TargetPath = $AnotherInstanceWithFullConfig.targetPhysicalPath[1].SourcePath
    $AnotherInstanceWithFullConfig.OverwriteWLIfpresent = "Yes"

    (Get-Date -Format "yyyy/MM/dd hh:MM:ss") + " : RESTORING DATABASE : $database to " + ($targetInstance.ServerName | Out-String) | Add-content $logfile
    Write-Host "$database : RESTORING to " $targetVm -ForegroundColor Yellow
    $restoreJob = Restore-AzRecoveryServicesBackupItem -WLRecoveryConfig $AnotherInstanceWithFullConfig -VaultId $vault.ID # Comment this out to not perform restores
    (Get-Date -Format "yyyy/MM/dd hh:MM:ss") + " : RESTORING DATABASE : $database : JOB ID: " + ($restoreJob.JobID | Out-String ) | Add-content $logfile

    Write-Host "$database : COMPLETE" -ForegroundColor Yellow
}

$day = (Get-Date).AddDays(-1).ToUniversalTime()
$restoreJobs = Get-AzRecoveryServicesBackupJob -VaultId $vault.id | Where-Object { $_.StartTime -gt $day -and $_.Operation -match "Restore" }

while ($restoreJobs) {
    Start-Sleep -Seconds 15
    Write-Host "Finding all jobs not in Completed status..." -ForegroundColor Yellow
    $restoreJobs = Get-AzRecoveryServicesBackupJob -VaultId $vault.id | Where-Object { $_.StartTime -gt $day -and $_.Operation -match "Restore" -and $_.Status -eq "InProgress" }
}

(Get-Date -Format "yyyy/MM/dd hh:MM:ss") + " : No more jobs in the InProgress status. All backup jobs are completed." | Add-content $logfile
Write-Host "All jobs completed." -ForegroundColor Yellow