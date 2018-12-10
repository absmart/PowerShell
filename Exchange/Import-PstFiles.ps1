Add-PSSnapin microsoft.exchange*
 
#configuration variables
$csv=Import-Csv "c:\scripts\pstmapping.csv" | Where-Object {$_.Type -ne "DNE"}
$batch_name="PST Import - $(Get-date -Format g)"
$error_file="c:\scripts\PSTMapping_errors_$(Get-date -Format Mdyyyy_HHmm).csv"
$process_location="\\exchangeServerName01\TEMP_PSTs\reprocess4"
 
Add-Content $error_file "PSTLabel,DisplayName,Alias,Type"
 
foreach ($mailbox in $csv){
    $pst_path="$($process_location)\$($mailbox.pstlabel)*.pst" 
    get-ChildItem $pst_path | Foreach-object{   
        try{
            New-MailboxImportRequest -Mailbox $mailbox.Alias -name $_.BaseName -FilePath $_.FullName -BatchName $batch_name -LargeItemLimit 300 -BadItemLimit 100 -AcceptLargeDataLoss -ErrorAction Stop
            $pst_file=$_.FullName       
        }
        catch{
            $_.Exception.Message | Out-File "$($process_location)\log\errors.log" -Append
            Add-Content $error_file "$($mailbox.pstlabel),$($mailbox.DisplayName),$($mailbox.Alias),$($mailbox.type)"
            move-item $pst_file z:\error
 
        }
    }
}
 
 
 
 
 
 
 
Add-PSSnapin microsoft.exchange*
$failed_flag=$false
$completed_flag=$false
$smtp_server="mail.exchangeServerName01.com"
 
Get-MailboxImportRequest | Where-Object {$_.Status -eq "Completed"} |  foreach-object {
    Get-date -Format G >> "\\exchangeServerName01\TEMP_PSTs\Processed\processed.log"
    Write-host "Attempting to move $($_.filepath) to processed folder"
    Move-Item $_.filepath "\\exchangeServerName01\TEMP_PSTs\Processed"    
    Get-MailboxImportRequest  -Name $_.Name |fl  >> "\\exchangeServerName01\TEMP_PSTs\Processed\processed.log"
    Get-MailboxImportRequest  -Name $_.Name | Get-MailboxImportRequestStatistics | fl >> "\\exchangeServerName01\TEMP_PSTs\Processed\processed.log"
    Get-MailboxImportRequest  -Name $_.Name | Remove-MailboxImportRequest -Confirm:$false
    $completed_mailboxes+="$($_.Name)`n"
    $completed_flag=$true
 
}
 
Get-MailboxImportRequest | Where-Object {$_.Status -eq "Failed"} |  foreach-object {
    Get-date -Format G >> "\\exchangeServerName01\TEMP_PSTs\Failed\failed.log"
    Write-host "Attempting to move $($_.filepath) to Failed folder"
    Move-Item $_.filepath "\\exchangeServerName01\TEMP_PSTs\Failed\"  
    $failed_request= Get-MailboxImportRequest  -Name $_.Name |fl  
    Get-MailboxImportRequest  -Name $_.Name |fl  >> "\\exchangeServerName01\TEMP_PSTs\Failed\failed.log"
    Get-MailboxImportRequest  -Name $_.Name | Get-MailboxImportRequestStatistics | fl >> "\\exchangeServerName01\TEMP_PSTs\Failed\failed.log"
    Get-MailboxImportRequest  -Name $_.Name | Remove-MailboxImportRequest -Confirm:$false
    $failed_mailboxes+="$($_.Name)`n$($failed_request)`n"
    $failed_flag=$true
 
}
 
if($completed_flag){
    Send-MailMessage -to "emailaddress@company.tld" -from "source@company.tld" -smtpserver $smtp_server -subject "completed imports" -BodyAsHtml "<table><tr><td>The following mailbox import job's have completed</td></tr><tr><td>$($completed_mailboxes)</td></tr></table>"
}
 
if($failed_flag){
    Send-MailMessage -to "emailaddress@company.tld" -from "source@company.tld" -smtpserver $smtp_server -subject "failed imports" -BodyAsHtml "<table><tr><td>The following mailbox import job's have failed</td></tr><tr><td>$($failed_mailboxes)</td></tr></table>"
}
 

