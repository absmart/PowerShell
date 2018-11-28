param(
    $ExportPath = "C:\temp\virtualDirectories.csv",
    $sitesPath = "C:\temp\sites.csv",
    $servers = @("A")
)

$output = @()

foreach($server in $servers){

    $results = Invoke-Command -ComputerName $server -ScriptBlock {

        Import-Module WebAdministration

        $results = @()

        $sites = Get-Website

        foreach($site in $sites){
            $virtualDirectories = Get-WebVirtualDirectory -Site $site.Name

            foreach($dir in $virtualDirectories){                
                $vDirObj = New-Object PSObject -Property @{
                    Computer = $ENV:COMPUTERNAME
                    Website = $site.Name
                    Path = $dir.path
                    virtualDirectoryPhysicalPath = $dir.physicalPath
                    virtualDirectoryUserName = $dir.userName
                    logonMethod = $dir.logonMethod
                    ItemXPath = $dir.ItemXPath
                    applicationPool = $site.applicationPool
                    websiteId = $site.id
                    websitePhysicalPath = $site.physicalPath
                    userName = $site.userName
                }
                $results += $vDirObj
            }
        }

        return $results
    }

    $output += $results

}

$output | Export-Csv -Path $ExportPath -NoTypeInformation