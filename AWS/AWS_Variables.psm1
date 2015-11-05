$aws_defaults =@{
    "environment01" = (New-Object -TypeName PSObject -Property @{
        VPC = @("vpc-364b1c53")
        Region =@("us-west-2")
    })
    "ami" = (New-Object -TypeName PSObject -Property @{
        AmazonLinuxHVM = @("ami-f0091d91")
        Ubuntu = @("ami-5189a661")
        WinSer2012R2Base = @("ami-f8f715cb")
    })
}