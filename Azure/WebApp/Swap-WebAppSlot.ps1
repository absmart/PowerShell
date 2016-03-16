param(
  $WebAppName = "AzureWebAppTest",
  $SourceSlot = "Staging",
  $TargetSlot = "production",
  $ResourceGroupName = "WebApp",
  [ValidateSet("Swap","Revert","Apply")] $SwapType
)

switch ($SwapType)
{
  "Apply" # not working
  {
    # Initiate multi-phase swap and apply target slot configuration to source slot
    $ParametersObject = @{targetSlot  = "$TargetSlot"}
    Invoke-AzureRmResourceAction -ResourceGroupName $ResourceGroupName `
                                -ResourceType Microsoft.Web/sites/slots `
                                -ResourceName $SourceSlot `
                                -Action applySlotConfig `
                                -Parameters $ParametersObject `
                                -ApiVersion 2015-07-01
  }
  "Revert" # need to debug this, not working currently
  {
    # Revert the first phase of multi-phase swap and restore source slot configuration
    Invoke-AzureRmResourceAction -ResourceGroupName $ResourceGroupName `
                                -ResourceType Microsoft.Web/sites/slots `
                                -ResourceName $SourceSlot `
                                -Action resetSlotConfig -ApiVersion 2015-07-01
  }
  "Swap"
  {
    # Swap deployment slots
    $ParametersObject = @{targetSlot  = "$TargetSlot"}
    Invoke-AzureRmResourceAction -ResourceGroupName $ResourceGroupName `
                                -ResourceType Microsoft.Web/sites/slots `
                                -ResourceName $SourceSlot `
                                -Action slotsswap `
                                -Parameters $ParametersObject `
                                -ApiVersion 2015-07-01
  }
}
