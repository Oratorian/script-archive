#!/bin/bash
declare -A user_media_ids

get_config() {
    local key="$1"
    jq -r --arg key "$key" '
    getpath($key | split(".") | map(if . == "" then null else . end)) // empty' ./cfg/config.json
}

# Function to get an associative array from JSON for user_media_ids
get_media_array() {
    local key="$1"
    declare -A assoc_array

    # Extract key-value pairs from the nested user_media_ids in JSON
    while IFS="=" read -r k v; do
        assoc_array["$k"]="$v"
    done < <(jq -r --arg key "$key" '.[$key] | to_entries | map("\(.key)=\(.value)") | .[]' ./cfg/config.json)

    # Populate the global associative array (user_media_ids)
    for k in "${!assoc_array[@]}"; do
        user_media_ids["$k"]="${assoc_array[$k]}"
    done
}

