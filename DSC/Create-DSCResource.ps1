<#
I use this to help create properties for new DSC resources and use the New-xDSCResource cmdlet to help generate the prerequisite files and folder structure.
I don't have any goal to turn this into a real script or resource.
#>

Import-Module xDSCResourceDesigner

# Create new DSC Resource and properties

$ResourceName = "cSSLCertificate2"
$ModuleName = "cSSLCertificate2"

$SslCertName = New-xDscResourceProperty -Name Name -Type String -Attribute Write
$SslCertThumbprint = New-xDscResourceProperty -Name Thumbprint -Type String -Attribute Key
$Ensure = New-xDscResourceProperty -Name Ensure -Type String -Attribute Write -ValidateSet "Present","Absent"
$CertificateSubject = New-xDscResourceProperty -Name Subject -Type String -Attribute Write -Description "The subject name of the certificate."
$CertificateStore = New-xDscResourceProperty -Name Store -Type String -Attribute Write -Description "The location of the certificate store."
$PfxPassphrase = New-xDscResourceProperty -Name PfxPassphrase -Type PSCredential -Attribute Write -Description "The credential object to import the pfx file. This is only required if adding the certificate."

New-xDSCResource -Name $ResourceName -Property $SslCertName,$Ensure,$SslCertThumbprint,$CertificateSubject,$CertificateStore,$PfxPassphrase -ModuleName $ModuleName -ClassVersion 1.0 -FriendlyName $ResourceName -Force
#New-xDscResource -Name $ResourceName -Property $AcceptRdpConnection,$EnforceNLAuth,$AddFirewallRule  -ModuleName $ModuleName -ClassVersion 1.0 -FriendlyName $ResourceName -Force

