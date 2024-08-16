#!/bin/bash

# Generate the current UNIX timestamp
current_timestamp=$(date +%s)

# URL of the Crunchyroll RSS feed with the current timestamp
rss_url="https://www.crunchyroll.com/rss/calender?time=$current_timestamp"

# User-specified mediaIds to check
# To obtain the seriesTitle visit https://www.crunchyroll.com/rss/calender and look for something like this - > <crunchyroll:seriesTitle>Bye Bye, Earth</crunchyroll:seriesTitle> < -
# You need to do this for all shows you want to get a release notifycation for.
# Add them into the array below in the following format : ["Title of the show"]="day" where day is the day of the week when the anime should air, each show in a new line
declare -A user_media_ids
user_media_ids=(
    ["Bye Bye, Earth"]="Fr"
    ["2.5 Dimensional Seduction"]="Fr"
)

# Notification service configurations
notify_email=false
notify_pushover=false
notify_ifttt=false
notify_slack=false
notify_discord=true

# Email configuration
email_recipient="your_email@example.com"

# Pushover configuration
pushover_user_key="your_pushover_user_key"
pushover_app_token="your_pushover_app_token"

# IFTTT configuration
ifttt_event="your_ifttt_event"
ifttt_key="your_ifttt_key"

# Slack configuration
slack_webhook_url="https://hooks.slack.com/services/your/slack/webhook/url"

# Discord configuration
discord_webhook_url="https://discord.com/your/discord/channel/webhook/"

# File to keep track of announced series titles
announced_file="/tmp/announced_series_titles"

# Declare the associative array for announced titles
declare -A ANNOUNCED_TITLES

# Ensure the announced file exists
touch "$announced_file"

# Load the announced series titles from the file into the associative array
if [ -f "$announced_file" ]; then
    while IFS= read -r line; do
        ANNOUNCED_TITLES["$line"]=1
    done < "$announced_file"
fi

# Reset the announced series titles at 00:01 every day
current_time=$(date +%H:%M)
if [ "$current_time" == "00:01" ]; then
    > "$announced_file"
    ANNOUNCED_TITLES=()
fi

# Function to check if a title is in the announced list
is_title_announced() {
    local title="$1"
    if [[ -n "${ANNOUNCED_TITLES[$title]}" ]]; then
        return 0
    else
        return 1
    fi
}

# Function to add a title to the announced list
add_title_to_announced() {
    local title="$1"
    echo "$title" >> "$announced_file"
    ANNOUNCED_TITLES["$title"]=1
}

# Get the current day of the week (Mon, Tue, Wed, etc.)
current_day=$(date +%a)

# Fetch the RSS feed
rss_feed=$(curl -sL "$rss_url")

# Parse the XML and extract necessary elements
media_items=$(echo "$rss_feed" | xmlstarlet sel -N cr="http://www.crunchyroll.com/rss" -N media="http://search.yahoo.com/mrss/" -t -m "//item" -v "concat(cr:seriesTitle, '|', title, '|', link, '|', description, '|', media:thumbnail[1]/@url)" -n)

# Function to notify via email
notify_via_email() {
    echo "Series Title $1 found in RSS feed!" | mail -s "Crunchyroll Series Title Alert" "$email_recipient"
}

# Function to notify via Pushover
notify_via_pushover() {
    curl -s \
        --form-string "token=$pushover_app_token" \
        --form-string "user=$pushover_user_key" \
        --form-string "message=Series Title $1 found in RSS feed!" \
        https://api.pushover.net/1/messages.json
}

# Function to notify via IFTTT
notify_via_ifttt() {
    curl -s -X POST \
        -H "Content-Type: application/json" \
        -d "{\"value1\":\"Series Title $1 found in RSS feed!\"}" \
        https://maker.ifttt.com/trigger/$ifttt_event/with/key/$ifttt_key
}

# Function to notify via Slack
notify_via_slack() {
    curl -s -X POST \
        -H 'Content-type: application/json' \
        --data "{\"text\":\"Series Title $1 found in RSS feed!\"}" \
        "$slack_webhook_url"
}

# Function to clean HTML tags and unwanted parts from description
clean_description() {
    echo "$1" | sed -E 's/<img[^>]*>//g; s/<br \/>//g'
}

# Function to decode HTML entities using xmlstarlet
decode_html_entities() {
    echo "$1" | xmlstarlet unescape
}

# Function to notify via Discord with embed
notify_via_discord() {
    local series_title="$1"
    local title="$2"
    local link="$3"
    local description=$(clean_description "$(decode_html_entities "$4")")
    local thumbnail_url="$5"
    #local image_url="${thumbnail_url%.*}_full.jpg"

    local markdown_link="[$title]($link)"

    json_payload=$(jq -n --arg title "$title" \
                          --arg description "$description" \
                          --arg url "$link" \
                          --arg image_url "$thumbnail_url" \
                          --arg mlink "$markdown_link" \
                          '{
                              "content": null,
                              "embeds": [{
                                  "title": "New Episode Released",
                                  "description": $description,
                                  "url": $url,
                                  "color": 5814783,
                                  "fields": [{
                                     "name": $title,
                                     "value": $mlink
                                   }],
                                  "image": {
                                      "url": $image_url
                                  }
                              }],
                              "attachments": []
                          }')
    curl -s -X POST \
        -H 'Content-Type: application/json' \
        -d "$json_payload" \
        "$discord_webhook_url"
}

# Check if any user-specified seriesTitles are found in the RSS feed
while IFS= read -r line; do
    series_title=$(echo "$line" | cut -d'|' -f1)
    title=$(echo "$line" | cut -d'|' -f2)
    link=$(echo "$line" | cut -d'|' -f3)
    description=$(echo "$line" | cut -d'|' -f4)
    thumbnail_url=$(echo "$line" | cut -d'|' -f5)

    for user_title in "${!user_media_ids[@]}"; do
        if [ "$series_title" == "$user_title" ] && [ "${user_media_ids[$user_title]}" == "$current_day" ]; then
            if ! is_title_announced "$series_title"; then
                if [ "$notify_email" = true ]; then notify_via_email "$series_title"; fi
                if [ "$notify_pushover" = true ]; then notify_via_pushover "$series_title"; fi
                if [ "$notify_ifttt" = true ]; then notify_via_ifttt "$series_title"; fi
                if [ "$notify_slack" = true ]; then notify_via_slack "$series_title"; fi
                if [ "$notify_discord" = true ]; then notify_via_discord "$series_title" "$title" "$link" "$description" "$thumbnail_url"; fi
                add_title_to_announced "$series_title"
            fi
        fi
    done
done <<< "$media_items"
