<#
I use this to help create properties for new DSC resources and use the New-xDSCResource cmdlet to help generate the prerequisite files and folder structure.
I don't have any goal to turn this into a real script or resource.
#>

Import-Module xDSCResourceDesigner

# Create new DSC Resource and properties

$ResourceName = "cPowerShell"

$AllowRemoteShellAccess = New-xDscResourceProperty -Name AllowRemoteShellAccess -Type String -Attribute Key -ValidateSet "true","false" -Description "Enables access to remote shells. If you set this parameter to False, new remote shell connections will be rejected by the server. The default is True."
$IdleTimeout = New-xDscResourceProperty -Name IdleTimeout -Type String -Attribute Write -Description "Specifies the maximum time, in milliseconds, that the remote shell will remain open when there is no user activity in the remote shell. The remote shell is automatically deleted after the time that is specified. You can specify any values from 0 through 2147483647. A value of 0 indicates an infinite time-out. The default is 900000 (15 minutes)."
$MaxConcurrentUsers = New-xDscResourceProperty -Name MaxConcurrentUsers -Type String -Attribute Write -Description "Specifies the maximum number of users who can concurrently perform remote operations on the same computer through a remote shell. New shell connections will be rejected if they exceed the specified limit. You can specify any value from 1 through 100."
$MaxProcessesPerShell = New-xDscResourceProperty -Name MaxProcessesPerShell -Type String -Attribute Write -Description "Specifies the maximum number of processes that any shell operation is allowed to start. You can specify any number from 0 through 2147483647. A value of 0 allows for an unlimited number of processes. By default, the limit is five processes per shell."
$MaxMemoryPerShellMB = New-xDscResourceProperty -Name MaxMemoryPerShellMB -Type String -Attribute Write -Description "Specifies the maximum total amount of memory that can be allocated by an active remote shell and all its child processes. You can specify any value from 0 through 2147483647. A value of 0 means that the ability of the remote operations to allocate memory is limited only by the available virtual memory. The default value is 0."
$MaxShellsPerUser = New-xDscResourceProperty -Name MaxShellsPerUser -Type String -Attribute Write -Description "Specifies the maximum number of concurrent shells that any user can remotely open on the same system. If this policy setting is enabled, the user will not be able to open new remote shells if the count exceeds the specified limit. If this policy setting is disabled or is not configured, by default, the limit will be set to two remote shells per user. You can specify any number from 0 through 2147483647. A value of 0 allows for an unlimited number of shells."

New-xDSCResource -Name $ResourceName -Property $AllowRemoteShellAccess,$IdleTimeout,$MaxConcurrentUsers,$MaxProcessesPerShell,$MaxMemoryPerShellMB,$MaxShellsPerUser -ModuleName $ModuleName -ClassVersion 1.0 -FriendlyName $ResourceName -Force -Path .\$ResourceName

<#
$TaskName = New-xDscResourceProperty -Name TaskName -Type String -Attribute Key

$Enabled = New-xDscResourceProperty -Name Enabled -Type String -Attribute Write -ValidateSet "True","False"
$Description = New-xDscResourceProperty -Name Description -Type String -Attribute Write
$TaskSchedule = New-xDscResourceProperty -Name TaskSchedule -Type String -Attribute Write -ValidateSet "Time","Daily","Weekly","Monthly","Idle","Boot","Logon"
$TaskStartTime = New-xDscResourceProperty -Name TaskStartTime -Type String -Attribute Write
$RunAsUser = New-xDscResourceProperty -Name RunAsUser -Type String -Attribute  Write
$RunAsUserCredentials = New-xDscResourceProperty -Name RunAsUserCredentials -Type PSCredential[] -Attribute Write
$TaskToRun = New-xDscResourceProperty -Name TaskToRun -Type String -Attribute Write
$Arguments = New-xDscResourceProperty -Name Arguments -Type String -Attribute Write
#>
#New-xDSCResource -Name $ResourceName -Property $TaskName,$Ensure,$Enabled,$Description,$TaskSchedule,$TaskStartTime,$RunAsUser,$RunAsUserCredentials,$TaskToRun,$Arguments -ModuleName $ModuleName -ClassVersion 1.0 -FriendlyName $ModuleName -Force -Path .\$ModuleName