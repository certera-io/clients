function Set-KeyFile {

    <#
    .SYNOPSIS
    Persists a given key to file
	
	.DESCRIPTION
    Compares the current key and overwrites if different based on file hash (MD5). Key is DER or PEM format obtained from Get-Key.
    
    .OUTPUTS
    $True if cert was written to file. $False if key was not written to file.
	
	.EXAMPLE
	Set-KeyFile -Key $derKey -KeyFile some.mysite.com.key.der

	Stores the DER formatted key in specified file.
	
	.EXAMPLE
	Set-KeyFile -Key $pemKey -KeyFile some.mysite.com.key.pem
	
	Stores the PEM formatted key in specified file.
	#>

	[OutputType([bool])]
	param (
		[Parameter(ValueFromPipeline = $true, Mandatory = $true)]
		[string]
		$Key,
		
		[Parameter(Mandatory = $true)]
		[string]
		$KeyFile
	)

	# Key is base64 encoded DER or PEM
	$isPem = $Key.StartsWith("-----BEGIN")
	
	# Since .NET components are being used, change it so things like WriteAllBytes works correctly
	[Environment]::CurrentDirectory = (Get-Location -PSProvider FileSystem).ProviderPath

	$updateKey = $True
	if (Test-Path $KeyFile) {
		Write-Host "Comparing to existing key"
		if ($isPem) {
			$keyFileContents = [System.IO.File]::ReadAllText($KeyFile)
		}
		else {
			$bytes = [System.IO.File]::ReadAllBytes($KeyFile)
			$keyFileContents = [Convert]::ToBase64String($bytes)
		}
		
		$keyFileHash = Get-StringHash $keyFileContents
		$keyHash = Get-StringHash $Key
		
		Write-Debug "$keyHash $keyFileHash"
		
		$updateKey = $keyHash -ne $keyFileHash
	}

	if ($updateKey)
	{
		if ($isPem) {
			[IO.File]::WriteAllText($KeyFile, $Key)
		}
		else {
			$bytes = [Convert]::FromBase64String($Key)
			[IO.File]::WriteAllBytes($KeyFile, $bytes)
		}
		Write-Host "Key updated"
	}
	else {
		Write-Host "Key not changed"
	}

	return $updateKey
}

#http://jongurgul.com/blog/get-stringhash-get-filehash/ 
function Get-StringHash([String] $String, $HashName = "MD5") 
{ 
	$StringBuilder = New-Object System.Text.StringBuilder 
	[System.Security.Cryptography.HashAlgorithm]::Create($HashName).ComputeHash([System.Text.Encoding]::UTF8.GetBytes($String)) | %{ 
		[Void]$StringBuilder.Append($_.ToString("x2")) 
	} 
	$StringBuilder.ToString() 
}