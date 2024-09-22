# FiveM Server Update Script

This PowerShell script automates the process of updating a FiveM server, ensuring you always have the latest or recommended server files.

## Features

- Downloads and applies updates for your FiveM server.
- Automatically installs 7-Zip if it's not present on your system.
- Configurable paths for update storage and FiveM installation.
- Option to choose between "latest" or "recommended" versions of FiveM.
- Released under GPL-3.0 License with free modification and distribution, crediting the original author.

## Prerequisites

- PowerShell 5.0 or higher
- [7-Zip](https://www.7-zip.org/) for extracting archives (automatically installed by the script if not available).

## Installation

1. Clone or download this repository.
2. Modify the configuration variables in the script as necessary:
    - `$UPDATE_DIR`: Path where updates will be stored.
    - `$FIVEM_DIR`: Path to your FiveM installation.
    - `$RUN_SCRIPT`: The executable to run (default is `FXServer.exe`).
    - `$RELEASE`: Choose "latest" or "recommended" for updates.

## Usage

1. Run the script using PowerShell:
    ```powershell
    .\fivemupdate.ps1
    ```
2. The script will check for updates and apply them if necessary.

## Configuration

You can adjust the following variables inside the script:

- `$UPDATE_DIR`: Set the directory where updates are stored.
- `$FIVEM_DIR`: Specify the installation directory of FiveM.
- `$RUN_SCRIPT`: Define the executable to be run (default is `FXServer.exe`).
- `$RELEASE`: Specify the type of update (either 'latest' or 'recommended').

## License

This script is released under the GPL-3.0 license. You are free to reproduce, modify, and distribute this script as long as the original author is credited.

---

**Author**: Oration 'Mahesvara'  
**GitHub**: [Oratorian@github.com](https://github.com/Oratorian)