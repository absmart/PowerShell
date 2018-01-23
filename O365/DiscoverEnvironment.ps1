param(
    $Path = (Get-Location),
    $HybridTest,
    $Office365,
    $FederatedDomainName
)

#Create variable to hold our info and add the date and time as the first entry
$ExchangeEnv = New-Object PSObject
Add-Member -InputObject $ExchangeEnv -MemberType NoteProperty -Name TimeStamp -Value ([string](Get-Date -format yyyyMMddhhmm))

#Get all Exchange servers
$GetExchangeServer = Get-ExchangeServer 
Add-Member -InputObject $ExchangeEnv -MemberType NoteProperty -Name GetExchangeServer -Value $GetExchangeServer

#Get Exchange server processors
$ExchangeProcessor = @()
ForEach ($Server.Name in $GetExchangeServer) {
	$x = Get-WmiObject win32_processor -ComputerName $server
	$x.Name= $Server
	$ExchangeProcessor += $x
}
Add-Member -InputObject $ExchangeEnv -MemberType NoteProperty -Name ExchangeProcessor -Value $ExchangeProcessor

#Get exchange server disk util
$ExchangeDisk = @()
ForEach ($Server.Name in $GetExchangeServer) {
	$x = Get-WmiObject Win32_LogicalDisk -ComputerName $Server | Where-Object {$_.Size -gt 0} 
	$x.Name = $Server
	$ExchangeDisk += $x
}
Add-Member -InputObject $ExchangeEnv -MemberType NoteProperty -Name ExchangeDisk -Value $ExchangeDisk

#Get exchange server certs
$GetExchangeCertificate = @()
ForEach ($Server.Name in $GetExchangeServer) {
	$x = Get-ExchangeCertificate -Server $Server 
	$x.Name = $Server
	$GetExchangeCertificate += $x
}
Add-Member -InputObject $ExchangeEnv -MemberType NoteProperty -Name GetExchangeCertificate -Value $GetExchangeCertificate

#Test Replication Health
$TestReplicationHealth = @()
ForEach ($Server.Name in $GetExchangeServer)  {
	$x = Test-ReplicationHealth -Server $Server 
	$x.Name = $Server
	$TestReplicationHealth += $x
}
Add-Member -InputObject $ExchangeEnv -MemberType NoteProperty -Name TestReplicationHealth -Value $TestReplicationHealth

#Get misc Exchange info
$GetOrganizationConfig = Get-OrganizationConfig  
$GetAcceptedDomain = Get-AcceptedDomain 
$GetRemoteDomain = Get-RemoteDomain 
$GetDatabaseAvailabilityGroup = Get-DatabaseAvailabilityGroup 
$GetDatabaseAvailabilityGroupStatus = Get-DatabaseAvailabilityGroup -status 
$GetMailboxDatabase = Get-MailboxDatabase 
$GetMailboxDatabaseStatus = Get-MailboxDatabase -status 
Add-Member -InputObject $ExchangeEnv -MemberType NoteProperty -Name GetOrganizationConfig -Value $GetOrganizationConfig
Add-Member -InputObject $ExchangeEnv -MemberType NoteProperty -Name GetAcceptedDomain -Value $GetAcceptedDomain
Add-Member -InputObject $ExchangeEnv -MemberType NoteProperty -Name GetRemoteDomain -Value $GetRemoteDomain
Add-Member -InputObject $ExchangeEnv -MemberType NoteProperty -Name GetDatabaseAvailabilityGroup -Value $GetDatabaseAvailabilityGroup
Add-Member -InputObject $ExchangeEnv -MemberType NoteProperty -Name GetDatabaseAvailabilityGroupStatus -Value $GetDatabaseAvailabilityGroupStatus
Add-Member -InputObject $ExchangeEnv -MemberType NoteProperty -Name GetMailboxDatabase -Value $GetMailboxDatabase
Add-Member -InputObject $ExchangeEnv -MemberType NoteProperty -Name GetMailboxDatabaseStatus -Value $GetMailboxDatabaseStatus

$GetMailboxStatistics = Get-Mailbox -Resultsize Unlimited | Get-MailboxStatistics | Where-Object {$_.ObjectClass -eq "Mailbox"} 
$GetArchiveStatistics = Get-Mailbox -Resultsize Unlimited | Get-MailboxStatistics -archive -erroraction silentlycontinue 
Add-Member -InputObject $ExchangeEnv -MemberType NoteProperty -Name GetMailboxStatistics -Value $GetMailboxStatistics
Add-Member -InputObject $ExchangeEnv -MemberType NoteProperty -Name GetArchiveStatistics -Value $GetArchiveStatistics

$GetEmailAddressPolicy = Get-EmailAddressPolicy 
$GetEmailAddressPolicyIncludeMailboxSessingOnly = Get-EmailAddressPolicy �IncludeMailboxSettingOnlyPolicy 
Add-Member -InputObject $ExchangeEnv -MemberType NoteProperty -Name GetEmailAddressPolicy -Value $GetEmailAddressPolicy
Add-Member -InputObject $ExchangeEnv -MemberType NoteProperty -Name GetEmailAddressPolicyIncludeMailboxSessingOnly -Value $GetEmailAddressPolicyIncludeMailboxSessingOnly

$GetOWAVirtualDirectory = Get-OWAvirtualDirectory 
$GetECPVirtualDirectory = Get-ECPVirtualDirectory 
$GetOABVirtualDirectory = Get-OABVirtualDirectory 
$GetWebServicesVirtualDirectory = Get-WebServicesVirtualDirectory 
$GetActiveSyncVirtualDirectory = Get-ActiveSyncVirtualDirectory
$GetClientAccessServer = Get-ClientAccessServer 
$GetOutlookAnywhere = Get-OutlookAnywhere 
Add-Member -InputObject $ExchangeEnv -MemberType NoteProperty -Name GetOWAVirtualDirectory -Value $GetOWAVirtualDirectory
Add-Member -InputObject $ExchangeEnv -MemberType NoteProperty -Name GetECPVirtualDirectory -Value $GetECPVirtualDirectory
Add-Member -InputObject $ExchangeEnv -MemberType NoteProperty -Name GetOABVirtualDirectoryGetRemoteDomain -Value $GetOABVirtualDirectory
Add-Member -InputObject $ExchangeEnv -MemberType NoteProperty -Name GetWebServicesVirtualDirectory -Value $GetWebServicesVirtualDirectory
Add-Member -InputObject $ExchangeEnv -MemberType NoteProperty -Name GetActiveSyncVirtualDirectory -Value $GetActiveSyncVirtualDirectory
Add-Member -InputObject $ExchangeEnv -MemberType NoteProperty -Name GetClientAccessServer -Value $GetClientAccessServer
Add-Member -InputObject $ExchangeEnv -MemberType NoteProperty -Name GetOutlookAnywhere -Value $GetOutlookAnywhere

$MailboxPermissions = Get-Mailbox -resultsize unlimited  | Get-mailboxpermission | Where-Object {($_.user.tostring() -ne "NT AUTHORITY\SELF") -and ($_.user.tostring() -notlike "S-1-5-21-*") -and ($_.IsInherited -eq $false)} 
$SendAs = Get-Mailbox -ResultSize unlimited | Get-ADPermission | Where-Object {$_.ExtendedRights -like "Send-As" -and $_.User -notlike "NT AUTHORIT\SELF" -and $_.Deny -eq $false} 
$SendOnBehalf = Get-Mailbox -ResultSize unlimited | Select-Object displayname -ExpandProperty GrantSendOnBehalfTo 
Add-Member -InputObject $ExchangeEnv -MemberType NoteProperty -Name MailboxPermissions -Value $MailboxPermissions
Add-Member -InputObject $ExchangeEnv -MemberType NoteProperty -Name SendAs -Value $SendAs
Add-Member -InputObject $ExchangeEnv -MemberType NoteProperty -Name SendOnBehalf -Value $SendOnBehalf

#--------------------------
# Get Calendar Folder delegations
#--------------------------
$users = Get-Mailbox -resultsize unlimited
$Temp = ForEach ($mb in $users) {Get-MailboxFolderPermission -Identity ($mb.alias + ':\calendar') | select-object @{l='Identity';e={$mb.alias}}, foldername, User,@{l='AccessRights';e={$_.AccessRights}}}
$Temp | Export-Csv .\CalendarPermissions.csv

#--------------------------
# Get Contacts Folder delegations
#--------------------------
$users = Get-Mailbox -resultsize unlimited
$Temp = ForEach ($mb in $users) {Get-MailboxFolderPermission -Identity ($mb.alias + ':\contacts') | select-object @{l='Identity';e={$mb.alias}}, foldername, User,@{l='AccessRights';e={$_.AccessRights}}}
$Temp | Export-Csv .\ContactsPermissions.csv

Get-UMAutoAttendant | Format-List > .\UMAutoattendants.txt
Get-UMDialPlan | Format-List > .\UMDialPlans.txt
Get-UMHuntGroup |Format-ListFL > .\UMHuntGroups.txt
Get-UMIPGateway | Format-List > .\UMIPGateways.txt
Get-UMMailbox | Select-Object DisplayName,EmailAddresses,UMAddress,LinkedMasterAccount,PrimarySmtpAddress,SamAccountName,ServerName,UMDialPlan,UMMailboxPolicy,Extensions,PhoneNumber | Export-CSV .\UMMailboxInfo.csv
Get-UMMailboxPolicy | Format-List > .\UMMailboxPolicies.txt
Get-UmServer | Format-List > .\UMServers.txt

Get-ReceiveConnector | Format-List Server,Name,Identity,FQDN,*auth*,Banner,*Max*,*Perm*,Bindings,RemoteIPRanges > .\ALLReceiveConnectorConfig.txt
Get-SendConnector | Format-List > .\ALLSendConnectorConfig.txt

##Public Folder Commands

try{$pfCheck = Get-PublicFolderDatabase}
catch{$pfCheck = $null}

if($pfCheck){
    ##Look for \ in PublicFolderNames
    Get-PublicFolderStatistics -ResultSize Unlimited | Where-Object {$_.Name -like "*\*"} | Format-List Name, Identity

    ##Look for Spaces or , in Alias of Public Folders

    Get-publicfolder "\" -recurse | Where-Object {$_.MailEnabled -eq $True} | Get-MailPublicFolder | Where-Object {$_.alias -like "* *" -or $_.alias -like "*,*"}

    ##Specific Invalid Alias Query - Replace with the character Example: "*#*
    Get-MailPublicFolder | Where-Object {$_.Alias -like "*/*"} | Select-Object alias, identity | Export-csv .\PublicFolderAliaswithBackSlashinName.csv

    ##Previous Public Folder Migration Check
    Get-OrganizationConfig | Format-List PublicFoldersLockedforMigration, PublicFolderMigrationComplete > .\PFMigrationCheck.txt

    ##Orginal Public Folder Source Structure
    Get-PublicFolder -Recurse | Export-CliXML .\Legacy_PFStructure.xml

    ##Legacy Public Folder Statistic
    Get-PublicFolderStatistics -ResultSize Unlimited | Export-CliXML .\Legacy_PFStatistics.xml

    ##Legacy Public Folder Permissions Snapshot
    Get-PublicFolder -Recurse | Get-PublicFolderClientPermission | Select-Object Identity,User -ExpandProperty AccessRights | Export-CliXML .\PFLegacy_PFPerms.xml

    ##PUblicFolder Data
    Get-PublicFolder -Identity \ -Recurse -ResultSize Unlimited | Get-PublicFolderStatistics | Select-Object Name, FolderPath, ItemCount, TotalItemSize, LastUserAccessTime, LastUserModificationTime, MailEnabled | Export-CSV .\PFMigratinfo.CSV
}
##On Premise Hybrid Configuration Discovery

if($HybridTest){
    
    Get-HybridConfiguration | Format-List > $Path\OnPremiseHybridConfiguration.txt
    Get-FederatedOrganizationIdentifier | Format-List > .\OnPremiseFedOrgId.txt
    Get-OrganizationRelationship | Format-List > .\OnPremiseOrgRelationshipConfig.txt
    Get-FederationInformation

    Get-RemoteDomain | Format-List > .\OnpremiseRemotDomainInformation.txt
    Get-FederationTrust | Format-List > .\OnpremiseFedTrust.txt

    try{
        Test-FederationTrust
    }
    catch{
    # **Note: If Error run this script to create exTest account.
        Write-Host "An error occured. Error is " + $_.ErrorMessage. "You may need to create an exTest account. Follow instructions in the following URL: http://exchangeserverpro.com/exchange-server-2013-creating-a-test-mailbox-user-for-troubleshooting-with-test-cmdlets/" -ForegroundColor Red
    }
}

##Office 365 Tenant Discovery Commands

if($Office365)
{
    Get-AcceptedDomain | Format-List > .\Office365FullDeatilsAcceptedDomains.txt
    Get-AcceptedDomain | Format-List DomainName,DomainType,AddressBookEnabled,Default,AuthenticationType > .\AcceptedDomains.txt
    Get-OrganizationConfig | Format-List > .\Office365OrgConfig.txt
    Get-HybridMailflow | Format-List > .\Office365HybridMailflow.txt
    Get-FederatedOrganizationIdentifier | Format-List > .\Office365FederatedOrgID.txt
    Get-FederationInformation -DomainName $FederatedDomainName | Format-List > .\FedInfo.txt
    Get-FederationTrust | Format-List > .\Office365FedTrust.txt
    Get-OrganizationRelationship | Format-List > .\Office365OrgRelationshipConfig.txt
    Get-SharingPolicy | Format-List > .\Office365SSharingPolicy.txt
    Get-MsolAccountSku | Format-List > .\Office365Licenses.txt
    Get-MsolCompanyInformation | Format-List > .\Office365CompanyInformation.txt
    Get-MsolContact > .\Office365ContactInformation.txt
    Get-MsolDomain > .\Office365MSOLDomains.txt
    Get-MsolDomainFederationSettings -DomainName $FederatedDomainName | Format-List > .\Office365MsolCFC.txt
    Get-RemoteDomain | Format-List > .\Office365RemoteDomains.txt
    Get-InboundConnector | Format-List > .\Office365Inboundconnectors.txt
    Get-OutboundConnector | Format-List > .\Office365Outboundconnectors.txt
    Get-OwaMailboxPolicy | Format-List > .\Office365OWAPolicies.txt
}

$ExchangeEnv | Export-Clixml -Path ".\ExchangeEnvironment-$($ExchangeEnv.FileTimeStamp).xml"