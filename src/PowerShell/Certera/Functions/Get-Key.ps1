function Get-Key {

    <#
    .SYNOPSIS
    Gets a key from Certera
    
    .DESCRIPTION
    A key can be in DER or PEM format.
    
    .OUTPUTS
    string containing the key in DER (base 64 encoded) or PEM format, or `$null`.
    
    .EXAMPLE
    $derKey = Get-Key -CerteraHost cert.mysite.com -ApiKey 8gpkuxy4a304 -KeyName some-key-name -Format der

    Gets a key in DER format.
    
    .EXAMPLE
    $pemKey = Get-Key -CerteraHost cert.mysite.com -ApiKey 8gpkuxy4a304 -KeyName some-key-name -Format pem
    
    Gets a key in PEM format.
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
        $KeyName,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet("der", "pem")]
        [string]
        $Format
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

    $params = @{
        format = "$Format"
    }
        
    $headers = @{
        apiKey = $ApiKey
    }
    
    Write-Host "Requesting key $KeyName"
    if ($IsPSCore) {
        $resp = Invoke-WebRequest https://$CerteraHost/api/key/$KeyName `
            -SkipCertificateCheck:$skipCertCheck `
            -Body $params `
            -Headers $headers `
            -UseBasicParsing
    }
    else {
        $resp = Invoke-WebRequest https://$CerteraHost/api/key/$KeyName `
            -Body $params `
            -Headers $headers `
            -UseBasicParsing
    }
    
    if ($resp.StatusCode -eq 404) {
        Write-Host "Key $KeyName not found"
        return $null
    }
    
    if ($resp.StatusCode -ne 200) {
        throw "Error: $($resp.StatusCode) $($resp.StatusDescription) $($resp.Content)"
    }
    
    $keyData = $resp.Content

    Write-Host "Key retrieved."
    
    return $keyData
}