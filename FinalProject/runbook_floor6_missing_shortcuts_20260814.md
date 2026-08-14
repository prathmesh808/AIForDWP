# Runbook: Floor 6 Missing Desktop Shortcuts

## Version Header
- Title: Floor 6 Missing Desktop Shortcuts Runbook
- Version: 1.0
- Date: 14/08/2026
- Author: prathameshgavade
- Reviewed: self
- Status: draft
- Change: initial version from RCA

## Purpose
Restore missing desktop shortcuts for Floor 6 users when the likely cause is profile load or profile mapping issues.

## Scope
- Incident pattern: Floor 6 users report missing desktop shortcuts.
- Source RCA: rca_floor6_missing_shortcuts_20260814.md.

## 1) Prerequisites

Use this checklist before starting. Do not begin Procedure until all mandatory items are checked.

### 1.1 Access checklist
- [ ] [ELEVATED] You can sign in to the affected endpoint with a local admin or support admin account.
- [ ] [ELEVATED] You can open Registry Editor and edit `HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList`.
- [ ] [ELEVATED] You can run elevated Command Prompt and elevated PowerShell.
- [ ] You can access and update the active incident ticket in ITSM.

### 1.2 Tools checklist
- [ ] Remote support tool or physical access to the affected endpoint.
- [ ] Command Prompt (`cmd.exe`) and PowerShell (`powershell.exe`).
- [ ] Registry Editor (`regedit.exe`).
- [ ] Event Viewer (`eventvwr.msc`).
- [ ] File Explorer (`explorer.exe`).
- [ ] Text editor for evidence notes.

### 1.3 Mandatory end-user information checklist
- [ ] Affected user UPN and SAM account name.
- [ ] Affected device hostname.
- [ ] Exact time issue started for that user (local time zone).
- [ ] Screenshot or exact wording of what user sees on desktop.
- [ ] Confirmation whether user has already restarted device.

### 1.4 Mandatory comparison and recovery information checklist
- [ ] One unaffected user/device pair from same floor for baseline comparison.
- [ ] Known-good Legal shortcut list or source path for standard shortcuts.
- [ ] Backup destination path confirmed: `C:\Temp\ShortcutBackup\<username>\`.
- [ ] Rollback approver/owner is available during registry edits.

## 2) Procedure

1. Open the incident ticket in ITSM and record affected username, UPN, and hostname.
Expected result: Ticket has the exact target user/device details.

2. On affected endpoint, open Command Prompt as administrator from `Start > type cmd > Run as administrator`. [ELEVATED]
Expected result: Elevated console opens with administrator context.

3. Run `whoami` in elevated Command Prompt.
Expected result: Console returns the support admin account identity.

4. Run `echo %USERPROFILE%` in the affected user session console.
Expected result: Active profile path used by current session is displayed.

5. Open Registry Editor from `Start > Run > regedit` and navigate to `Computer\HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList`. [ELEVATED]
Expected result: Profile SID list is visible.

6. In Registry Editor, select `ProfileList` and use `File > Export` to save `C:\Temp\ProfileList_Backup.reg`. [ELEVATED]
Expected result: Registry backup file is created for rollback.

7. In `ProfileList`, open each SID key and inspect `ProfileImagePath` value to locate affected user mapping.
Expected result: SID-to-user profile mapping is identified.

8. In `ProfileList`, verify whether the same SID exists with `.bak` suffix.
Expected result: `.bak` mapping anomaly is confirmed or ruled out.

9. Open File Explorer path `C:\Users\Public\Desktop`.
Expected result: Public desktop shortcut files are visible.

10. Create backup folder `C:\Temp\ShortcutBackup\<username>\PublicDesktop`.
Expected result: Public desktop backup destination exists.

11. Copy all items from `C:\Users\Public\Desktop` to `C:\Temp\ShortcutBackup\<username>\PublicDesktop`.
Expected result: Public desktop shortcuts are backed up.

12. Open File Explorer path `C:\Users\<username>\Desktop`.
Expected result: User desktop shortcut files are visible.

13. Create backup folder `C:\Temp\ShortcutBackup\<username>\UserDesktop`.
Expected result: User desktop backup destination exists.

14. Copy all items from `C:\Users\<username>\Desktop` to `C:\Temp\ShortcutBackup\<username>\UserDesktop`.
Expected result: User desktop shortcuts are backed up.

15. Open Event Viewer from `Start > Run > eventvwr.msc`.
Expected result: Event Viewer console opens.

16. Navigate to log location `Event Viewer > Windows Logs > Application`.
Expected result: Application log list is visible.

17. In Application log, select `Filter Current Log...` and set Event sources to `User Profile Service`.
Expected result: Profile-related events are filtered for faster review.

18. In filtered Application log, review events around incident start time and record Event ID and message text.
Expected result: Profile-load evidence is captured in ticket notes.

19. Sign out affected user from `Start > user icon > Sign out`.
Expected result: User session fully ends.

20. Restart endpoint from `Start > Power > Restart`.
Expected result: Endpoint returns to sign-in screen.

21. If `.bak` anomaly exists, in Registry Editor rename the non-`.bak` SID key to `<SID>.old`. [ELEVATED]
Expected result: Conflicting key is preserved but removed from active mapping.

22. If `.bak` anomaly exists, rename `<SID>.bak` to `<SID>`. [ELEVATED]
Expected result: Correct SID mapping becomes active.

23. If `.bak` anomaly exists, set `RefCount` DWORD value to `0` in the active SID key. [ELEVATED]
Expected result: RefCount is reset to normal.

24. If `.bak` anomaly exists, set `State` DWORD value to `0` in the active SID key. [ELEVATED]
Expected result: State is reset to normal.

25. Restart endpoint from `Start > Power > Restart`.
Expected result: Profile mapping repair is loaded.

26. Ask affected user to sign in and run `echo %USERPROFILE%` in Command Prompt.
Expected result: User signs in and expected profile path is returned.

27. Open `C:\Users\<username>\Desktop` and verify required shortcuts exist.
Expected result: Required shortcut files are present.

28. If required shortcuts are missing, copy approved known-good shortcuts into `C:\Users\<username>\Desktop`.
Expected result: Missing shortcuts are restored.

29. Right-click desktop and click `Refresh`.
Expected result: Restored shortcuts appear on screen.

30. Repeat steps 2 through 29 for each additional affected device.
Expected result: All affected users receive consistent remediation.

31. Update ITSM ticket with profile path before/after, registry findings, event log IDs/messages, and restoration actions.
Expected result: Auditable technical timeline is complete.

## 3) Verification

1. On remediated endpoint, open Command Prompt from `Start > type cmd > Enter` and run `echo %USERPROFILE%`.
Pass criteria: Output matches expected user profile path (for example `C:\Users\<username>`), not a temporary profile path.

2. Open File Explorer and browse to `C:\Users\<username>\Desktop`.
Pass criteria: Required Legal shortcut files are present in this folder.

3. In File Explorer, browse to `C:\Users\Public\Desktop`.
Pass criteria: Shared shortcuts expected for all users are present.

4. On user desktop, right-click empty area and click `Refresh`.
Pass criteria: All restored shortcuts are visible on screen after refresh.

5. Open Event Viewer from `Start > Run > eventvwr.msc` and navigate to `Event Viewer > Windows Logs > Application`.
Pass criteria: Application log is open at correct location.

6. In Application log, click `Filter Current Log...`, set `Event sources` to `User Profile Service`, set `Logged` to `Last 1 hour`, then click `OK`.
Pass criteria: Filtered list shows only recent User Profile Service events.

7. Review filtered events after remediation timestamp and record Event ID and Level.
Pass criteria: No new Error level User Profile Service events after fix time.

8. On unaffected comparison endpoint, run `echo %USERPROFILE%` and verify desktop shortcut visibility.
Pass criteria: Remediated endpoint now matches unaffected baseline for profile path and shortcut visibility.

9. In ITSM queue, apply filter `Location = Floor 6` and `Category = Desktop Shortcuts` for `Last 60 minutes`.
Pass criteria: No new high-priority recurrence ticket appears after remediation.

## 4) Rollback

Use immediately if shortcut loss worsens, profile issues spread, or user cannot sign in after registry edit.

Target rollback execution time: under 3 minutes.

1. Sign in to affected endpoint using support admin account from `Ctrl+Alt+Del > Switch user`. [ELEVATED]
Expected result: You have admin session on the affected device.

2. Open Registry Editor from `Start > Run > regedit`, then click `File > Import` and select `C:\Temp\ProfileList_Backup.reg`. [ELEVATED]
Expected result: Original `ProfileList` registry state is restored.

3. Restart immediately from `Start > Power > Restart`.
Expected result: Endpoint reloads with pre-change profile mapping.

4. After restart, open File Explorer and copy backup contents from `C:\Temp\ShortcutBackup\<username>\UserDesktop` to `C:\Users\<username>\Desktop`.
Expected result: User desktop shortcuts are restored to pre-change state.

5. In File Explorer, copy backup contents from `C:\Temp\ShortcutBackup\<username>\PublicDesktop` to `C:\Users\Public\Desktop`.
Expected result: Public desktop shortcuts are restored to pre-change state.

6. Open Event Viewer from `Start > Run > eventvwr.msc` and navigate to `Event Viewer > Windows Logs > Application`; filter `Event source = User Profile Service` and `Logged = Last 15 minutes`.
Expected result: Immediate post-rollback profile event state is visible for triage.

7. Ask user to sign in and run `echo %USERPROFILE%` in Command Prompt.
Expected result: User returns to pre-remediation profile behavior and desktop state.

8. Update ITSM timeline with rollback start time, rollback end time, imported backup file name, and observed log state; escalate to DWP lead.
Expected result: Rollback is fully auditable and handed off.

## 5) Notes

- If `.bak` is not present, do not force SID key renames; proceed with profile path and permission validation.
- If profile path is correct but shortcuts are still missing, check desktop redirection path reachability next.
- If shortcut files exist but are not visible, use desktop Refresh and explorer restart before deeper remediation.
- If multiple users fail after the same restart cycle, pause further registry edits and escalate for wider profile service investigation.
- Related files:
  - rca_floor6_missing_shortcuts_20260814.md
  - floor6_missing_shortcuts_detailed_analysis_20260814.md
  - floor6_missing_shortcuts_scope_only_hypothesis_20260814.md
  - incident_triage_floor6_missing_desktop_shortcuts.md