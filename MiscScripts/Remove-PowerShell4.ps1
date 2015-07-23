param(
    [string] $Computers,
    $SourcePath
    )

Invoke-Command -ComputerName $Computers -Authentication Credssp -Credential $env:USERDOMAIN\$env:USERNAME -ScriptBlock{
    
    $DestinationPath = "C:\MSU"
        
    Copy-Item -Path $SourcePath -Destination $DestinationPath -Force -Recurse

    Start-Process dism.exe -ArgumentList "/online /remove-package /PackagePath:C:\MSU\Windows6.1-KB2809215-x64.cab /LogLevel:3 /NoRestart" -Wait 
    Start-Process dism.exe -ArgumentList "/online /remove-package /PackagePath:C:\MSU\Windows6.1-KB2872035-x64.cab /LogLevel:3 /NoRestart" -Wait 
    Start-Process dism.exe -ArgumentList "/online /remove-package /PackagePath:C:\MSU\Windows6.1-KB2872047-x64.cab /LogLevel:3 /NoRestart" -Wait 
    Start-Process dism.exe -ArgumentList "/online /remove-package /PackagePath:C:\MSU\Windows6.1-KB2819745-x64.cab /LogLevel:3 /NoRestart" -Wait 

    Remove-Item C:\MSU -Recurse -Force
} -ArgumentList $SourcePath