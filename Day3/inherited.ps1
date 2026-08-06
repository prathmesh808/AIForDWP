<#
.SYNOPSIS
    Endpoint Health Snapshot — reports key system metrics to the console.

.DESCRIPTION
    Collects and displays:
      - Computer name and total physical RAM
      - Free disk space on the C: drive
      - Top 5 processes by memory usage
      - Recent System event-log errors (last 10 events, Level 2 only)
      - Count of local user profiles inactive for more than 90 days

.AUTHOR
    Unknown (inherited script — refactored for readability)

.HOW TO RUN
    Run directly in an elevated PowerShell session:
        .\inherited.ps1

    No parameters required. Output is written to the console.

.NOTES
    Read-only: this script makes no changes to the system.
    Requires permission to read WMI, event logs, and process list.
#>

# Retrieve general computer system information (name, RAM, domain, etc.)
$computerSystem = Get-CimInstance Win32_ComputerSystem

# Get the number of free bytes remaining on the C: drive
$driveFreeByes = Get-PSDrive C | Select-Object -ExpandProperty Free

# Find the top 5 processes consuming the most memory (working set), largest first
$topMemoryProcesses = Get-Process | Sort-Object WS -Descending | Select-Object -First 5

# Read the last 10 System event-log entries and keep only errors (Level 2)
$systemErrors = Get-WinEvent -LogName System -MaxEvents 10 | Where-Object { $_.Level -eq 2 }

# Identify local user profiles that are not special/system accounts and unused for 90+ days
$staleUserProfiles = Get-CimInstance Win32_UserProfile | Where-Object {
    -not $_.Special -and $_.LastUseTime -lt (Get-Date).AddDays(-90)
}

# Display computer name and total physical memory in bytes
Write-Host $computerSystem.Name $computerSystem.TotalPhysicalMemory

# Display C: drive free space converted from bytes to GB, rounded to 2 decimal places
Write-Host ([math]::Round($driveFreeByes / 1GB, 2)) 'GB free'

# Display the name and memory usage (bytes) for each of the top 5 processes
$topMemoryProcesses | ForEach-Object { Write-Host $_.Name $_.WS }

# Display the timestamp and message for each System error event found
$systemErrors | ForEach-Object { Write-Host $_.TimeCreated $_.Message }

# If any stale profiles were found, report the total count
if ($staleUserProfiles.Count -gt 0) { Write-Host 'Stale profiles:' $staleUserProfiles.Count }
