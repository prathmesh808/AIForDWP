# AVD Black Screen Incident: Timing-Weighted Hypothesis

Date: 2026-08-06  
Role: DWWP Engineer  
Scope basis only (no commitment to single root cause yet)

## Incident Scope Facts
- Symptom: Blank screen post-login; clears after ~30s for some users, persists for others.
- Who: ~40% of users on POOL-FIN-01. POOL-FIN-02 completely unaffected.
- Since: ~07:00 this morning.
- Changes: Overnight image update to POOL-FIN-01 at 02:00. POOL-FIN-02 not updated.

## Key Timing Interpretation
Most consistent signal: only the updated pool is impacted, while the unchanged pool is fully healthy.  
This strongly favors image-introduced regressions in logon/profile/shell initialization paths over tenant-wide or random infrastructure causes.

## Re-Ranked Likely Causes (Most Probable First)

### 1) FSLogix profile container attach delay/failure introduced by new POOL-FIN-01 image
Why this fits the scope facts:
- Directly aligns with update isolation: changed pool bad, unchanged pool good.
- Symptom pattern (temporary black screen for some; persistent for others) matches profile mount timeout/failure behavior.
- Post-login onset is consistent with profile initialization stage.

Single fastest check:
- On one affected POOL-FIN-01 host, check FSLogix Operational logs during first affected logons today for attach/mount timeout or error events.

### 2) Shell/AppX registration regression in the updated image
Why this fits the scope facts:
- Image-scoped component issue would affect only POOL-FIN-01.
- Black screen after authentication can occur when shell components (Explorer/Start/UWP shell) are delayed or fail to initialize.
- 30-second clear in some sessions is consistent with retry/timeout behavior.

Single fastest check:
- On affected POOL-FIN-01 host, inspect AppXDeployment and shell-related event logs around login time for registration/activation failures.

### 3) AVD agent/bootloader/dependency mismatch on updated image
Why this fits the scope facts:
- Strongly tied to image composition/versioning and therefore pool-specific.
- Can produce "session connected but desktop not ready" symptoms.
- Explains why unaffected pool remains normal.

Single fastest check:
- Compare AVD agent/bootloader versions and service health on one affected POOL-FIN-01 host vs one healthy POOL-FIN-02 host.

### 4) Logon policy/script/security startup regression baked into image baseline
Why this fits the scope facts:
- Still compatible with update-only impact if the image changed policy processing conditions or startup components.
- Can cause login stalls with black screen while synchronous actions complete.
- Mixed user impact can occur if timing/dependency differs per host/session.

Single fastest check:
- Review GroupPolicy Operational/logon duration events on affected host to identify one dominant delayed stage.

### 5) Graphics/display acceleration regression in updated image
Why this fits the scope facts:
- Possible due to updated drivers/settings in new image and pool-specific deployment.
- Can cause black screen or delayed render.
- Lower probability than profile/shell causes given current symptom shape and pool split.

Single fastest check:
- Run one controlled test session on affected host with software rendering forced; compare immediate post-login behavior.

## Most Consistent Cause with the "POOL-FIN-02 Not Updated and Unaffected" Fact
Primary hypothesis:
- Image-introduced logon stack regression on POOL-FIN-01, with FSLogix profile attach delay/failure as leading mechanism.

Reason:
- Best direct match to timing and blast-radius boundaries.
- Naturally explains both transient (~30s) and persistent black screen outcomes.

## Confidence Posture
- Do not commit to single root cause yet.
- Proceed with fastest discriminating checks in ranking order to confirm/eliminate rapidly.

---

## Addendum: Event Details, Hypothesis Review, and Resolution (Appended 2026-08-06)

### Event Details Reviewed

Affected host: SHFIN-01-A (POOL-FIN-01)  
Window reviewed: 07:00-07:30

- 07:02:10 - LSM Event 21: session logon succeeded (FINBRIDGE\mlopez, Session 3)
- 07:02:14 - Kernel-General Event 1: host boot time 02:03:11 (post overnight image update)
- 07:02:16 - Application Error Event 1000: dwm.exe faulting module igdumd64.dll (0xc0000005)
- 07:02:17 - LSM Event 40: session disconnected
- 07:02:18 - DWM Event 9009: Desktop Window Manager exited
- 07:02:44 - LSM Event 21: reconnect logon succeeded
- 07:02:46 - Application Error Event 1000: dwm.exe faulting module igdumd64.dll
- 07:02:47 - LSM Event 40: session disconnected
- 07:03:01 - DWM Event 9009: Desktop Window Manager exited
- 07:03:10 - LSM Event 21: second reconnect logon succeeded (Session 4)
- 07:08:22 - LSM Event 21: another user logon succeeded (FINBRIDGE\akapoor, Session 5)
- 07:08:24 - Application Error Event 1000: dwm.exe faulting module igdumd64.dll

Comparison host: SHFIN-02-A (POOL-FIN-02, unaffected)

- 07:01:44 - LSM Event 21: session logon succeeded
- 07:01:46 - DWM Event 9011: DWM started successfully
- No Application Error events in the same window

### Reviewed Hypotheses vs Evidence

1) FSLogix profile container attach delay/failure  
Status: Contradicted by evidence
- Determining evidence: 07:02:16 Event 1000 (dwm.exe/igdumd64.dll), followed immediately by 07:02:17 Event 40 and 07:02:18 Event 9009.
- Interpretation: crash-disconnect sequence is graphics/DWM-led, not profile-attach-led in provided logs.

2) Shell/AppX registration regression  
Status: Contradicted by evidence
- Determining evidence: repeated DWM crash pattern at 07:02:16 and 07:02:46 (Event 1000), with DWM exits at 07:02:18 and 07:03:01 (Event 9009).
- Interpretation: supplied evidence points to DWM graphics fault rather than AppX/shell registration failure.

3) AVD agent/bootloader/dependency mismatch  
Status: Neutral to weakly contradicted
- Determining evidence: multiple successful logons/reconnects (Event 21 at 07:02:10, 07:02:44, 07:03:10, 07:08:22), while failures correlate to DWM crash events.
- Interpretation: no direct agent/bootloader failure events in supplied data.

4) Logon policy/script/security startup regression  
Status: Contradicted by evidence
- Determining evidence: immediate post-logon DWM crashes (Event 1000) and DWM exits (Event 9009) tightly precede disconnects (Event 40).
- Interpretation: observed failure chain is render path instability, not policy/script stall.

5) Graphics/display acceleration regression in updated image  
Status: Supported by evidence
- Determining evidence: repeated Event 1000 dwm.exe faults in igdumd64.dll at 07:02:16, 07:02:46, and 07:08:24; matching Event 9009 exits and Event 40 disconnects; unaffected pool shows Event 9011 healthy DWM start and no app errors.
- Interpretation: strongest direct fit to pool-specific post-update behavior.

### Surviving Hypothesis

- Graphics/display stack regression introduced by the POOL-FIN-01 image update, specifically DWM crashing in Intel graphics module igdumd64.dll.

### Detailed Resolution Steps

#### 1) Immediate Containment
- Place affected POOL-FIN-01 session hosts into drain mode to prevent new user impact.
- Route new sessions to POOL-FIN-02 where capacity permits.
- Issue incident communication noting image-linked black screen behavior under mitigation.

#### 2) Canary Mitigation Validation
- Select one affected POOL-FIN-01 host.
- Force software rendering for AVD sessions as temporary mitigation.
- Execute 3-5 controlled test logons.
- Pass criteria: no new Event 1000 (dwm.exe/igdumd64.dll), no Event 9009, no immediate Event 40 disconnect after Event 21.

#### 3) Stabilize at Scale
- If canary passes, apply mitigation to all POOL-FIN-01 hosts.
- Reboot in controlled batches.
- Return hosts to service in waves while tracking disconnect and black-screen reports.

#### 4) Permanent Image Remediation
- Build a replacement POOL-FIN-01 image from known-good baseline.
- Remove/replace Intel graphics driver version 31.0.101.4146 with validated stable version.
- Keep non-graphics changes minimal to preserve causal clarity.
- Roll out to canary hosts first, then phased production rollout.

#### 5) Validation Gates Before Closure
- Functional: 20+ consecutive successful logons with no black-screen persistence.
- Telemetry: zero recurring Event 1000 (dwm.exe + igdumd64.dll) and Event 9009 in validation window.
- Service quality: reconnect and fresh logon behavior match unaffected pool baseline.

#### 6) Recurrence Prevention
- Add post-image smoke tests for AVD login, reconnect, and desktop render readiness.
- Add promotion gate to block image rollout on any DWM crash signature.
- Add proactive alerting for Event 1000 where process is dwm.exe and module is igdumd64.dll.