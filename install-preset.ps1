[CmdletBinding()]
Param()

try {
    if (!(Get-Module GsriModpackLib -ListAvailable)) { Install-Module GsriModpackLib -Scope CurrentUser }
    Import-Module GsriModpackLib -Force
    
    if (-not (Write-InstallationStatus -Path $PSScriptRoot -Verbose:($PSBoundParameters['Verbose'] -eq $true))) {
        throw 'Please fix your installation first'
    }
    Install-Preset -Path . -Name 'GSRI' -Verbose:($PSBoundParameters['Verbose'] -eq $true)
}
catch {
    $Message = $_.Exception.Message
    Write-Host -ForegroundColor Red "`n *** $Message ***`n"
}
finally {
    Pause
}