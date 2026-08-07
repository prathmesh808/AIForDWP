# End-User Communications — Finance Shared Drive Access Failure

Date: 2026-08-07  
Source of facts: Incident analysis and RCA for Finance shared drive SYSTEM context script failure

---

## Audience 1 — Non-Technical Executive

Your access and data are safe. This morning, a technical configuration dating from a March 2024 system change caused the Finance team's shared drive to not connect automatically at start-up. No data was lost or at risk. We identified the cause, applied a fix, and confirmed full access has been restored. No action is required from you — if any Finance team member still cannot access the shared drive, please ask them to contact the IT Service Desk.

---

## Audience 2 — Affected End-User Team (Finance)

Your access and data are safe. This morning, a background IT configuration issue — caused by a change made in 2024 — meant your shared drive (S:) did not connect automatically when you logged in. We found the cause and fixed it. To restore your access now, please sign out and sign back in to your device and the S: drive will reconnect automatically. If the issue persists after signing back in, contact the DWP Service Desk and quote reference: Finance shared drive — 2026-08-07.

---

## Audience 3 — Engineer-to-Engineer Internal Note

**Status:** Resolved and validated.

**Scope and impact:**
- Symptom: S: drive (`\\finbridge-fs01\Finance`) not mapped at logon for all Finance users.
- Affected: 45 users, all DESKTOP-FB* devices (OU=Finance).
- Onset: 2026-08-07 ~08:00 (morning logon wave).
- Non-Finance users and file server itself unaffected.
- Change recorded at incident time: nil (from end-user/Service Desk perspective).

**Root cause:**
`Map-FinBridgeDrives.ps1` deployed as an Intune Platform Script running as **SYSTEM**. At execution time (08:00:03), `LanmanWorkstation` (Workstation service) had not yet entered running state — it started at 08:00:05. UNC path `\\finbridge-fs01\Finance` failed with Win32 error 53 ("Network name cannot be found"). Script exited code 1 with no retry configured. Drive letter S: never assigned. Race condition reproducible on every logon for all Finance devices.

Defect origin: **2024-03-14 23:30** — drive mapping migrated from GPO logon script (USER context, full session established, Workstation service running) to Intune Platform Script (SYSTEM context, early logon, no service dependency awareness). Script not updated for new context. No functional validation performed at migration. Defect latent ~2 years.

**IME log evidence (DESKTOP-FB* all devices):**
```
08:00:01  ScriptRunner  Info     Executing: Map-FinBridgeDrives.ps1
08:00:02  ScriptRunner  Info     Script context: SYSTEM account
08:00:03  ScriptRunner  Warning  Network path \\finbridge-fs01\Finance not accessible from SYSTEM context
08:00:03  ScriptRunner  Error    Script failed. Exit code: 1. Error: Network name cannot be found.
08:00:04  ScriptRunner  Info     No retry configured.
```

**System Event log evidence (DESKTOP-FB041, representative):**
```
08:00:05  Service Control Manager  Event 7036  Workstation service entered running state
08:00:06  GroupPolicy              Event 1500  Group Policy settings processed successfully
08:00:07  Ntfs                     Event 98    Could not map drive letter S: — not assigned
```

- Event 7036 at 08:00:05 confirms Workstation service started 2 seconds after script already failed.
- Event 1500 at 08:00:06 eliminates GPO as a cause.
- Event 98 at 08:00:07 is downstream consequence, not independent cause.
- Error 53 (path not found) rules out ACL denial (error 5) and server-side outage.

**Exact action taken:**
1. Intune admin centre → **Devices → Scripts and remediations → Platform scripts → `Map-FinBridgeDrives.ps1` → Properties → Edit**
2. Changed **"Run this script using the logged on credentials"** → **Yes** (was: No / SYSTEM)
3. Saved; incremented script comment to force re-run on devices with cached failure state
4. Pushed device sync to all DESKTOP-FB* via Intune device blade

**Config detail:**
- Script name: `Map-FinBridgeDrives.ps1`
- Intune setting changed: `Run as account` = `User` (previously `System`)
- Target scope: all DESKTOP-FB* devices, OU=Finance
- Re-run trigger: script body version increment (Intune treats modified script as new; re-executes)

**Verification steps:**
- Pilot on DESKTOP-FB041: sign out → sign in
- IME log: confirmed `Map-FinBridgeDrives.ps1` exit code **0**
- S: drive present and accessible in File Explorer
- System log: Event 98 absent post-remediation
- Finance team confirmation: all 45 users confirmed access restored

**Preventive action required:**

| Action | Detail | Owner | Target |
|---|---|---|---|
| Harden script with Workstation service readiness guard | Add polling loop at top of `Map-FinBridgeDrives.ps1` — wait up to 30s for `LanmanWorkstation` Running state before any UNC call. Defence-in-depth if context reverts to SYSTEM. | DWP Engineering | Within 5 business days |
| Audit all Intune Platform Scripts for SYSTEM-context UNC operations | Identify any other scripts performing UNC/SMB access as SYSTEM without service dependency checks. Apply same guard pattern. | DWP Engineering | Within 5 business days |
| Intune script failure alerting | Alert when any Intune Platform Script reports non-zero exit code across >5 devices in same OU within 15 minutes | EUC / Monitoring | Next monitoring sprint |
| Change control gate for execution context changes | Any change altering script execution context (GPO→Intune, USER→SYSTEM) must include documented functional test evidence before change closure. Add "execution account" and "dependent services verified" to change template. | Change Management | Next CAB cycle |
| KEDB entry | Log symptom pattern: all users in OU lose mapped drive, IME error 53, SYSTEM context, Workstation service timing. Enables L1 fast-match on recurrence. | Service Desk / Knowledge | Within 2 business days |

**Workstation service guard (reference implementation):**
```powershell
# Wait for Workstation service before attempting UNC mapping
$maxWait = 30
$elapsed = 0
while ((Get-Service -Name LanmanWorkstation).Status -ne 'Running' -and $elapsed -lt $maxWait) {
    Start-Sleep -Seconds 2
    $elapsed += 2
}
if ((Get-Service -Name LanmanWorkstation).Status -ne 'Running') {
    Write-Error "Workstation service not ready after $maxWait seconds. Aborting drive mapping."
    exit 1
}
```

**Key lesson for recurrence recognition:**
If a Finance device (or any DESKTOP-FB*) reports a missing S: drive, check IME log first — `ScriptRunner` entries will show context and error within seconds of logon. Error 53 from SYSTEM context = this defect pattern. Error 5 = ACL issue. Error 64 = server-side share problem. Do not start with server-side checks.
