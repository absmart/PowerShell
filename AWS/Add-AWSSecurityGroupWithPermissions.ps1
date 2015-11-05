[CmdletBinding(DefaultParameterSetName="GroupName")]
param(
    [Parameter(Mandatory=$true)]
    [System.String]
    $GroupName,

    [ValidateSet("TCP","UDP")]
    $Protocol = "TCP",

    [System.Int32]
    $Port,

    [ValidateScript({$_ -match "\b\d{1,2}.\b\d{1,2}.\b\d{1,2}.\b\d{1,2}/\b\d{1,2}"})]
    $CidrBlock = "0.0.0.0/0",
        
    [switch]
    $Inbound,

    [switch]
    $Outbound,

    $Region = (Get-DefaultAWSRegion)
)

Import-Module (Join-Path $env:POWERSHELL_HOME "\AWS\AWS_Variables.psm1")

function Set-IpObject{
    param(
        [ValidateSet("TCP","UDP")]
        $Protocol = "TCP",
    
        [System.Int32]
        $Port,
    
        [ValidateScript({$_ -match "\b\d{1,2}.\b\d{1,2}.\b\d{1,2}.\b\d{1,2}/\b\d{1,2}"})]
        $CidrBlock = "0.0.0.0/0"
    )

    $ipPermissions = New-Object Amazon.EC2.Model.IpPermission
    $ipPermissions.IpProtocol = $Protocol
    $ipPermissions.ToPort = $Port
    $ipPermissions.FromPort = $Port
    $ipPermissions.IpRanges = $CIDRBlock
    
    return $ipPermissions
}
<#
try{ 
    Get-EC2SecurityGroup -GroupName $GroupName
    $GroupContinue = $true
    Write-Verbose "$GroupName was found and will be used for adding permission."
}
catch{ 
    Write-Error "$GroupName - EC2SecurityGroup does not exist in default VPC, failed to add permission to group."
    $GroupContinue = $false
}#>

$ipPermissions = Set-IpObject -Protocol $Protocol -Port $Port -CidrBlock $CidrBlock

$GroupContinue = $true
if($GroupContinue -eq $true){
    if($Inbound)
    {
        Write-Verbose "Ingress was selected, adding ALLOW permission to $GroupName."        
        Grant-EC2SecurityGroupIngress -GroupName $GroupName -IpPermission $ipPermissions
    }
    if($Outbound)
    {
        Write-Verbose "Egress was selected, adding ALLOW permission to $GroupName."
        Grant-EC2SecurityGroupEgress -GroupName $GroupName -IpPermission $ipPermissions
    }    
}
<#
if($GroupName){
    try{
        Get-EC2SecurityGroup -GroupName $GroupName
        Write-Host "Using existing security group - $GroupName" -ForegroundColor Green
    }
    catch{
        Write-Host "Security group does not exist, creating new group - $GroupName" -ForegroundColor Yellow
    }
}
if($GroupId){
    try{Get-EC2SecurityGroup -GroupId $GroupId}
    catch{
        Write-Host "Security group does not exist" -ForegroundColor Yellow
    }
}

#>
    #Grant-EC2SecurityGroupIngress -GroupId $GroupId -IpPermission $ipPermissions

