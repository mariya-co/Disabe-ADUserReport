# Script to disable AD users from a CSV file and generate an HTML report of the results.

# Set paths for input and output
$csvPath = "C:\path\to\your\file.csv"
$htmlOutputPath = "C:\path\to\output.html"
$users = Import-Csv -Path $csvPath -ErrorAction Stop

# Initialise generic list to store log entries.
$logList = [System.Collections.Generic.List[PSObject]]::new()

foreach ($row in $users) {
    $username = ($row.SAMAccountName).Trim()

    # Check for empty entries in .csv file.
    if ([string]::IsNullOrWhiteSpace($username)) {
        $logList.Add([PSCustomObject]@{
            Name     = ''
            Username = ''
            Action   = 'Skipped'
            Result   = 'Empty username entry.'
            Status   = 'Warning'
        })
        continue
    }

    # Get AD User, check if it's enabled, disable it if so, log the results the list.
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

# HTML Report Generation
$htmlHead = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>AD Disable Results Report</title>
    <style>
        table { width: 100%; border-collapse: collapse; }
        th, td { padding: 8px 12px; border: 1px solid #aaa; text-align: left; }
        th { background-color: #f2f2f2; }
        .Success { background-color: #c8e6c9; }
        .Warning { background-color: #fff9c4; }
        .Error { background-color: #ffccbc; }
    </style>
</head>
<body>
    <h2>AD Disable Results Report</h2>
    <table>
        <tr>
            <th>Name</th>
            <th>Username</th>
            <th>Action</th>
            <th>Result</th>
            <th>Status</th>
        </tr>
"@
# Add entries from the log list to the HTML table.
$htmlRows = foreach ($entry in $logList) {
    "<tr class='$($entry.Status)'><td>$($entry.Name)</td><td>$($entry.Username)</td><td>$($entry.Action)</td><td>$($entry.Result)</td><td>$($entry.Status)</td></tr>"
}

$htmlFoot = @"
    </table>
</body>
</html>
"@

# Combine all parts of the HTML and save to file.
$htmlContent = $htmlHead + ($htmlRows -join "`n") + $htmlFoot
Set-Content -Path $htmlOutputPath -Value $htmlContent -Encoding UTF8

Write-Host "HTML report saved to $htmlOutputPath"
