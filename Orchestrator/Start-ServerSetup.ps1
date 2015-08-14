
<#
.SYNOPSIS 
 This script was used to start a System Center Orchestrator runbook and also perform some first-run tasks to setup a new server.
 
 If the UploadAuditResults variable is set to True, the remote system's details will be logged to the Servers list on the SharePoinUrl team site.

 .EXAMPLE
 
 In this example, the server named TESTSERVER will be configured. It will restart automatically if required for either the .NET and PowerShell installations steps.
 The Server Audit step will NOT upload the the Servers list on the AppOps team site. Because of this being set to False, the Environment and Farm variables will not be used beyond initial invocation of the script.

 .\Start-ServerSetup.ps1 -Computers TESTSERVER -RestartAllowed True -UploadAuditResults False -Environment TEST -Farm MISC -Datacenter CDC -ServerType AppServer

#>
param (	
	[ParaMeter(Mandatory=$true)]
    $Computers,
    [ValidateSet("True","False")][string] $RestartAllowed,
    [ValidateSet("True","False")][string] $UploadAuditResults,
    [ValidateSet("Production","Test","QA","Development")][string] $Environment, #  Only used for recording the server inforamation to SharePoint.
    [ValidateSet("Datacenter","Azure","AWS")][string] $Datacenter, #  Only used for recording the server inforamation to SharePoint.
    [ValidateSet("AppServer","WebServer","SQLServer")][string] $ServerType, #  Only used for recording the server inforamation to SharePoint.
    [ParaMeter(Mandatory=$false)]
	[string] $SharePointFarm, #  Only used for recording the server inforamation to SharePoint.
    $RunAsAccountName,
	$DomainName
)

Import-Module (Join-Path $env:POWERSHELL_HOME "Libraries\General_Functions.psm1")
Import-Module (Join-PATH $env:POWERSHELL_HOME "Orchestrator\Modules\OrchestratorServiceModule.psm1")

function Enable-PSRemoting{
    param (
    	[string[]] $computers
    )

    $cmd="Enable-PSRemoting -force;Enable-WSmanCredSSP -role server -force"
    $cmdBytes = [System.Text.Encoding]::Unicode.GetBytes($cmd)
    $cmdEncoded = [Convert]::ToBase64String($cmdBytes)

    $creds = Get-Credential -Credential "$ENV:UserDomain\$ENV:UserName"

    $computers | % {
    	psexec \\$_ -h -u $creds.UserName -p $creds.GetNetworkCredential().Password cmd /c "echo . | powershell -EncodedCommand $cmdEncoded"
    }
}

function Enable-RemoteExecution{
    
    param (
    	[string[]] $computers
    )

    $cmd="Set-ExecutionPolicy -ExecutionPolicy Unrestricted"
    $cmdBytes = [System.Text.Encoding]::Unicode.GetBytes($cmd)
    $cmdEncoded = [Convert]::ToBase64String($cmdBytes)

    $creds = Get-Credential -Credential "$ENV:UserDomain\$ENV:UserName"

    $computers | % {
    	psexec \\$_ -h -u $creds.UserName -p $creds.GetNetworkCredential().Password cmd /c "echo . | powershell -EncodedCommand $cmdEncoded"
    }
}

foreach($Computer in $Computers){
    
    # Test remote PowerShell

    $RemoteTest = Invoke-Command -ComputerName $Computer -ScriptBlock { 1 }
    
    # If remote PowerShell fails, attempt to enable

    if($RemoteTest -ne "1")
        {
        Enable-PSRemoting -computers $Computer | Out-Null
        Enable-RemoteExecution -computers $Computer | Out-Null
		Invoke-Command -ComputerName $Computer -ScriptBlock{Enable-WSManCredSSP -Role Server -Force}
        }

    Invoke-Command -ComputerName $Computer -ArgumentList $DomainName -ScriptBlock {
		param(
			$DomainName
		)
        
        function Get-LocalAdmins
        {
	        $adsi  = [ADSI]("WinNT://" + "localhost" + ",computer") 
	        $Group = $adsi.psbase.children.find("Administrators") 
        	$members = $Group.psbase.invoke("Members") | %{$_.GetType().InvokeMember("Name", 'GetProperty', $null, $_, $null)} 
	
	        return $members
        }

        function Add-LocalAdmin{
            param( 
                [string] $Computer, 
                [string] $User 
            )
            $domain_controller = $DomainName
            $localGroup = [ADSI]"WinNT://localhost/Administrators,group"
            $localGroup.Add("WinNT://$domain_controller/$User,group")
        }
    
        # Add SCOM to local administrators group if missing

        $Admins = Get-LocalAdmins
    
        if($Admins -notcontains $RunAsAccountName)
            {
            Add-LocalAdmin -Computer $Computer -User $RunAsAccountName
            }

        # Set maximum memory per remote PowerShell to 1024 MB
        
        $RemotePSMemoryLimit = Get-Item WSMan:\localhost\Shell\MaxMemoryPerShellMB
        
        if($RemotePSMemoryLimit -lt 1024)
            {
            Set-Item WSMan:\localhost\Shell\MaxMemoryPerShellMB 1024
            }
    }
    
    # Invoke web service for Orchestrator here!

    # GUID Values for Input
    $rbParam1guid = "1d50eea9-ad36-4fb3-ae1f-2db338fa84af" # Computer
    $rbParam2guid = "d898aeb8-180b-47ba-a66d-47c3cfaae3ce" # UploadAuditResults
    $rbParam3guid = "e6ac04a0-346c-4663-a40d-97b4a42647f7" # Environment
    $rbParam4guid = "591d9db5-eb05-4678-8bd4-1b3dfc9ccb69" # RestartAllowed
	$rbParam5guid = "b24383a4-c9ac-4185-9810-39fc8a00d2ea" # SharePointFarm
    $rbParam6guid = "d8588b73-1939-4c8a-be3d-fe031c511907" # ServerType
    $rbParam7guid = "b32741e1-0da8-4d49-a768-0d21c2bcf878" # Datacenter

    # Install-ServerStandards GUID

    $rbGUID = "1144bdbb-daac-469d-988f-4ba119718553" # Install-ServerStandards Runbook GUID
    $ServiceURL = $orchestrator_environment.WebServiceUrl # Orchestrator web service URL

    [hashtable] $rbParameters = @{

        # Create table to correlate GUIDs with their respective variables

        $rbParam1guid = $Computer;
        $rbParam2guid = $UploadAuditResults;
        $rbParam3guid = $Environment;
        $rbParam4guid = $RestartAllowed;
		$rbParam5guid = $SharePointFarm;
        $rbParam6guid = $ServerType;
        $rbParam7guid = $Datacenter
    }

    # Define the runbook to start

    $Runbook = Get-OrchestratorRunbook -ServiceURL $ServiceURL -RunbookId $rbGUID

    # Start the runbook with the table of parameters

    Start-OrchestratorRunbook -Runbook $Runbook -Parameters $rbParameters
}