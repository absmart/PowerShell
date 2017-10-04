Get-Mailbox -ResultSize Unlimited -Filter {RecipientTypeDetails -eq "UserMailbox"} | ` 
    Set-Mailbox -AuditEnabled $true -AuditOwner HardDelete,MailboxLogin,SoftDelete