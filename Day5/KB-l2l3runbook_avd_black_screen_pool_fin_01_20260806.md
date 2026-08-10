# Runbook: AVD Black Screen — POOL-FIN-01 Graphics Stack Regression

**KB ID:** KB-L2L3-AVD-001  
**Version:** v2.0  
**Date:** 2026-08-10  
**Status:** Active  
**Audience:** L2/L3 DWP Engineers  
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

This matters because finance users depend on stable interactive sessions during business hours. If DWM crashes during logon, users either see a persistent black screen, delayed shell initialization, or are disconnected shortly after successful authentication. A prolonged issue can cause pool-wide business impact and force emergency redirection to `POOL-FIN-02`.

## Symptom

What engineers observe:

- In `Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Monitor > User sessions`, users connect and disconnect repeatedly.
- In `Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Manage > Session hosts`, hosts are `Available` but user sessions remain unstable.
- `POOL-FIN-02` remains healthy and can accept sessions, indicating a pool-specific pattern.

What users report:

- Black screen after sign-in.
- Desktop eventually appears after a long delay, or the session disconnects within minutes.
- Behavior often starts after overnight image updates.
- Issue is repeatable for multiple users in `POOL-FIN-01`.

## Root Cause

Specific technical cause:

- A regressed Intel graphics stack in the updated `POOL-FIN-01` image causes `dwm.exe` to crash via `igdumd64.dll` during user logon and desktop composition.

Evidence that confirms this root cause:

- `Event ID 1000` (Application Error) in `Event Viewer > Windows Logs > Application`.
- In that event, field `Faulting application name` = `dwm.exe`.
- In that event, field `Faulting module name` = `igdumd64.dll`.
- `Event ID 9009` in `Event Viewer > Applications and Services Logs > Microsoft > Windows > Desktop Window Manager-Operational` in the same time window.
- `Event ID 21` followed by `Event ID 40` in `Event Viewer > Applications and Services Logs > Microsoft > Windows > TerminalServices-LocalSessionManager > Operational` for the same user/session window.
- Pool comparison: same pattern present in `POOL-FIN-01`, absent in `POOL-FIN-02`.

## Detection

Use this section to confirm the incident in under 3 minutes before remediation.

### Fast path (command-first)

1. Identify one affected host from `POOL-FIN-01` and one healthy control host from `POOL-FIN-02`.
Portal paths:
- `Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Manage > Session hosts`
- `Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-02 > Manage > Session hosts`
Expected result: You have `<fin01-host>` (suspected) and `<fin02-host>` (control).

2. Run this PowerShell on your admin workstation (with Az modules and access) to pull all required evidence from both hosts without opening Event Viewer.

```powershell
# Inputs
$resourceGroup = "<resource-group>"
$fin01Host = "<fin01-host>"
$fin02Host = "<fin02-host>"

# Script that runs inside each VM
$collectScript = @'
$start = (Get-Date).AddHours(-4)

"=== Application log: Event ID 1000 (Faulting app/module) ==="
Get-WinEvent -FilterHashtable @{LogName='Application'; Id=1000; StartTime=$start} |
	Select-Object -First 20 TimeCreated, MachineName,
		@{n='FaultingApplication';e={($_.Message -split "`n" | Where-Object {$_ -match 'Faulting application name:'} | Select-Object -First 1).Trim()}},
		@{n='FaultingModule';e={($_.Message -split "`n" | Where-Object {$_ -match 'Faulting module name:'} | Select-Object -First 1).Trim()}}

"=== DWM Operational log: Event ID 9009 ==="
Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-Desktop Window Manager/Operational'; Id=9009; StartTime=$start} |
	Select-Object -First 20 TimeCreated, MachineName, Id, Message

"=== DWM Operational log: Event ID 9011 (healthy control baseline) ==="
Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-Desktop Window Manager/Operational'; Id=9011; StartTime=$start} |
	Select-Object -First 20 TimeCreated, MachineName, Id, Message

"=== LSM Operational log: Event IDs 21 and 40 ==="
Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-TerminalServices-LocalSessionManager/Operational'; Id=21,40; StartTime=$start} |
	Select-Object -First 40 TimeCreated, MachineName, Id, Message
'@

Invoke-AzVMRunCommand -ResourceGroupName $resourceGroup -VMName $fin01Host -CommandId 'RunPowerShellScript' -ScriptString $collectScript
Invoke-AzVMRunCommand -ResourceGroupName $resourceGroup -VMName $fin02Host -CommandId 'RunPowerShellScript' -ScriptString $collectScript
```

Expected result: Output shows exact events and message fields for both pools.

3. Optional Azure CLI equivalent (if using `az` instead of Az PowerShell).

```bash
az vm run-command invoke \
	--resource-group <resource-group> \
	--name <fin01-host> \
	--command-id RunPowerShellScript \
	--scripts "Get-WinEvent -FilterHashtable @{LogName='Application'; Id=1000; StartTime=(Get-Date).AddHours(-4)} | Select-Object -First 10 TimeCreated,MachineName,Message"

az vm run-command invoke \
	--resource-group <resource-group> \
	--name <fin01-host> \
	--command-id RunPowerShellScript \
	--scripts "Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-Desktop Window Manager/Operational'; Id=9009; StartTime=(Get-Date).AddHours(-4)} | Select-Object -First 10 TimeCreated,MachineName,Id,Message"

az vm run-command invoke \
	--resource-group <resource-group> \
	--name <fin02-host> \
	--command-id RunPowerShellScript \
	--scripts "Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-Desktop Window Manager/Operational'; Id=9011; StartTime=(Get-Date).AddHours(-4)} | Select-Object -First 10 TimeCreated,MachineName,Id,Message"
```

Expected result: CLI output confirms failed signature on `POOL-FIN-01` and healthy baseline on `POOL-FIN-02`.

### Pass/Fail criteria (must all pass)

1. Exact log location for crash evidence:
- `Event Viewer > Windows Logs > Application`
- `Event ID 1000`
- Required fields in event message:
	- `Faulting application name: dwm.exe`
	- `Faulting module name: igdumd64.dll`
Expected result: At least one matching `1000` event in incident window on `POOL-FIN-01` host.

2. Exact log location for DWM failure evidence:
- `Event Viewer > Applications and Services Logs > Microsoft > Windows > Desktop Window Manager-Operational`
- `Event ID 9009`
Expected result: `9009` present in same timeframe as `1000` on `POOL-FIN-01`.

3. Exact log location for session impact evidence:
- `Event Viewer > Applications and Services Logs > Microsoft > Windows > TerminalServices-LocalSessionManager > Operational`
- `Event IDs 21 and 40`
Expected result: `21` followed by `40` for impacted session in same window.

4. Healthy baseline comparison (required control):
- Control host in `POOL-FIN-02`
- `Event Viewer > Applications and Services Logs > Microsoft > Windows > Desktop Window Manager-Operational`
- `Event ID 9011` observed as healthy operational baseline on control host, while `1000 (dwm.exe/igdumd64.dll)` and correlated `9009` failure pattern are absent.
Expected result: Baseline supports pool-specific failure in `POOL-FIN-01`.

5. Final diagnosis rule:
- Confirm this incident only when the following correlation is present on `POOL-FIN-01`:
	- `Event 1000` in Application with `dwm.exe` + `igdumd64.dll`
	- `Event 9009` in DWM Operational in same window
	- Session pattern `21 -> 40` in LSM Operational
	- Control comparison on `POOL-FIN-02` aligns with healthy `Event 9011` baseline
Expected result: Engineer can declare this KB as confirmed root-cause pattern and proceed to Resolution.

## Resolution

Target completion: 5-10 minutes for containment and first-host remediation.

### Portal quick path (exact location/options)

1. Contain affected hosts.
Path: `Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Manage > Session hosts > <host> > Settings`.
Option: set `Allow new sessions` to `No`, then select `Save`.
Expected result: `POOL-FIN-01` affected host is drained and stops taking new sessions.

2. Confirm redirection capacity before continuing.
Path: `Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-02 > Manage > Session hosts`.
Option: confirm at least one host is `Available`.
Expected result: Safe comparison/fallback pool is ready.

3. Remediate first host.
Path: `Azure portal > Virtual machines > <affected-host> > Connect`.
Option: open approved admin session and run the approved graphics mitigation package.
Expected result: Mitigation package completes without error.

4. Restart remediated host.
Path: `Azure portal > Virtual machines > <affected-host> > Overview`.
Option: select `Restart`.
Expected result: VM returns online.

5. Re-enable first stable host.
Path: `Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Manage > Session hosts > <affected-host> > Settings`.
Option: set `Allow new sessions` to `Yes`, then select `Save`.
Expected result: Only validated host is returned to service.

6. Correct image source for remaining hosts.
Path: `Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Properties`.
Option: capture current image/source reference, then in team image console set corrected image for `POOL-FIN-01` and deploy canary first.
Expected result: Corrected image version is active for staged rollout.

7. Roll out to remaining affected hosts one by one.
Path: `Azure portal > Virtual machines > <host> > Overview > Restart` and `Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Manage > Session hosts > <host> > Settings`.
Option: restart, validate, then set `Allow new sessions = Yes`.
Expected result: `POOL-FIN-01` restored without mass reintroduction risk.

### Command quick path (PowerShell / Azure CLI)

```powershell
# Inputs
$subId = "<subscription-id>"
$rg = "<resource-group>"
$hpFin01 = "POOL-FIN-01"
$hpFin02 = "POOL-FIN-02"
$affectedHosts = @("<fin01-host1>","<fin01-host2>")   # VM names
$sessionHostNames = @("<fin01-host1.fqdn>","<fin01-host2.fqdn>")  # AVD session-host resource names

Set-AzContext -Subscription $subId

# 1) Drain impacted session hosts
foreach ($sh in $sessionHostNames) {
	az desktopvirtualization session-host update --resource-group $rg --host-pool-name $hpFin01 --name $sh --allow-new-session false | Out-Null
}

# 2) Confirm POOL-FIN-02 capacity snapshot
az desktopvirtualization session-host list --resource-group $rg --host-pool-name $hpFin02 --query "[].{name:name,status:status,allowNewSession:allowNewSession,sessions:sessions}" -o table

# 3) Run approved mitigation package remotely on first affected VM (example path placeholder)
$mitigationScript = @'
Start-Process -FilePath "C:\Temp\ApprovedGraphicsMitigation\mitigation.exe" -ArgumentList "/quiet /norestart" -Wait
'@
Invoke-AzVMRunCommand -ResourceGroupName $rg -VMName $affectedHosts[0] -CommandId 'RunPowerShellScript' -ScriptString $mitigationScript | Out-Null

# 4) Restart first VM
az vm restart --resource-group $rg --name $affectedHosts[0]

# 5) Return first validated host to service
az desktopvirtualization session-host update --resource-group $rg --host-pool-name $hpFin01 --name $sessionHostNames[0] --allow-new-session true | Out-Null
```

```bash
# Equivalent CLI examples
az desktopvirtualization session-host update --resource-group <rg> --host-pool-name POOL-FIN-01 --name <fin01-host1.fqdn> --allow-new-session false
az desktopvirtualization session-host list --resource-group <rg> --host-pool-name POOL-FIN-02 -o table
az vm run-command invoke --resource-group <rg> --name <fin01-host1> --command-id RunPowerShellScript --scripts "Start-Process 'C:\Temp\ApprovedGraphicsMitigation\mitigation.exe' -ArgumentList '/quiet /norestart' -Wait"
az vm restart --resource-group <rg> --name <fin01-host1>
az desktopvirtualization session-host update --resource-group <rg> --host-pool-name POOL-FIN-01 --name <fin01-host1.fqdn> --allow-new-session true
```

## Verification

### Portal quick path (exact location/options)

1. Confirm host settings on remediated pool.
Path: `Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Manage > Session hosts`.
Option: verify each remediated host shows `Status = Available` and `Allow new sessions = Yes`.
Expected result: Host settings are correct for production use.

2. Confirm user session behavior.
Path: `Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Monitor > User sessions`.
Option: verify new sessions are opening and staying connected.
Expected result: No immediate disconnect churn.

3. Confirm control pool health.
Path: `Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-02 > Monitor > User sessions`.
Option: verify no overload signs during redirection period.
Expected result: Comparison pool remains stable.

4. Confirm log-level recovery on at least two remediated hosts.
Paths:
- `Event Viewer > Windows Logs > Application` filter `Event ID 1000`
- `Event Viewer > Applications and Services Logs > Microsoft > Windows > Desktop Window Manager-Operational` filter `Event IDs 9009,9011`
- `Event Viewer > Applications and Services Logs > Microsoft > Windows > TerminalServices-LocalSessionManager > Operational` filter `Event IDs 21,40`
Option: verify no new `1000 (dwm.exe / igdumd64.dll)` and no new `9009` in validation window.
Expected result: Failure signature cleared; baseline behavior returns.

### Command quick path (PowerShell / Azure CLI)

```powershell
$rg = "<resource-group>"
$hpFin01 = "POOL-FIN-01"
$hpFin02 = "POOL-FIN-02"

# Host/session status verification
az desktopvirtualization session-host list --resource-group $rg --host-pool-name $hpFin01 --query "[].{name:name,status:status,allowNewSession:allowNewSession,sessions:sessions}" -o table
az desktopvirtualization user-session list --resource-group $rg --host-pool-name $hpFin01 --query "[].{session:sessionHostName,user:userPrincipalName,state:sessionState}" -o table
az desktopvirtualization user-session list --resource-group $rg --host-pool-name $hpFin02 --query "[].{session:sessionHostName,user:userPrincipalName,state:sessionState}" -o table

# Log verification on two hosts
$hostsToCheck = @("<fin01-host1>","<fin01-host2>")
$verifyScript = @'
$start=(Get-Date).AddMinutes(-30)
Get-WinEvent -FilterHashtable @{LogName='Application';Id=1000;StartTime=$start} |
	Where-Object {$_.Message -match 'Faulting application name:\s*dwm.exe' -and $_.Message -match 'Faulting module name:\s*igdumd64.dll'} |
	Select-Object TimeCreated,MachineName,Id,Message
Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-Desktop Window Manager/Operational';Id=9009,9011;StartTime=$start} |
	Select-Object TimeCreated,MachineName,Id,Message
Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-TerminalServices-LocalSessionManager/Operational';Id=21,40;StartTime=$start} |
	Select-Object TimeCreated,MachineName,Id,Message
'@
foreach($h in $hostsToCheck){ Invoke-AzVMRunCommand -ResourceGroupName $rg -VMName $h -CommandId 'RunPowerShellScript' -ScriptString $verifyScript | Out-Null }
```

## Rollback

If remediation worsens impact, execute immediately.

### Portal quick path (exact location/options)

1. Re-contain unstable hosts.
Path: `Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Manage > Session hosts > <host> > Settings`.
Option: set `Allow new sessions = No`, then `Save`.
Expected result: Additional user impact is stopped.

2. Protect landing pool capacity.
Path: `Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-02 > Manage > Session hosts`.
Option: verify `Available` capacity before forcing user sign-out on bad hosts.
Expected result: Users can reconnect to healthy capacity.

3. Roll image source back to last known-good.
Path: `Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Properties`.
Option: confirm current source reference; in team image console set `Last known-good image version` as active for `POOL-FIN-01` and pause current rollout.
Expected result: New deployments stop using bad image.

4. Validate rollback canary.
Path: `Azure portal > Virtual machines > <rollback-canary-host> > Overview > Restart`, then `Azure portal > Virtual machines > <rollback-canary-host> > Connect`.
Option: restart, connect, run Detection checks.
Expected result: Canary no longer shows failure signature.

5. Restore service in waves.
Path: `Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Manage > Session hosts > <host> > Settings`.
Option: set `Allow new sessions = Yes` only after per-host validation.
Expected result: Stable rollback with controlled blast radius.

### Command quick path (PowerShell / Azure CLI)

```powershell
$rg = "<resource-group>"
$hpFin01 = "POOL-FIN-01"
$rollbackSessionHosts = @("<fin01-host1.fqdn>","<fin01-host2.fqdn>")
$rollbackVms = @("<fin01-host1>","<fin01-host2>")

# 1) Re-drain hosts immediately
foreach($sh in $rollbackSessionHosts){
	az desktopvirtualization session-host update --resource-group $rg --host-pool-name $hpFin01 --name $sh --allow-new-session false | Out-Null
}

# 2) Restart rollback canary after known-good image assignment in image console
az vm restart --resource-group $rg --name $rollbackVms[0]

# 3) Validate canary quickly
$rbScript = @'
$start=(Get-Date).AddMinutes(-30)
Get-WinEvent -FilterHashtable @{LogName='Application';Id=1000;StartTime=$start} |
	Where-Object {$_.Message -match 'Faulting application name:\s*dwm.exe' -and $_.Message -match 'Faulting module name:\s*igdumd64.dll'} |
	Select-Object TimeCreated,MachineName,Id
Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-Desktop Window Manager/Operational';Id=9009,9011;StartTime=$start} |
	Select-Object TimeCreated,MachineName,Id
'@
Invoke-AzVMRunCommand -ResourceGroupName $rg -VMName $rollbackVms[0] -CommandId 'RunPowerShellScript' -ScriptString $rbScript | Out-Null

# 4) Re-enable validated hosts in waves
foreach($sh in $rollbackSessionHosts){
	az desktopvirtualization session-host update --resource-group $rg --host-pool-name $hpFin01 --name $sh --allow-new-session true | Out-Null
}
```

```bash
az desktopvirtualization session-host update --resource-group <rg> --host-pool-name POOL-FIN-01 --name <fin01-host1.fqdn> --allow-new-session false
az vm restart --resource-group <rg> --name <rollback-canary-host>
az vm run-command invoke --resource-group <rg> --name <rollback-canary-host> --command-id RunPowerShellScript --scripts "Get-WinEvent -FilterHashtable @{LogName='Application';Id=1000;StartTime=(Get-Date).AddMinutes(-30)} | Select-Object TimeCreated,Id,Message"
az desktopvirtualization session-host update --resource-group <rg> --host-pool-name POOL-FIN-01 --name <fin01-host1.fqdn> --allow-new-session true
```

Escalate to EUC Platform/Image Team if rollback canary still shows `Event 1000 (dwm.exe + igdumd64.dll)` and `Event 9009` correlation.

## Preventive

Implement these specific controls to prevent recurrence:

1. Image promotion gate with event-driven quality criteria.
Owner/Timing: Release engineer + image owner, before deployment.
Method: Automated 24-hour canary on one `POOL-FIN-01` host [REQUIRES: release pipeline gate + log query job].
Pass/Fail: Pass only if count of `Event ID 1000 (dwm.exe + igdumd64.dll)` = 0 and `Event ID 9009` = 0; fail on any match.
If fail: Change manager blocks promotion, keeps canary drained, opens defect to image owner.

2. Driver baseline pinning in image pipeline.
Owner/Timing: Image owner, before deployment.
Method: Automated driver allowlist check against approved Intel version/date [REQUIRES: image build validation script].
Pass/Fail: Pass if detected version/date equals approved baseline; fail if mismatch or missing metadata.
If fail: Pipeline stops publication; release engineer requires CAB-approved exception to continue.

3. Automated synthetic sign-in and log correlation test.
Owner/Timing: Release engineer, before deployment.
Method: Automated synthetic sign-in after each image build with event correlation `21 -> 1000 -> 9009 -> 40` in 15 minutes.
Pass/Fail: Pass if zero correlated chains and session remains connected >= 10 minutes; fail if chain count >= 1.
If fail: Build is rejected and image is not promoted beyond canary.

4. Pool safety guardrail for redirection events.
Owner/Timing: DWP engineer, during deployment.
Method: Manual capacity check on `POOL-FIN-02` before each drain wave; automation approach: query session host capacity via scheduled script.
Pass/Fail: Pass if `POOL-FIN-02` available hosts >= 1 and projected load < 80%; fail if threshold exceeded.
If fail: Limit drain to <= 30% of `POOL-FIN-01` hosts per wave and pause next wave.

5. Proactive monitoring and alerting.
Owner/Timing: Service desk lead, during deployment and after deployment.
Method: Automated Azure Monitor alerts for `1000 (dwm.exe + igdumd64.dll)`, `9009`, and `40` surge after `21` [REQUIRES: alert rules + action group].
Pass/Fail: Pass if alert count stays below threshold (0 critical alerts per 30 minutes); fail if threshold breached.
If fail: Trigger incident bridge and start rollback trigger control immediately.

6. Pre-deployment smoke test gate (before release).
Owner/Timing: DWP engineer, before deployment.
Method: Manual smoke test on canary: sign in, launch shell and 2 core finance apps; automation approach: scripted AVD sign-in + app launch check [REQUIRES: synthetic test harness].
Pass/Fail: Pass if desktop appears < 60 seconds and both apps open < 120 seconds with zero `1000/9009`; fail otherwise.
If fail: Do not start production rollout; return image to image owner for fix.

7. In-flight monitoring during rollout window.
Owner/Timing: Service desk lead, during deployment.
Method: Automated 5-minute rolling checks of `POOL-FIN-01` disconnect rate and `Event ID 9009` counts [REQUIRES: workbook/dashboard with thresholds].
Pass/Fail: Pass if disconnect rate < 3% and `9009` count = 0 per 5-minute bucket; fail on breach for 2 consecutive buckets.
If fail: Freeze rollout wave and execute rollback trigger control.

8. Post-deployment validation before change closure.
Owner/Timing: Change manager + DWP engineer, after deployment.
Method: Manual evidence review from two remediated hosts and both pools; automation approach: attach auto-generated validation report to change record.
Pass/Fail: Pass if 30-minute window shows zero `1000 (dwm.exe + igdumd64.dll)`, zero `9009`, and no `21->40` churn spike.
If fail: Keep change open, maintain controlled drain, and re-enter remediation/rollback.

9. Rollback trigger threshold.
Owner/Timing: DWP engineer, during deployment and after deployment.
Method: Automated trigger preferred; manual trigger allowed if alerts unavailable [REQUIRES: rollback runbook threshold in incident checklist].
Pass/Fail: Trigger rollback when any of: >= 1 `1000 (dwm.exe + igdumd64.dll)`, >= 2 `9009` in 10 minutes, or session disconnects > 5% in 10 minutes.
If fail: Set `Allow new sessions = No` on active wave hosts and revert to last known-good image canary.

10. Knowledge update and checklist hardening.
Owner/Timing: Change manager + image owner, after deployment.
Method: Manual update of KB/runbook/checklist within 1 business day; automation approach: mandatory post-incident task in change workflow [REQUIRES: change-template field enforcement].
Pass/Fail: Pass when updated KB version, new thresholds, and command snippets are published and peer-reviewed.
If fail: Block closure of problem record and CAB learning action remains open.

## Related

- Known error: `Day4\known_error_avd_black_screen_pool_fin_01_20260806.md`
- RCA: `Day3\rca_avd_black_screen_pool_fin_01_20260806.md`
- Closure note: `Day4\closure_note_avd_black_screen_pool_fin_01_20260806.md`
- End-user communication template: `Day4\end_user_communication_avd_black_screen_20260806.md`
- Adjacent investigations when signature does not match:
	- FSLogix/profile attach failures
	- Shell/AppX initialization failures
	- Group policy processing failures
	- AVD agent or broker-side logon issues