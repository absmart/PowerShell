<#
.SYNOPSIS 
 
 This script is used to perform initial configuration for an AppOps server to download and install the DSC private certificate, LCM and configure the LCM accordingly.
 Select the appropriate Environment and ServerType from the set of options. Updates to the script are required if additional options are required.
 StartDSCConfiguration can be toggled to True or False to immediately enable the DSC configuration by intiating the Consistency scheduled task.

 This script must be run directly on the server in which you want DSC to be configured on. Use Setup-LocalConfigurationManager if the system is already configured.

.EXAMPLE
 
 .\Start-cConfiguration.ps1 -Environment Test -ServerType ApplicationServer -StartDSCConfiguration True

 In this example DSC will be configured for an application server, and it will be assigned to the Test environment group. 
 The StartDSCConfiguration variable is True, which means the Consistency scheduled task will be run immediately after the LCM is configured.

#>
param(
    $PowerShellPath,
    $DscPath,
    $EnableCredSSP
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

<#
# Deprecated the SCRIPTS_HOME variable to bring the powershell_home var in line with the folder name in Github.
if($ScriptsPath){
    [Environment]::SetEnvironmentVariable("SCRIPTS_HOME", $ScriptsPath, "Machine")
}
#>

# Configure execution policy to be less strict, allow unsigned PowerShell scripts and modules to be used.

$ExecutionPolicy = "Unrestricted"
Try
{
    Write-Verbose "Setting the execution policy of PowerShell."
    Set-ExecutionPolicy -ExecutionPolicy $ExecutionPolicy -Force -ErrorAction Stop
}
Catch
{
    $ErrorMsg = $_.Exception.Message    Write-Verbose $ErrorMsg
}

# Check CredSSP values and setup if not configured properly. 
# Probably should add a DSC resource to do this, but on the back-burner right now as it requires PoSH 4.0 or newer.

if($EnableCredSSP){

    $CredSSP = Get-Item WSMan:\localhost\Client\Auth\CredSSP

    if($CredSSP.Value -ne $true){
        Enable-WSManCredSSP -Role Client -DelegateComputer * -Force
    }
}