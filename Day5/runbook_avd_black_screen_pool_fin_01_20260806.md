# Title: AVD Black Screen on POOL-FIN-01 After Image Update
# Version: 1.0
# Date: 07/08/2026
# Author: Sathishbabu
# Reviewed: self
# Status: draft
# Change: initial version from RCA

Audience: DWP engineers responding to Azure Virtual Desktop incidents  
Scenario: Users logging in to POOL-FIN-01 see a black screen, experience delayed desktop load, or disconnect shortly after logon.

## 1. Prerequisites

- [ ] Azure portal access is confirmed for `Azure Virtual Desktop`, `Virtual machines`, and the resource group that contains `POOL-FIN-01` and `POOL-FIN-02`.
- [ ] Local administrator rights on affected session hosts are confirmed. Required for steps marked `[Elevated]`.
- [ ] Access to one approved remote administration path is confirmed: `Azure portal > Virtual machines > Connect`, Azure Bastion, or the approved admin RDP path.
- [ ] Access to Event Viewer on affected session hosts is confirmed.
- [ ] Access to the team image management console for `POOL-FIN-01` is confirmed.
- [ ] The exact name of the current `POOL-FIN-01` image version is recorded.
- [ ] The exact name of the last known-good `POOL-FIN-01` image version is recorded.
- [ ] The approved graphics mitigation package is available before work starts.
- [ ] The approved rollback image version is available before work starts.
- [ ] Access to the unaffected comparison pool `POOL-FIN-02` is confirmed.
- [ ] A maintenance approval or incident manager approval to drain hosts and reboot hosts is confirmed.
- [ ] A test user account that is licensed for the finance desktop/application assignment is confirmed.

### Mandatory Information From The End User

- [ ] Affected user UPN or `DOMAIN\username` is recorded.
- [ ] Exact time the black screen was first seen is recorded with time zone.
- [ ] Whether the black screen recovered by itself is recorded.
- [ ] If recovery occurred, the approximate wait time before recovery is recorded.
- [ ] Whether the session disconnected automatically is recorded.
- [ ] Whether the issue happens on every sign-in or only some sign-ins is recorded.
- [ ] Whether the user can reconnect and eventually get a desktop is recorded.
- [ ] Whether other users in the same finance pool are affected is recorded.
- [ ] A screenshot or photo of the black screen is attached if the user can provide one.
- [ ] The user device type and connection method are recorded.
- [ ] The host pool name shown to the user or the affected session host name is recorded if available.
- [ ] The user confirms whether the issue started after the overnight image update window.

### Mandatory Information From Monitoring Or Service Desk

- [ ] List of affected `POOL-FIN-01` session hosts is recorded.
- [ ] Current active session count on `POOL-FIN-01` is recorded.
- [ ] Current active session count on `POOL-FIN-02` is recorded.
- [ ] The first host and first timestamp where the crash pattern was observed are recorded.
- [ ] Any recent image, driver, or host maintenance change on `POOL-FIN-01` is recorded.

## 2. Procedure

1. Open `https://portal.azure.com` in a browser.
Expected result: The Azure portal sign-in page or home page opens.

2. Open `Azure Virtual Desktop` from the Azure portal search bar.
Expected result: The Azure Virtual Desktop service page opens.

3. Select `Host pools` in the left navigation pane.
Expected result: The host pool list opens.

4. Select the host pool `POOL-FIN-01`.
Expected result: The `POOL-FIN-01` host pool overview page opens.

5. Select `Session hosts` under the `Manage` section for `POOL-FIN-01`.
Expected result: The `POOL-FIN-01` session host list opens.

6. Record the name of each session host that shows `Available` or an active session count greater than `0`.
Expected result: You have the exact list of hosts that are candidates for containment and validation.

7. Select `Host pools` again in the Azure Virtual Desktop service page.
Expected result: The host pool list opens.

8. Select the host pool `POOL-FIN-02`.
Expected result: The `POOL-FIN-02` host pool overview page opens.

9. Select `Session hosts` under the `Manage` section for `POOL-FIN-02`.
Expected result: The `POOL-FIN-02` session host list opens.

10. Confirm that at least one `POOL-FIN-02` host shows `Available` and can accept redirected users.
Expected result: You have confirmed there is healthy comparison capacity before draining `POOL-FIN-01`.

11. Return to `Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts`.
Expected result: The affected pool session host list is visible again.

12. Select the first affected session host in the `POOL-FIN-01` list. `[Elevated]`
Expected result: The session host details page opens.

13. Select `No` for `Allow new sessions` on the session host details page. `[Elevated]`
Expected result: The host enters drain mode and stops accepting new user sessions.

14. Select `Save` on the session host details page. `[Elevated]`
Expected result: Azure confirms the session host settings were updated successfully.

15. Repeat the drain change for each additional affected `POOL-FIN-01` session host. `[Elevated]`
Expected result: All unstable hosts are in drain mode.

16. Select `User sessions` under the `Monitor` section for `POOL-FIN-01`.
Expected result: The current session list for the affected pool opens.

17. Confirm that no new sessions are being assigned to drained `POOL-FIN-01` hosts.
Expected result: New sessions are no longer landing on the hosts placed in drain mode.

18. Open `Virtual machines` from the Azure portal search bar.
Expected result: The Azure virtual machine list opens.

19. Select the virtual machine that matches the first affected `POOL-FIN-01` session host name. `[Elevated]`
Expected result: The VM overview page opens.

20. Select `Connect` on the VM toolbar. `[Elevated]`
Expected result: The available connection methods open.

21. Select the approved connection method for your environment. `[Elevated]`
Expected result: The connection workflow for the target VM opens.

22. Sign in to the session host with a local administrator or approved privileged account. `[Elevated]`
Expected result: You have an administrative session on the affected host.

23. Open `Event Viewer` from the Start menu on the affected host. `[Elevated]`
Expected result: Event Viewer opens.

24. Expand `Windows Logs` in the Event Viewer left pane. `[Elevated]`
Expected result: The standard Windows logs are visible.

25. Select `Application` under `Windows Logs`. `[Elevated]`
Expected result: The Application log opens.

26. Select `Filter Current Log...` in the right `Actions` pane. `[Elevated]`
Expected result: The Application log filter dialog opens.

27. Enter `1000` in the `Includes/Excludes Event IDs` field. `[Elevated]`
Expected result: The filter is ready to show Application Error events only.

28. Select `OK` in the filter dialog. `[Elevated]`
Expected result: The Application log shows only `Event ID 1000` entries.

29. Open the most recent `Event ID 1000` created during the affected user sign-in window. `[Elevated]`
Expected result: The event details pane opens.

30. Confirm that `Faulting application name` is `dwm.exe` in the event details. `[Elevated]`
Expected result: The event matches the expected Desktop Window Manager crash pattern.

31. Confirm that `Faulting module name` is `igdumd64.dll` in the event details. `[Elevated]`
Expected result: The event matches the Intel graphics regression signature.

32. Expand `Applications and Services Logs` in the Event Viewer left pane. `[Elevated]`
Expected result: The application and service log tree opens.

33. Browse to `Applications and Services Logs > Microsoft > Windows > Desktop Window Manager-Operational`. `[Elevated]`
Expected result: The DWM operational log opens.

34. Select `Filter Current Log...` in the right `Actions` pane for the DWM log. `[Elevated]`
Expected result: The DWM log filter dialog opens.

35. Enter `9009` in the `Includes/Excludes Event IDs` field. `[Elevated]`
Expected result: The filter is ready to show DWM exit events only.

36. Select `OK` in the filter dialog. `[Elevated]`
Expected result: The DWM log shows only `Event ID 9009` entries.

37. Confirm that a `9009` event exists within the same time window as the `dwm.exe` application crash. `[Elevated]`
Expected result: You have matched the DWM exit to the user impact window.

38. Browse to `Applications and Services Logs > Microsoft > Windows > TerminalServices-LocalSessionManager > Operational`. `[Elevated]`
Expected result: The Local Session Manager operational log opens.

39. Select `Filter Current Log...` in the right `Actions` pane for the Local Session Manager log. `[Elevated]`
Expected result: The Local Session Manager filter dialog opens.

40. Enter `21,40` in the `Includes/Excludes Event IDs` field. `[Elevated]`
Expected result: The filter is ready to show only logon success and disconnect events.

41. Select `OK` in the filter dialog. `[Elevated]`
Expected result: The Local Session Manager log shows only `Event ID 21` and `Event ID 40` entries.

42. Confirm that the affected user has an `Event ID 21` followed by an `Event ID 40` in the same incident window. `[Elevated]`
Expected result: You have confirmed the logon-success followed by disconnect sequence.

43. Open `Device Manager` from the Start menu on the affected host. `[Elevated]`
Expected result: Device Manager opens.

44. Expand `Display adapters` in Device Manager. `[Elevated]`
Expected result: The installed graphics adapter list is visible.

45. Open the properties of the active Intel display adapter. `[Elevated]`
Expected result: The adapter properties dialog opens.

46. Select the `Driver` tab in the adapter properties dialog. `[Elevated]`
Expected result: The installed driver version and driver date are visible.

47. Record the installed driver version and driver date from the `Driver` tab. `[Elevated]`
Expected result: The current graphics driver baseline for the host is documented.

48. Compare the recorded driver version with the last known-good image baseline recorded in the prerequisites.
Expected result: You know whether the host is using the regressed graphics stack.

49. Open the approved remote administration console or package location that contains the approved graphics mitigation package for this incident. `[Elevated]`
Expected result: The exact approved mitigation package is available to run.

50. Execute the approved graphics mitigation package on the affected host. `[Elevated]`
Expected result: The mitigation completes without errors.

51. Restart the affected session host from `Azure portal > Virtual machines > <affected-host> > Overview > Restart`. `[Elevated]`
Expected result: Azure shows the restart request as submitted and the VM returns online.

52. Sign in to the restarted host with the approved test user account.
Expected result: The desktop loads without a black screen and the session stays connected.

53. Repeat the mitigation and restart actions for each remaining affected `POOL-FIN-01` session host. `[Elevated]`
Expected result: Each unstable host is remediated in a controlled wave.

54. Open the team image management console used to publish the `POOL-FIN-01` image. `[Elevated]`
Expected result: The image publishing console opens.

55. Select the image definition used by `POOL-FIN-01`. `[Elevated]`
Expected result: The current image versions for the pool are visible.

56. Select the approved corrected image version or create the corrected image version using the validated graphics baseline. `[Elevated]`
Expected result: A corrected image version is ready for deployment.

57. Deploy the corrected image to one canary session host in `POOL-FIN-01`. `[Elevated]`
Expected result: One host is updated for controlled validation.

58. Restart the canary host after the corrected image deployment. `[Elevated]`
Expected result: The canary host returns online on the corrected image.

59. Sign in to the canary host with the approved test user account.
Expected result: The desktop loads normally and the session remains stable.

60. Review `Windows Logs > Application` for new `Event ID 1000` entries after the canary sign-in. `[Elevated]`
Expected result: No new `dwm.exe` crash is present after image correction.

61. Review `Applications and Services Logs > Microsoft > Windows > Desktop Window Manager-Operational` for new `Event ID 9009` entries after the canary sign-in. `[Elevated]`
Expected result: No new DWM exit event is present after image correction.

62. Return to `Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts > <canary-host>`.
Expected result: The canary session host details page opens.

63. Select `Yes` for `Allow new sessions` on the canary session host details page. `[Elevated]`
Expected result: The canary host is prepared to accept production sessions again.

64. Select `Save` on the canary session host details page. `[Elevated]`
Expected result: Azure confirms the canary host settings were updated successfully.

65. Deploy the corrected image to the remaining affected `POOL-FIN-01` session hosts. `[Elevated]`
Expected result: All affected hosts are updated to the validated image.

66. Set `Allow new sessions` to `Yes` on each remediated session host only after successful host-level validation. `[Elevated]`
Expected result: Remediated hosts are returned to service one by one.

67. Monitor `Azure Virtual Desktop > Host pools > POOL-FIN-01 > User sessions` for 30 minutes after the last host returns to service.
Expected result: Users sign in successfully with no new black screen or disconnect pattern.

## 3. Verification

1. Open `https://portal.azure.com` in a browser.
Expected result: The Azure portal sign-in page or home page opens.

2. Open `Azure Virtual Desktop` from the Azure portal search bar.
Expected result: The Azure Virtual Desktop service page opens.

3. Select `Host pools` in the left navigation pane.
Expected result: The host pool list opens.

4. Select the host pool `POOL-FIN-01`.
Expected result: The `POOL-FIN-01` host pool overview page opens.

5. Select `Session hosts` under the `Manage` section for `POOL-FIN-01`.
Expected result: The `POOL-FIN-01` session host list opens.

6. Confirm that each remediated session host shows `Available` and `Allow new sessions` set to `Yes`.
Expected result: The pool shows only validated hosts accepting new sessions.

7. Select `User sessions` under the `Monitor` section for `POOL-FIN-01`.
Expected result: The current user session list opens.

8. Confirm that new user sessions are being created successfully on remediated `POOL-FIN-01` hosts.
Expected result: The pool is accepting production traffic again.

9. Sign in to `POOL-FIN-01` with the approved test user account.
Expected result: The desktop opens without a black screen.

10. Disconnect the test user session from the desktop session.
Expected result: The session disconnect completes without error.

11. Reconnect the same test user to `POOL-FIN-01`.
Expected result: The desktop reconnects without a black screen or forced disconnect.

12. Open `Virtual machines` from the Azure portal search bar.
Expected result: The Azure virtual machine list opens.

13. Select the first remediated session host VM. `[Elevated]`
Expected result: The VM overview page opens.

14. Select `Connect` on the VM toolbar. `[Elevated]`
Expected result: The available connection methods open.

15. Select the approved connection method for your environment. `[Elevated]`
Expected result: The connection workflow for the target VM opens.

16. Sign in to the session host with a local administrator or approved privileged account. `[Elevated]`
Expected result: You have an administrative session on the remediated host.

17. Open `Event Viewer` from the Start menu on the remediated host. `[Elevated]`
Expected result: Event Viewer opens.

18. Browse to `Windows Logs > Application`. `[Elevated]`
Expected result: The Application log opens.

19. Select `Filter Current Log...` in the right `Actions` pane. `[Elevated]`
Expected result: The Application log filter dialog opens.

20. Enter `1000` in the `Includes/Excludes Event IDs` field. `[Elevated]`
Expected result: The filter is ready to show Application Error events only.

21. Select `OK` in the filter dialog. `[Elevated]`
Expected result: The Application log shows only `Event ID 1000` entries.

22. Confirm that no new `Event ID 1000` event exists after remediation where `Faulting application name` is `dwm.exe` and `Faulting module name` is `igdumd64.dll`. `[Elevated]`
Expected result: No new application crash evidence is present after the fix.

23. Browse to `Applications and Services Logs > Microsoft > Windows > Desktop Window Manager-Operational`. `[Elevated]`
Expected result: The DWM operational log opens.

24. Select `Filter Current Log...` in the right `Actions` pane. `[Elevated]`
Expected result: The DWM log filter dialog opens.

25. Enter `9009` in the `Includes/Excludes Event IDs` field. `[Elevated]`
Expected result: The filter is ready to show DWM exit events only.

26. Select `OK` in the filter dialog. `[Elevated]`
Expected result: The DWM log shows only `Event ID 9009` entries.

27. Confirm that no new `Event ID 9009` entries exist after remediation in the validation window. `[Elevated]`
Expected result: No new DWM exit evidence is present after the fix.

28. Browse to `Applications and Services Logs > Microsoft > Windows > TerminalServices-LocalSessionManager > Operational`. `[Elevated]`
Expected result: The Local Session Manager operational log opens.

29. Select `Filter Current Log...` in the right `Actions` pane. `[Elevated]`
Expected result: The Local Session Manager filter dialog opens.

30. Enter `21,40` in the `Includes/Excludes Event IDs` field. `[Elevated]`
Expected result: The filter is ready to show only logon success and disconnect events.

31. Select `OK` in the filter dialog. `[Elevated]`
Expected result: The Local Session Manager log shows only `Event ID 21` and `Event ID 40` entries.

32. Confirm that the test user has a successful `Event ID 21` without a following `Event ID 40` in the same validation window. `[Elevated]`
Expected result: The test sign-in completed without the previous disconnect pattern.

33. Repeat the log validation on one additional remediated host if more than one host was affected. `[Elevated]`
Expected result: The fix is confirmed on more than one host before incident closure.

34. Confirm in the service desk queue or incident bridge notes that no new black screen reports were raised during the 30-minute validation window.
Expected result: User-facing symptoms remain cleared before closure.

35. Confirm that `POOL-FIN-02` did not enter an unhealthy or overloaded state during redirection.
Expected result: The comparison pool remained stable during recovery.

## 4. Rollback

1. Open `https://portal.azure.com` in a browser.
Expected result: The Azure portal sign-in page or home page opens.

2. Open `Azure Virtual Desktop` from the Azure portal search bar.
Expected result: The Azure Virtual Desktop service page opens.

3. Select `Host pools` in the left navigation pane.
Expected result: The host pool list opens.

4. Select the host pool `POOL-FIN-01`.
Expected result: The `POOL-FIN-01` host pool overview page opens.

5. Select `Session hosts` under the `Manage` section for `POOL-FIN-01`.
Expected result: The `POOL-FIN-01` session host list opens.

6. Select the degraded session host that became worse after mitigation or image remediation. `[Elevated]`
Expected result: The session host details page opens.

7. Select `No` for `Allow new sessions` on the session host details page. `[Elevated]`
Expected result: The degraded host stops accepting new user sessions.

8. Select `Save` on the session host details page. `[Elevated]`
Expected result: Azure confirms the drain setting was saved.

9. Repeat the drain action for every `POOL-FIN-01` host showing the same unstable behavior. `[Elevated]`
Expected result: All unstable hosts are blocked from taking new sessions.

10. Select `User sessions` under the `Monitor` section for `POOL-FIN-01`.
Expected result: The current user session list opens.

11. Identify all active users still connected to the degraded hosts.
Expected result: You know exactly which users are still on unstable hosts.

12. Instruct each identified user to sign out and reconnect after you confirm alternate capacity is available.
Expected result: Active users begin moving away from unstable hosts.

13. Select `Host pools` again in the Azure Virtual Desktop service page.
Expected result: The host pool list opens.

14. Select the host pool `POOL-FIN-02`.
Expected result: The `POOL-FIN-02` host pool overview page opens.

15. Select `Session hosts` under the `Manage` section for `POOL-FIN-02`.
Expected result: The `POOL-FIN-02` session host list opens.

16. Confirm that at least one `POOL-FIN-02` host shows `Available` before continuing.
Expected result: You have confirmed safe landing capacity for redirected users.

17. Stop the rollback procedure here if the immediate goal was containment and user impact is now controlled.
Expected result: The incident is stabilized within the first few minutes.

18. Open the team image management console used to publish the `POOL-FIN-01` image. `[Elevated]`
Expected result: The image publishing console opens.

19. Select the image definition used by `POOL-FIN-01`. `[Elevated]`
Expected result: The current and previous image versions are visible.

20. Disable further deployment of the newly remediated image version. `[Elevated]`
Expected result: No additional hosts can receive the unstable image.

21. Select the last known-good image version recorded in the prerequisites. `[Elevated]`
Expected result: The rollback image version is selected.

22. Set the last known-good image version as the active deployment source for `POOL-FIN-01`. `[Elevated]`
Expected result: The pool is ready to roll back to the stable image.

23. Deploy the last known-good image to one rollback canary host in `POOL-FIN-01`. `[Elevated]`
Expected result: One host is prepared for rollback validation.

24. Restart the rollback canary host from `Azure portal > Virtual machines > <rollback-canary-host> > Overview > Restart`. `[Elevated]`
Expected result: Azure shows the restart request as submitted and the host returns online.

25. Sign in to the rollback canary host with the approved test user account.
Expected result: The desktop loads normally and the session remains stable.

26. Open `Event Viewer` on the rollback canary host. `[Elevated]`
Expected result: Event Viewer opens.

27. Browse to `Windows Logs > Application`. `[Elevated]`
Expected result: The Application log opens.

28. Filter the Application log to `Event ID 1000`. `[Elevated]`
Expected result: The log shows only application crash events.

29. Confirm that no new `dwm.exe` crash with module `igdumd64.dll` occurred after rollback. `[Elevated]`
Expected result: The rollback image does not reproduce the application crash signature.

30. Browse to `Applications and Services Logs > Microsoft > Windows > Desktop Window Manager-Operational`. `[Elevated]`
Expected result: The DWM operational log opens.

31. Filter the DWM log to `Event ID 9009`. `[Elevated]`
Expected result: The log shows only DWM exit events.

32. Confirm that no new `Event ID 9009` exists after rollback validation. `[Elevated]`
Expected result: The rollback image does not reproduce the DWM exit signature.

33. Deploy the last known-good image to the remaining affected `POOL-FIN-01` hosts only after the canary rollback host passes validation. `[Elevated]`
Expected result: The affected pool returns to the last stable image in a controlled wave.

34. Set `Allow new sessions` to `Yes` on each rollback host only after sign-in and log validation succeeds. `[Elevated]`
Expected result: Restored hosts return to service without reintroducing user impact.

35. Escalate to the EUC Platform/Image Team with the failed image version, affected host names, and the exact Application and DWM event timestamps if the rollback canary host also fails. 
Expected result: Engineering receives the precise evidence needed for deeper image or driver investigation.

## 5. Notes

- Warning: Do not return a host to service after reboot alone unless you have completed a clean sign-in test and log review.
- Warning: If `POOL-FIN-02` does not have enough spare capacity, drain only a subset of affected `POOL-FIN-01` hosts at a time to avoid a broader service outage.
- Edge case: If the user can authenticate but never reaches the shell, continue to treat the incident as a display-composition failure when the `Event ID 21` -> `Event ID 1000` -> `Event ID 9009` -> `Event ID 40` sequence is present.
- Edge case: If no `igdumd64.dll` faults are present, stop using this runbook and switch to a separate logon failure investigation for FSLogix, shell, AppX, policy, or AVD agent issues.
- Related incident: Use this runbook together with the known error record in `Day4\known_error_avd_black_screen_pool_fin_01_20260806.md` when the symptom matches.
- Related incident: The unaffected comparison pool in this incident was `POOL-FIN-02`; if a future incident affects both pools, treat that as a different failure pattern and escalate earlier.