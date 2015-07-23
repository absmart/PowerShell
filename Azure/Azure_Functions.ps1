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
        $LabName = "ABSLab",
        $StoageAccountName = "abslabstorage",
        $AutomationAccountName = "ABSAutomation"
    )

    New-AzureAffinityGroup -Name $LabName
    New-AzureStorageAccount -StorageAccountName $StoageAccountName -AffinityGroup $LabName
    New-AzureService -ServiceName $LabName -Location $Location
    New-AzureAutomationAccount -Name $AutomationAccountName -Location $Location
}

function New-ABSAzureVmWindows {
    param(
        $VmName,
        $VmSize = "Small",
        $Image = "a699494373c04fc0bc8f2bb1389d6106__Windows-Server-2012-R2-201506.01-en.us-127GB.vhd",
        $AdminUsername = "alexadmin",
        $AdminPassword = "supersecurepasswordhere",
        #[ValidateSet("Windows","Linux")]$OsType,
        $Location = "Central US",
        $LabName = "ABSLab",
        $StoageAccountName = "abslabstorage",
        $AutomationAccountName = "ABSAutomation"
    )
    <#
    if(!($Image))
    { 
        $Image = Get-AzureImageName -OS Windows -Keyword "Windows Server 2012 R2 Datacenter"
        $ImageName = $Image[0].ImageName
    }
    else { $ImageName = $Image.ImageName }
    #>
    $ImageName = $Image
    $VnetName = "Group ABS01-RGroup ABS01-VNet"

    $AzureVM = New-AzureVMConfig -Name $VmName -InstanceSize $VmSize -ImageName $ImageName -Verbose
    $AzureVM = New-AzureVMConfig -Name $VmName -InstanceSize $VmSize -ImageName $ImageName -Verbose
    $AzureVM | Add-AzureProvisioningConfig -Windows -AdminUsername $AdminUsername -Password $AdminPassword -Verbose
    $AzureVM | New-AzureVM -ServiceName $LabName -Location $Location -Verbose -AffinityGroup $LabName


    <#
    switch ($OsType)
    {
        "Windows" {
            $AzureVM | Add-AzureProvisioningConfig -Windows -AdminUsername $AdminUsername -Password $AdminPassword
        }
        "Linux" {
            $AzureVM | Add-AzureProvisioningConfig -AdminUsername $AdminUsername -Password $AdminPassword
        }
    }
    #>
}
<#
New-ABSAzureVmWindows -VmName ABS-S01
New-ABSAzureVmWindows -VmName ABS-S02
New-ABSAzureVmWindows -VmName ABS-S03
#>
<#
$Vms = "ABS-S02","ABS-S03"
foreach($Vm in $Vms){
    Remove-AzureVM -Name $Vm -DeleteVHD -ServiceName ABSLab
}
#>
