#!/bin/bash
# Specify the path to the source and backup directory without a trailing slash '/'.
dir=$(dirname "$(realpath "$0")")
source=/mnt/fivem/losthope         		# Which directory should be backed up?
backup=/mnt/fivembackup       		# Where should the backups be stored?
excludeFile=$dir/exclude.txt # Exclusions are entered line by line in this file.
# From here you don't really need to change anything.

lastBackupFile="$dir/.last_backup_path"
if [ -f "$lastBackupFile" ]; then
  lastBackupPath=$(cat "$lastBackupFile")
else
  lastBackupPath="" # If the file doesn't exist, default to empty
fi

# Create exclusion file, only if it does not already exist:
touch $excludeFile

# Determine the date:
weekday=$(date +"%a") # %a = Day of the week as short text. Note that the content of the variable depends on the system's set language.
day=$(date +"%d")       # %d = Day of the month as a two-digit number.
month=$(date +"%m")     # %m = Month as a two-digit number.

# Define backup function:
function backup ()
{

 startTime=$(date +%s)
 backupPath="$backup/$1/"

 echo >"$backup/_last_backup.txt"
 echo "-----------------------------------------------" >> "$backup/_last_backup.txt"
 echo "Starting backup: $(date "+%Y-%m-%d %H:%M:%S")" >> "$backup/_last_backup.txt"
 echo "Backup Path: $backupPath" >> "$backup/_last_backup.txt"
 echo "Source Path: $source" >> "$backup/_last_backup.txt"
 echo "Link Destination used: $lastBackupPath" >> "$backup/_last_backup.txt"
 echo "-----------------------------------------------" >> "$backup/_last_backup.txt"
 echo -e '\n' >>"$backup/_last_backup.txt"



 if [ -n "$lastBackupPath" ]; then
  linkDestOption="--link-dest=$lastBackupPath"
 else
  linkDestOption=""
 fi

 rsync -rtpgov --delete --checksum -hh --stats --exclude-from="$excludeFile" $linkDestOption "$source/" "$backup/$1/" >>"$backup/_last_backup.txt" 2>&1
 rsync -rtpgov --delete --checksum -hh --stats --exclude-from="$excludeFile" --link-dest="/mnt/fivem/OldScripts/" "/mnt/fivem/OldScripts/" "$backup/$1/OldScripts/" 2>&1
 mysqldump --single-transaction -u fivem -pnewaera -h 49.13.172.228 fivem>"$backup/$1/sql_backup_$(date "+%Y-%m-%d").sql" 


 endTime=$(date +%s)
 duration=$((endTime - startTime))
 backupSize=$(du -sh "$backupPath" | cut -f1)

 echo -e '\n'>> "$backup/_last_backup.txt"
 echo "-----------------------------------------------" >> "$backup/_last_backup.txt"
 echo "Backup completed: $(date "+%Y-%m-%d %H:%M:%S")" >> "$backup/_last_backup.txt"
 echo "Duration: $duration seconds" >> "$backup/_last_backup.txt"
 echo "Backup Size: $backupSize" >> "$backup/_last_backup.txt"
 echo "-----------------------------------------------" >> "$backup/_last_backup.txt"

 mv $backup/_last_backup.txt $backup/$1/_last_backup_$(date "+%Y-%m-%d").txt
 echo "$backup/$1" > $lastBackupFile
 }

## Daily backup (Monday - Sunday):
# Only if the day is not the 1st, 9th, 16th or 24th, a backup is made here - otherwise a weekly or monthly backup is performed:
if [[ $day != 01 && $day != 09 && $day != 16 && $day != 24 ]]; then
 # and if weekday = ... then backup in the subfolder of the weekday:
 case "$weekday" in Mon|Tue|Wed|Thu|Fri|Sat|Sun) backup $weekday ;; esac
 # Note: For an operating system with German language settings, the weekday names must be changed as follows: 'Mo|Di|Mi|Do|Fr|Sa|So'.
fi

## Weekly backups:
# Note:
# 1st week is the month's backup.

# 2nd week (9th day):
case "$day" in 09) backup 09 ;; esac

# 3rd week (16th day):
case "$day" in 16) backup 16 ;; esac

# 4th week (24th day):
case "$day" in 24) backup 24 ;; esac

## Monthly backups:
# if even month (Mg):
case "$month" in 02|04|06|08|10|12)
 # and if 1st of the month:
 case "$day" in 01)
 backup Mg
 ;; esac
;; esac

# if odd month (Mu):
case "$month" in 01|03|05|07|09|11)
 # and if 1st of the month:
 case "$day" in 01)
 backup Mu
 ;; esac
;; esac
