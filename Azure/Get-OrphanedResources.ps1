<#
.SYNOPSIS
This script is used to find VM resources leftover after the VM has been deleted in an Azure subscription.
All outputs are exported to CSV but this ps1 file can be sourced into a current session to use the function cmdlets.

#>
param(
    $ExportFolder
)

function Get-OrphanNetworkInterface {
    $results = @()
    $nics = Get-AzNetworkInterface | Where-Object { $null -eq $_.VirtualMachine }
    foreach ($nic in $nics) {
        $result = [PSCustomObject][ordered] @{
            NicName                      = $nic.Name
            ResourceGroupName            = $nic.ResourceGroupName
            ResourceGuid                 = $nic.ResourceGuid
            Id                           = $nic.Id
            MacAddress                   = $nic.MacAddress
            ipConfig1PrivateIp           = $nic.IpConfigurations[0].PrivateIpAddress
            ipConfig1PrivateIpAllocation = $nic.IpConfigurations[0].PrivateIpAllocationMethod
            ipConfig1PublicIp            = $nic.IpConfigurations[0].PublicIpAddress
            subnetId                     = $nic.IpConfigurations[0].Subnet[0].Id
            subnetName                   = $nic.IpConfigurations[0].Subnet[0].Name
            VirtualMachine               = $nic.VirtualMachine
        }
        $results += $result
    }
    return $results
}

function Get-OrphanManagedDisk {
    $results = @()

    $disks = Get-AzDisk | Where-Object { $null -eq $_.ManagedBy }
    foreach ($disk in $disks) {
        $result = [PSCustomObject][ordered] @{
            DiskName          = $disk.Name
            ResourceGroupName = $storageAccount.ResourceGroupName
            Sku               = $disk.Sku.Name
            TimeCreated       = $disk.TimeCreated
            OsType            = $disk.OsType
            HyperVGeneration  = $disk.HyperVGeneration
            DiskSizeGB        = $disk.DiskSizeGB
            ManagedBy         = $disk.ManagedBy
            Id                = $disk.Id
            Location          = $disk.Location
        }
        $results += $result
    }
    return $results
}

function Get-OrphanedUnmanagedDisk {
    param(
        $StorageAccountName,
        $StorageAccountResourceGroupName
    )

    # Set $results to an array type, allows us to add $result objects into the array
    $results = @()

    # Check if params were both provided, otherwise grab everything
    if ($null -eq $StorageAccountName -or $null -eq $StorageAccountResourceGroupName) {
        Write-Verbose -Message "Either the StorageAccountName or StorageAccountResourceGroupName was not provided, querying all storage accounts."
        $storageAccounts = Get-AzStorageAccount
    }
    else {
        Write-Verbose -Message "Getting properties from $StorageAccountName..."
        $storageAccounts = Get-AzStorageAccount -Name $StorageAccountName -ResourceGroupName $StorageAccountResourceGroupName
    }

    foreach ($storageAccount in $storageAccounts) {
        $ctx = $storageAccount.Context

        $containers = Get-AzStorageContainer -Context $ctx

        foreach ($container in $containers) {
            $blobs = Get-AzStorageBlob -Container $container.Name -Context $ctx

            $pageBlobs = $blobs | Where-Object { $_.BlobType -eq 'PageBlob' -and $_.Name.EndsWith('.vhd') }
            foreach ($pageBlob in $pageBlobs) {
                # Find all blobs that don't have a lease
                if ($pageBlob.ICloudBlob.Properties.LeaseStatus -eq 'Unlocked') {
                    # Create a new object array and add to results array
                    $result = [PSCustomObject][ordered] @{
                        BlobName          = $pageblob.Name
                        BlobType          = $pageBlob.BlobType
                        DiskSizeGB        = $pageBlob.Length / 1e+9
                        DiskSizeBytes     = $pageBlob.Length
                        LastModified      = $pageBlob.LastModified
                        Created           = $pageblob.ICloudBlob.Properties.Created
                        LeaseStatus       = $pageBlob.ICloudBlob.Properties.LeaseStatus
                        Container         = $container.Name
                        StorageAccount    = $storageAccount.StorageAccountName
                        StorageAccountSKU = $storageAccount.Sku.Name
                        ResourceGroupName = $storageAccount.ResourceGroupName
                    }
                    $results += $result
                }
            }
        }
    }
    return $results
}

$context = Get-AzContext

# Check if a context exists and can be used, stop if nothing is found.
if (!($context)) {
    Write-Host "No Azure context found, please connect with Connect-AzAccount and retry."
}
else
{
    $subscriptionId = $context.Subscription.Id
    if (!($ExportFolder)) {
        Write-Host "ExportFolder parameter not set, saving outputs to current directory." -ForegroundColor Yellow
        $ExportFolder = ".\"
    }

    Get-OrphanNetworkInterface | Export-Csv    -NoTypeInformation -Path ($ExportFolder + "\" + $subscriptionId + "-orphan-nic.csv")
    Get-OrphanManagedDisk | Export-Csv    -NoTypeInformation -Path ($ExportFolder + "\" + $subscriptionId + "-orphan-manageddisk.csv")
    Get-OrphanedUnmanagedDisk | Export-Csv    -NoTypeInformation -Path ($ExportFolder + "\" + $subscriptionId + "-orphan-unmanageddisk.csv")
}