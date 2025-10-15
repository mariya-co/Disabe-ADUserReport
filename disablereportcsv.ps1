# CSV report version, same logic as the html script but outs to a csv instead.
$csvPath = "C:\Users\Administrator\Desktop\disabled\disabled.csv"
$csvOutputPath = "C:\Users\Administrator\Desktop\disabled\disablereport.html"
$users = Import-Csv -Path $csvPath -ErrorAction Stop

# Intialise generic list to store log entries
$logList = [System.Collections.Generic.List[PSObject]]::new()

foreach ($row in $users) {
    $username = ($row.SAMAccountName)

    # Get AD User, check if it's enabled, disable if so, log results to the list
    try {
        $adUser = Get-ADUser -Identity $username -ErrorAction Stop
        
        if (!$adUser.Enabled) {
            $logList.Add([PSCustomObject]@{
                Name     = $adUser.Name
                Username = $username
                Action   = 'Checked'
                Result   = "User '$username' already disabled."
                Status   = 'Warning'
            })
            continue
        }
        Disable-ADAccount -Identity $username -ErrorAction Stop
        $logList.Add([PSCustomObject]@{
            Name     = $adUser.Name
            Username = $username
            Action   = 'Disable'
            Result   = "User '$username' disabled."
            Status   = 'Success'
        })
    }
    catch {
        $logList.Add([PSCustomObject]@{
            Name     = $adUser.Name
            Username = $username
            Action   = 'Disable'
            Result   = "Failed to disable user '$username'. Error: $($_.Exception.Message)"
            Status   = 'Error'
        })
    }
}

# Out to a CSV, write path in terminal for ease of access
$logList | Export-CSV -Path $csvOutputPath -NoTypeInformation -Encoding UTF8
Write-Host "CSV report saved to $csvOutputPath"
