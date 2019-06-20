try {

    $global:fail = $false

    # Verifying current architecture
    Write-Host "Vérification de l'architecture du processeur : " -NoNewline
    $Is_Arch_X64 = ($env:PROCESSOR_ARCHITECTURE -eq 'AMD64')
    if ($Is_Arch_X64) { Write-Host -ForegroundColor Green '[X64]' } else { Write-Host -ForegroundColor DarkYellow '[X86]' }    
    $Uninstall_Registry_Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall'
    $Uninstall_Registry_Path_Wow64 = 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall'


    function Test-Installation {
        param(
            [string]$DisplayName,
            [string]$Subnode = "",
            [bool]$IsWOW64 = $false
        )

        Write-Host "Vérification de l'installation de $DisplayName : " -NoNewline

        $Uninstall_Registry_Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall'
        $Uninstall_Registry_Path_Wow64 = 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
        $Registry_Path = If ($Is_WOW64) { $Uninstall_Registry_Path_Wow64 } else { $Uninstall_Registry_Path }
        $Registry_Path = "$Registry_Path\$Subnode"

        $Registry_Entry = Get-ChildItem -Recurse -Path $Registry_Path |
        Where-Object {
            $DisplayName -eq ($_ | Get-ItemProperty -Name DisplayName -ErrorAction Ignore).DisplayName
        } |
        Select-Object -First 1
        
        $Install_Location = $Registry_Entry | Get-ItemPropertyValue -Name InstallLocation
        If ($null -eq $Install_Location) {
            $global:fail = $true
            Write-Host -ForegroundColor Red "[FAIL]"
        }
        else {
            Write-Host -ForegroundColor Green "[OK]"
            Write-Host -ForegroundColor Blue " > $Install_Location"
        }
    }


    # Vérification de l'installation de Arma 3
    Test-Installation -DisplayName 'Arma 3'
    
    # Vérification de l'installation de Arma 3 Sync
    Test-Installation -DisplayName 'Arma3Sync' -IsWOW64 $Is_Arch_X64
    
    # Vérification de l'installation de Teamspeak
    Test-Installation -DisplayName 'TeamSpeak 3 Client'
  
    # Vérification si le modpack est à jour
    Write-Host 'Vérification de la version du modpack : ' -NoNewline
    $Ver_Remote = (Invoke-WebRequest -URI "https://mods.gsri.team/version.txt").Content
    $Ver_Remote_Null = ($null -eq $Ver_Remote)
    $Ver_Remote_Value = if ($Ver_Remote_Null) { "-" } else { $Ver_Remote.Trim() }
    $Ver_Local = (Get-Content .\version.txt -ErrorAction Ignore)
    $Ver_Local_Null = ($null -eq $Ver_Local)
    $Ver_Local_Value = if ($Ver_Local_Null) { "-" } else { $Ver_Local.Trim() }
    $Ver_Compare = Compare-Object $Ver_Remote_Value -DifferenceObject $Ver_Local_Value
    if ($Ver_Null_Remote -or $Ver_Null_Local -or $Ver_Compare) {
        $global:fail = $true
        Write-Host -ForegroundColor Red "[FAIL]"
    }
    else {
        Write-Host -ForegroundColor Green "[OK]"
    }
    Write-Host -ForegroundColor Blue " > Version locale : $Ver_Local_Value"
    Write-Host -ForegroundColor Blue " > Version serveur : $Ver_Remote_Value"
    
    # Vérification absence de reliquats TFAR 0.x
    Write-Host 'Vérification de l''absence du plugin TS3 TFAR 0.x : ' -NoNewline
    $TFAR_0_86 = Test-Path -PathType Leaf "$TS_Plugins_Path\task_force_radio_win32.dll"
    $TFAR_0_64 = Test-Path -PathType Leaf "$TS_Plugins_Path\task_force_radio_win64.dll"
    if ($TFAR_0_86 -or $TFAR_0_64) {
        $global:fail = $true
        Write-Host -ForegroundColor Red "[FAIL]" 
        if ($TFAR_0_86) { Write-Host -ForegroundColor Blue " > $TS_Plugins_Path\task_force_radio_win32.dll présent" }
        if ($TFAR_0_64) { Write-Host -ForegroundColor Blue " > $TS_Plugins_Path\task_force_radio_win64.dll présent" }
    }
    else {
        Write-Host -ForegroundColor Green "[OK]" 
    }

    # Vérification installation TFAR 1.x
    Write-Host 'Vérification de la présence du plugin TS3 TFAR 1.x : ' -NoNewline
    $TFAR_1_86 = Test-Path -PathType Leaf "$TS_Plugins_Path\TFAR_win32.dll"
    $TFAR_1_64 = Test-Path -PathType Leaf "$TS_Plugins_Path\TFAR_win64.dll"
    if (!($TFAR_1_86 -and $TFAR_1_64)) {
        $global:fail = $true
        Write-Host -ForegroundColor Red "[FAIL]"
        if(!$TFAR_1_86) { Write-Host -ForegroundColor Blue " > $TS_Plugins_Path\TFAR_win32.dll absent" }
        if(!$TFAR_1_64) { Write-Host -ForegroundColor Blue " > $TS_Plugins_Path\TFAR_win64.dll absent" }
    }
    else {
        Write-Host -ForegroundColor Green "[OK]" 
    }    

    if ($global:fail) {
        Write-Host -ForegroundColor Red "`n *** Votre installation n'est pas correcte *** `n"
    }
    else {
        Write-Host -ForegroundColor Green "`n *** Votre installation est validée *** `n"
    }
    Pause
}
catch {
    $global:fail = $true
    Write-Host ""
    Write-Host -ForegroundColor DarkYellow 'Une erreur est survenue :'
    Write-Host -ForegroundColor DarkYellow $_.Exception.Message
    Pause
}
