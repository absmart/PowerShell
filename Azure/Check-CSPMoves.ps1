param(
    $csv_resources
)

$moveCSV = "https://raw.githubusercontent.com/tfitzmac/resource-capabilities/master/move-support-resources.csv"

# Pull the latest Move Support CSV from Git and get non-supported values
$unsupportedMoveCSV = (Invoke-WebRequest -Uri $moveCSV).Content | ConvertFrom-Csv
$unsupportedMove = ($unsupportedMoveCSV | Where-Object {$_.'Move Subscription' -eq 0}).Resource

$csv = Import-Csv $csv_resources


$resources = $csv | Where-Object { $unsupportedMove -contains $_.ResourceType }