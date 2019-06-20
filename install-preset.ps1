#Verifying preset directory existance
Write-Host "Vérification de l'existance du dossier de préset du launcher Arma 3 : " -NoNewline
$Preset_Directory = "$env:LOCALAPPDATA\Arma 3 Launcher\Presets"
$Directory_Exists = Test-Path -PathType Container $Preset_Directory
if (!$Directory_Exists) {
    Write-Host -ForegroundColor Yellow "[MISSING]"
    Write-Host "Création du dossier de préset du launcher Arma 3 : " -NoNewline
    New-Item $Preset_Directory -ItemType Directory | Out-Null
    Write-Host -ForegroundColor Green "[OK]"
}
else {
    Write-Host -ForegroundColor Green "[PRESENT]"
}

# Verifying preset installation
Write-Host "Vérification de l'existance d'un préset GSRI : " -NoNewline
$Preset_File = "$Preset_Directory\GSRI.preset2"
$Preset = Test-Path -PathType Leaf $Preset_File
if ($Preset) {
    Write-Host -ForegroundColor Yellow "[EXISTS]"
    Remove-Item $Preset_File -Confirm
    if (Test-Path -PathType Leaf $Preset_File) { exit }
}
else {
    Write-Host -ForegroundColor Green "[NONE]"
}

# Creating a new preset file
Write-Host "Génération d'un préset GSRI : " -NoNewline
$Preset_Date = Get-Date -Format "o"
Add-Content -Path $Preset_File '<?xml version="1.0" encoding="utf-8"?>'
Add-Content -Path $Preset_File '<addons-presets>'
Add-Content -Path $Preset_File "<last-update>$Preset_Date</last-update>"
Add-Content -Path $Preset_File '<published-ids>'
Get-ChildItem -Path $PSScriptRoot -Recurse -Filter "@*" |
Where-Object { !($_.FullName -like "*\Campaign\@*") } |
ForEach-Object {
    Add-Content -Path $Preset_File "<id>local:$($_.FullName)</id>"
}
Add-Content -Path $Preset_File '</published-ids>'
Add-Content -Path $Preset_File '<dlcs-appids />'
Add-Content -Path $Preset_File '</addons-presets>'
Write-Host -ForegroundColor Green "[OK] "

Pause