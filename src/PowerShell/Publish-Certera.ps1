param (
	[Parameter(Mandatory=$true)]
	[ValidatePattern("^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(-(0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(\.(0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*)?(\+[0-9a-zA-Z-]+(\.[0-9a-zA-Z-]+)*)?$")]
	[string]
	$Version,
	
	[string]
	$ApiKey	
)

$PSScriptFilePath = Get-Item $MyInvocation.MyCommand.Path

$manifestPath = Join-Path -Path $PSScriptRoot -ChildPath '.\Certera\Certera.psd1' -Resolve

$modulePath = Join-Path -Path $PSScriptRoot -ChildPath ".\Certera" -Resolve

$moduleVersionRegex = 'ModuleVersion\s*=\s*(''|")([^''"])+(''|")' 
$rawManifest = Get-Content -Raw -Path $manifestPath
if( $rawManifest -notmatch ('ModuleVersion\s*=\s*(''|"){0}(''|")' -f [regex]::Escape($version.ToString())))
{
	$rawManifest = $rawManifest -replace $moduleVersionRegex,('ModuleVersion = ''{0}''' -f $Version)
	$rawManifest | Set-Content -Path $manifestPath -NoNewline
}

Publish-Module -Path $modulePath `
			   -Repository 'PSGallery' `
			   -NuGetApiKey $ApiKey