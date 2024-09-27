function IsAllowedDub($title, $allowedDubs) {
    $lowerTitle = $title.ToLower()

    if ($lowerTitle -notmatch '\(.*dub\)') {
        return $true
    }

    if (-not $allowedDubs) {
        return $false
    }

    foreach ($dub in $allowedDubs.Split(',')) {
        if ($lowerTitle -like "*$($dub.ToLower())*dub*") {
            return $true
        }
    }

    return $false
}