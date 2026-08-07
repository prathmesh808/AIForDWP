# RCA: AVD Black Screen on POOL-FIN-01

Date of report: 2026-08-06  
Prepared by: DWWP Engineering  
Incident status: Resolved

## 1) Executive Summary
At approximately 07:00, users connecting to POOL-FIN-01 began experiencing a black screen immediately after login. For some users, the screen recovered after about 30 seconds; for others, sessions disconnected or remained unusable. POOL-FIN-02 was unaffected.

The issue started after an overnight image update applied only to POOL-FIN-01 at 02:00. Event logs from affected hosts showed repeated Desktop Window Manager (dwm.exe) crashes in Intel graphics module igdumd64.dll, followed by DWM termination and user session disconnects.

The approved mitigation and remediation were applied, and service was verified healthy at 10:00. Users successfully logged in to POOL-FIN-01 with no further issues reported.

## 2) Scope and Impact
- Symptom: Black screen post-login; intermittent self-recovery for some users, persistent failure for others.
- Affected population: Approximately 40% of users assigned to POOL-FIN-01.
- Unaffected population: POOL-FIN-02 users.
- Service impact window: Approximately 07:00 to 10:00.
- Business impact: User productivity degradation and failed/unstable interactive sessions in finance pool.

## 3) Environment and Change Context
- Change event: Overnight image update to POOL-FIN-01 at 02:00.
- Control group: POOL-FIN-02 remained on pre-update image and did not exhibit the symptom.
- Host evidence source: SHFIN-01-A (affected) and SHFIN-02-A (unaffected comparison).

## 4) Supporting Evidence

### Affected Host Evidence (SHFIN-01-A)
- 07:02:10 - LSM Event 21: Session logon succeeded for FINBRIDGE\mlopez.
- 07:02:14 - Kernel-General Event 1: Host booted at 02:03:11 (post-image update reboot).
- 07:02:16 - Application Error Event 1000: Faulting app dwm.exe, faulting module igdumd64.dll, exception 0xc0000005.
- 07:02:17 - LSM Event 40: Session disconnected.
- 07:02:18 - DWM Event 9009: Desktop Window Manager exited.
- 07:02:44 - LSM Event 21: Reconnect logon succeeded.
- 07:02:46 - Application Error Event 1000: Repeat dwm.exe fault in igdumd64.dll.
- 07:02:47 - LSM Event 40: Session disconnected.
- 07:03:01 - DWM Event 9009: DWM exited again.
- 07:08:22 - LSM Event 21: Logon succeeded for FINBRIDGE\akapoor.
- 07:08:24 - Application Error Event 1000: Repeat dwm.exe fault in igdumd64.dll.

### Unaffected Comparison Evidence (SHFIN-02-A)
- 07:01:44 - LSM Event 21: Session logon succeeded.
- 07:01:46 - DWM Event 9011: DWM started successfully.
- No Application Error events in incident comparison window.

### Evidence Interpretation
- Authentication and session creation completed (multiple Event 21), indicating user identity and broker path were operational.
- Failure occurred in display composition path immediately after logon on affected pool (Event 1000 + Event 9009 + Event 40 sequence).
- Control pool behaved normally with healthy DWM startup and no crashes.
- Change isolation and event signatures align with graphics stack regression introduced by updated POOL-FIN-01 image.

## 5) Timeline (All times local)
- 02:00 - Overnight image update started for POOL-FIN-01.
- 02:03 - Affected host rebooted following update (Kernel-General Event 1 reflects 02:03:11 boot time).
- 07:00 - Incident symptom window begins; black screen reports start.
- 07:02 - First captured affected user sequence: logon success, dwm.exe crash in igdumd64.dll, DWM exit, disconnect.
- 07:02 to 07:08 - Repeated crash/disconnect pattern confirmed across reconnect and additional user.
- 07:xx to 09:xx - Mitigation and remediation actions executed (drain/route/graphics mitigation and image correction workflow per response plan).
- 10:00 - Resolution verified: users logging into POOL-FIN-01 successfully; no issues reported.

## 6) Hypothesis Review and Elimination
Initial hypotheses were:
1. FSLogix profile attach delay/failure.
2. Shell/AppX registration regression.
3. AVD agent or bootloader mismatch.
4. Logon policy/script/security startup regression.
5. Graphics/display acceleration regression.

Evidence-based outcome:
- Hypothesis 1: Contradicted by immediate DWM crash signature.
- Hypothesis 2: Contradicted by repeated igdumd64.dll-linked DWM failures and absent shell fault evidence.
- Hypothesis 3: Neutral to weakly contradicted (logon success repeats; no direct agent failure events).
- Hypothesis 4: Contradicted by deterministic graphics crash-to-disconnect chain.
- Hypothesis 5: Supported by direct faulting module evidence and unaffected control pool behavior.

## 7) Confirmed Root Cause
A graphics stack regression was introduced in the updated POOL-FIN-01 image, causing dwm.exe to crash in Intel graphics module igdumd64.dll during post-logon desktop composition. The crashes triggered DWM termination and session disconnects/black screen behavior for a subset of users.

## 8) Resolution Actions Implemented

### Immediate Containment
- Restricted new sessions on unstable POOL-FIN-01 hosts.
- Routed users to healthy capacity where possible.

### Mitigation
- Applied software-rendering oriented mitigation on affected hosts to bypass unstable hardware acceleration path.
- Rebooted and returned hosts in controlled waves with monitoring.

### Permanent Remediation
- Updated/remediated image graphics stack for POOL-FIN-01 (driver path correction and validation against known-good behavior).
- Verified post-change host behavior before full return to normal routing.

### Validation at Closure (10:00)
- Users successfully logged into POOL-FIN-01.
- No active black screen reports.
- No repeating crash pattern reported after remediation window.

## 9) 5 Whys Analysis
1. Why did users see a black screen after login?  
Because the desktop rendering process failed shortly after session logon.

2. Why did desktop rendering fail?  
Because Desktop Window Manager (dwm.exe) crashed repeatedly.

3. Why did dwm.exe crash repeatedly?  
Because the graphics module igdumd64.dll faulted with access violation (0xc0000005).

4. Why was this graphics fault present only in impacted sessions?  
Because the updated POOL-FIN-01 image introduced a graphics stack state that was unstable in AVD session rendering conditions.

5. Why did this reach production impact?  
Because pre-production image validation did not include a blocking gate for DWM crash signatures under realistic AVD login and reconnect scenarios.

## 10) Preventive and Corrective Actions

### Technical Preventive Actions
- Add mandatory post-image AVD smoke tests: fresh logon, reconnect, idle resume, Teams/video render, Office launch.
- Add deployment blocker: any Event 1000 where process is dwm.exe and module is igdumd64.dll fails image promotion.
- Add automated alerting for DWM crash signatures (Event 1000 + Event 9009 correlation) during first hours after rollout.
- Require side-by-side canary comparison against control pool before full production rollout.

### Process Preventive Actions
- Enforce phased rollout with explicit pause-and-verify checkpoints.
- Maintain rollback-ready previous image version for rapid pool reversion.
- Add incident playbook decision tree for pool isolation when one pool is updated and the other is clean.

### Ownership and Follow-up
- DWWP Engineering: implement monitoring rules and rollout gates.
- EUC Platform/Image Team: maintain validated driver baseline and compatibility matrix.
- Service Operations: run post-change health review and confirm closure criteria.

## 11) Closure Statement
Incident resolved at 10:00 after mitigation and remediation activities. User validation and service observations confirmed stable logon behavior on POOL-FIN-01 with no ongoing black screen reports.