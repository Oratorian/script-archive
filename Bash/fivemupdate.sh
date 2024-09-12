#!/bin/bash
# This script © 2024 by Oration 'Mahesvara' is released unter the MIT license 
# Reproduction and modifications are allowed as long as I Oratorian@github.com is credited 
# as the original Author


# Configuration variables
UPDATE_DIR="/opt/fivemupdates/"
fivem_dir="/dir/to/fivem/run.sh
SESSION_NAME="fivem" # Session name for either tmux or screen.
USE_TMUX=true  # Set to false to use screen instead of tmux

# URL of the fivem artifacts release api.
pageUrl="https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/" # Don't edit this line.

# Fetch the URL with the highest version number
highestVersionUrl=$(curl -s "$pageUrl" | \
grep -oE 'href="[^"]+[0-9]{4}[^"]+"' | \
awk -F'"' '{print $2}' | \
sort -nr | \
head -n 1)

# Construct the full URL
baseUrl="${highestVersionUrl}"
cleanUrl="${baseUrl:2}"
downUrl="$pageUrl$cleanUrl"

# Extract the version number from the URL
versionCode=$(echo "$highestVersionUrl" | grep -oE '[0-9]{4}-[a-f0-9]+' | cut -d'-' -f1)

# Download the file with wget, naming it with the version code
if [[ -z "$versionCode" ]] || [[ -f "${UPDATE_DIR}${versionCode}.tar.xz" ]]
  then
    echo "Nothing to do"
else
    wget -Nq $downUrl -O "${UPDATE_DIR}${versionCode}.tar.xz"
    if [ $? -eq 0 ]; then
        if [ "$USE_TMUX" = true ]; then
            tmux kill-session -t "$SESSION_NAME"
            tar xf "${UPDATE_DIR}${versionCode}.tar.xz" -C ${fivem_dir}
            tmux new -d -s "$SESSION_NAME" ~/fx/run.sh
        else
            screen -S "$SESSION_NAME" -X quit
            tar xf "${UPDATE_DIR}${versionCode}.tar.xz" -C ${fivem_dir}
            screen -d -m -S "$SESSION_NAME" ~/fx/run.sh
        fi
    else
        echo "Download failed, aborting."
    fi
fi

ls -t "${UPDATE_DIR}" | grep -E '^[0-9]{4}(-.*)?\.tar\.xz$' | tail -n +6 | xargs -r rm --
