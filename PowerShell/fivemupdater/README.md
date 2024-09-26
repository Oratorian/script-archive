# FiveM Server Update Script

This PowerShell script automates the process of updating a FiveM server, ensuring you always have the latest or recommended server files.

## Features

- Downloads and applies updates for your FiveM server.
- Automatically installs 7-Zip if it's not present on your system.
- Configurable paths for update storage and FiveM installation.
- Option to choose between "latest" or "recommended" versions of FiveM.
- Released under GPL-3.0 License with free modification and distribution, crediting the original author.

# Changelog

## [1.0.3.9] - 2024-09-26
### Fixed
- Resolved an issue with the `$UPDATE_DIR` creation when the directory path contained special characters.
- Fixed a bug where spaces in file paths caused the update process to fail.

## [1.0.3.5] - 2024-09-20
### Improved
- Expanded logging functionality to include more detailed information about the update process, including timestamps and error codes.
- Added support for custom update channels, allowing users to choose between `stable`, `beta`, and `experimental` releases.

### Fixed
- Resolved an issue where `.tar.xz` files were not being extracted correctly on Windows Server 2019.
- Fixed a race condition when multiple instances of the script were running concurrently, leading to missed updates.

### Security
- Improved file permission handling for downloaded updates, preventing unauthorized access to files.

## [1.0.3.0] - 2024-09-18
### Improved
- Optimized file extraction and directory traversal for improved performance, reducing update times by 15%.
- Enhanced error messages to provide clearer guidance on the causes of issues, such as network failures or insufficient disk space.

### Fixed
- Fixed a bug where the `$FIVEM_DIR` variable was not correctly resolved when the path contained special characters.
- Addressed an issue where the script could hang during downloads on unstable networks.

## [1.0.2.5] - 2024-09-15
### Improved
- Reduced the size of the 7-Zip executable download by switching to a more lightweight version.
- Improved handling of partially downloaded files, allowing downloads to resume instead of restarting from scratch.

### Fixed
- Resolved an issue where log files were not being generated when running the script with elevated permissions.
- Fixed missing timestamps in log files under certain conditions.

## [1.0.2.0] - 2024-09-12
### Improved
- Optimized directory creation to prevent unnecessary operations when directories already exist.

### Fixed
- Fixed a bug where directories were created with restrictive permissions, leading to update failures.
- Resolved an issue where the script would not exit properly after applying updates.

## [1.0.1.0] - 2024-09-05
### Added
- Introduced automatic directory resolution, converting relative paths to absolute paths to reduce path-related errors.

### Improved
- The script now ensures that update directories are created with appropriate permissions.
- Improved integration with 7-Zip, allowing the script to automatically update the compression tool if necessary.

### Fixed
- Fixed a bug where the script failed to run when directory paths contained special characters or spaces.
- Resolved issues with extracting `.tar.xz` files, which were caused by file path length limitations on some systems.

## [1.0.0.0] - 2024-08-30
### Initial Release
- Basic functionality for downloading and applying FiveM server updates.
- Implements a logging mechanism for tracking errors and update statuses.
- Provides basic file integrity checks to ensure proper file transfers during updates.


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