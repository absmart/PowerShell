if(!(Get-Module -Name *Vmware*)){Write-Error -Message "VMWare modules not found! Run this script within a PowerCLI window." -ErrorAction Stop}

$vms = Get-VM

foreach($vm in $vms)
{
    # Get the VM information
    $result = $vm | select Name,PowerState,NumCpu,MemoryGB,ProvisionedSpaceGB,UsedSpaceGB,Version
    $result | Add-Member -MemberType NoteProperty -Name OperatingSystem -Value $vm.Guest.OSFullName
    $result | Add-Member -MemberType NoteProperty -Name State -Value $vm.Guest.State
    $result | Add-Member -MemberType NoteProperty -Name Host -Value $_.VMHost.Name
    $result | Add-Member -MemberType NoteProperty -Name Firmware -Value $_.ExtensionData.Config.Firmare

    $result | Export-Csv C:\temp\vmInfo.csv -NoTypeInformation -Append

    # Get the network adapters and dump them to their own CSV file
    foreach($networkAdapter in $vm.NetworkAdapters){
    
        $nic = New-Object -TypeName psobject
        $nic | Add-Member -MemberType NoteProperty -Name vmName -Value $networkAdapter.Parent.Name
        $nic | Add-Member -MemberType NoteProperty -Name nicName -Value $networkAdapter.Name
        $nic | Add-Member -MemberType NoteProperty -Name connected -Value $networkAdapter.ConnectionState.Connected
        $nic | Add-Member -MemberType NoteProperty -Name networkName -Value $networkAdapter.NetworkName
        $nic | Add-Member -MemberType NoteProperty -Name nicType -Value $networkAdapter.Type
        
        $nic | Export-Csv -NoTypeInformation -Path C:\temp\nicInfo.csv -Append
    }

    # Get the hard disks and add them to the object
    foreach($disk in $vm.HardDisks){
        
        # Name, Filename,DiskType,StorageFormat,CapacityGB,Parent
        $hdd = New-Object -TypeName psobject
        $hdd | Add-Member -MemberType NoteProperty -Name vmName -Value $disk.Parent.Name
        $hdd | Add-Member -MemberType NoteProperty -Name diskName -Value $disk.Name
        $hdd | Add-Member -MemberType NoteProperty -Name diskType -Value $disk.DiskType
        $hdd | Add-Member -MemberType NoteProperty -Name storageFormat -Value $disk.StorageFormat

        $hdd | Export-Csv -NoTypeInformation -Path C:\temp\diskInfo.csv -Append
    }
}