#requires -Version 5.1
<#
.SYNOPSIS
Safely cleans temporary files on Windows endpoints with dry-run and rollback support.

.DESCRIPTION
- Targets temp locations and only processes files older than -OlderThanDays.
- Dry run mode lists candidate files without changing anything.
- Skips locked files and logs the error without stopping.
- Uses per-file try/catch so one failure does not stop the run.
- Logs every action to a timestamped log file.
- Creates a manifest for rollback.
- Idempotent behavior: re-running cleanup or rollback is safe.

.NOTES
PowerShell version: 5.1
#>

[CmdletBinding()]
param(
    # Show files that would be cleaned without moving/deleting anything.
    [switch]$DryRun,

    # Only process files older than this number of days. Default is 0.
    [ValidateRange(0, 3650)]
    [int]$OlderThanDays = 0,

    # Run rollback mode to restore files from a previous manifest.
    [switch]$Rollback,

    # Optional manifest path for rollback. If omitted, latest manifest is used.
    [string]$RollbackManifest,

    # Optional custom target paths. Defaults to common temp folders.
    [string[]]$TargetPaths = @(
        "$env:TEMP",
        "$env:WINDIR\Temp",
        "$env:LOCALAPPDATA\Temp"
    ),

    # Working folder for logs, manifests, and rollback backups.
    [string]$WorkingRoot = "$PSScriptRoot\TempCleanupData"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ------------------------------
# Section: Setup folders and log file
# Creates stable folder structure for logs/manifests/backups.
# ------------------------------
$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$logsDir = Join-Path $WorkingRoot 'Logs'
$manifestsDir = Join-Path $WorkingRoot 'Manifests'
$backupsDir = Join-Path $WorkingRoot 'Backups'

New-Item -Path $WorkingRoot -ItemType Directory -Force | Out-Null
New-Item -Path $logsDir -ItemType Directory -Force | Out-Null
New-Item -Path $manifestsDir -ItemType Directory -Force | Out-Null
New-Item -Path $backupsDir -ItemType Directory -Force | Out-Null

$logPath = Join-Path $logsDir ("tempcleanup_{0}.log" -f $timestamp)

# ------------------------------
# Section: Logging helper
# Writes every action to console and log file with timestamp and level.
# ------------------------------
function Write-Log {
    param(
        [Parameter(Mandatory=$true)][string]$Message,
        [ValidateSet('INFO','WARN','ERROR')][string]$Level = 'INFO'
    )

    $line = "[{0}] [{1}] {2}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Level, $Message
    Write-Host $line
    Add-Content -Path $logPath -Value $line
}

# ------------------------------
# Section: Locked file detector
# Attempts exclusive file open; if it fails, file is treated as locked.
# ------------------------------
function Test-FileLocked {
    param([Parameter(Mandatory=$true)][string]$Path)

    try {
        $fs = [System.IO.File]::Open($Path, 'Open', 'ReadWrite', 'None')
        $fs.Close()
        return $false
    }
    catch {
        return $true
    }
}

# ------------------------------
# Section: Normalize target paths
# Expands env vars, removes duplicates, and keeps only existing paths.
# ------------------------------
function Resolve-TargetPaths {
    param([string[]]$Paths)

    $resolved = @()
    foreach ($p in $Paths) {
        if ([string]::IsNullOrWhiteSpace($p)) { continue }
        $expanded = [Environment]::ExpandEnvironmentVariables($p)
        if (Test-Path -LiteralPath $expanded) {
            $resolved += (Resolve-Path -LiteralPath $expanded).Path
        }
    }

    return $resolved | Sort-Object -Unique
}

# ------------------------------
# Section: Load latest manifest for rollback
# Picks latest manifest if user did not provide one.
# ------------------------------
function Get-LatestManifestPath {
    param([string]$Dir)

    $latest = Get-ChildItem -Path $Dir -Filter '*.csv' -File -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1

    if ($null -eq $latest) {
        return $null
    }

    return $latest.FullName
}

# ------------------------------
# Section: Rollback mode
# Restores files from a prior cleanup run using manifest records.
# Idempotent: skips files already restored or missing backup payload.
# ------------------------------
if ($Rollback) {
    $manifestPath = $RollbackManifest
    if ([string]::IsNullOrWhiteSpace($manifestPath)) {
        $manifestPath = Get-LatestManifestPath -Dir $manifestsDir
    }

    if ([string]::IsNullOrWhiteSpace($manifestPath) -or -not (Test-Path -LiteralPath $manifestPath)) {
        Write-Log -Level 'ERROR' -Message 'Rollback requested but no valid manifest file was found.'
        exit 1
    }

    Write-Log -Message ("Rollback mode started using manifest: {0}" -f $manifestPath)

    $rows = Import-Csv -Path $manifestPath
    $restored = 0
    $skipped = 0
    $failed = 0

    foreach ($row in $rows) {
        # Only moved files are rollback candidates.
        if ($row.Status -ne 'Moved') {
            $skipped++
            Write-Log -Level 'WARN' -Message ("Skip row with Status={0} for {1}" -f $row.Status, $row.OriginalPath)
            continue
        }

        try {
            if (Test-Path -LiteralPath $row.OriginalPath) {
                # Idempotency: file already restored.
                $skipped++
                Write-Log -Message ("Already present, skip restore: {0}" -f $row.OriginalPath)
                continue
            }

            if (-not (Test-Path -LiteralPath $row.BackupPath)) {
                $failed++
                Write-Log -Level 'ERROR' -Message ("Backup payload missing, cannot restore: {0}" -f $row.BackupPath)
                continue
            }

            $parent = Split-Path -Parent $row.OriginalPath
            if (-not (Test-Path -LiteralPath $parent)) {
                New-Item -Path $parent -ItemType Directory -Force | Out-Null
            }

            Move-Item -LiteralPath $row.BackupPath -Destination $row.OriginalPath -Force
            $restored++
            Write-Log -Message ("Restored: {0}" -f $row.OriginalPath)
        }
        catch {
            $failed++
            Write-Log -Level 'ERROR' -Message ("Rollback failed for {0} :: {1}" -f $row.OriginalPath, $_.Exception.Message)
        }
    }

    Write-Log -Message ("Rollback summary -> Restored: {0}, Skipped: {1}, Failed: {2}" -f $restored, $skipped, $failed)
    exit 0
}

# ------------------------------
# Section: Cleanup mode
# Collects candidate files and either lists (dry run) or moves them to backup.
# Moving (not permanent delete) enables rollback.
# ------------------------------
$operationId = Get-Date -Format 'yyyyMMdd_HHmmss'
$operationBackupDir = Join-Path $backupsDir $operationId
New-Item -Path $operationBackupDir -ItemType Directory -Force | Out-Null

$manifestPathOut = Join-Path $manifestsDir ("cleanup_manifest_{0}.csv" -f $operationId)
$manifestRows = New-Object System.Collections.Generic.List[object]

$resolvedTargets = Resolve-TargetPaths -Paths $TargetPaths
if ($resolvedTargets.Count -eq 0) {
    Write-Log -Level 'WARN' -Message 'No valid target paths found. Nothing to do.'
    exit 0
}

Write-Log -Message ("Cleanup mode started. DryRun={0}, OlderThanDays={1}" -f [bool]$DryRun, $OlderThanDays)
Write-Log -Message ("Targets: {0}" -f ($resolvedTargets -join '; '))

$cutoff = (Get-Date).AddDays(-1 * $OlderThanDays)
$scanned = 0
$candidates = 0
$moved = 0
$locked = 0
$errors = 0
$dryRunCount = 0

foreach ($target in $resolvedTargets) {
    Write-Log -Message ("Scanning target: {0}" -f $target)

    $files = Get-ChildItem -LiteralPath $target -File -Recurse -Force -ErrorAction SilentlyContinue

    foreach ($file in $files) {
        $scanned++

        if ($file.LastWriteTime -gt $cutoff) {
            continue
        }

        $candidates++

        # Per-file error handling by design.
        try {
            if ($DryRun) {
                $dryRunCount++
                Write-Log -Message ("DRYRUN would clean: {0}" -f $file.FullName)
                $manifestRows.Add([pscustomobject]@{
                    OperationId   = $operationId
                    Timestamp     = (Get-Date).ToString('o')
                    OriginalPath  = $file.FullName
                    BackupPath    = ''
                    LastWriteTime = $file.LastWriteTime.ToString('o')
                    Status        = 'DryRun'
                    Error         = ''
                }) | Out-Null
                continue
            }

            if (Test-FileLocked -Path $file.FullName) {
                $locked++
                Write-Log -Level 'WARN' -Message ("Locked file skipped: {0}" -f $file.FullName)
                $manifestRows.Add([pscustomobject]@{
                    OperationId   = $operationId
                    Timestamp     = (Get-Date).ToString('o')
                    OriginalPath  = $file.FullName
                    BackupPath    = ''
                    LastWriteTime = $file.LastWriteTime.ToString('o')
                    Status        = 'LockedSkipped'
                    Error         = 'File is locked'
                }) | Out-Null
                continue
            }

            # Move to backup to preserve rollback capability.
            $backupName = "{0}{1}" -f ([guid]::NewGuid().ToString('N')), $file.Extension
            $backupPath = Join-Path $operationBackupDir $backupName

            Move-Item -LiteralPath $file.FullName -Destination $backupPath -Force
            $moved++
            Write-Log -Message ("Moved for cleanup: {0} -> {1}" -f $file.FullName, $backupPath)

            $manifestRows.Add([pscustomobject]@{
                OperationId   = $operationId
                Timestamp     = (Get-Date).ToString('o')
                OriginalPath  = $file.FullName
                BackupPath    = $backupPath
                LastWriteTime = $file.LastWriteTime.ToString('o')
                Status        = 'Moved'
                Error         = ''
            }) | Out-Null
        }
        catch {
            $errors++
            $msg = $_.Exception.Message
            Write-Log -Level 'ERROR' -Message ("Failed file: {0} :: {1}" -f $file.FullName, $msg)

            $manifestRows.Add([pscustomobject]@{
                OperationId   = $operationId
                Timestamp     = (Get-Date).ToString('o')
                OriginalPath  = $file.FullName
                BackupPath    = ''
                LastWriteTime = $file.LastWriteTime.ToString('o')
                Status        = 'Error'
                Error         = $msg
            }) | Out-Null
        }
    }
}

# ------------------------------
# Section: Persist manifest and print summary
# Saves all per-file actions and prints final totals.
# ------------------------------
$manifestRows | Export-Csv -Path $manifestPathOut -NoTypeInformation -Encoding UTF8 -Force

Write-Log -Message ("Manifest saved: {0}" -f $manifestPathOut)
Write-Log -Message ("Summary -> Scanned: {0}, Candidates: {1}, DryRunListed: {2}, Moved: {3}, LockedSkipped: {4}, Errors: {5}" -f $scanned, $candidates, $dryRunCount, $moved, $locked, $errors)
Write-Log -Message ("Log file: {0}" -f $logPath)
Write-Log -Message ("Backup folder for this run: {0}" -f $operationBackupDir)
