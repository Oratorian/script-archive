#!/bin/bash

#Cron style schedule when the announce file needs to be reset (Default: 0 0 * * * [Every Day Midnight])
cron_time="5 0 * * *"

# URL of the Crunchyroll RSS feed with the current timestamp
rss_url="https://www.crunchyroll.com/rss/calender?time=$(date +%s)"

# User-specified seriesTitle to check
# To obtain the seriesTitle visit https://www.crunchyroll.com/rss/calender and look for something like this - > <crunchyroll:seriesTitle>Bye Bye, Earth</crunchyroll:seriesTitle> < -
# You need to do this for all shows you want to get a release notifycation for.
# Add them into the array below, each show in a new line
user_media_ids=(
    "Bye Bye, Earth"
    "That Time I Got Reincarnated as a Slime"
    "Demon Slayer: Kimetsu no Yaiba"
    "My Hero Academia Season 7"
    "Tower of God"
    "The Elusive Samurai"
    "Why Does Nobody Remember Me in This World?"
    "Dahlia in Bloom: Crafting a Fresh Start with Magical Tools"
    "A Nobody’s Way Up to an Exploration Hero"
    "YATAGARASU: The Raven Does Not Choose Its Master"
)

# Notification service configurations
notify_email=false
notify_pushover=false
notify_ifttt=false
notify_slack=false
notify_discord=true
notify_echo=false

# Also announce releases with (<lang> Dub), Replace with whatever Dub you want but only one.
dub='(german dub)'

# Email configuration (Not working, needs more attention)
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

install_cron_job() {
    # Define the desired cron job
    local cron_job="$cron_time > $announced_file"

    # Check if the exact cron job already exists
    local cron_exists=$(crontab -l 2>/dev/null | grep -F "$cron_job")

    # If the exact cron job doesn't exist
    if [ -z "$cron_exists" ]; then
        # Remove any existing cron job with the same command
        crontab -l 2>/dev/null | grep -v "$announced_file" | crontab -

        # Add the new cron job with the updated time
        (crontab -l 2>/dev/null; echo "$cron_job") | crontab -
        echo "Cron job installed to empty the announced file daily at $cron_time."
    else
        echo "Cron job already exists and is up to date."
    fi
}

# Function to check if a title is in the announced list
is_title_announced() {
    local keyword="$1"
    for announced_title in "${!ANNOUNCED_TITLES[@]}"; do
        if [[ "$announced_title" == *"$keyword"* ]]; then
            return 0
        fi
    done
    return 1
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

# Check if the fetched content is valid XML
if ! echo "$rss_feed" | grep -q "<?xml"; then
    echo "Error: The fetched content is not valid XML."
    exit 1
fi

# Parse the XML and extract necessary elements
media_items=$(echo "$rss_feed" | xmlstarlet sel -N cr="http://www.crunchyroll.com/rss" -N media="http://search.yahoo.com/mrss/" -t -m "//item" -v "concat(cr:title, '|', title, '|', link, '|', description, '|', media:thumbnail[1]/@url)" -n)

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
notify_via_echo() {
    local series_title="$1"
    local title="$2"
    local link="$3"
    local description=$(clean_description "$(decode_html_entities "$4")")
    echo -e "New Anime release
Title: $title
Link: $link"
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

# Function to check if the title contains any dub information
contains_any_dub() {
    local title="$1"
    if [[ "$title" =~ \(.*[Dd]ub\) ]]; then
        return 0  # True, contains some dub information
    fi
    return 1  # False, does not contain any dub information
}

# Check if any user-specified seriesTitles are found in the RSS feed
while IFS= read -r line; do
    series_title=$(echo "$line" | cut -d'|' -f1)
    title=$(echo "$line" | cut -d'|' -f2)
    link=$(echo "$line" | cut -d'|' -f3)
    description=$(echo "$line" | cut -d'|' -f4)
    thumbnail_url=$(echo "$line" | cut -d'|' -f5)

    # Convert the title to lowercase for comparison
    lower_series_title=$(echo "$title" | tr '[:upper:]' '[:lower:]')

    # Only announce titles with "(German Dub)" or titles without any dub info
    if [[ "$lower_series_title" == *"$dub"* ]] || ! contains_any_dub "$lower_series_title"; then
        for user_title in "${!user_media_ids[@]}"; do
            lower_user_title=$(echo "$user_title" | tr '[:upper:]' '[:lower:]')

            # If the title matches the user-specified title and the current day
            if [[ "$lower_series_title" == "$lower_user_title"* ]]; then #&& [ "${user_media_ids[$user_title]}" == "$current_day" ]; then
                if ! is_title_announced "$user_title"; then
                    # Announce the title
                    if [ "$notify_email" = true ]; then notify_via_email "$series_title"; fi
                    if [ "$notify_pushover" = true ]; then notify_via_pushover "$series_title"; fi
                    if [ "$notify_ifttt" = true ]; then notify_via_ifttt "$series_title"; fi
                    if [ "$notify_slack" = true ]; then notify_via_slack "$series_title"; fi
                    if [ "$notify_discord" = true ]; then notify_via_discord "$series_title" "$title" "$link" "$description" "$thumbnail_url"; fi
                    if [ "$notify_echo" = true ]; then notify_via_echo "$series_title" "$title" "$link" "$description" "$thumbnail_url"; fi
                    add_title_to_announced "$title"
                fi
            fi
        done
    fi
done <<< "$media_items"
install_cron_job