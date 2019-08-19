<#
.SYNOPSIS
This script is used to verify that the AutomaticClustering feature is not enabled on a VM. This feature can cause
serious issues with Azure VMs using Storage Spaces to stripe multiple disks and should not be enabled.

#>
$StorSub = Get-StorageSubSystem

foreach ($SubSystem in $StorSub) 
{
       if (($SubSystem.Model -eq "Clustered Storage Spaces") –and ($SubSystem.AutomaticClusteringEnabled -eq $true)) 
        {
            $SubSystem | Select Model,AutomaticClusteringEnabled
        }
       else {Write-Host "`n `t[ERROR] No clustered storage spaces found" -ForegroundColor Yellow}
} 
