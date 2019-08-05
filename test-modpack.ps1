[CmdletBinding()]
Param()

Install-Module GsriModpackLib -Force -MaximumVersion 2.0
Import-Module GsriModpackLib -Force -MaximumVersion 2.0

Show-InstallationStatus -Path $PSScriptRoot -Verbose:($PSBoundParameters['Verbose'] -eq $true) | Out-Null
Pause