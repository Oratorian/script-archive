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

## [1.2.0] - 2024-09-22
### Added
- **Finalized behavior for check intervals:** 
  - The `Confirm-IntervalWarning` function now returns the final interval, ensuring the correct assignment to `$GlobalCheckInterval`.
  - Enhanced logic for confirming check intervals below 10 minutes, asking the user to confirm or change the interval.
  - Added a timer display showing the remaining time before the next check.
  - Introduced global logging configuration (`$GlobalLogToFile` and `$GlobalDebug`) to control where log messages are written (file, console, or both).
  
### Fixed
- **Corrected check interval behavior:** 
  - The script now correctly uses the returned interval, ensuring that the user’s choice or the recommended value (10 minutes) is applied.
  
### Improved
- **Logging adjustments:** 
  - Refined the `Write-LogMessage` function to handle logging based on global settings, avoiding manual changes for each log instance.

## [1.1.1] - 2024-09-22
### Fixed
- **Resolved interval issues:**
  - Fixed a problem where the script used the initial configuration value for `$GlobalCheckInterval` even after the user set a new interval.
  - Ensured that the script correctly applies new or default intervals as specified by the user.

## [1.1.0] - 2024-09-22
### Added
- **User prompts for interval warnings:** 
  - Implemented a warning message when the check interval is set below 10 minutes, allowing the user to confirm or adjust the interval.
  - If the user chooses not to proceed, they are given the option to set a new interval or use the recommended value (10 minutes).
  
### Fixed
- **Check interval validation:** 
  - Corrected logic for handling unsafe intervals and prompted the user to make an informed decision on whether to proceed or modify the interval.

## [1.0.1] - 2024-09-22
### Added
- **Countdown display for check intervals:**
  - Added a time remaining display showing how long until the next RSS feed check.
  
### Fixed
- **RSS feed structure handling:**
  - Adjusted the script to handle the flattened RSS structure from Crunchyroll, ensuring proper matching of series titles and dubs.

## [1.0.0] - 2024-09-22
### Initial Release
- **Core functionality:**
  - Fetches and processes Crunchyroll’s RSS feed.
  - Allows configuration of user-specified series and allowed dubs for filtering.
  - BurntToast notifications for Windows tray alerts.
  - Logs script execution events to a file and/or console.
  - Filters announcements based on a configurable time range.

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
