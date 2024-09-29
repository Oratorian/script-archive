# Crunchyroll Notify Script

## Overview

This Bash script monitors Crunchyroll's RSS feed for new anime releases and notifies users when a series from their watchlist is released. The notifications are configurable to be sent through various services like email, Pushover, IFTTT, Slack, Discord, or directly to the terminal.

The script also allows users to filter anime announcements based on the available dubs and ensures that Japanese releases (the default language) are always notified. Additionally, it has a built-in mechanism to prevent duplicate notifications by keeping track of previously announced titles.

## Features

- Monitors Crunchyroll's RSS feed for new releases.
- Filters notifications based on user-defined series and language dubs.
- Sends notifications through:
  - Email
  - Pushover
  - IFTTT
  - Slack
  - Discord
  - Terminal echo
- Prevents duplicate announcements by keeping track of previously announced series.
- Automatically resets the notification list daily through a cron job.
- Configurable time range to accommodate delays between publishing and script execution.

## Configuration

1. **Series Watchlist**:
   Define the series you want to monitor along with the specific dubs you are interested in. If no dubs are specified, the default (Japanese) language is assumed.
   Modify the `user_media_ids` section:
   ```bash
   declare -A user_media_ids=(
       ["Bye Bye, Earth"]=""
       ["The Elusive Samurai"]="English"
       ["My Hero Academia"]="English,German"
   )
   ```

2. **Notification Methods**:
   Enable or disable notification services by setting the following variables in the config section of the script:
   ```bash
   notify_email=false
   notify_pushover=false
   notify_ifttt=false
   notify_slack=false
   notify_discord=false
   notify_echo=true
   ```

3. **Notification Range**:
   Set the time in minutes to account for delays between publishing and when the script is run:
   ```bash
   announcerange="60"  # Default: 60 minutes
   ```

4. **Announced Titles File**:
   The script keeps track of announced titles in a temporary file. By default, this file is located at `/tmp/announced_series_titles`. This file will be reset daily via a cron job.

5. **Cron Job**:
   The script installs a cron job to reset the announced titles file every day at midnight (00:00) by default. You can modify the cron job schedule by adjusting the `cron_time` variable:
   ```bash
   cron_time="0 0 * * *"
   ```

## How to Use

1. Clone or download the script to your system.
2. Open the script and modify the configuration section to suit your preferences (series titles, notification methods, etc.).
3. Run the script:
   ```bash
   ./crunchyroll-notify.sh
   ```
4. (Optional) Add the script to your crontab if you want it to run automatically at regular intervals.

## Prerequisites

- `curl`
- `xmlstarlet`
- `jq`
- Proper setup for any notification services you intend to use (e.g., Slack webhook URL, Pushover API keys, etc.).

## License

This project is open-source and available under the [MIT License](LICENSE).
