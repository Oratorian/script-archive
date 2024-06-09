#!/bin/bash

# Backup directory where .google_authenticator backups are stored
BACKUP_DIR="/opt/backups"

# Usernames and their corresponding home directories
declare -A USER_HOMES=(
    [root]="/root"
    [user1]="/mnt/user1"
    # Add more mappings as needed
)

# Loop over each user/home pair
for username in "${!USER_HOMES[@]}"; do
    HOME_DIR="${USER_HOMES[$username]}"
    FILE=".google_authenticator"
    MONITORED_PATH="${HOME_DIR}/${FILE}"
    BACKUP_PATH="${BACKUP_DIR}/.google_authenticator_${username}"

    # Function to check and restore the .google_authenticator file
    check_and_restore() {
        if [ ! -f "${MONITORED_PATH}" ]; then
            cp "${BACKUP_PATH}" "${MONITORED_PATH}"
            echo ".google_authenticator restored for ${username} at $(date)" >> /var/log/google_authenticator_restore.log
            chown ${username}:${username} "${MONITORED_PATH}"
            chmod 600 "${MONITORED_PATH}"
        fi
    }

    # Initial check in case the file is already missing before the monitoring starts
    check_and_restore

    # Start monitoring in the background
    inotifywait -m -e delete_self "${MONITORED_PATH}" --format "%w%f" | while read path; do
        check_and_restore
    done &
done

# Wait indefinitely to keep the script running
wait
