param(
        [string] $Computers,
        $SourcePath
    )

Invoke-Command -ComputerName $Computers -Authentication Credssp -Credential $env:USERDOMAIN\$env:USERNAME -ScriptBlock{    
    
    $DestinationPath = "C:\TempNETFramework"

    Copy-Item -Path $SourcePath -Destination $DestinationPath -Force -Recurse
                
    Start-Process -FilePath "$DestinationPath\.NET452_NDP452-KB2901907-x86-x64-AllOS-ENU.exe" -ArgumentList "/q /norestart" -Wait

    Remove-Item C:\TempNETFramework -Recurse -Force
} -ArgumentList $SourcePath