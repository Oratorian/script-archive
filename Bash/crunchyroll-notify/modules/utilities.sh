#!/bin/bash

clean_description() {
    echo "$1" | sed -E 's/<img[^>]*>//g; s/<br \/>//g; s/&#13;//g' | tr -d '
'
}

decode_html_entities() {
    echo "$1" | xmlstarlet unescape
}

add_title_to_announced() {
    local title="$1"
    echo "$title" >>"$announced_file"
    ANNOUNCED_TITLES["$title"]=1
}

check_announced_file() {
    if [ -z "$announced_file" ]; then
        echo "Error: No file path returned for 'announced_file' in config."
        exit 1
    fi

    if [ ! -f "$announced_file" ]; then
        touch "$announced_file"
        echo "Created announced file at $announced_file."
    else
        echo "Announced file already exists at $announced_file."
    fi
}

is_within_time_range() {
    local pub_date="$1"
    local range_in_minutes="$2"

    pub_date_seconds=$(date --date="$pub_date" +%s)

    current_time_seconds=$(date -u +%s)

    time_difference=$((current_time_seconds - pub_date_seconds))

    range_in_seconds=$((range_in_minutes * 60))

    if ((time_difference <= range_in_seconds && time_difference >= -range_in_seconds)); then
        return 0
    else
        return 1
    fi
}

is_title_announced() {
    local keyword="$1"
    for announced_title in "${!ANNOUNCED_TITLES[@]}"; do
        if [[ "$announced_title" == *"$keyword"* ]]; then
            return 0
        fi
    done
    return 1
}

is_allowed_dub() {
    local title="$1"
    local allowed_dubs="$2"
    local lower_title=$(echo "$title" | tr '[:upper:]' '[:lower:]')

    # Strip dub information and episode information from the title
    series_name=$(echo "$lower_title" | sed 's/(.*dub)//g' | sed 's/ - episode.*//g' | sed 's/ *$//')

    # If no dub is specified in the title, it's considered Japanese (default language)
    if ! [[ "$lower_title" =~ \(.*[Dd]ub\) ]]; then
        return 0 # Allow it (Japanese)
    fi

    # If allowed dubs is empty, reject if dub is present
    if [[ -z "$allowed_dubs" ]]; then
        return 1 # No allowed dubs, reject it if dub is present
    fi

    # Loop through each allowed dub in the list
    IFS=',' read -r -a allowed_dubs_array <<<"$allowed_dubs"
    for dub in "${allowed_dubs_array[@]}"; do
        # Check if the current title contains the allowed dub (match just the language part)
        if [[ "$lower_title" == *"$(echo "$dub" | tr '[:upper:]' '[:lower:]')"*"dub"* ]]; then
            return 0 # True, allowed dub found (e.g., "Hindi Dub", "English Dub")
        fi
    done

    return 1 # False, no allowed dub found
}