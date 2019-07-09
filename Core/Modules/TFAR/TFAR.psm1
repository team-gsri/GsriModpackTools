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

Export-ModuleMember -Function Test-TaskForceStatus
Export-ModuleMember -Function Install-TaskForceAddon