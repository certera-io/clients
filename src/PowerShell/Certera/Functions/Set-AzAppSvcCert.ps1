function Set-AzAppSvcCert {
	
	<#
    .SYNOPSIS
    Updates an Azure App Service SSL binding to use the specified certificate
	
	.DESCRIPTION
    Compares the current certificate used by the binding to the specified certificate (based on thumbprint).
	Updates SSL binding certificate if thumbprint different.
    
    .OUTPUTS
    $True if binding was updated. $False if binding was not updated.
	
	.EXAMPLE
	Set-AzAppSvcCert -Certificate $pfxCert `
		-ResourceGroupName MyAzRG `
		-WebAppName api-example-site `
		-SslBindingName api.example.com `
		-PfxPassword "234SECRETbc123" `
		-TenantId "contoso.com" `
		-AppId "123-34234-23424" `
		-AppSecret "app-secret"

	Updates the Azure App Service SSL binding to use the specified certificate.
	#>
	
	[OutputType([bool])]
	param (
		[Parameter(ValueFromPipeline = $true, Mandatory = $true)]
		[string]
		$Certificate,
		
		[Parameter(Mandatory = $true)]
		[string]
		$ResourceGroupName,
		
		[Parameter(Mandatory = $true)]
		[string]
		$WebAppName,
		
		[Parameter(Mandatory = $true)]
		[string]
		$SslBindingName,
		
		[Parameter(Mandatory = $true)]
		[string]
		$PfxPassword,
		
		[Parameter(Mandatory = $true)]
		[string]
		$TenantId,
		
		[Parameter(Mandatory = $true)]
		[string]
		$AppId,
		
		[Parameter(Mandatory = $true)]
		[string]
		$AppSecret
	)

	$isPem = $Certificate.StartsWith("-----BEGIN CERTIFICATE-----")
	if ($isPem) {
		throw "PEM format not supported"
	}
	
	# Make sure we have the Az PS module imported
	Ensure-Module Az

	# Connect to Azure using Service Pricipal
	$credentials = New-Object System.Management.Automation.PSCredential ($AppId, $AppSecret)
	Connect-AzAccount -ServicePrincipal -Credential $credentials -Tenant $TenantId

	$currentSslBinding = Get-AzureRmWebAppSSLBinding -ResourceGroupName $ResourceGroupName `
		-WebAppName $WebAppName `
		-Name $SslBindingName

	$bytes = [Convert]::FromBase64String($Certificate)
	
	$xCert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2Collection
	$xCert.Import($bytes, $PfxPassword, "DefaultKeySet")
	
	$thumbprint = ($xCert.Thumbprint | select -last 1)
	
	$updateCert = $True
	if ($currentSslBinding) {
		# Compare thumbprint
		#$updateCert = @(Compare-Object $currentSslBinding.Thumbprint $xCert.Thumbprint).length -ne 0
		$updateCert = $currentSslBinding.Thumbprint -ne ($xCert.Thumbprint | select -last 1)
	}

	if ($updateCert) {
		Write-Host "Binding thumbprint $($currentSslBinding.Thumbprint) does not match available thumbprint $thumbprint"
	
		$tempFile = New-TemporaryFile
		
		try {
			# Save cert to temp location that will be deleted after
			[IO.File]::WriteAllBytes($tempFile, $bytes)

			New-AzureRmWebAppSSLBinding -ResourceGroupName $ResourceGroupName -WebAppName $WebAppName -Name $SslBindingName `
				-CertificateFilePath $tempFile `
				-CertificatePassword $PfxPassword
				-ErrorAction Continue
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

function Ensure-Module {
    param(
        [string] $mod
    )
    $m = Get-Module -Name $mod
    if($m -eq $null)
    {
        Write-Host "$mod not imported"
        $module = Get-InstalledModule $mod -ea SilentlyContinue
        $module
        if ($module -eq $null)
        {
			Write-Host "$mod not installed. Installing..."
            Install-Module $mod -Force -AllowClobber
        }
        Write-Host "Importing $mod"
        Import-Module $mod -Scope Global
    }
}