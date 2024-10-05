function IsAllowedDub {
    param (
        [string] $title,
        [string[]] $allowedDubs  # Accept an array of allowed dubs
    )

    $lowerTitle = $title.ToLower()

    # If the title doesn't mention any dub, treat it as Japanese (default)
    if ($lowerTitle -notmatch '\(.*dub\)') {
        return $true
    }

    # If no allowed dubs are specified, return false for titles with explicit dubs
    if (-not $allowedDubs -or $allowedDubs.Count -eq 0) {
        return $false
    }

    # Check if the title contains one of the allowed dubs
    foreach ($dub in $allowedDubs) {
        if ($lowerTitle -like "*$($dub.ToLower())*dub*") {
            return $true
        }
    }

    return $false
}