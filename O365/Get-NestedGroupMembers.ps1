
$item = "All APAC Employees"

$group = Get-DistributionGroup -Identity $item

$members = Get-DistributionGroupMember -Identity $item

$nestedGroups =  $members | Where-Object {$_.RecipientType -ne 'UserMailbox' -and $_.RecipientType -ne 'User'}

$nestGroupMembers = foreach($nestedGroup in $nestedGroups.Name){
    Get-DistributionGroupMember -Identity $nestedGroup
}

