param(
    $SmtpTo,
    $SmtpFrom,
    $SmtpServer
)

Import-Module (Join-Path $env:POWERSHELL_HOME "\Libraries\Sharepoint_Functions.ps1")
Import-Module (Join-Path $env:POWERSHELL_HOME "\Libraries\General_Variables.psm1")

$XAServer = $citrix_environment.Farm01.DATA_COLLECTOR
$SharePointUrl = $deployment_tracking.IssueTracker.Url
$SharePointList = $deployment_tracking.IssueTracker.List

$Enabled = Invoke-Command -ComputerName $XAServer -ScriptBlock{ Add-PSSnapin Citrix.XenApp.Commands; Get-XAServer | Where {$_.LogonsEnabled -eq $false } }

if($Enabled)
{
    foreach($ServerName in $Enabled.ServerName)
    {
        Invoke-Command -ComputerName $ServerName -ScriptBlock{ change logon /enable } -ErrorAction SilentlyContinue

        Write-Verbose "$ServerName was found to have remote logins disabled. 'change logon /enable' performed to resolve."

        $Table = @{
            Title = "$ServerName : Remote Logins Disabled"
            User = $env:USERNAME
            Description = "$ServerName : Remote logins found disabled. 'change logon /enable' command was performed on $ServerName to resolve."
        }

        WriteTo-SPListViaWebService -url $SharePointUrl -list $SharePointList -Item $Table

        Start-Sleep -Seconds 3
        $FarmLoad = Invoke-Command -ComputerName $ServerName -ScriptBlock {qfarm /load}

        $EmailParams = @{
            To = $SmtpTo
            From = $SmtpFrom
            SmtpServer = $SmtpServer
            Subject = "$ServerName Remote Logins Disabled"
            Body = "The Check-XenAppServerRemoteLogins process has detected that $ServerName has remote logins disabled.
            'change logon /enable' has been performed on $ServerName to resolve the issue. Please verify the server is available to remote clients.
            
            $FarmLoad
            "
            Priority = "High"
        }
        Send-MailMessage @EmailParams
    }
}
else
{
    Write-Verbose "All servers have remote logins enabled. No action taken."
}