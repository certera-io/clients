param (
	[Parameter(Mandatory=$true)]
	[ValidatePattern("^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(-(0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(\.(0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*)?(\+[0-9a-zA-Z-]+(\.[0-9a-zA-Z-]+)*)?$")]
	[string]
	$Version,
	
	[string]
	$ApiKey	
)

$PSScriptFilePath = Get-Item $MyInvocation.MyCommand.Path

$nuspecPath = Join-Path -Path $PSScriptRoot -ChildPath '.\Certera.nuspec' -Resolve
$manifestPath = Join-Path -Path $PSScriptRoot -ChildPath '.\Module\Certera.psd1' -Resolve

$modulePath = Join-Path -Path $PSScriptRoot -ChildPath '.\Module\Certera.psd1' -Resolve

# Modify the Certera.nuspec version
$nuspec = [xml](Get-Content -Raw -Path $nuspecPath)
if ($nuspec.package.metadata.version -ne $Version)
{
	$nuGetVersion = $Version #-replace '-([A-Z0-9]+)[^A-Z0-9]*(\d+)$','-$1$2'
	$nuspec.package.metadata.version = $nugetVersion
	$nuspec.Save($nuspecPath)
}

$moduleVersionRegex = 'ModuleVersion\s*=\s*(''|")([^''"])+(''|")' 
$rawManifest = Get-Content -Raw -Path $manifestPath
if( $rawManifest -notmatch ('ModuleVersion\s*=\s*(''|"){0}(''|")' -f [regex]::Escape($version.ToString())))
{
	$rawManifest = $rawManifest -replace $moduleVersionRegex,('ModuleVersion = ''{0}''' -f $Version)
	$rawManifest | Set-Content -Path $manifestPath -NoNewline
}
	
.\nuget.exe pack Certera.nuspec

#Publish-Module -Path $ModulePath `
#			   -Repository 'PSGallery' `
#			   -NuGetApiKey $ApiKey