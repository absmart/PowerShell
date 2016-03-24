param(
    $JobName,
    $ComputerName,
    $Username,
    $Password
)

$securePassword = ConvertTo-SecureString -String $Password -AsPlainText -Force
$Credential = New-Object System.Management.Automation.PSCredential ($Username, $securePassword)

    Write-Host "<prtg>"

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
        [system.string] $jobStatus = $status.Status
    }
    else{
        [system.string] $JobStatus = $jobErrorMessage
    }

    # Return results to host for PRTG to capture


    "<result>"
    "<channel>$jobName</channel>"
    "<value>$jobStatus</value>"
 
    "<text></text>" # add text here
    "</result>"

}

    "</prtg>"