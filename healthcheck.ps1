try {

    # Récupération du dossier mods
    Write-Host -ForegroundColor Green -NoNewline "[OK] "
    Write-Host "Dossier mods : " $PSScriptRoot

    # Vérification de l'installation de Arma 3
    $A3_Registry_Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Steam App 107410'
    $A3_Registry = Get-ItemProperty -Path $A3_Registry_Path -ErrorAction Ignore
    if ($null -eq $A3_Registry.InstallLocation) { throw "[FAIL] Arma 3 n'est pas installé !" }
    Write-Host -ForegroundColor Green -NoNewline "[OK] "
    Write-Host "Arma 3 installé : " $A3_Registry.InstallLocation

    # Vérification de l'installation de Arma3Sync
    $Sync_Registry_Path = 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\{F097E7D7-D093-4394-9EED-43AFCCD12B7A}_is1'
    $Sync_Registry = Get-ItemProperty -Path $Sync_Registry_Path -ErrorAction Ignore
    if ($null -eq $Sync_Registry.InstallLocation) { throw "[FAIL] Arma3Sync n'est pas installé !" }
    Write-Host -ForegroundColor Green -NoNewline "[OK] "
    Write-Host "Arma3Sync installé : " $Sync_Registry.InstallLocation

    # Vérification de l'installation de Teamspeak
    $TS_Registry_Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\TeamSpeak 3 Client'
    $TS_Registry = Get-ItemProperty -Path $TS_Registry_Path -ErrorAction Ignore
    if ($null -eq $TS_Registry.InstallLocation) { throw "[FAIL] Teamspeak n'est pas installé !" }
    Write-Host -ForegroundColor Green -NoNewline "[OK] "
    Write-Host "Teamspeak installé : " $TS_Registry.InstallLocation

    # Vérification si le modpack est à jour
    $Ver_Remote = (Invoke-WebRequest -URI "https://mods.gsri.team/version.txt").Content.Trim()
    if ($null -eq $Ver_Remote) {
        throw "[FAIL] impossible de contacter le serveur de mods GSRI !"
    }
    Write-Host -ForegroundColor Green -NoNewline "[OK] "
    Write-Host "Modpack GSRI : version" $Ver_Remote
    $Ver_Local = (Get-Content .\version.txt).Trim()
    Write-Host -ForegroundColor Green -NoNewline "[OK] "
    Write-Host "Modpack local : version" $Ver_Local
    if (Compare-Object $Ver_Remote -DifferenceObject $Ver_Local) {
        throw "[FAIL] Veuillez mettre à jour le modpack GSRI !"
    }

    # Récupération du chemin des plugins
    $TS_Plugins_Path = "$env:APPDATA\TS3Client\plugins"
    Write-Host -ForegroundColor Green -NoNewline "[OK] "
    Write-Host "Teamspeak plugins : " $TS_Plugins_Path

    # Arrête de Teamspeak si nécessaire
    $TS_was_running = $false
    $TS_Count = Get-Process -Name "ts3client_win64" -ErrorAction Ignore | Measure-Object
    if ($TS_Count.Count -gt 0) {
        $TS_was_running = $true
        Write-Host -ForegroundColor DarkYellow -NoNewline "[WARN] "
        Write-Host "Teamspeak en cours d'exécution, arrêt en cours ..."
        Start-Process -Verb RunAs -FilePath "powershell.exe" -ArgumentList 'Get-Process -Name "ts3client_win64" | ForEach-Object { $_.CloseMainWindow() | Out-Null }'
        Start-Sleep -Seconds 3
    }

    # Nettoyage des reliquats de TFAR 0.x
    "$TS_Plugins_Path\task_force_radio_win32.dll", `
        "$TS_Plugins_Path\task_force_radio_win64.dll" | ForEach-Object {
        if (Test-Path -PathType Leaf $_) {
            Write-Host -ForegroundColor DarkYellow -NoNewline "[WARN] "
            Write-Host "Plugin TFAR 0.x présent, suppression en cours ..."
            Remove-Item $_
        }
    }

    # Vérification de la présence de l'installeur du plugin TFAR
    $TFAR_Zip = "$PSScriptRoot\Core\@TFAR\teamspeak\task_force_radio.ts3_plugin"
    if (-not (Test-Path -PathType Leaf $TFAR_Zip)) {
        throw "[FAIL] Le mod TFAR est manquant"
    }
    Write-Host -ForegroundColor Green -NoNewline "[OK] "
    Write-Host "Installeur plugin TFAR présent : " $TFAR_Zip

    # Réinstallation du plugin
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    "$TS_Plugins_Path\TFAR_win32.dll",
    "$TS_Plugins_Path\TFAR_win64.dll" | ForEach-Object { if (Test-Path -PathType Leaf $_) { Remove-Item $_ } }
    if (Test-Path -PathType Container "$TS_Plugins_Path\radio-sounds") { Remove-Item -Recurse "$TS_Plugins_Path\radio-sounds" }
    [System.IO.Compression.ZipFile]::ExtractToDirectory($TFAR_Zip, "$TS_Plugins_Path\..")
    Remove-Item "$TS_Plugins_Path\..\package.ini"
    Write-Host -ForegroundColor Green -NoNewline "[OK] "
    Write-Host "Plugin TFAR forcé sur la version GSRI avec succès"

    # Vérification de l'existance d'un préset GSRI
    $A3_Preset = "$env:LOCALAPPDATA\Arma 3 Launcher\Presets\GSRI.preset2"
    Write-Host -ForegroundColor Green -NoNewline "[OK] "
    Write-Host "Arma 3 Launcher GSRI preset : " $A3_Preset
    if (Test-Path -PathType Leaf $A3_Preset) {
        Write-Host -ForegroundColor DarkYellow -NoNewline "[WARN] "
        Write-Host "Le preset GSRI existe déjà, suppression ..."
        Remove-Item $A3_Preset
    }
    Add-Content -Path $A3_Preset '<?xml version="1.0" encoding="utf-8"?>'
    Add-Content -Path $A3_Preset "<addons-presets>
<last-update>$(Get-Date -Format "o")</last-update>
<published-ids>"
    Get-ChildItem -Path $PSScriptRoot -Recurse -Filter "@*" |
            Where-Object { !($_.FullName -like "*\Campaign\@*") } |
            ForEach-Object {
        Add-Content -Path $A3_Preset "<id>local:$($_.FullName)</id>"
    }
    Add-Content -Path $A3_Preset '</published-ids>
<dlcs-appids />
</addons-presets>'
    Write-Host -ForegroundColor Green -NoNewline "[OK] "
    Write-Host "Preset GSRI créé dans le launcher officiel"

    
    Write-Host ""
    Write-Host "Votre installation est validée"
    Pause
}
catch {
    Write-Host ""
    Write-Host -ForegroundColor Red $_.Exception.Message
    Pause
}
