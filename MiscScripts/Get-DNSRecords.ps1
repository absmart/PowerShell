param(
    $recordData
)

$zones = Get-DnsServerZone
foreach($zone in $zones)
{
    Get-DnsServerResourceRecord -ZoneName $zone.ZoneName | Where-Object {$_.RecordData -eq $recordData}
}