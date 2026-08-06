# DWP Temp Cleanup Script (PowerShell 5.1)

This folder contains a safe temp-file cleanup script for Windows endpoints:
- `temp_cleanup_safe.ps1`

The script is designed for operational safety:
- Supports dry-run mode (no deletion)
- Targets files older than a configurable number of days
- Skips locked files and continues processing
- Uses per-file try/catch handling
- Logs every action to a timestamped log file
- Produces a summary report
- Supports rollback via manifest + backup storage
- Is idempotent (repeat runs do not re-delete already removed files)

## Script Parameters

- `-Paths <string[]>`
  - One or more folders to scan recursively.
  - Default: `$env:TEMP`, `C:\Windows\Temp`

- `-OlderThanDays <int>`
  - Deletes only files with `LastWriteTime` older than this many days.
  - Default: `0`

- `-DryRun`
  - Shows the list of files that would be deleted.
  - No files are moved or deleted.

- `-BackupRoot <string>`
  - Root path where backup files and manifests are stored.
  - Default: `$env:ProgramData\DWP\TempCleanup\Backup`

- `-LogRoot <string>`
  - Root path where timestamped logs are written.
  - Default: `$env:ProgramData\DWP\TempCleanup\Logs`

- `-Rollback`
  - Runs rollback mode (restores files from backup).
  - Uses `-ManifestPath` when provided.
  - If omitted, script automatically uses the newest manifest under `-BackupRoot`.

- `-ManifestPath <string>`
  - CSV manifest created by a cleanup run.
  - Optional with `-Rollback` (recommended for explicit control).

- `-PurgeBackupAfterMove`
  - In cleanup mode: permanently removes backup copies after successful move (disables practical rollback).
  - In rollback mode: attempts to remove backup files after restore.

## Usage Examples

### 1) Dry run (list only)
```powershell
powershell.exe -ExecutionPolicy Bypass -File .\temp_cleanup_safe.ps1 -DryRun
```

### 2) Delete files older than 7 days in default temp paths
```powershell
powershell.exe -ExecutionPolicy Bypass -File .\temp_cleanup_safe.ps1 -OlderThanDays 7
```

### 3) Target a custom path
```powershell
powershell.exe -ExecutionPolicy Bypass -File .\temp_cleanup_safe.ps1 -Paths "C:\Temp", "$env:LOCALAPPDATA\Temp" -OlderThanDays 3
```

### 4) Rollback from a manifest
```powershell
powershell.exe -ExecutionPolicy Bypass -File .\temp_cleanup_safe.ps1 -Rollback -ManifestPath "C:\ProgramData\DWP\TempCleanup\Backup\Backup_20260805_101501_<run-id>\manifest_20260805_101501_<run-id>.csv"
```

### 5) Rollback using newest available manifest automatically
```powershell
powershell.exe -ExecutionPolicy Bypass -File .\temp_cleanup_safe.ps1 -Rollback
```

## Notes on Idempotency and Safety

- The script processes only files currently present at runtime.
- If re-run with the same settings, already moved/deleted files are not processed again.
- Locked/in-use files are skipped and logged; script continues without stopping.
- Each run creates a unique log and (non-dry-run) manifest for traceability.

## Recommended Operational Practice

1. Run with `-DryRun` first.
2. Run cleanup with an appropriate `-OlderThanDays` value.
3. Retain manifests for rollback audit/recovery.
4. Review the summary and log output after each run.
