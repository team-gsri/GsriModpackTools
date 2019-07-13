@{
    Author          = 'Arwyn'
    CompanyName     = 'www.gsri.team'
    Copyright       = '(c) 2019 - GSRI - MIT license'

    GUID            = '3cf3c6bb-bc05-45e6-a663-2b77b6ed18b1'
    Description     = 'This module contains functions used by GSRI team relative to modpack installation'
    ModuleVersion   = '1.0'

    RootModule      = 'GSRI.psm1'    
    FunctionsToExport = @(
        'Install-TaskForceAddon',
        'Install-Preset',
        'Write-InstallationStatus'
    )
}