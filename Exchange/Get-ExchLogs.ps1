param(
    $ConnectorName,
    $ServerName,
    $Start = '08/22/2017 00:00:00',
    $End = '08/23/2017 00:00:00',
    $CsvExportPath = "~\Downloads\MessageLogReport.csv"
)

if($ServerName){
    $logs = Get-MessageTrackingLog -Server $ServerName -Start $Start -End $End -ResultSize Unlimited | Where-Object {$_.ConnectorId -eq $ConnectorName}
}
else{
    $logs = Get-MessageTrackingLog -Start $Start -End $End -ResultSize Unlimited | Where-Object {$_.ConnectorId -eq $ConnectorName}
}


$report = $logs | Select TimeStamp, ClientIp, ClientHostname, ServerIp, ServerHostname, ConnectorId, Source, EventId, InternalMessageId, MessageId, TotalBytes, RecipientCount,
                     MessageSubject, Sender, OriginalClientIp, `
                             @{Name="Recipients";Expression={$_.Recipients} }, `
                             @{Name="RecipientStatus";Expression={$_.RecipientStatus}}

$report | Export-Csv -NoTypeInformation -Path $CsvExportPath