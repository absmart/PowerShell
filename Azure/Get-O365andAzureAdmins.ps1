#Requires -Modules AzureAD, Az.Accounts

function Get-AzureADGroupMembersRecursive {
    param(
        [CmdletBinding(SupportsShouldProcess = $true)]
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
        [ValidateScript( { Get-AzureAdGroup -ObjectId $_ })]
        $ObjectId,
        [switch]$Recursive
    )

    Write-Verbose -Message "Enumerating group members in group $ObjectId"

    $UserMembers = Get-AzureADGroupMember -ObjectId $ObjectId | Where-Object { $_.ObjectType -eq "User" }

    if ($PSBoundParameters['Recursive']) {
        $GroupsMembers = Get-AzureADGroupMember -ObjectId $ObjectId | Where-Object { $_.ObjectType -eq "Group" }
        if ($GroupsMembers) {
            Write-Verbose -Message "$ObjectId have $($GroupsMembers.count) group(s) as members, enumerating..."
            $GroupsMembers | ForEach-Object -Process {
                Write-Verbose "Enumerating nested group $($_.Displayname) ($($_.ObjectId))"
                $UserMembers += Get-AzureADGroupMembersRecursive -Recursive -ObjectId $_.ObjectId
            }
        }
    }
    Write-Output ($UserMembers | Sort-Object -Property EmailAddress -Unique)
}

# Get Office 365 directory roles and output to CSV

Connect-AzureAD

$directoryRoles = Get-AzureADDirectoryRole

$directoryRolesResults = @()

foreach ($role in $directoryRoles) {

    $members = Get-AzureADDirectoryRoleMember -ObjectId $role.ObjectId

    foreach ($member in $members) {
        $result = [PSCustomObject][ordered] @{
            DirectoryRole     = $role.DisplayName
            DirectoryObjectId = $role.ObjectId
            UserDisplayName   = $member.DisplayName
            UserObjectId      = $member.ObjectId
            UserPrincipalName = $member.UserPrincipalName
            UserType          = $member.UserType
        }
        $directoryRolesResults += $result
    }
}

$directoryRolesResults | Export-Csv .\Office365DirectoryRoleMembers.csv -NoTypeInformation

# Get all Azure AD directory roles and output members to CSV

Connect-AzAccount

$roleAssignments = Get-AzRoleAssignment

$roleAssignmentResults = @()

foreach ($assignment in $roleAssignments) {

    $result = [PSCustomObject][ordered] @{
        RoleAssignmentId   = $assignment.RoleAssignmentId
        Scope              = $assignment.Scope
        DisplayName        = $assignment.DisplayName
        SignInName         = $assignment.SignInName
        RoleDefinitionName = $assignment.RoleDefinitionName
        RoleDefinitionId   = $assignment.RoleDefinitionId
        ObjectId           = $assignment.ObjectId
        ObjectType         = $assignment.ObjectType
        CanDelegate        = $assignment.CanDelegate
    }
    $roleAssignmentResults += $result
}

# Find groups in the role assignments and expand to users

$groupAssignments = $roleAssignments | Where-Object {$_.ObjectType -eq "Group"}

foreach($assignment in $groupAssignments){

    $groupMembers = Get-AzureADGroupMembersRecursive -Recursive -ObjectId $assignment.ObjectId

    foreach($member in $groupMembers){
        $result = [PSCustomObject][ordered] @{
            RoleAssignmentId    = $assignment.RoleAssignmentId
            Scope               = $assignment.Scope
            DisplayName         = $member.DisplayName
            SignInName          = $member.UserPrincipalName
            RoleDefinitionName  = $assignment.RoleDefinitionName
            RoleDefinitionId    = $assignment.RoleDefinitionId
            ObjectId            = $member.ObjectId
            ObjectType          = $member.UserType
            CanDelegate         = $assignment.CanDelegate
        }
        $roleAssignmentResults += $result
    }
}

$roleAssignmentResults | Export-Csv .\AzureRoleAssignments.csv -NoTypeInformation