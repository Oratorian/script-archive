#================================================================================================================================================================================================================================================================================================================
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
# ----------------
# Functions Start
# -----------------
$logFilePath = Join-Path -Path $PSScriptRoot -ChildPath "crunchyroll_notify_log.txt"

function Write-LogMessage {
    param (
        [string] $message,
        [string] $color = "red"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp - $message"

    if ($GlobalLogToFile -or $GlobalDebug) {
        Add-Content -Path $logFilePath -Value $logMessage
    }

    if (-not $GlobalLogToFile -or $GlobalDebug) {
        Write-Host $logMessage -ForegroundColor $color
    }
}

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

function IsAllowedDub($title, $allowedDubs) {
    $lowerTitle = $title.ToLower()

    if ($lowerTitle -notmatch '\(.*dub\)') {
        return $true
    }

    if (-not $allowedDubs) {
        return $false
    }

    foreach ($dub in $allowedDubs.Split(',')) {
        if ($lowerTitle -like "*$($dub.ToLower())*dub*") {
            return $true
        }
    }

    return $false
}

function Confirm-IntervalWarning {
    param (
        [int]$interval
    )

    if ($interval -lt 10) {
        Write-LogMessage "WARNING: The check interval is set to less than 10 minutes, which may result in an IP ban from the RSS feed." "red"
        $response = Read-Host "Do you want to proceed with this interval? (yes/no)"

        if ($response.ToLower() -ne "yes") {
            Write-LogMessage "User opted not to continue with a risky check interval." "red"
            $newIntervalResponse = Read-Host "Do you want to set a new interval? (yes to set, no to use recommended value of 10)"
            if ($newIntervalResponse.ToLower() -eq "yes") {
                $newInterval = [int](Read-Host "Please enter the new interval in minutes (minimum 10):")
                if ($newInterval -ge 10) {
                    Write-LogMessage "New check interval set to $newInterval minutes." "green"
                    return $newInterval
                }
                else {
                    Write-LogMessage "Invalid interval entered. Using recommended value of 10 minutes." "yellow"
                    return 10
                }
            }
            else {
                Write-LogMessage "Using the recommended interval of 10 minutes." "yellow"
                return 10
            }
        }
        else {
            Write-LogMessage "User acknowledged the risk and chose to proceed." "yellow"
        }
    }

    return $interval
}
function IsWithinTimeRange($pubDate, $rangeInMinutes) {
    $pubDateTime = [DateTime]::Parse($pubDate)
    $currentTime = Get-Date
    $timeDifference = $currentTime - $pubDateTime

    return $timeDifference.TotalMinutes -le $rangeInMinutes -and $timeDifference.TotalMinutes -ge - $rangeInMinutes
}

function IsTitleAnnounced($keyword) {
    if (Test-Path $announcedFile) {
        $announcedTitles = Get-Content $announcedFile
        return $announcedTitles -contains $keyword
    }
    return $false
}

function AddTitleToAnnounced($title) {
    Add-Content -Path $announcedFile -Value $title
    Write-LogMessage "Title '$title' added to the announced list." "green"
}

function NotifyViaTray($title, $link) {
    $button = New-BTButton -Content "Watch Now" -Arguments $link
    New-BurntToastNotification -Text "New Anime Release: $title", "Watch on Crunchyroll" -Button $button
    Write-LogMessage "Notification sent for '$title'." "green"
}

function Invoke-NextCheckTimer {
    $nextCheckTime = (Get-Date).AddMinutes($GlobalCheckInterval)
    $remainingTime = $nextCheckTime - (Get-Date)
    Write-LogMessage "Time remaining before next check: $([math]::floor($remainingTime.TotalMinutes)) minute(s) $([math]::floor($remainingTime.Seconds)) second(s)" "yellow"
}

# -----------------
# Functions End
# -----------------
#================================================================================================================================================================================================================================================================================================================
# ---------------------
# Main Section Start
# ---------------------

$GlobalCheckInterval = Confirm-IntervalWarning -interval $GlobalCheckInterval
$lastRunDateFile = "$env:TEMP\lastRunDate"
$currentDate = Get-Date -Format "yyyy-MM-dd"

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