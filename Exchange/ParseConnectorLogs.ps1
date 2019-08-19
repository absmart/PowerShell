Add-PSSnapIn *Exchange* -ErrorAction SilentlyContinue
#
# This script will get the SmtpReceive protocol logs and summarize the number of relays and
# when the last relay was seen from each system that is relaying off the CAS servers
#

$OutputFile = ".\ExSMTPConnections.csv"

# remove the 5 from "Version 1[45]" if you only want Exchange 2010 or the 5 if you only want 2013
#$ExCAS = Get-ExchangeServer | Where {($_.AdminDisplayVersion -Match "Version 1[45]") -And ($_.ServerRole -Like "*ClientAccess*")}
# Comment above, uncomment below and modify the site name at the end if you only want to look at logs from servers in a particular site
$ExCAS = Get-ExchangeServer | Where {($_.AdminDisplayVersion -Match "Version 1[45]") -And ($_.ServerRole -Like "*ClientAccess*")}

$LogHeader = @('date-time','connector-id','session-id','sequence-number','local-endpoint','remote-endpoint','event','data','context')

# Build a hash with the keys being as CSV formatted string of "connector-id", "local-endpoint", "remote-endpoint" and
# the hash values being an array of the count of each unique key, and the last "date-time" seen for it
$RptHash = @{}

ForEach ($Server in $ExCAS) {
    Write-Host ("Processing {0}" -f $Server.Name) -ForegroundColor Green
    #
    # Set $CASPath = "\\" + $Server.Name + "\C$\Program Files\Microsoft\Exchange Server\V14\TransportRoles\Logs\ProtocolLog\SmtpReceive" }
    switch -Wildcard ($Server.AdminDisplayVersion) {
	    "Version 14*" { $SmtpRecvPath = (Get-TransportServer $Server.Name).ReceiveProtocolLogPath.PathName }
	    "Version 15*" { $SmtpRecvPath = (Get-FrontendTransportService $Server.Name).ReceiveProtocolLogPath.PathName }
    }
    # replace the drive letter with a UNC path: e.g.: C:\ -> \\XYZHost\C$\
    $CASPath = "\\" + $Server.Name + "\" + ($SmtpRecvPath -replace "^(.):",'$1$')

    # Get the log files in each server's path and sort the log files by mofification
    # time, so the last date of each connection can be recorded
    $ServerLogs = Get-ChildItem -Path $CASPath *.log | Sort-Object -Property LastWriteTime -ErrorAction Continue

    If ($ServerLogs) {

		Write-Host -Foreground Yellow "$CASPath"

		$ServerLogs | ForEach-Object -Process {

			Write-Host ("< {0}" -f $_) -ForegroundColor Yellow
			Get-Content $_.FullName | Select-Object -Skip 5  -First 1000 | ConvertFrom-Csv -Header $LogHeader -Delimiter "," |
			Select-Object connector-id,local-endpoint,@{n='remote-endpoint';e={(($_.'remote-endpoint' -split ":")[0])}},date-time |

			ForEach-Object -Process {
				# Each unique key is the combination of connector-id, local-endpoint, and remote-endpoint
				$RptKey = ("{0},{1},{2}" -f $_.'connector-id', $_.'local-endpoint', $_.'remote-endpoint')
				# The value for this key is an array of the count of times this unique key appears, and the last date-time seen

				$RptVal = @(1, $_.'date-time')

				if ($RptHash.ContainsKey($RptKey)) {
					$RptVal[0] = $RptHash.Item($RptKey)[0] + 1
					$RptHash.Remove($RptKey)
				}
				# Add the most recent date-time with the initial or incremented count for this key
				$RptHash.Add($RptKey,$RptVal)
	    	}
		}
	}
	Else {
		Write-Host -Foreground Yellow "No logs found in $CASPath"
    }
}

# Convert each hash key back from CSV format to a 3 element object (Connector, Local-Endpoint, Remote-Endpoint), then
# select them and the hash value array (Count, Last Date-Time) as a set of 5 elements to output as each new CSV line

$RptHash.Keys | ForEach-Object { $RptEnt = $_; $RptEnt | ConvertFrom-Csv -Header @("Connector", "Local-Endpoint", "Remote-Endpoint") |
Select-Object Connector, Local-EndPoint, Remote-EndPoint,
    @{N="Remote-EndPoint Name";E={($_.'Remote-EndPoint' | Resolve-DnsName -Type PTR -ErrorAction SilentlyContinue).NameHost}},
    @{N="Count";E={$RptHash.Item($RptEnt)[0]}}, @{N="Last Date-Time";E={$RptHash.Item($RptEnt)[1]}} } |
		Export-Csv -NoTypeInformation $OutputFile