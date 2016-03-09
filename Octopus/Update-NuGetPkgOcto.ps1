Set-Location "D:\Users\ABS\Deployment"
$apikey = "API-LEJYJLZT3SWXEGB5PHONIKQGLE"

$pkgs = Get-ChildItem .\pkg -Recurse
foreach($pkg in $pkgs)
{
    .\NuGet.exe push $pkg.FullName -ApiKey $apikey -Source http://abs-s01/nuget/packages
}

<#
$octosites = @("OctoSite1","OctoSite2")
foreach($site in $octosites){
    $Test = Test-Path D:\Web\$Site
    if($Test -eq $false)
    {
        New-Item -Path D:\Web\OctoSite1 -ItemType Directory
    }
}
#>