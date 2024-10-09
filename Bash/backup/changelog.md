# Changelog

## [2.2.0] - 2024.10.09

### Removed

- **OldScripts rsync Command**: The rsync command for `/mnt/fivem/OldScripts/` has been removed from the backup script, as it is no longer needed.

### Notes

- This change simplifies the backup script by eliminating an unnecessary rsync operation.
- Users should be aware that the `OldScripts` directory will no longer be backed up by this script.
- No changes are needed in the `backup_config.conf` file for this update.

---

## [2.1.0] - Previous date

### Added

- **Conditional MySQL Dump**: Introduced a new configuration option `do_mysql_dump` in `backup_config.conf`. When set to `"true"`, the script will perform a MySQL database dump during backups. When set to `"false"`, the MySQL dump step will be skipped.

### Changed

- **Backup Script**: Updated `backup.sh` to conditionally perform the MySQL dump based on the `do_mysql_dump` setting.

### Notes

- Users should update their `backup_config.conf` file to include the new `do_mysql_dump` and `mysql_dump_db` setting.
- The default behavior is to perform the MySQL dump (`do_mysql_dump="true"`).

---

## [2.0.0] - Earlier date

### Added

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
- **Support for Size Prefixes in `required_space`**: You can now specify the `required_space` in the configuration file using units like MB, GB, or TB.

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

## Versioning Note

- **Version 2.2.0**: Incremented due to the removal of the `OldScripts` rsync operation, which is a notable change affecting the script's functionality.
- **Version 2.1.0**: Introduced the `do_mysql_dump` and `mysql_dump_db` option for conditional MySQL backups.
- **Version 2.0.0**: Major overhaul with numerous enhancements for security, reliability, and maintainability.

---

**Important Notes for Version 2.2.0 Users:**

- **Action Required**: No action is required unless you need to back up the `OldScripts` directory using a different method.
- **Testing**: It's recommended to test the updated script in a controlled environment to ensure it operates as expected without the `OldScripts` rsync step.
- **Backup Coverage**: Verify that all necessary directories are still being backed up according to your requirements.

---