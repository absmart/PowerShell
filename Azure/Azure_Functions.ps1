Import-Module Azure
Add-AzureAccount

function ConnectTo-AzureInstance {
    param(
        $Subscription
    )

    if(!($Subscription)){
        Get-AzureSubscription
        $Subscription = Read-Host "Enter the Azure subscription:"
        Select-AzureSubscription $Subscription
    }
    else
    {
        Select-AzureSubscription $Subscription
    }
    Add-AzureAccount -Credential
}

function Get-AzureImageName {
    param(
        [ValidateSet("Windows","Linux")]$OS,
        $Keyword
        )

    $ImageList = Get-AzureVMImage | Where {$_.OS -eq $OS -and $_.Label -match $Keyword} | Sort-Object CreatedTime
    return $ImageList
}

function Get-AzureAvailableVmSizes {
    param(
        $Location = "Central US"
    )

    $AvailableSizes = (Get-AzureLocation | Where {$_.name -eq $Location}).VirtualMachineRoleSizes

    return $AvailableSizes
}

function Get-AzureRdp {
    param(
        $Name,
        $ServiceName
    )

    $Vm = Get-AzureVM –ServiceName $ServiceName –Name $Name
    $Rdp = $vm | Get-AzureEndpoint
    $HostDns = (New-Object "System.Uri" $Vm.DNSName).Authority
    $Port = $Rdp | Where {$_.Name -eq "RemoteDesktop"} | Select Port -ExpandProperty Port

    Start-Process "mstsc" -ArgumentList "/V:$HostDns`:$Port /w:1024 /h:768"
}

function Setup-AzureLab {
    param(
        $Location = "Central US",
        $LabName,
        $StoageAccountName,
        $AutomationAccountName
    )

    New-AzureAffinityGroup -Name $LabName
    New-AzureStorageAccount -StorageAccountName $StoageAccountName -AffinityGroup $LabName
    New-AzureService -ServiceName $LabName -Location $Location
    New-AzureAutomationAccount -Name $AutomationAccountName -Location $Location
}

function New-AzureVmWindows {
    param(
        $VmName,
        $VmSize = "Small",
        $Image = "a699494373c04fc0bc8f2bb1389d6106__Windows-Server-2012-R2-201506.01-en.us-127GB.vhd",
        $AdminUsername,
        $AdminPassword,
        $Location = "Central US",
        $LabName,
        $VnetName,
        $StoageAccountName,
        $AutomationAccountName
    )

    $AzureVM = New-AzureVMConfig -Name $VmName -InstanceSize $VmSize -ImageName $Image -Verbose
    $AzureVM = New-AzureVMConfig -Name $VmName -InstanceSize $VmSize -ImageName $Image -Verbose
    $AzureVM | Add-AzureProvisioningConfig -Windows -AdminUsername $AdminUsername -Password $AdminPassword -Verbose
    $AzureVM | New-AzureVM -ServiceName $LabName -Location $Location -Verbose -AffinityGroup $LabName
}