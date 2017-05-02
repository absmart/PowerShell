Import-Module (Join-Path $env:POWERSHELL_HOME "\Azure\Azure_Variables.psm1")

function Select-AzureRmVSTSSubscription {
    Get-AzureRmSubscription -SubscriptionName "Visual Studio Enterprise" | Select-AzureRmSubscription | Out-Null
    Get-AzureRmContext
}
New-Alias -Name vstsselect -Value Select-AzureRmVSTSSubscription

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