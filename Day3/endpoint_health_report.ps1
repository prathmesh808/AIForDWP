<#
Endpoint Health Report (Read-Only)
PowerShell version target: 5.1

VERIFY BEFORE RUNNING:
1) Run with permissions that can read Event Logs and HKLM registry keys; standard user access may limit some sections.
2) Internet speed test uses an external download endpoint (default: https://speed.hetzner.de/10MB.bin).
    Verify external test URLs are allowed by your network/proxy and acceptable for your environment.
    You can override the default endpoint with -SpeedTestUrl if your environment requires an approved internal/external URL.
3) "Top 5 Processes by CPU" uses cumulative CPU seconds since process start, not instantaneous live CPU percentage.
4) "How many users logged in" is based on session data from quser when available.

This script is strictly read-only:
- No registry writes
- No service changes
- No file writes
- No configuration/system state changes
#>

[CmdletBinding()]
param(
    [string]$SpeedTestUrl = 'https://speed.hetzner.de/10MB.bin',
    [int]$SpeedTestTimeoutSeconds = 30
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Continue'

# Section 1: System uptime
# Reads OS last boot time and calculates current uptime duration.
function Get-SystemUptime {
    try {
        $os = Get-CimInstance -ClassName Win32_OperatingSystem
        $lastBoot = $os.LastBootUpTime
        $uptime = (Get-Date) - $lastBoot

        [pscustomobject]@{
            LastBootTime = $lastBoot
            UptimeDays   = [math]::Round($uptime.TotalDays, 2)
            Uptime       = ('{0}d {1}h {2}m' -f $uptime.Days, $uptime.Hours, $uptime.Minutes)
        }
    }
    catch {
        [pscustomobject]@{ Error = $_.Exception.Message }
    }
}

# Section 2: Free disk space
# Reads logical disk information for local fixed drives and reports size/free space in GB.
function Get-FreeDiskSpace {
    try {
        Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3" |
            Select-Object DeviceID,
                @{Name='SizeGB';Expression={ [math]::Round($_.Size / 1GB, 2) }},
                @{Name='FreeGB';Expression={ [math]::Round($_.FreeSpace / 1GB, 2) }},
                @{Name='FreePercent';Expression={ if ($_.Size -gt 0) { [math]::Round(($_.FreeSpace / $_.Size) * 100, 2) } else { $null } }}
    }
    catch {
        [pscustomobject]@{ Error = $_.Exception.Message }
    }
}

# Section 3: Pending reboot (registry checks)
# Reads known registry indicators that Windows uses to signal a pending reboot.
function Get-PendingRebootStatus {
    $checks = [ordered]@{
        'CBS_RebootPending' = Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending'
        'WU_RebootRequired' = Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired'
        'PendingFileRenameOperations' = $false
    }

    try {
        $sessionManager = Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager' -ErrorAction SilentlyContinue
        if ($null -ne $sessionManager -and $null -ne $sessionManager.PendingFileRenameOperations) {
            $checks['PendingFileRenameOperations'] = $true
        }
    }
    catch {
        # Keep default false if key/value cannot be read.
    }

    $isPending = $checks.Values -contains $true

    [pscustomobject]@{
        PendingReboot = $isPending
        Details       = [pscustomobject]$checks
    }
}

# Section 4: Top 5 processes by memory (Working Set)
# Reads running process list and sorts by WorkingSet64 descending.
function Get-TopMemoryProcesses {
    try {
        Get-Process |
            Sort-Object -Property WorkingSet64 -Descending |
            Select-Object -First 5 ProcessName, Id,
                @{Name='WorkingSetMB';Expression={ [math]::Round($_.WorkingSet64 / 1MB, 2) }}
    }
    catch {
        [pscustomobject]@{ Error = $_.Exception.Message }
    }
}

# Section 5: Top 5 processes by CPU
# Reads running process list and sorts by CPU time (seconds) descending.
function Get-TopCpuProcesses {
    try {
        Get-Process |
            ForEach-Object {
                [pscustomobject]@{
                    ProcessName = $_.ProcessName
                    Id          = $_.Id
                    CpuSeconds  = if ($null -ne $_.TotalProcessorTime) {
                        [math]::Round($_.TotalProcessorTime.TotalSeconds, 2)
                    }
                    else {
                        0
                    }
                }
            } |
            Sort-Object -Property CpuSeconds -Descending |
            Select-Object -First 5 ProcessName, Id, CpuSeconds
    }
    catch {
        [pscustomobject]@{ Error = $_.Exception.Message }
    }
}

# Section 6: Last 5 system log errors
# Reads the System event log for latest error-level events.
function Get-LastSystemErrors {
    try {
        Get-WinEvent -FilterHashtable @{ LogName = 'System'; Level = 2 } -MaxEvents 5 |
            Select-Object TimeCreated, Id, ProviderName,
                @{Name='Message';Expression={ ($_.Message -replace "`r`n", ' ') }}
    }
    catch {
        [pscustomobject]@{ Error = $_.Exception.Message }
    }
}

# Section 7: Internet speed
# Performs a read-only download stream test and calculates approximate Mbps.
function Get-InternetSpeedMbps {
    $candidateUrls = @(
        $SpeedTestUrl
        'https://speed.cloudflare.com/__down?bytes=10000000'
        'https://proof.ovh.net/files/10Mb.dat'
        'https://speedtest.tele2.net/10MB.zip'
    ) | Select-Object -Unique

    $attemptErrors = New-Object System.Collections.Generic.List[string]

    foreach ($candidateUrl in $candidateUrls) {
        try {
            $request = [System.Net.WebRequest]::Create($candidateUrl)
            $request.Method = 'GET'
            $request.Timeout = $SpeedTestTimeoutSeconds * 1000
            $request.ReadWriteTimeout = $SpeedTestTimeoutSeconds * 1000

            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            $response = $request.GetResponse()
            $stream = $response.GetResponseStream()

            try {
                $buffer = New-Object byte[] 8192
                [long]$totalBytes = 0

                while (($read = $stream.Read($buffer, 0, $buffer.Length)) -gt 0) {
                    $totalBytes += $read
                }
            }
            finally {
                if ($null -ne $stream) {
                    $stream.Close()
                }
                if ($null -ne $response) {
                    $response.Close()
                }
                $stopwatch.Stop()
            }

            if ($stopwatch.Elapsed.TotalSeconds -le 0) {
                throw 'Speed test duration was too short to calculate.'
            }

            $mbps = (($totalBytes * 8) / 1MB) / $stopwatch.Elapsed.TotalSeconds

            return [pscustomobject]@{
                Url             = $candidateUrl
                DownloadedMB    = [math]::Round($totalBytes / 1MB, 2)
                DurationSeconds = [math]::Round($stopwatch.Elapsed.TotalSeconds, 2)
                ApproxMbps      = [math]::Round($mbps, 2)
            }
        }
        catch {
            $attemptErrors.Add(($candidateUrl + ' -> ' + $_.Exception.Message))
        }
    }

    [pscustomobject]@{
        Error         = 'Unable to complete internet speed test using the configured endpoints.'
        AttemptedUrls = ($candidateUrls -join ', ')
        Details       = ($attemptErrors -join '; ')
    }
}

# Section 8: Microsoft Defender service status
# Reads WinDefend service status to determine whether Defender is running.
function Get-DefenderServiceStatus {
    try {
        $svc = Get-Service -Name 'WinDefend' -ErrorAction Stop
        [pscustomobject]@{
            ServiceName = $svc.Name
            DisplayName = $svc.DisplayName
            Status      = $svc.Status
            IsRunning   = ($svc.Status -eq 'Running')
        }
    }
    catch {
        [pscustomobject]@{ Error = "WinDefend service not found or inaccessible: $($_.Exception.Message)" }
    }
}

# Section 9: Number of logged-in users
# Reads current user session data and reports session count and unique usernames.
function Get-LoggedInUsers {
    try {
        $quserOutput = quser 2>$null
        if (-not $quserOutput) {
            throw 'quser returned no data.'
        }

        $lines = $quserOutput | Select-Object -Skip 1 | Where-Object { $_ -match '\S' }
        $parsedUsers = @()

        foreach ($line in $lines) {
            $clean = $line.TrimStart('>',' ')
            $username = ($clean -split '\s+')[0]
            if ($username) {
                $parsedUsers += $username
            }
        }

        $uniqueUsers = $parsedUsers | Sort-Object -Unique

        [pscustomobject]@{
            SessionCount    = $parsedUsers.Count
            UniqueUserCount = $uniqueUsers.Count
            Users           = ($uniqueUsers -join ', ')
        }
    }
    catch {
        # Fallback: may only expose the currently logged-on interactive user.
        try {
            $current = (Get-CimInstance Win32_ComputerSystem).UserName
            $count = if ([string]::IsNullOrWhiteSpace($current)) { 0 } else { 1 }
            [pscustomobject]@{
                SessionCount    = $count
                UniqueUserCount = $count
                Users           = $current
                Note            = 'Fallback method used; session detail unavailable.'
            }
        }
        catch {
            [pscustomobject]@{ Error = $_.Exception.Message }
        }
    }
}

# Section 10: Last Windows Update time
# Reads latest successful Windows Update install event; falls back to most recent hotfix date.
function Get-LastWindowsUpdate {
    try {
        $event = Get-WinEvent -FilterHashtable @{
            LogName      = 'System'
            ProviderName = 'Microsoft-Windows-WindowsUpdateClient'
            Id           = 19
        } -MaxEvents 1 -ErrorAction Stop

        [pscustomobject]@{
            Source      = 'WindowsUpdateClient Event ID 19'
            TimeCreated = $event.TimeCreated
            Message     = ($event.Message -replace "`r`n", ' ')
        }
    }
    catch {
        try {
            $hotfix = Get-HotFix | Where-Object { $_.InstalledOn } | Sort-Object InstalledOn -Descending | Select-Object -First 1
            if ($null -eq $hotfix) {
                throw 'No hotfix installation data available.'
            }

            [pscustomobject]@{
                Source      = 'Get-HotFix fallback'
                TimeCreated = $hotfix.InstalledOn
                Message     = "HotFixID: $($hotfix.HotFixID); Description: $($hotfix.Description)"
            }
        }
        catch {
            [pscustomobject]@{ Error = $_.Exception.Message }
        }
    }
}

# Report execution
# Calls each read-only section function and prints a structured endpoint health report.
Write-Host "============================================================"
Write-Host "Endpoint Health Report (Read-Only)"
Write-Host "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host "Computer:  $env:COMPUTERNAME"
Write-Host "============================================================"

Write-Host "`n1) System Uptime"
Get-SystemUptime | Format-List

Write-Host "`n2) Free Disk Space"
Get-FreeDiskSpace | Format-Table -AutoSize

Write-Host "`n3) Pending Reboot (Registry)"
Get-PendingRebootStatus | Format-List

Write-Host "`n4) Top 5 Processes by Memory (Working Set)"
Get-TopMemoryProcesses | Format-Table -AutoSize

Write-Host "`n5) Top 5 Processes by CPU"
Get-TopCpuProcesses | Format-Table -AutoSize

Write-Host "`n6) Last 5 System Log Errors"
Get-LastSystemErrors | Format-Table -Wrap -AutoSize

Write-Host "`n7) Internet Speed"
Get-InternetSpeedMbps | Format-List

Write-Host "`n8) Microsoft Defender Service Status"
Get-DefenderServiceStatus | Format-List

Write-Host "`n9) Logged-In User Count"
Get-LoggedInUsers | Format-List

Write-Host "`n10) Last Windows Update"
Get-LastWindowsUpdate | Format-List

Write-Host "`nReport completed. No system changes were made by this script."
