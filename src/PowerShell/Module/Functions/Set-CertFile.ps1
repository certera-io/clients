function Set-CertFile {

    <#
    .SYNOPSIS
    Persists a given certificate to file
	
	.DESCRIPTION
    Compares the current cert and overwrites if different based on thumbprint. Certificate is PFX or PEM format obtained from Get-Cert. 
	If PfxPassword is specified, the file is considered to be PFX. Otherwise, it is considered to be PEM format.
    
    .OUTPUTS
    $True if cert was written to file. $False if cert was not written to file.
	
	.EXAMPLE
	Set-CertFile -Certificate $pfxCert -CertFile some.mysite.com.pfx -PfxPassword "!234SECRETbc123"

	Stores the PFX certificate in specified file.
	
	.EXAMPLE
	Set-CertFile -Certificate $pemCert -CertFile some.mysite.com.pem
	
	Stores the PEM formatted certificate in specified file.
	#>
	
	[OutputType([bool])]
	param (
		[Parameter(ValueFromPipeline = $true, Mandatory = $true)]
		[string]
		$Certificate,
		
		[Parameter(Mandatory = $true)]
		[string]
		$CertFile,
		
		[Parameter(Mandatory = $false)]
		[string]
		$PfxPassword
	)

	# Certificate is base64 encoded PFX or PEM
	$isPem = $Certificate.StartsWith("-----BEGIN")
	if ($isPem) {
		if (-Not "PemCertImporter" -as [type]) {
			$source = @"
				using System;
				using System.Security.Cryptography.X509Certificates;
				
				public class PemCertImporter
				{
					public static X509Certificate2Collection GetCertFromPem(string pem)
					{
						pem = pem.Replace("-----END CERTIFICATE-----", "");
						var parts = pem.Split(new[] { "-----BEGIN CERTIFICATE-----" }, StringSplitOptions.RemoveEmptyEntries);

						var result = new X509Certificate2Collection();
						foreach (var part in parts)
						{
							var cleaned = part.Trim();
							if (string.IsNullOrWhiteSpace(cleaned))
							{
								continue;
							}
							result.Import(Convert.FromBase64String(cleaned));
						}
						return result;
					}
				}
"@
			Add-Type -TypeDefinition $source
		}
		$xCert = [PemCertImporter]::GetCertFromPem($Certificate)
	}
	else {
		$bytes = [Convert]::FromBase64String($Certificate)
		
		# Load the certificate to compare thumbprints
		$xCert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2Collection
		$xCert.Import($bytes, $PfxPassword, "DefaultKeySet")
	}
	# Since .NET components are being used, change it so things like WriteAllBytes works correctly
	[Environment]::CurrentDirectory = (Get-Location -PSProvider FileSystem).ProviderPath

	$updateCert = $True
	if (Test-Path $CertFile) {
		Write-Host "Comparing to existing certificate"
		
		# Compare thumbprint
		if ($isPem) {
			$currentPemContents = Get-Content $CertFile
			$currentCert = [PemCertImporter]::GetCertFromPem($currentPemContents)
		}
		else {
			$currentCert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2Collection
			$currentCert.Import($CertFile, $PfxPassword, "DefaultKeySet")
		}
		
		$updateCert = @(Compare-Object $currentCert.Thumbprint $xCert.Thumbprint).length -ne 0
	}

	if ($updateCert)
	{
		if ($isPem) {
			[IO.File]::WriteAllText($CertFile, $Certificate)
		}
		else {
			$bytes = [Convert]::FromBase64String($Certificate)
			[IO.File]::WriteAllBytes($CertFile, $bytes)
		}
		Write-Host "Certificate updated"
	}
	else {
		Write-Host "Cert not changed"
	}

	return $updateCert
}