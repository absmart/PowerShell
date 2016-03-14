param(
    $ComputerName
)

$sources = Invoke-Command -ComputerName $ComputerName -ScriptBlock {
    Add-PSSnapin Microsoft.SharePoint.PowerShell

    $searchApp = Get-SPServiceApplication | Where-Object {$_.DisplayName -eq "Search Service Application"}

    if($searchApp -eq $null){
        $searchApp =  Get-SPServiceApplication | where { $_.TypeName -eq "Search Service Application" }
    }

    $sources = $searchApp | Get-SPEnterpriseSearchCrawlContentSource
    return $sources
}

foreach($source in $sources){

    $status = Invoke-Command -ComputerName $ComputerName -ArgumentList $source -ScriptBlock {
        param(
            $source
        )

        Add-PSSnapin Microsoft.SharePoint.PowerShell
        
        $status = $source | Select CrawlState, CrawlStatus, DeleteCount, ErrorCount, LevelHighErrorCount, SuccessCount, FullCrawlSchedule, IncrementalCrawlSchedule, StartAddress, CrawlStarted

        return $status
    }

    $status
}