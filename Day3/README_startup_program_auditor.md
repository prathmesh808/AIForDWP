# Startup Program Auditor (PowerShell 5.1)

This script helps a DWP engineer audit startup programs and optionally disable matching entries safely.

Script location:
- Day3/startup_program_auditor.ps1

## Safety Model

- Default mode is dry run (read-only listing).
- Disable mode only moves startup entries to DWP-disabled locations.
- It does not delete startup entries.
- Re-running disable with the same filter is idempotent (already-disabled items are skipped).

## Verify Before Running

1. Run as Administrator if you need to disable machine-wide startup entries (HKLM / All Users).
2. Confirm your -ProgramName filter is specific enough to avoid unintended matches.
3. Confirm endpoint policy allows startup entry modifications.
4. If you only need reporting, run with -DryRun (or no flags).

## Options

- -DryRun
  - Lists startup programs from:
    - HKCU Run key
    - HKLM Run keys (native + WOW6432Node)
    - Current user Startup folder
    - All users Startup folder
  - Also lists items already disabled by this script.

- -Disable
  - Enables disable mode.
  - Must be used with -ProgramName.

- -ProgramName <string>
  - Name filter used in disable mode.
  - Match is case-insensitive and uses contains-style wildcard matching against startup item name and command/path.

## Examples

Dry run (default behavior):

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "c:\Users\labuser\Documents\Training\Day3\startup_program_auditor.ps1"
```

Explicit dry run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "c:\Users\labuser\Documents\Training\Day3\startup_program_auditor.ps1" -DryRun
```

Disable startup entries matching "Teams":

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "c:\Users\labuser\Documents\Training\Day3\startup_program_auditor.ps1" -Disable -ProgramName "Teams"
```

## Idempotency Notes

- Registry startup entries are moved from Run to Run-Disabled-DWPAuditor.
- Startup folder entries are moved into Startup-Disabled-DWPAuditor.
- If an item is already in the disabled location, the script skips it and reports that status.
