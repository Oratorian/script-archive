#!/bin/bash

#Cron style schedule when the announce file needs to be reset (Default: 0 0 * * * [Every Day Midnight])
cron_time="5 0 * * *"

# URL of the Crunchyroll RSS feed with the current timestamp
rss_url="https://www.crunchyroll.com/rss/calender?time=$(date +%s)"

# User-specified seriesTitle to check
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

declare -A ANNOUNCED_TITLES
touch "$announced_file"

if [ -f "$announced_file" ]; then
    while IFS= read -r line; do
        ANNOUNCED_TITLES["$line"]=1
    done < "$announced_file"
fi

install_cron_job() {
    local cron_job="$cron_time > $announced_file"

    local cron_exists=$(crontab -l 2>/dev/null | grep -F "$cron_job")

    if [ -z "$cron_exists" ]; then
        crontab -l 2>/dev/null | grep -v "$announced_file" | crontab -

        (crontab -l 2>/dev/null; echo "$cron_job") | crontab -
        echo "Cron job installed to empty the announced file daily at $cron_time."
    else
        echo "Cron job already exists and is up to date."
    fi
}

install_cron_job

is_title_announced() {
    local keyword="$1"
    for announced_title in "${!ANNOUNCED_TITLES[@]}"; do
        if [[ "$announced_title" == *"$keyword"* ]]; then
            return 0
        fi
    done
    return 1
}

add_title_to_announced() {
    local title="$1"
    echo "$title" >> "$announced_file"
    ANNOUNCED_TITLES["$title"]=1
}

rss_feed=$(curl -sL "$rss_url")
current_day=$(date +%a)
media_items=$(echo "$rss_feed" | xmlstarlet sel -N cr="http://www.crunchyroll.com/rss" -N media="http://search.yahoo.com/mrss/" -t -m "//item" -v "concat(cr:seriesTitle, '|', title, '|', link, '|', description, '|', media:thumbnail[1]/@url)" -n)

if ! echo "$rss_feed" | grep -q "<?xml"; then
    echo "Error: The fetched content is not valid XML."
    exit 1
fi

notify_via_email() {
    echo "Series Title $1 found in RSS feed!" | mail -s "Crunchyroll Series Title Alert" "$email_recipient"
}

notify_via_pushover() {
    curl -s \
        --form-string "token=$pushover_app_token" \
        --form-string "user=$pushover_user_key" \
        --form-string "message=Series Title $1 found in RSS feed!" \
        https://api.pushover.net/1/messages.json
}

notify_via_ifttt() {
    curl -s -X POST \
        -H "Content-Type: application/json" \
        -d "{\"value1\":\"Series Title $1 found in RSS feed!\"}" \
        https://maker.ifttt.com/trigger/$ifttt_event/with/key/$ifttt_key
}

notify_via_slack() {
    curl -s -X POST \
        -H 'Content-type: application/json' \
        --data "{\"text\":\"Series Title $1 found in RSS feed!\"}" \
        "$slack_webhook_url"
}

clean_description() {
    echo "$1" | sed -E 's/<img[^>]*>//g; s/<br \/>//g'
}

decode_html_entities() {
    echo "$1" | xmlstarlet unescape
}

notify_via_discord() {
    local series_title="$1"
    local title="$2"
    local link="$3"
    local description=$(clean_description "$(decode_html_entities "$4")")
    local thumbnail_url="$5"

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

while IFS= read -r line; do
    series_title=$(echo "$line" | cut -d'|' -f1)
    title=$(echo "$line" | cut -d'|' -f2)
    link=$(echo "$line" | cut -d'|' -f3)
    description=$(echo "$line" | cut -d'|' -f4)
    thumbnail_url=$(echo "$line" | cut -d'|' -f5)

    for user_title in "${!user_media_ids[@]}"; do
        if [[ "$series_title" == *"$user_title"* ]] && [ "${user_media_ids[$user_title]}" == "$current_day" ]; then
            if ! is_title_announced "$user_title"; then
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