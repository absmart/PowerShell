param(
    $Path,
    $ExportPath
)

$Folders = Get-ChildItem $Path -Recurse | where-object {($_.PsIsContainer)}

$Acl = $Folders | Get-ACL | Export-Csv -Path $ExportPath -NoTypeInformation