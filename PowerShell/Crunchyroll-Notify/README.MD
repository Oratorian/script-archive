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

### Versioning History:
- **1.0.0.0**: Initial script creation with basic RSS monitoring and notifications.
- **1.0.0.1**: Added logging to both console and file.
- **1.0.0.2**: Added interval warning for intervals below 10 minutes, prompting the user to continue or adjust the interval.
- **1.0.1.0**: Introduced the ability to display the time remaining before the next check.
- **1.0.1.1**: Added user prompt to adjust the check interval, offering the option to set a new value or revert to the recommended value.
- **1.0.2.0**: Refined logging function to handle logging settings through global configuration, making logging easier to manage without modifying individual calls.
- **1.0.2.1**: Fixed the `Confirm-IntervalWarning` logic to ensure correct application of user input for the check interval.
- **1.0.2.2**: Adjusted `Confirm-IntervalWarning` to return the final interval, allowing direct assignment and preventing conflicts with initial configuration values.
- **1.0.2.3**: Minor fixes related to interval handling and logging behavior consistency.
- **1.0.2.4**: Finalized all adjustments and ensured stable behavior for RSS checks, notifications, and logging.

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

