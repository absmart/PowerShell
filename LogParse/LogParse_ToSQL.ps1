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

if($Config.logparse.sites -eq "All"){ 
    Import-Module WebAdministration    
    $Sites = Get-ChildItem -Path IIS:\Sites | Select Name, Id    
}
else{
    $Sites += @($Config.logparse.sites.site)
}

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
	elseif( $Site.id -notmatch "W3SVC") {
        $id = "W3SVC" + $Site.id
	}
    else {
    	$id = $Site.id
    }

	$Log =  $LogPath + "\" + $id + "\" + $LogName
    $Table = $Config

	if( Test-Path $Log )
	{
		foreach($Query in $Queries)
		{
            $Table = $Query.table

            if($Query.sql -imatch '!='){
                # Replace the != with <> as Logparser doesn't support != input.
                $SqlQuery = ($Query.sql.Replace("!=","<>") -f $Table,$Log)
            }
            else{
                $SqlQuery = $Query.sql -f $Table,$Log
            }

            $Sql = $SqlQuery + " " + $Query.option # Adding space for formatting syntax.

            Write-Verbose "SqlQuery ::: $SqlQuery"
            Write-Verbose "Options ::: $Query.option"
            Write-Verbose "Sql variable : $Sql"

			&$LOGPARSE $sql
		}
	}
}