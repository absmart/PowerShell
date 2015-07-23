<#
.SYNOPSIS 
 
 This script is used to remotely configure a system for a specific environment and server type based on pre-created LCM schema MOF configurations. This script is
 used with the assumption that a system is already on a domain, has remote PowerShell enabled, CredSSP enabled, and other considerations.

 Use this script to add existing systems to DSC. Do not use this script for a system that has not undergone previous automations to configure an AppOps system.

.EXAMPLE
 
 .\Setup-LocalConfigurationManager.ps1 -Computers ServerName -Environment UAT -ServerType -WebServer -StartDscConfiguration True

 In this example DSC will be configured for a UAT web server.

 The StartDscConfiguration variable is True, which means the Consistency scheduled task will be run immediately after the LCM is configured
 and any configurations specific to that system and environment type will be immediately applied to the system.

#>
param(
    $Computers,
    [ValidateSet("Production","UAT","Development","Test","QA")] $Environment,
    [ValidateSet("CitrixServer","SharePointServer","ApplicationServer","dotNetFarm","WebServer")] $ServerType,
    [ValidateSet($True,$False)] $StartDscConfiguration = $False,
    $RecordDscSetup
    )

$Credentials = Get-Credential -UserName ($env:USERDOMAIN + "\" +$env:USERNAME) -Message "Please enter administrative credentials:"

Invoke-Command -ComputerName $Computers -Authentication Credssp -Credential $Credentials -ArgumentList $Environment,$ServerType,$StartDSCConfiguration,$RecordDscSetup -ScriptBlock{
    param(
        $Environment,
        $ServerType,
        $StartDSCConfiguration
    )
    $TempFolder = Test-Path C:\temp
    if($TempFolder -eq $false)
    {
        New-Item -Path C:\Temp -ItemType Directory
    }

    # Add the location of your meta.mof file here. In this example a hidden administrative share is used to store these.
    $Source = ("\\PullServer\LCMConfigurations$\" + $ServerType + "_" + $Environment + "\" + "localhost.meta.mof")
    $Destination = "C:\temp\localhost.meta.mof"

    Copy-Item -Path $Source -Destination $Destination -Recurse -Container
    
    Set-DscLocalConfigurationManager -ComputerName localhost -Path C:\Temp\ -Verbose
    
    Remove-Item C:\temp\localhost.meta.mof
    
	if($StartDscConfiguration -eq $True)
    {
        try
        {
            # Try the new Update-DscConfiguration command included in WMF 5.0.
            Update-DscConfiguration -Verbose -Wait
        }
        catch
        {
            # Use the old Consistency scheduled task if Update-DscConfiguration does not work
		    schtasks /run /TN "Microsoft\Windows\Desired State Configuration\Consistency"
        }
    }
}