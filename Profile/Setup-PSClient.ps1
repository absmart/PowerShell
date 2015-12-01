param(
    $PowerShellPath,
    $DscPath,
    $EnableCredSSPClient = "*",
    $ExecutionPolicy = "Unrestricted"
)

if($PowerShellPath){
    try{
        [Environment]::SetEnvironmentVariable("POWERSHELL_HOME", $PowerShellPath, "Machine") | Out-Null
    }
    catch{
        $ErrorMsg = $_.Exception.Message        Write-Host $ErrorMsg
    }
}
if($DscPath){
    try{
        [Environment]::SetEnvironmentVariable("DSC_HOME", $DscPath, "Machine")
    }
    catch{
        $ErrorMsg = $_.Exception.Message        Write-Host $ErrorMsg
    }    
}

Try
{
    Write-Verbose "Setting the execution policy of PowerShell."
    Set-ExecutionPolicy -ExecutionPolicy $ExecutionPolicy -Force -ErrorAction Stop
}
Catch
{
    $ErrorMsg = $_.Exception.Message    Write-Verbose $ErrorMsg
}

if($EnableCredSSP){

    $CredSSP = Get-Item WSMan:\localhost\Client\Auth\CredSSP

    if($CredSSP.Value -ne $true){
        Enable-WSManCredSSP -Role Client -DelegateComputer $EnableCredSSP -Force
    }
}

# Install modules
Copy-Item -Path $env:POWERSHELL_HOME\Profile\Modules\* -Destination $env:USERPROFILE\Documents\windowsPowerShell\Modules -Recurse -Container