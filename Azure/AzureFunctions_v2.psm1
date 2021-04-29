# Import-Module (Join-Path $env:POWERSHELL_HOME "\Azure\Azure_Variables.psm1")
# Enable-AzureRmAlias

function Select-AzureRmVSTSSubscription {
    Get-AzureRmSubscription -SubscriptionName "Visual Studio Enterprise" | Select-AzureRmSubscription | Out-Null
    Get-AzureRmContext
}
New-Alias -Name vstsselect -Value Select-AzureRmVSTSSubscription

function ConnectTo-AzureInstance {
    param(
        $Subscription
    )

    if (!($Subscription)) {
        Get-AzureSubscription
        $Subscription = Read-Host "Enter the Azure subscription:"
        Select-AzureSubscription $Subscription
    }
    else {
        Select-AzureSubscription $Subscription
    }
    Add-AzureAccount -Credential
}

function Get-AzureImageName {
    param(
        [ValidateSet("Windows", "Linux")]$OS,
        $Keyword
    )

    $ImageList = Get-AzureVMImage | Where-Object { $_.OS -eq $OS -and $_.Label -match $Keyword } | Sort-Object CreatedTime
    return $ImageList
}

function Get-AzureAvailableVmSizes {
    param(
        $Location = "Central US"
    )

    $AvailableSizes = (Get-AzureLocation | Where { $_.name -eq $Location }).VirtualMachineRoleSizes

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
    $Port = $Rdp | Where { $_.Name -eq "RemoteDesktop" } | Select Port -ExpandProperty Port

    Start-Process "mstsc" -ArgumentList "/V:$HostDns`:$Port /w:1024 /h:768"
}

function Copy-AzureNsg {
    param(
        $SourceNsgName,
        $SourceResourceGroupName,
        $DestinationNsgName,
        $DestinationResourceGroupName
    )

    $nsg = Get-AzureRmNetworkSecurityGroup -Name $SourceNsgName -ResourceGroupName $SourceResourceGroupName
    $nsgRules = Get-AzureRmNetworkSecurityRuleConfig -NetworkSecurityGroup $nsg
    if(!($newNsg = Get-AzureRmNetworkSecurityGroup -name $DestinationNsgName -ResourceGroupName $DestinationResourceGroupName))
    {
        $newNsg = New-AzureRmNetworkSecurityGroup -Name $DestinationNsgName -ResourceGroupName $DestinationResourceGroupName
    }
    foreach ($nsgRule in $nsgRules) {
        Add-AzureRmNetworkSecurityRuleConfig -NetworkSecurityGroup $newNsg `
        -Name $nsgRule.Name `
        -Protocol $nsgRule.Protocol `
        -SourcePortRange $nsgRule.SourcePortRange `
        -DestinationPortRange $nsgRule.DestinationPortRange `
        -SourceAddressPrefix $nsgRule.SourceAddressPrefix `
        -DestinationAddressPrefix $nsgRule.DestinationAddressPrefix `
        -Priority $nsgRule.Priority `
        -Direction $nsgRule.Direction `
        -Access $nsgRule.Access
    }
    Set-AzureRmNetworkSecurityGroup -NetworkSecurityGroup $newNsg
}

function Get-AzureIpRanges {
    $downloadUri = "https://www.microsoft.com/en-in/download/confirmation.aspx?id=41653"
    $downloadPage = Invoke-WebRequest -Uri $downloadUri
    $xmlFileUri = ($downloadPage.RawContent.Split('"') -like "https://*PublicIps*")[0]
    $response = Invoke-WebRequest -Uri $xmlFileUri

    return $response
}