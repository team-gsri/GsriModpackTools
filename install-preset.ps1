[CmdletBinding()]
Param()

try {
    Install-Module GsriModpackLib -Force -MaximumVersion 2.0
    Import-Module GsriModpackLib -Force -MaximumVersion 2.0

    $Result = Show-InstallationStatus -Path $PSScriptRoot -Verbose:($PSBoundParameters['Verbose'] -eq $true)
    if (-not $Result) {
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