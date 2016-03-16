$azure =@{
    "images" = (New-Object -TypeName PSObject -Property @{
        ubuntu = @("b39f27a8b8c64d52b05eac6a62ebad85__Ubuntu-15_10-amd64-server-20160204-en-us-30GB")
        windows2012r2 = @("a699494373c04fc0bc8f2bb1389d6106__Windows-Server-2012-R2-20160126-en.us-127GB.vhd")
    })
    #"sizes" = (Get-AzureLocation | Where-Object { $_.name -eq "Central US"}).VirtualMachineRoleSizes
}