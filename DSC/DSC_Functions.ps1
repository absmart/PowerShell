$PullServer = "ServerNameHere"

function Add-DscEnvVariable {
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
        $Path
    )
    $VariableName = "DSC_HOME"
    [Environment]::SetEnvironmentVariable($VariableName, $Path, "Machine")
}

function Copy-DscPublishedResourcesToPullServer {
    $PublishResourcePath = "$env:DSC_HOME\Resources\_PublishedToPullServer"
    Copy-Item $PublishResourcePath\* -Destination "\\$PullServer\C`$\Program Files\WindowsPowerShell\Modules" # Change to appropriate Pull Server name

}

function Recycle-DscEngine {
    $dscProcessID = Get-WmiObject msft_providers | 
    Where-Object {$_.provider -like 'dsccore'} | 
    Select-Object -ExpandProperty HostProcessIdentifier 
    Get-Process -Id $dscProcessID | Stop-Process
}

function Install-DscPrivateCertificate {
    Param (
        $ComputerName,
        $PfxPass = (Read-Host "Pfx Password please!" -AsSecureString)
    )

    $Credentials = Get-Credential -UserName $env:USERDOMAIN\$env:USERNAME -Message "Enter your US ID:"
    
    Invoke-Command -ComputerName $ComputerName -Authentication Credssp -Credential $Credentials -ArgumentList $PfxPass -ScriptBlock{
    
        param(
            $PfxPass
        )

        $CertificatePath = "" # Add a path to the Pfx certificate file here.
        try{

            # Use the new Import-PfxCertificate cmdlet (only works on Windows 8 or Server 2012).
            Import-PfxCertificate -FilePath $CertificatePath -CertStoreLocation Cert:\LocalMachine\My -Password $PfxPass
        } catch
        {
            # If Import-PfxCertificate fails, try the .NET class method
            $StoreName = 'My'
            $StoreLocation= 'LocalMachine'

            $CertificateObject = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
            $CertificateObject.Import($CertificatePath,$PfxPass)

            $CertStore  = New-Object System.Security.Cryptography.X509Certificates.X509Store($StoreName,$StoreLocation)
            $CertStore.Open('MaxAllowed')
            $CertStore.Add($CertificateObject)
        }
    }
}


function Get-DscRegkeySettings {
    param(
        $ComputerName
    )

    Invoke-Command -ComputerName $ComputerName -ScriptBlock {
    
        $ConfigurationId = (Get-DscLocalConfigurationManager).ConfigurationID
        $Environment = Get-ItemProperty HKLM:\SOFTWARE\Wow6432Node\cInfo -Name "Environment"
        $ServerType = Get-ItemProperty HKLM:\SOFTWARE\Wow6432Node\cInfo -Name "ServerType"
        $DscGuid = Get-ItemProperty HKLM:\SOFTWARE\Wow6432Node\cInfo -Name "DscGuid"

        $Table = New-Object psobject

        Add-Member -InputObject $Table -MemberType NoteProperty -Name ConfigurationID -Value $ConfigurationId
        Add-Member -InputObject $Table -MemberType NoteProperty -Name ComputerName -Value $env:COMPUTERNAME
        Add-Member -InputObject $Table -MemberType NoteProperty -Name Environment -Value $Environment.Environment
        Add-Member -InputObject $Table -MemberType NoteProperty -Name ServerType -Value $ServerType.ServerType
        Add-Member -InputObject $Table -MemberType NoteProperty -Name DscGuid -Value $DscGuid.DscGuid

        return $table

    } | select ComputerName, ConfigurationID, Environment, ServerType
}


<#
.SYNOPSIS 
 
 Use this command to remotely initiate the Consistency scheduled task that will immediately run the Test functions in all DSC resources on a system.
 If any tests fail, the Set method will be used to configure the system per it's configuration.

 If the LCM is configured for a Pull server, it will also update the local configuration if there are updates available.

.EXAMPLE
 
 Start-PullConfigConsistency -ComputerName ent-web-f01u01
 
#>
function Start-DscConfigurationUpdate {

	param(
		$Computers
		)

	Invoke-Command -ComputerName $Computers -ScriptBlock{
        try
        {
            Update-DscConfiguration -Verbose -Wait
        }
        catch
        {
		    schtasks /run /TN "Microsoft\Windows\Desired State Configuration\Consistency"
        }
	}
}

# Get current MOF, compare to the one on the Pull server # Not finished!
function Check-DscMofState {
    
    param(
        $ComputerName = "localhost"
    )

    $Script = {
            
    }

    if($ComputerName -ne "localhost"){
        Invoke-Command -ComputerName $ComputerName -ScriptBlock $Script -Credential (Get-Credential) -Authentication Credssp
    }
    else
    {
        $Script
    }
}