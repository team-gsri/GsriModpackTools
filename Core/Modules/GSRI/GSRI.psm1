#Requires -Module TFAR
#Requires -Module AppStatus
#Requires -Module Arma

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

Export-ModuleMember -Function Install-Preset
Export-ModuleMember -Function Write-InstallationStatus 