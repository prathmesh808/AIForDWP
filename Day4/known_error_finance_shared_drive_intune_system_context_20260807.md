# Known-Error Record — Finance Shared Drive Access Failure (SYSTEM Context Script Race Condition)

Date added: 2026-08-07  
Source: RCA — rca_finance_shared_drive_intune_system_context_20260807.md  
Status: Permanent fix applied; record retained for recurrence detection

---

**Symptom:** All users in the affected OU lose their mapped shared drive (S:) at logon and cannot access `\\finbridge-fs01\Finance`. The drive letter is absent in File Explorer and no error is shown to the user — the mapping silently fails during the logon sequence.

**Cause:** The Intune Platform Script `Map-FinBridgeDrives.ps1` executes as the SYSTEM account during early logon before the Workstation service (LanmanWorkstation) has entered running state. The UNC path `\\finbridge-fs01\Finance` cannot be resolved without the SMB client stack, returning Win32 error 53 ("Network name cannot be found"). The script exits with code 1 and no retry is configured, so drive letter S: is never assigned.

**Scope:** All devices in OU=Finance (DESKTOP-FB* — 45 users) managed by Intune with `Map-FinBridgeDrives.ps1` deployed as a Platform Script running as SYSTEM. Non-Finance users, the file server (`finbridge-fs01`), and shared infrastructure are unaffected.

**Workaround:** Instruct the affected user to manually map the drive immediately: open File Explorer → Map network drive → S: → `\\finbridge-fs01\Finance`. Alternatively run `net use S: \\finbridge-fs01\Finance` from a Command Prompt. This restores access for the current session without requiring a device restart or IT intervention on the device.

**Permanent fix:** In Intune admin centre navigate to Devices → Scripts and remediations → Platform scripts → `Map-FinBridgeDrives.ps1` → Properties → Edit, and set "Run this script using the logged on credentials" to **Yes**. Increment the script version to force re-execution on devices with a cached failure state, then push a device sync to all DESKTOP-FB* devices. Users regain automatic drive mapping at next logon after the policy is received.

**How to spot it:** In the Intune Management Extension log on the affected device, look for `ScriptRunner Warning: Network path \\finbridge-fs01\Finance not accessible from SYSTEM context` followed by `ScriptRunner Error: Script Map-FinBridgeDrives.ps1 failed. Exit code: 1. Error: Network name cannot be found.` — both at the same second during logon. In the System Event log, Event ID **98** from source **Ntfs** confirms `drive letter S: has not been assigned`, and Event ID **7036** from **Service Control Manager** shows the Workstation service entering running state *after* the script failure timestamp. The combination of error 53 (not error 5, which would indicate an ACL issue) and the SYSTEM context warning in the IME log is the definitive fingerprint for this pattern.
