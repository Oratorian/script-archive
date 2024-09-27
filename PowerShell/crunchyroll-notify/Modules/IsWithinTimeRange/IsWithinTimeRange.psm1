function IsWithinTimeRange($pubDate, $rangeInMinutes) {
    $pubDateTime = [DateTime]::Parse($pubDate)
    $currentTime = Get-Date
    $timeDifference = $currentTime - $pubDateTime

    return $timeDifference.TotalMinutes -le $rangeInMinutes -and $timeDifference.TotalMinutes -ge - $rangeInMinutes
}