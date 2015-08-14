<#
I use this to help create properties for new DSC resources and use the New-xDSCResource cmdlet to help generate the prerequisite files and folder structure.
I don't have any goal to turn this into a real script or resource.
#>

Import-Module xDSCResourceDesigner

# Create new DSC Resource and properties

$ResourceName = "cSSL"
$ModuleName = "cSSL"

$Ensure = New-xDscResourceProperty -Name Ensure -Type String -Attribute Write -ValidateSet "Present","Absent"
$SslCertName = New-xDscResourceProperty -Name Name -Type String -Attribute Key -Description "The name of the certificate as listed in the Cert store."
$PfxPassword = New-xDscResourceProperty -Name Password -Type PSCredential[] -Attribute Write -Description "Password for the Certificate."
$CertificatePath = New-xDscResourceProperty -Name Path -Type String -Attribute Write -Description "The path used to import the certificate."
$CertificateSubject = New-xDscResourceProperty -Name Subject -Type String -Attribute Write -Description "The subject name of the certificate."
$CertificateStore = New-xDscResourceProperty -Name Store -Type String -Attribute Write -Description "The location of the certificate store."

New-xDSCResource -Name $ResourceName -Property $SslCertName,$Ensure,$PfxPassword,$CertificatePath,$CertificateSubject,$CertificateStore -ModuleName $ModuleName -ClassVersion 1.0 -FriendlyName $ResourceName -Force

<#
$TaskName = New-xDscResourceProperty -Name TaskName -Type String -Attribute Key

$Enabled = New-xDscResourceProperty -Name Enabled -Type String -Attribute Write -ValidateSet "True","False"
$Description = New-xDscResourceProperty -Name Description -Type String -Attribute Write
$TaskSchedule = New-xDscResourceProperty -Name TaskSchedule -Type String -Attribute Write -ValidateSet "Time","Daily","Weekly","Monthly","Idle","Boot","Logon"
$TaskStartTime = New-xDscResourceProperty -Name TaskStartTime -Type String -Attribute Write
$RunAsUser = New-xDscResourceProperty -Name RunAsUser -Type String -Attribute  Write
$RunAsUserCredentials = New-xDscResourceProperty -Name RunAsUserCredentials -Type PSCredential[] -Attribute Write
$TaskToRun = New-xDscResourceProperty -Name TaskToRun -Type String -Attribute Write
$Arguments = New-xDscResourceProperty -Name Arguments -Type String -Attribute Write
#>
#New-xDSCResource -Name $ResourceName -Property $TaskName,$Ensure,$Enabled,$Description,$TaskSchedule,$TaskStartTime,$RunAsUser,$RunAsUserCredentials,$TaskToRun,$Arguments -ModuleName $ModuleName -ClassVersion 1.0 -FriendlyName $ModuleName -Force -Path .\$ModuleName