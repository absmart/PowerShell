
$StorSub = Get-StorageSubSystem

foreach ($SubSystem in $StorSub) 
{
       if (($SubSystem.Model -eq "Clustered Storage Spaces") –and ($SubSystem.AutomaticClusteringEnabled -eq $true)) 
        {
            $SubSystem | Select Model,AutomaticClusteringEnabled
        }
       else {Write-Host "`n `t[ERROR] No clustered storage spaces found" -ForegroundColor Yellow}
} 