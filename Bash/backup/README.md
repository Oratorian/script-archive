# Backup Script

This script automates the process of backing up specified directories and MySQL databases using `rsync` and `mysqldump`, with support for daily, weekly, and monthly backups. It includes customizable options for backup directories, exclusion lists, disk space checks, and email notifications for failures.

**Version:** 2.0.0

## Table of Contents

- [Features](#features)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Configuration](#configuration)
  - [Configuration Options](#configuration-options)
  - [Example Configuration](#example-configuration)
- [Usage](#usage)
- [Scheduling Backups](#scheduling-backups)
- [Example Cron Job](#example-cron-job)
- [Logging and Notifications](#logging-and-notifications)
- [Backup Retention Policies](#backup-retention-policies)
- [Security Considerations](#security-considerations)
- [Error Handling](#error-handling)
- [Concurrency Control](#concurrency-control)
- [Customization](#customization)
- [Troubleshooting](#troubleshooting)
- [Version History](#version-history)
- [License](#license)
- [Contributions](#contributions)

## Features

- **Flexible Backup Scheduling**: Automatically performs daily, weekly, and monthly backups based on the current date.
- **Rsync Integration**: Utilizes `rsync` for efficient file synchronization, supporting incremental backups with the `--link-dest` option.
- **Secure MySQL Database Backup**: Dumps the MySQL database securely using credentials stored in a protected `~/.my.cnf` file.
- **Exclusion File Support**: Allows specifying files and directories to exclude from backups via an `exclude.txt` file.
- **Configuration File**: Centralizes all configurable parameters in an external `backup_config.conf` file for easy management.
- **Enhanced Security**: Avoids hard-coded passwords and secures sensitive data.
- **Logging and Email Notifications**: Logs detailed backup information and sends email alerts on failures.
- **Disk Space Monitoring**: Checks available disk space before starting the backup to ensure sufficient space.
- **Robust Error Handling**: Implements strict error checking and reporting mechanisms.
- **Backup Retention Policies**: Automatically cleans up old backups based on customizable retention periods.
- **Concurrency Control**: Prevents multiple instances from running simultaneously using a lock file.
- **Compression**: Compresses MySQL dump files to save disk space.

## Prerequisites

- **Operating System**: Unix-like environment with Bash shell.
- **Rsync**: Ensure `rsync` is installed (`sudo apt-get install rsync` on Debian/Ubuntu).
- **MySQL Client Utilities**: For `mysqldump` (`sudo apt-get install mysql-client`).
- **Mail Transfer Agent (MTA)**: For email notifications (e.g., `sendmail`, `postfix`).
- **Permissions**: Ability to set file permissions and execute scripts.

## Installation

1. Download backup.sh

2. Set Script Permissions:

```chmod +x backup.sh```

3. Create Configuration File:

Download configuration file

4. Edit the Configuration File:

Open backup_config.conf in your preferred text editor and configure the variables as needed.

5. Secure MySQL Credentials:

Create a MySQL options file with restricted permissions:

```cat <<EOF > ~/.my.cnf
[client]
user=your_mysql_user
password=your_mysql_password
host=your_mysql_host
EOF

chmod 600 ~/.my.cnf
```

6. Create Exclude File (Optional):

If you have files or directories to exclude, create an exclude.txt file:

```touch exclude.txt```

Add paths to exclude, one per line.



## Configuration

# Configuration Options

All configurations are managed via the backup_config.conf file.

 - source_dir: Absolute path to the directory you want to back up.

 - backup_dir: Absolute path where backups will be stored.

 - exclude_file: Path to the exclude file.

 - required_space: Minimum required disk space for the backup (supports units: KB, MB, GB, TB).

-email_recipient: Email address for failure notifications.


## Example Configuration

# backup_config.conf
```
# Directory to be backed up
source_dir="/mnt/fivem/losthope"

# Directory where backups will be stored
backup_dir="/mnt/fivembackup"

# Exclude file path
exclude_file="$dir/exclude.txt"

# Required disk space (specify with units: KB, MB, GB, TB)
required_space="10GB"

# Email address for notifications
email_recipient="admin@example.com"

# Whether to perform MySQL dump ("true" or "false")
do_mysql_dump="true"

# MySQL database to dump
mysql_dump_db="database-to-dump"
```

## Usage

1. Ensure Configuration:

 - Verify that backup_config.conf is properly configured.

 - Ensure MySQL credentials are stored securely in ~/.my.cnf.

 - Confirm that the exclude.txt file exists if specified.



2. Run the Script Manually:
```./backup.sh```

3. Automate with Cron:

Schedule the script to run automatically (see Example Cron Job).


## Scheduling Backups

The script's internal logic determines the backup schedule:

- **Daily Backups**: Every day except on the 1st, 9th, 16th, and 24th.

- **Weekly Backups**: On the 9th, 16th, and 24th of each month.

- **Monthly Backups**: On the 1st day of the month; stores in Mg (even months) or Mu (odd months).


# Example Cron Job

To run the backup script daily at 2:00 AM, add the following line to your crontab:

```0 2 * * * /path/to/backup.sh```

Edit your crontab with:

```crontab -e```

## Logging and Notifications

- **Log Files**: Located in each backup subdirectory with the format _last_backup_YYYY-MM-DD.txt.

- **Email Notifications**: Sent to email_recipient if an error occurs during the backup process.


## Backup Retention Policies

The script automatically cleans up old backups:

- **Daily Backups**: Deletes backups older than 7 days.

- **Weekly Backups**: Deletes backups older than 30 days.

- **Monthly Backups**: Retention policy can be adjusted by editing the cleanup_old_backups function in backup.sh.


## Security Considerations

- **MySQL Credentials**: Store in ~/.my.cnf with permissions set to 600 to prevent unauthorized access.

- **Script and Config Permissions**: Restrict access to the script and configuration files (chmod 700 if necessary).

- **Sensitive Data**: Avoid logging sensitive information.


## Error Handling

- **Strict Error Checking**: The script exits immediately on any error (set -euo pipefail).

- **Exit Status Checks**: Verifies the success of critical commands like rsync and mysqldump.

- **Alerts**: Sends email notifications on failure.


## Concurrency Control

**Lock File**: Located at backup_script.lock in the script directory to prevent concurrent executions.

**Cleanup**: Ensures the lock file is removed upon script exit, even if interrupted.


## Customization

- **Adjust Retention Policies**: Modify the cleanup_old_backups function in backup.sh.

- **Disk Space Requirements**: Update required_space in backup_config.conf with your desired threshold.

- **Exclude Paths**: Add or remove entries in exclude.txt.


## Troubleshooting

- **Insufficient Disk Space**: Ensure backup_dir has enough free space as specified in required_space.

- **Email Notifications Not Working**: Confirm that an MTA is installed and properly configured.

- **Permission Denied Errors**: Check file and directory permissions for the script, configuration files, and backup directories.

- **MySQL Dump Fails**: Verify MySQL credentials and network connectivity to the MySQL server.


## Version History

See changelog.md for detailed version history and changes.

License

This project is licensed under the MIT License - see the LICENSE file for details.

Contributions

Contributions are welcome! Please open an issue or submit a pull request on GitHub.



