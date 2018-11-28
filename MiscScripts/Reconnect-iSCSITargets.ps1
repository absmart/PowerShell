$chapUsername = "iqn.1991-05.com.microsoft:iscsiInitiatorNameGoesHere.domain.tld"
$PwdTxt = Get-Content "C:\Scripts\VTLiSCSICred.txt"
$chapPassword = $pwdTxt | ConvertTo-SecureString 

$iscsiTargets = Get-iscsiTarget

foreach($target in $iscsiTargets)
{
    Connect-IscsiTarget -IsPersistent $true -ChapUsername $chapUsername -ChapSecret $chapPassword -AuthenticationType MUTUALCHAP -NodeAddress $target.NodeAddress
}