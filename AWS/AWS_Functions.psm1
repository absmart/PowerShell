# Check if the AWS Tools are imported and if not, import them!

if(!(Get-Module -Name AWSPowerShell)){
    try{Import-Module (Join-Path ${env:ProgramFiles(x86)} "\AWS Tools\PowerShell\AWSPowerShell\AWSPowerShell.psd1")}
    catch{Write-Host "Failed to import the AWSPowerShell module. Verify the AWS PowerShell tools are installed!" -ForegroundColor Red; $_.Exception.Message}
}

#Initialize-AWSDefaults -ProfileName asmartProfile -Region us-west-2
Set-DefaultAWSRegion -Region us-west-2

Import-Module (Join-Path $env:POWERSHELL_HOME "\AWS\AWS_Variables.psm1")

function New-AWSKeyPair{
    param(
        $KeyName,
        $Path
    )
    $KeyPair = New-EC2KeyPair -KeyName $KeyName
    $KeyPair.KeyMaterial | Out-File -Encoding ascii $Path
}

function Get-EC2ImagesByPlatform{
    param(
        $FilterValue = "windows"
    )
    $platform_values = New-Object 'collections.generic.list[string]'
    $platform_values.add($FilterValue)
    $filter_platform = New-Object Amazon.EC2.Model.Filter -Property @{Name = "platform"; Values = $platform_values}
    Get-EC2Image -Owner amazon, self -Filter $filter_platform
}

<#
# Amazon Linux AMI 2015.09.1 x86_64 HVM EBS
[system.string] $Image = $aws_defaults.ami.AmazonLinuxHVM
$GroupId = (Get-EC2SecurityGroup -GroupName "SSH Access from Office").GroupId

$Ec2InstanceParams = @{
    ImageId = ""
    MinCount = ""
    MaxCount = ""
}

New-EC2Instance @params
#New-EC2Instance -ImageId $Image -MinCount 1 -MaxCount 1 -KeyName TestKey01 -SecurityGroup $GroupId -InstanceType t2.micro -
#>