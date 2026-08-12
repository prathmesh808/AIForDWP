# Phased Intune Deployment Plan: FinBridge Connect v3.1

Scope:
- App: FinBridge Connect v3.1 (Win32 .intunewin), already in Intune app catalog
- Fleet: 10,000 Windows 11 endpoints
- Deadline: 3 weeks from 2026-08-12 (target completion by 2026-09-02)
- Constraints: Finance requires 500 users by end of week 1; 5% of fleet on 4 GB RAM devices (at-risk)
- Rollback baseline: FinBridge Connect v3.0 available in catalog

Assumptions for execution:
- Intune assignment model uses Entra ID groups.
- Service desk ticket data is available by app/version tag within 24 hours.
- Crash telemetry is available from Endpoint Analytics and/or MDE app reliability signals.

## 1. RING STRUCTURE

Ring design is built to meet the 3-week deadline while reducing operational risk and explicitly isolating 4 GB RAM devices.

Ring 1 (Pilot)
- Size: 500 devices total
- Composition:
  - 200 IT and endpoint engineering test users/devices
  - 150 cross-functional power users (non-Finance)
  - 100 Finance users (subset of the required 500)
  - 50 devices from the 4 GB RAM at-risk pool
- Duration: 3 calendar days minimum active monitoring
- Purpose:
  - Validate install/uninstall behavior, detection rule accuracy, and basic app stability
  - Validate behavior on at-risk hardware before broader expansion
  - Detect deployment script, requirement, and restart-related defects early
- Intune assignment group type:
  - Primary: Assigned (static) Entra ID device security group for strict cohort control
  - Suggested group: SG-FinBridge-v31-Ring1-Required

Ring 2 (Early)
- Size: 2,500 devices total (cumulative 3,000 including Ring 1)
- Composition:
  - Remaining 400 Finance users to complete Finance 500 by end of week 1
  - Additional business units with moderate operational criticality
  - Additional 200 devices from 4 GB RAM pool in a dedicated subgroup
- Duration: 4 calendar days minimum active monitoring
- Purpose:
  - Prove scale behavior beyond pilot
  - Validate support volume trend, install success consistency, and ring-level resilience
  - Confirm no amplified failure pattern on lower-spec hardware
- Intune assignment group type:
  - Primary: Dynamic Entra ID device group based on approved ring tag (for scale)
  - Finance subgroup remains assigned/static for deadline control
  - Suggested groups:
    - SG-FinBridge-v31-Ring2-Required
    - SG-FinBridge-v31-Finance-Required
    - SG-FinBridge-v31-4GB-Early

Ring 3 (Broad)
- Size: Remaining 7,000 devices (cumulative 10,000)
- Composition:
  - All remaining in-scope Win11 endpoints except any isolated holdback groups
- Duration: 10 calendar days with daily health checks (staged waves inside ring)
- Purpose:
  - Complete deployment inside deadline while preserving ability to stop by wave
  - Confirm stable operation at enterprise scale and finalize closure metrics
- Intune assignment group type:
  - Primary: Dynamic Entra ID device group for broad inclusion
  - Use wave tags for controlled burst rollout (for example 2,500 then 2,500 then 2,000)
  - Suggested groups:
    - SG-FinBridge-v31-Ring3-Wave1
    - SG-FinBridge-v31-Ring3-Wave2
    - SG-FinBridge-v31-Ring3-Wave3

## 2. ADVANCE CRITERIA

Advance decisions are gate-based and reviewed at fixed times. Criteria must all pass unless a documented exception is approved.

Ring 1 to Ring 2 advance criteria
- Install success rate:
  - Minimum 97.0% Installed state in Intune Device install status for Ring 1 group
  - Measurement point: at least 72 hours after Ring 1 assignment start
- Error rate threshold:
  - Maximum 2.0% Failed state in Intune Device install status for Ring 1 group
- User-reported issues threshold:
  - Maximum 8 tickets per 100 users (8%) tagged FinBridge v3.1 in the first 72 hours
  - No more than 2 severity-2 incidents; zero severity-1 incidents
- Monitoring period:
  - Minimum 72 continuous hours after policy assignment with at least one forced sync cycle completed across 95% of Ring 1 devices

Ring 2 to Ring 3 advance criteria
- Install success rate:
  - Minimum 98.0% Installed state in Intune Device install status across cumulative Ring 1 plus Ring 2
  - Measurement point: at least 96 hours after Ring 2 assignment start
- Error rate threshold:
  - Maximum 1.5% Failed state across cumulative Ring 1 plus Ring 2
- User-reported issues threshold:
  - Maximum 5 tickets per 100 users (5%) tagged FinBridge v3.1 during Ring 2 monitoring window
  - Zero severity-1 incidents; no upward day-over-day trend in severity-2 incidents for 2 consecutive days
- Monitoring period:
  - Minimum 96 continuous hours after Ring 2 assignment with at least 95% of targeted devices checked in within the window

Hold condition (pause without full rollback)
- Trigger:
  - If install success is between 95.0% and 97.0% in a ring and failures are concentrated in one identifiable subgroup (for example, 4 GB RAM devices or a single hardware model), pause progression to next ring.
- Example:
  - Ring 2 reaches 96.2% success overall, but 4 GB RAM subgroup shows 9% Failed. Action is hold Ring 3, isolate 4 GB subgroup, continue remediation and retest without tenant-wide rollback.

## 3. ROLLBACK TRIGGERS

Rollback is controlled by explicit thresholds, named decision owners, and fixed decision windows.

Trigger 1: Install failure rate automatic halt
- Condition:
  - Failed state exceeds 5.0% of targeted devices in any active ring for 24 consecutive hours after initial 24-hour stabilization period.
- Decision owner:
  - Endpoint Engineering Lead (primary) plus Service Owner approval (secondary).
- Decision window:
  - 2 hours from threshold breach confirmation.
- Exact Intune rollback action:
  - Remove Required assignment for FinBridge v3.1 from active ring groups (for example SG-FinBridge-v31-Ring2-Required and all pending Ring 3 groups).
  - Add those same groups to FinBridge v3.0 as Required.
  - Add FinBridge v3.1 as Uninstall assignment to the affected ring groups where uninstall is validated.

Trigger 2: Application crash rate rollback consideration
- Condition:
  - Crash rate for FinBridge Connect v3.1 exceeds 3 crashes per 100 active devices per 24 hours for 2 consecutive days, or increases by more than 100% day-over-day for 2 days.
- Decision owner:
  - Major Incident Manager, advised by Endpoint Reliability Engineer and App Owner.
- Decision window:
  - 4 hours from second-day breach confirmation.
- Exact Intune rollback action:
  - Freeze all new v3.1 assignments immediately (remove pending Ring 3 Required assignments).
  - If confirmed app defect, switch active ring groups to FinBridge v3.0 Required and apply v3.1 Uninstall to those groups.

Trigger 3: Business-critical failure immediate rollback
- Condition:
  - A reproducible defect prevents Finance users from accessing required financial systems through FinBridge Connect (for example, authenticated tunnel established but ERP endpoints unreachable for more than 30 minutes across at least 20 Finance users).
- Decision owner:
  - Incident Commander (on-call) with Finance IT Service Owner concurrence.
- Decision window:
  - Immediate execution, no wait for percentage thresholds.
- Exact Intune rollback action:
  - Remove FinBridge v3.1 Required assignment from SG-FinBridge-v31-Finance-Required.
  - Assign FinBridge v3.0 as Required to SG-FinBridge-v31-Finance-Required.
  - Assign FinBridge v3.1 as Uninstall to SG-FinBridge-v31-Finance-Required if uninstall has passed validation.

Trigger 4: 4 GB RAM at-risk group isolation
- Condition:
  - 4 GB RAM subgroup failure rate exceeds 8.0% over any rolling 48-hour window, even if global ring metrics pass.
- Decision owner:
  - Endpoint Engineering Lead with EUC Architecture approval.
- Decision window:
  - 4 hours from confirmed threshold breach.
- Exact Intune containment action (ring isolation first):
  - Remove 4 GB group(s) from all active v3.1 Required assignments.
  - Keep non-4 GB groups progressing if their metrics remain within thresholds.
  - Assign isolated 4 GB group to v3.0 Required until compatibility fix or adjusted requirement policy is validated.

## 4. FINANCE DEADLINE RESOLUTION

Option A: Compress pilot to place Finance into Ring 2 by end of week 1
- Minimum safe pilot duration:
  - 72 hours minimum with at least one business day plus one non-business day observation.
- Risk introduced:
  - Reduced time to detect low-frequency stability issues before Finance expansion.
- Compensating control:
  - Increase live monitoring cadence to every 4 hours; pre-stage a rollback assignment package and approval chain; maintain Finance subgroup split (100 then 400) rather than one-step cutover.

Option B: Create a separate priority Ring 0 for Finance before main pilot
- Ring 0 structure:
  - 100 Finance users on day 1, then 400 Finance users on days 2 to 4 if Ring 0 gates pass.
  - Assigned/static Finance groups for strict targeting: SG-FinBridge-v31-Finance-R0-100 and SG-FinBridge-v31-Finance-R0-400.
- Ring 0 advance conditions:
  - Minimum 97.5% install success at 48 hours for first 100 users.
  - Maximum 2.0% failure rate.
  - Maximum 6 tickets per 100 users.
  - Zero severity-1 incidents.
- Ring 0 rollback plan:
  - If failure rate exceeds 4.0% for 12 hours or any business-critical failure occurs, immediately revert both Finance groups to v3.0 Required and set v3.1 Uninstall for those groups.

Recommendation
- Recommend Option B (Finance Ring 0), not Option A.
- Justification:
  - Meets Finance end-of-week-1 commitment with explicit control and rollback boundaries.
  - Avoids weakening the integrity of the main pilot for the rest of the 10,000-device rollout.
  - Contains business risk to a clearly bounded high-priority cohort while preserving data quality from Ring 1 for enterprise decisions.

Execution timeline summary (recommended Option B)
- Week 1:
  - Days 1 to 2: Finance Ring 0 first 100
  - Days 3 to 4: Finance Ring 0 remaining 400 after gate pass
  - Days 3 to 5: Main Ring 1 pilot 500
- Week 2:
  - Ring 2 early rollout 2,500 (including any remaining controlled cohorts)
- Week 3:
  - Ring 3 broad rollout remaining 7,000 in staged waves, complete by 2026-09-02
