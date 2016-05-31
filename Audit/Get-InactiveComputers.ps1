param(
    $DaysInactive = 90,
    $Path = ".\inactiveComputerReport.csv"
)

Import-Module -Name ActiveDirectory

$Time = (Get-Date).AddDays(-($DaysInactive))
 
# Get all AD computers with lastLogonTimestamp less than our time
Get-ADComputer -Filter {LastLogonTimeStamp -lt $Time} -Properties LastLogonTimeStamp | 
    Select-Object Name,@{Name="Stamp"; Expression={[DateTime]::FromFileTime($_.lastLogonTimestamp)}} | 
    Export-Csv $Path -NoTypeInformation