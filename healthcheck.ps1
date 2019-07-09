[CmdletBinding()]
Param()

Import-Module .\Core\Modules\Arma -Force
Import-Module .\Core\Modules\AppStatus -Force
Import-Module .\Core\Modules\TFAR -Force
Import-Module .\Core\Modules\GSRI -Force

$Result = Write-InstallationStatus -Path $PSScriptRoot -Verbose:($PSBoundParameters['Verbose'] -eq $true)
Pause