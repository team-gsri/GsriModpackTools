[CmdletBinding()]
Param()

Import-Module .\Core\Modules\Arma -Force
Import-Module .\Core\Modules\AppStatus -Force
Import-Module .\Core\Modules\TFAR -Force
Import-Module .\Core\Modules\GSRI -Force

try {
    if(-not (Write-InstallationStatus -Path $PSScriptRoot -Verbose:($PSBoundParameters['Verbose'] -eq $true))) {
        throw 'Please fix your installation first'
    }
    $PluginPath = 'Core\@TFAR\teamspeak\task_force_radio.ts3_plugin'
    Install-TaskForceAddon -PluginSource "$PSScriptRoot\$PluginPath" -Verbose:($PSBoundParameters['Verbose'] -eq $true)
}
catch {
    $Message = $_.Exception.Message
    Write-Host -ForegroundColor Red "`n *** $Message ***`n"
}
finally {
    Pause
}