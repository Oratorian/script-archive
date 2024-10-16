# Changelog

All notable changes to this project will be documented in this file.

## 2.1.1 - 2024-10-015

### Added
- none

### Changed
- none

### Fixed
- Retrieval of Version number from downloadUrl

---
## 2.1.0 - 2024-10-02

### Added
- `-restart` parameter to allow restarting the server without updating.
- `-update` parameter to allow updating without restarting the server.
- Automatic killing of processes on ports `40120` and `30120` after quitting `tmux` or `screen`.

### Changed
- Refactored script to use a `case` statement for cleaner handling of parameters.

### Fixed
- None

---

## 2.0.0 - 2024-09-28

### Added
- Modularization: `update_server` and `restart_server` functions to separate update and restart logic.
- Support for `tmux` or `screen` session handling based on user preference.
- Automatic download and installation of the latest or recommended FiveM server version using the official API.
- Logic to automatically keep only the 5 most recent server update files, deleting older versions.

### Changed
- **Version Check Mechanism**: Changed the version check from scraping the web page for the highest version URL to fetching version data from the FiveM changelog API. This provides more reliable and structured version retrieval.
- Improved logging and handling of server restarts for better control using the `USE_TMUX` variable.

### Fixed
- None

---

## 1.1.0 - 2024-09-14

### Added
- Directory creation logic for both the update directory (`UPDATE_DIR`) and FiveM server directory (`fivem_dir`) if they do not already exist.
- Automatic fetching of the highest available version of the FiveM server artifacts from the official FiveM API.
- Download mechanism using `wget` to retrieve and store the latest server files, using the version code as part of the filename.

### Changed
- None

### Fixed
- None

---

## 1.0.0 - 2024-09-01

### Added
- Initial release of the script for automating FiveM server updates.
- Downloads the latest available version of FiveM server artifacts from the official API.
- Restarts the FiveM server using either `tmux` or `screen`, based on user configuration.
- Cleans up old versions of the server, retaining only the last 5 updates.
- Basic session management using `SESSION_NAME` for `tmux` or `screen` sessions.

### Changed
- None

### Fixed
- None

---