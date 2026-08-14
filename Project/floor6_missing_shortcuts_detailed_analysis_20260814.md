# Detailed Analysis: Floor 6 Missing Desktop Shortcuts

## Document Control
- Incident: Floor 6 Missing Desktop Shortcuts
- Date prepared: 2026-08-14
- Scope basis: Scope facts plus prior elimination notes in existing analysis

## 1) Scope Facts Used
- Symptom: Floor 6 missing desktop shortcuts
- Who: Floor 6
- Since: 09:00 this morning
- Change: Nil

## 2) Evidence Position
- Evidence available is scope-level only plus hypothesis-elimination notes.
- No platform error codes were provided in the incident data shared so far.
- Error code statement: No error code meaning is asserted in this analysis.

## 3) Ranked Top 3 Most Likely Causes (Most Probable First)

### 1. User profile load issue at sign-in (temporary or partial profile mapping)
- Why it fits the evidence:
  - Sudden morning onset across a floor can align with profile load failures during first sign-ins.
  - Missing desktop shortcuts is consistent with landing in a profile path that does not contain expected desktop artifacts.
- Fastest check to confirm or eliminate:
  - On one affected endpoint, verify active session profile path and ProfileList mapping against expected user profile path.
- Specific remediation action if confirmed:
  - Repair profile mapping, restart endpoint, and re-sign-in user on correct profile path; restore shortcut set if required.

### 2. Desktop redirection target unavailable or not reachable
- Why it fits the evidence:
  - If desktop content is redirected, a morning path/availability issue can make shortcuts appear missing for multiple users at once.
- Fastest check to confirm or eliminate:
  - Open affected user's Desktop location properties and confirm target path is reachable and populated.
- Specific remediation action if confirmed:
  - Restore path availability and access, then refresh session and reload desktop contents.

### 3. Permission drift on user or public desktop locations
- Why it fits the evidence:
  - Read/access permission changes can hide shortcuts without deleting files.
- Fastest check to confirm or eliminate:
  - Compare effective read permissions on `C:\Users\<user>\Desktop` and `C:\Users\Public\Desktop` between one affected and one unaffected user/device.
- Specific remediation action if confirmed:
  - Correct ACL inheritance/permissions via approved baseline and force policy refresh.

## 4) Finalized Surviving Hypothesis
- Final hypothesis: User profile load issue at sign-in (temporary or partial profile mapping) is the best-fit surviving hypothesis.
- Confidence: Medium (scope-driven and elimination-based; requires endpoint proof points to raise to High).

## 5) Exact Remediation Steps
1. Select one affected user/device and one unaffected comparison user/device.
2. Confirm the affected user's active session profile path under `C:\Users`.
3. Open `HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList` and validate expected SID-to-ProfileImagePath mapping.
4. Check for duplicate SID entries with `.bak` suffix and incorrect ProfileImagePath.
5. Back up shortcuts from `C:\Users\Public\Desktop` and affected user desktop path.
6. Sign out affected user and restart endpoint.
7. If profile mapping issue is present, repair mapping per standard profile-repair SOP.
8. Restart endpoint after repair.
9. Sign user back in and verify expected profile path is active.
10. Restore missing shortcuts from known-good set or approved remediation package if needed.
11. Repeat for remaining affected users/devices in Floor 6 cohort.

## 6) Correct Order of Operations
1. Compare affected versus unaffected baseline.
2. Validate profile path and registry mapping.
3. Backup shortcut artifacts before any repair.
4. Repair profile mapping and restart.
5. Validate login path and shortcut presence.
6. Scale to remaining affected devices.

## 7) Verification After Remediation
1. Affected users load expected profile path (not fallback/temporary behavior).
2. Required desktop shortcuts appear in session and physically exist in expected desktop folders.
3. Affected versus unaffected comparison no longer shows differences for profile path and shortcut visibility.
4. No new Floor 6 missing-shortcut incidents in next 1 business hour.

## 8) Preventive Action
- Add a post-logon profile integrity check in rollout validation:
  - Validate expected profile path load and desktop artifact presence for canary users before broad release.
- Add help desk self-heal shortcut package tied to profile-path check outcome.
- Add incident closure checklist item requiring affected-versus-unaffected comparison evidence.

## 9) Copilot Fault Determination
- Is this a Copilot bug? No.
- Reason: Desktop shortcuts are endpoint profile and shell artifact behavior outside Copilot generation/runtime path.