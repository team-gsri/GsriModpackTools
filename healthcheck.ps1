[CmdletBinding()]
Param()

Import-Module .\GSRI -Force

Write-InstallationStatus -Path $PSScriptRoot -Verbose:($PSBoundParameters['Verbose'] -eq $true) | Out-Null
Pause