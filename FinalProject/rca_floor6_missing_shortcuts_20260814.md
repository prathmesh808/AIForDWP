# Root Cause Analysis (RCA): Floor 6 Missing Desktop Shortcuts

## RCA Metadata
- Incident: Floor 6 Missing Desktop Shortcuts
- Date first symptom window: 2026-08-14 (from 09:00)
- Date first report noted: 2026-08-14 09:14
- Affected scope: Floor 6
- RCA date: 2026-08-14
- Status: Working RCA based on available scope and elimination evidence

---

## 1) Executive Summary
Floor 6 users reported missing desktop shortcuts beginning around 09:00. Based on scope facts and elimination analysis performed to date, the most likely root cause is a user profile load issue at sign-in (temporary or partial profile mapping), resulting in users landing in a profile context where expected desktop shortcuts are not presented.

No incident data supplied explicit error codes; therefore, no error code meaning is asserted in this RCA.

---

## 2) Supporting Evidence

### 2.1 Confirmed evidence from incident inputs
1. Symptom cluster: missing desktop shortcuts.
2. Scope: Floor 6 users.
3. Start time: approximately 09:00.
4. Change statement at intake: Nil.
5. Elimination output retained one primary working hypothesis: profile load/mapping issue.

### 2.2 Evidence not yet captured (required for closure)
1. Endpoint profile mapping screenshots for affected versus unaffected users.
2. Registry proof points under `ProfileList` for affected users.
3. Desktop folder existence and ACL comparison output.
4. Event log snippets around sign-in profile load sequence.

---

## 3) Timeline (Known)

| Time | Event | Evidence Type | Notes |
|---|---|---|---|
| 09:00 | Missing shortcut behavior begins | Scope fact | Floor 6 symptom onset |
| 09:14 | Incident escalation noted | Reported | Multi-user impact acknowledged |
| After initial triage | Hypothesis elimination run | Analytical | Surviving hypothesis retained |
| RCA preparation | Resolution sequence finalized | Analytical | Pending field verification |

---

## 4) Ranked Cause Analysis (Top 3)

### 1) User profile load issue at sign-in (temporary or partial mapping)
- Why this ranks first:
  - Best explains sudden multi-user morning onset with shortcut absence in active session.
- Fastest check:
  - Validate active profile path and SID mapping for one affected endpoint.
- Remediation if confirmed:
  - Repair profile mapping, restart, and restore shortcut artifacts.

### 2) Desktop redirection path unavailable
- Why this ranks second:
  - Can cause visible shortcut loss without file deletion across multiple users.
- Fastest check:
  - Verify Desktop redirection target reachability and contents.
- Remediation if confirmed:
  - Restore target path availability and permissions, then refresh sessions.

### 3) Permission drift on desktop folders
- Why this ranks third:
  - ACL drift can hide shortcuts while files remain present.
- Fastest check:
  - Compare effective permissions on user/public desktop folders for affected vs unaffected.
- Remediation if confirmed:
  - Reapply baseline ACLs and force policy refresh.

---

## 5) Five Whys

Problem statement:
Why did Floor 6 users lose visibility of desktop shortcuts Monday morning?

1. Why were shortcuts missing?
- Because users likely signed into a profile context that did not present expected desktop artifacts.

2. Why was profile context incorrect?
- Because profile mapping/load at sign-in may have fallen back to temporary or partial mapping.

3. Why would mapping/load fail for multiple users?
- Because a shared dependency in profile initialization or environment state likely failed during morning sign-ins.

4. Why was this not detected before user impact?
- Because there was no enforced pre- or post-logon profile integrity gate for the affected cohort.

5. Why did response require reactive triage?
- Because preventive controls did not require affected-versus-unaffected profile path comparison at first alert.

Root cause from 5-Whys:
- Primary: Profile load/mapping failure at sign-in leading to missing desktop artifacts in active session.
- Contributing: Insufficient preventive profile-integrity validation controls.

---

## 6) Final Hypothesis and Resolution Plan

### Final hypothesis
User profile load issue at sign-in (temporary or partial profile mapping) caused missing desktop shortcuts for Floor 6 users.

### 6.1 Exact remediation steps
1. Identify affected and unaffected comparison pair.
2. Confirm active user profile path on affected endpoint.
3. Inspect `ProfileList` SID mapping and `.bak` anomalies.
4. Backup user and public desktop shortcuts.
5. Sign out user and restart endpoint.
6. Repair profile mapping per SOP if anomalies exist.
7. Restart endpoint and re-sign-in affected user.
8. Restore shortcut set if still missing.
9. Repeat for remaining impacted endpoints.

### 6.2 Correct order of operations
1. Baseline comparison.
2. Evidence capture.
3. Backup artifacts.
4. Repair and restart.
5. Validate and restore artifacts.
6. Roll out to remaining devices.

### 6.3 Verification checks
1. Expected profile path is loaded for remediated users.
2. Required shortcuts are visible and present in expected desktop folders.
3. Affected/unaffected comparison no longer shows deviation.
4. No recurrence tickets for one business hour.

### 6.4 Preventive actions
1. Add canary profile-load validation before broad deployment waves.
2. Add post-logon desktop artifact check to release checklist.
3. Publish help desk one-click shortcut restore package with profile-path precheck.
4. Require closure evidence for affected-vs-unaffected profile comparison.

---

## 7) Error Code Handling Statement
- No explicit error codes were shared in this incident data set.
- This RCA does not assign meaning to any unsupplied code values.

---

## 8) Copilot Fault Assessment
- Is this a Copilot bug? No.
- Reason: Desktop shortcuts are endpoint profile/shell behavior, not Copilot runtime behavior.

---

## 9) Action Tracker
| Action | Owner Role | Priority | Status |
|---|---|---|---|
| Capture affected/unaffected profile path evidence | DWP engineer | High | Pending |
| Execute profile mapping remediation on affected cohort | DWP engineer | High | Pending |
| Validate shortcut restoration and no recurrence | Service desk lead | High | Pending |
| Add profile-integrity gate to release checklist | Release engineer | Medium | Planned |

---

## 10) Non-Technical Update Draft
"The shortcut issue appears tied to how user desktop profiles loaded this morning, not to data loss. We are restoring normal desktop views and adding checks to prevent this from repeating."