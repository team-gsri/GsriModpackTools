try {

    $global:fail = $false

    # Verifying current architecture
    Write-Host "Vérification de l'architecture du processeur : " -NoNewline
    $Is_Arch_X64 = ($env:PROCESSOR_ARCHITECTURE -eq 'AMD64')
    if ($Is_Arch_X64) { Write-Host -ForegroundColor Green '[X64]' } else { Write-Host -ForegroundColor Yellow '[X86]' }    
    $Uninstall_Registry_Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall'
    $Uninstall_Registry_Path_Wow64 = 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall'


    function Test-Installation {
        param(
            [string]$Name,
            [string]$Node,
            [bool]$IsWOW64 = $false
        )

        Write-Host "Vérification de l'installation de $Name : " -NoNewline

        $Uninstall_Registry_Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall'
        $Uninstall_Registry_Path_Wow64 = 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
        $Uninstall_Path = If ($IsWOW64) { $Uninstall_Registry_Path_Wow64 } else { $Uninstall_Registry_Path }
        $Registry_Path = "$Uninstall_Path\$Node"
        $Install_Location = Get-ItemPropertyValue -Path $Registry_Path -Name InstallLocation
        If ($null -eq $Install_Location) {
            $global:fail = $true
            Write-Host -ForegroundColor Red "[FAIL]"
        }
        else {
            Write-Host -ForegroundColor Green "[OK]"
        }
    }


    # Vérification de l'installation de Arma 3
    Test-Installation -Name 'Arma 3' -Node 'Steam App 107410'
    
    # Vérification de l'installation de Arma 3 Sync
    Test-Installation -Name 'Arma3Sync' -Node '{F097E7D7-D093-4394-9EED-43AFCCD12B7A}_is1' -IsWOW64 $Is_Arch_X64 
    
    # Vérification de l'installation de Teamspeak
    Test-Installation -Name 'TeamSpeak 3 Client' -Node 'TeamSpeak 3 Client'
  
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
    $TFAR_Zero_File = if ($Is_Arch_X64) { "$TS_Plugins_Path\task_force_radio_win64.dll" } else { "$TS_Plugins_Path\task_force_radio_win32.dll" }
    $TFAR_Zero = Test-Path -PathType Leaf $TFAR_Zero_File
    if ($TFAR_Zero) {
        $global:fail = $true
        Write-Host -ForegroundColor Red "[FAIL]" 
        Write-Host -ForegroundColor Blue " > $TFAR_Zero_File présent"
    }
    else {
        Write-Host -ForegroundColor Green "[OK]" 
    }

    # Vérification installation TFAR 1.x
    Write-Host 'Vérification de la présence du plugin TS3 TFAR 1.x : ' -NoNewline
    $TFAR_Beta_File = if ($Is_Arch_X64) { "$TS_Plugins_Path\TFAR_win64.dll" } else { "$TS_Plugins_Path\TFAR_win32.dll" }
    $TFAR_Beta = Test-Path -PathType Leaf $TFAR_Beta_File
    if (!$TFAR_Beta) {
        $global:fail = $true
        Write-Host -ForegroundColor Red "[FAIL]"
        Write-Host -ForegroundColor Blue " > $TFAR_Beta_File absent"
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
    Write-Host -ForegroundColor Yellow 'Une erreur est survenue :'
    Write-Host -ForegroundColor Yellow $_.Exception.Message
    Pause
}
