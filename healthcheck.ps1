[CmdletBinding()]
Param()

if (!(Get-Module GsriModpackLib -ListAvailable)) { Install-Module GsriModpackLib -Scope CurrentUser }
Import-Module GsriModpackLib -Force

Write-InstallationStatus -Path $PSScriptRoot -Verbose:($PSBoundParameters['Verbose'] -eq $true) | Out-Null
Pause