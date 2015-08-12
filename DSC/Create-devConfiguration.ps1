param(
    [ValidateSet("Production","UAT","Development","QA","Test")] $Environment,
    [ValidateSet("CitrixServer","SharePointServer","ApplicationServer","WebServer","dotNetFarm")] $ServerType,
    $Guid = $null, # No longer used, guid must be added to SP List
    [ValidateSet("D:\","E:\","C:\")] $Drive, # no longer used, pulled from SP List
    $ScriptSource,
    $Administrators,
    $PublishToPullServer
)

# Set paths for Logs and Scripts

$LogsPath = ($Drive + "Logs")
$ScriptsPath = ($Drive + "Scripts")
$UtilsPath = ($Drive + "Utils")
$WebPath = ($Drive + "Web")

if($Guid -eq $null)
{
    Import-Module (Join-Path $env:POWERSHELL_HOME "\Libraries\Sharepoint_functions.ps1")
        
    $Url = "http://Sharepoint.domain.com/sites/Department/Support/"
    $List = "DSC Guids"

    $GuidList = Get-SPListViaWebService -url $url -list $List
    $Guid = $GuidList | Where {$_.ServerType -eq $ServerType -and $_.Environment -eq $Environment} | Select Guid -ExpandProperty Guid
    $Drive = $GuidList | Where {$_.ServerType -eq $ServerType -and $_.Environment -eq $Environment} | Select Drive -ExpandProperty Drive
    
    Write-Host "GUID value was not specified, please provide a GUID or localhost value." -ForegroundColor Red
    $Guid = Read-Host "Enter the GUID or localhost for this DSC configuration:"
}

$ConfigData= @{
    AllNodes = @(
        @{
            # The name of the node we are describing (or guid)
            NodeName = $Guid

            # Public certificate file used to encrypt the $Credential variable
            CertificateFile = "\\PullServer\D$\DSC\DSCCredentialCertificate_Public.cer"
                        
            # The thumbprint of the Encryption Certificate used to decrypt the credentials on target node
            Thumbprint = "ABC123" # Thumbprint of DSC Credential Certificate            
        }
    )
}

configuration cConfiguration
{
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullorEmpty()]
        [PsCredential] $Credential 
        )
    
    Import-DscResource -ModuleName cSmbShare
    Import-DscResource -ModuleName cScheduledTask
    Import-DscResource -ModuleName xPSDesiredStateConfiguration
    Import-DscResource -ModuleName xPowerShellExecutionPolicy
    Import-DscResource -ModuleName xCredSSP
        
    Node $AllNodes.NodeName
    {
        LocalConfigurationManager
        {
             CertificateId = $Node.Thumbprint 
        }

        
        # SCOM Registry Keys
        Registry EnvironmentKey
        {
            Ensure = "Present"
            Key = "HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\cInfo"
            ValueName = "Environment"
            ValueData = $Environment
        }
        Registry ServerTypeKey
        {
            Ensure = "Present"
            Key = "HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\cInfo"
            ValueName = "ServerType"
            ValueData = $ServerType
        }
        Registry GuidRegKey
        {
            Ensure = "Present"
            Key = "HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\cInfo"
            ValueName = "DscGuid"
            ValueData = $Guid
        }
        
        xPowerShellExecutionPolicy Unrestricted
        {
            ExecutionPolicy = "Unrestricted"
        }
        
        xCredSSP CredSSP
        {
            Ensure = "Present"
            Role = "Server"
        }

        # Local Administrators Group
        
        Group Administrators
        {
            GroupName = "Administrators"
            Credential = $Credential
            MembersToInclude = $Administrators
        }
        
        # Environment Variables
        
        Environment ScriptsHome
        {
            Ensure = "Present"
            Name = "SCRIPTS_HOME"
            Value = $ScriptsPath
        }
        
        # Scripts Folder Sync
        
        File Scripts
        {
            SourcePath = "$ScriptSource"
            DestinationPath = $ScriptsPath
            Credential = $Credential
            Checksum = "SHA-1"
            Ensure = "Present"
            Force = "True"
            Recurse = "True"
            Type = "Directory"
            MatchSource = "True"
        }
        
        # Utils Folder Sync
        
        File Utils
        {
            SourcePath = "$ScriptSource\Utils"
            DestinationPath = $UtilsPath
            Credential = $Credential
            Checksum = "SHA-1"
            Ensure = "Present"
            Force = "True"
            Recurse = "True"
            Type = "Directory"
            MatchSource = "True"            
        }
        
        # Housekeeping Scheduled Task
        
        cScheduledTask Housekeeping
        {
            TaskName = "Housekeeping"            
            Ensure = "Present"
            Enabled = "True"
            Description = "This is a test."
            TaskSchedule = "Daily"
            TaskStartTime = "21:00:00"
            RunAsUser = $Credential
            TaskToRun = "$ScriptsPath\Housekeeping\log_cleanup.bat"
            DependsOn = "[File]Scripts"
        }

        # Sync-Scripts Scheduled Task Removal

        cScheduledTask SyncScripts
        {
            TaskName = "Sync-Scripts"
            Ensure = "Absent"
        }

        # Logs Folder
        
        File Logs
        {
            Ensure = "Present"
            DestinationPath = $LogsPath
            Type = "Directory"
        }
        
        # SMB Shares
        
        cSmbShare Logs
        {
            Ensure = "Present"
            Name = "Logs"
            Path = $LogsPath
            DependsOn = "[File]Logs"
            ReadAccess = "Everyone"
        }

        # QA / Test / UAT Monitoring
        
        Group PerformanceLogUsers
        {
            GroupName = "Performance Log Users"
            Credential = $Credential
            MembersToInclude = "Domain\MonitoringGroup","Domain\QATeamGroup"
        }
        Group PerformanceMonitorUsers
        {
            GroupName = "Performance Monitor Users"
            Credential = $Credential
            MembersToInclude = "Domain\MonitoringGroup","Domain\QATeamGroup"
        }
        Group EventLogReaders
        {
            GroupName = "Event Log Readers"
            Credential = $Credential
            MembersToInclude = "Domain\MonitoringGroup","Domain\QATeamGroup"
        }        
        
        if($ServerType -eq "WebServer" -or $ServerType -eq "dotnetFarm" -or $ServerType -eq "ABS")
        {
            File Web
            {
                Ensure = "Present"
                DestinationPath = $WebPath
                Type = "Directory"
            }
            cSmbShare Web
            {
                Ensure = "Present"
                Name = "Web"
                Path = $WebPath
                DependsOn = "[File]Web"
                ReadAccess = "Everyone"
            }
            # Required features
            
            WindowsFeature WebServer
            {
                Ensure = "Present"
                Name = "Web-Server"
            }
            
        }
    }
}

if($env:DSC_HOME -ne $null)
{
    $OutPath = ("$env:DSC_HOME\DSCConfigurations\" + $ServerType + "_" + $Environment)
}
else
{
    $OutPath = Read-Host "No environment variable for DSC_HOME found. Enter a location to output the configuration to:"
}

# Create the MOF to add to the Pull server
cConfiguration -ConfigurationData $ConfigData -OutputPath $OutPath -Credential (Get-Credential -Message "Enter service account used for the configuration's `$Credential variable:")
Write-Host "Configuration created and output to $OutPath." -ForegroundColor Yellow

# Creates the checksum to also add to the Pull server
New-DSCCheckSum -ConfigurationPath $OutPath -Force

if($PublishToPullServer)
{
    # Write-Host "Creating the MOF for $Guid. See the following path for MOF configuration and checksum files: $OutPath."
    Copy-Item -Path $OutPath\* -Destination "\\PullServer\c$\Program Files\WindowsPowerShell\DscService\Configuration" -Force -Recurse
    Write-Host "Configuration for $ServerType $Environment copied to the DSC Pull Server." -ForegroundColor Yellow
}