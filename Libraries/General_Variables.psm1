# These variables are all generalized, but used to source environment names without updating all scripts in the repo.


$deployment_tracking = @{
    "DeploymentTracker" = (New-Object -TypeName PSObject -Property @{
        Url = "sharepoint.fqdn.tld/sites/Department"
        List = "Deployment Tracker"
    })
}

$domain_information = @{
    "Domain01" = (New-Object -TypeName PSObject -Property @{
        DomainName = "fqdn.tld"
    })
}

$orchestrator_environment = @{
    "WebServiceURL" = "http://orchestrator.domain.tld/Orchestrator2012/Orchestrator.svc/"
    "RunbookServers" = (New-Object -TypeName PSObject -Property @{Servers = @("Orch01","Orch02","Orch03")})
}

$dsc_environment = @{
	"PullServer" = (New-Object -TypeName PSObject -Property @{
		ModulesPath = "\\PullServer\DscService\Modules"
		ConfigurationPath = "\\PullServer\DscService\Configuration"
        CertificatePath = "\\PullServer\ShareName\"
        CertificateName = "\\PullServer\ShareName\CertName.pfx"
		})
}

$citrix_environment =@{
    "Farm01" = (New-Object -TypeName PSObject -Property @{
        FARM_VERSION = @("6.x")
        DATA_COLLECTOR = @("COLLECTOR01")
        DATA_STORE = @("SQLSERVER01")
        DATABASE = @("XENAPP01")
        XENAPP_SERVERS = @("XEN01","XEN02","XEN03","XEN04","XEN05","XEN06","XEN07","XEN08")
        });
    "Farm02" = (New-Object -TypeName PSObject -Property @{
        FARM_VERSION = @("7.x")
        DATA_COLLECTOR = @("COLLECTOR02")
        DATA_STORE = @("SQLSERVER02")
        DATABASE = @("XENAPP02")
        XENAPP_SERVERS = @("XEN01","XEN02","XEN03","XEN04","XEN05","XEN06","XEN07","XEN08")
        WEBSERVICEURL = [string]@("deliverycontroller.domain.com:80") # WebServiceUrl is used for Citrix 7.x farms only.
        });
    "Logging" = (New-Object -TypeName PSObject -Property @{
        SQLServer = "LoggingServerName"
        Database = "XenAppLogging"
        ProcessTable = "SessionProcesses"
        LoadTable = "ServerLoad"
        SharePointUrl = "sharepoint.fqdn.tld/sites/Department/"
        SharePointEventLogList = "Citrix - Windows Event Logs"
    })
}

$dotnetfarm =@{
    "Production" = (New-Object -TypeName PSObject -Property @{
        Servers = @("Server01","Server02")
    })
    "UAT" = (New-Object -TypeName PSObject -Property @{
        Servers = @("Server01","Server02")
    })
    "Development" = (New-Object -TypeName PSObject -Property @{
        Servers = @("Server01","Server02")
    })
}