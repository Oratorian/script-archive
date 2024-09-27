function Invoke-NextCheckTimer {
    $nextCheckTime = (Get-Date).AddMinutes($GlobalCheckInterval)
    $remainingTime = $nextCheckTime - (Get-Date)
    Write-LogMessage "Time remaining before next check: $([math]::floor($remainingTime.TotalMinutes)) minute(s) $([math]::floor($remainingTime.Seconds)) second(s)" "yellow"
}