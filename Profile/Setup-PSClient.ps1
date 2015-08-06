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
    $DscPath    
)

if($PowerShellPath){
    [Environment]::SetEnvironmentVariable("POWERSHELL_HOME", $PowerShellPath, "Machine")
}
if($DscPath){
    [Environment]::SetEnvironmentVariable("DSC_HOME", $DscPath, "Machine")
}
<#
# Deprecated the SCRIPTS_HOME variable to bring the powershell_home var in line with the folder name in Github.
if($ScriptsPath){ 
    [Environment]::SetEnvironmentVariable("SCRIPTS_HOME", $ScriptsPath, "Machine") 
}
#>

Enable-WSManCredSSP -Role Client -DelegateComputer * -Force