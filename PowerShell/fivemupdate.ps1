#---------------------------------------------------------------------------------------------
# This script © 2024 by Oration 'Mahesvara' is released unter the GPL-3.0 license
# Reproduction and modifications are allowed as long as I Oratorian@github.com is credited
# as the original Author
#---------------------------------------------------------------------------------------------

# Configuration variables
$UPDATE_DIR = "./updates2"  # Relative or absolute path where updates are stored
$FIVEM_DIR = "./fivem2"     # Relative or absolute path where FiveM is installed (Typically where FXServer.exe is located)
$RUN_SCRIPT = "FXServer.exe"
$RELEASE = "latest"         # Can be either 'recommended' or 'latest'


function Ensure-7ZipInstalled {
    $sevenZipPath = "$ScriptDir\7z.exe"
    $installerUrl = "https://7-zip.org/a/7zr.exe"


    if (-Not (Test-Path $sevenZipPath)) {
        Write-Output "7-Zip is not installed. Installing now, Downloading to $sevenZipPath"
        Invoke-WebRequest -Uri $installerUrl -OutFile $sevenZipPath
        Write-Output "7-Zip Download complete."
    } else {
        Write-Output "7-Zip exists."
    }
}

function Resolve-Directory {
    param (
        [string]$Path,
        [string]$ScriptDir
    )

    if ([System.IO.Path]::IsPathRooted($Path)) {
        return [System.IO.Path]::GetFullPath($Path)
    } else {
        $resolvedPath = Join-Path -Path $ScriptDir -ChildPath $Path
        return [System.IO.Path]::GetFullPath($resolvedPath)
    }
}

Ensure-7ZipInstalled
$ScriptDir = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
$UPDATEDIR = Resolve-Directory -Path $UPDATE_DIR -ScriptDir $ScriptDir
$FIVEMDIR = Resolve-Directory -Path $FIVEM_DIR -ScriptDir $ScriptDir

if (-Not [string]::IsNullOrWhiteSpace($UPDATEDIR) -and (Test-Path $UPDATEDIR)) {
    Write-Output "Using update directory: $UPDATEDIR"
} else {
    New-Item -ItemType Directory -Path $UPDATEDIR
    Write-Output "Default update directory is not set or inaccessible. Creating directory: $UPDATEDIR"
}

if (-Not [string]::IsNullOrWhiteSpace($FIVEMDIR) -and (Test-Path $FIVEMDIR)) {
    Write-Output "Using FiveM directory: $FIVEMDIR"
} else {
    New-Item -ItemType Directory -Path $FIVEMDIR
    Write-Output "Default FiveM directory is not set or inaccessible. Creating directory: $FIVEMDIR"
}



$jsonData = Invoke-RestMethod -Uri "https://changelogs-live.fivem.net/api/changelog/versions/win32/server"

if ($RELEASE -eq "recommended") {
    $downloadUrl = $jsonData.recommended_download
} else {
    $downloadUrl = $jsonData.latest_download
}

$versionCode = ($downloadUrl -split 'master/')[1] -split '-' | Select-Object -First 1
$destinationFile = "${UPDATEDIR}/${versionCode}.zip"

if ([string]::IsNullOrWhiteSpace($versionCode) -or (Test-Path $destinationFile)) {
    Write-Output "Nothing to do"
} else {
    $scriptProcessName = $RUN_SCRIPT -replace '\.exe$', ''
    try {
        $scriptProcess = Get-Process -Name $scriptProcessName -ErrorAction SilentlyContinue
        Stop-Process -Name $scriptProcessName -Force -ErrorAction Stop
        Write-Output "Stopped running script: $RUN_SCRIPT"
    } catch {
        Write-Output "No running process found for: $RUN_SCRIPT. Nothing to stop."
    }

    Invoke-WebRequest -Uri $downloadUrl -OutFile $destinationFile
    & 7z x $destinationFile -o"$FIVEMDIR" -aoa

    Start-Process "$FIVEMDIR\$RUN_SCRIPT"
    Write-Output "Started FXServer: $FIVEMDIR\$RUN_SCRIPT"
}

Get-ChildItem $UPDATEDIR -Filter "*.zip" |
    Sort-Object CreationTime -Descending |
    Select-Object -Skip 5 |
    Remove-Item -Force