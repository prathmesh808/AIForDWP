# KB: Finance Shared Drive S: Not Mapping - Intune SYSTEM Context Race Condition

**KB ID:** KB-L2L3-FIN-001  
**Version:** v1.0  
**Date:** 2026-08-10  
**Status:** Active  
**Audience:** L2/L3 DWP Engineers  
**Source Runbook:** Day5/runbook_finance_shared_drive_intune_system_context_20260807.md

## Background: what the system does and why it matter

Finance users require drive `S:` mapped to `\\finbridge-fs01\Finance` at logon for daily operations (shared files, templates, reporting packs, and team working folders).

The mapping is delivered by Intune Platform Script `Map-FinBridgeDrives.ps1`. If the script runs at the wrong time or wrong security context, the user session starts without `S:` and Finance workflows stop.

Why this matters:
- Finance impact is usually broad (many users sign in at the same time).
- Missing `S:` can look like a file server outage, but in this incident pattern the server is often healthy.
- Fast, correct diagnosis avoids unnecessary server/network escalation and restores service quickly.

## Symptom: what the engineer observers and what the user report

Engineer observes:
- Repeated incidents from Finance users on `DESKTOP-FB*` devices.
- `S:` is missing or inaccessible after sign-in.
- Intune script `Map-FinBridgeDrives.ps1` reports failure on affected devices.
- Issue is strongest during sign-in windows and may reproduce every logon.

User reports:
- "My S drive is missing."
- "I cannot open \\finbridge-fs01\Finance."
- "Manual mapping sometimes works after desktop loads."
- "Other users in Finance are seeing the same issue."

Typical error text:
- `Network name cannot be found` (Win32 error 53)

## Root cause: the specific technical cause with the evidence that confirms it

Specific technical cause:
- `Map-FinBridgeDrives.ps1` executes in Intune under `SYSTEM` context.
- Script runs before SMB client readiness (`LanmanWorkstation` service fully running) during logon.
- UNC access attempt to `\\finbridge-fs01\Finance` fails with error 53.
- Script exits non-zero (exit code 1), no retry, so `S:` is never mapped.

Evidence that confirms this root cause:
- IntuneManagementExtension log shows:
  - script start for `Map-FinBridgeDrives.ps1`
  - execution context as SYSTEM
  - UNC access failure and error 53
  - non-zero exit code (commonly 1)
- System log shows `Service Control Manager` Event ID `7036` (`Workstation` entered running state) after script failure timestamp.
- Optional corroboration: downstream event showing mapping consequence (`Ntfs` Event ID `98`, drive letter not assigned).
- GPO event processing remains normal (`GroupPolicy` Event ID `1500`), helping rule out "GPO failed" as primary cause.

## Detection: exactly how to confirm this is the issue before acting- include specific event ids, log locations and what to look for

Use this under-3-minute flow on one affected pilot device, then compare with one unaffected control device.

1. Run IME quick extract on the affected device (primary evidence)
- Log location: `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log`
- Run in PowerShell:

```powershell
$ime = 'C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log'
Get-Content $ime -Tail 2500 |
  Select-String -Pattern 'Map-FinBridgeDrives.ps1|SYSTEM|Network name cannot be found|Win32 error 53|exit code' |
  ForEach-Object { $_.Line }
```

- Expected result: recent lines show `Map-FinBridgeDrives.ps1`, execution in `SYSTEM` context, `Network name cannot be found` (Win32 error 53), and a non-zero `exit code`.

2. Pull required System events quickly from exact log
- Log location: `Event Viewer > Windows Logs > System`
- Run in PowerShell:

```powershell
$start = (Get-Date).AddHours(-4)
Get-WinEvent -FilterHashtable @{LogName='System'; Id=7036,1500,98; StartTime=$start} |
  Sort-Object TimeCreated |
  Select-Object TimeCreated, Id, ProviderName, Message |
  Format-Table -AutoSize
```

- Expected result:
  - Event ID `7036` from `Service Control Manager` confirms `Workstation` entered running state.
  - Event ID `1500` from `GroupPolicy` appears as normal processing.
  - Event ID `98` from `Ntfs` may appear as corroboration that mapping did not complete.

3. Print timestamp correlation between IME failure and Event ID 7036
- Run in PowerShell:

```powershell
$ime = 'C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log'
$fail = Get-Content $ime -Tail 8000 |
  Select-String -Pattern 'Map-FinBridgeDrives.ps1|Network name cannot be found|Win32 error 53|exit code' |
  Select-Object -Last 1

$ws7036 = Get-WinEvent -FilterHashtable @{LogName='System'; Id=7036; StartTime=(Get-Date).AddHours(-4)} |
  Where-Object { $_.ProviderName -eq 'Service Control Manager' -and $_.Message -match 'Workstation' } |
  Select-Object -Last 1

[pscustomobject]@{
  ImeFailureLine = if ($fail) { $fail.Line } else { 'Not found' }
  Workstation7036Time = if ($ws7036) { $ws7036.TimeCreated } else { 'Not found' }
}
```

- Expected result: failure evidence is present in IME output, and Event `7036` shows Workstation readiness in the same sign-in window (often after failure line time context).

4. Validate healthy baseline on one unaffected control device
- Use a non-affected Finance endpoint or known healthy comparison endpoint.
- Check same IME log location: `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log`
- Run in PowerShell:

```powershell
$ime = 'C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log'
Get-Content $ime -Tail 2500 |
  Select-String -Pattern 'Map-FinBridgeDrives.ps1|exit code 0|Network name cannot be found|Win32 error 53' |
  ForEach-Object { $_.Line }
```

- Expected result: latest `Map-FinBridgeDrives.ps1` run block shows success (`exit code 0`) and no `Network name cannot be found` / Win32 error 53.

5. Decision gate before taking action
- Confirm all of the following on the affected device:
  - IME contains `Map-FinBridgeDrives.ps1` failure in `SYSTEM` context.
  - IME contains `Network name cannot be found` (Win32 error 53) and non-zero exit code.
  - System log contains Event `7036` (`Workstation` running) in same sign-in window.
  - Event `1500` is present (helps rule out GP failure as primary cause).
  - Event `98` may be present as supporting evidence.
- Expected result: if all checks match and healthy control shows `exit code 0` with no error 53, this KB is confirmed for use.

## Resolution: step-by-step fix with expected result after each step - include specific portal/console paths

1. Open the exact Intune script object
- Path: `Devices > Manage devices > Scripts and remediations > Platform scripts > Map-FinBridgeDrives.ps1`
- Expected result: Script overview opens for `Map-FinBridgeDrives.ps1`.

2. Capture rollback baseline before edits
- Path: `Map-FinBridgeDrives.ps1 > Properties`
- Record in ticket:
  - `Run this script using the logged on credentials` current value
  - `Version` current value
  - `Assignments` screenshot
- Expected result: pre-change baseline is documented for immediate rollback.

3. Set logged-on credentials to Yes (critical fix)
- Path: `Map-FinBridgeDrives.ps1 > Properties > Edit (Script settings) > Run this script using the logged on credentials`
- Set value to `Yes`, then `Review + save` and `Save`.
- Expected result: confirmation toast shows settings saved.

4. Increment script version to force re-run
- Path: `Map-FinBridgeDrives.ps1 > Properties > Edit (Basics) > Version`
- Increase version by one step (example `1.0` -> `1.1`), then `Review + save` and `Save`.
- Expected result: new version is published and eligible for endpoint re-processing.

5. Confirm Finance-only assignment scope
- Path: `Map-FinBridgeDrives.ps1 > Assignments`
- Verify only Finance target groups are assigned.
- Expected result: no non-Finance group present.

6. Trigger pilot sync immediately
- Path: `Devices > All devices > <pilot-device> > ... > Sync`
- Expected result: device sync action accepted.

7. Force sign-out/sign-in on pilot
- Action: sign out current user and sign in with approved Finance test account.
- Expected result: fresh user session starts with updated Intune script policy.

8. Fast endpoint validation command set (pilot)
- Run in PowerShell on pilot endpoint:

```powershell
# Verify mapping and share access
Get-PSDrive -Name S -ErrorAction SilentlyContinue
Test-Path '\\finbridge-fs01\Finance'

# Verify required service/event evidence window
Get-Service -Name LanmanWorkstation | Select-Object Name, Status, StartType
Get-WinEvent -FilterHashtable @{LogName='System'; Id=7036,1500,98; StartTime=(Get-Date).AddHours(-2)} |
  Sort-Object TimeCreated |
  Select-Object TimeCreated, Id, ProviderName, Message

# Verify latest script result in IME log
$ime = 'C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log'
Get-Content $ime -Tail 3000 |
  Select-String -Pattern 'Map-FinBridgeDrives.ps1|exit code|Network name cannot be found|Win32 error 53|SYSTEM' |
  ForEach-Object { $_.Line }
```

- Expected result: `S:` exists, share path resolves, Workstation service is running, and latest script block shows success (`exit code 0`) with no new Win32 error 53.

9. Roll out to remaining affected devices
- Path: `Devices > All devices > <each affected device> > ... > Sync`
- Expected result: sync queued on affected Finance devices.

10. Instruct one-time mandatory sign-out/sign-in via Service Desk
- Expected result: users receive corrected mapping behavior on next sign-in.

11. Optional automation path (Graph PowerShell) for speed
- Use this only if Graph Intune automation is already approved and available in your environment.
- Example commands (tenant-specific IDs required):

```powershell
# Prerequisite modules and auth
Connect-MgGraph -Scopes 'DeviceManagementConfiguration.ReadWrite.All','DeviceManagementManagedDevices.PrivilegedOperations.All'
Select-MgProfile -Name beta

# Find script
$script = Invoke-MgGraphRequest -Method GET -Uri 'https://graph.microsoft.com/beta/deviceManagement/deviceShellScripts?$filter=displayName eq ''Map-FinBridgeDrives.ps1'''

# Update run context to user and increment version metadata (example payload; adapt to your tenant schema)
$body = @{
  runAsAccount = 'user'
  description  = 'vNext - run as logged-on user'
} | ConvertTo-Json
Invoke-MgGraphRequest -Method PATCH -Uri ("https://graph.microsoft.com/beta/deviceManagement/deviceShellScripts/{0}" -f $script.value[0].id) -Body $body -ContentType 'application/json'

# Trigger device sync
Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/beta/deviceManagement/managedDevices/<managedDeviceId>/syncDevice"
```

- Expected result: script context update and sync are executed centrally.
- Fallback if Graph automation is unavailable: use portal-only steps 1-10 above.

## Verification: how to confirm the fix worked

1. Verify pilot access evidence
- On pilot endpoint, open `File Explorer > This PC > S:`.
- Expected result: `\\finbridge-fs01\Finance` opens without error.

2. Verify pilot IME success evidence
- Log path: `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log`
- Run:

```powershell
$ime = 'C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log'
Get-Content $ime -Tail 3000 |
  Select-String -Pattern 'Map-FinBridgeDrives.ps1|exit code 0|Network name cannot be found|Win32 error 53' |
  ForEach-Object { $_.Line }
```

- Expected result: latest run block contains `exit code 0` and no new `Network name cannot be found` / Win32 error 53.

3. Verify service and event state on pilot
- Log path: `Event Viewer > Windows Logs > System`
- Run:

```powershell
Get-Service LanmanWorkstation | Select-Object Name, Status
Get-WinEvent -FilterHashtable @{LogName='System'; Id=7036,1500,98; StartTime=(Get-Date).AddHours(-2)} |
  Sort-Object TimeCreated |
  Select-Object TimeCreated, Id, ProviderName, Message
```

- Expected result: Workstation service is running, no fresh failure pattern appears in the post-fix window.

4. Verify at least 3 additional affected devices
- Repeat steps 1-3 on three additional previously affected Finance devices.
- Expected result: each sampled device shows S: access plus IME success.

5. Observe queue for recurrence
- Monitor Service Desk queue for 30 minutes.
- Expected result: no new Finance shared-drive incidents.

6. Record closure evidence
- Save ticket evidence: one S: success screenshot, IME success snippet from pilot, and sampled device list with timestamps.
- Expected result: closure is auditable and defensible.

## Rollback: what to do if the fix makes thing worse- be specific

Use rollback if failures increase, non-Finance impact appears, or user logon behavior regresses.

1. Reopen exact script setting path
- Path: `Devices > Manage devices > Scripts and remediations > Platform scripts > Map-FinBridgeDrives.ps1 > Properties > Edit (Script settings) > Run this script using the logged on credentials`
- Expected result: script setting is editable.

2. Revert run context immediately
- Set `Run this script using the logged on credentials = No`.
- Select `Review + save` then `Save`.
- Expected result: save confirmation appears.

3. Restore pre-change version
- Path: `Map-FinBridgeDrives.ps1 > Properties > Edit (Basics) > Version`
- Set version back to value captured in Resolution step 2.
- Select `Review + save` then `Save`.
- Expected result: version baseline is restored.

4. Trigger pilot sync for rollback ingestion
- Path: `Devices > All devices > <pilot-device> > ... > Sync`
- Expected result: rollback policy sync request accepted.

5. Confirm new IME run occurred after rollback timestamp
- Log path: `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log`
- Run:

```powershell
$rollbackStart = Get-Date
Start-Sleep -Seconds 10
$ime = 'C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log'
Get-Content $ime -Tail 4000 |
  Select-String -Pattern 'Map-FinBridgeDrives.ps1|exit code|SYSTEM|Network name cannot be found|Win32 error 53' |
  ForEach-Object { $_.Line }
```

- Expected result: a new script execution block appears after rollback action time.

6. Publish immediate user workaround
- Service Desk instruction: `net use S: \\finbridge-fs01\Finance`
- Expected result: temporary access path is available while root fix is reassessed.

7. Optional automation rollback path (Graph PowerShell)
- Use only where Graph Intune automation is approved and validated.
- Example:

```powershell
Connect-MgGraph -Scopes 'DeviceManagementConfiguration.ReadWrite.All','DeviceManagementManagedDevices.PrivilegedOperations.All'
Select-MgProfile -Name beta

# Revert script run context (example payload; adapt to tenant schema)
$body = @{ runAsAccount = 'system'; description = 'Rollback to previous run context' } | ConvertTo-Json
Invoke-MgGraphRequest -Method PATCH -Uri 'https://graph.microsoft.com/beta/deviceManagement/deviceShellScripts/<scriptId>' -Body $body -ContentType 'application/json'

# Trigger pilot sync
Invoke-MgGraphRequest -Method POST -Uri 'https://graph.microsoft.com/beta/deviceManagement/managedDevices/<managedDeviceId>/syncDevice'
```

- Expected result: rollback configuration and pilot sync are applied centrally.
- Fallback if Graph automation is unavailable: complete portal rollback steps 1-6.

8. Escalate if still unstable
- Escalate to L3/EUC platform with timeline, IME snippets, Event 7036/1500/98 window, and impact scope.
- Expected result: higher-tier engineering takes over with full evidence pack.

## Preventive: the specific change to process or tooling that stop this recurring

Process controls:
- Add mandatory change-gate for execution context in any GPO-to-Intune script migration.
- Require explicit test evidence at interactive sign-in for any script that maps drives or accesses UNC paths.
- Require rollback metadata in every script change record (old context, old version, target assignments).

Tooling controls:
- Add IME monitoring rule for `Map-FinBridgeDrives.ps1` non-zero exits across Finance fleet.
- Add detection alert for repeated error text `Network name cannot be found` with SYSTEM context.
- Add post-deployment validation checklist in Intune release workflow to verify user-context vs SYSTEM-context suitability.

Script hardening recommendation:
- Add a readiness guard in script logic to wait for `LanmanWorkstation` service before UNC mapping attempts.
- Keep user-context execution for mapping actions unless security policy explicitly forbids it.

## Related: other incidents or KB article this connects to

- Day5/runbook_finance_shared_drive_intune_system_context_20260807.md (source runbook)
- Day4/rca_finance_shared_drive_intune_system_context_20260807.md (deep technical RCA)
- Day4/known_error_finance_shared_drive_intune_system_context_20260807.md (known error pattern)
- Day4/closure_note_finance_shared_drive_20260807.md (closure evidence)
- Day4/end_user_communication_finance_shared_drive_20260807.md (communication template)
- Day5/kb_l1_finance_shared_drive_access_20260807.md (L1 user-facing quick guidance)
