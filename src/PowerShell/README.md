Examples for using the Certera PowerShell module on the PowerShell Gallery: https://www.powershellgallery.com/packages/Certera

## Installing and Importing
```powershell
Install-Module Certera

Import-Module Certera
```

## Variable declarations
```powershell

$certeraHost = "cert.yourdomain.com"
$apiKey = "your-api-key"
$certName = "your-cert-name"
$pfxPassword = "<set-your-pwd>"
$keyName = "your-key-name"
```

## Working with PFX certificates
```powershell
# Get PFX certificate
$pfxCert = Get-Cert -CerteraHost $certeraHost -ApiKey $apiKey -CertName $certName -PfxPassword $pfxPassword -Staging

# Save PFX certificate to file
Set-CertFile -Certificate $pfxCert -CertFile "$certName.pfx" -PfxPassword $pfxPassword

# Set IIS certificate
Set-IisCert -Certificate $pfxCert -PfxPassword $pfxPassword -Port 443 -IisSite "Default Web Site" -SniHostName "www.mysite.com"

# Set Azure App Service certificate
Set-AzAppSvcCert -Certificate $pfxCert -ResourceGroupName MyAzRG -WebAppName api-example-site -SslBindingName api.example.com -PfxPassword $pfxPassword -TenantId "contoso.com" -AppId "123-34234-23424" -AppSecret "app-secret"
```

## Working with PEM certificates
```powershell
# Get PEM certificate
$pemCert = Get-Cert -CerteraHost $certeraHost -ApiKey $apiKey -CertName $certName -Staging

# Save PEM certificate to file
Set-CertFile -Certificate $pemCert -CertFile $certName.pem
```

## Working with keys
```powershell
# Get DER key
$derKey = Get-Key -CerteraHost $certeraHost -ApiKey $apiKey -KeyName $keyName -Format der

# Save DER key
Set-KeyFile -Key $derKey -KeyFile $certName.key.der

# Get PEM key
$pemKey = Get-Key -CerteraHost $certeraHost -ApiKey $apiKey -KeyName $keyName -Format pem

# Save PEM key
Set-KeyFile -Key $pemKey -KeyFile $certName.key.pem
```
