# Crunchyroll RSS Feed Notifier

This PowerShell script monitors a Crunchyroll RSS feed for new anime releases and sends Windows tray notifications using BurntToast. The script allows users to specify series titles and dubs to monitor and includes configurable intervals for checking the RSS feed. It also provides warnings for unsafe intervals and allows users to adjust accordingly to avoid IP bans. The script offers flexible logging options and displays the time remaining before the next check.

## Key Features:
- **Customizable series and allowed dubs:** Specify which series and dubs to monitor.
- **Configurable check interval:** Set the check interval with warnings if set below 10 minutes to avoid potential IP bans.
- **Time remaining display:** Shows the time remaining before the next RSS feed check.
- **Windows tray notifications:** Notifications via BurntToast with clickable links to Crunchyroll.
- **Flexible logging:** Log messages to the console, file, or both with global configuration options.
- **Automatic BurntToast installation:** Ensures the BurntToast module is installed and up-to-date.

## Version: 1.0.2.4

# Changelog

## [1.0.2.4] - 2024-09-22
### Added
- Finalized logging and interval adjustment behavior.
- Implemented stable behavior for RSS feed checks and notifications.
- Polished the script flow and ensured consistency across configurations and user prompts.

## [1.0.2.3] - 2024-09-22
### Fixed
- Adjusted the `Confirm-IntervalWarning` logic to handle interval reassignment correctly after user input.
- Resolved minor issues related to logging inconsistencies and user input for the interval.
- Ensured correct behavior for user-defined intervals or defaults when adjusting intervals.

## [1.0.2.2] - 2024-09-22
### Improved
- Modified `Confirm-IntervalWarning` function to return the final interval, allowing the direct assignment of the check interval.
- Prevented conflicts with initial configuration values by directly returning the final interval and assigning it to `$GlobalCheckInterval`.
- Cleaned up user prompt logic to make the flow more intuitive.

## [1.0.2.1] - 2024-09-22
### Fixed
- Resolved the issue where the script used the initial configuration value for `$GlobalCheckInterval` even after setting a new value.
- Added logic to handle interval assignment dynamically based on user input, ensuring correct use of new or default intervals.

## [1.0.2.0] - 2024-09-22
### Added
- Enhanced logging flexibility by refining the `Write-LogMessage` function to check global logging configurations.
- Global configuration variables (`$GlobalLogToFile` and `$GlobalDebug`) control logging behavior without needing to modify individual `Write-LogMessage` calls.
- Added functionality to allow logging to console, file, or both based on global settings.
  
### Fixed
- Corrected logic in `IsAllowedDub` and `NotifyViaTray` to ensure correct matching and notification behavior.

## [1.0.1.3] - 2024-09-22
### Added
- Implemented a time-remaining display, showing the user the countdown before the next RSS feed check.
- Added a countdown display, ensuring clarity of time left between RSS checks.

## [1.0.1.2] - 2024-09-22
### Fixed
- Resolved an issue where the script would erroneously apply the check interval from the initial configuration instead of the user-provided value.
- Corrected the prompt behavior to offer users the option to set a new interval when the selected one is below the recommended threshold.

## [1.0.1.1] - 2024-09-22
### Added
- Introduced a user prompt to ask whether they want to proceed with a risky interval when set below 10 minutes.
- Provided users with the ability to set a new check interval or revert to the recommended value (10 minutes) in case of an unsafe interval.
  
### Fixed
- Corrected the check interval warning behavior to properly handle intervals under 10 minutes and allow users to proceed or adjust.

## [1.0.1.0] - 2024-09-22
### Added
- Added a user-friendly prompt to warn users when the check interval is set below 10 minutes, due to the risk of an IP ban.
- The script now asks if users want to continue with the current interval or switch to a safer, recommended value (10 minutes).

## [1.0.0.2] - 2024-09-22
### Added
- Introduced interval-based logic, allowing users to configure the script to check the RSS feed at custom intervals (in minutes).
- Added the ability to convert the user-defined interval (in minutes) to seconds for accurate `Start-Sleep` functionality.

## [1.0.0.1] - 2024-09-22
### Fixed
- Improved the handling of flattened RSS structures by adjusting how the script processes the series title and episode details.
- Refined the logic to ensure the script properly matches user-specified series and dub combinations, considering the flattened XML structure.

## [1.0.0.0] - 2024-09-22
### Initial Release
- Basic functionality for fetching and processing Crunchyroll's RSS feed.
- Configurable list of user-specified series and allowed dubs for monitoring.
- Implemented BurntToast notifications for Windows tray alerts.
- Introduced logging functionality for tracking script execution and events.
- Initial handling of time-range filtering for announcements.

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