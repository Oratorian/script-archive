# Backup Script

This script automates the process of backing up specified directories using `rsync` and `mysqldump`, with support for daily, weekly, and monthly backups. It includes customizable options for backup directories, exclusion lists, and link-destination functionality to improve efficiency with incremental backups.

## Features

- **Daily Backups**: Automatically backs up your source directory every day, except on specific days reserved for weekly and monthly backups (1st, 9th, 16th, 24th of the month).
- **Weekly Backups**: Backs up the source directory on the 9th, 16th, and 24th day of each month.
- **Monthly Backups**: Creates a special monthly backup on the 1st day of every month, with separate directories for even and odd months.
- **Rsync Integration**: Uses `rsync` for efficient file synchronization, supporting the `--link-dest` option for incremental backups. Files are excluded based on an exclusion list.
- **MySQL Database Backup**: Dumps the MySQL database to a file in the backup directory using `mysqldump`.
- **Exclusion File**: Supports the use of an exclusion file (`exclude.txt`) where you can specify files and directories to skip during backups.
- **Customizable Paths**: Allows you to easily specify source and backup directories through variables within the script.
- **Backup Logging**: Logs backup details, including start time, duration, and size, to a text file for each backup operation.
- **Efficient Backup Rotation**: The script manages backups by organizing them into subdirectories for daily, weekly, and monthly backups, ensuring old backups are kept separate.

## Usage

1. **Configure the Script**:
The script includes several configuration variables that can be modified to suit your environment:

- `source`: point to the directory you want to back up.
- `backup`: Specify the destination directory for backups.

2. **Schedule Backups**:
   - Daily backups are scheduled for every day except the 1st, 9th, 16th, and 24th days of the month.
   - Weekly backups are performed on the 9th, 16th, and 24th days of the month.
   - Monthly backups are scheduled for the 1st day of each month, alternating between odd and even months.

3. **Run the Script**:
   You can run the script manually or set it up in a cron job for automated backups. The backup directories will be automatically created and organized based on the current date.

## Example Cron Job

To automate the script using a cron job, you can add the following line to your crontab file:

```bash
0 2 * * * /path/to/backup.sh
```