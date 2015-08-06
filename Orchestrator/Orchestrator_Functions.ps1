Import-Module (Join-Path $ENV:POWERSHELL_HOME "Orchestrator\Modules\OrchestratorServiceModule.psm1")
<#
.SYNOPSIS
 This function is used to remotely start Orchestrator Runbooks. The ServiceURL is hardcoded, but can be changed to any of the other runbook servers as well.
 
.EXAMPLE
 
 In this example, the Start-OrchRunbook function is used to start the test runbook called "Enable Notepad on CDC-APP-XENP01 XA Application".

 Start-OrchRunbook -Runbook 53ae4ee0-a75c-4571-a4e6-4446bba49270
 
 #>
function Start-OrchRunbook {
    param(
        [string]$RunbookGUID,
        [String]$Parameters
    )

    $ServiceURL = $orchestrator_environment.WebServiceURL

    $Runbook = Get-OrchestratorRunbook -ServiceURL $ServiceURL -RunbookId $RunbookGUID

    Start-OrchestratorRunbook -Runbook $RunbookGUID -Parameters $Parameters
}

<#
.SYNOPSIS
 This function is used to get the full details of a Orchestrator runbook by the runbook's name.

.EXAMPLE
 In this example, the command is used to find the details of the Enable Notepad runbook.

 Get-OrchRunbook -RunbookName "Enable Notepad"

 #>
function Get-OrchRunbook {
    param(
        [string]$RunbookName
        )

        $ServiceURL = $orchestrator_environment.WebServiceURL

        $Runbook = Get-OrchestratorRunbook -ServiceURL $ServiceURL | Where {$_.Name -match "$RunbookName"}
        Return $Runbook
}

<#
.SYNOPSIS
 This function is used to get the GUID of a Orchestrator runbook by the runbook's name.

.EXAMPLE
 In this example, the command is used to find the GUID of the Enable Notepad runbook.

 Get-OrchRunbookGUID -RunbookName "Enable Notepad"

 #>
function Get-OrchRunbookGUID {
    param(
        [string]$RunbookName
        )
                
        $ServiceURL = $orchestrator_environment.WebServiceURL

        $Runbook = Get-OrchestratorRunbook -ServiceURL $ServiceURL | Where {$_.Name -match "$RunbookName"}
        Return $Runbook.Id
}