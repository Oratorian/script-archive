# FiveM Server Updater Script

This Bash script automates the process of updating a FiveM server. It downloads the latest or recommended version of the FiveM server files, extracts them, and restarts the server using either `tmux` or `screen` for session management. It also performs cleanup of older versions to save disk space.

## Features

- **Automatic Updates**: Fetches and installs the latest or recommended version of the FiveM server from the official API.
- **Session Management**: Allows the use of either `tmux` or `screen` to manage server sessions, with configurable session names.
- **Customizable Directories**: Defines separate directories for storing updates and the main FiveM installation.
- **Version Control**: Ensures only the 5 most recent server updates are retained, automatically deleting older versions.
- **Download Management**: Verifies if the latest version is already downloaded before attempting a new download.

## Configuration

The script includes several configuration variables that can be modified to suit your environment:

- `source`: Point to the directory you want to back up.
- `backup`: Specify the destination directory for backups.


## How It Works

1. **Directory Setup**: Ensures the update and FiveM directories exist, creating them if necessary.
2. **Fetch Latest Version**: Retrieves the latest or recommended version information from the FiveM API.
3. **Download & Extract**: If a new version is found, it downloads the update as a `.tar.xz` file and extracts it to the FiveM server directory.
4. **Server Restart**: Restarts the server using `tmux` or `screen`, based on the configuration.
5. **Cleanup**: Keeps only the 5 most recent versions in the update directory, automatically deleting older files.

## Prerequisites

- `tmux` or `screen`: One of these tools must be installed for session management.
- `wget`: Used to download server updates.
- `curl`: Required to fetch update information from the FiveM API.

## Usage

1. Configure the variables at the top of the script to match your environment.
2. Run the script to update the server:

```bash
./fivemupdate.sh