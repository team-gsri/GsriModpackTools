# modpack-tools

## What is `modpack-tools`?

This a project is a maintenance project aimed at developping and supporting our team's scripts used for modpack maintenance. They are intended to help our players and visitors to ensure their Arma 3 mod installation is not corrupted and help them for their initial setup.

## Quick reference

- **Where to get help with Arma 3**

    [the Arma 3 official support](https://support.bohemia.net/arma-3), [the Bohemia Interactive Forums](https://forums.bohemia.net/forums/forum/218-arma-3/)

- **Where to file issues with `modpack-tools`**

    [the project's Github](https://github.com/team-gsri/modpack-tools/issues)

- **Maintained by**

    [ArwynFr](https://github.com/ArwynFr)

## How to use this tools

This project is a tool-pack composed of multiple scripts :

- ### `healthcheck.ps1`

This script will check your installation for missing steps in our installation procedure ; it will not change anything and you must use other scripts to correct failures.

- ### `install-preset.ps1`

This script will create an Arma 3 launcher preset named `GSRI` with the mods you downloaded. It will ignore Campaign mods as theses are to be used only on very specific missions. If you already have a GSRI-named preset, it will ask confirmation before trying to overwrite.

- ### `install-tfar.ps1`

This script will check your TFAR plugin and try to install it. Since we are using TFAR beta (1.x), which uses different filenames than TFAR zero (0.x), manual installation may cause mayhem in your teamspeak plugins directory ; this script will do it's best to tidy the mess and help you get everything working.

## Contributing

You may contribute to the project either by:

- Submiting issues and request features on github
- Forking the github repository and make pull requests

## License

This software is licensed under the terms of the [MIT License](LICENSE).