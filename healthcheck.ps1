[CmdletBinding()]
Param()

Import-Module .\Core\Modules\AppStatus -Force
Import-Module .\Core\Modules\TFAR -Force
Import-Module .\Core\Modules\GSRI -Force

Write-InstallationStatus -Path $PSScriptRoot
Pause