# Exports all mailboxes from Exchange Servers. Edit the servers if you want to only grab specific mailboxes.

$csvFilePath = "C:\temp\mailboxReport.csv"

Import-Module ActiveDirectory # Required for the UsageLocation / Country AD attribute

# This will grab all mailboxes in an org

$Mailboxes = Get-Mailbox -ResultSize Unlimited

# Un-comment this if you want to only grab from certain servers.
<#
$Servers = (Get-ExchangeServer).Name
$Mailboxes = $null

foreach($server in $servers){
    $Mailboxes += Get-Mailbox -Server $server -ResultSize Unlimited
}
#>

foreach($mailbox in $Mailboxes)
{
    $mailboxStats = $mailbox | Get-MailboxStatistics

    if($mailbox.UserPrincipalName -eq $mailbox.PrimarySMTPAddress.ToString()){ $upnMatch = $true}
    else{$upnMatch = $false}

    #$country = Get-ADUser $mailbox.SamAccountName -Properties Country | select Country -ExpandProperty Country
    $country = $null

    $result = New-Object -TypeName PSObject -Property @{
        InScope = ""
        UserPrincipalName = $mailbox.UserPrincipalName
        PrimarySMTPAddress = $mailbox.PrimarySMTPAddress.ToString()
        UpnMatch = $upnMatch
        DisplayName = $mailbox.DisplayName
        MigrationGroup = ""
        Batch = ""
        Status = ""
        MailboxSizeInMB = $mailboxStats.TotalItemSize.Value.ToMB()
        ItemCount = $mailboxStats.ItemCount
        DeletedItemCount = $mailboxStats.DeletedItemCount
        Database = $mailbox.Database.Name
        UsageLocation = $country
        Alias = $mailbox.Alias
        IsShared = $mailbox.IsShared
        LastLogonTime = $mailboxStats.LastLogonTime
        LastLoggedOnUserAccount = $mailboxStats.LastLoggedOnUserAccount        
    }

    $result | Export-Csv -Path $csvFilePath -NoTypeInformation -Append
}