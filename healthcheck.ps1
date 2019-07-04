[CmdletBinding()]
Param()

. .\gsri.ps1

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