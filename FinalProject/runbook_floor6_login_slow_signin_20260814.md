# Runbook: Floor 6 Login Failures and Slow Sign-In

## Version Header
- Title: Floor 6 Login Failures and Slow Sign-In Runbook
- Version: 1.0
- Date: 14/08/2026
- Author: prathameshgavade
- Reviewed: self
- Status: draft
- Change: initial version from RCA

## Purpose
Provide a cold-start, pressure-ready procedure to restore Floor 6 login service when users cannot log in or sign-in is extremely slow, based on the validated RCA hypothesis: Conditional Access and Intune compliance mismatch on a subset of endpoints.

## Scope
- Incident pattern: Multiple users on Floor 6 report login failure or very slow sign-in.
- Service area: Microsoft Entra sign-in path, Conditional Access, and Intune compliance state.

## 1) Prerequisites

Use this checklist before starting. Do not begin Procedure until all mandatory items are checked.

### 1.1 Access checklist
- [ ] [ELEVATED] You can sign in to Microsoft Entra admin center with Security Administrator or Conditional Access Administrator role.
- [ ] [ELEVATED] You can sign in to Microsoft Intune admin center with Intune Administrator or Endpoint Security Manager role.
- [ ] [ELEVATED] You can edit membership of the pre-approved emergency access group for Floor 6.
- [ ] You can read Entra sign-in logs.
- [ ] You can read Intune device compliance reports.

### 1.2 Tools and systems checklist
- [ ] Browser session open to Microsoft Entra admin center at https://entra.microsoft.com.
- [ ] Browser session open to Microsoft Intune admin center at https://intune.microsoft.com.
- [ ] Active incident ticket open in ITSM tool.
- [ ] Change record approved for temporary Conditional Access exclusion.
- [ ] Communication channel available (incident bridge or service desk war room).

### 1.3 Mandatory information from end users checklist
- [ ] Three affected Floor 6 usernames in UPN format (example: user@company.com).
- [ ] One exact failed login timestamp per selected user (local time with time zone).
- [ ] Device name for each selected user (example: FB-L6-LAP-104).
- [ ] Network type for each selected user at failure time (wired, wifi, VPN, or remote).
- [ ] Screenshot or exact text of on-screen login error if available.

### 1.4 Mandatory incident metadata checklist
- [ ] Name of the emergency access group approved for temporary bypass.
- [ ] Name of the target Conditional Access policy under investigation.
- [ ] Rollback approver name and contact method confirmed.
- [ ] Communications owner for user updates confirmed.

## 2) Procedure

1. Enter the incident ticket ID and change record ID into your working notes template.
Expected result: Every action can be traced to an approved incident and change.

2. Open Microsoft Entra admin center and go to Identity > Monitoring and health > Sign-in logs.
Expected result: The Sign-in logs page is open.

3. Set the Sign-in logs Time range filter to start at 08:45 and end at current time.
Expected result: Log view includes the full suspected incident window.

4. Set the Sign-in logs User filter to the first affected user UPN.
Expected result: Log rows are reduced to the selected user.

5. Set the Sign-in logs Status filter to Failure.
Expected result: Failed sign-in events are isolated.

6. Open the failed event that matches the user-provided timestamp.
Expected result: Event details panel is visible for that exact failure.

7. Record the values from the Basic info tab (Status, Failure reason, Error code, Correlation ID) into incident notes.
Expected result: The key authentication evidence fields are captured.

8. Open the Conditional Access tab for the same event and record the policy result for the target policy.
Expected result: You know whether Conditional Access blocked or allowed the event.

9. Repeat steps 4 through 8 for the second affected user.
Expected result: Second evidence point is captured in the same format.

10. Repeat steps 4 through 8 for the third affected user.
Expected result: Third evidence point is captured in the same format.

11. Open Microsoft Intune admin center and go to Devices > All devices.
Expected result: Device inventory list is visible.

12. Search for the first affected device name and open the device record.
Expected result: Device details page is open for the correct endpoint.

13. Open Monitor > Device compliance in that device record.
Expected result: Compliance state and failed controls are visible for the device.

14. Record each failing compliance control name and last check-in time from the device compliance view.
Expected result: Compliance blockers are documented with timestamps.

15. Repeat steps 12 through 14 for the second affected device.
Expected result: Second device compliance evidence is captured.

16. Repeat steps 12 through 14 for the third affected device.
Expected result: Third device compliance evidence is captured.

17. [ELEVATED] In Entra admin center, go to Identity > Groups > All groups, open the emergency Floor 6 access group, and add the three affected users.
Expected result: The three users are members of the emergency access group.

18. [ELEVATED] In Entra admin center, go to Protection > Conditional Access > Policies, open the target policy, and add the emergency group under Exclude for Users.
Expected result: A time-boxed exclusion is active for only the emergency group.

19. Ask the first affected user to sign in and wait for one completed attempt.
Expected result: User sign-in succeeds or latency drops significantly.

20. In Intune, open the first affected device and select Sync.
Expected result: A new device sync job is submitted.

21. In Intune, open the second affected device and select Sync.
Expected result: A new device sync job is submitted.

22. In Intune, open the third affected device and select Sync.
Expected result: A new device sync job is submitted.

23. On the first affected endpoint, open Event Viewer and navigate to Windows Logs > Security, then filter Current Log for Event IDs 4625 and 4624.
Expected result: You can confirm failed and successful interactive sign-in events locally.

24. On the first affected endpoint, open Event Viewer and navigate to Applications and Services Logs > Microsoft > Windows > User Device Registration > Admin.
Expected result: Device registration and token-related events are visible for troubleshooting device state.

25. On the first affected endpoint, run dsregcmd /status in an elevated Command Prompt.
Expected result: AzureAdJoined, DomainJoined, and device state fields are visible for identity posture check.

26. Remediate the first listed failing compliance control in Intune according to the policy requirement.
Expected result: One blocking compliance issue is resolved or pending re-evaluation.

27. Remediate the second listed failing compliance control in Intune according to the policy requirement.
Expected result: Additional blocking compliance issue is resolved or pending re-evaluation.

28. In Intune, refresh Monitor > Device compliance for each of the three devices.
Expected result: Devices move to Compliant state or show reduced blocker count.

29. [ELEVATED] In Entra group membership, remove the three users from the emergency access group after compliance is confirmed.
Expected result: Temporary bypass user scope is removed.

30. [ELEVATED] In the Conditional Access policy, remove the emergency group from Exclude and save policy.
Expected result: Normal policy enforcement is fully restored.

31. Ask all three users to perform one new sign-in under normal policy.
Expected result: All three users complete sign-in without failure and without extreme delay.

32. Update incident notes with portal paths used, log evidence captured, actions taken, and timestamps.
Expected result: Incident record is complete for audit and handoff.

## 3) Verification

1. Open Microsoft Entra admin center at https://entra.microsoft.com and go to Identity > Monitoring and health > Sign-in logs.
Pass condition: Sign-in logs page is open.

2. Set Time range to "Last 1 hour" and set User to the first validated user UPN.
Pass condition: Only recent events for that user are displayed.

3. Set Status to "Success" and open the newest event.
Pass condition: Basic info shows successful sign-in for that user.

4. Open the Conditional Access tab in that event.
Pass condition: Target CA policy result is Success or Not applied due to normal compliant state, not due to temporary exclusion.

5. Repeat steps 2 through 4 for the second validated user.
Pass condition: Second user also shows success with no policy denial.

6. Repeat steps 2 through 4 for the third validated user.
Pass condition: Third user also shows success with no policy denial.

7. Open Microsoft Intune admin center at https://intune.microsoft.com and go to Devices > All devices.
Pass condition: Device inventory page is open.

8. Open each of the three validated devices and navigate to Monitor > Device compliance.
Pass condition: Compliance state is Compliant for each validated device.

9. On one validated endpoint, open Event Viewer at eventvwr.msc and go to Windows Logs > Security.
Pass condition: Security log is accessible.

10. In Security log, select Filter Current Log and set Event IDs to 4624,4625.
Pass condition: Recent successful sign-in events (4624) are present and no repeated fresh failure pattern (4625 burst) is visible after fix time.

11. On the same endpoint, open Event Viewer path Applications and Services Logs > Microsoft > Windows > User Device Registration > Admin.
Pass condition: No new critical device registration failures appear after remediation timestamp.

12. Open the ITSM queue filtered to Floor 6 login category for the last 60 minutes.
Pass condition: No new high-priority login-failure tickets were created after fix announcement.

13. In Entra admin center, go to Identity > Groups > All groups and open the emergency access group.
Pass condition: Group membership does not include temporary incident users.

14. In Entra admin center, go to Protection > Conditional Access > Policies and open the target policy.
Pass condition: Emergency group is not listed under Exclude and policy is Enabled.

## 4) Rollback (Immediate Action if Impact Worsens)

Trigger rollback if any of these occur:
- Sign-in failures increase after temporary exclusion change.
- Unintended users outside Floor 6 gain exclusion scope.
- Compliance remediation causes additional endpoint instability.

Target execution time: under 3 minutes.

Rollback steps:
1. [ELEVATED] Open Microsoft Entra admin center at https://entra.microsoft.com and navigate to Protection > Conditional Access > Policies > open target policy.
Expected result: Policy editor is open for immediate rollback.

2. [ELEVATED] In the target policy, remove the emergency access group from Exclude users and click Save.
Expected result: Temporary bypass path is removed from policy in one save action.

3. [ELEVATED] Navigate to Identity > Groups > All groups > open emergency access group > Members.
Expected result: Member list is open.

4. [ELEVATED] Select all incident-added users in Members and click Remove, then confirm removal.
Expected result: Emergency group is cleared of temporary incident users.

5. Open Identity > Monitoring and health > Sign-in logs, set Time range to Last 15 minutes, and filter by one impacted user.
Expected result: You can confirm post-rollback authentication outcomes immediately.

6. Open Microsoft Intune admin center at https://intune.microsoft.com and go to Devices > All devices > select each actively changed device > Device actions.
Expected result: Device actions panel is visible for each changed endpoint.

7. Cancel any pending remediation action you started in this incident window on those devices.
Expected result: No additional remediation change is in progress.

8. Open the endpoint Event Viewer path Windows Logs > Security and filter Event IDs 4625,4624 for the last 15 minutes.
Expected result: Fresh failure or success pattern is visible for immediate incident triage decision.

9. Post one message in the incident bridge: "Rollback executed" with timestamp, policy name, and group name.
Expected result: All responders have a synchronized rollback checkpoint.

10. Update the incident ticket timeline with rollback start time, rollback end time, and actions completed.
Expected result: Audit trail is complete and handoff-ready.

## 5) Notes

- This runbook is specific to the RCA hypothesis of access boundary and compliance mismatch.
- If Entra logs show invalid credential failures without policy/compliance denials, switch to credential-path investigation runbook.
- If sign-in failures are widespread across multiple floors at the same time, prioritize tenant or identity service health checks before endpoint remediation.
- If only slowness remains after successful authentication, assess profile load and post-login initialization separately.
- Related artifacts:
  - FinalProject/rca_floor6_login_slow_signin_20260814.md
  - FinalProject/floor6_login_slow_signin_detailed_analysis_20260814.md
  - FinalProject/incident_triage_floor6_login_and_slow_signin.md