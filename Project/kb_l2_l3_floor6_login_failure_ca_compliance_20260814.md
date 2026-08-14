# L2/L3 Knowledge Base: Floor 6 Login Failure and Slow Sign-In

Version: v 1.0  
Date: 14/08/2026  
Status: Draft

## Runbook Source Of Truth
- Source runbook: runbook_floor6_login_slow_signin_20260814.md
- Source version: 1.0
- Re-expression rule: This L2/L3 article is a role-specific re-expression of the same runbook flow and checks, not an independent troubleshooting path.

## Background
Floor 6 users sign in through Microsoft Entra identity controls and device compliance checks from Intune. At sign-in time, Conditional Access policy evaluates user identity, device state, and policy rules before access is granted. This matters because any mismatch between policy requirements and device compliance can block login or cause long delays while checks are retried.

## Symptom
Engineer observes:
- Multiple users from the same location (Floor 6) report login failures or very slow sign-in in the same time window.
- Pattern begins around business-start hours and affects more than one endpoint.

User reports:
- Cannot log in.
- Login takes a very long time.

## Root Cause
Specific technical cause:
- Conditional Access policy enforcement intersects with noncompliant or unknown Intune device state for a subset of Floor 6 endpoints.

Evidence that confirms it:
- Entra sign-in events show failure or delay tied to Conditional Access decision path.
- Intune device compliance view for affected devices shows one or more blocking controls not compliant.
- Comparison check shows affected users/devices fail where unaffected users/devices pass under the same policy period.

## Detection
Use this 3-minute confirm path before any policy change.

1. Open https://entra.microsoft.com and navigate to Identity > Monitoring and health > Sign-in logs.
Log location: Entra Sign-in logs.
Set filters: Time range = Last 30 minutes, User = one affected Floor 6 user, Status = Failure.
Fields to read: Date, User, Status, Failure reason, Error code, Correlation ID.
Expected pattern: At least one failure in the incident window.

2. Open the newest failed event and select the Conditional Access tab.
Log location: Entra Sign-in logs > selected event > Conditional Access.
Fields to read: Policy name, Result.
Expected pattern: Target policy Result = Failure or blocked decision.

3. In the same failed event, select the Device info tab.
Log location: Entra Sign-in logs > selected event > Device info.
Fields to read: Device ID, Join type, Compliant.
Expected pattern: Compliant = No or Unknown on failed event.

4. Open https://intune.microsoft.com and navigate to Devices > All devices > open the same device (by Device ID or name) > Monitor > Device compliance.
Log location: Intune device compliance record.
Fields to read: Compliance state, failing controls, Last check-in.
Expected pattern: Compliance state = Noncompliant or In grace period with one or more failing controls.

5. Run one affected-versus-unaffected comparison.
Comparison check:
- Affected pair: one Floor 6 user and device.
- Unaffected pair: one known-good user and device from another floor in same 30-minute window.
Log locations: Entra Sign-in logs and Intune device compliance.
Fields to compare: Entra Status, Entra Conditional Access Result, Intune Compliance state.
Expected pattern: Affected pair = failure plus CA block plus noncompliant device; unaffected pair = success plus no CA block plus compliant device.

6. On one affected endpoint, open Event Viewer (eventvwr.msc) > Windows Logs > Security and apply Filter Current Log for Event IDs 4625,4624.
Log location: Endpoint Security log.
Fields to read: TimeCreated, Account Name, Logon Type, Failure Information.
Expected pattern: Repeated Event ID 4625 in incident window; Event ID 4624 appears only after successful recovery.

Decision rule:
- Confirm this incident type only if steps 2, 3, and 4 all match expected patterns and step 5 comparison also matches.
- If any of steps 2, 3, or 4 does not match, stop and branch to alternate diagnosis.

Note on error codes:
- Record Entra Error code exactly as shown.
- Do not infer code meaning unless your tenant error-code catalog explicitly defines it.

## Resolution
Objective: restore user sign-in in 5-10 minutes, then return policy to normal.

1. Open https://entra.microsoft.com > Identity > Monitoring and health > Sign-in logs.
Action: Set filters Time range = Last 30 minutes, Status = Failure, User = first affected user.
Expected result: At least one failed event is visible for the selected user.

2. Open the failed event > Conditional Access tab.
Action: Confirm target Conditional Access policy Result = Failure or blocked.
Expected result: Policy block is confirmed as active for this incident.

3. Open https://entra.microsoft.com > Identity > Groups > All groups > open emergency Floor 6 group > Members.
Action: Click Add members and add exactly the 3 validated affected users. [ELEVATED]
Expected result: Group member count increases by 3.

4. Open https://entra.microsoft.com > Protection > Conditional Access > Policies > open target policy.
Action: Open Exclude > Users and groups > Select groups > add emergency Floor 6 group > Select > Done > Save. [ELEVATED]
Expected result: Policy exclusion is active for emergency group.

5. Ask one affected user to attempt sign-in immediately.
Action: Capture success or failure time.
Expected result: User signs in successfully or delay is materially reduced.

6. Open https://intune.microsoft.com > Devices > All devices > select affected device > Sync.
Action: Click Sync for first affected device.
Expected result: Sync action is accepted by Intune.

7. Repeat Sync for second and third affected devices.
Action: Devices > All devices > device > Sync.
Expected result: All 3 devices show sync action submitted.

8. Open affected device record in Intune > Monitor > Device compliance.
Action: Record failing controls and remediate top blocking control defined by policy.
Expected result: At least one blocking control moves toward compliant.

9. Refresh Device compliance for all 3 devices after sync.
Action: Reopen Monitor > Device compliance on each device.
Expected result: Compliance state becomes Compliant or blocker count decreases.

10. Open Entra target CA policy again.
Action: Remove emergency group from Exclude > Save. [ELEVATED]
Expected result: Temporary exclusion is removed.

11. Open emergency Floor 6 group > Members.
Action: Remove incident-added users. [ELEVATED]
Expected result: Emergency group is returned to pre-incident scope.

12. Ask all 3 users to sign in once under normal policy.
Action: Record outcomes and timestamps.
Expected result: All 3 users sign in without failure.

## Verification
1. Open https://entra.microsoft.com > Identity > Monitoring and health > Sign-in logs.
Check: Time range = Last 1 hour; test each of the 3 remediated users.
Pass criteria: Latest event Status = Success.

2. In each successful Entra event, open Conditional Access tab.
Check field: Target policy Result.
Pass criteria: Result is not blocked for tested sign-ins.

3. Open https://intune.microsoft.com > Devices > All devices > each remediated device > Monitor > Device compliance.
Check fields: Compliance state, failing controls, last check-in.
Pass criteria: Compliance state = Compliant and no blocking controls remain.

4. On one remediated endpoint open eventvwr.msc > Windows Logs > Security.
Check: Filter Current Log with Event IDs 4624,4625 and time window after fix.
Pass criteria: At least one new 4624 success and no repeated 4625 burst pattern.

5. Open eventvwr.msc > Applications and Services Logs > Microsoft > Windows > User Device Registration > Admin.
Check: Error events after remediation timestamp.
Pass criteria: No new critical registration error trend after fix.

6. Open ITSM queue filter for Floor 6 login incidents for last 60 minutes.
Check: Ticket volume and priority.
Pass criteria: No new high-priority repeat incident created after fix confirmation.

## Rollback
Use immediately if sign-ins worsen or impact expands. Target rollback time: under 3 minutes.

1. Open https://entra.microsoft.com > Protection > Conditional Access > Policies > open target policy.
Action: Remove emergency Floor 6 group from Exclude > Users and groups > Save. [ELEVATED]
Expected result: Temporary bypass is disabled immediately.

2. Open https://entra.microsoft.com > Identity > Groups > All groups > emergency Floor 6 group > Members.
Action: Select incident-added users > Remove > Confirm. [ELEVATED]
Expected result: Emergency group returns to pre-incident membership.

3. Open https://entra.microsoft.com > Identity > Monitoring and health > Sign-in logs.
Action: Set Time range = Last 15 minutes and check one impacted user.
Expected result: Immediate post-rollback auth state is visible.

4. Open one impacted endpoint > eventvwr.msc > Windows Logs > Security.
Action: Filter Current Log with Event IDs 4624,4625 and time window = Last 15 minutes.
Expected result: Current success or failure pattern is immediately visible.

5. Open https://intune.microsoft.com > Devices > All devices > each actively changed device > Device actions.
Action: Cancel pending incident-started remediation actions if available.
Expected result: No additional remediation changes continue in background.

6. Update incident timeline and bridge message.
Action: Post "Rollback executed" with timestamp, CA policy name, and emergency group name; then escalate to IAM and Endpoint leads.
Expected result: Team has a synchronized checkpoint and controlled next action.

## Preventive
Strengthened controls (existing controls retained and expanded):

1. CAB auth-path gate with canary tests.
Owner: change manager; Timing: before deployment; Mode: manual now, automate via release pipeline policy check [REQUIRES: release pipeline policy gate].
Pass/Fail signal: Pass only if Entra canary sign-in success is 3/3 and Intune canary compliance is 3/3 in the pre-release window; Fail if either count is below target.
If fail: block CAB approval and return change to release engineer with failed test evidence attached.

2. In-flight sign-in failure alert by floor ring.
Owner: DWP engineer; Timing: during deployment; Mode: automated [REQUIRES: scheduled query alert in Entra or SIEM connector].
Pass/Fail signal: Alert when failed sign-ins tied to same Conditional Access policy exceed 10 events in 15 minutes for one floor ring.
If fail: auto-page on-call, freeze rollout, and execute rollback decision in 10 minutes.

3. Intune compliance drift alert during rollout.
Owner: release engineer; Timing: during deployment; Mode: automated [REQUIRES: Intune compliance export plus alert rule].
Pass/Fail signal: Fail if noncompliant devices in active rollout ring exceed 5 percent or increase by more than 3 devices in 10 minutes.
If fail: auto-open P2 incident, pause next ring promotion, and assign top failing controls for remediation.

4. Temporary exclusion hygiene for emergency access.
Owner: change manager; Timing: during deployment and after deployment; Mode: manual now, automate via policy-as-code validation [REQUIRES: CA policy lint/check process].
Pass/Fail signal: Pass only if each exclusion has owner, expiry timestamp, and linked change ID; Fail if any field is missing.
If fail: reject or revert policy save and require corrected exclusion metadata before proceeding.

5. Post-change validation checklist in change record.
Owner: service desk lead; Timing: after deployment; Mode: manual now, automate by mandatory ITSM form rules [REQUIRES: ITSM workflow rule update].
Pass/Fail signal: Pass only if all fields are completed: 3-user Entra success check, 3-device Intune compliant check, rollback owner, rollback timestamp test.
If fail: change cannot be closed and remains in implementation state until evidence is provided.

6. Pre-deployment smoke-test gate (additional explicit layer).
Owner: release engineer; Timing: before deployment; Mode: manual now, automate via scripted smoke test runner [REQUIRES: scripted Entra plus Intune smoke test job].
Pass/Fail signal: Pass only if one test user per target floor and one test device per target floor complete login in under 90 seconds with CA result not blocked.
If fail: do not start deployment window; raise change risk rating and reschedule.

7. Post-deployment health validation gate (additional explicit layer).
Owner: DWP engineer; Timing: after deployment; Mode: manual.
Pass/Fail signal: Pass only if Event ID 4625 count does not exceed baseline plus 20 percent for 60 minutes and no new P1 or P2 login incidents are opened.
If fail: keep change open, activate incident bridge, and start controlled rollback.

8. Rollback trigger threshold (additional explicit layer).
Owner: change manager; Timing: during deployment; Mode: automated trigger with manual approval [REQUIRES: rollout dashboard threshold rule].
Pass/Fail signal: Trigger rollback when any threshold is met: sign-in failures above 10 in 15 minutes, affected users above 5, or compliance below 95 percent in active ring.
If fail threshold met: stop rollout immediately and execute rollback runbook within 3 minutes.

9. Knowledge update control from incident learnings (additional explicit layer).
Owner: service desk lead; Timing: after deployment and after incident closure; Mode: manual now, automate with closure checklist [REQUIRES: mandatory KB update task in ITSM].
Pass/Fail signal: Pass only if runbook and L1 and L2-L3 KB versions are updated within 2 business days and linked to incident record.
If fail: block final incident closure and escalate to DWP engineer for documentation completion.

## Related
- runbook_floor6_login_slow_signin_20260814.md
- rca_floor6_login_slow_signin_20260814.md
- floor6_login_slow_signin_detailed_analysis_20260814.md
- incident_triage_floor6_login_and_slow_signin.md
- floor6_login_scope_only_hypothesis_20260814.md