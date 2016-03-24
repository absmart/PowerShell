param(
    $ComputerName,
    $Username,
    $Password
)

$securePassword = ConvertTo-SecureString -String $Password -AsPlainText -Force
$Credential = New-Object System.Management.Automation.PSCredential ($Username, $securePassword)

$sources = Invoke-Command -ComputerName $ComputerName -Credential $Credential -Authentication Credssp -ScriptBlock {
    Add-PSSnapin Microsoft.SharePoint.PowerShell

    $searchApp = Get-SPServiceApplication | Where-Object {$_.DisplayName -eq "Search Service Application"}

    if($searchApp -eq $null){
        $searchApp =  Get-SPServiceApplication | where { $_.TypeName -eq "Search Service Application" }
    }

    $sources = $searchApp | Get-SPEnterpriseSearchCrawlContentSource
    return $sources
}

    "<prtg>"

foreach($source in $sources){

    $status = Invoke-Command -ComputerName $ComputerName -Credential $Credential -Authentication Credssp -ArgumentList $source -ScriptBlock {
        param(
            $source
        )

        Add-PSSnapin Microsoft.SharePoint.PowerShell
        
        $status = $source | Select CrawlState, CrawlStatus, DeleteCount, ErrorCount, LevelHighErrorCount, SuccessCount, FullCrawlSchedule, IncrementalCrawlSchedule, StartAddress, CrawlStarted

        return $status
    }

    if($status.ContentSource.CrawlStatus -ne $null)
    {
        $crawlState = $status.ContentSource.CrawlStatus
    }
    else { $crawlState = 0 }
    $crawlLevelHighErrorCount = $status.LevelHighErrorCount

    # Return results to host for PRTG to capture


        "<result>"
            "<channel>crawlState</channel>"
            "<value>$crawlState</value>"
        "</result>"
        
        "<result>"
            "<channel>crawlLevelHighErrorCount</channel>"
            "<value>$crawlLevelHighErrorCount</value>"
        "</result>"

}

    "</prtg>"