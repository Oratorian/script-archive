function IsAllowedDub {
    param (
        [string] $title,
        [string[]] $allowedDubs  # Accept an array of allowed dubs
    )

    $lowerTitle = $title.ToLower()

    if (-not $allowedDubs -or $allowedDubs.Count -eq 0) {
        return $false
    }

    foreach ($dub in $allowedDubs) {
        if ($lowerTitle -like "*$($dub.ToLower())*dub*") {
            return $true
        }
    }

    return $false
}
