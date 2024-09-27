function AddTitleToAnnounced($title) {
    Add-Content -Path $announcedFile -Value $title
    Write-LogMessage "Title '$title' added to the announced list." "green"
}