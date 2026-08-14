# Root Cause Analysis (RCA): Floor 6 Login Failures and Slow Sign-In

## RCA Metadata
- Incident: Floor 6 Login Failures and Slow Sign-In
- Incident date/time first report: Monday 09:14
- RCA date: 2026-08-14
- Affected scope: Floor 6 Legal (~45 users); at least 12 impacted
- Current status: Working root cause finalized pending field validation

---

## 1. Executive Summary
On Monday morning, Floor 6 experienced widespread authentication disruption (cannot log in or very slow sign-in) after recent Windows 11 migration, Intune enrollment, and a Friday app rollout. Based on evidence available to date, the most likely root cause is a permissions/access boundary condition: Conditional Access and Intune compliance state mismatch affecting token issuance and sign-in policy evaluation. The Friday app rollout likely increased compliance drift or delayed prerequisite completion on a subset of devices.

No platform evidence indicates this is a Copilot product fault for the login symptom.

---

## 2. Supporting Evidence

### 2.1 Directly observed evidence
1. Slack escalation at 09:14 indicating at least a dozen users unable to log in or facing very slow login.
2. Affected cohort localized to Floor 6 Legal (about 45 users).
3. Environment changed recently: Win11 migration and Intune enrollment.
4. Additional change introduced Friday afternoon: new document management app rollout to same floor.

### 2.2 Evidence not yet collected (required to fully close)
1. Entra sign-in failure reason details for representative affected users.
2. Device compliance snapshots from Intune at failure timestamps.
3. Affected vs unaffected comparison of app assignment/install results.
4. Distribution of failure stage (pre-auth, token issuance, profile load, shell start).

### 2.3 Error code handling statement
- No explicit error codes were provided in this incident data set.
- This RCA does not assert any error-code meaning without supplied codes.

---

## 3. Timeline (Known + Investigation Milestones)

| Time | Event | Evidence Type | Notes |
|---|---|---|---|
| Friday afternoon (prior business day) | New document management app deployed to Floor 6 | Reported change | Potential trigger window opened |
| Monday 09:14 | IT Ops Slack escalation received | Direct evidence | At least 12 users: login failure or extreme slowness |
| Monday 09:14 onward | Incident triage started | Process | Scope and recent changes identified |
| RCA preparation time | Hypothesis convergence on CA/compliance boundary | Analytical | Requires log confirmation steps listed below |

---

## 4. Ranked Cause Analysis (Top 3)

### 1) Permissions/Access Boundary (Most probable)
Why this ranking:
- Large same-floor impact after endpoint governance changes strongly indicates policy boundary effects.
- Symptom split (failure for some, slow for others) aligns with compliance-policy evaluation variability.

Fastest confirmation check:
- Correlate one affected user's Entra sign-in failure reason with Intune compliance state at the same timestamp.

### 2) License/Client Prerequisite Issue
Why this ranking:
- Friday app deployment can alter sign-in/startup dependencies and cause broad first-business-day login friction.

Fastest confirmation check:
- Compare app install status and context (user/system) between one affected and one unaffected device.

### 3) Data Indexing Lag (contributing, less likely primary)
Why this ranking:
- Can explain post-auth slowness but rarely true sign-in failure.

Fastest confirmation check:
- Confirm whether users are blocked before authentication vs slowed only after desktop initialization.

---

## 5. Five Whys

Problem statement:
Why did Floor 6 experience widespread inability to log in or very slow sign-in Monday morning?

1. Why were users unable to log in or delayed?
- Because authentication/policy evaluation likely failed or stalled on a subset of Floor 6 endpoints.

2. Why did policy evaluation fail/stall on those endpoints?
- Because device compliance and access-policy prerequisites were likely not in a valid state at sign-in time.

3. Why were prerequisites not valid at sign-in time?
- Because recent Win11/Intune transition and Friday app rollout changed device state and dependency timing.

4. Why did change impact manifest broadly on Monday?
- Because production cohort rollout reached a large legal floor without sufficient post-change canary and Monday readiness gate.

5. Why was there no early containment before business peak?
- Because identity-impacting rollout controls (pre-peak validation, drift monitoring, auto-halt thresholds) were not strict enough.

Root cause from 5-Whys:
- Primary: Access boundary mismatch (Conditional Access/compliance) during sign-in after endpoint and app changes.
- Contributing: Rollout governance gap (insufficient canary/validation before peak hours).

---

## 6. Final Hypothesis and Resolution Plan

### Final hypothesis
Conditional Access enforcement intersected with noncompliant/unknown device state on a subset of Floor 6 endpoints after Win11+Intune transition and Friday app rollout, causing login denial or prolonged policy evaluation.

### 6.1 Exact remediation steps
1. Select 3 representative affected users and capture exact failure timestamps.
2. Pull Entra sign-in logs for those attempts and confirm policy/compliance failure reason.
3. In Intune, inspect compliance rule failures on corresponding devices.
4. Apply emergency, time-bound CA exclusion to Floor 6 support group (minimal scope).
5. Force Intune sync on affected devices.
6. Remediate failing compliance prerequisites (required app/policy/config).
7. Re-run compliance evaluation until devices report compliant.
8. Remove emergency CA exclusion.
9. Validate with pilot users and then with wider Floor 6 sample.

### 6.2 Correct order of operations
1. Contain impact rapidly (temporary minimal CA exclusion).
2. Restore access first for business continuity.
3. Correct underlying compliance/app prerequisite state.
4. Re-enable policy boundary controls.
5. Verify outcome and close incident communications.

### 6.3 Verification checks after remediation
1. No new compliance-related sign-in failures in Entra for remediated devices.
2. Floor 6 sign-in success rate normalizes during business window.
3. Median sign-in duration returns to expected baseline.
4. No repeat login tickets from same impacted users by next business day.

### 6.4 Preventive action
- Implement identity-change release controls:
  - Canary cohort mandatory for any policy/app affecting auth path.
  - Friday rollout requires same-day sign-in smoke test and rollback decision gate.
  - Automated alert when compliance drift exceeds threshold in a rollout ring.
  - Monday morning freeze window for non-critical auth-path changes.

---

## 7. Copilot Fault Assessment
- Is this a Copilot bug? No.
- Reason: symptom is endpoint sign-in and identity policy behavior, outside Copilot runtime path for this incident.

---

## 8. Residual Risk and Assumptions
1. Residual risk: If logs later show credential or federation outage patterns, ranking may change.
2. Assumption: Recent change timing is causal; this must be validated by timestamp correlation.
3. Assumption: No hidden infrastructure outage was present in parallel.

---

## 9. Action Tracker
| Action | Owner | Priority | Status |
|---|---|---|---|
| Entra sign-in + Intune compliance timestamp correlation | IAM + Endpoint | High | Pending execution |
| Temporary Floor 6 CA exclusion (time-boxed) | IAM | High | Pending approval |
| Compliance prerequisite remediation on affected devices | Endpoint Engineering | High | Pending |
| CA exclusion rollback after compliance recovery | IAM | High | Pending |
| Rollout governance hardening (canary + gates) | IT Ops + CAB | Medium | Planned |

---

## 10. Non-Technical Communication Draft
"This morning's Floor 6 login disruption was most likely caused by workstation policy/compliance conditions after recent endpoint changes, not a Copilot service defect. We can safely restore access using a temporary controlled policy exception while we correct the underlying device compliance state, then reinstate normal controls once validated."