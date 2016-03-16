param(
    $ComputerName,
    $Username,
    $Password
)

$securePassword = ConvertTo-SecureString -String $Password -AsPlainText -Force
$Credential = New-Object System.Management.Automation.PSCredential ($Username, $securePassword)

$sources = Invoke-Command -ComputerName $ComputerName -Credential $Credential -ScriptBlock {
    Add-PSSnapin Microsoft.SharePoint.PowerShell

    $searchApp = Get-SPServiceApplication | Where-Object {$_.DisplayName -eq "Search Service Application"}

    if($searchApp -eq $null){
        $searchApp =  Get-SPServiceApplication | where { $_.TypeName -eq "Search Service Application" }
    }

    $sources = $searchApp | Get-SPEnterpriseSearchCrawlContentSource
    return $sources
}

foreach($source in $sources){

    $status = Invoke-Command -ComputerName $ComputerName -Credential $Credential -ArgumentList $source -ScriptBlock {
        param(
            $source
        )

        Add-PSSnapin Microsoft.SharePoint.PowerShell
        
        $status = $source | Select CrawlState, CrawlStatus, DeleteCount, ErrorCount, LevelHighErrorCount, SuccessCount, FullCrawlSchedule, IncrementalCrawlSchedule, StartAddress, CrawlStarted

        return $status
    }

    $crawlState = $status.ContentSource.CrawlStatus
    $crawlLevelHighErrorCount = $status.LevelHighErrorCount

    # Return results to host for PRTG to capture

    Write-Host "<prtg>"
    "<result>"
    "<channel>crawlState</channel>"
    "<value>$crawlState</value>" # need to update this to integer only
    "<text></text>" # add text here
    "</result>"
    "</prtg>"

    Write-Host "<prtg>"
    "<result>"
    "<channel>crawlLevelHighErrorCount</channel>"
    "<value>$crawlLevelHighErrorCount</value>"
    "<text></text>" # add text here
    "</result>"
    "</prtg>"
}