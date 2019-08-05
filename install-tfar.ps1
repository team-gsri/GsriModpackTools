[CmdletBinding()]
Param()

try {
    Install-Module GsriModpackLib -Force -MaximumVersion 2.0
    Import-Module GsriModpackLib -Force -MaximumVersion 2.0
    
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