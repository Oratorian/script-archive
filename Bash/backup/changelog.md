# Changelog

## [2.0.0] - 2024.10.09

### Added

- **Support for Size Prefixes in `required_space`**: You can now specify the `required_space` in the configuration file using units like MB, GB, or TB. The script includes a function to parse and convert this value into kilobytes for accurate disk space checking.
- **Security Enhancements**: Removed hard-coded passwords by utilizing `~/.my.cnf` for MySQL credentials.
- **Error Handling**: Implemented checks for exit statuses of `rsync` and `mysqldump` commands, exiting and sending alerts on failure.
- **Locale Independence**: Adjusted date formats to be locale-independent by using numeric representations.
- **Named Parameters**: Updated functions to use named parameters and consistent variable names for clarity.
- **Variable Quoting**: Quoted all variables to prevent word splitting and globbing issues.
- **Logging Function**: Created a `log_message` function to centralize logging.
- **Disk Space Monitoring**: Added a check for available disk space before starting the backup process.
- **Concurrency Control**: Implemented a lock file mechanism to prevent simultaneous script executions.
- **Portability Enhancements**: Used `$(...)` for command substitution and avoided backticks for better readability and nesting.
- **Backup Retention Policies**: Added logic to clean up old backups based on their age.
- **Modularization**: Broke down repetitive tasks into functions for better maintainability.
- **Verbose Comments**: Added comments throughout the script to explain each section.
- **File Permission Management**: Set `umask` to ensure correct permissions on backup files.
- **Error Reporting**: Implemented a `send_alert` function to notify via email in case of failures.
- **Strict Error Checking**: Enabled `set -euo pipefail` for robust error handling.
- **Configuration File**: Moved configurations to an external `backup_config.conf` file for easier management.
- **Directory Validation**: Added checks to ensure source and backup directories exist before proceeding.
- **Exclude File Handling**: Ensured the exclude file is created if it doesn't exist.
- **Compression**: Compressed MySQL dumps using `gzip` to save disk space.

### Changed

- **Scheduling Logic**: Simplified scheduling by using numeric date checks and functions.
- **Backup Function**: Modified to accept a named parameter, improving readability.
- **Date Handling**: Adjusted date variables to remove dependencies on system locale.
- **Script Organization**: Refactored code for better structure and readability.
- **Disk Space Check**: Updated to compare `available_space` with `required_space_kb` in kilobytes.

### Removed

- **Hard-Coded Passwords**: Eliminated hard-coded MySQL passwords from the script.
- **Redundant Code**: Removed unnecessary checks and simplified conditions.

---

**Note**: This release marks a significant overhaul of the backup script, introducing numerous enhancements for security, reliability, and maintainability. Users should:

- Update their configurations by creating or modifying the `backup_config.conf` file.
- Ensure that the `required_space` is specified with the desired units (e.g., `10GB`, `500MB`).
- Create the MySQL credentials file `~/.my.cnf` with appropriate permissions.
- Verify the existence of the `exclude.txt` file or adjust its path in the configuration.
- Adjust the `email_recipient` setting in the configuration file according to their environment.
- Install and configure an MTA (Mail Transfer Agent) like `sendmail` or `postfix` if email notifications are desired.
- Thoroughly test the updated script in a controlled environment before deploying it to production to ensure it operates as expected.

---

**Versioning Note**: Incremented the version to **2.0.0** due to the extensive changes and improvements, which constitute a major update from the initial release.