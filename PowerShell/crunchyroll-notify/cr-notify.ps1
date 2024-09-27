#================================================================================================================================================================================================================================================================================================================

#---------------------------------------------------------------------------------------------
# This script © 2024 by Oration 'Mahesvara' is released unter the GPL-3.0 license
# Reproduction and modifications are allowed as long as I Oratorian@github.com is credited
# as the original Author
#---------------------------------------------------------------------------------------------

## Version: 2.0.1

# Changelog

## [2.0.1] - 2024-09-27
### Fixed
# - Added the `ModuleToProcess` field to `.psd1` manifest files to correctly link `.psm1` files, resolving an issue where modules were not being loaded during import.

### Added
# - Specified module dependencies in the `.psd1` manifest files using the `RequiredModules` field to ensure that required modules (e.g., `BurntToast`, `Pester`) are automatically loaded or installed when the module is imported.

#---

## [2.0.0] - 2024-09-26
### Major Changes
# - Refactored the script into a modular architecture by separating functions into individual PowerShell modules.
# - Implemented manifest files for each module for better modularity and reusability.
# - Changed versioning to Semantic Versioning (SemVer) from 4-digit versioning.

#---

## [1.2.0] - 2024-09-26

### Added
# - Added `$checkinterval` variable for controlling the interval between RSS feed checks, defaulting to 10 minutes, with configurable options.
# - Added `Confirm-IntervalWarning` function to alert users when the check interval is set to less than 10 minutes, with an option to proceed or set a new interval.
# - Introduced user-configurable logging options (`$GlobalLogToFile`, `$GlobalDebug`) allowing logging to console, file, or both, controlled via config without editing `Write-LogMessage` calls.

### Changed
# - Refined `Write-LogMessage` to support logging configuration, reducing the need for manual changes when switching between logging modes.
# - Reworked the check interval logic so `Confirm-IntervalWarning` returns the final interval value, which is used for future checks, preventing reliance on initial config values.
# - Integrated user confirmation for check intervals less than 10 minutes and added handling for setting a new interval if declined.

### Fixed
# - Corrected a bug where setting an interval below 10 minutes would still use the original value from the config due to improper value reassignment logic.
# - Fixed an issue where incorrect log messages were displayed when setting new intervals that did not meet the minimum threshold.
# - Adjusted logic for checking `seriesTitle` and dub permissions to ensure the proper handling of allowed dubs and titles from `$userMediaIDs`.

# ---

## [1.1.1] - 2024-09-25

### Changed
# - Adjusted the logging mechanism to include color-coded messages for warnings, errors, and normal logs, enhancing visual debugging.
# - Updated the structure of RSS feed handling due to the flattened XML returned by `Invoke-RestMethod`, eliminating reliance on nested item structures.
# - Modified the notification system to use BurntToast with clickable buttons (`New-BTButton`) to open the episode URL when clicked.

### Fixed
# - Resolved an issue where all anime titles were being announced instead of filtering by `$userMediaIDs`.
# - Corrected the RSS feed parsing logic to ensure items are processed from the flattened XML structure and not dependent on nested `channel.item`.
# - Addressed a minor logging issue where incorrect messages were being shown when setting a new check interval below the allowed range.

# ---

## [1.1.0] - 2024-09-24

### Added
# - Introduced support for clickable notifications using BurntToast `New-BTButton` to launch the episode link directly from the tray notification.
# - Added `$userMediaIDs` to filter specific series based on user preferences, allowing users to track only their chosen anime series.
# - Implemented a time range check using `$announceRange`, limiting notifications to episodes within a certain release window (in minutes).

### Changed
# - Replaced hardcoded time ranges with the `$announceRange` variable, giving users control over the time window for which episodes are announced.
# - Added color-coded log messages throughout the script to improve readability and debug output.

### Fixed
# - Fixed an issue where tray notifications did not send clickable buttons for watching the episode link directly from the notification.
# - Corrected the dub filtering logic to ensure only allowed dubs are notified.
# - Resolved a bug with `seriesTitle` and `episodeTitle` parsing, ensuring titles are correctly processed and logged.

# ---

## [1.0.0] - 2024-09-22

### Added
# - Initial release of the script with basic RSS feed parsing functionality using `Invoke-RestMethod` to fetch Crunchyroll updates.
# - Implemented series title and dub filtering based on user input via `$userMediaIDs`.
# - Added time-based filtering to ensure episod# es within a certain time window are notified.
# - Introduced BurntToast for tray notifications of new episode releases.
# 


# ----------------
# Config Start
# ----------------

# User-specified seriesTitle to check
# To obtain the seriesTitle visit https://www.crunchyroll.com/rss/calender and look for something like this - > <crunchyroll:seriesTitle>Bye Bye, Earth</crunchyroll:seriesTitle> < -
# You need to do this for all shows you want to get a release notifycation for.
# Add them into the array below, each show in a new line
# Format is like this "Title"="Dubs" Where Dubs is a comma seperated list of dubs to announce (Since Japanese is standard DUB it will always get announced and does not need to be specified here)
$userMediaIDs = @{
    "Wistoria: Wand and Sword" = ""  # Add more series as needed
    "Tower of God" = ""
}

# Time difference range in minutes for announcements
$announceRange = 60

# File to keep track of announced series titles
$announcedFile = "$env:TEMP\announced_series_titles"

# Logging Configuration
$GlobalLogToFile = $true   # Set to $false to disable logging to file
$GlobalDebug = $true      # Set to $true to log to both file and console

#Checkinterval in seconds default: 600 (10min)
# ATTENTION : Everything lower then 10 minutes can result in an IP ban on the rss feed. Typicall values are 10 - 15 min on each rss sync
$GlobalCheckInterval = 10  # Default check interval in minutes

# ----------------
# Config End
# ----------------
#================================================================================================================================================================================================================================================================================================================
# ---------------------
# Main Section Start
# ---------------------

Get-ChildItem -Path "$PSScriptRoot\Modules" -Directory | ForEach-Object {

    $manifestPath = "$($_.FullName)\$($_.Name).psd1"
    if (Test-Path $manifestPath) {
        Import-Module "$manifestPath" -Verbose
        Write-Host "Module $($_.Name) imported successfully."
    } else {
        Write-Host "Manifest file not found for module $($_.Name)." -ForegroundColor Red
    }
}

$logFilePath = Join-Path -Path $PSScriptRoot -ChildPath "crunchyroll_notify_log.txt"
$GlobalCheckInterval = Confirm-IntervalWarning -interval $GlobalCheckInterval
$lastRunDateFile = "$env:TEMP\lastRunDate"
$currentDate = Get-Date -Format "yyyy-MM-dd"
Write-LogMessage "Script started." "green"

if (-not (Get-Module -ListAvailable -Name BurntToast)) {
    try {
        Install-Module -Name BurntToast -Force -AllowClobber -ErrorAction Stop
        Write-LogMessage "BurntToast module installed." "green"
    }
    catch {
        Write-LogMessage "Failed to install BurntToast module: $_" "red"
        exit 1
    }
}

if (-not (Get-Module -Name BurntToast)) {
    try {
        Import-Module -Name BurntToast
        Write-LogMessage "BurntToast module import sucessfull." "green"
    }
    catch {
        Write-LogMessage "Failed to import BurntToast module: $_" "red"
        exit 1
    }
}

if (-not (Test-Path $announcedFile)) {
    New-Item -Path $announcedFile -ItemType File -Force | Out-Null
    Write-LogMessage "Announced file created." "yellow"
}
else {
    Write-LogMessage "Announced file exists at." "green"
}

if (Test-Path $lastRunDateFile) {
    $lastRunDate = Get-Content $lastRunDateFile

    if ($currentDate -ne $lastRunDate) {
        Write-Host "A new day has started. Wiping announcefile."
        Set-Content -Path $announcedFile -Value $null
    }
}
else {
    Set-Content -Path $lastRunDateFile -Value $currentDate
}
Set-Content -Path $lastRunDateFile -Value $currentDate

while ($true) {
    Write-LogMessage "Checking for new releases..." "green"

    $cacheBuster = [System.Guid]::NewGuid().ToString()
    $feedUrl = "https://www.crunchyroll.com/rss/calendar?time=$([math]::floor((Get-Date -UFormat %s)))&cacheBuster=$cacheBuster"

    try {
        $rssFeed = Invoke-RestMethod -Uri $feedUrl
        Write-LogMessage "RSS feed fetched successfully." "green"
    }
    catch {
        Write-LogMessage "Error fetching or parsing RSS feed: $_" "red"
        exit 1
    }

    if ($null -ne $rssFeed) {
        Write-LogMessage "Found elements in the RSS feed." "green"

        foreach ($item in $rssFeed) {
            $title = $item.title
            $seriesTitle = $item.seriesTitle
            $episodeTitle = $item.episodeTitle
            $pubDate = $item.pubDate
            $link = $item.link

            if (-not $userMediaIDs.ContainsKey($seriesTitle)) {
                Write-LogMessage "Series '$seriesTitle - $episodeTitle' is not in user-specified list. Skipping." "yellow"
                continue
            }

            Write-LogMessage "Processing item: Title='$title', Series='$seriesTitle', PubDate='$pubDate'" "yellow"
            $allowedDubs = $userMediaIDs[$seriesTitle]

            if (IsAllowedDub $title $allowedDubs) {
                Write-LogMessage "Allowed dub found for '$title'." "green"

                if (IsWithinTimeRange $pubDate $announceRange) {
                    Write-LogMessage "Title '$title' is within the allowed time range." "green"

                    if (-not (IsTitleAnnounced $title)) {
                        NotifyViaTray $seriesTitle $link
                        AddTitleToAnnounced $title
                    }
                    else {
                        Write-LogMessage "Title '$title' has already been announced." "yellow"
                    }
                }
                else {
                    Write-LogMessage "Title '$title' is outside the allowed time range." "blue"
                }
            }
            else {
                Write-LogMessage "No allowed dub found for '$title'. Skipping." "red"
            }
        }
    }
    else {
        Write-LogMessage "No elements found in RSS feed." "red"
        exit 1
    }
    $sleepTime = ($GlobalCheckInterval * 60)
    Invoke-NextCheckTimer

    while ($sleepTime -gt 0) {
        $minutesLeft = [math]::Floor($sleepTime / 60)
        $secondsLeft = $sleepTime % 60
        Write-LogMessage "Time remaining before next check: $minutesLeft minute(s) $secondsLeft second(s)" "cyan"

        Start-Sleep -Seconds 60
        $sleepTime -= 60
    }

    Write-LogMessage "Waking up for the next check..." "green"
}
# ---------------------
# Main Section End
# ---------------------
