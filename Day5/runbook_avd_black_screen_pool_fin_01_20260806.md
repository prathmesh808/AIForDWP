# Runbook: AVD Black Screen — POOL-FIN-01 Graphics Stack Regression
 Engineers  
**Reference RCA:** `Day3\rca_avd_black_screen_pool_fin_01_20260806.md`

---

## 1. Prerequisites

Confirm every item below before starting. Do not proceed if any item is missing.

### Access
- [ ] **[ELEVATED]** AVD Host Pool Contributor role (or higher) on POOL-FIN-01 in Azure portal — needed to set drain mode
- [ ] **[ELEVATED]** Local Administrator on POOL-FIN-01 session hosts — needed to apply registry mitigation and restart hosts
- [ ] **[ELEVATED]** Access to the image management pipeline / image console — needed for permanent remediation
- [ ] RDP or Azure Bastion access to individual session hosts (e.g. SHFIN-01-A)
- [ ] Read access to Windows Event Viewer on affected session hosts

### Tools
- Azure portal (https://portal.azure.com) — AVD Host Pool and VM management
- Remote Desktop client or Azure Bastion — direct session host access
- Windows Event Viewer — built into session host OS
- PowerShell (Run as Administrator) on session host — for registry changes and restarts

### Information to Have Ready
- Name of the affected pool: **POOL-FIN-01**
- Name of the healthy comparison pool: **POOL-FIN-02**
- At least one affected session host name (e.g. SHFIN-01-A) — from Azure portal > AVD > Host Pools > POOL-FIN-01 > Session Hosts
- The **previous known-good image version** tag for POOL-FIN-01 — from your image deployment log (needed for rollback)

### When to Use This Runbook
Use this runbook when **all three** of the following are true:
1. POOL-FIN-01 users report black screen immediately after login
2. Symptom began after an overnight image update to POOL-FIN-01
3. POOL-FIN-02 users are unaffected

---

## 2. Procedure

### Phase A — Confirm the Root Cause (Do Not Skip)

**Step 1.** In the Azure portal, go to **Azure Virtual Desktop → Host Pools → POOL-FIN-01 → Session Hosts** and note the name of at least one affected host (e.g. SHFIN-01-A).  
*Expected: You have at least one host name to work with.*

**Step 2.** Connect to the affected host (e.g. SHFIN-01-A) via Azure Bastion or RDP using your admin account.  
*Expected: You have a PowerShell or desktop session on the host.*

**Step 3.** On the affected host, open **Event Viewer → Windows Logs → Application**. Filter for **Event ID 1000** in the last 4 hours.  
*Expected: You see at least one entry where `Faulting application name` = `dwm.exe` AND `Faulting module name` = `igdumd64.dll` with exception code `0xc0000005`.*

**Step 4.** In the same Event Viewer session, go to **Windows Logs → Application** and filter for **Event ID 9009** (source: Desktop Window Manager) in the same 4-hour window.  
*Expected: Multiple Event 9009 entries, timestamped within seconds of the Event 1000 entries from Step 3.*

**Step 5.** Connect to the **unaffected comparison host** SHFIN-02-A (from POOL-FIN-02) via Azure Bastion or RDP. Open Event Viewer and check for Event ID 1000 with `dwm.exe` / `igdumd64.dll` in the same 4-hour window.  
*Expected: No matching Event 1000 entries. If SHFIN-02-A also shows crashes — **stop**, do not continue, escalate to L3 as this is a different incident.*

> **Decision gate:** Only continue to Phase B if Steps 3–4 confirmed the crash pattern on POOL-FIN-01 **and** Step 5 confirmed POOL-FIN-02 is clean.

---

### Phase B — Containment (Stop New Users Hitting Broken Hosts)

> **[ELEVATED]** Steps 6–8 require AVD Host Pool Contributor role.

**Step 6.** In the Azure portal, go to **Azure Virtual Desktop → Host Pools → POOL-FIN-01 → Session Hosts**. Click the first affected host → **Settings** → set **Allow new sessions** to **No** → click **Save**.  
*Expected: The host shows drain mode active; no new sessions will be routed to it.*

**Step 7.** Repeat Step 6 for every remaining session host in POOL-FIN-01.  
*Expected: All POOL-FIN-01 hosts have "Allow new sessions = No".*

**Step 8.** In the Azure portal, go to **Azure Virtual Desktop → Host Pools → POOL-FIN-02 → Session Hosts** and confirm at least one host shows **Status = Available** and **Allow new sessions = Yes**.  
*Expected: POOL-FIN-02 can receive redirected users. If it cannot, stop and contact the AVD capacity team before proceeding.*

**Step 9.** Send the following message to affected users via Teams or email:  
> "We are aware of a login issue with the Finance AVD environment. Please disconnect and reconnect — you will be routed to a stable session. Apologies for the disruption."  
*Expected: Users are informed and will attempt reconnection to POOL-FIN-02.*

---

### Phase C — Mitigation (Software Rendering Bypass Per Host)

> Apply to each POOL-FIN-01 host individually. This bypasses the faulty Intel hardware acceleration path without a full image rollback.

> **[ELEVATED]** Steps 10–13 require local Administrator on the session host.

**Step 10.** Connect to the first drained POOL-FIN-01 host (e.g. SHFIN-01-A) via Azure Bastion or RDP using your admin account.  
*Expected: You have an administrative session on the host.*

**Step 11.** Open **PowerShell as Administrator** on the host and run:

```powershell
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AEDEBUG" `
    -Name "DisableHWAcceleration" -Value 1 -Type DWord -Force
```

*Expected: Command completes with no error output.*

**Step 12.** Verify the key was written by running:

```powershell
Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AEDEBUG" `
    -Name "DisableHWAcceleration"
```

*Expected: Output shows `DisableHWAcceleration : 1`.*

**Step 13.** Restart the host:

```powershell
Restart-Computer -Force
```

*Expected: Host reboots. Wait 2–3 minutes before connecting again.*

**Step 14.** After the host is back online, connect a test session using your **standard (non-admin) test account**.  
*Expected: Desktop loads fully within 30 seconds. No black screen.*

**Step 15.** On the host, open **Event Viewer → Windows Logs → Application** and confirm there are **no new Event ID 1000** entries for `dwm.exe` / `igdumd64.dll` since the reboot.  
*Expected: Zero matching crash events post-reboot.*

**Step 16.** In the Azure portal, go to **Azure Virtual Desktop → Host Pools → POOL-FIN-01 → Session Hosts** → click the host → **Settings** → set **Allow new sessions** to **Yes** → click **Save**.  
*Expected: Host is returned to rotation and accepting new sessions.*

**Step 17.** Repeat Steps 10–16 for each remaining POOL-FIN-01 session host, one at a time.  
*Expected: All POOL-FIN-01 hosts are back online with the software rendering mitigation applied.*

---

### Phase D — Permanent Remediation (Image Correction)

> **[ELEVATED]** Requires access to the image management pipeline.

**Step 18.** Raise a task with the **EUC Platform/Image Team** and provide: (a) the exact image version deployed overnight to POOL-FIN-01, and (b) the previous known-good image version. Request identification of the graphics driver change between versions.  
*Expected: Image Team confirms the specific Intel graphics driver package introduced in the update.*

**Step 19.** The Image Team rebuilds the POOL-FIN-01 image, reverting to the last known-good Intel graphics driver or applying a validated replacement. Do not proceed until the Image Team confirms the new image is ready.  
*Expected: A new corrected image version is available in the image pipeline.*

**Step 20.** The Image Team runs pre-production smoke tests on the corrected image: fresh logon, reconnect, idle resume, Teams/video render, Office launch. Confirm zero Event 1000 (dwm.exe + igdumd64.dll) entries during testing.  
*Expected: All smoke tests pass with no DWM crashes.*

**Step 21.** Deploy the corrected image to **one POOL-FIN-01 host only** (canary). Perform the verification checks in Section 3 (V1–V4) on that host before continuing.  
*Expected: Canary host passes all verification checks.*

**Step 22.** Deploy the corrected image to the remaining POOL-FIN-01 hosts one at a time, verifying each host after deployment before moving to the next.  
*Expected: All POOL-FIN-01 hosts running the corrected image.*

**Step 23.** On each host now running the corrected image, open **PowerShell as Administrator** and remove the temporary mitigation registry key:

```powershell
Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AEDEBUG" `
    -Name "DisableHWAcceleration" -ErrorAction SilentlyContinue
```

*Expected: Command completes with no error.*

**Step 24.** Restart each host after removing the mitigation key (run `Restart-Computer -Force` in an elevated PowerShell session and wait 2–3 minutes).  
*Expected: Host reboots onto the corrected image with hardware acceleration active.*

---

## 3. Verification

Complete **all six checks** before closing the incident. Do not close if any check fails.

**V1.** Log in to POOL-FIN-01 using a **standard test account** (not your admin account). Confirm the desktop loads fully within 30 seconds.  
*Pass: Desktop visible, no black screen.*

**V2.** Log out, then immediately reconnect with the same test account.  
*Pass: Reconnect succeeds, no black screen, desktop loads within 30 seconds.*

**V3.** On each POOL-FIN-01 session host, open **Event Viewer → Windows Logs → Application** and confirm there are no Event ID 1000 entries for `dwm.exe` in the last 30 minutes.  
*Pass: Zero matching entries.*

**V4.** On each POOL-FIN-01 session host, open **Event Viewer → Applications and Services Logs → Microsoft → Windows → Desktop Window Manager-Operational** and confirm Event ID **9011** (DWM started successfully) is present after the last reboot with no **9009** (DWM exited) after it.  
*Pass: 9011 present post-reboot, no subsequent 9009.*

**V5.** In the Azure portal, go to **Azure Virtual Desktop → Host Pools → POOL-FIN-01 → Session Hosts** and confirm **all hosts** show **Allow new sessions = Yes** and **Status = Available**.  
*Pass: All hosts fully in rotation.*

**V6.** Contact at least one user who was affected and confirm they can log in successfully with no black screen.  
*Pass: User confirms successful login.*

---

## 4. Rollback

Use this section **immediately** if the mitigation in Phase C makes things worse — for example: hosts become unresponsive after reboot, DWM crashes persist, or new symptoms appear. Every step below is immediately actionable.

> **[ELEVATED]** All rollback steps require AVD Host Pool Contributor and local Administrator access.

**R1.** In the Azure portal, go to **Azure Virtual Desktop → Host Pools → POOL-FIN-01 → Session Hosts**. For each host: click the host → **Settings** → set **Allow new sessions** to **No** → **Save**.  
*Action: Stops all new users from hitting broken hosts immediately.*

**R2.** In the Azure portal, go to **Azure Virtual Desktop → Host Pools → POOL-FIN-02 → Session Hosts** and confirm **Allow new sessions = Yes** on all POOL-FIN-02 hosts.  
*Action: Ensures users can reconnect to the healthy pool.*

**R3.** Send the following message to affected users:  
> "Finance AVD login issue ongoing. Please connect via POOL-FIN-02 until further notice."  
*Action: Stops users from retrying POOL-FIN-01.*

**R4.** If the software rendering mitigation key (Step 11) caused instability, connect to each affected POOL-FIN-01 host via Azure Bastion and run in an elevated PowerShell session:

```powershell
Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AEDEBUG" `
    -Name "DisableHWAcceleration" -ErrorAction SilentlyContinue
Restart-Computer -Force
```

*Action: Removes the mitigation key and reboots. The host will return to the pre-mitigation black-screen state — keep it drained until image rollback in R5 is complete.*

**R5.** Contact the **EUC Platform/Image Team** and request an emergency rollback of POOL-FIN-01 to the **previous known-good image version** (provide the exact version tag you noted in Prerequisites). Do not attempt to re-image hosts yourself without the Image Team.  
*Action: Initiates controlled image rollback.*

**R6.** After the Image Team re-images the first host, perform a test logon (V1 from Section 3) before enabling it. Only enable the host if V1 passes.  
*Action: Validates each host individually before returning to service.*

**R7.** Once all POOL-FIN-01 hosts are confirmed healthy on the rolled-back image, set **Allow new sessions = Yes** on all of them in the Azure portal.  
*Action: Returns POOL-FIN-01 to full service.*

**R8.** Notify users that POOL-FIN-01 is restored and they may reconnect normally.

> **Escalation trigger:** If Event ID 1000 (dwm.exe + igdumd64.dll) and Event 9009 still appear after image rollback in R5–R6, escalate immediately to L3 and the EUC Platform team — this is outside the scope of this runbook.

---

## 5. Notes

### Edge Cases
- **Some users get through, others do not:** This is expected — the crash is non-deterministic per session. Do not assume the pool is healthy because some users logged in. Require full Section 3 verification before clearing the incident.
- **POOL-FIN-02 at capacity:** If POOL-FIN-02 cannot absorb all redirected users, contact the AVD capacity team to scale out POOL-FIN-02 **before** completing Step 7. Do not drain all of POOL-FIN-01 if there is nowhere for users to go.
- **Software rendering mitigation not enough:** If Event 1000 (dwm.exe + igdumd64.dll) continues after applying Step 11 and rebooting, do not try additional registry changes. Go directly to image rollback (Section 4, steps R5 onwards).
- **Multiple pools affected:** If POOL-FIN-02 also starts showing black screens (Step 5 fails), this runbook does not apply. Stop, escalate to L3, and investigate a wider platform or broker issue.
- **Registry path in Step 11 may not exist:** PowerShell will create it automatically. Always confirm with Step 12 before restarting.

### Warnings
- **Do not remove drain mode prematurely.** Always complete V1–V4 in Section 3 before setting a host back to "Allow new sessions = Yes".
- **The software rendering mitigation (Step 11) degrades rendering performance.** It is temporary only. It must be removed (Steps 23–24) once the corrected image is deployed.
- **Do not apply the image correction (Phase D) without the Image Team's pre-production smoke tests.** Deploying an untested corrected image can introduce new regressions.

### Preventive Controls (For Reference)
The following controls were added after this incident to prevent recurrence:
- Mandatory post-image AVD smoke tests before promotion (fresh logon, reconnect, idle resume, Teams/video, Office launch)
- Deployment blocker: any Event 1000 where process = dwm.exe and module = igdumd64.dll fails image promotion
- Automated alerting for DWM crash signatures (Event 1000 + Event 9009 correlation) in the first 2 hours after rollout
- Phased rollout with explicit pause-and-verify checkpoints before each wave

### Related Documents
- **RCA:** `Day3\rca_avd_black_screen_pool_fin_01_20260806.md`
- **Closure note:** `Day4\closure_note_avd_black_screen_pool_fin_01_20260806.md`
- **Known error record:** `Day4\known_error_avd_black_screen_pool_fin_01_20260806.md`
- **End-user communication template:** `Day4\end_user_communication_avd_black_screen_20260806.md`
- **Hypothesis log:** `Day4\avd_black_screen_hypothesis_pool_fin_20260806.md`

### Key Event IDs for This Incident
| Event ID | Log | Source | Meaning |
|----------|-----|--------|---------|
| 1000 | Application | Application Error | dwm.exe crash in igdumd64.dll (exception 0xc0000005) |
| 9009 | DWM-Operational | Desktop Window Manager | DWM terminated unexpectedly |
| 9011 | DWM-Operational | Desktop Window Manager | DWM started successfully (healthy baseline) |
| 21 | LSM-Operational | TerminalServices-LocalSessionManager | User session logon succeeded |
| 40 | LSM-Operational | TerminalServices-LocalSessionManager | User session disconnected |
