# Root Cause Analysis (RCA): Floor 6 Copilot Unexpected Client Matter

## RCA Metadata
- Incident: Floor 6 Copilot Unexpected Client Matter
- Symptom window start: 2026-08-14 09:00
- First report noted: 2026-08-14 09:14
- Scope: Floor 6
- RCA date: 2026-08-14
- Status: Working RCA based on available scope and triage evidence

---

## 1) Executive Summary
A Floor 6 user reported Copilot surfaced an unexpected client matter. Based on scope facts and prior triage analysis, the most likely root cause is permissions/access boundary mismatch (effective access broader than expected by the user), potentially driven by inherited grants or group-based access paths.

No explicit error codes were supplied in the incident data. This RCA does not assign meaning to unsupplied codes.

---

## 2) Supporting Evidence

### 2.1 Confirmed from provided inputs
1. Reported behavior: Copilot returned unexpected client matter content.
2. Affected scope: Floor 6.
3. Onset: around 09:00.
4. Intake change statement: Nil.
5. Triage ranking placed permissions/access boundary as most probable.

### 2.2 Evidence not yet collected (required for closure)
1. Exact prompt/response and citation/source IDs.
2. Effective-access snapshot for reporting user at incident time.
3. Full inheritance chain of cited item.
4. Group membership evidence affecting legal repository visibility.
5. Reproduction result with controlled denied-access account.

---

## 3) Timeline (Known)

| Time | Event | Evidence Type | Notes |
|---|---|---|---|
| 09:00 | Unexpected matter visibility begins | Scope fact | Initial symptom window |
| 09:14 | Incident report captured | Reported | Floor 6 user concern raised |
| Post-report | Scope-only hypothesis ranking performed | Analytical | Permissions boundary ranked highest |
| RCA preparation | Final working hypothesis documented | Analytical | Pending evidence verification |

---

## 4) Ranked Cause Analysis (Top 3)

### 1) Permissions/access boundary mismatch
- Why ranked first:
  - Most frequent cause of "unexpected" Copilot retrieval.
  - Aligns with inherited or group-based access drift patterns.
- Fastest check:
  - Run effective access on exact cited source for reporting user.
- Remediation if confirmed:
  - Remove unintended permission path and retest citation behavior.

### 2) Access propagation or indexing delay
- Why ranked second:
  - Temporary mismatch can occur after permission updates.
- Fastest check:
  - Compare incident-time vs current effective-access state on cited source.
- Remediation if confirmed:
  - Wait/validate propagation completion, then retest prompt and source citation.

### 3) Indirect exposure through inherited container permissions
- Why ranked third:
  - Common in shared legal libraries with deep inheritance.
- Fastest check:
  - Trace item-to-parent inheritance grants.
- Remediation if confirmed:
  - Correct inheritance and enforce least-privilege model.

---

## 5) Five Whys

Problem statement:
Why did Copilot return a client matter that the user believed was unauthorized?

1. Why did Copilot return that matter?
- Because Copilot grounded response on content it evaluated as accessible to the user.

2. Why was that content evaluated as accessible?
- Because an access path likely existed through direct, group, or inherited permission grants.

3. Why did that access path exist unexpectedly?
- Because permission boundaries and inheritance visibility were not fully understood or recently changed without clear visibility.

4. Why was this not detected before user impact?
- Because no proactive effective-access verification gate was enforced for sensitive legal repositories.

5. Why did response rely on reactive triage?
- Because prompt/citation evidence capture and access-boundary validation were not triggered automatically at first alert.

Root cause from 5-Whys:
- Primary: permissions/access boundary mismatch for sensitive legal content.
- Contributing: insufficient preventive controls for inheritance and effective-access validation.

---

## 6) Final Hypothesis and Resolution Plan

### Final hypothesis
Permissions/access boundary mismatch allowed retrieval path to the cited matter for the reporting user context.

### 6.1 Exact remediation steps
1. Capture prompt, response, citation/source ID, timestamp, and user identity.
2. Run effective access on cited source for reporting user.
3. Map all permission paths: direct, inherited, group-based, and shared-link paths.
4. Remove unintended grant path.
5. Re-run effective access to confirm expected deny state.
6. Re-run original prompt and verify citation no longer appears.
7. Validate authorized-user control still retrieves expected content.
8. Record evidence and close containment with Legal/Security update.

### 6.2 Correct order of operations
1. Evidence capture.
2. Access-path validation.
3. Permission correction.
4. Retest and verification.
5. Communication and closure.

### 6.3 Verification checks
1. Effective access on cited item is correct for reporting user.
2. Original reproduction prompt no longer returns unauthorized citation.
3. Authorized control account still functions as expected.
4. No repeat incidents in monitoring period.

### 6.4 Preventive actions
1. Scheduled effective-access audits on legal-sensitive repositories.
2. Mandatory inheritance review in legal content change workflow.
3. Immediate prompt/citation capture requirement in incident intake form.
4. Alerting on high-impact permission expansion events.

---

## 7) Error Code Handling Statement
- No explicit error codes were provided.
- No error code meanings are inferred in this RCA.

---

## 8) Copilot Fault Assessment
- Current assessment: Unclear.
- Escalate as potential Copilot defect only if denied-access account can reproducibly retrieve cited source despite corrected permissions.

---

## 9) Action Tracker
| Action | Owner Role | Priority | Status |
|---|---|---|---|
| Collect prompt/response/citation evidence | DWP engineer | High | Pending |
| Run effective-access and inheritance trace | DWP engineer | High | Pending |
| Correct unintended permission path | DWP engineer | High | Pending |
| Validate with control accounts | Service desk lead | High | Pending |
| Add preventive governance controls | Change manager | Medium | Planned |

---

## 10) Non-Technical Update Draft
"The issue is most likely linked to document access configuration rather than confirmed Copilot system failure. We are validating and correcting access boundaries, then retesting to ensure only authorized matter content is returned."