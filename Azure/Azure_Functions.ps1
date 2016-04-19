Import-Module (Join-Path $env:POWERSHELL_HOME "\Azure\Azure_Variables.psm1")

function Load-AzureRM{
    try{Get-AzureRmSubscription}
    catch{
        Select-AzureRmProfile -Path C:\Keys\visualStudioKey-Azure.json | Out-Null
    }
}
New-Alias -Name arm -Value Load-AzureRM

Load-AzureRm # Forcibly select personal Azure profile on profile start

function Set-AzureLabContext {
    Get-AzureRmSubscription | Where-Object {$_.SubscriptionId -eq "b8d7c6ba-ef18-484c-ad5c-da10d1e329fd"} | Set-AzureRmContext
}
New-Alias -Name azlab -Value Set-AzureLabContext

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
