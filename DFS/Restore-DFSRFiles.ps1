#Get Conflicts and deleted folders
$fodder = Get-ChildItem -Path D:\Data\ -Directory

foreach ($fod in $fodder) {

    try { $source = (get-childitem -path $fod.fullname -Attributes d+h 'DFSrPrivate')[0] }
    catch { $source = $null }
    if ($source.FullName) {
        write-host $source.FullName
        $destination = New-Item (join-path 'D:\Temp\Data-DfsPrivate-20191001\PreExistRestored' $fod.name) -ItemType Directory -ErrorAction SilentlyContinue
        $destination = Get-Item (join-path 'D:\Temp\Data-DfsPrivate-20191001\PreExistRestored' $fod.name)
        $destination.fullname
        Copy-Item -Path $source.FullName -Destination $destination.FullName -Force -Recurse
    }
}

$parentregex = [regex]'^[\W\w]+(?=\\)'

$privates = Get-ChildItem -Path D:\Temp\Data-PreExisting-20191001-2 -Recurse -Filter 'DFSrprivate'
foreach ($private in $privates) {
    if (!(test-path (join-path $private.fullname 'ConflictAndDeletedManifest.xml'))) { continue }

    $confdel = [xml](Get-Content (join-path $private.fullname 'ConflictAndDeletedManifest.xml') -Encoding utf8)
    $items = $confdel.ConflictAndDeletedManifest.Resource
    ForEach ($item in $items) {
        $item.path = $item.path -replace '\\\\\.\\E:\\Shares\\', '\\.\E:\Shares_20181114_2\'
        New-Item -Path $($parentregex.Matches($item.path).value) -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
        $source = join-path $private.fullname ('ConflictAndDeleted\' + $item.NewName)
        Copy-Item -Path $source -Destination $item.path -Force

    }
}


############### conflict and deleted
$parentregex = [regex]'^[\W\w]+(?=\\)'

$privates = Get-ChildItem -Path D:\Temp\Data-PreExisting-20191001-2 -Recurse -Filter 'DFSrprivate'
foreach ($private in $privates) {
    if (!(test-path (join-path $private.fullname 'ConflictAndDeletedManifest.xml'))) { continue }

    $confdel = [xml](Get-Content D:\Temp\Data-DfsPrivate-20191001\ConflictAndDeletedManifest.xml -Encoding utf8)
    $items = $confdel.ConflictAndDeletedManifest.Resource
    ForEach ($item in $items) {
        $item.path = $item.path -replace '\\\\\.\\E:\\Shares\\', '\\.\E:\Shares_20181114_2\'
        New-Item -Path $($parentregex.Matches($item.path).value) -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
        $source = join-path $private.fullname ('ConflictAndDeleted\' + $item.NewName)
        Copy-Item -Path $source -Destination $item.path -Force
    }
}

################ preexist
$parentregex = [regex]'^[\W\w]+(?=\\)'

$privates = Get-ChildItem -Path D:\Temp\Data-PreExisting-20191001-2 -Recurse -Filter 'DFSrprivate'
foreach ($private in $privates) {
    if (!(test-path (join-path $private.fullname 'ConflictAndDeletedManifest.xml'))) { continue }

    $confdel = [xml](Get-Content D:\Temp\Data-DfsPrivate-20191001\PreExistingManifest.xml)
    $items = $confdel.PreExistingManifest.Resource
    ForEach ($item in $items) {
        $item.path = $item.path -replace '\\\\\.\\D:\\Data\\', '\\.\D:\Temp\Data-DfsPrivate-20191001\PreExistRestored\'
        New-Item -Path $($parentregex.Matches($item.path).value) -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
        $source = ('D:\Temp\Data-DfsPrivate-20191001\PreExisting\' + $item.NewName)
        Copy-Item -Path $source -Destination $item.path -Force
    }
}



$confdel = [xml](Get-Content D:\Temp\Data-DfsPrivate-20191001\ConflictAndDeletedManifest.xml)
$items = $confdel.ConflictAndDeletedManifest.Resource
ForEach ($item in $items) {
    $item.path = $item.path -replace '\\\\\.\\D:\\Data\\', '\\.\D:\Temp\Data-DfsPrivate-20191001\CAndDStored\'
    New-Item -Path $($parentregex.Matches($item.path).value) -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
    $source = ('D:\Temp\Data-DfsPrivate-20191001\ConflictAndDeleted\' + $item.NewName)
    Copy-Item -Path $source -Destination $item.path -Force
}