# http://ss64.com/ps/syntax-elevate.html

powershell.exe -noprofile -executionPolicy bypass -command {Set-Item WSMan:\localhost\Shell\AllowRemoteShellAccess -Value $true}

Start-Process powershell.exe -Verb runAs -ArgumentList "-noProfile -command {Set-Item WSMan:\localhost\Shell\AllowRemoteShellAccess -Value $true} -ExecutionPolicy Bypass"