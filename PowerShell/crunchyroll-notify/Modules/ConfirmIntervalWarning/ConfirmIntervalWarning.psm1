function Confirm-IntervalWarning {
    param (
        [int]$interval
    )

    if ($interval -lt 10) {
        Write-LogMessage "WARNING: The check interval is set to less than 10 minutes, which may result in an IP ban from the RSS feed." "red"
        $response = Read-Host "Do you want to proceed with this interval? (yes/no)"

        if ($response.ToLower() -ne "yes") {
            Write-LogMessage "User opted not to continue with a risky check interval." "red"
            $newIntervalResponse = Read-Host "Do you want to set a new interval? (yes to set, no to use recommended value of 10)"
            if ($newIntervalResponse.ToLower() -eq "yes") {
                $newInterval = [int](Read-Host "Please enter the new interval in minutes (minimum 10):")
                if ($newInterval -ge 10) {
                    Write-LogMessage "New check interval set to $newInterval minutes." "green"
                    return $newInterval
                }
                else {
                    Write-LogMessage "Invalid interval entered. Using recommended value of 10 minutes." "yellow"
                    return 10
                }
            }
            else {
                Write-LogMessage "Using the recommended interval of 10 minutes." "yellow"
                return 10
            }
        }
        else {
            Write-LogMessage "User acknowledged the risk and chose to proceed." "yellow"
        }
    }

    return $interval
}