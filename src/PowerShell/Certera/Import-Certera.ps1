<#
.SYNOPSIS
Imports the Certera module.

.EXAMPLE
.\Import-Certera.ps1 -Force

Imports the Certera module, reloading it if its already loaded.
#>

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

[CmdletBinding(SupportsShouldProcess=$true)]
param(
    # Reload the module no matter what.
    [Switch]$Force
)

#Requires -Version 4
Set-StrictMode -Version 'Latest'

$CerteraPsd1Path = Join-Path -Path $PSScriptRoot -ChildPath 'Certera.psd1' -Resolve

& {
    
	if ($Force -and (Get-Module -Name 'Certera'))
	{
		Write-Host "Removing Certera Module"
		Remove-Module -Name 'Certera' -Force
	}
	
	Import-Module -Name $CerteraPsd1Path -Force:$Force
    
}