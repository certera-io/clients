function Set-IisCert {

    <#
    .SYNOPSIS
    Updates an IIS binding to use the specified certificate
	
	.DESCRIPTION
    Compares the current certificate used by the binding to the specified certificate (based on thumbprint).
	Certificate is stored in LocalMachine\WebHosting certificate store.
	Updates IIS binding certificate if thumbprint different.
    
    .OUTPUTS
    $True if binding was updated. $False if binding was not updated.
	
	.EXAMPLE
	Set-IisCert -Certificate $pfxCert  -PfxPassword "!234SECRETbc123" -Port 443 -IisSite "Default Web Site" -SniHostName "test.mysite.com"

	Updates the IIS site's binding to use the specified certificate.
	#>
	
	[OutputType([bool])]
	param (
		[Parameter(ValueFromPipeline = $true, Mandatory = $true)]
		[string]
		$Certificate,
		
		[Parameter(Mandatory = $true)]
		[string]
		$PfxPassword,
			
		[Parameter(Mandatory = $true)]
		[int]
		$Port,
		
		[Parameter(Mandatory = $true)]
		[string]
		$IisSite,
		
		[Parameter(Mandatory = $true)]
		[string]
		$SniHostName
	)
	
	$isPem = $Certificate.StartsWith("-----BEGIN CERTIFICATE-----")
	if ($isPem) {
		throw "PEM format not supported"
	}
	
	$bytes = [Convert]::FromBase64String($Certificate)
	
	$xCert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2Collection
	$xCert.Import($bytes, $PfxPassword, "DefaultKeySet")
	
	$thumbprint = ($xCert.Thumbprint | select -last 1)
	
	$binding = Get-WebBinding -Name $IisSite -Port $Port -Protocol "https" | Where-Object { 
		($_.bindingInformation -Split ":")[-1] -eq $SniHostName
	}

	$updateCert = $True
	if ($binding) {
		# Compare thumbprint
		$updateCert = $binding.certificateHash -ne $thumbprint
	}
	else {
		throw "Unable to locate IIS binding: $IisSite`:$Port`:$SniHostName"
	}

	if ($updateCert)
	{
		Write-Host "Binding thumbprint $($binding.certificateHash) does not match available thumbprint $thumbprint"
		$tempFile = New-TemporaryFile
		try {
			# Save cert to temp location that will be deleted after
			[IO.File]::WriteAllBytes($tempFile, $bytes)
			
			$securePwd = ConvertTo-SecureString -String $PfxPassword -AsPlainText -Force
			$importedCert = (Import-PfxCertificate -FilePath $tempFile -Password $securePwd -CertStoreLocation Cert:\LocalMachine\WebHosting -Verbose)
			
			$binding.AddSslCertificate($importedCert.Thumbprint, "WebHosting")
		}
		finally {
			Remove-Item $tempFile
		}
	}
	else {
		Write-Host "Binding certificate same as available certificate"
	}
	
	return $updateCert
}