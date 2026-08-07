# Title: Finance Shared Drive S: Not Mapping - Intune SYSTEM Context Race Condition
# Version: 1.0
# Date: 07/08/2026
# Author: prathameshgavade
# reviewed: self
# status: draft
# change: initial version from RCA

Audience: DWP engineers handling Finance shared drive mapping failures under time pressure.
Scenario: Finance users cannot access S: mapped to \\finbridge-fs01\Finance after logon.

## 1. Prerequisites

### Access Checklist

- [ ] Confirm Intune role has permission to read and edit platform scripts at `Intune admin center > Devices > Manage devices > Scripts and remediations > Platform scripts`. [Elevated]
- [ ] Confirm Intune role has permission to trigger device sync at `Intune admin center > Devices > All devices > <device> > ... > Sync`. [Elevated]
- [ ] Confirm permission to sign in to one affected Finance endpoint for pilot validation (local logon, RDP, or approved remote support tool).
- [ ] Confirm permission to open `Event Viewer` on the pilot endpoint. [Elevated]
- [ ] Confirm permission to read `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log` on the pilot endpoint. [Elevated]
- [ ] Confirm approved test account for Finance is available and can sign in to an affected endpoint.

### Tools And Systems Checklist

- [ ] Confirm browser access to `https://intune.microsoft.com`.
- [ ] Confirm Notepad or CMTrace is available on the pilot endpoint to read IME logs.
- [ ] Confirm File Explorer is available on the pilot endpoint for drive validation.
- [ ] Confirm script object exists as `Map-FinBridgeDrives.ps1` in `Platform scripts`.
- [ ] Confirm affected device naming pattern is `DESKTOP-FB*`.
- [ ] Confirm target mapping is `S:` to `\\finbridge-fs01\Finance`.

### Mandatory Information From End User

- [ ] Record affected user full UPN (example: user@finbridge.com).
- [ ] Record affected device hostname (example: DESKTOP-FB041).
- [ ] Record exact first failure time with time zone.
- [ ] Record exact error text shown by user when opening `S:` or `\\finbridge-fs01\Finance`.
- [ ] Record whether issue happens at every sign-in or intermittently.
- [ ] Record whether manual mapping using `net use S: \\finbridge-fs01\Finance` works.
- [ ] Record whether user can open other network shares.
- [ ] Record whether user already tried sign out/sign in.
- [ ] Record whether user is on VPN, office LAN, or other network at time of failure.

### Mandatory Information From Service Desk / Monitoring

- [ ] Record current count of affected Finance users.
- [ ] Record at least three affected device names if incident is widespread.
- [ ] Record whether non-Finance users are impacted.
- [ ] Record whether any concurrent file server or network incident exists.
- [ ] Record incident/ticket ID used for all changes and closure evidence.

### Change Safety Checklist

- [ ] Record current `Run this script using the logged on credentials` value before any edit. [Elevated]
- [ ] Record current script version and last known-good script version before any edit. [Elevated]
- [ ] Capture screenshot of current script assignment groups before any edit. [Elevated]
- [ ] Confirm assignment scope is Finance-only before any edit. [Elevated]

## 2. Procedure

1. Open `https://intune.microsoft.com`.
Expected result: Intune admin center sign-in page opens.

2. Sign in with your privileged Intune account. [Elevated]
Expected result: Intune home page opens.

3. Select `Devices` in the left navigation.
Expected result: `Devices | Overview` page opens.

4. Select `Manage devices`.
Expected result: Manage devices menu expands.

5. Select `Scripts and remediations`.
Expected result: Scripts and remediations page opens.

6. Select `Platform scripts`.
Expected result: Platform scripts list opens.

7. Select `Map-FinBridgeDrives.ps1`. [Elevated]
Expected result: Script overview pane opens.

8. Select `Properties`.
Expected result: Script property summary opens.

9. Record the current value of `Run this script using the logged on credentials`. [Elevated]
Expected result: Current execution context is documented in the incident notes.

10. Record the current script version value. [Elevated]
Expected result: Current version is documented in the incident notes.

11. Select `Edit` in the `Script settings` section. [Elevated]
Expected result: Script settings edit pane opens.

12. Set `Run this script using the logged on credentials` to `Yes`. [Elevated]
Expected result: Field shows `Yes`.

13. Select `Review + save`. [Elevated]
Expected result: Review page opens showing the new execution context.

14. Select `Save`. [Elevated]
Expected result: Notification confirms script settings saved successfully.

15. Select `Properties` again.
Expected result: Updated script property summary opens.

16. Select `Edit` in the `Basics` section. [Elevated]
Expected result: Basic properties edit pane opens.

17. Increase the `Version` value by one increment (example: `1.0` to `1.1`). [Elevated]
Expected result: New version value is visible in the version field.

18. Select `Review + save`. [Elevated]
Expected result: Review page opens with new version value.

19. Select `Save`. [Elevated]
Expected result: Notification confirms version update saved successfully.

20. Select `Assignments`.
Expected result: Assignment groups page opens.

21. Confirm only Finance target groups are assigned.
Expected result: No non-Finance groups are present.

22. Select `Devices` in the left navigation.
Expected result: Devices area opens.

23. Select `All devices`.
Expected result: Device list opens.

24. Search for the pilot hostname in the device search box.
Expected result: Pilot device record appears in the results.

25. Select the pilot device record. [Elevated]
Expected result: Pilot device overview page opens.

26. Select `...` (More) on the top command bar.
Expected result: Device action menu opens.

27. Select `Sync`. [Elevated]
Expected result: Confirmation message indicates sync request sent.

28. Sign out the current user from the pilot endpoint.
Expected result: Pilot endpoint returns to sign-in screen.

29. Sign in to the pilot endpoint with the approved Finance test account.
Expected result: Desktop loads for the test account.

30. Open `File Explorer > This PC` on the pilot endpoint.
Expected result: Local and mapped drives list is displayed.

31. Open drive `S:`.
Expected result: `\\finbridge-fs01\Finance` content opens without error.

32. Open `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log` in Notepad or CMTrace on the pilot endpoint. [Elevated]
Expected result: IME log file opens.

33. Search in the IME log for `Map-FinBridgeDrives.ps1`.
Expected result: Most recent script execution entries are located.

34. Confirm the latest script execution entry shows exit code `0`.
Expected result: Script success is confirmed at log level.

35. Open `Event Viewer > Windows Logs > System` on the pilot endpoint.
Expected result: System log console opens.

36. Filter the System log by `Event sources: Service Control Manager` and `Event ID: 7036`.
Expected result: Workstation service state change events are displayed.

37. Confirm a `Workstation` service running event exists in the latest logon window.
Expected result: SMB client service readiness is confirmed for that session.

38. Return to `Intune admin center > Devices > All devices`.
Expected result: Device list opens.

39. Select each remaining affected Finance device and run `... > Sync`. [Elevated]
Expected result: Sync actions are queued for all affected Finance devices.

40. Send Service Desk instruction for one mandatory user sign-out and sign-in across affected Finance users.
Expected result: User re-logon action is initiated across impacted population.

## 3. Verification

1. Open `https://intune.microsoft.com`.
Expected result: Intune admin center sign-in page or home page opens.

2. Go to `Devices > All devices > <pilot-device> > Device status > Device action status`.
Expected result: A recent `Sync` action is shown for the pilot device.

3. Sign in to the pilot endpoint with the approved Finance test user account.
Expected result: User desktop opens successfully.

4. Open `File Explorer > This PC` on the pilot endpoint.
Expected result: Drive list is visible.

5. Open drive `S:` from `This PC`.
Expected result: `\\finbridge-fs01\Finance` opens with folder contents and no error popup.

6. Open `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log` in Notepad or CMTrace. [Elevated]
Expected result: IME log opens.

7. Search for `Map-FinBridgeDrives.ps1` in the IME log.
Expected result: Latest script execution block is located.

8. Confirm the latest execution block contains a success result (`exit code 0` or `completed successfully`).
Expected result: Script execution success is confirmed in logs.

9. Open `Event Viewer > Windows Logs > System`.
Expected result: System log console opens.

10. Select `Filter Current Log...` and set `Event sources` to `Service Control Manager` and `Event IDs` to `7036`.
Expected result: Only relevant service state events are displayed.

11. Confirm a `Workstation` service running event exists for the same logon window.
Expected result: SMB client readiness is confirmed in the pilot session timeline.

12. Repeat steps 3 to 8 on three additional affected Finance devices.
Expected result: All sampled devices show S: access and successful script execution.

13. Check Service Desk queue for 30 minutes for new Finance shared-drive incidents.
Expected result: No new related tickets are raised.

14. Save closure evidence in the incident ticket: one S: access screenshot, one IME success snippet, and sampled device list.
Expected result: Closure evidence is complete and auditable.

## 4. Rollback

Use this rollback only if the new configuration causes broader impact (for example, S: mapping failure increases, non-Finance targets are affected, or user logon script behavior regresses).

Target execution time: under 3 minutes.

1. Open `https://intune.microsoft.com`.
Expected result: Intune admin center opens.

2. Navigate to `Devices > Manage devices > Scripts and remediations > Platform scripts > Map-FinBridgeDrives.ps1 > Properties > Edit`.
Expected result: Script settings edit page opens. [Elevated]

3. Set `Run this script using the logged on credentials` to `No`.
Expected result: Field value shows `No`. [Elevated]

4. Select `Review + save`, then select `Save`.
Expected result: Confirmation toast shows settings saved. [Elevated]

5. Navigate to `Map-FinBridgeDrives.ps1 > Properties > Basics > Edit`.
Expected result: Basic properties edit page opens. [Elevated]

6. Set `Version` back to the pre-change value recorded in the prerequisite checklist.
Expected result: Previous known-good version is shown. [Elevated]

7. Select `Review + save`, then select `Save`.
Expected result: Confirmation toast shows version rollback saved. [Elevated]

8. Go to `Devices > All devices`, select the pilot device, then run `... > Sync`.
Expected result: Sync request submitted. [Elevated]

9. On the pilot endpoint, open `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log` and confirm a new script run appears after rollback timestamp.
Expected result: Rollback policy ingestion is confirmed by new IME log activity. [Elevated]

10. Send immediate Service Desk advisory: temporary user workaround command `net use S: \\finbridge-fs01\Finance`.
Expected result: Users receive instant fallback while engineering reworks the fix.

## 5. Notes

- This issue pattern is strongly indicated by Intune script execution as SYSTEM plus Win32 error 53 (`Network name cannot be found`) during logon.
- SYSTEM context can run before `LanmanWorkstation` is ready; user context aligns better with drive mapping at interactive logon.
- If S: exists but access is denied, treat as ACL or group membership issue, not this race condition.
- If `\\finbridge-fs01\Finance` fails from multiple non-Finance endpoints, investigate file server, DNS, or network path before changing Intune script settings.
- If users stay logged in for long periods, they may not receive corrected behavior until sign-out/sign-in.
- Related incident: Finance shared drive outage on 2026-08-07 caused by Intune SYSTEM context timing.
- Related known error candidate: GPO-to-Intune script migration without execution-context validation.
