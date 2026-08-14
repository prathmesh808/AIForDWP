# Ranked Differential: Floor 6 Login and Performance (Friday Deploy to Monday Impact)

Date: 2026-08-14  
Scope: Floor 6 Legal, post Win11 migration and Intune enrollment, with Friday afternoon document management app rollout and Monday morning login/slow-sign-in incidents.

## Problem Framing
A cluster of login failures and severe sign-in slowness appeared Monday morning after a Friday app deployment to the same floor. The task is to rank likely causes, define the fastest check for each, and state what evidence confirms or rules out deployment causality.

## Ranked Differential (Most Likely First)

### 1) Conditional Access plus Intune compliance mismatch (most likely primary mechanism)
Why this is ranked first:
- Same-floor cluster and mixed symptom pattern (hard fail for some, extreme delay for others) is classic for policy evaluation variance by device posture.
- The environment already had identity-governance change activity (Win11 plus Intune transitions), increasing risk of timing drift between policy requirements and endpoint state.

Fastest check:
- For 3 representative affected users, correlate Entra sign-in event outcome and failure reason with Intune compliance state at the exact incident timestamp.

Evidence that confirms deployment as cause or trigger:
- Incident onset follows Friday deployment window.
- Affected users share deploy-cohort prerequisites or app-related policy dependency failures.
- Sign-in success normalizes after correcting compliance prerequisites introduced or stressed by the deployed app path.

Evidence that rules out deployment as cause:
- Same CA/compliance failure pattern appears in non-deployed cohorts.
- Failures are explained by independent tenant-wide identity outage or credential/federation faults.
- No meaningful state difference between affected and unaffected devices relative to deploy artifacts.

---

### 2) App prerequisite or install-context defect from Friday package (most likely direct deployment fault)
Why this is ranked second:
- Monday first-business-day incidents after a Friday push strongly fit first-logon initialization and dependency-order defects.
- User-context vs system-context packaging mistakes can cause startup blockers or delayed sign-in processing.

Fastest check:
- Compare one affected and one unaffected device for app assignment result, install status, install context, dependency completion, and startup component health.

Evidence that confirms deployment as cause:
- Affected devices show failed or incomplete app dependency chain introduced Friday.
- Unaffected devices either lacked the package or completed dependency chain successfully.
- Pilot redeploy of corrected package removes symptoms.

Evidence that rules out deployment as cause:
- App install and dependency state are healthy and identical across affected and unaffected devices.
- Devices never targeted by the Friday rollout show the same failure pattern.
- Rollback or package disable has no impact on symptom rate.

---

### 3) Post-login indexing or profile-load pressure (likely contributor, unlikely root of true login denial)
Why this is ranked third:
- Explains slow desktop readiness but not strong pre-authentication failure patterns.
- Can coexist as a secondary performance drag in newly migrated cohorts.

Fastest check:
- Split timing into pre-auth/token stage versus post-shell stage using Entra event timing plus endpoint event logs.

Evidence that confirms deployment as cause:
- Majority of impacted users authenticate successfully, then experience only post-login slowness.
- New app startup/indexing components are active and resource-heavy on affected devices.

Evidence that rules out deployment as cause:
- Failure occurs before shell launch or during token issuance.
- No measurable startup or resource delta linked to deployed app components.

---

### 4) Tenant or upstream identity service issue (alternative, lower probability)
Why this is ranked fourth:
- The scope is floor-localized with direct recent change context, which weakens pure platform-outage explanation.

Fastest check:
- Compare same-window sign-in outcomes across other floors and non-targeted cohorts.

Evidence that confirms deployment as cause:
- Other cohorts are stable while deployed cohort fails.

Evidence that rules out deployment as cause:
- Broad multi-floor failures with no deployment-cohort concentration.

## Deployment Causality Decision Rule
Conclude Friday deployment is causal only if all four conditions hold:
1. Temporal linkage: failures begin after rollout and cluster in targeted cohort.
2. State linkage: affected endpoints show deployment-specific prerequisite or policy-state differences.
3. Reversibility: rollback or corrective package change reduces failures.
4. Reproducibility: controlled pilot can reproduce and then clear with corrected build/config.

If one or more conditions fail, treat deployment as non-causal or contributory only, and re-rank toward identity-platform or credential-path causes.

## Fast Execution Plan (First 30 Minutes)
1. Pull 3 affected user Entra sign-in records and timestamp-lock results.
2. Pull matching Intune compliance snapshots for those timestamps.
3. Run affected vs unaffected app assignment and install-context comparison.
4. Classify stage of failure: pre-auth, token policy, profile load, or post-shell.
5. If CA/compliance mismatch is validated, apply time-boxed minimal-scope access containment and remediate prerequisites.
6. Re-test with pilot users, then broaden validation.

## Closure Evidence Required
- Entra and Intune timestamp correlation outputs for affected and control users.
- App assignment/install-context comparison table.
- Before-and-after sign-in success and median sign-in duration trend for Floor 6.
- Explicit statement whether deployment is primary cause, contributing cause, or ruled out.
