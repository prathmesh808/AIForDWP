# RCA: Finance Team Cannot Access Shared Drives — Intune Script SYSTEM Context Race Condition

Date of report: 2026-08-07  
Prepared by: DWP Engineer  
Incident status: Resolved

---

## 1) Executive Summary

At approximately 08:00 on 2026-08-07, all 45 Finance users lost access to shared drive S: (mapped to `\\finbridge-fs01\Finance`). The failure was simultaneous across all Finance devices (DESKTOP-FB*) and coincided exactly with the morning logon wave. No change was recorded by the Finance team or Service Desk at the time of incident.

Investigation of the Intune Management Extension (IME) log and System Event log on affected devices revealed that the drive mapping PowerShell script `Map-FinBridgeDrives.ps1` executes under the SYSTEM account via Intune. At the point of execution (08:00:03), the Windows Workstation service (LanmanWorkstation) — which provides the SMB client stack required for UNC path resolution — had not yet entered running state (08:00:05). The script attempted the UNC path, received error 53 ("Network name cannot be found"), exited with code 1, and had no retry configured. Drive letter S: was never assigned.

The defect was introduced on 2024-03-14 when the drive mapping mechanism was migrated from a GPO logon script (which ran as the logged-on USER, after the full user session was established) to an Intune PowerShell script (which runs as SYSTEM during early logon, before dependent services are ready). The script logic was not updated to account for the changed execution context. The defect remained latent for approximately two years before manifesting as a widespread incident.

Resolution was applied by changing the Intune script execution context to the logged-on user credential, restoring the original behaviour. All 45 Finance users regained drive access following device sync and re-logon.

---

## 2) Scope and Impact

| Field | Detail |
|---|---|
| Symptom | S: drive not mapped; `\\finbridge-fs01\Finance` inaccessible |
| Affected users | All Finance users — 45 users |
| Affected devices | All DESKTOP-FB* devices (OU=Finance) |
| Unaffected | Non-Finance users and devices — no shared infrastructure impact confirmed |
| Impact start | 2026-08-07 ~08:00 (morning logon wave) |
| Impact end | 2026-08-07 (post-remediation, same day) |
| Business impact | Full Finance team loss of shared drive access; Finance operations dependent on shared drives blocked for the incident duration |
| Change recorded at time of incident | Nil |

---

## 3) Environment and Change Context

- **Drive mapping mechanism:** `Map-FinBridgeDrives.ps1` deployed via Microsoft Intune as a Platform Script
- **Execution context at time of incident:** SYSTEM account (early logon, pre-user-session)
- **Target path:** `\\finbridge-fs01\Finance` → mapped to drive letter S:
- **Affected OU:** OU=Finance (all DESKTOP-FB* devices)
- **Prior change (root cause origin):**

> *2024-03-14 23:30 — Drive mapping script migrated from GPO logon script (runs as USER) to Intune PowerShell script (runs as SYSTEM). Script not updated to handle SYSTEM context — network paths via UNC require the Workstation service and mapped credentials which are not available to SYSTEM at login time. Source: DESKTOP-FB022*

The migration change was performed in March 2024. No functional validation of the drive mapping under the new execution context was recorded. The defect was latent from migration date until this incident.

---

## 4) Supporting Evidence

### Intune Management Extension Log — DESKTOP-FB* (all affected devices)

| Timestamp | Source | Level | Detail |
|---|---|---|---|
| 08:00:01 | ScriptRunner | Info | Executing: `Map-FinBridgeDrives.ps1` |
| 08:00:02 | ScriptRunner | Info | Script context: SYSTEM account |
| 08:00:03 | ScriptRunner | Warning | Network path `\\finbridge-fs01\Finance` not accessible from SYSTEM context at execution time |
| 08:00:03 | ScriptRunner | Error | Script `Map-FinBridgeDrives.ps1` failed. Exit code: 1. Error: Network name cannot be found. |
| 08:00:04 | ScriptRunner | Info | No retry configured. |

### System Event Log — DESKTOP-FB041 (representative sample)

| Timestamp | Source | Event ID | Level | Detail |
|---|---|---|---|---|
| 08:00:05 | Service Control Manager | 7036 | Info | Workstation service entered running state |
| 08:00:06 | GroupPolicy | 1500 | Info | Group Policy settings processed successfully |
| 08:00:07 | Ntfs | 98 | Warning | File system could not map drive letter S: — drive letter has not been assigned |

### Evidence Interpretation

- The Workstation service (Event 7036, 08:00:05) entered running state **two seconds after** the script had already failed (08:00:03). This is the direct race condition — the SMB client was not ready when the SYSTEM-context script attempted the UNC path.
- Group Policy Event 1500 (08:00:06) confirms GP applied successfully. GPO is not the cause and was not disrupted.
- NTFS Event 98 (08:00:07) is a downstream consequence of the script failure — S: was never assigned because the script exited before mapping could complete.
- The error message "Network name cannot be found" (Win32 error 53) is consistent with the Workstation service being unavailable — not with a server-side outage, DNS failure, or ACL denial, all of which would produce different error codes or log signatures.
- The IME log explicitly records "Script context: SYSTEM account" and "not accessible from SYSTEM context" — the execution context mismatch is self-documented in the log.

---

## 5) Timeline

| Date / Time | Event |
|---|---|
| **2024-03-14 23:30** | Drive mapping script migrated from GPO logon script (USER context) to Intune Platform Script (SYSTEM context). Script not updated for new context. Defect introduced. |
| **2024-03-14 to 2026-08-06** | Defect latent — root cause not yet manifesting as a reported incident (possible prior silent failures not captured or not escalated) |
| **2026-08-07 ~08:00** | Finance team morning logon wave begins |
| **08:00:01** | `Map-FinBridgeDrives.ps1` begins execution as SYSTEM on DESKTOP-FB* devices |
| **08:00:02** | IME log confirms SYSTEM account context |
| **08:00:03** | Script attempts UNC path `\\finbridge-fs01\Finance` — Workstation service not yet running — error 53 returned |
| **08:00:04** | Script exits, exit code 1. No retry configured. Drive mapping abandoned. |
| **08:00:05** | Workstation service enters running state (Event 7036) — too late for script execution |
| **08:00:06** | Group Policy processes successfully (Event 1500) — GP confirmed not involved |
| **08:00:07** | NTFS Event 98 — S: drive letter not assigned |
| **~08:00+** | All 45 Finance users report inability to access shared drives |
| **Incident window** | DWP Engineer investigates; IME log and System log reviewed; prior migration change note identified |
| **Remediation** | Intune script execution context changed to logged-on user; script version incremented to force re-run; device sync pushed |
| **Post-remediation** | Finance devices re-logon; S: drive maps successfully; IME log confirms exit code 0; Event 98 absent |

---

## 6) Hypothesis Review and Elimination

Five hypotheses were generated from scope facts prior to log evidence review. Each was assessed against the IME and System log evidence.

| # | Hypothesis | Verdict | Determining Evidence |
|---|---|---|---|
| 1 | DFS / File Server service down | **Eliminated** | Error explicitly attributed to SYSTEM context (`08:00:03`); Workstation service started normally (`08:00:05` Event 7036); no server-side failure events |
| 2 | AD security group removed from share ACL | **Not confirmed — closed out** | Error class is 53 (path not found), not 5 (access denied); no ACL denial event recorded; AD group membership verified intact post-incident |
| 3 | GPO drive mapping not applying | **Eliminated** | Event 1500 (`08:00:06`) — GP processed successfully; explicitly confirmed as not a GP issue |
| 4 | DNS resolution failure | **Eliminated as primary cause** | Error 53 fully explained by SYSTEM context / Workstation service timing; DNS verified functional post-incident |
| 5 | Network / VLAN block to file server | **Eliminated** | Workstation service entered running state (Event 7036); no network-layer events; non-Finance access to server unaffected |

**Confirmed cause:** Intune PowerShell script executing as SYSTEM before the Workstation service is ready — race condition introduced by 2024-03-14 migration without script adaptation.

---

## 7) Confirmed Root Cause

The Intune Platform Script `Map-FinBridgeDrives.ps1` executes under the SYSTEM account during early logon. At the time of execution, the Windows Workstation service (LanmanWorkstation), which provides the SMB client stack necessary for UNC path resolution, has not yet entered running state. The script attempts to connect to `\\finbridge-fs01\Finance`, receives Win32 error 53 ("Network name cannot be found"), and exits with code 1. No retry is configured. Drive letter S: is never assigned. This behaviour reproduces identically on all Finance devices at every logon.

The underlying defect was introduced on 2024-03-14 when the drive mapping was migrated from a GPO logon script (which executes in the fully-established user session, with the Workstation service already running and user credentials available) to an Intune PowerShell script (which executes as SYSTEM, early in the boot/logon sequence, with no dependency on the Workstation service being ready). The script was not modified to account for the changed execution context, and no functional validation of drive mapping under the new context was performed.

---

## 8) 5 Whys Analysis

**1. Why could Finance users not access the shared drive?**  
Because drive letter S: was not mapped on their devices at logon.

**2. Why was S: not mapped?**  
Because `Map-FinBridgeDrives.ps1` failed with exit code 1 every time it ran, and no retry or fallback was configured.

**3. Why did the script fail?**  
Because it attempted to connect to `\\finbridge-fs01\Finance` as the SYSTEM account before the Workstation service had entered running state — the SMB client stack required for UNC resolution was not yet available.

**4. Why was the script running as SYSTEM before the Workstation service was ready?**  
Because in 2024 the script was migrated from a GPO logon script (USER context, executed after full session establishment) to an Intune Platform Script (SYSTEM context, executed early in logon with no service dependency awareness). The script code was not updated to handle the new context.

**5. Why was the script not updated when the deployment method changed?**  
Because the 2024 migration was performed as a lift-and-shift — the script was moved without functional validation in the new execution context, and there was no change control gate requiring evidence that drive mapping worked under Intune SYSTEM execution before the change was closed.

---

## 9) Resolution Actions Implemented

### Immediate Containment

- Identified affected population: all 45 Finance users (DESKTOP-FB*, OU=Finance)
- Confirmed non-Finance users unaffected — no broader service impact
- Communicated interim workaround to Finance team: manually map `\\finbridge-fs01\Finance` as S: via File Explorer or `net use S: \\finbridge-fs01\Finance`

### Mitigation and Remediation

**Action 1 — Changed Intune script execution context**
- In Intune admin centre: **Devices → Scripts and remediations → Platform scripts → `Map-FinBridgeDrives.ps1` → Properties → Edit**
- Changed **"Run this script using the logged on credentials"** from **No** to **Yes**
- Saved and pushed device sync to all DESKTOP-FB* devices

**Action 2 — Forced script re-execution**
- Incremented script version in Intune to trigger re-run on devices where the script had previously failed and cached a failure state

**Action 3 — Pilot validation before broad push**
- Tested on DESKTOP-FB041: signed out and re-signed in
- Confirmed: S: drive present and accessible; IME log shows exit code 0; Event 98 absent from System log
- Proceeded to full rollout after pilot confirmation

### Validation at Closure

- S: drive mapped successfully on all Finance devices following re-logon
- IME log confirms `Map-FinBridgeDrives.ps1` exit code 0 across sampled devices
- No NTFS Event 98 observed post-remediation
- Finance team confirmed full access to shared drives restored

---

## 10) Preventive and Corrective Actions

### Technical Actions

| Action | Detail | Owner |
|---|---|---|
| Update `Map-FinBridgeDrives.ps1` with Workstation service readiness guard | Add a polling loop at script start that waits up to 30 seconds for `LanmanWorkstation` to enter Running state before attempting any UNC path. Provides defence-in-depth if execution context ever reverts to SYSTEM. | DWP Engineering |
| Add Intune script health monitoring | Alert on any Intune Platform Script reporting non-zero exit codes across more than 5 devices in the same OU within a 15-minute window | EUC / Monitoring team |
| Audit all Intune Platform Scripts for SYSTEM-context UNC path operations | Identify any other scripts that perform UNC access as SYSTEM without a service readiness check — remediate with same pattern | DWP Engineering |

### Process Actions

| Action | Detail | Owner |
|---|---|---|
| Mandate functional validation on deployment method changes | Any change that alters the execution context of an existing script (e.g. GPO → Intune, USER → SYSTEM) must include a documented test confirming the primary function works in the new context before change closure | Change Management / DWP Lead |
| Add "execution context" as a mandatory field in change records for script deployments | Change templates for script-related changes must capture: execution account, execution trigger, and dependent services. Reviewer must sign off that context compatibility was verified. | Change Management |
| Create known-error record for SYSTEM-context UNC failures | Add to KEDB so future similar symptoms (drive mapping fails, IME error 53, SYSTEM context) can be matched quickly without full investigation | Service Desk / Knowledge team |

### Ownership and Follow-up

- **DWP Engineering:** Script hardening (Workstation service guard) and SYSTEM-context script audit — target: within 5 business days
- **EUC / Monitoring:** Intune script failure alerting rule — target: next monitoring sprint
- **Change Management:** Change template update for script deployment context fields — target: next CAB cycle
- **Service Desk / Knowledge:** KEDB entry for SYSTEM-context drive mapping failure pattern — target: within 2 business days

---

## 11) Lessons Learned

- A two-year-old migration change was the root cause of a 45-user incident. Lift-and-shift migrations without functional validation in the new context carry silent risk that may not surface immediately.
- The Intune Management Extension log is a high-value diagnostic source for script execution failures — it self-documents the execution context, error, and exit code. It should be the first log checked for any drive mapping or logon script complaint on Intune-managed devices.
- "Nil change" incident reports should not rule out historical changes. The relevant change predated the incident by over two years; the Finance team and first-line responders had no awareness of it.
- The SYSTEM vs USER execution context distinction in Windows is a common failure mode for scripts migrated from GPO to Intune. It should be treated as a required compatibility check in any such migration.
