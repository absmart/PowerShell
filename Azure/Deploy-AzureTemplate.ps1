param(
    [Parameter(ParameterSetName='TemplateFile')]
    $TemplateFile,
    [Parameter(ParameterSetName='TemplateFile')]
    $ParameterFile,

    [Parameter(ParameterSetName='TemplateUri')]
    $TemplateUri,

    $ResourceGroup = (Read-Host "Enter the ResourceGroup: "),
    $Location = (Read-Host "Enter the Location: "),
    $DeploymentName
)

try{Get-AzureRmSubscription}
catch{Login-AzureRmAccount}

try{Get-AzureRMResourceGroup -Name $ResourceGroup -Location $Location}
catch{New-AzureRMResourceGroup -Name $ResourceGroup -Location $Location}

if(!($DeploymentName)){
    $DeploymentName = $ResourceGroup + "-deployment"
}

if($TemplateUri){
    New-AzureRmResourceGroupDeployment -Name $DeploymentName -ResourceGroupName $ResourceGroup -TemplateUri $TemplateUri
}
else{
    New-AzureRmResourceGroupDeployment -Name $DeploymentName `
        -ResourceGroupName $ResourceGroup `
        -TemplateFile $TemplateFile `
        -TemplateParameterFile $ParameterFile
}
