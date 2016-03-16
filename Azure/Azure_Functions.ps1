Import-Module (Join-Path $env:POWERSHELL_HOME "\Azure\Azure_Variables.psm1")

function Load-AzureRM{        
    try{Get-AzureRmSubscription}
    catch{Login-AzureRmAccount}
}
New-Alias -Name arm -Value Load-AzureRM

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

function ConnectTo-MsolService {
    $msolCred = Get-Credential
    Connect-MsolService -Credential $msolCred
}
New-Alias -Name aad -Value ConnectTo-MsolService

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
        $VmSize = "Standard_DS1",
        $Image = $azure.images.windows2012r2,
        $AdminUsername,
        $AdminPassword,
        $Location = "Central US",
        $LabName,
        $VnetName,
        $StorageAccountName,
        $AutomationAccountName
    )

    $AzureVM = New-AzureVMConfig -Name $VmName -InstanceSize $VmSize -ImageName $Image -Verbose
    $AzureVM = New-AzureVMConfig -Name $VmName -InstanceSize $VmSize -ImageName $Image -Verbose
    $AzureVM | Add-AzureProvisioningConfig -Windows -AdminUsername $AdminUsername -Password $AdminPassword -Verbose
    $AzureVM | New-AzureVM -ServiceName $LabName -Location $Location -Verbose -AffinityGroup $LabName
}