<#
.SYNOPSIS
 This function is used to assist with creating applications in a 7.x Citrix farm in a consistent and easier method than the GUI.

.EXAMPLE
 
 .\Create-XAApplication.ps1 -ApplicationName "Notepad" -DesktopGroup "XenApp Servers" -ServerName XaServer -WorkingDirectory C:\windows\system32\ -CommandLineExecutable C:\windows\system32\notepad.exe -Enabled $true -AssignedUsers "Domain\Group"


    AdminFolderName                  :
    AdminFolderUid                   : 0
    ApplicationName                  : Notepad
    ApplicationType                  : HostedOnDesktop
    AssociatedDesktopGroupPriorities : {0}
    AssociatedDesktopGroupUUIDs      : {a66ebd0b-10df-4a8f-a78e-c85cbd9f38b7}
    AssociatedDesktopGroupUids       : {8}
    AssociatedUserFullNames          : {}
    AssociatedUserNames              : {}
    AssociatedUserUPNs               : {}
    BrowserName                      : Notepad
    ClientFolder                     :
    CommandLineArguments             :
    CommandLineExecutable            : C:\windows\system32\notepad.exe
    CpuPriorityLevel                 : Normal
    Description                      :
    Enabled                          : True
    IconFromClient                   : False
    IconUid                          : 1
    MetadataKeys                     : {}
    MetadataMap                      : {}
    Name                             : Notepad
    PublishedName                    : Notepad
    SecureCmdLineArgumentsEnabled    : True
    ShortcutAddedToDesktop           : False
    ShortcutAddedToStartMenu         : False
    StartMenuFolder                  :
    UUID                             : 3ae5a9f0-c751-4aa7-ad4f-70fb65568399
    Uid                              : 10
    UserFilterEnabled                : True
    Visible                          : True
    WaitForPrinterCreation           : False
    WorkingDirectory                 : C:\windows\system32\
#>
param(
    [ParaMeter(Mandatory=$true)]
        $ApplicationName,
        $DesktopGroup,
        $ServerName,
        $WorkingDirectory,
        $CommandLineExecutable,
        [ValidateSet($True,$False)] $Enabled,

    [ParaMeter(Mandatory=$false)] 
        $AssignedUsers,
        $CommandLineArguments,
        $Description,
        $ClientFolder,        
        $UserFilterEnabled = $True
)

Import-Module (Join-Path $env:POWERSHELL_HOME "Libraries\SharePoint_Functions.ps1")

Import-Module (Join-PATH $env:POWERSHELL_HOME "Citrix\Modules\PvsPSSnapin.dll")
Import-Module (Join-PATH $env:POWERSHELL_HOME "Citrix\Modules\Citrix.Common.Commands.Data.dll")
Import-Module (Join-PATH $env:POWERSHELL_HOME "Citrix\Modules\Citrix.Common.Commands.dll")
Import-Module (Join-PATH $env:POWERSHELL_HOME "Citrix\Modules\BrokerSnapin.dll")
Set-Variable -Name script_parameters -Value $PSBoundParameters -Option Constant

$SharePointUrl = $deployment_tracking.DeploymentTracker.Url
$SharePointList = $deployment_tracking.DeploymentTracker.List
$DirectorWebServiceURL = $citrix_environment.Farm02.WebServiceURL

# Functions

function Get-ScriptParameters
{
    $params = @()
    foreach( $key in $script_parameters.Keys ) {
        $params += ("{0} : {1}" -f $key, $script_parameters[$key] )
    }
    return ([string]::Join(";", $params))
}

function Get-SPUserViaWS
{
    param ( [string] $url, [string] $name )
	$service = New-WebServiceProxy ($url + "_vti_bin/UserGroup.asmx?WSDL") -Namespace User -UseDefaultCredential
	$user = $service.GetUserInfo("i:0#.w|$name") 
    return $user.user.id + ";#" + $user.user.Name
}

# End Functions

# Pre-defined variables

$ApplicationType = "HostedOnDesktop"
$BrowserName = $ApplicationName
    
# Create application with supplied parameters

New-BrokerApplication -AdminAddress $DirectorWebServiceURL -Name $ApplicationName -BrowserName $BrowserName -PublishedName $ApplicationName -DesktopGroup $DesktopGroup -CommandLineExecutable $CommandLineExecutable -ApplicationType $ApplicationType -WorkingDirectory $WorkingDirectory -Enabled $Enabled -UserFilterEnabled $UserFilterEnabled

# Add optional settings to application

if($CommandLineArguments){
    Set-BrokerApplication -Name $ApplicationName -CommandLineArguments $CommandLineArguments
}
if($Description){
    Set-BrokerApplication -Name $ApplicationName -Description $Description
}
if($ClientFolder){
    Set-BrokerApplication -Name $ApplicationName -ClientFolder $ClientFolder
}

# Assign Icon from EXE

$Icon = Get-CtxIcon -ServerName $ServerName -FileName $CommandLineExecutable | Select-Object -First 1
$IconUid = New-BrokerIcon -EncodedIconData $Icon.EncodedIconData
Set-BrokerApplication -Name $ApplicationName -IconUid $IconUid.Uid

# Add User

if($AssignedUsers){
    Get-BrokerUser -Name $AssignedUsers | Add-BrokerUser -Application $ApplicationName
}

# Record Creation of Application

Set-Variable -Name script_name -Value $MyInvocation.MyCommand.Name
$script_params = Get-ScriptParameters

$deploy = New-Object PSObject -Property @{
    Title = ("Citrix 7.x Farm Application Created - $ApplicationName")
    DeploymentType = "Full"
    DeploymentSteps = ("Automated with {2} script from computer {1}. Application created is called '{0}'." -f $ApplicationName, $ENV:COMPUTERNAME, $script_name )
    Notes = ("Script Parameters: $script_params")
}

$environment_property = "Prod_x0020_Deployment" # This value will be different based on your environment.
$deployer_property =  "Prod_x0020_Deployer" # This value will be different based on your environment.

$deploy | Add-Member -MemberType NoteProperty -Name $environment_property -Value $(Get-Date).ToString("yyyy-MM-ddThh:mm:ssZ")
$deploy | Add-Member -MemberType NoteProperty -Name $deployer_property -Value (Get-SPUserViaWS -url $SharePointUrl -name ($ENV:USERDOMAIN + "\" + $ENV:USERNAME))

WriteTo-SPListViaWebService -url $SharePointList -list $deploy_tracker -Item (Convert-ObjectToHash $deploy)