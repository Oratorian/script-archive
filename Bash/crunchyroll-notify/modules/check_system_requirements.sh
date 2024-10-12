#!/bin/bash

# Function to install missing packages based on the detected OS
install_package() {
    local package="$1"
    if [ -x "$(command -v apt)" ]; then
        sudo apt update && sudo apt install -y "$package"
    elif [ -x "$(command -v yum)" ]; then
        sudo yum install -y "$package"
    elif [ -x "$(command -v dnf)" ]; then
        sudo dnf install -y "$package"
    elif [ -x "$(command -v pacman)" ]; then
        sudo pacman -Sy --noconfirm "$package"
    elif [ -x "$(command -v zypper)" ]; then
        sudo zypper install -y "$package"
    elif [ -x "$(command -v brew)" ]; then
        brew install "$package"
    else
        echo "Error: Unsupported OS or package manager. Please install $package manually."
        exit 1
    fi
}

# Function to check if required system tools are installed, and install them if missing
check_system_requirements() {
    local missing=false

    # List of required tools
    for tool in curl jq xmlstarlet cron bash grep sed cut date; do
        if ! command -v "$tool" &>/dev/null; then
            echo "Error: $tool is not installed. Attempting to install it."
            install_package "$tool"
            if ! command -v "$tool" &>/dev/null; then
                echo "Failed to install $tool. Please install it manually."
                missing=true
            fi
        fi
    done

    if [ "$missing" = true ]; then
        echo "Some dependencies could not be installed. Please install them manually."
        exit 1
    else
        echo "All required tools are installed."
    fi
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