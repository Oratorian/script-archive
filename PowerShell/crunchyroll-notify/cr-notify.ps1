cls
#================================================================================================================================================================================================================================================================================================================

#---------------------------------------------------------------------------------------------
# This script © 2024 by Oration 'Mahesvara' is released unter the GPL-3.0 license
# Reproduction and modifications are allowed as long as I Oratorian@github.com is credited
# as the original Author
#---------------------------------------------------------------------------------------------

## Version: 2.1.2

#================================================================================================================================================================================================================================================================================================================
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process

Get-ChildItem -Path "$PSScriptRoot\Modules" -Directory | ForEach-Object {

    $manifestPath = "$($_.FullName)\$($_.Name).psd1"
    if (Test-Path $manifestPath) {
        Import-Module "$manifestPath" -Verbose
        Write-Host "Module $($_.Name) imported successfully."
    }
    else {
        Write-Host "Manifest file not found for module $($_.Name)." -ForegroundColor Red
    }
}

$configPath = Join-Path -Path $PSScriptRoot -ChildPath "config.json"
if (-not (Test-Path $configPath)) {
    Write-LogMessage "Configuration file not found at $configPath." "red"
    exit 1
}

try {
    $config = Get-Content -Raw -Path $configPath | ConvertFrom-Json
    Write-LogMessage "Configuration file loaded successfully." "green"
}
catch {
    Write-LogMessage "Failed to load configuration file: $_" "red"
    exit 1
}

$userMediaIDs = $config.userMediaIDs
$announceRange = $config.announceRange
$Global:GlobalLogToFile = $config.GlobalLogToFile
$Global:GlobalDebug = $config.GlobalDebug
#$GlobalCheckInterval = $config.GlobalCheckInterval
$announcedFile = $config.announcedFile
$Global:logFilePath = Join-Path -Path $PSScriptRoot -ChildPath "crunchyroll_notify_log.txt"
$Global:GlobalCheckInterval = Confirm-IntervalWarning -interval $config.GlobalCheckInterval
$lastRunDateFile = "$env:TEMP\lastRunDate"
$currentDate = Get-Date -Format "yyyy-MM-dd"

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
    Write-LogMessage "Announced file exists." "green"
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
Write-LogMessage "Script started." "green"

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
            $seriesTitle = $item.seriesTitle  # Use the exact series title as retrieved
            $episodeTitle = $item.episodeTitle
            $pubDate = $item.pubDate
            $link = $item.link
        
            # Check if the exact series title exists in userMediaIDs
            if ($userMediaIDs.PSObject.Properties.Name -contains $seriesTitle) {
                $allowedDubs = $userMediaIDs.$seriesTitle
                Write-LogMessage "Dubs for $seriesTitle : $allowedDubs"
            }
            else {
                Write-LogMessage "Series '$seriesTitle' is not in user-specified list. Skipping." "yellow"
                continue
            }
        
            # Split allowed dubs into an array if they are not empty
            $allowedDubsArray = @()
            if ($allowedDubs -and $allowedDubs.Trim() -ne "") {
                $allowedDubsArray = $allowedDubs -split ',\s*'  # Split by comma and optional spaces
            }
        
            Write-LogMessage "Processing: $seriesTitle with allowed dubs: '$allowedDubsArray'"
        
            # Check if the title has an allowed dub
            if (IsAllowedDub $title $allowedDubsArray) {
                Write-LogMessage "Allowed dub found for '$title'." "green"
        
                # Check if the title is within the allowed time range
                if (IsWithinTimeRange $pubDate $announceRange) {
                    Write-LogMessage "Title '$title' is within the allowed time range." "green"
        
                    # Check if the title has already been announced
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

    # Use GlobalCheckInterval to control the sleep duration
    $sleepTime = ($GlobalCheckInterval * 60)
    Invoke-NextCheckTimer

    while ($sleepTime -gt 0) {
        $minutesLeft = [math]::Floor($sleepTime / 60)
        $secondsLeft = $sleepTime % 60
        Write-Host "Time remaining before next check: $minutesLeft minute(s) $secondsLeft second(s)" -ForegroundColor "cyan"

        Start-Sleep -Seconds 60
        $sleepTime -= 60
    }

    Write-Host "Waking up for the next check..." -ForegroundColor "green"
}