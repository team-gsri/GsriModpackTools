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

function Test-NodePath {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string]$Node
    )

    if (Test-Path $Node -ErrorAction SilentlyContinue) {
        Write-Verbose "$Node trouvé"
        return $true
    }
    else {
        Write-Verbose "$Node n'existe pas"
        return $false
    }
}

function Test-NodePathAndPropertyPath {
    [CmdletBinding()]
    param(
        [string]$Node,
        [string]$Property
    )

    if (-not (Test-NodePath $Node)) {
        return $false;
    }
    
    $Item = Get-ItemProperty $Node -Name $Property -ErrorAction Ignore
    if ($null -eq $Item) { 
        Write-Verbose "Propriété $Property non trouvée"
        return $false 
    }

    $Path = Get-ItemPropertyValue $Node -Name $Property -ErrorAction Ignore
    if ($null -eq $Path) { return $false }
    return Test-NodePath $Path
}

function Test-AppInstallation {
    [CmdletBinding()]
    param(
        [string]$Name,
        [string]$Node,
        [string]$Property,
        [switch]$IsWOW64
    )

    $Registry_Path = 'HKLM:\SOFTWARE'
    $IsWin64 = ($env:PROCESSOR_ARCHITECTURE -eq 'AMD64')
    
    if ($IsWin64 -and $IsWOW64) {
        Write-Verbose 'Cette application utilise WOW64'
        $Registry_Path = "$Registry_Path\WOW6432Node"
    }
        
    $Registry_Path = "$Registry_Path\$Node"
    return Test-NodePathAndPropertyPath -Node $Registry_Path -Property $Property
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
    return $null -eq $Compare
}

function Test-TaskForceLegacy {
    [CmdletBinding()]
    param()

    $status = 0
    "$env:APPDATA\TS3Client\plugins\task_force_radio_win64.dll",
    "$env:APPDATA\TS3Client\plugins\task_force_radio_win32.dll" | ForEach-Object {
        if (Test-Path -PathType Leaf $_) {
            $status++
            Write-Verbose "$_ non trouvé"
        }
        else {
            Write-Verbose "$_ trouvé"
        }
    }    
    return 0 -eq $status
}

function Test-TaskForceBeta {
    [CmdletBinding()]
    param()

    $status = 0
    "$env:APPDATA\TS3Client\plugins\TFAR_win64.dll",
    "$env:APPDATA\TS3Client\plugins\TFAR_win32.dll" | ForEach-Object {
        if (Test-Path -PathType Leaf $_) {
            $status++
            Write-Verbose "$_ trouvé"
        }
        else {
            Write-Verbose "$_ non trouvé"
        }
    }    
    return 2 -eq $status
}

function Write-Generic {
    param(
        [string]$Message,
        [bool]$Result
    )
    Write-Host "$Message :`t" -NoNewline
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
        [string]$Property = 'InstallLocation',
        [switch]$IsWOW64
    )
    $Result = (Test-AppInstallation -Name $Name -Node $Node -Property $Property -IsWOW64:$IsWOW64)
    return Write-Generic -Message "Vérification de l'installation de $Name" -Result $Result
}

function Write-ModpackStatus {
    $Result = (Test-ModpackVersion)
    return Write-Generic -Message 'Vérification de la version du modpack GSRI' -Result $Result
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

    $Uninstall_Path = 'Microsoft\Windows\CurrentVersion\Uninstall'
    $status += Write-AppInstallationStatus -Name 'Steam' -Node 'Valve\Steam' -Property 'InstallPath' -IsWOW64
    $status += Write-AppInstallationStatus -Name 'Arma 3' -Node "$Uninstall_Path\Steam App 107410"
    $status += Write-AppInstallationStatus -Name 'Arma 3 Sync' -Node "$Uninstall_Path\{F097E7D7-D093-4394-9EED-43AFCCD12B7A}_is1" -IsWOW64
    $status += Write-AppInstallationStatus -Name 'TeamSpeak' -Node "$Uninstall_Path\TeamSpeak 3 Client"
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