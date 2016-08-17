param(
    $ComputerName
)
foreach($Computer in $ComputerName){
    Get-WmiObject -Class Win32_Share -ComputerName $Computer | Export-CSV .\$Computer-ShareReport.csv -NoTypeInformation -Append
}