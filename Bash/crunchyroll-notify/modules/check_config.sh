#!/bin/bash

# Function to check if config.json exists, create it if not, and check if "Example Anime" is present
check_config() {
    local config_path="./cfg/config.json"

    # Check if the config file exists
    if [ ! -f "$config_path" ]; then
        echo "Config file not found. Creating default config at $config_path..."

        # Create the cfg directory if it doesn't exist
        mkdir -p ./cfg

        # Write the default config to config.json
        cat > "$config_path" <<EOL
{
  "cron_time": "0 0 * * *",
  "animes": {
    "Example Anime": "ExampleDub",
  },
  "notification_services": {
    "email": false,
    "pushover": false,
    "ifttt": false,
    "slack": false,
    "discord": false,
    "echo": true
  },
  "announcerange": 60,
  "announced_file": "/tmp/announced_series_titles",
  "email_recipient": "your_email@example.com",
  "pushover": {
    "user_key": "your_pushover_user_key",
    "app_token": "your_pushover_app_token"
  },
  "ifttt": {
    "event": "your_ifttt_event",
    "key": "your_ifttt_key"
  },
  "slack": {
    "webhook_url": "https://hooks.slack.com/services/your/slack/webhook/url"
  },
  "discord": {
    "webhook_url": "https://discord.com/your/discord/channel/webhook/"
  }
}
EOL

        echo "Default config created. Please edit the config before running the script again."
        exit 1
    fi

    # Check if "Example Anime" is present in the config
    if [[ -n "${user_media_ids["Example Anime"]}" ]]; then
        echo "Error: 'Example Anime' is still present in the config. Please update your config before running the script."
        exit 1
    fi
}
