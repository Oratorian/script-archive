function Invoke-NextCheckTimer {
    $nextCheckTime = (Get-Date).AddMinutes($GlobalCheckInterval)
    $remainingTime = $nextCheckTime - (Get-Date)
}