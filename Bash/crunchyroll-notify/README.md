
# Crunchyroll Anime Release Notifier

## Description

This script monitors Crunchyroll RSS feeds for new anime releases and filters the results based on the user’s specified language dubs. The script supports notifications through multiple services, including email, Pushover, Slack, Discord, and more. It also uses a cron job to reset the notification list daily, ensuring fresh updates with each run.

## Features

- Filters anime releases by user-specified dubs.
- Supports notifications through:
  - Email
  - Pushover
  - IFTTT
  - Slack
  - Discord
  - Echo (output to terminal)
- Cron job integration to reset the notification list daily.
- Easy configuration via `config.json`.

## Prerequisites

- `jq`
- `curl`
- `xmlstarlet`
- `bash`
- `cron`

These dependencies must be installed on your system. The script will attempt to install missing dependencies based on your operating system.

## Installation

1. Download this script and modules:

2. Ensure that required tools are installed:
   ```bash
   ./crunchyroll-notify.sh
   ```

   The script will automatically check if the required tools (`jq`, `curl`, `xmlstarlet`, etc.) are installed. If any are missing, it will attempt to install them.

## Configuration

Before running the script, you need to configure it by setting your preferences in `./cfg/config.json`.

### Configuration File Structure

Here is the default `config.json` structure:

```json
{
  "cron_time": "0 0 * * *",
  "anime": {
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
```

### Steps to Configure

1. **Set your desired cron schedule**:
   - Modify `"cron_time"` to determine how often the script should check for new anime releases. The default is set to run daily at midnight (`0 0 * * *`).

2. **Specify which anime titles to monitor**:
   - Under `"anime"`, replace `"Example Anime"` with actual anime titles you want to monitor from the Crunchyroll RSS feed.
   - The format is `"<Anime Title>": "<Dubs>"`. The dubs are a comma-separated list of languages (e.g., `"English,German"`).

3. **Configure Notification Services**:
   - Under `"notification_services"`, enable or disable services (`email`, `pushover`, `ifttt`, etc.) by setting them to `true` or `false`.
   - Make sure to configure the relevant fields such as `"email_recipient"`, `"pushover"` keys, and Slack/Discord webhook URLs if those services are enabled.

4. **Adjust announcerange**:
   - The `"announcerange"` field specifies the time range in minutes in which new anime releases should be considered for notification.

## Running the Script

Once configured, you can run the script:

```bash
./crunchyroll-notify.sh
```

The script will:
1. Check for new anime releases from the Crunchyroll RSS feed.
2. Filter releases by the specified dubs in `config.json`.
3. Send notifications through the selected services.

If `config.json` is missing, the script will automatically create one with default values and prompt you to configure it.

## Setting Up Cron

To ensure the script runs periodically, you can install the cron job as specified in `config.json`:

```bash
crontab -e
```

Add the following line to schedule the script according to the `cron_time` specified in your config:

```bash
0 0 * * * /path/to/crunchyroll-notify.sh
```

This example will run the script daily at midnight. You can modify the schedule based on your needs.

## License

This project is licensed under the GPL-3 License. See the `LICENSE` file for details.
