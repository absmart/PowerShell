
$domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain() 
$ddn = $domain.GetDirectoryEntry().distinguishedName 

write-host -foregroundcolor yellow -backgroundcolor black "Active Directory Information"
"------------------------------------------------------------------------------------------------" 
"Forest name:             " + $domain.Forest.Name  
"Forest version:          " + $domain.Forest.ForestMode 
""
"Domain name:             " + $domain.Name
"Domain mode:             " + $domain.DomainMode  
""
""

write-host -foregroundcolor yellow -backgroundcolor black "Exchange Organization Information"
"------------------------------------------------------------------------------------------------"  
# Exchange organization name
$config = [ADSI]"LDAP://CN=Microsoft Exchange,CN=Services,CN=Configuration,$ddn" 
$orgName = $config.psbase.children | where {$_.objectClass -eq 'msExchOrganizationContainer'} 
"Organization name:       " + $orgName.name 

   
# Gathering current exchange server names, versions, and install dates
$root = New-Object System.DirectoryServices.DirectoryEntry("LDAP://RootDSE")
$configpartition = [adsi]("LDAP://CN=Microsoft Exchange,CN=Services," + $root.configurationNamingContext)
$searcher = New-Object System.DirectoryServices.DirectorySearcher($configpartition)
$searcher.filter = '(objectclass=msExchExchangeServer)'

$colProplist = "name", "serialnumber", "whenCreated"
foreach ($i in $colProplist){
	$searcher.PropertiesToLoad.Add($i) | out-null
}

$ExchServer = $searcher.FindAll()

""
""
write-host -foregroundcolor yellow -backgroundcolor black "Exchange Server information"
"------------------------------------------------------------------------------------------------"  
$ExchServer | ft @{label='Server Name';width=24;e={$_.properties.name}},@{label='Exchange Version';width=45;e={$_.properties.serialnumber}},@{label='Installation Date';e={$_.properties.whencreated}}

