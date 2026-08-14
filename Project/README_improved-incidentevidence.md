# improved-incidentevidence.ps1

Safe temporary-file cleanup script for Windows endpoints (PowerShell 5.1) with dry run, per-file error handling, logging, and rollback.

## What It Does
- Scans configured temp folders.
- Targets only files older than `-OlderThanDays` (default `0`).
- Skips locked files and logs them.
- Uses per-file `try/catch` so one failure does not stop the run.
- Logs every action to a timestamped log file.
- Produces a manifest CSV for full traceability.
- Supports rollback from manifest by restoring moved files.
- Idempotent behavior:
  - Running cleanup again safely processes only currently present files.
  - Running rollback again skips already restored files.

## Important Safety Behavior
This script **moves** files from source temp folders into a backup folder for the run, instead of permanent deletion, so rollback is possible.

## Parameters
- `-DryRun`
  - Lists files that would be cleaned, without moving/deleting anything.
- `-OlderThanDays <int>`
  - Cleans files older than this many days. Default is `0`.
- `-Rollback`
  - Runs rollback mode.
- `-RollbackManifest <path>`
  - Optional manifest path to restore from. If omitted, latest manifest is used.
- `-TargetPaths <string[]>`
  - Optional custom folders to scan.
- `-WorkingRoot <path>`
  - Optional root for logs, manifests, backups.

## Common Examples
- Dry run with defaults:
```powershell
powershell -ExecutionPolicy Bypass -File .\improved-incidentevidence.ps1 -DryRun
```

- Clean files older than 7 days:
```powershell
powershell -ExecutionPolicy Bypass -File .\improved-incidentevidence.ps1 -OlderThanDays 7
```

- Clean custom paths:
```powershell
powershell -ExecutionPolicy Bypass -File .\improved-incidentevidence.ps1 -OlderThanDays 3 -TargetPaths "C:\Temp","D:\AppTemp"
```

- Roll back latest run:
```powershell
powershell -ExecutionPolicy Bypass -File .\improved-incidentevidence.ps1 -Rollback
```

- Roll back from a specific manifest:
```powershell
powershell -ExecutionPolicy Bypass -File .\improved-incidentevidence.ps1 -Rollback -RollbackManifest "C:\Path\cleanup_manifest_20260814_101500.csv"
```

## Output Structure
Under `WorkingRoot` (default: `TempCleanupData`):
- `Logs\tempcleanup_<timestamp>.log`
- `Manifests\cleanup_manifest_<timestamp>.csv`
- `Backups\<operationId>\...moved files...`
- `Summaries\summary_cleanup_<operationId>.json`
- `Summaries\summary_cleanup_<operationId>.txt`
- `Summaries\summary_rollback_<timestamp>.json`
- `Summaries\summary_rollback_<timestamp>.txt`

## Structured Actionable Output
Each run now emits a structured handoff summary in both JSON and text formats.

- JSON summary is machine-readable for automation/handoff tooling.
- Text summary is operator-friendly and includes:
  - mode, duration, manifest path, backup path, and log path
  - counter totals (scanned, candidates, moved, locked, errors, etc.)
  - recommended next actions based on run outcome

This makes output actionable for another engineer without parsing raw status logs.

## Notes
- Run with elevated rights to maximize coverage of system temp paths.
- Rollback restores only files recorded as `Moved` in the manifest.
- Locked files are never forced; they are skipped and logged.
