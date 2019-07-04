[CmdletBinding()]
Param()

. .\gsri.ps1


function Remove-TaskForceLegacy {
    [CmdletBinding()]
    Param()

    "$env:APPDATA\TS3Client\plugins\task_force_radio_win64.dll",
    "$env:APPDATA\TS3Client\plugins\task_force_radio_win32.dll" | ForEach-Object {
        Remove-Item $_ -ErrorAction Ignore
        Write-Verbose "$_ supprimé"
    }
}

function Install-TaskForceBeta {
    [CmdletBinding()]
    Param()

    $Plugin_Path = "$PSScriptRoot\Core\@TFAR\teamspeak"
    $Plugin_Source = "$Plugin_Path\task_force_radio.ts3_plugin"
    $Plugin_Zip = "$Plugin_Path\task_force_radio.zip"
    Copy-Item $Plugin_Source $Plugin_Zip
    Expand-Archive -Path $Plugin_Zip -DestinationPath "$env:APPDATA\TS3Client" -Force
    Remove-Item "$env:APPDATA\TS3Client\package.ini" -ErrorAction Ignore
    Remove-Item $Plugin_Zip -ErrorAction Ignore
    Write-Generic 'Installation du plugin Task Force Beta 1.x' $true
}

function Install-TaskForceAddon {
    [CmdletBinding()]
    Param()

    if (Write-ModpackStatus) { throw 'Veuillez télécharger le modpack d''abord' }
    if (Write-TeamspeakStatus) { throw 'Veuillez fermer Teamspeak d''abord' }    
    if (Write-TaskForceLegacy) { Remove-TaskForceLegacy }
    Install-TaskForceBeta
}

try {
    Install-TaskForceAddon
}
catch {
    $Message = $_.Exception.Message
    Write-Host -ForegroundColor Red "`n *** $Message ***`n"
}
finally {
    Pause
}