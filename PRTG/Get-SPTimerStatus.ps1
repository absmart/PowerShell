param(
    $JobName,
    $ComputerName,
    $Username,
    $Password
)

$securePassword = ConvertTo-SecureString -String $Password -AsPlainText -Force
$Credential = New-Object System.Management.Automation.PSCredential ($Username, $securePassword)

foreach($job in $jobName){

    $status = Invoke-Command -ComputerName $ComputerName -Credential $Credential -ArgumentList $JobName -ScriptBlock {
        param(
            $JobName
        )
        Add-PSSnapin Microsoft.SharePoint.PowerShell
    
        $return = (Get-SPTimerJob -Identity $JobName).HistoryEntries | Sort-Object -Descending -Property StartTime | Select-Object -First 1 
        return $return
    }
    $jobStatus = $status.Status
    $jobErrorMessage = $status.ErrorMessage

    if($jobErrorMessage -eq $null){
        [system.string] $jobStatus = ""
    }
    else{
        [system.string] $jobError = $jobErrorMessage
    }

    # Return results to host for PRTG to capture

    Write-Host "<prtg>"
    "<result>"
    "<channel>$jobName</channel>"
    "<value>$jobStatus</value>"
    "</result>"
    "</prtg>"
}