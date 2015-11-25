[CmdletBinding(SupportsShouldProcess=$true)]
param(
	[Parameter(Mandatory=$true)]
	[string] $ConfigFile
)

$Config = [xml] ( Get-Content $ConfigFile )

function Get-IISFileName
{
	param(
		[string] $LogFormat,
	    [ValidateSet("Daily","Monthly")] $Range = "Daily"
	)

    Switch ($Range){
        "Daily" {
            return $(Get-Date).AddDays(-1).ToString($LogFormat)  + ".log"    
        }
        "Monthly" {
            return $(Get-Date).AddMonths(-1).ToString($LogFormat)  + "*.log"
        }
    }
}

$Servers += @($Config.logparse.servers.server)
$Sites += @($Config.logparse.sites.site)
$Queries += @( $Config.logparse.queries.query | ? { -not [String]::IsNullOrEmpty($_.sql) } )
$LogPath = $Config.logparse.log_path

$LogParse = "D:\Utils\logparser.exe"

$LogName = Get-IISFileName -LogFormat $Config.logparse.fileformat -Range $Config.logparse.logging_range
Write-Verbose ("Log Name - " + $Log_Name)

foreach( $Site in $Sites )
{
	if( $Site.id -eq $null ){
		$id = "W3SVC" + (Get-Website | where { $_.Name -imatch $Site.Name } | Select -First 1 -Expand id).ToString()
	}
	else {
		$id = $Site.id
	}

	$Log =  $LogPath + "\" + $id + "\" + $LogName

	if( Test-Path $Log )
	{
		foreach($Query in $Queries)
		{
            if($Query.sql -imatch '!='){
                $SqlQuery = ($Query.sql.Replace("!=","<>") -f $Log) # Replace the != with <> as Logparser doesn't support != input.
            }
            else{
                $SqlQuery = $Query.sql
            }

            $Sql = $SqlQuery + " " + $Query.option # Adding space for formatting syntax.

            Write-Verbose "SqlQuery ::: $SqlQuery"
            Write-Verbose "Options ::: $Query.option"
            Write-Verbose "Sql variable : $Sql"

			&$LOGPARSE $sql
		}
	}
}