# L2/L3 Knowledge Base: Floor 6 Missing Desktop Icons

Version: v 1.0  
Date: 14/08/2026  
Status: Draft

## Background
Windows user desktops are built from two main locations: user desktop folder and public desktop folder. At sign-in, Windows loads the user profile from registry mapping under ProfileList, then shows desktop items from those folders. If profile mapping is wrong or a temporary profile is loaded, users may not see expected icons. This matters because users lose quick access to legal workflow tools and support volume rises quickly.

## Symptom
Engineer observes:
- Multiple Floor 6 users report missing desktop icons in the same morning window.
- Devices may still contain icon files, but users do not see them on desktop.

User reports:
- My desktop icons are gone.
- I can log in, but my normal desktop is missing.

## Root Cause
Specific technical cause:
- User profile load and mapping issue at sign-in, commonly tied to ProfileList SID mapping anomalies including SID.bak conditions.

Evidence that confirms it:
- User Profile Service events in Application log during incident window.
- ProfileList mapping values do not align with expected user profile path.
- Affected vs unaffected comparison shows profile path mismatch and icon visibility mismatch only on affected device.

## Detection
Run this 3-minute confirm path before any fix action.

1. Open Event Viewer from `Start > Run > eventvwr.msc` and go to `Windows Logs > Application`.
- Filter path: `Action > Filter Current Log...`
- Filter values: `Event sources = User Profile Service`, `Logged = Last 1 hour`, `Event IDs = 1511,1515,1508,1509,1500`
- Fields to read in each matching event: `Date and Time`, `Event ID`, `Level`, `General message`
- Match condition: One or more of these Event IDs for the affected user/device in incident window.

2. Open Event Viewer location `Windows Logs > Security`.
- Filter path: `Action > Filter Current Log...`
- Filter values: `Event IDs = 4624,4634`, `Logged = Last 1 hour`
- Fields to read: `Account Name`, `Logon Type`, `TimeCreated`
- Match condition: Normal sign-in/sign-out sequence exists for affected user, proving desktop issue occurs after sign-in.

3. Open Registry Editor from `Start > Run > regedit` and go to `Computer\HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList`.
- Fields to read in SID key for affected user: `ProfileImagePath`, `RefCount`, `State`, SID key name
- Match condition: SID `.bak` exists, or `ProfileImagePath` is unexpected, or `RefCount/State` indicates abnormal profile state.

4. Open file paths in File Explorer:
- `C:\Users\<username>\Desktop`
- `C:\Users\Public\Desktop`
- Fields to read: file count and required icon names from known-good list
- Match condition: Required files exist in folder but not visible on desktop, or required files missing from expected path.

5. Run affected vs unaffected comparison (same floor, same time window).
- Compare exact fields:
  - Application log Event IDs 1511,1515,1508,1509,1500 presence
  - `ProfileImagePath`, `.bak`, `RefCount`, `State` in ProfileList
  - Required icon presence in user/public desktop folders
- Confirm this incident type only if affected device matches steps 1, 3, and 4 while unaffected device does not.

Decision rule:
- Confirm profile-mapping desktop-icon incident when match conditions in steps 1, 3, and 5 are true.
- If step 3 is false and step 4 shows files missing in both locations, branch to packaging/deployment path instead of profile mapping.

## Resolution
Target execution time: 5-10 minutes for one affected device.

1. Azure path: Intune admin center > Devices > Windows > Windows devices > open affected device.
- Action: Confirm `Primary user`, `Device name`, and `Last check-in` match incident target.
- Expected result: Correct device is selected and online.

2. Azure path: Intune admin center > Devices > Windows > Windows devices > affected device > Device actions.
- Action: Click `Sync`.
- Expected result: Sync request accepted.

3. Azure path: Intune admin center > Devices > Windows > Windows devices > affected device > Device diagnostics.
- Action: Click `Collect diagnostics`.
- Expected result: Pre-change diagnostics job created.

4. Local console path: Start > Run > `regedit` > `Computer\HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList`.
- Action: Click `File > Export` and save `C:\Temp\ProfileList_Backup.reg`.
- Expected result: Registry backup exists for rollback.

5. Local registry path: `...\ProfileList`.
- Action: Open SID keys and locate affected user by `ProfileImagePath`.
- Expected result: Affected user's SID mapping key identified.

6. Local registry path: affected SID key and matching `.bak` key if present.
- Action: If `.bak` exists, rename non-bak SID to `.old`, then rename `.bak` key to base SID.
- Expected result: Correct SID mapping is active.

7. Local registry path: active SID key.
- Action: Set `RefCount` DWORD to `0` and `State` DWORD to `0`.
- Expected result: Profile state values normalized.

8. Local file path: `C:\Users\<username>\Desktop` and `C:\Users\Public\Desktop`.
- Action: Restore required icon files from known-good source to missing location.
- Expected result: Required icons exist in expected folder(s).

9. Azure path: Intune admin center > Devices > Windows > Windows devices > affected device > Device actions.
- Action: Click `Restart`; after reboot, ask user to sign in.
- Expected result: User reaches desktop with expected icons visible.

10. Comparison check: open unaffected baseline device record in Intune.
- Action: Compare profile behavior and icon presence between affected and unaffected device.
- Expected result: No material difference after remediation.

## Verification
1. Local log path: Event Viewer > Windows Logs > Application.
- Action: `Filter Current Log...` with `Event source = User Profile Service`, `Logged = Last 1 hour`, `Event IDs = 1511,1515,1508,1509,1500`.
- Pass criteria: No new Error-level matches after remediation timestamp.

2. Local log path: Event Viewer > Windows Logs > Security.
- Action: `Filter Current Log...` with `Event IDs = 4624,4634` and filter by affected user account.
- Pass criteria: Normal sign-in/sign-out cycle exists after reboot.

3. Local registry path: `HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList`.
- Action: Re-check `ProfileImagePath`, SID key names, `RefCount`, and `State`.
- Pass criteria: No active `.bak` for affected mapping and expected profile path is set.

4. Local file paths: `C:\Users\<username>\Desktop` and `C:\Users\Public\Desktop`.
- Action: Verify required icon file names and then refresh desktop.
- Pass criteria: Required icons are both present on disk and visible on desktop.

5. Comparison check: affected device vs unaffected baseline device.
- Action: Compare Event ID presence, profile mapping values, and icon visibility.
- Pass criteria: Affected device now matches baseline behavior.

## Rollback
Use immediately if user cannot sign in, icons worsen, or profile behavior degrades.

Target rollback time: under 3 minutes.

1. Local console path: Start > Run > `regedit` > File > Import > select `C:\Temp\ProfileList_Backup.reg`.
- Expected result: Original ProfileList mapping is restored immediately.

2. Azure path: Intune admin center > Devices > Windows > Windows devices > affected device > Device actions.
- Action: Click `Restart`.
- Expected result: Device reboots with pre-change registry mapping.

3. Local file paths: `C:\Temp\ShortcutBackup\<username>\UserDesktop` and `C:\Temp\ShortcutBackup\<username>\PublicDesktop`.
- Action: Copy files back to `C:\Users\<username>\Desktop` and `C:\Users\Public\Desktop`.
- Expected result: Pre-change icon set restored.

4. Local log path: Event Viewer > Windows Logs > Application.
- Action: Filter `User Profile Service` with `Logged = Last 15 minutes`.
- Expected result: Post-rollback profile state captured for escalation.

5. Azure path: Intune admin center > Devices > Windows > Windows devices.
- Action: Stop remediation on remaining affected devices and escalate to DWP lead.
- Expected result: Blast radius contained and next action controlled.

## Preventive
1. Intune proactive remediation for profile anomalies.
- Owner: DWP engineer; Timing: during deployment; Mode: automated [REQUIRES: Intune Proactive Remediations].
- Pass/Fail signal: pass if SID.bak count = 0, ProfileImagePath mismatch count = 0, and required icon list missing count = 0 in scheduled run; fail if any count > 0.
- If fail: auto-create P2 ticket and assign affected device list to service desk lead within 15 minutes.

2. Release gate for desktop icon integrity (pre-deployment smoke gate).
- Owner: change manager; Timing: before deployment; Mode: manual now, automate with CAB form validation [REQUIRES: ITSM change template rule].
- Pass/Fail signal: pass only if canary pair (1 affected-like + 1 baseline) shows profile path = expected and required icon list = 100 percent present; fail if either check fails.
- If fail: block rollout approval and return change to release engineer with failed evidence.

3. In-flight dashboard alert during rollout window.
- Owner: release engineer; Timing: during deployment; Mode: automated [REQUIRES: central log query/alerting].
- Pass/Fail signal: fail when User Profile Service Event IDs 1511,1515,1508,1509,1500 appear on 3 or more Floor 6 devices in 30 minutes.
- If fail: freeze current ring and open incident bridge; no next-ring promotion until alert clears.

4. Standard shortcut restore package with guardrails.
- Owner: service desk lead; Timing: during deployment and after deployment; Mode: automated package with manual launch [REQUIRES: signed Intune package].
- Pass/Fail signal: pass if package run returns success code and required icon file count matches baseline on target device; fail if return code nonzero or count mismatch.
- If fail: stop package re-runs and escalate to DWP engineer for profile mapping remediation.

5. Closure checklist with measurable evidence.
- Owner: service desk lead; Timing: after deployment; Mode: manual now, automate with mandatory fields [REQUIRES: ITSM closure workflow update].
- Pass/Fail signal: pass only if ticket includes affected-vs-unaffected comparison, before/after ProfileList screenshot, before/after icon count, and post-fix Event ID summary.
- If fail: incident cannot be closed and is reassigned to DWP engineer.

6. Post-deployment health validation gate.
- Owner: release engineer; Timing: after deployment; Mode: automated metric check [REQUIRES: rollout health dashboard].
- Pass/Fail signal: pass if new Event IDs 1511,1515,1508,1509,1500 remain at 0 for 60 minutes and recurrence tickets = 0; fail otherwise.
- If fail: keep change open and trigger controlled remediation plan.

7. Rollback trigger threshold control.
- Owner: change manager; Timing: during deployment; Mode: manual trigger now, automatable threshold rule [REQUIRES: automated threshold policy].
- Pass/Fail signal: fail threshold met if impacted users >= 5, or affected devices >= 3 in 30 minutes, or any user cannot sign in after fix.
- If fail: execute rollback runbook immediately and notify service desk lead plus DWP engineer.

8. Knowledge update control from incident learnings.
- Owner: service desk lead; Timing: after deployment and after incident closure; Mode: manual now, automate via closure task [REQUIRES: mandatory KB task in ITSM].
- Pass/Fail signal: pass only if runbook, L1 article, and L2/L3 KB are version-updated and linked to incident within 2 business days.
- If fail: block final problem record closure and escalate to change manager.

## Related
- FinalProject/runbook_floor6_missing_shortcuts_20260814.md
- FinalProject/rca_floor6_missing_shortcuts_20260814.md
- FinalProject/floor6_missing_shortcuts_detailed_analysis_20260814.md
- FinalProject/floor6_missing_shortcuts_scope_only_hypothesis_20260814.md
- FinalProject/incident_triage_floor6_missing_desktop_shortcuts.md