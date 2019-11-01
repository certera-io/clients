function Get-Cert {

    <#
    .SYNOPSIS
    Gets a certificate from Certera
    
    .DESCRIPTION
    A certificate can be in PFX or PEM format. When PfxPassword is specified, the format is PFX. Otherwise, a PEM certificate is returned.
    PFX certificates contain an exportable private key. PEM certificates do not contain the private key.
    
    .OUTPUTS
    string containing full certificate chain in PFX (base 64) protected with the given password or PEM format or `$null`.
    
    .EXAMPLE
    $pfxCert = Get-Cert -CerteraHost cert.mysite.com -ApiKey 8gpkuxy4a304 -CertName some-cert-name -PfxPassword "!234SECRETbc123" -Staging
    
    Gets a staging certificate in PFX format secured with given password.

    .EXAMPLE
    $pemCert = Get-Cert -CerteraHost cert.mysite.com -ApiKey 8gpkuxy4a304 -CertName some-cert-name -Staging
    
    Gets a staging certificate PEM format.
    #>
    
    [OutputType([string])]
    param (    
        [Parameter(Mandatory = $true)]
        [string]
        $CerteraHost,
        
        [Parameter(Mandatory = $true)]
        [string]
        $ApiKey,
        
        [Parameter(Mandatory = $true)]
        [string]
        $CertName,
        
        [Parameter(Mandatory = $false)]
        [string]
        $PfxPassword,    
        
        [switch]
        $Staging
    )
    
    $IsPSCore = $PSVersionTable['PSEdition'] -eq 'Core'
    
    $skipCertCheck = $CerteraHost -eq "localhost"
    
    # When connecting to localhost, trust the self-signed cert
    if ($skipCertCheck -And -Not $IsPSCore) {
        if (-Not "TrustAllCertsPolicy" -as [type]) {
            add-type @"
                using System.Net;
                using System.Security.Cryptography.X509Certificates;
                public class TrustAllCertsPolicy : System.Net.ICertificatePolicy {
                    public bool CheckValidationResult(
                        ServicePoint srvPoint, X509Certificate certificate,
                        WebRequest request, int certificateProblem) {
                            return true;
                    }
                }
"@
            [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
        }
    }

    # If no PFX password is specified, the default cert format is PEM
    $params = @{}
    
    if (-Not [string]::IsNullOrWhiteSpace($PfxPassword)) {
        $params.Add("format", "pfx")
        $params.Add("pfxPassword", $PfxPassword)
    }
    
    if ($Staging) {
        $params.Add("staging", "true")
    }
        
    $headers = @{
        apiKey = $ApiKey
    }
    
    Write-Host "Requesting certificate $CertName"
    
    if ($IsPSCore) {
        $resp = Invoke-WebRequest "https://$CerteraHost/api/certificate/$CertName" `
            -SkipCertificateCheck:$skipCertCheck `
            -SslProtocol 'Tls12' `
            -Body $params `
            -Headers $headers `
            -UseBasicParsing
    }
    else {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        
        $resp = Invoke-WebRequest "https://$CerteraHost/api/certificate/$CertName" `
            -Body $params `
            -Headers $headers `
            -UseBasicParsing
    }
    
    if ($resp.StatusCode -eq 404) {
        Write-Host "Certificate $CertName not found"
        return $null
    }
    
    if ($resp.StatusCode -ne 200) {
        throw "Error: $($resp.StatusCode) $($resp.StatusDescription) $($resp.Content)"
    }
    
    $certData = $resp.Content

    Write-Host "Certificate retrieved."
    
    return $certData
}