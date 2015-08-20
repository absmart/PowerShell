$ConfigData= @{
    AllNodes = @(
        @{
            # The name of the node we are describing (or guid)
            NodeName = $Guid # Define this if this will be a Pull configuration, otherwise define $Guid as 'localhost'.
            #NodeName = "localhost"

            # Public certificate file used to encrypt the $Credential variable. In this example it is directly referenced by the admin share on D:\.
            CertificateFile = "\\PullServer\DSC\DSCCredentialCertificate_Public.cer"
        }
    )
    DomainInfo = @(
        @{
            DomainName = "domain.tld"   # Adjust this to the domain used for your IIS site bindings. 
                                        # If you want to use different domains, add additional and break the foreach $Site process in the configuration as needed.
        }
    )

    # This configuration assumes that all of the Websites will be stored in the same physical path. If there are changes or groups, add more configurations to call out later in the configuration.
    WebServerConfiguration = @(
        @{
            WebPath = "E:\Web"
            LogPath = "E:\Logs"
            IisPath = "E:\IIS"
            Websites = @("Website1","Website2","Website3")
            SourcePath = "\\NAS\Share\Sources"            
        }
    )

    PullServer = @(
        @{
            DscShare = "\\PullServer\DSC\"
        }
    )

    Certificates = @(
        @{
            StarDomainTldName = "star.domain.tld"
            StarDomainTldThumbprint = "ABC12345"
            StarDomainTldStore = "localmachine"
            StarDomainTldRoot = "My"
        }
    )
}

configuration wConfiguration
{
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullorEmpty()]
        [PsCredential] $DomainJoinCredential,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullorEmpty()]
        [PsCredential] $FileCopyCredential,
        
        [Parameter(Mandatory=$true)]
        [ValidateNotNullorEmpty()]
        [PsCredential] $PasswordServiceCredential
        )
    
    # Custom Resources
    Import-DscResource -ModuleName cSmbShare
    Import-DscResource -ModuleName cScheduledTask
    Import-DscResource -ModuleName cWebAdministration
    Import-DscResource -ModuleName cWebGlobalConfig
    Import-DscResource -ModuleName cPowerShell

    # MS Resources
    Import-DscResource -ModuleName xPSDesiredStateConfiguration
    Import-DscResource -ModuleName xPowerShellExecutionPolicy
    Import-DscResource -ModuleName xCredSSP
    Import-DscResource -ModuleName xWebAdministration

    Node $AllNodes.NodeName
    {
        xPowerShellExecutionPolicy Unrestricted
        {
            ExecutionPolicy = "Unrestricted"
        }

        cPowerShell PoshSettings
        {
            AllowRemoteShellAccess = "True"
            MaxMemoryPerShellMB = "1024"
        }

        # Folders and SMB Shares
            
        File Web
        {
            Ensure = "Present"
            DestinationPath = $WebServerConfiguration.WebPath
            Type = "Directory"
        }

        cSmbShare Web
        {
            Ensure = "Present"
            Name = "Web"
            Path = $WebServerConfiguration.WebPath
            DependsOn = "[File]Web"
            ReadAccess = "Everyone"
        }
        
        File Logs
        {
            Ensure = "Present"
            DestinationPath = $WebServerConfiguration.LogPath
            Type = "Directory"
        }
        
        cSmbShare Logs
        {
            Ensure = "Present"
            Name = "Logs"
            Path = $WebServerConfiguration.LogPath
            DependsOn = "[File]Logs"
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
            
        cWebGlobalConfig TraceFailedReqLogDirectory { Setting = "TraceFailedReqLogDirectory"; Value = $WebServerConfiguration.LogPath + "\logs\FailedReqLogFiles"; DependsOn = "[WindowsFeature]Web-Server" }
        cWebGlobalConfig LogFileDirectory { Setting = "LogFileDirectory"; Value = $WebServerConfiguration.LogPath; DependsOn = "[WindowsFeature]Web-Server" }
        cWebGlobalConfig BinaryLogFileDirectory { Setting = "BinaryLogFileDirectory"; Value = $WebServerConfiguration.LogPath; DependsOn = "[WindowsFeature]Web-Server" }
        cWebGlobalConfig W3CLogFileDirectory { Setting = "W3CLogFileDirectory"; Value = $WebServerConfiguration.LogPath; DependsOn = "[WindowsFeature]Web-Server" }
        cWebGlobalConfig LogExtFileFlags { Setting = "LogExtFileFlags"; Value = "Date,Time,ClientIP,UserName,ServerIP,Method,UriStem,UriQuery,HttpStatus,BytesSent,BytesRecv,TimeTaken"; DependsOn = "[WindowsFeature]Web-Server" }
        cWebGlobalConfig ConfigHistoryPath { Setting = "ConfigHistoryPath"; Value = $WebServerConfiguration.IisPath + "\history"; DependsOn = "[WindowsFeature]Web-Server" }
        cWebGlobalConfig AspDiskTemplateCacheDirectory { Setting = "AspDiskTemplateCacheDirectory"; Value = $WebServerConfiguration.IisPath + "\temp\ASP Compiled Templates"; DependsOn = "[WindowsFeature]Web-Server" }
        cWebGlobalConfig IisCompressedFilesDirectory { Setting = "IisCompressedFilesDirectory"; Value = $WebServerConfiguration.IisPath + "\temp\IIS Temporary Compressed Files"; DependsOn = "[WindowsFeature]Web-Server" }
        cWebGlobalConfig LocalTimeRollover { Setting = "LocalTimeRollover"; Value = "True"; DependsOn = "[WindowsFeature]Web-Server" }

        # Copy files and cleanup default inetpub directory

        File InetpubCopy
        {
            Ensure = "Present"
            DestinationPath = $WebServerConfiguration.IisPath
            SourcePath = "C:\inetpub"
            MatchSource = "False"
            Type = "Directory"
            DependsOn = "[WindowsFeature]Web-Server"
        }

        File WwwrootRemoval
        {
            Ensure = "Absent"
            DestinationPath = ($WebServerConfiguration.IisPath + "\wwwroot")
            Type = "Directory"
            DependsOn = "[File]InetpubCopy"
        }
                        
        Registry WwwRootPath
        {
            Ensure = "Present"
            Key = "HKEY_LOCAL_MACHINE\Software\Microsoft\inetstp"
            ValueName = "PathWWWRoot"
            ValueData = $WebServerConfiguration.WebPath
            ValueType = "String"
            DependsOn = "[WindowsFeature]Web-Server"
        }
            
        Registry WasParameters
        {
            Ensure = "Present"
            Key = "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\WAS\Parameters"
            ValueName = "ConfigIsolationPath"
            ValueData = ($WebServerConfiguration.IisPath + "\temp\appPools")
            ValueType = "String"
            DependsOn = "[WindowsFeature]Web-Server"
        }

        Registry WebManagement
        {
            Ensure = "Present"
            Key = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WebManagement\Server"
            ValueName = "EnableRemoteManagement"
            ValueData = "1"
            DependsOn = "[WindowsFeature]Web-Server"
        }

        # Certificates for Https bindings

        cCertificate Https
        {
            Name = "star.domain.com"
            Ensure = "Present"
            Password = $starPfxPassword
            Path = ($PullServer.CertificateShare + "\CertificateName.pfx")
            Thumbprint = $Certificates.StarDomainTldThumbprint
        }
        
        # Websites and Application Pools

        foreach($Site in $WebServerConfiguration.Websites)
        {
            File $Site
            {
                SourcePath = ($WebServerConfiguration.SourcePath + "\" + $Site + "\" + $Environment) # Update this source path to whatever is relevant for your environment.                
                DestinationPath = ($WebServerConfiguration.WebPath + "\" + $Site)
                Credential = $FileCopyCredential
                Checksum = "SHA-1"
                Ensure = "Present"
                Force = "True"
                Recurse = "True"
                Type = "Directory"
                MatchSource = "True"
                DependsOn = "[WindowsFeature]Web-Server"
            }

            cWebAppPoolPsSvc $Site
            {
                Name = "AppPool - $Site"
                Ensure = "Present"
                State = "Started"
                AppPoolIdentity = $PasswordServiceCredential
                DependsOn = "[File]$Site"
            }

            cWebSite $Site
            {
                Name = $Site
                Ensure = "Present"
                PhysicalPath = ($WebServerConfiguration.WebPath + "\" + $Site)
                State = "Started"
                ApplicationPool = "AppPool - $Site"
                BindingInfo = cWebBindingInformation
                    {
                        Port = "80";
                        Protocol = "http";
                        HostName = $Site + "." + $DomainInfo.DomainName;
                    }
                DependsOn = "[cWebAppPool]$Site"
            }
        }
        
        foreach($Site in $WebServerConfiguration.SSLSites)
        {
            File $Site
            {
                SourcePath = ($WebServerConfiguration.SourcePath + "\" + $Site + "\" + $Environment) # Update this source path to whatever is relevant for your environment.                
                DestinationPath = ($WebServerConfiguration.WebPath + "\" + $Site)
                Credential = $FileCopyCredential
                Checksum = "SHA-1"
                Ensure = "Present"
                Force = "True"
                Recurse = "True"
                Type = "Directory"
                MatchSource = "True"
                DependsOn = "[WindowsFeature]Web-Server"
            }

            cWebAppPoolPsSvc $Site
            {
                Name = "AppPool - $Site"
                Ensure = "Present"
                State = "Started"
                AppPoolIdentity = $PasswordServiceCredential
                DependsOn = "[File]$Site"
            }

            cWebSite $Site
            {
                Name = $Site
                Ensure = "Present"
                PhysicalPath = ($WebServerConfiguration.WebPath + "\" + $Site)
                State = "Started"
                ApplicationPool = "AppPool - $Site"
                BindingInfo = cWebBindingInformation
                    {
                        Port = "443";
                        Protocol = "https";
                        HostName = $Site + "." + $DomainInfo.DomainName;
                        CertificateThumbprint = $WebsiteConfigurationHTTPS.CertificateThumbprint
                    }
                DependsOn = "[cWebAppPool]$Site","[cCertificate]Https"
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

wConfiguration -ConfigurationData $ConfigData `
    -OutputPath $OutPath `
    -DomainJoinCredential (Get-Credential -Message "Enter the account used to join the node to the domain:") `
    -FileCopyCredential (Get-Credential -Message "Enter the account used to copy files to the node:") `
    -PasswordServiceCredential (Get-Credential -Message "Enter the account used to authenticate with the Password Web Service:")
