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

Export-ModuleMember -Function Test-AppInstallation