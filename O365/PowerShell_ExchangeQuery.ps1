
Get-ReceiveConnector | Select-Object Name, Identity, Bindings, Comment, DefaultDomain, DistinguishedName, DomainSecureEnabled, Enabled, Fqdn, Guid, Server, @{n='RemoteIPRange';e={$_.RemoteIPRanges}} | Export-CSV -NoTypeInformation -Path .\ReceiveConnectors.csv

Get-Mailbox -ResultSize 1 | Select-Object Identity, UserPrincipalName, DisplayName, DistinguishedName, @{n='EmailAddresses';e={$_.EmailAddresses}}, IsResource, IsLinked, IsMailboxEnabled, IsValid | Export-CSV -NoTypeInformation -Path .\Mailboxes.csv

Get-MailboxDatabase | Select-Object * | Export-CSV -NoTypeInformation -Path .\MailboxDatabases.csv

# This one will take awhile depending on the number of mailboxes. Run this one last
Get-Mailbox -ResultSize Unlimited | Get-MailboxStatistics | Select-Object * | Export-Csv -NoTypeInformation -Path .\MailboxStatistics.csv