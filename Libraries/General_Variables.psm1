$orchestrator_environment = @{
    "WebServiceURL" = "http://orchestrator.domain.tld/Orchestrator2012/Orchestrator.svc/"
    "RunbookServers" = (New-Object -TypeName PSObject -Property @{Servers = @("Orch01","Orch02","Orch03")})
}

$dsc_environment = @{
	"PullServer" = (New-Object -TypeName PSObject -Property @{
		PullServerModulesPath = "\\PullServer\DscService\Modules"
		PullServerConfigurationPath = "\\PullServer\DscService\Configuration"
		})
}

$citrix_environment =@{
    "Datacenter01" = (New-Object -TypeName PSObject -Property @{
        DATA_COLLECTOR = @("CDC-APP-XENP00")
        DATA_STORE = @("CDC-SQL-XENP01")
        DATABASE = @("XENAPP")
        XENAPP_SERVERS = @("XEN01","XEN02","XEN03","XEN04","XEN05","XEN06","XEN07","XEN08")
        });
}