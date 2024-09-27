# Crunchyroll RSS Feed Notifier

This PowerShell script monitors a Crunchyroll RSS feed for new anime releases and sends Windows tray notifications using BurntToast. The script allows users to specify series titles and dubs to monitor and includes configurable intervals for checking the RSS feed. It also provides warnings for unsafe intervals and allows users to adjust accordingly to avoid IP bans. The script offers flexible logging options and displays the time remaining before the next check.

## Key Features:
- **Customizable series and allowed dubs:** Specify which series and dubs to monitor.
- **Configurable check interval:** Set the check interval with warnings if set below 10 minutes to avoid potential IP bans.
- **Time remaining display:** Shows the time remaining before the next RSS feed check.
- **Windows tray notifications:** Notifications via BurntToast with clickable links to Crunchyroll.
- **Flexible logging:** Log messages to the console, file, or both with global configuration options.
- **Automatic BurntToast installation:** Ensures the BurntToast module is installed and up-to-date.

# Changelog

## [2.0.1] - 2024-09-27
### Fixed
- Added the `ModuleToProcess` field to `.psd1` manifest files to correctly link `.psm1` files, resolving an issue where modules were not being loaded during import.

### Added
- Specified module dependencies in the `.psd1` manifest files using the `RequiredModules` field to ensure that required modules (e.g., `BurntToast`, `Pester`) are automatically loaded or installed when the module is imported.

---

## [2.0.0] - 2024-09-26

### Added
- Refactored the script into a modular architecture, separating functions into individual PowerShell modules.
- Implemented `.psd1` manifest files for each module to improve modularity, versioning, and reusability.
- Integrated Semantic Versioning (SemVer) for the project, moving from the previous 4-digit versioning system to standardize the release process.

### Changed
- Functions and logic are now organized into separate PowerShell modules, making it easier to maintain, extend, and import individual components.
- Updated logging, dub filtering, and notification systems to follow the new modular structure.
- The main script now imports relevant modules using the manifest files and manages global configurations more efficiently.
  
---
## [1.2.0] - 2024-09-26

### Added
- Added `$checkinterval` variable for controlling the interval between RSS feed checks, defaulting to 10 minutes, with configurable options.
- Added `Confirm-IntervalWarning` function to alert users when the check interval is set to less than 10 minutes, with an option to proceed or set a new interval.
- Introduced user-configurable logging options (`$GlobalLogToFile`, `$GlobalDebug`) allowing logging to console, file, or both, controlled via config without editing `Write-LogMessage` calls.

### Changed
- Refined `Write-LogMessage` to support logging configuration, reducing the need for manual changes when switching between logging modes.
- Reworked the check interval logic so `Confirm-IntervalWarning` returns the final interval value, which is used for future checks, preventing reliance on initial config values.
- Integrated user confirmation for check intervals less than 10 minutes and added handling for setting a new interval if declined.

### Fixed
- Corrected a bug where setting an interval below 10 minutes would still use the original value from the config due to improper value reassignment logic.
- Fixed an issue where incorrect log messages were displayed when setting new intervals that did not meet the minimum threshold.
- Adjusted logic for checking `seriesTitle` and dub permissions to ensure the proper handling of allowed dubs and titles from `$userMediaIDs`.

---

## [1.1.1] - 2024-09-25

### Changed
- Adjusted the logging mechanism to include color-coded messages for warnings, errors, and normal logs, enhancing visual debugging.
- Updated the structure of RSS feed handling due to the flattened XML returned by `Invoke-RestMethod`, eliminating reliance on nested item structures.
- Modified the notification system to use BurntToast with clickable buttons (`New-BTButton`) to open the episode URL when clicked.

### Fixed
- Resolved an issue where all anime titles were being announced instead of filtering by `$userMediaIDs`.
- Corrected the RSS feed parsing logic to ensure items are processed from the flattened XML structure and not dependent on nested `channel.item`.
- Addressed a minor logging issue where incorrect messages were being shown when setting a new check interval below the allowed range.

---

## [1.1.0] - 2024-09-24

### Added
- Introduced support for clickable notifications using BurntToast `New-BTButton` to launch the episode link directly from the tray notification.
- Added `$userMediaIDs` to filter specific series based on user preferences, allowing users to track only their chosen anime series.
- Implemented a time range check using `$announceRange`, limiting notifications to episodes within a certain release window (in minutes).

### Changed
- Replaced hardcoded time ranges with the `$announceRange` variable, giving users control over the time window for which episodes are announced.
- Added color-coded log messages throughout the script to improve readability and debug output.

### Fixed
- Fixed an issue where tray notifications did not send clickable buttons for watching the episode link directly from the notification.
- Corrected the dub filtering logic to ensure only allowed dubs are notified.
- Resolved a bug with `seriesTitle` and `episodeTitle` parsing, ensuring titles are correctly processed and logged.

---

## [1.0.0] - 2024-09-22

### Added
- Initial release of the script with basic RSS feed parsing functionality using `Invoke-RestMethod` to fetch Crunchyroll updates.
- Implemented series title and dub filtering based on user input via `$userMediaIDs`.
- Added time-based filtering to ensure episodes within a certain time window are notified.
- Introduced BurntToast for tray notifications of new episode releases.

## Usage Instructions:
1. Clone this repository or download the script file.
2. Ensure that the required PowerShell module (BurntToast) is installed. The script will automatically install this if it's missing.
3. Modify the `$userMediaIDs` in the configuration section to specify which series you want to monitor.
4. Adjust the `$announceRange` and `$checkInterval` variables as needed.
5. Run the script, and it will display notifications for new episodes based on your preferences.
6. The script logs messages to the console, file, or both depending on the configuration.

### Configuration Options:
- **$userMediaIDs**: An associative array where you can list series titles and allowed dubs.
- **$announceRange**: Controls the time range (in minutes) for filtering episodes.
- **$GlobalLogToFile**: Enables or disables logging to a file.
- **$GlobalDebug**: Logs messages to both file and console when set to `true`.
- **$checkInterval**: Sets the interval for RSS feed checks in minutes.


## License

This script is released under the GPL-3.0 license. You are free to reproduce, modify, and distribute this script as long as the original author is credited.

---


**Author**: Oration 'Mahesvara'  
**GitHub**: [Oratorian@github.com](https://github.com/Oratorian)
