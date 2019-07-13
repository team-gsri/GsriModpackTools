function Get-LocalVersion {
    [CmdletBinding()]
    param(
        [string]$Path
    )
    $VersionFile = "$Path\version.txt"
    if (-not(Test-Path $VersionFile -PathType Leaf)) {
        Write-Verbose "$VersionFile not found"
        return 0
    }
    $Version = (Get-Content "$Path\version.txt" -ErrorAction SilentlyContinue).Trim()
    Write-Verbose "Local version : $Version"
    return $Version
}

function Get-RemoteVersion {
    [CmdletBinding()]
    param()

    $Content = (Invoke-WebRequest -URI 'https://mods.gsri.team/version.txt').Content
    if ($null -eq $Content) { throw 'Cannot contact GSRI mods repository' }
    $Version = $Content.Trim()
    Write-Verbose "Remote version : $Version"
    return $Version
}

function Test-ModpackVersion {
    [CmdletBinding()]
    param(
        [string]$Path
    )

    $Remote = Get-RemoteVersion    
    $Local = Get-LocalVersion -Path $Path
    if (0 -eq $Local) {
        Write-Verbose 'Local modpack not detected'
        return $false
    }

    $Compare = Compare-Object $Remote -DifferenceObject $Local
    if ( $null -eq $Compare) {
        Write-Verbose 'Local and remote versions match'
        return $true
    }
    else {
        Write-Verbose 'Local and remote versions mismatch'
        return $false
    }
}

function Write-Generic {
    [CmdletBinding()]
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
    [CmdletBinding()]
    param(
        [string]$Name,
        [string]$Node,
        [string]$Property = 'InstallLocation',
        [switch]$IsWOW64
    )
    $Result = (Test-AppInstallation -Name $Name -Node $Node -Property $Property -IsWOW64:$IsWOW64 -Verbose:($PSBoundParameters['Verbose'] -eq $true))
    return Write-Generic -Message "Checking app installation $Name" -Result $Result
}

function Write-ModpackStatus {
    [CmdletBinding()]
    param(
        [string] $Path
    )
    
    $Result = (Test-ModpackVersion -Path $Path)
    return Write-Generic -Message 'Checking GSRI modpack is up-to-date' -Result $Result
}

function Write-TaskForceStatus {
    [CmdletBinding()]
    param()

    $Result = Test-TaskForceStatus -Verbose:($PSBoundParameters['Verbose'] -eq $true)
    return Write-Generic -Message 'Checking TFAR plugin installation' -Result $Result    
}

function Write-InstallationStatus {
    [CmdletBinding()]
    param(
        [string]$Path = '.'
    )

    $Uninstall_Path = 'Microsoft\Windows\CurrentVersion\Uninstall'
    $status += Write-AppInstallationStatus -Name 'Steam' -Node 'Valve\Steam' -Property 'InstallPath' -IsWOW64
    $status += Write-AppInstallationStatus -Name 'Arma 3' -Node "$Uninstall_Path\Steam App 107410"
    $status += Write-AppInstallationStatus -Name 'Arma 3 Sync' -Node "$Uninstall_Path\{F097E7D7-D093-4394-9EED-43AFCCD12B7A}_is1" -IsWOW64
    $status += Write-AppInstallationStatus -Name 'TeamSpeak' -Node "$Uninstall_Path\TeamSpeak 3 Client"
    $status += Write-ModpackStatus -Path $Path
    $status += Write-TaskForceStatus

    if (0 -lt $status) {
        Write-Host -ForegroundColor Red "`n *** Your installation is incorrect *** `n"
        return $false
    }
    else {
        Write-Host -ForegroundColor Green "`n *** Your installation is valid *** `n"
        return $true
    }
}

function Install-Preset {
    [CmdletBinding()]
    param(
        [string]$Path,
        [string]$Name
    )

    if (-not(Test-Path $Path -PathType Container)) {
        throw "$Path not found"
    }
    Get-ChildItem -Path $Path -Recurse -Filter "@*" |
    Where-Object { -not ($_.FullName -like "*\Campaign\@*") } |
    Write-Preset -Name $Name -Verbose:($PSBoundParameters['Verbose'] -eq $true)
}

function Test-Paths {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline)]
        [string[]]$Files,
        [int]$Expected
    )
    Begin {
        $Actual = 0
    }
    Process {
        $Files | ForEach-Object {
            if (Test-Path $_ -PathType Leaf) {
                $Actual++
                Write-Verbose "$_ found"
            }
            else {
                Write-Verbose "$_ not found"
            }
        }
    }
    End {
        return $Expected -eq $Actual
    }
}

function Test-TaskForceLegacy {
    [CmdletBinding()]
    param()

    return "$env:APPDATA\TS3Client\plugins\task_force_radio_win64.dll",
    "$env:APPDATA\TS3Client\plugins\task_force_radio_win32.dll" | Test-Paths -Expected 0    
}

function Test-TaskForceBeta {
    [CmdletBinding()]
    param()

    return "$env:APPDATA\TS3Client\plugins\TFAR_win64.dll",
    "$env:APPDATA\TS3Client\plugins\TFAR_win32.dll" | Test-Paths -Expected 2
}

function Test-TeamspeakStatus {
    [CmdletBinding()]
    Param()

    $Exe = if ($env:PROCESSOR_ARCHITECTURE -eq 'AMD64') { 'ts3client_win64' } else { 'ts3client_win32' }
    $Count = (Get-Process -Name $Exe -ErrorAction Ignore | Measure-Object).Count
    Write-Verbose "$Exe.exe : $Count processes running"
    return 0 -eq $Count
}

function  Test-TaskForceStatus {
    [CmdletBinding()]
    param ()
    
    return (Test-TaskForceLegacy) -and (Test-TaskForceBeta)
}

function Remove-TaskForceLegacy {
    [CmdletBinding()]
    Param()

    "$env:APPDATA\TS3Client\plugins\task_force_radio_win64.dll",
    "$env:APPDATA\TS3Client\plugins\task_force_radio_win32.dll" | ForEach-Object {
        Remove-Item $_ -ErrorAction Ignore
        Write-Verbose "$_ removed"
    }
}

function Expand-TaskForceBeta {
    [CmdletBinding()]
    Param(
        [string] $PluginSource
    )

    $PluginPath = Split-Path -Parent $PluginSource
    $PluginZip = "$PluginPath\task_force_radio.zip"
    Copy-Item $PluginSource $PluginZip
    Expand-Archive -Path $PluginZip -DestinationPath "$env:APPDATA\TS3Client" -Force
    Remove-Item "$env:APPDATA\TS3Client\package.ini" -ErrorAction Ignore
    Remove-Item $PluginZip -ErrorAction Ignore
}

function Install-TaskForceAddon {
    [CmdletBinding()]
    Param(
        [string] $PluginSource
    )

    if (-not(Test-Path $PluginSource -PathType Leaf)) {
        throw "$PluginSource not found"
    }
    if (-not (Test-TeamspeakStatus)) {
        throw 'Please close Teamspeak before install'
    }
    if (-not(Test-TaskForceLegacy)) {
        Write-Verbose 'TFAR 0.x found'
        Remove-TaskForceLegacy 
    }
    Expand-TaskForceBeta -PluginSource $PluginSource
}

function Write-Preset {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline)]
        [object[]]$Mods,
        [string]$Name
    )
    Begin {
        $PresetDate = Get-Date -Format "o"
        $File = "$env:LOCALAPPDATA\Arma 3 Launcher\Presets\$Name.preset2"
        if (Test-Path $File) { Remove-Item $File }
        Add-Content -Path $File '<?xml version="1.0" encoding="utf-8"?>'
        Add-Content -Path $File '<addons-presets>'
        Add-Content -Path $File "<last-update>$PresetDate</last-update>"
        Add-Content -Path $File '<published-ids>'
    }
    Process {
        $Mods | ForEach-Object {
            Write-Verbose $_.FullName
            Add-Content -Path $File "<id>local:$($_.FullName)</id>"            
        }
    }
    End {
        Add-Content -Path $File '</published-ids>'
        Add-Content -Path $File '<dlcs-appids />'
        Add-Content -Path $File '</addons-presets>'
    }
}
function Test-NodePath {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string]$Node
    )

    if (Test-Path $Node -ErrorAction SilentlyContinue) {
        Write-Verbose "$Node found"
        return $true
    }
    else {
        Write-Verbose "$Node not found"
        return $false
    }
}

function Test-NodePathAndPropertyValue {
    [CmdletBinding()]
    param(
        [string]$Node,
        [string]$PropertyName
    )

    if (-not (Test-NodePath $Node)) { 
        Write-Verbose "$Node not found"
        return $false; 
    }    
    $Property = Get-ItemProperty $Node -Name $PropertyName -ErrorAction Ignore
    if ($null -eq $Property) { 
        Write-Verbose "$Node.$PropertyName not found"
        return $false 
    }

    $Value = Get-ItemPropertyValue $Node -Name $PropertyName -ErrorAction Ignore
    if ($null -eq $Value) {
        Write-Verbose "$Node.$PropertyName has no value"
        return $false 
    }

    return Test-NodePath $Value
}

function Test-AppInstallation {
    [CmdletBinding()]
    param(
        [string]$Name,
        [string]$Node,
        [string]$Property,
        [switch]$IsWOW64
    )

    $RegistryPath = 'HKLM:\SOFTWARE'
    $IsWin64 = ($env:PROCESSOR_ARCHITECTURE -eq 'AMD64')
    
    if ($IsWin64 -and $IsWOW64) {
        Write-Verbose 'Looking for a WOW64 application'
        $RegistryPath = "$RegistryPath\WOW6432Node"
    }
        
    $RegistryPath = "$RegistryPath\$Node"
    Write-Verbose "Searching for $RegistryPath.$Property"
    return Test-NodePathAndPropertyValue -Node $RegistryPath -Property $Property
}
