#!/bin/bash

# ------------------------------------------------------------
#  Crunchyroll Notify Script - Version 2.0.1
#  Author: Oratorian 'Mahesvara'
#  License: GPL-3.0
# ------------------------------------------------------------
#
#  Description:
#  This script monitors Crunchyroll's RSS feed for new anime 
#  releases and sends notifications for series in your watchlist.
#  See 'declare -A user_media_ids=(' to find the Watchlist.
#  Notifications can be sent via:
#    - Email
#    - Pushover
#    - IFTTT
#    - Slack
#    - Discord
#    - Echo (terminal output)
#
#  You can specify which series and dubs you are interested in, 
#  and the script prevents duplicate notifications by tracking 
#  previously announced titles.
#
# ------------------------------------------------------------
#  License:
#  This script is licensed under the GNU General Public License 
#  v3.0 (GPL-3.0). For more details, visit:
#  https://www.gnu.org/licenses/gpl-3.0.html
# ------------------------------------------------------------


#----------------
# Config Start
#----------------

# Cron style schedule when the announce file needs to be reset (Default: 0 0 * * * [Every Day Midnight])
cron_time="0 0 * * *"

# User-specified seriesTitle to check
# To obtain the seriesTitle visit https://www.crunchyroll.com/rss/calender and look for something like this - > <crunchyroll:seriesTitle>Bye Bye, Earth</crunchyroll:seriesTitle> < -
# You need to do this for all shows you want to get a release notifycation for.
# Add them into the array below, each show in a new line
# Format is like this ["Title"]="Dubs" Where Dubs is a comma seperated list of dubs to announce (Since Japanese is standard DUB it will always get announced and does not need to be specified here)
declare -A user_media_ids=(
    ["Bye Bye, Earth"]=""
    ["The Elusive Samurai"]="English"
    ["My Hero Academia"]="English,German"
)

# Notification service configurations
notify_email=false
notify_pushover=false
notify_ifttt=false
notify_slack=false
notify_discord=false
notify_echo=true

# To accomendate the time difference between publishing and script runtime, set time in minutes
# the script shall announce an anime after pubdate. ex : Anime publshed @ 6 PM UTC but script runs at 6:10 PM UTC, announcerange=60 => Anime gets announced because within range, announcerange=5 => Anime does not get announced because out of range.
announcerange="60"

# File to keep track of announced series titles

announced_file="/tmp/announced_series_titles"

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

#----------------
# Config End
#----------------

# /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#-----------------
# Functions Start
#-----------------
declare -A ANNOUNCED_TITLES

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

install_cron_job() {
    local cron_job="$cron_time > $announced_file"
    local cron_exists=$(crontab -l 2>/dev/null | grep -F "$cron_job")

    if [ -z "$cron_exists" ]; then
        crontab -l 2>/dev/null | grep -v "$announced_file" | crontab -
        (
            crontab -l 2>/dev/null
            echo "$cron_job"
        ) | crontab -
        echo "Cron job installed to empty the announced file daily at $cron_time."
    else
        echo "Cron job already exists and is up to date."
    fi
}

add_title_to_announced() {
    local title="$1"
    echo "$title" >>"$announced_file"
    ANNOUNCED_TITLES["$title"]=1
}

check_announced_file() {
    if [ ! -f "$announced_file" ]; then
        touch "$announced_file"
        echo "Created announced file at $announced_file."
    else
        echo "Announced file already exists at $announced_file."
    fi
}

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
    echo "$1" | sed -E 's/<img[^>]*>//g; s/<br \/>//g; s/&#13;//g' | tr -d '\r\n'
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
                                    "id": 802559332,
                                    "name": "Title :",
                                    "value": " ",
                                    "inline": true
                                    },
                                    {
                                    "id": 401448333,
                                    "name": $title,
                                    "value": " ",
                                    "inline": true
                                    },
                                    {
                                    "id": 897239191,
                                    "name": " ",
                                    "value": " ",
                                    "inline": false
                                    },
                                    {
                                    "id": 469320997,
                                    "name": "Watch on",
                                    "value": " ",
                                    "inline": true
                                    },
                                    {
                                    "id": 907109677,
                                    "name": "Crunchyroll :",
                                    "value": $mlink,
                                    "inline": true
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

#-----------------
# Functions End
#-----------------

# /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#-----------------
# Main Code Start
#-----------------

check_announced_file

if [ -f "$announced_file" ]; then
    while IFS= read -r line; do
        ANNOUNCED_TITLES["$line"]=1
    done <"$announced_file"
fi

rss_feed=$(curl -sL "https://www.crunchyroll.com/rss/calendar?time=$(date +%s)")

if ! echo "$rss_feed" | grep -q "<?xml"; then
    echo "Error: The fetched content is not valid XML."
    exit 1
fi

media_items=$(echo "$rss_feed" | xmlstarlet sel -N cr="http://www.crunchyroll.com/rss" -N media="http://search.yahoo.com/mrss/" -t -m "//item" -v "concat(crunchyroll:seriesTitle, '|', title, '|', pubDate, '|', link, '|', normalize-space(description), '|', media:thumbnail[1]/@url)" -n)

while IFS= read -r line; do
    series_title=$(echo "$line" | cut -d'|' -f1)
    title=$(echo "$line" | cut -d'|' -f2)
    pub_date=$(echo "$line" | cut -d'|' -f3)
    link=$(echo "$line" | cut -d'|' -f4)
    description=$(echo "$line" | cut -d'|' -f5)
    thumbnail_url=$(echo "$line" | cut -d'|' -f6)
    lower_series_title=$(echo "$title" | tr '[:upper:]' '[:lower:]')
    allowed_dubs="${user_media_ids["$series_title"]}"

if is_allowed_dub "$lower_series_title" "$allowed_dubs"; then

        if ! is_within_time_range "$pub_date" "$announcerange"; then
            continue
        fi

        for user_title in "${!user_media_ids[@]}"; do
            lower_user_title=$(echo "$user_title" | tr '[:upper:]' '[:lower:]')

            if [[ "$lower_series_title" == "$lower_user_title"* ]]; then
                if ! is_title_announced "$lower_series_title"; then
                    [ "$notify_email" = true ] && notify_via_email "$series_title"
                    [ "$notify_pushover" = true ] && notify_via_pushover "$series_title"
                    [ "$notify_ifttt" = true ] && notify_via_ifttt "$series_title"
                    [ "$notify_slack" = true ] && notify_via_slack "$series_title"
                    [ "$notify_discord" = true ] && notify_via_discord "$series_title" "$title" "$link" "$description" "$thumbnail_url"
                    [ "$notify_echo" = true ] && notify_via_echo "$series_title" "$title" "$link" "$description" "$thumbnail_url"
                    add_title_to_announced "$lower_series_title"
                fi
            fi
        done
    else
        continue
    fi
done <<<"$media_items"

install_cron_job

#-----------------
# Main Code End
#-----------------
