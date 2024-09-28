# Shutdown Daemon PowerShell Script

## Overview

The Shutdown Daemon is a PowerShell script designed to manage remote shutdowns by listening for specific commands over a network. It supports custom configuration through parameters or a `.env` file and is intended for integration with Wake-on-LAN (WOL) systems, enabling secure shutdown operations.

## Features

- Binds to a specified IP address and port to listen for shutdown requests.
- Uses a secret key for secure communication with the Wake-on-LAN server.
- Configurable Wake-on-LAN (WOL) IP and port for integration with WOL servers.
- Supports configuration through both command-line parameters and a `.env` file for flexible deployment.
- Prompts for missing configuration values, such as the secret key.

---
## Only works in conjection with my
- [Python Wake-On-Lan Server](https://github.com/Oratorian/script-archive/tree/main/Python/wol)
---

## Usage

### Basic Command

Run the script by providing necessary parameters such as `ipAddress`, `port`, `secretKey`, `wolip`, and `wolport`:

```powershell
.\shutdown-daemon.ps1 -ipAddress "0.0.0.0" -port 8080 -secretKey "your_secret_key" -wolip "100.125.20.111" -wolport 8889
```

### Configuration via `.env` File

You can configure the script using a `.env` file located in your `$appDataPath`. If no `.env` file is present, the following default values will be used:

- `ipAddress`: `0.0.0.0`
- `port`: `8080`
- `secretKey`: (Must be provided either via the `.env` file or as a parameter.)
- `wolip`: (Must be provided either via the `.env` file or as a parameter.)
- `wolport`: `8889`

### Example `.env` File

Create a `.env` file with the following format:

```
ipAddress=192.168.1.100
port=8080
secretKey=your_secret_key
wolip=100.125.20.111
wolport=8889
```

Place this file in the directory specified by `$appDataPath`.

### Prompts for Missing Values

If the `secretKey` is not provided via the `.env` file or as a command-line parameter, the script will prompt you to enter it interactively.
If the `wolip` is not provided via the `.env` file or as a command-line parameter, the script will prompt you to enter it interactively.

## How to Configure

1. **Command-line Parameters**: Use `-ipAddress`, `-port`, `-secretKey`, `-wolip`, and `-wolport` as arguments when running the script to specify the binding IP address, port, and communication secret.
2. **Environment Variables**: Alternatively, configure these settings in a `.env` file in your `$appDataPath`. This allows you to set the IP address, port, WOL IP, WOL port, and secret key without specifying them every time the script runs.

## Notes

- The `secretKey` is required for secure communication and must be kept private.
- The daemon listens for shutdown commands and requires proper network and security configurations to function correctly.
- The WOL IP (`wolip`) and WOL port (`wolport`) are required to communicate with the Wake-on-LAN server.

## Version

Current version: **1.0.4**
