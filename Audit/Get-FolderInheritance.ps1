param(
    $Path
)

$directoryChildItems = (Get-ChildItem -Path $Path -Recurse -Directory)
$results = @()
    
foreach($directory in $directoryChildItems)
{
    #$inheritance = ($directory | Get-Acl).Access | Where-Object {$_.InheritanceFlags -eq $false}
    $acls = (Get-Acl -Path $directory.FullName).Access
    foreach ($acl in $acls)
    {
        if($acl.IsInherited -eq $false)
        {
            $result = [ordered]@{
                FolderPath = $directory.FullName;
                IsInherited = $acl.IsInherited;
                InheritanceFlags = $acl.InheritanceFlags;
                PropagationFlags = $acl.PropagationFlags
            }

        $results += (New-Object -TypeName PSObject -Property $result)
            
        }
    }
}

return $results
