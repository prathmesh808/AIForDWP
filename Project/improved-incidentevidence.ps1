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
$summariesDir = Join-Path $WorkingRoot 'Summaries'

New-Item -Path $WorkingRoot -ItemType Directory -Force | Out-Null
New-Item -Path $logsDir -ItemType Directory -Force | Out-Null
New-Item -Path $manifestsDir -ItemType Directory -Force | Out-Null
New-Item -Path $backupsDir -ItemType Directory -Force | Out-Null
New-Item -Path $summariesDir -ItemType Directory -Force | Out-Null

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
# Section: Structured summary writer
# Emits machine-readable JSON and a readable action summary for handoff.
# ------------------------------
function Write-StructuredSummary {
    param(
        [Parameter(Mandatory=$true)][ValidateSet('Cleanup','Rollback')][string]$Mode,
        [Parameter(Mandatory=$true)][string]$SummaryId,
        [Parameter(Mandatory=$true)][datetime]$StartedAtUtc,
        [Parameter(Mandatory=$true)][datetime]$EndedAtUtc,
        [Parameter(Mandatory=$true)][string]$WorkingRoot,
        [Parameter(Mandatory=$true)][string]$LogPath,
        [string]$ManifestPath,
        [string]$BackupPath,
        [int]$Scanned = 0,
        [int]$Candidates = 0,
        [int]$DryRunListed = 0,
        [int]$Moved = 0,
        [int]$LockedSkipped = 0,
        [int]$Restored = 0,
        [int]$Skipped = 0,
        [int]$Failed = 0,
        [int]$Errors = 0,
        [bool]$DryRun = $false,
        [int]$OlderThanDays = 0,
        [string[]]$ResolvedTargets = @()
    )

    $recommendedActions = New-Object System.Collections.Generic.List[string]

    if ($Mode -eq 'Cleanup') {
        if ($DryRun) {
            $recommendedActions.Add('Review DryRun rows in the manifest, then run again without -DryRun when approved.') | Out-Null
        }
        if ($Errors -gt 0) {
            $recommendedActions.Add('Open the manifest and filter Status = Error, then remediate paths or permissions before rerun.') | Out-Null
        }
        if ($LockedSkipped -gt 0) {
            $recommendedActions.Add('Close file handles or restart affected apps/endpoints, then rerun cleanup for locked files.') | Out-Null
        }
        if ($Moved -gt 0) {
            $recommendedActions.Add('Retain manifest and backup folder for rollback window; validate user-facing app behavior.') | Out-Null
        }
        if ($Candidates -eq 0) {
            $recommendedActions.Add('No eligible files found; adjust -OlderThanDays or target paths if cleanup was expected.') | Out-Null
        }
    }
    else {
        if ($Failed -gt 0) {
            $recommendedActions.Add('Investigate failed restore rows and recover missing backup payloads before rerun.') | Out-Null
        }
        if ($Restored -gt 0) {
            $recommendedActions.Add('Validate restored application behavior and confirm incident closure evidence.') | Out-Null
        }
        if ($Skipped -gt 0) {
            $recommendedActions.Add('Skipped rows are expected for idempotency/non-moved rows; review only if unexpected.') | Out-Null
        }
    }

    if ($recommendedActions.Count -eq 0) {
        $recommendedActions.Add('No immediate follow-up actions required.') | Out-Null
    }

    $summary = [pscustomobject]@{
        SummaryId           = $SummaryId
        Mode                = $Mode
        StartedAtUtc        = $StartedAtUtc.ToString('o')
        EndedAtUtc          = $EndedAtUtc.ToString('o')
        DurationSeconds     = [math]::Round(($EndedAtUtc - $StartedAtUtc).TotalSeconds, 2)
        WorkingRoot         = $WorkingRoot
        LogPath             = $LogPath
        ManifestPath        = $ManifestPath
        BackupPath          = $BackupPath
        DryRun              = $DryRun
        OlderThanDays       = $OlderThanDays
        Targets             = $ResolvedTargets
        Counters            = [pscustomobject]@{
            Scanned         = $Scanned
            Candidates      = $Candidates
            DryRunListed    = $DryRunListed
            Moved           = $Moved
            LockedSkipped   = $LockedSkipped
            Restored        = $Restored
            Skipped         = $Skipped
            Failed          = $Failed
            Errors          = $Errors
        }
        RecommendedActions  = $recommendedActions
    }

    $summaryJsonPath = Join-Path $summariesDir ("summary_{0}.json" -f $SummaryId)
    $summaryTxtPath = Join-Path $summariesDir ("summary_{0}.txt" -f $SummaryId)

    $summary | ConvertTo-Json -Depth 6 | Set-Content -Path $summaryJsonPath -Encoding UTF8

    $actionLines = @()
    $actionLines += "ACTION SUMMARY"
    $actionLines += "Mode: $Mode"
    $actionLines += "SummaryId: $SummaryId"
    $actionLines += "DurationSeconds: $([math]::Round(($EndedAtUtc - $StartedAtUtc).TotalSeconds, 2))"
    $actionLines += "ManifestPath: $ManifestPath"
    $actionLines += "BackupPath: $BackupPath"
    $actionLines += "LogPath: $LogPath"
    $actionLines += "Counters: Scanned=$Scanned; Candidates=$Candidates; DryRunListed=$DryRunListed; Moved=$Moved; LockedSkipped=$LockedSkipped; Restored=$Restored; Skipped=$Skipped; Failed=$Failed; Errors=$Errors"
    $actionLines += "RecommendedActions:"
    foreach ($action in $recommendedActions) {
        $actionLines += "- $action"
    }

    $actionLines | Set-Content -Path $summaryTxtPath -Encoding UTF8

    Write-Log -Message ("Structured summary JSON: {0}" -f $summaryJsonPath)
    Write-Log -Message ("Structured summary text: {0}" -f $summaryTxtPath)

    Write-Host ''
    Write-Host '===== ACTION SUMMARY ====='
    foreach ($line in $actionLines) {
        Write-Host $line
    }

    return $summary
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
    $rollbackStartUtc = (Get-Date).ToUniversalTime()
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

    $null = Write-StructuredSummary -Mode 'Rollback' `
        -SummaryId ("rollback_{0}" -f $timestamp) `
        -StartedAtUtc $rollbackStartUtc `
        -EndedAtUtc ((Get-Date).ToUniversalTime()) `
        -WorkingRoot $WorkingRoot `
        -LogPath $logPath `
        -ManifestPath $manifestPath `
        -BackupPath '' `
        -Restored $restored `
        -Skipped $skipped `
        -Failed $failed

    exit 0
}

# ------------------------------
# Section: Cleanup mode
# Collects candidate files and either lists (dry run) or moves them to backup.
# Moving (not permanent delete) enables rollback.
# ------------------------------
$cleanupStartUtc = (Get-Date).ToUniversalTime()
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

$null = Write-StructuredSummary -Mode 'Cleanup' `
    -SummaryId ("cleanup_{0}" -f $operationId) `
    -StartedAtUtc $cleanupStartUtc `
    -EndedAtUtc ((Get-Date).ToUniversalTime()) `
    -WorkingRoot $WorkingRoot `
    -LogPath $logPath `
    -ManifestPath $manifestPathOut `
    -BackupPath $operationBackupDir `
    -Scanned $scanned `
    -Candidates $candidates `
    -DryRunListed $dryRunCount `
    -Moved $moved `
    -LockedSkipped $locked `
    -Errors $errors `
    -DryRun ([bool]$DryRun) `
    -OlderThanDays $OlderThanDays `
    -ResolvedTargets $resolvedTargets
