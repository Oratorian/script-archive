function NotifyViaTray($title, $link) {
    $button = New-BTButton -Content "Watch Now" -Arguments $link
    New-BurntToastNotification -Text "New Anime Release: $title", "Watch on Crunchyroll" -Button $button
    Write-LogMessage "Notification sent for '$title'." "green"
}