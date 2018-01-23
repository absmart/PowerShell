param(
    $mailboxList,
    $removeLicenses,
    $connectExchangeOnline,
    $connectMsol,
    $credential = (Get-Credential)
)

# Used with Exchange Online only.


function Connect-O365EO { param($Credential)
    $connectionUri = "https://outlook.office365.com/powershell-liveid/"
    Connect-MsolService -Credential $credential
    $session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri $ConnectionUri -Credential $credential -Authentication Basic –AllowRedirection
    Import-PSSession $session -DisableNameChecking
}

Connect-O365EO -Credentials $credential

$mailboxes = Import-Csv -Path $mailboxList

foreach($mbx in $mailboxes){

    Set-Mailbox -Identity $mbx.Identity -Type $mbx.Type
}

if($removeLicenses)
{
    Set-MsolUser
}