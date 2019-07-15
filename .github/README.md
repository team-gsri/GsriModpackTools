# modpack-tools

## What is `modpack-tools`?

This a project maintains a series of powershell scripts used by [french Arma 3 milsim unit GSRI](https://www.gsri.team) to help with our modpack maintenance.

It helps our players and visitors to ensure their modpack installation is not corrupted and help them for their initial setup. It uses a library we developped on our own which can be found in [modpack-lib](https://github.com/team-gsri/modpack-lib)

## Rules and standards

The follwing documents provide additional information on rules and standards applying to this project :

* [MIT license](./LICENSE)
* [GSRI code of conduct](./CODE_OF_CONDUCT.md)
* [Contributing to this project](./CONTRIBUTING.md)

## How to use these scripts

This project is a tool-pack composed of multiple scripts. These scripts are expected to be downloaded along our modpack using Arma3Sync. For details on how to do that, please refere to our website https://www.gsri.team/jouer (FR).

- ### `test-modpack.ps1`

This script will check your installation for missing steps in our installation procedure ; it will not change anything and you must use other scripts or manual actions to correct failures.

- ### `install-preset.ps1`

This script will create an Arma 3 launcher preset named `GSRI` with the mods you downloaded. It will ignore Campaign mods as theses are to be used only on very specific missions. If you already have a GSRI-named preset, it will ask confirmation before trying to overwrite.

- ### `install-tfar.ps1`

This script will check your TFAR plugin and try to install it. Since we are using TFAR beta (1.x), which uses different filenames than TFAR zero (0.x), manual installation may cause mayhem in your teamspeak plugins directory ; this script will do it's best to tidy the mess and help you get everything working.

## How to get help ?

You can ask for support on [our discord server](https://discord.gg/bhMn4jd)
