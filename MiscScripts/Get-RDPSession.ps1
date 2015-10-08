param(
    $Username = $env:USERNAME,
    $ComputerName = "localhost"
)

foreach($Computer in $ComputerName){

    $Query = $null
    $Result = $null

    $Query = qwinsta /server:$Computer | foreach { (($_.trim() -replace "\s+",","))} | ConvertFrom-Csv
    $Q = $Query | where {$_.USERNAME -match $Username}

    if($Q -ne $null)
    {
        $Result = @{
            SessionName = $Q.SessionName
            Username = $Q.Username
            ID = $Q.ID
            State = $Q.State
            Type = $Q.Type
            Device = $Q.Device
            ComputerName = $Computer
        }
        return $Result
    }
}
<#
foreach($Computer in $ComputerName){
    qwinsta /server:$Computer | foreach { (($_.trim() -replace "\s+",","))} | ConvertFrom-Csv
    $queryResults += (qwinsta /server:$Computer | foreach { (($_.trim() -replace "\s+",","))} | ConvertFrom-Csv)  
    return $queryResults
}
#>