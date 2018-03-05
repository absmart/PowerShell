Import-Module C:\Scripts\Posh-SSH\Posh-SSH.psm1
Import-Module C:\Scripts\Posh-SSH\PoshSSH.dll

$Logfile = "C:\Scripts\Upload-HRNavexToFTPSite.log"

$Source = "<Local directory or SMB path goes here>"
$Ftp = "<sftp host goes here>"
$Port = 22

$Username = "SuperSecretUserNameHere"
$PwdTxt = Get-Content "C:\Path\To\CredentialFile.txt"
$SecurePwd = $pwdTxt | ConvertTo-SecureString 
$Credential = New-Object System.Management.Automation.PSCredential -ArgumentList $Username, $SecurePwd

try{
    New-SFTPSession -ComputerName $Ftp -Credential $Credential -Port $Port -AcceptKey -ErrorAction Stop -Verbose
    (Get-Date -Format "yyyy/MM/dd hh:MM:ss") + " : SUCCESS - Connected to $Ftp." | Add-content $Logfile
}
catch{
    $ErrorMessage = $_.Exception.Message
    (Get-Date -Format "yyyy/MM/dd hh:MM:ss") + " : FAILED - Unable to connect to $Ftp." | Add-content $Logfile
    (Get-Date -Format "yyyy/MM/dd hh:MM:ss") + " : ERROR MESSAGE - $ErrorMessage" | Add-content $Logfile
}

$SourceFiles = Get-ChildItem -Path $Source | Where-Object {$_.PSIsContainer -ne $true}

foreach($File in $SourceFiles){
    try{
        Set-SFTPFile -SessionId 0 -LocalFile $File -RemotePath "/" -Overwrite -Verbose -ErrorAction Stop

        (Get-Date -Format "yyyy/MM/dd hh:MM:ss") + " : SUCCESS - Copied $File from " + $File.FullName + " to $Ftp." | Add-content $Logfile
        Remove-Item $File.FullName
    }
    catch{
        (Get-Date -Format "yyyy/MM/dd hh:MM:ss") + " : FAILED - To copy $File from " + $File.FullName + " to $Ftp." | Add-content $Logfile
    }
}

Remove-SFTPSession -SessionId 0