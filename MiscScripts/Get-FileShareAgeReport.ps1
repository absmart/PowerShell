#requires -RunAsAdministrator

<#
.SYNOPSIS

 This is a script to pull statistics from file shares and find what the most recently modified files are.

#>

$shares = Get-WmiObject -Query "SELECT Name, Path FROM Win32_Share" |
    Select-Object Name, Path |
    Where-Object {$_.Name -ne "IPC$" -and $_.Name -ne "C$" -and $_.Name -ne "E$"}

foreach($share in $shares)
{
    $files = Get-ChildItem -Path $share.Path -Recurse

    $results = @()
    foreach($file in $files){
            $results += (New-Object -TypeName PSObject -Property @{
                Name            = $file.Name
                Path            = $file.Path
                LastWriteTime   = $file.LastWriteTime
                LastAccessTime  = $file.LastAccessTime
                Directory       = $file.Directory
                DirectoryName   = $file.DirectoryName
                Extension       = $file.Extension
                FullName        = $file.FullName
        })
    }
    $results | Export-Csv -Path .\FileShareReport.csv -NoTypeInformation -Append
}