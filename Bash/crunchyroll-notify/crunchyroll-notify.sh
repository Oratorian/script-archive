#!/bin/bash

#================================================================================================================================================================================================================================================================================================================

#---------------------------------------------------------------------------------------------
# This script © 2024 by Oration 'Mahesvara' is released unter the GPL-3.0 license
# Reproduction and modifications are allowed as long as I Oratorian@github.com is credited
# as the original Author
#---------------------------------------------------------------------------------------------

## Version: 2.1.3

#================================================================================================================================================================================================================================================================================================================


#-----------------
# Main Code Start
#-----------------
for module in ./modules/*.sh; do
    source "$module"
done
check_config
check_system_requirements
install_cron_job

if [ -n "$announced_file" ] && [ -f "$announced_file" ]; then
    while IFS= read -r line; do
        ANNOUNCED_TITLES["$line"]=1
    done < "$announced_file"
else
    echo "Error: announced_file is not set or does not exist."
    check_announced_file
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

#-----------------
# Main Code End
#-----------------
