param(
    $JobName,
    $ComputerName
)

foreach($job in $jobName){

    $status = Invoke-Command -ComputerName $ComputerName -ArgumentList $JobName -ScriptBlock {
        param(
            $JobName
        )
        Add-PSSnapin Microsoft.SharePoint.PowerShell
    
        $return = (Get-SPTimerJob -Identity $JobName).HistoryEntries | Sort-Object -Descending -Property StartTime | Select-Object -First 1 
        return $return
    }

    $status
}