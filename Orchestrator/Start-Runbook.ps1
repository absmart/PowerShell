<#

This script is designed to be used to initiate a runbook using the Orchestrator web service URL.
The GUID values are currently configured for the runbook "Toggle XA Application".

#>
Import-Module (Join-PATH $env:POWERSHELL_HOME "Libraries\Standard_Variables.ps1")
Import-Module (Join-PATH $env:POWERSHELL_HOME "Orchestrator\Modules\OrchestratorServiceModule.psm1")

# XA Server to use to enable the application
$XAServer = "XaServer"

# Email addresses to be sent email notification of the runbook action
$EmailNotification = '"address1@fqdn.tld","address2@fqdn.tld"'

# Define Web Service URL
$ServiceURL = $orchestrator_environment.WebServiceURL

# Runbook GUID for Enable CMS in Citrix runbook
$rbGUID = "75e86861-e68c-42e3-bfb5-93089127a122"

# XA Server input variable GUID
$rbParam1guid = "d7093abe-119a-40a1-a70c-5e0fb63b0ead"

# Email Recipients input variable GUID
$rbParam2guid = "8b171505-9fa8-4cb1-a611-e9c7628a0820"

[hashtable] $rbParameters = @{

    # Create table to correlate GUIDs with their respective variables
    # Enter values for parameters

    $rbParam1guid = $XAServer;
    $rbParam2guid = $EmailNotification;
    }

# Define the runbook to start

$Runbook = Get-OrchestratorRunbook -ServiceURL $ServiceURL -RunbookId $rbGUID

# Start the runbook with the table of parameters

Start-OrchestratorRunbook -Runbook $Runbook -Parameters $rbParameters