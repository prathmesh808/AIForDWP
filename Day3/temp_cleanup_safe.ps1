<#
.SYNOPSIS
Safely cleans up temporary files on Windows endpoints.

.DESCRIPTION
This script deletes (or dry-runs) temporary files older than a specified age.
It supports per-file error handling, skips locked files, writes detailed logs,
and supports rollback by moving files to a backup location before deletion.

.NOTES
- Built for Windows PowerShell 5.1.
- Designed to be safe and idempotent.
#>

[CmdletBinding()]
param(
    # Target paths to clean. Defaults to common temp locations.
    [Parameter()]
    [string[]]$Paths = @($env:TEMP, 'C:\Windows\Temp'),

    # Minimum file age in days. 0 means all files older than now.
    [Parameter()]
    [ValidateRange(0, 36500)]
    [int]$OlderThanDays = 0,

    # When set, the script only reports files that would be cleaned.
    [Parameter()]
    [switch]$DryRun,

    # Root folder used to store rollback backups and manifests.
    [Parameter()]
    [string]$BackupRoot = "$env:ProgramData\DWP\TempCleanup\Backup",

    # Root folder used to store execution logs.
    [Parameter()]
    [string]$LogRoot = "$env:ProgramData\DWP\TempCleanup\Logs",

    # Perform rollback from a previous manifest instead of cleanup.
    [Parameter()]
    [switch]$Rollback,

    # Manifest file to use during rollback. Required with -Rollback.
    [Parameter()]
    [string]$ManifestPath,

    # If set, backup files are permanently deleted after successful move.
    [Parameter()]
    [switch]$PurgeBackupAfterMove
)

# Section: Strict safety settings and common preferences.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Section: Prepare timestamped run metadata and folders.
$runTimestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$runId = [guid]::NewGuid().ToString()

if (-not (Test-Path -LiteralPath $LogRoot)) {
    New-Item -Path $LogRoot -ItemType Directory -Force | Out-Null
}
if (-not (Test-Path -LiteralPath $BackupRoot)) {
    New-Item -Path $BackupRoot -ItemType Directory -Force | Out-Null
}

$logFile = Join-Path $LogRoot ("TempCleanup_{0}_{1}.log" -f $runTimestamp, $runId)

# Section: Logging helper to ensure every action is recorded and printed.
function Write-Log {
    param(
        [Parameter(Mandatory = $true)][string]$Message,
        [Parameter()][ValidateSet('INFO', 'WARN', 'ERROR')][string]$Level = 'INFO'
    )

    $stamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'
    $line = "[{0}] [{1}] {2}" -f $stamp, $Level, $Message
    Add-Content -LiteralPath $logFile -Value $line
    Write-Host $line
}

# Section: Converts paths to stable hash names for collision-safe backup storage.
function Get-PathHash {
    param(
        [Parameter(Mandatory = $true)][string]$InputPath
    )

    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($InputPath.ToLowerInvariant())
        $hashBytes = $sha.ComputeHash($bytes)
        return ([BitConverter]::ToString($hashBytes)).Replace('-', '')
    }
    finally {
        if ($sha) { $sha.Dispose() }
    }
}

# Section: Builds a backup path that preserves source identity and enables rollback.
function New-BackupFilePath {
    param(
        [Parameter(Mandatory = $true)][string]$OriginalPath,
        [Parameter(Mandatory = $true)][string]$BackupFolder
    )

    $fileName = [System.IO.Path]::GetFileName($OriginalPath)
    $ext = [System.IO.Path]::GetExtension($fileName)
    $baseName = if ([string]::IsNullOrWhiteSpace($ext)) { $fileName } else { $fileName.Substring(0, $fileName.Length - $ext.Length) }
    $pathHash = Get-PathHash -InputPath $OriginalPath

    $safeFileName = "{0}_{1}{2}" -f $baseName, $pathHash.Substring(0, 16), $ext
    return (Join-Path $BackupFolder $safeFileName)
}

# Section: Finds the newest manifest in backup storage for simplified rollback.
function Get-LatestManifestPath {
    param(
        [Parameter(Mandatory = $true)][string]$BackupFolderRoot
    )

    if (-not (Test-Path -LiteralPath $BackupFolderRoot)) {
        return $null
    }

    $latestManifest = Get-ChildItem -LiteralPath $BackupFolderRoot -Filter 'manifest_*.csv' -File -Recurse -ErrorAction SilentlyContinue |
        Sort-Object -Property LastWriteTime -Descending |
        Select-Object -First 1

    if ($latestManifest) {
        return $latestManifest.FullName
    }

    return $null
}

# Section: Attempts rollback from a manifest and logs each restore outcome.
function Invoke-Rollback {
    param(
        [Parameter(Mandatory = $true)][string]$Manifest,
        [Parameter(Mandatory = $true)][switch]$PurgeBackup
    )

    Write-Log -Message "Rollback mode requested. Manifest: $Manifest"

    if (-not (Test-Path -LiteralPath $Manifest)) {
        throw "Manifest not found: $Manifest"
    }

    $entries = @(Import-Csv -LiteralPath $Manifest)
    if ($entries.Count -eq 0) {
        Write-Log -Message "Manifest is empty. Nothing to rollback." -Level 'WARN'
        return
    }

    $restored = 0
    $skipped = 0
    $errors = 0

    foreach ($entry in $entries) {
        $source = $entry.OriginalPath
        $backup = $entry.BackupPath

        try {
            if (Test-Path -LiteralPath $source) {
                Write-Log -Message "Original file already exists, skipping restore: $source" -Level 'WARN'
                $skipped++
                continue
            }

            if (-not (Test-Path -LiteralPath $backup)) {
                Write-Log -Message "Backup file missing, skipping restore: $backup" -Level 'WARN'
                $skipped++
                continue
            }

            $sourceParent = Split-Path -Path $source -Parent
            if (-not (Test-Path -LiteralPath $sourceParent)) {
                New-Item -Path $sourceParent -ItemType Directory -Force | Out-Null
            }

            Move-Item -LiteralPath $backup -Destination $source -Force -ErrorAction Stop
            Write-Log -Message "Restored: $source"
            $restored++

            if ($PurgeBackup.IsPresent) {
                if (Test-Path -LiteralPath $backup) {
                    Remove-Item -LiteralPath $backup -Force -ErrorAction Stop
                }
            }
        }
        catch {
            $errors++
            Write-Log -Message ("Rollback failed for '{0}': {1}" -f $source, $_.Exception.Message) -Level 'ERROR'
            continue
        }
    }

    Write-Log -Message ("Rollback summary: Restored={0}, Skipped={1}, Errors={2}" -f $restored, $skipped, $errors)
}

# Section: Main cleanup workflow with per-file try/catch and summary tracking.
$summary = [ordered]@{
    RunId            = $runId
    DryRun           = [bool]$DryRun
    OlderThanDays    = $OlderThanDays
    PathsRequested   = $Paths.Count
    PathsScanned     = 0
    CandidateFiles   = 0
    DeletedFiles     = 0
    DryRunListed     = 0
    LockedSkipped    = 0
    MissingSkipped   = 0
    AccessDenied     = 0
    OtherErrors      = 0
}

try {
    Write-Log -Message "Starting script. DryRun=$DryRun OlderThanDays=$OlderThanDays Rollback=$Rollback"
    Write-Log -Message "Log file: $logFile"

    if ($Rollback) {
        if ([string]::IsNullOrWhiteSpace($ManifestPath)) {
            $ManifestPath = Get-LatestManifestPath -BackupFolderRoot $BackupRoot
            if ([string]::IsNullOrWhiteSpace($ManifestPath)) {
                throw ("Rollback requested but no manifest was provided and no manifest was found under BackupRoot: {0}" -f $BackupRoot)
            }

            Write-Log -Message ("No -ManifestPath provided. Using latest manifest: {0}" -f $ManifestPath) -Level 'WARN'
        }

        Invoke-Rollback -Manifest $ManifestPath -PurgeBackup:$PurgeBackupAfterMove
        Write-Log -Message 'Script completed in rollback mode.'
        return
    }

    $cutoff = (Get-Date).AddDays(-$OlderThanDays)
    Write-Log -Message "Cleanup cutoff date/time: $cutoff"

    $runBackupFolder = Join-Path $BackupRoot ("Backup_{0}_{1}" -f $runTimestamp, $runId)
    $manifestFile = Join-Path $runBackupFolder ("manifest_{0}_{1}.csv" -f $runTimestamp, $runId)

    if (-not $DryRun) {
        New-Item -Path $runBackupFolder -ItemType Directory -Force | Out-Null
        @() | Export-Csv -LiteralPath $manifestFile -NoTypeInformation
        Write-Log -Message "Backup folder: $runBackupFolder"
        Write-Log -Message "Manifest file: $manifestFile"
    }

    foreach ($path in $Paths) {
        if ([string]::IsNullOrWhiteSpace($path)) {
            continue
        }

        if (-not (Test-Path -LiteralPath $path)) {
            Write-Log -Message "Path not found, skipping: $path" -Level 'WARN'
            continue
        }

        $summary.PathsScanned++
        Write-Log -Message "Scanning path: $path"

        $files = @()
        try {
            $files = Get-ChildItem -LiteralPath $path -File -Recurse -Force -ErrorAction Stop |
                Where-Object { $_.LastWriteTime -lt $cutoff }
        }
        catch {
            $summary.OtherErrors++
            Write-Log -Message ("Failed to enumerate path '{0}': {1}" -f $path, $_.Exception.Message) -Level 'ERROR'
            continue
        }

        foreach ($file in $files) {
            $summary.CandidateFiles++

            if ($DryRun) {
                Write-Log -Message ("[DRY-RUN] Would delete: {0}" -f $file.FullName)
                $summary.DryRunListed++
                continue
            }

            try {
                if (-not (Test-Path -LiteralPath $file.FullName)) {
                    $summary.MissingSkipped++
                    Write-Log -Message ("File no longer exists, skipping: {0}" -f $file.FullName) -Level 'WARN'
                    continue
                }

                $backupPath = New-BackupFilePath -OriginalPath $file.FullName -BackupFolder $runBackupFolder

                # Move first (for rollback), then purge from backup if requested.
                Move-Item -LiteralPath $file.FullName -Destination $backupPath -Force -ErrorAction Stop

                [PSCustomObject]@{
                    OriginalPath = $file.FullName
                    BackupPath   = $backupPath
                    DeletedAt    = (Get-Date).ToString('o')
                    LastWriteTime = $file.LastWriteTime.ToString('o')
                    Length       = $file.Length
                    RunId        = $runId
                } | Export-Csv -LiteralPath $manifestFile -NoTypeInformation -Append

                if ($PurgeBackupAfterMove) {
                    Remove-Item -LiteralPath $backupPath -Force -ErrorAction Stop
                }

                Write-Log -Message ("Deleted: {0}" -f $file.FullName)
                $summary.DeletedFiles++
            }
            catch [System.UnauthorizedAccessException] {
                $summary.AccessDenied++
                Write-Log -Message ("Access denied for '{0}': {1}" -f $file.FullName, $_.Exception.Message) -Level 'WARN'
                continue
            }
            catch [System.IO.IOException] {
                $summary.LockedSkipped++
                Write-Log -Message ("Likely locked/in use, skipped '{0}': {1}" -f $file.FullName, $_.Exception.Message) -Level 'WARN'
                continue
            }
            catch {
                $summary.OtherErrors++
                Write-Log -Message ("Failed to process '{0}': {1}" -f $file.FullName, $_.Exception.Message) -Level 'ERROR'
                continue
            }
        }
    }
}
catch {
    Write-Log -Message ("Fatal error: {0}" -f $_.Exception.Message) -Level 'ERROR'
    throw
}
finally {
    # Section: Final summary output for operations reporting.
    Write-Log -Message '----- SUMMARY START -----'
    foreach ($key in $summary.Keys) {
        Write-Log -Message ("{0}: {1}" -f $key, $summary[$key])
    }
    if (-not $DryRun -and -not $Rollback) {
        Write-Log -Message 'For rollback, run this script with -Rollback -ManifestPath <manifest.csv>'
    }
    Write-Log -Message '----- SUMMARY END -----'
    Write-Host "`nSummary complete. Log file: $logFile"
}
