param(
    $Name,
    $ExportPassphrase,
    $TenantId = (Get-AzureRmContext).Tenant.TenantId
)

# Login to Azure PowerShell and
Login-AzureRmAccount
Import-Module AzureRM.Resources

# Create the self signed cert
$CertificateName = $Name
$thumbprint = (New-SelfSignedCertificate -CertStoreLocation Cert:\LocalMachine\My -DnsName $CertificateName).Thumbprint
$passphrase = ConvertTo-SecureString -String $ExportPassphrase -Force -AsPlainText
Export-PfxCertificate -Cert "Cert:\Localmachine\My\$Thumbprint" -FilePath c:\certificates\$CertificateName.pfx -Password $passphrase

# Load the certificate
$cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate("C:\certificates\$CertificateName.pfx", $ExportPassphrase)
$keyValue = [System.Convert]::ToBase64String($cert.GetRawCertData())
$keyId = [guid]::NewGuid()

$keyCredential = New-Object  Microsoft.Azure.Commands.Resources.Models.ActiveDirectory.PSADKeyCredential
$keyCredential.StartDate = ($Cert).GetEffectiveDateString()
$keyCredential.EndDate= ($Cert).GetExpirationDateString()
$keyCredential.KeyId = $keyId
$keyCredential.Type = "AsymmetricX509Cert"
$keyCredential.Usage = "Verify"
$keyCredential.Value = $keyValue

# Create the Azure Active Directory Application
$ApplicationName = $Name
$ApplicationPage = ("http://" + $Name)
$ApplicationUri =  ("http://" + $Name)

$azureAdApplication = New-AzureRmADApplication -DisplayName $ApplicationName -HomePage $ApplicationPage -IdentifierUris $ApplicationUri -KeyCredentials $keyCredential

# Create the Service Principal and connect it to the Application
New-AzureRmADServicePrincipal -ApplicationId $azureAdApplication.ApplicationId

# Give the Service Principal Reader access to the current subscription
New-AzureRmRoleAssignment -RoleDefinitionName Reader -ServicePrincipalName $azureAdApplication.ApplicationId

# Now you can login to Azure PowerShell with your Service Principal and Certificate
Login-AzureRmAccount -TenantId $TenantId -Certificate $thumbprint -ApplicationId $azureAdApplication.ApplicationId
