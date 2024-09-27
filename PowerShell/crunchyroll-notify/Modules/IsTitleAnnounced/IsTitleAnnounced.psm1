function IsTitleAnnounced($keyword) {
    if (Test-Path $announcedFile) {
        $announcedTitles = Get-Content $announcedFile
        return $announcedTitles -contains $keyword
    }
    return $false
}
