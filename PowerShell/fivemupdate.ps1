# Configuration variables
$UPDATE_DIR = ""
$FIVEM_DIR = ""
$RUN_SCRIPT = "FXServer.exe"
$pageUrl = "https://runtime.fivem.net/artifacts/fivem/build_server_windows/master/"
$ScriptDir = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition

if (-Not [string]::IsNullOrWhiteSpace($UPDATE_DIR) -and (Test-Path $UPDATE_DIR)) {
    Write-Output "Using update directory: $UPDATE_DIR"
} else {
    $UPDATE_DIR = $ScriptDir
    Write-Output "Default update directory is not set or inaccessible. Falling back to script directory: $UPDATE_DIR"
}

if (-Not [string]::IsNullOrWhiteSpace($FIVEM_DIR) -and (Test-Path $FIVEM_DIR)) {
    Write-Output "Using FiveM directory: $FIVEM_DIR"
} else {
    $FIVEM_DIR = "$ScriptDir\fivem"
    Write-Output "Default FiveM directory is not set or inaccessible. Falling back to script directory: $FIVEM_DIR"
}


if (-Not (Test-Path $UPDATE_DIR)) {
    New-Item -ItemType Directory -Path $UPDATE_DIR
    Write-Output "Created directory: $UPDATE_DIR"
}


$webContent = Invoke-WebRequest -Uri $pageUrl
$links = $webContent.Links.Href | Where-Object { $_ -match '\d{4}[^"]+' } | Sort-Object -Descending
$highestVersionUrl = $links[0]
$downUrl = $pageUrl + $highestVersionUrl.TrimStart('/')
$versionCode = $highestVersionUrl -match '\d{4}-[a-f0-9]+' | Out-Null
$versionCode = $Matches[0] -split '-' | Select-Object -First 1
$destinationFile = "${UPDATE_DIR}/${versionCode}.7z"

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

        Invoke-WebRequest -Uri $downUrl -OutFile $destinationFile
        & 7z x $destinationFile -o"$FIVEM_DIR" -aoa
        
        Start-Process "$FIVEM_DIR/$RUN_SCRIPT"
        Write-Output "Started new script: $RUN_SCRIPT"
}

Get-ChildItem $UPDATE_DIR -Filter "*.7z" | 
    Sort-Object CreationTime -Descending | 
    Select-Object -Skip 5 |
    Remove-Item -Force
