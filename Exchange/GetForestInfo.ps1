# ForestInfo.ps1
# PowerShell program to determine functional level of the Active Directory
# forest and all domains. Also find all FSMO role holders, all sites, and
# and all Global Catalog servers in the forest.
# Author: Richard Mueller
# PowerShell Version 1.0
# December 7, 2012

$Forest = [system.directoryservices.activedirectory.Forest]::GetCurrentForest()
"Forest Name:                " + $Forest.Name
"  Forest Functional Level:  " + $Forest.ForestMode
"  Schema Master:            " + $Forest.SchemaRoleOwner
"  Domain Naming Master:     " + $Forest.NamingRoleOwner

# Determine Configuration naming context from RootDSE object.
$RootDSE = [System.DirectoryServices.DirectoryEntry]([ADSI]"LDAP://RootDSE")
$ConfigNC = $RootDSE.Get("configurationNamingContext")

# Use ADSI Searcher object to determine NetBIOS names of domains.
$Searcher = New-Object System.DirectoryServices.DirectorySearcher
$Searcher.SearchScope = "subtree"
$Searcher.PropertiesToLoad.Add("nETBIOSName") > $Null
# Base of search is Partitions container in the configuration container.
$Searcher.SearchRoot = "LDAP://cn=Partitions,$ConfigNC"

ForEach ($Domain In $Forest.Domains)
{
    # Convert DNS name into distinguished name.
    $DN = "dc=" + $Domain.Name.Replace(".", ",dc=")
    # Find the corresponding partition and retrieve the NetBIOS name.
    $Searcher.Filter = "(nCName=$DN)"
    $NetBIOSName = ($Searcher.FindOne()).Properties.Item("nETBIOSName")
    "`nDomain Name:                " + $Domain.Name
    "  Distinguished Name:       $DN"
    "  NetBIOS Name:             $NetBIOSName"
    "  Domain Functional Level:  " + $Domain.DomainMode
    "  PDC Emulator:             " + $Domain.PdcRoleOwner
    "  RID Master:               " + $Domain.RidRoleOwner
    "  Infrastructure Master:    " + $Domain.InfrastructureRoleOwner
    "  Domain Controllers:"

    ForEach ($DC In $Domain.DomainControllers)
    {
        "                            " + $DC.Name
    }
}

"Sites:"
ForEach ($Site In $Forest.Sites)
{
    "                            " + $Site.Name
}

"Global Catalogs:"
ForEach ($GC In $Forest.GlobalCatalogs)
{
    "                            " + $GC.Name
}