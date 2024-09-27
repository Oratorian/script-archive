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