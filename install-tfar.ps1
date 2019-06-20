# Verifying current architecture
Write-Host "Vérification de l'architecture du processeur : " -NoNewline
$Is_Arch_X64 = ($env:PROCESSOR_ARCHITECTURE -eq 'AMD64')
if ($Is_Arch_X64) { Write-Host -ForegroundColor Green '[X64]' } else { Write-Host -ForegroundColor DarkYellow '[X86]' }    

# Verifying setup presence
Write-Host "Vérification de la présence du mod TFAR : " -NoNewline
$TFAR_Zip_File = "$PSScriptRoot\Core\@TFAR\teamspeak\task_force_radio.ts3_plugin"
$TFAR_Zip = Test-Path -PathType Leaf $TFAR_Zip_File
if (!$TFAR_Zip) {
    Write-Host -ForegroundColor Red "[FAIL] "
}
else {
    Write-Host -ForegroundColor Green "[OK] "
}

# Verifying wether TS3 is running or stopped
Write-Host "Vérification si Teamspeak est en cours d'exécution : " -NoNewline
$TS_Exe = if ($Is_Arch_X64) { "ts3client_win64" } else { "ts3client_win32" }
$TS_Running = (Get-Process -Name $TS_Exe -ErrorAction Ignore | Measure-Object).Count -gt 0
if ($TS_Running) {
    Write-Host -ForegroundColor DarkYellow "[RUN] "
}
else {
    Write-Host -ForegroundColor Green "[STOP] "
}

# Verifying whether TFAR 0.x is installed
$TS_Path = "$env:APPDATA\TS3Client\plugins"
Write-Host "Vérification de l'absence du plugin TFAR Zero : " -NoNewline
$TFAR_Zero_64 = "$TS_Path\task_force_radio_win64.dll"
$TFAR_Zero_86 = "$TS_Path\task_force_radio_win32.dll"
$TFAR_Zero_File = if ($Is_Arch_X64) { $TFAR_Zero_64 } else { $TFAR_Zero_86 }
$TFAR_Zero = Test-Path -PathType Leaf $TFAR_Zero_File
if ($TFAR_Zero -and $TS_Running) {
    Write-Host -ForegroundColor Red "[FAIL]"
    Write-Host -ForegroundColor DarkYellow " > TFAR 0.x installé et Teamspeak en cours d'exécution"
    exit
}
elseif ($TFAR_Zero) {
    Write-Host -ForegroundColor DarkYellow "[FAIL]"
    Write-Host -ForegroundColor Blue " > TFAR 0.x installé, suppression en cours"
    Remove-Item $TFAR_Zero_64 -ErrorAction Ignore
    Remove-Item $TFAR_Zero_86 -ErrorAction Ignore
}
else {
    Write-Host -ForegroundColor Green "[OK]"
}

# Verifying whether TFAR 1.x is installed
$TS_Path = "$env:APPDATA\TS3Client\plugins"
Write-Host "Vérification de la présence du plugin TFAR Beta : " -NoNewline
$TFAR_Beta_64 = "$TS_Path\TFAR_win64.dll"
$TFAR_Beta_86 = "$TS_Path\TFAR_win32.dll"
$TFAR_Beta_File = if ($Is_Arch_X64) { $TFAR_Beta_64 } else { $TFAR_Beta_86 }
$TFAR_Beta = Test-Path -PathType Leaf $TFAR_Beta_File
if (!$TFAR_Beta -and !$TFAR_Zip) {
    Write-Host -ForegroundColor Red "[FAIL]"
    Write-Host -ForegroundColor DarkYellow " > Plugin pas installé et setup mmanquant"
    Write-Host -ForegroundColor DarkYellow " > Veuillez vérifier l'intégrité des mods téléchargés !"
    exit
} elseif(!$TFAR_Beta) {
    Write-Host -ForegroundColor DarkYellow "[MISSING]"
    Write-Host "Installation du plugin TFAR Beta : " -NoNewline
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory($TFAR_Zip_File, "$TS_Path\..")
    Remove-Item "$TS_Path\..\package.ini"
} else {
    Write-Host -ForegroundColor Green "[OK]"
}
