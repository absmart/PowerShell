<#
    **
    THIS CONFIGURATION IS STILL IN DEVELOPMENT. DO NOT RUN THIS ON PRODUCTION SYSTEMS!
    **
#>
param(
    [ValidateSet("Production","UAT","Development","QA","Test")] $Environment,
    [ValidateSet("CitrixServer","SharePointServer","ApplicationServer","WebServer","dotNetFarm")] $ServerType,
    $OutPath = $null,
    [ValidateSet("D:\","E:\","C:\")] $Drive = "E:\",
    $PublishToPullServer
)

Import-Module (Join-Path $env:POWERSHELL_HOME "\Libraries\Sharepoint_Functions.ps1")
Import-Module (Join-Path $env:POWERSHELL_HOME "\Libraries\General_Variables.psm1")

# Get the guid and drive letter for the given system type

$Url = "http://SharePoint.domain.com/Department/Support/" # Sharepoint Site
$List = "DSC Guids"
$GuidList = Get-SPListViaWebService -url $url -list $List

$Guid = $GuidList | Where {$_.ServerType -eq $ServerType -and $_.Environment -eq $Environment} | Select Guid -ExpandProperty Guid
$Drive = $GuidList | Where {$_.ServerType -eq $ServerType -and $_.Environment -eq $Environment} | Select Drive -ExpandProperty Drive

# Define local paths for system type

$LogsPath = ($Drive + "Logs")
$ScriptsPath = ($Drive + "Scripts")
$UtilsPath = ($Drive + "Utils")

$WebPath = ($Drive + "Web")
$IisPath = ($Drive + "IIS")

if($Guid -eq $null)
{
    Write-Host "GUID value could not be found. Please enter the GUID for this ServerType and Environment." -ForegroundColor Red
    $Guid = Read-Host "Enter the GUID or localhost for this DSC configuration:"
}

$ConfigData= @{
    AllNodes = @(
        @{
            # The name of the node we are describing (or guid)
            NodeName = $Guid

            # Public certificate file used to encrypt the $Credential variable. In this example it is directly referenced by the admin share on D:\.
            CertificateFile = "\\PullServer\D$\DSC\DSCCredentialCertificate_Public.cer"
                        
            # The thumbprint of the Encryption Certificate used to decrypt the credentials on target node
            Thumbprint = "" # Thumbprint of DSC Credential Certificate
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

    # Resources
    Import-DscResource -ModuleName cSmbShare
    Import-DscResource -ModuleName cScheduledTask
    Import-DscResource -ModuleName cWebAdministration
    Import-DscResource -ModuleName cWebGlobalConfig

    # MS Resources
    Import-DscResource -ModuleName xPSDesiredStateConfiguration
    Import-DscResource -ModuleName xPowerShellExecutionPolicy
    Import-DscResource -ModuleName xCredSSP
    Import-DscResource -ModuleName xWebAdministration

    Node $AllNodes.NodeName
    {
        LocalConfigurationManager
        {
             CertificateId = $Node.Thumbprint
        }
        
        if($ServerType -eq "WebServer" -or $ServerType -eq "dotnetFarm" -or $ServerType -eq "ABS")
        {
            # Folders and SMB Shares
            
            File Web
            {
                Ensure = "Present"
                DestinationPath = "$WebPath"
                Type = "Directory"
            }

            cSmbShare Web
            {
                Ensure = "Present"
                Name = "Web"
                Path = "$WebPath"
                DependsOn = "[File]Web"
                ReadAccess = "Everyone"
            }
            
            # Required features and roles
                        
            foreach($Feature in @(
                "Web-Server","Application-Server","AS-WAS-Support","AS-HTTP-Activation",
                "AS-TCP-Activation","AS-Named-Pipes","Web-Http-Redirect","Web-ASP",
                "Web-Log-Libraries","Web-Request-Monitor","Web-Http-Tracing","Web-Custom-Logging",
                "Web-Basic-Auth","Web-Windows-Auth","Web-Digest-Auth","Web-Dyn-Compression",
                "Web-Mgmt-Tools","Web-Scripting-Tools","Web-Mgmt-Service","Web-Mgmt-Compat",
                "Web-WMI","Web-Lgcy-Scripting","RDC")
                )
            {
                WindowsFeature $Feature
                {
                    Ensure = "Present"
                    Name = "$Feature"
                }
            }
            

            # Global IIS Settings
            
            cWebGlobalConfig TraceFailedReqLogDirectory { Setting = "TraceFailedReqLogDirectory"; Value = "$LogsPath\logs\FailedReqLogFiles" }
            cWebGlobalConfig LogFileDirectory { Setting = "LogFileDirectory"; Value = "$LogsPath" }
            cWebGlobalConfig BinaryLogFileDirectory { Setting = "BinaryLogFileDirectory"; Value = "$LogsPath" }
            cWebGlobalConfig W3CLogFileDirectory { Setting = "W3CLogFileDirectory"; Value = "$LogsPath" }
            cWebGlobalConfig LogExtFileFlags { Setting = "LogExtFileFlags"; Value = "Date,Time,ClientIP,UserName,ServerIP,Method,UriStem,UriQuery,HttpStatus,BytesSent,BytesRecv,TimeTaken" }
            cWebGlobalConfig ConfigHistoryPath { Setting = "ConfigHistoryPath"; Value = "$IisPath\history"}
            cWebGlobalConfig AspDiskTemplateCacheDirectory { Setting = "AspDiskTemplateCacheDirectory"; Value = "$IisPath\temp\ASP Compiled Templates"}
            cWebGlobalConfig IisCompressedFilesDirectory { Setting = "IisCompressedFilesDirectory"; Value = "$IisPath\temp\IIS Temporary Compressed Files"}
            cWebGlobalConfig LocalTimeRollover { Setting = "LocalTimeRollover"; Value = "True"}
                        
            File InetpubCopy
            {
                Ensure = "Present"
                DestinationPath = "$IisPath"
                SourcePath = "C:\inetpub"
                MatchSource = "False"
                Type = "Directory"
                DependsOn = "[WindowsFeature]Web-Server"
            }

            File WwwrootRemoval
            {
                Ensure = "Absent";
                DestinationPath = "$IisPath\wwwroot";
                Type = "Directory"
                DependsOn = "[File]InetpubCopy"
            }
                        
            Registry WwwRootPath
            {
                Ensure = "Present"
                Key = "HKEY_LOCAL_MACHINE\Software\Microsoft\inetstp"
                ValueName = "PathWWWRoot"
                ValueData = "$WebPath"
                ValueType = "String"
            }
            
            Registry WasParameters
            {
                Ensure = "Present"
                Key = "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\WAS\Parameters"
                ValueName = "ConfigIsolationPath"
                ValueData = "$IisPath\temp\appPools"
                ValueType = "String"
            }

            Registry WebManagement
            {
                Ensure = "Present"
                Key = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WebManagement\Server"
                ValueName = "EnableRemoteManagement"
                ValueData = "1"
            }
            
            # Scheduled Tasks
            
            cScheduledTask NewRelicStartup
            {
                Ensure = "Present"
                TaskName = "NewRelicStartup"
                Enabled = "True"
                Description = "This task is set to run at system startup to reset specific registry keys for NewRelic and perform an IISRESET command. This will insure the NewRelic client is always reporting properly after a system restart."
                TaskSchedule = "Boot"                
                RunAsUser = $Credential
                TaskToRun = "C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe -command &{$Drive\Scripts\Applications\NewRelic\Reset-NewRelicAPM.ps1}"
                DependsOn = "[File]Scripts"
            }
            #>

            # WebSites

            foreach($Site in @(
                "TestWebSite1","TestWebSite2"
                )
            )

            {                
                File $Site
                {
                    SourcePath = "\\NAS\Code\$Site\Production" # Update this source path to whatever is relevant for your environment.
                    DestinationPath = "$WebPath\$Site"
                    Credential = $Credential
                    Checksum = "SHA-1"
                    Ensure = "Present"
                    Force = "True"
                    Recurse = "True"
                    Type = "Directory"
                    MatchSource = "True"
                    DependsOn = "[WindowsFeature]Web-Server"
                }
                
                cWebAppPool $Site
                {
                    Name = "AppPool - $Site"
                    Ensure = "Present"
                    State = "Started"
                    IdentityCredential = $Credential
                    DependsOn = "[File]$Site"
                }
                
                cWebSite $Site
                {
                    Name = "$Site"
                    Ensure = "Present"
                    PhysicalPath = "$WebPath\$Site"
                    State = "Started"
                    ApplicationPool = "AppPool - $Site"
                    BindingInfo = cWebBindingInformation
                        {
                            Port = "80";
                            Protocol = "http";
                            HostName = "$Site.domain.com"; # Update the domain!
                        }
                    DependsOn = "[cWebAppPool]$Site"
                }
            }            
            
            # Remove Default Site
            
            cWebSite DefaultWebSite
            {
                Name = "Default Web Site"
                Ensure = "Absent"
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