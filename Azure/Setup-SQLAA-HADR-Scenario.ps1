Import-Module "C:\Program Files (x86)\Microsoft SDKs\Azure\PowerShell\Azure\Azure.psd1"
Get-AzurePublishSettingsFile
Import-AzurePublishSettingsFile C:\Keys\AzurePubSettingsFile.publishsettings

$location = "Central US"
$affinityGroupName = "ABS-SQLAA-Demo"
$affinityGroupDescription = "SQL HA with AlwaysOn Demo"
$affinityGroupLabel = "SQL HA IaaS Affinity Group"
$networkConfigPath = (Join-Path $env:POWERSHELL_HOME "\Azure\Config\SQLAADemo.xml")
$virtualNetworkName = "ABS-SQLAA-VNET"
$storageAccountName = "abssqlaademo"
$storageAccountLabel = "ABS SQL HADR Storage Account"
$storageAccountContainer = "https://" + $storageAccountName + ".blob.core.windows.net/vhds/"
$winImageName = (Get-AzureVMImage | where {$_.Label -like "Windows Server 2008 R2 SP1*"} | sort PublishedDate -Descending)[0].ImageName
$sqlImageName = (Get-AzureVMImage | where {$_.Label -like "SQL Server 2012 SP1 Enterprise*"} | sort PublishedDate -Descending)[0].ImageName
$dcServerName = "ABSSQLDC"
$dcServiceName = "abssqldemoservice"
$availabilitySetName = "SQLHADR"
$vmAdminUser = "AzureAdmin"
$vmAdminPassword = (Read-Host "Enter a password for $vmAdminUser : ")
$workingDir = "c:\scripts\"

# Create the Affinity Group

New-AzureAffinityGroup `
    -Name $affinityGroupName `
    -Location $location `
    -Description $affinityGroupDescription `
    -Label $affinityGroupLabel


# Set the configuration path for the network config
Set-AzureVNetConfig `
    -ConfigurationPath $networkConfigPath

# Create a storage account
New-AzureStorageAccount `
    -StorageAccountName $storageAccountName `
    -Label $storageAccountLabel `
    -AffinityGroup $affinityGroupName
Set-AzureSubscription `
    -SubscriptionName (Get-AzureSubscription).SubscriptionName `
    -CurrentStorageAccount $storageAccountName

# Create a domain controller and availability set

New-AzureVMConfig `
    -Name $dcServerName `
    -InstanceSize Medium `
    -ImageName $winImageName `
    -MediaLocation "$storageAccountContainer$dcServerName.vhd" `
    -DiskLabel "OS" |
Add-AzureProvisioningConfig `
    -Windows `
    -DisableAutomaticUpdates `
    -AdminUserName $vmAdminUser `
    -Password $vmAdminPassword |
New-AzureVM `
    -ServiceName $dcServiceName `
    –AffinityGroup $affinityGroupName `
    -VNetName $virtualNetworkName


# Wait for the VM to be provisioned and download the rdp file

$VMStatus = Get-AzureVM -ServiceName $dcServiceName -Name $dcServerName

While ($VMStatus.InstanceStatus -ne "ReadyRole")
{
    write-host "Waiting for " $VMStatus.Name "... Current Status = " $VMStatus.InstanceStatus
    Start-Sleep -Seconds 15
    $VMStatus = Get-AzureVM -ServiceName $dcServiceName -Name $dcServerName
}

Get-AzureRemoteDesktopFile `
    -ServiceName $dcServiceName `
    -Name $dcServerName `
    -LocalPath "$workingDir$dcServerName.rdp"