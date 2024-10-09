#!/bin/bash
set -euo pipefail

# Set umask for file permissions
umask 027  # Files will have permissions 750

# Get the directory of the script
dir=$(dirname "$(realpath "$0")")

# Configuration file path
config_file="$dir/backup_config.conf"

# Check if config file exists
if [ -f "$config_file" ]; then
    source "$config_file"
else
    echo "Config file $config_file not found. Exiting."
    exit 1
fi

# Verify required variables are set
if [ -z "${source_dir:-}" ] || [ -z "${backup_dir:-}" ]; then
    echo "source_dir and backup_dir must be set in the config file."
    exit 1
fi

# Ensure Source and Backup Directories Exist
if [ ! -d "$source_dir" ]; then
    echo "Source directory $source_dir does not exist."
    exit 1
fi

if [ ! -d "$backup_dir" ]; then
    echo "Backup directory $backup_dir does not exist."
    exit 1
fi

# Implement a lock file to prevent concurrent execution
lock_file="$dir/backup_script.lock"

if [ -e "$lock_file" ]; then
    echo "Backup script is already running."
    exit 1
else
    touch "$lock_file"
fi

# Ensure the lock file is removed when the script exits
trap "rm -f $lock_file" EXIT

# Read the last backup path
last_backup_file="$dir/.last_backup_path"
if [ -f "$last_backup_file" ]; then
    last_backup_path=$(cat "$last_backup_file")
else
    last_backup_path="" # If the file doesn't exist, default to empty
fi

# Create exclusion file, only if it does not already exist
if [ ! -f "$exclude_file" ]; then
    touch "$exclude_file"
fi

# Determine the date
day=$(date +"%d")       # %d = Day of the month as a two-digit number.
month=$(date +"%m")     # %m = Month as a two-digit number.
month_num=$(echo "$month" | sed 's/^0*//')  # Remove leading zero
weekday_num=$(date +%u) # 1-7 (Monday to Sunday)
weekday_names=("Mon" "Tue" "Wed" "Thu" "Fri" "Sat" "Sun")
weekday=${weekday_names[$((weekday_num - 1))]}

# Function to log messages
function log_message() {
    echo "$1" >> "$log_file"
}

# Function to send alert emails
function send_alert() {
    local message="$1"
    echo "$message" | mail -s "Backup Script Alert" "$email_recipient"
}

# Function to check if today is a specific day of the month
function is_day_of_month() {
    local day_check="$1"
    [ "$day" -eq "$day_check" ]
}

# Function to check if the month is even
function is_even_month() {
    local month_num="$1"
    [ $((month_num % 2)) -eq 0 ]
}

# Function to check if the month is odd
function is_odd_month() {
    local month_num="$1"
    [ $((month_num % 2)) -ne 0 ]
}

# Function to convert human-readable sizes to kilobytes
function convert_to_kb() {
    local size="$1"
    local num unit
    num=$(echo "$size" | sed -E 's/^([0-9]+).*/\1/')
    unit=$(echo "$size" | sed -E 's/^[0-9]+(.*)/\1/' | tr '[:upper:]' '[:lower:]')
    case "$unit" in
        t|tb)
            echo $((num * 1024 * 1024 * 1024))
            ;;
        g|gb)
            echo $((num * 1024 * 1024))
            ;;
        m|mb)
            echo $((num * 1024))
            ;;
        k|kb|"")
            echo "$num"
            ;;
        *)
            echo "Invalid size unit: $unit"
            return 1
            ;;
    esac
}

# Convert required_space to kilobytes
required_space_kb=$(convert_to_kb "$required_space")
if [ $? -ne 0 ]; then
    echo "Failed to convert required_space to kilobytes."
    exit 1
fi

# Backup function
function backup() {
    local backup_subdir_name="$1"
    local start_time=$(date +%s)
    local backup_subdir="$backup_dir/$backup_subdir_name"
    
    # Create backup subdirectory if it doesn't exist
    mkdir -p "$backup_subdir"
    
    # Initialize the log file
    log_file="$backup_subdir/_last_backup_$(date "+%Y-%m-%d").txt"
    echo "-----------------------------------------------" > "$log_file"
    log_message "Starting backup: $(date "+%Y-%m-%d %H:%M:%S")"
    log_message "Backup Path: $backup_subdir"
    log_message "Source Path: $source_dir"
    log_message "Link Destination used: $last_backup_path"
    echo >> "$log_file"
    
    # Prepare rsync options
    if [ -n "$last_backup_path" ]; then
        link_dest_option="--link-dest=$last_backup_path"
    else
        link_dest_option=""
    fi
    
    # Check available disk space
    available_space=$(df -k "$backup_dir" | awk 'NR==2 {print $4}')
    if [ "$available_space" -lt "$required_space_kb" ]; then
        log_message "Not enough disk space for backup."
        send_alert "Not enough disk space for backup."
        exit 1
    fi
    
    # Perform rsync for the main source directory
    rsync -a --delete --checksum --exclude-from="$exclude_file" $link_dest_option "$source_dir/" "$backup_subdir/" >> "$log_file" 2>&1
    
    # Check if rsync was successful
    if [ $? -ne 0 ]; then
        log_message "Rsync failed for $source_dir"
        send_alert "Rsync failed for $source_dir"
        exit 1
    fi
    
    # Perform MySQL dump if enabled
    if [ "${do_mysql_dump,,}" == "true" ]; then
        if [ -z "${mysql_dump_db:-}" ]; then
            log_message "MySQL database name is not set in configuration."
            send_alert "MySQL database name is not set in configuration."
            exit 1
        fi
        
        # Perform MySQL dump
        mysqldump --single-transaction "$mysql_dump_db" > "$backup_subdir/sql_backup_${mysql_dump_db}_$(date "+%Y-%m-%d").sql"
        if [ $? -ne 0 ]; then
            log_message "MySQL dump failed for database $mysql_dump_db"
            send_alert "MySQL dump failed for database $mysql_dump_db"
            exit 1
        fi
        
        # Compress MySQL dump
        gzip "$backup_subdir/sql_backup_${mysql_dump_db}_$(date "+%Y-%m-%d").sql"
    fi
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    local backup_size=$(du -sh "$backup_subdir" | cut -f1)
    
    echo >> "$log_file"
    log_message "-----------------------------------------------"
    log_message "Backup completed: $(date "+%Y-%m-%d %H:%M:%S")"
    log_message "Duration: $duration seconds"
    log_message "Backup Size: $backup_size"
    log_message "-----------------------------------------------"
    
    # Update last backup path
    echo "$backup_subdir" > "$last_backup_file"
}

# Perform daily backup if today is not a weekly or monthly backup day
if ! is_day_of_month 1 && ! is_day_of_month 9 && ! is_day_of_month 16 && ! is_day_of_month 24; then
    backup "$weekday"
fi

# Perform weekly backups
if is_day_of_month 9; then
    backup "09"
fi

if is_day_of_month 16; then
    backup "16"
fi

if is_day_of_month 24; then
    backup "24"
fi

# Perform monthly backups
if is_day_of_month 1; then
    if is_even_month "$month_num"; then
        backup "Mg"  # Even months
    else
        backup "Mu"  # Odd months
    fi
fi

# Cleanup old backups
function cleanup_old_backups() {
    # Delete daily backups older than 7 days
    find "$backup_dir" -mindepth 1 -maxdepth 1 -type d -name "Mon" -o -name "Tue" -o -name "Wed" -o -name "Thu" -o -name "Fri" -o -name "Sat" -o -name "Sun" -mtime +7 -exec rm -rf {} \; 2>/dev/null
    
    # Delete weekly backups older than 30 days
    find "$backup_dir" -mindepth 1 -maxdepth 1 -type d -name "09" -o -name "16" -o -name "24" -mtime +30 -exec rm -rf {} \; 2>/dev/null
    
    # Optionally, delete monthly backups older than a certain number of days
    # Uncomment the following lines if needed
    # find "$backup_dir" -mindepth 1 -maxdepth 1 -type d -name "Mg" -o -name "Mu" -mtime +180 -exec rm -rf {} \; 2>/dev/null
}

cleanup_old_backups