# Changelog

## 2.1.3 - 2024-09-28

### Fixed
- **Logging**: The Logfile now shows which episode and show in particual got skipped instead of just repeated showing the Show got skipped.
-- ```
2024-09-28 10:45:27 - Series 'Quality Assurance in Another World' is not in user-specified list. Skipping.
2024-09-28 10:45:27 - Series 'Quality Assurance in Another World' is not in user-specified list. Skipping.
2024-09-28 10:45:27 - Series 'Quality Assurance in Another World' is not in user-specified list. Skipping.
2024-09-28 10:45:27 - Series 'Quality Assurance in Another World' is not in user-specified list. Skipping.
2024-09-28 10:45:27 - Series 'Quality Assurance in Another World' is not in user-specified list. Skipping.
2024-09-28 10:45:27 - Series 'Quality Assurance in Another World' is not in user-specified list. Skipping.
2024-09-28 10:45:27 - Series 'Quality Assurance in Another World' is not in user-specified list. Skipping.
```
---

## 2.1.2 - 2024-09-28

### Fixed
- **Invoke-NextCheckTimer**: Depending on Write-LogMessage, which resulted in Timer not being displayed when **GlobalDebug** was set to **false**

---

## 2.1.1 - 2024-09-28

### Added
- **JSON Configuration**: Replaced the previous associative array configuration with a `config.json` file. This allows for more flexible and structured configuration management.
  - Example format includes fields for `userMediaIDs`, `announceRange`, `GlobalLogToFile`, `GlobalDebug`, `GlobalCheckInterval`, and `announcedFile`.
- **Logging Improvements**: Enhanced logging to improve debugging and traceability of key actions, including logging exact series title matching and the retrieval of allowed dubs for each series.

### Changed
- **Revamped `IsAllowedDub` Handling**: The function now accepts an array of allowed dubs (split from the JSON configuration), removing the need for splitting comma-separated strings inside the function.
- **Series Title Matching**: Instead of normalizing series titles (trimming and lowercasing), the exact title from the RSS feed is now used to match against `userMediaIDs` without modification. This prevents issues with case sensitivity and trimming.
- **JSON Key Access**: Updated how JSON keys are accessed in PowerShell to account for differences between `PSCustomObject` and hashtables. This ensures proper key matching and value retrieval from the `userMediaIDs` configuration.

### Fixed
- **Allowed Dubs Retrieval**: Resolved an issue where allowed dubs were incorrectly retrieved as an empty string due to key mismatches in the JSON configuration. The new logic ensures correct retrieval of allowed dubs based on the exact series title key from the RSS feed.
- **Key Matching for JSON**: Fixed an issue where normalizing series titles caused mismatches with JSON keys. Now, exact key matching is used to ensure proper retrieval of values from the configuration.

---

## [2.0.1] - 2024-09-27
### Fixed
- Added the `ModuleToProcess` field to `.psd1` manifest files to correctly link `.psm1` files, resolving an issue where modules were not being loaded during import.

### Added
- Specified module dependencies in the `.psd1` manifest files using the `RequiredModules` field to ensure that required modules (e.g., `BurntToast`, `Pester`) are automatically loaded or installed when the module is imported.

---

## [2.0.0] - 2024-09-26
### Major Changes
- Refactored the script into a modular architecture by separating functions into individual PowerShell modules.
- Implemented manifest files for each module for better modularity and reusability.
- Changed versioning to Semantic Versioning (SemVer) from 4-digit versioning.

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
- Added time-based filtering to ensure episod# es within a certain time window are notified.
- Introduced BurntToast for tray notifications of new episode releases.
#