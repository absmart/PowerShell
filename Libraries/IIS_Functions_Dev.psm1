function Get-IISLogs{
    param(
        $Computers,
        [integer]$LastXFiles,
        [string]$SiteName
    )

    #$Computers = $sharepoint_environment.PRODUCTION.WEB
    $Content = $null

    $Content += Invoke-Command -ComputerName $Computers -ArgumentList $Last -ScriptBlock{
        # need to add code here to get the IIS log directory

        Set-Location -Path D:\Logs\W3SVC65 # Location of TaxToolLibrary logs

        $Files = Get-ChildItem -Path D:\Logs\W3SVC65 | Sort LastWriteTime -Descending | Select -First 3

        foreach($File in $Files)
        {
            $Content += Get-Content -Path $File 
        }
        return $Content    
    }
    $Content | Out-File D:\temp\65.txt
}