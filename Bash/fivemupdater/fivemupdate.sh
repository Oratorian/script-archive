#!/bin/bash

#---------------------------------------------------------------------------------------------
# This script © 2024 by Oration 'Mahesvara' is released unter the GPL-3.0 license
# Reproduction and modifications are allowed as long as I Oratorian@github.com is credited
# as the original Author
#---------------------------------------------------------------------------------------------

## Version 2.1.0

# Configuration variables
UPDATE_DIR="/opt/fivemupdates/"  # Directory where updates are downloaded
SESSION_NAME="fivem" # The session name used for tmux or screen
USE_TMUX=true  # Set to false to use screen instead of tmux
RELEASE="latest"  # Can be either 'recommended' or 'latest'
FIVEM_DIR="/mnt/fivem/"  # Directory where the FiveM server is installed

# Functions for update and restart
function update_server {
    # Ensure the update directory exists
    if [ ! -d "$UPDATE_DIR" ]; then
        echo "Update directory does not exist. Creating $UPDATE_DIR"
        mkdir -p "$UPDATE_DIR"
    fi

    # Ensure the FiveM directory exists
    if [ ! -d "$FIVEM_DIR" ]; then
        echo "FiveM directory does not exist. Creating $FIVEM_DIR"
        mkdir -p "$FIVEM_DIR"
    fi

    # URL of the API endpoint
    pageUrl="https://changelogs-live.fivem.net/api/changelog/versions/linux/server"

    # Fetch the JSON data from the API
    jsonData=$(curl -s "$pageUrl")

    # Select the appropriate download URL based on the RELEASE setting
    if [ "$RELEASE" = "recommended" ]; then
        downloadUrl=$(echo "$jsonData" | grep -oP '(?<="recommended_download":")[^"]+')
    else
        downloadUrl=$(echo "$jsonData" | grep -oP '(?<="latest_download":")[^"]+')
    fi

    # Extract the four-digit version number from the download URL
    versionCode=$(echo "$downloadUrl" | grep -oP '(?<=/)[0-9]{4}(?=-)')

    # Download the file with wget, naming it with the version code
    if [[ -z "$versionCode" ]] || [[ -f "${UPDATE_DIR}${versionCode}.tar.xz" ]]
    then
        echo "Nothing to do"
    else
        wget -Nq "$downloadUrl" -O "${UPDATE_DIR}${versionCode}.tar.xz"
        if [ $? -eq 0 ]; then
            echo "Downloaded version ${versionCode}."
            tar xf "${UPDATE_DIR}${versionCode}.tar.xz" -C "$FIVEM_DIR"
        else
            echo "Download failed, aborting."
        fi
    fi

    # Clean up old versions, keeping the last 5
    ls -t "${UPDATE_DIR}" | grep -E '^[0-9]+(-.*)?\.tar\.xz$' | tail -n +6 | xargs -r rm --
}

function restart_server {
    # Kill the session and restart with tmux or screen
    if [ "$USE_TMUX" = true ]; then
        echo "Killing processes using ports 40120 and 30120..."
        fuser -k 40120/tcp
        fuser -k 30120/tcp
        tmux kill-session -t "$SESSION_NAME"
        tmux new -d -s "$SESSION_NAME" $FIVEM_DIR/run.sh
    else
        echo "Killing processes using ports 40120 and 30120..."
        fuser -k 40120/tcp
        fuser -k 30120/tcp
        screen -S "$SESSION_NAME" -X quit
        screen -d -m -S "$SESSION_NAME" $FIVEM_DIR/run.sh
    fi
}

case "$1" in
    --update)
        update_server
        ;;
    --restart)
        restart_server
        ;;
    *)
        # Default behavior: perform both update and restart
        update_server
        restart_server
        ;;
esac