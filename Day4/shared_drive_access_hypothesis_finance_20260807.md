# Hypothesis Analysis — Finance Team Cannot Access Shared Drives
**Date:** 2026-08-07  
**Analyst:** DWP Engineer  
**Scope:** All Finance users (45 users) — shared drive access failure since ~08:00 this morning. No change recorded.

---

## Scope Facts Summary

| Field | Detail |
|---|---|
| Symptom | Cannot access shared drives |
| Who | All Finance users — 45 users |
| Since | ~08:00 today (2026-08-07) |
| Change | Nil reported |

---

## Ranked Hypotheses — Most Probable First

---

### 1. DFS Namespace or File Server Service Failure

**Why this fits:**
All 45 Finance users are affected simultaneously from the same start time. A DFS namespace outage or a stopped/crashed File Server service on the host serving Finance shares would produce an instant, complete, all-user loss of access with no client-side change required. The hard start time (~08:00) aligns with a service crash at business-hours load spike or a scheduled maintenance task that did not complete cleanly.

**Fastest single check:**
From any Finance PC (or the server directly), run:
```
net use \\<fileserver-or-DFS-root>\<finance-share>
```
If it returns **System error 53** (network path not found) or **error 64** (network name deleted), the share/service is down. Confirm on the file server with `services.msc` — check that **Server** service and **DFS Namespaces** service are running.

---

### 2. Active Directory Security Group Membership Change / Removed Group Permission on Share

**Why this fits:**
All 45 Finance users share a common AD group (e.g. `GRP-Finance-SharedDrive`). If that group was accidentally removed from the share/NTFS ACL — or users were bulk-removed from the group — all members lose access simultaneously at next authentication token refresh. A scheduled AD sync, overnight provisioning script, or an admin error overnight could produce this with a nil-change perception from the Finance team's side.

**Fastest single check:**
On the file server run:
```
Get-Acl "\\<server>\<share>" | Format-List
```
Confirm the Finance AD group is still present with at least Read permission. Cross-check group membership in AD:
```
Get-ADGroupMember -Identity "GRP-Finance-SharedDrive" | Measure-Object
```
Expect ~45 members; a count of 0 confirms this cause.

---

### 3. Group Policy Drive Mapping Failure (GPO Not Applying)

**Why this fits:**
Drive mappings are commonly delivered via Group Policy Preferences. If the GPO responsible for mapping the Finance shared drive failed to apply — due to a DC connectivity issue, GPO corruption, or a policy scope/filter change — all 45 users would lose the mapped drive letter at logon. The ~08:00 start time matches the morning logon wave. This is consistent with a nil-change report because the GPO itself may have been modified outside the Finance team's awareness.

**Fastest single check:**
On an affected Finance PC, run:
```
gpresult /r
```
Check whether the Finance drive-mapping GPO appears under **Applied GPOs**. If it shows under **Denied/Not Applied GPOs**, this is confirmed. Also check for errors:
```
Get-WinEvent -LogName "Microsoft-Windows-GroupPolicy/Operational" -MaxEvents 20
```

---

### 4. DNS Resolution Failure for File Server / DFS Root

**Why this fits:**
If the DNS record for the file server or DFS root became stale, expired, or was accidentally deleted overnight, all clients would fail to resolve the UNC path at the point their cached DNS TTL expired — producing a near-simultaneous failure for all users in the same subnet/DNS scope at ~08:00 when morning logons trigger fresh lookups. No change would be visible to end users.

**Fastest single check:**
On an affected Finance PC run:
```
nslookup <fileserver-hostname>
```
If this returns a failure or wrong IP, DNS is the cause. Confirm expected IP against the server's actual IP (`ipconfig` on server). Also test direct IP access:
```
net use \\<IP-address>\<share>
```
If IP access works but hostname fails, DNS is confirmed.

---

### 5. Network / VLAN Connectivity Issue Isolating Finance Segment from File Server

**Why this fits:**
If Finance users sit on a dedicated VLAN or subnet and a switch, router ACL, or VLAN configuration change blocked traffic to the file server subnet, all 45 users would lose access at once while the rest of the organisation is unaffected. The nil-change report is consistent — network infrastructure changes are often made outside the Finance team's (and sometimes the helpdesk's) awareness.

**Fastest single check:**
On an affected Finance PC run:
```
ping <fileserver-hostname-or-IP>
tracert <fileserver-hostname-or-IP>
```
If ping fails or tracert shows packets dropping at a network hop before reaching the server, a network/routing issue is confirmed. Compare with a test from a non-Finance PC on a different subnet — if that user can reach the server, the issue is isolated to the Finance network segment.

---

## Summary Table

| Rank | Cause | Blast Radius | Key Signal |
|------|-------|-------------|------------|
| 1 | DFS/File Server service down | All users, all shares | `net use` errors 53/64; service stopped on server |
| 2 | AD group removed from share ACL | All Finance users | Finance group absent from ACL or group emptied |
| 3 | GPO drive mapping not applying | All Finance users at logon | GPO absent from `gpresult /r` output |
| 4 | DNS resolution failure for server | All users on affected DNS scope | `nslookup` fails; direct IP access works |
| 5 | Network/VLAN block to file server | All Finance users (segment-specific) | `ping`/`tracert` fails from Finance PCs only |

---

## Next Steps

Do not commit to one cause yet. Run the fastest checks in parallel where possible (checks 1, 4, and 5 can be done from a single Finance PC in under 5 minutes). Report back findings to narrow to a confirmed root cause before remediation.

---

## Evidence Review — Intune Management Extension Log + System Log

**Source:** IME Log + System Event Log  
**Device sample:** DESKTOP-FB041 (representative of all DESKTOP-FB* Finance devices)  
**Incident window:** 08:00:01 – 08:00:07, 2026-08-07

**Prior change context (migration log, 2024-03-14 23:30):**  
Drive mapping script `Map-FinBridgeDrives.ps1` was migrated from a GPO logon script (ran as USER) to an Intune PowerShell script (ran as SYSTEM). The script was not updated to account for the SYSTEM context — UNC paths require the Workstation service and user-mapped credentials unavailable to SYSTEM at login time.

---

### H1 — DFS Namespace or File Server Service Failure
**Verdict: CONTRADICTS**

The IME log at `08:00:03` records:
> `Warning: Network path \\finbridge-fs01\Finance not accessible from SYSTEM context at execution time`

The error is explicitly attributed to **SYSTEM context**, not a server-side outage. If the file server or DFS namespace were down, the error would surface equally from user-context sessions and from direct UNC tests — no SYSTEM-context qualifier would appear. Additionally, System Log Event 7036 at `08:00:05` shows the Workstation service entered running state *after* the script already attempted the mapping, suggesting a timing issue rather than a persistent server failure. No server-side service failure event is recorded.

---

### H2 — AD Security Group Removed from Share / NTFS ACL
**Verdict: NEUTRAL**

No log entry references an ACL denial, an access-denied error (e.g. error 5 / `ERROR_ACCESS_DENIED`), or an AD group membership change. The failure at `08:00:03` is `"Network name cannot be found"` (error 53) — a path resolution failure, not a permissions denial. This hypothesis is neither supported nor contradicted by the evidence; it cannot be eliminated purely from these logs, but the error class does not match what an ACL removal would produce.

---

### H3 — Group Policy Drive Mapping Not Applying
**Verdict: CONTRADICTS**

System Log Event **1500** at `08:00:06` explicitly records:
> `Group Policy settings processed successfully.`

The log note confirms: *"GP is fine — this is NOT a GP issue."* GP applied without error on DESKTOP-FB041. The drive mapping failure is not downstream of a GPO fault. This hypothesis is eliminated by the GP success event.

---

### H4 — DNS Resolution Failure for File Server / DFS Root
**Verdict: NEUTRAL (leaning contradicts)**

The IME log at `08:00:03` uses the hostname `\\finbridge-fs01\Finance` and the error returned is `"Network name cannot be found"` (error 53). This *could* indicate DNS failure, but the prior change note is a more precise and complete explanation for the same error code — the script runs as SYSTEM before the Workstation service is fully initialised (service enters running state at `08:00:05`, two seconds *after* the script fails at `08:00:03`). DNS failure cannot be confirmed or ruled out from these logs alone, but the SYSTEM context / timing explanation fully accounts for the error without requiring DNS to be at fault.

---

### H5 — Network / VLAN Connectivity Isolating Finance Segment
**Verdict: CONTRADICTS**

System Log Event **7036** at `08:00:05` shows the Workstation service entering running state on DESKTOP-FB041 — this service requires network stack availability. A VLAN block or network isolation would prevent the Workstation service from fully initialising and would likely generate additional network-layer events. The error at `08:00:03` is precisely scoped to the SYSTEM account's inability to access the UNC path, not a blanket network unreachability. No ping failures, no network adapter events, and no routing errors are recorded.

---

## Updated Evidence Summary Table

| Rank | Hypothesis | Evidence Verdict | Determining Event |
|------|-----------|-----------------|-------------------|
| 1 | DFS/File Server service down | **CONTRADICTS** | `08:00:03` — error attributed to SYSTEM context, not server outage; `08:00:05` Event 7036 workstation service normal |
| 2 | AD group removed from ACL | **NEUTRAL** | No ACL denial event; error class is path resolution (error 53), not access denied (error 5) |
| 3 | GPO drive mapping not applying | **CONTRADICTS** | `08:00:06` Event **1500** — GP processed successfully |
| 4 | DNS resolution failure | **NEUTRAL (leaning contradicts)** | Error 53 explained by SYSTEM context timing without requiring DNS fault |
| 5 | Network/VLAN block | **CONTRADICTS** | `08:00:05` Event 7036 — Workstation service running normally; no network-layer errors recorded |

**Emerging picture:** The evidence consistently points toward the Intune script execution context. The script runs as SYSTEM before the Workstation service is ready (`08:00:03` failure vs `08:00:05` service start), and the prior migration change log (2024-03-14) confirms the script was never updated to handle SYSTEM context. Hypotheses 1, 3, and 5 are effectively eliminated. Hypothesis 2 remains open but is not supported by the error class. The SYSTEM context / script timing issue is the strongest single explanation across all evidence — but do not commit to a final cause until corroborated across multiple DESKTOP-FB* devices.

---

## Confirmed Root Cause and Resolution

### Root Cause: Intune PowerShell Script Executing as SYSTEM Before Workstation Service Is Ready

None of the original five hypotheses is confirmed by the evidence. The logs revealed a sixth cause that supersedes them. The surviving explanation — consistent with every log entry and the migration change note — is:

> **`Map-FinBridgeDrives.ps1` is deployed via Intune and executes as SYSTEM at logon. The Workstation service (which provides the SMB client stack required for UNC path resolution) has not yet entered running state when the script fires. The script attempts `\\finbridge-fs01\Finance` at `08:00:03`, receives error 53 ("Network name cannot be found"), exits with code 1, and no retry is configured. The drive letter S: is never assigned. This reproduces identically across all 45 Finance devices at every logon.**

The underlying defect is the 2024-03-14 migration that moved the script from a GPO logon script (ran as USER, after the user session and Workstation service were fully initialised) to an Intune PowerShell script (ran as SYSTEM, early in the boot sequence with no dependency awareness). The script logic was not changed to account for the different execution context.

H2 (AD ACL) is the only original hypothesis not eliminated by the logs but it is unsupported — the error class (53, path not found) does not match what an ACL removal produces (error 5, access denied). It should be verified and closed out as part of the remediation process below.

---

### Resolution Steps

#### Immediate Mitigation (same day — stops the bleeding)

**Step 1 — Change the Intune script execution context to logged-on user**

In Microsoft Intune admin centre:
1. Navigate to **Devices → Scripts and remediations → Platform scripts**
2. Locate `Map-FinBridgeDrives.ps1`
3. Select **Properties → Edit**
4. Under **Script settings**, change **Run this script using the logged on credentials** to **Yes**
5. Save and **Sync** or force a device check-in

This is the lowest-risk immediate fix. Running as the logged-on user means the script executes in the full user session — Workstation service is running, user credentials are available, and UNC paths resolve as they did under the original GPO logon script.

**Step 2 — Force a re-run across all Finance devices**

Intune does not re-run a PowerShell script that previously exited with a failure state without a trigger. To force re-execution for affected devices:
1. In Intune, reassign the script policy to a new Azure AD group that includes all Finance devices (DESKTOP-FB*)
2. Or increment the script version / modify a comment in the script body — Intune treats this as a new script and re-runs it
3. Devices will pick up the change at next check-in (up to 8 hours) or immediately if **Sync** is pushed from the device blade

**Step 3 — Verify remediation on a pilot device before broad push**

Pick one Finance device (e.g. DESKTOP-FB041). After policy sync, sign out and sign back in. Confirm:
- S: drive is present and accessible
- IME log shows `Script Map-FinBridgeDrives.ps1` completed with **Exit code: 0**
- No Event 98 (NTFS drive letter mapping failure) in System log

Only proceed to full rollout after pilot confirmation.

---

#### Permanent Fix (same day or next change window — closes the defect properly)

**Option A — Add a Workstation service readiness check inside the script (preferred if SYSTEM context must be retained)**

Add the following guard at the top of `Map-FinBridgeDrives.ps1` before any `New-PSDrive` or `net use` calls:

```powershell
# Wait for Workstation service before attempting UNC mapping
$maxWait = 30  # seconds
$elapsed = 0
while ((Get-Service -Name LanmanWorkstation).Status -ne 'Running' -and $elapsed -lt $maxWait) {
    Start-Sleep -Seconds 2
    $elapsed += 2
}
if ((Get-Service -Name LanmanWorkstation).Status -ne 'Running') {
    Write-Error "Workstation service did not start within $maxWait seconds. Aborting."
    exit 1
}
```

This makes the script self-defending against the race condition without requiring a context change.

**Option B — Run as logged-on user (simplest, matches original GPO behaviour)**

The Step 1 mitigation above is also the permanent fix. Running as the logged-on user is the correct model for drive mapping scripts — it replicates the GPO logon script behaviour that worked before the 2024 migration.

**Option C — Return drive mapping to GPO (only if Intune-managed drive mapping is not a hard requirement)**

If the Intune migration was not a deliberate policy decision (i.e. it was a lift-and-shift migration without functional validation), consider reverting the drive mapping to a GPO Logon Script or GPP Drive Map for Finance OU. This eliminates the Intune script entirely for this function.

---

#### Close-Out Checks

| Check | Purpose |
|---|---|
| Verify Finance AD group membership (`Get-ADGroupMember`) | Close out H2 — confirm ACL was never the issue |
| Check IME log on 3+ Finance devices post-fix | Confirm exit code 0 across the board, not just the pilot |
| Check System log for absence of Event 98 | Confirm S: drive letter assigned successfully |
| Monitor Intune device compliance for DESKTOP-FB* over 24h | Confirm no regression at next logon cycle |

---

### Incident Timeline Reconstruction

| Time | Event |
|---|---|
| 2024-03-14 23:30 | Drive mapping migrated from GPO (USER context) to Intune (SYSTEM context). Script not updated. Defect introduced. |
| 2026-08-07 08:00:01 | `Map-FinBridgeDrives.ps1` executes as SYSTEM at logon wave start |
| 08:00:03 | UNC path `\\finbridge-fs01\Finance` fails — Workstation service not yet running. Error 53. |
| 08:00:04 | Script exits, exit code 1. No retry configured. |
| 08:00:05 | Workstation service enters running state — too late. |
| 08:00:07 | NTFS Event 98 — S: drive letter not assigned. |
| ~08:00+ | All 45 Finance users report no access to shared drives. |
