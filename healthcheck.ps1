[CmdletBinding()]
Param()

function Get-RemoteVersion {
    [CmdletBinding()]
    param()

    $Content = (Invoke-WebRequest -URI 'https://mods.gsri.team/version.txt').Content
    if ($null -eq $Content) { throw 'Impossible de contacter le serveur de mods GSRI' }
    return $Content.Trim()
}

function Get-LocalVersion {
    $Content = (Get-Content .\version.txt -ErrorAction SilentlyContinue)
    if ($null -eq $Content) { return 0 }
    return $Content.Trim()
}

function Test-AppInstallation {
    [CmdletBinding()]
    param(
        [string]$Name,
        [string]$Node,
        [switch]$IsWOW64
    )

    $Registry_Path_Default = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall'
    $Registry_Path_Wow = 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
    $IsWin64 = ($env:PROCESSOR_ARCHITECTURE -eq 'AMD64')
    if ($IsWin64 -and $IsWOW64) {
        Write-Verbose 'Cette application utilise WOW64'
        $Registry_Path = "$Registry_Path_Wow\$Node"
    }
    else {
        $Registry_Path = "$Registry_Path_Default\$Node"
    }
    Write-Verbose "Recherche de la clef de registre : $Registry_Path"
    $Install_Location = Get-ItemPropertyValue -Path $Registry_Path -Name InstallLocation -ErrorAction SilentlyContinue        
    if ($null -eq $Install_Location) {
        write-verbose 'La clef de registre est introuvable'
        return $false 
    }
    Write-Debug "Recherche du chemin d'installation de l'application : $Install_Location"
    return Test-Path -Path $Install_Location -PathType Container -ErrorAction SilentlyContinue
}

function Test-ModpackVersion {
    [CmdletBinding()]
    param()

    $Remote = Get-RemoteVersion    
    Write-Verbose "Version serveur : $Remote"

    $Local = Get-LocalVersion
    if (0 -eq $Local) {
        Write-Verbose 'Modpack local introuvable'
        return $false
    }
    else {
        Write-Verbose "Version locale : $Local"
    }

    $Compare = Compare-Object $Remote -DifferenceObject $Local
    return 0 -eq $Compare
}

function Test-TaskForceLegacy {
    [CmdletBinding()]
    param()

    Write-Verbose 'Recherche des fichiers TFAR 0.x ...'
    "$env:APPDATA\TS3Client\plugins\task_force_radio_win64.dll",
    "$env:APPDATA\TS3Client\plugins\task_force_radio_win32.dll" | ForEach-Object {
        if (Test-Path -PathType Leaf $_) {
            Write-Warning "Un fichier TFAR 0.x a été détecté : $_"
            $status++
        }
    }    
    return 0 -eq $status
}

function Test-TaskForceBeta {
    [CmdletBinding()]
    param()

    Write-Verbose 'Recherche des fichiers TFAR 1.x ...'
    "$env:APPDATA\TS3Client\plugins\TFAR_win64.dll",
    "$env:APPDATA\TS3Client\plugins\TFAR_win32.dll" | ForEach-Object {
        if (-not (Test-Path -PathType Leaf $_)) {
            Write-Verbose "Le fichier TFAR 1.x est manquant : $_"
            $status++
        }
    }    
    return 2 -eq $status
}

function Write-Generic {
    param(
        [string]$Message,
        [bool]$Result
    )
    Write-Host "$Message : " -NoNewline
    if ($Result) {
        Write-Host -ForegroundColor Green '[OK]'
        return 0
    } 
    Write-Host -ForegroundColor Red '[FAIL]'
    return 1
}

function Write-AppInstallationStatus {
    param(
        [string]$Name,
        [string]$Node,
        [switch]$IsWOW64
    )
    $Result = (Test-AppInstallation -Name $Name -Node $Node -IsWOW64:$IsWOW64)
    return Write-Generic -Message "Vérification de l'installation de $Name" -Result $Result
}

function Write-ModpackStatus {
    $Result = (Test-ModpackVersion)
    return Write-Generic -Message 'Vérification de la version du modpack' -Result $Result
}

function Write-TaskForceStatus {
    [CmdletBinding()]
    param()

    $Result = (Test-TaskForceLegacy) -and (Test-TaskForceBeta)
    return Write-Generic -Message 'Vérification de l''installation du plugin TFAR' -Result $Result    
}

function Write-InstallationStatus {
    [CmdletBinding()]
    param()

    $status += Write-AppInstallationStatus -Name 'Arma 3' -Node 'Steam App 107410'
    $status += Write-AppInstallationStatus -Name 'Arma3Sync' -Node '{F097E7D7-D093-4394-9EED-43AFCCD12B7A}_is1' -IsWOW64
    $status += Write-AppInstallationStatus -Name 'TeamSpeak 3 Client' -Node 'TeamSpeak 3 Client'
    $status += Write-ModpackStatus
    $status += Write-TaskForceStatus

    if (0 -lt $status) {
        Write-Host -ForegroundColor Red "`n *** Votre installation n'est pas correcte *** `n"
    }
    else {
        Write-Host -ForegroundColor Green "`n *** Votre installation est validée *** `n"
    }
}

Write-InstallationStatus
Pause