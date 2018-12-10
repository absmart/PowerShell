# Guidance for this was found here: http://social.technet.microsoft.com/wiki/contents/articles/4869.ad-fs-2-0-how-to-migrate-claim-rules-between-trusts.aspx
#
#  If you want the files saved somewhere other than C:Temp, you need to change the "$RulePath" lines below.
 
Import-Module ADFS
 
# Export the Acceptance Transform Rules for each Claim Provider Trust (except the AD one)
$claimTrusts = Get-AdfsClaimsProviderTrust | ?{$_.Name -ne "Active Directory"}
foreach ($CT in $claimTrusts) {
    $RulePath = "C:Temp\rules\" + $CT.Name.Replace(" ","") + "-AcceptanceRules.txt"
        (Get-AdfsClaimsProviderTrust -Name $CT.Name).AcceptanceTransformRules | Out-File $RulePath
    $RulePath = $null
    }
 
# Export all three types of rules for each Relying-Party Trust
$RPTrusts = Get-AdfsRelyingPartyTrust
foreach ($RP in $RPTrusts) {
    $RulePath = ".\" + $RP.Name.Replace(" ","") + "-IssuanceTransformRules.txt"
    (Get-AdfsRelyingPartyTrust -Name $RP.Name).IssuanceTransformRules | Out-File $RulePath

    $RulePath = ".\" + $RP.Name.Replace(" ","") + "-IssuanceAuthRules.txt"
    (Get-AdfsRelyingPartyTrust -Name $RP.Name).IssuanceAuthorizationRules | Out-File $RulePath

    $RulePath = ".\" + $RP.Name.Replace(" ","") + "-DelegationAuthRules.txt"
    (Get-AdfsRelyingPartyTrust -Name $RP.Name).DelegationAuthorizationRules | Out-File $RulePath
}

# $adfsRelyingPartyTrusts = Get-AdfsRelyingPartyTrust