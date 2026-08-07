# Application Crash Analysis — OUTLOOK.EXE / KERNELBASE.dll

**Date:** 2026-08-06
**Analyst:** DWP Analyst
**Crash Date in Logs:** 2024-03-15

---

## Distinct Error Codes Identified

| # | Code / ID | Source | Meaning |
|---|-----------|--------|---------|
| 1 | **0xc0000005** | Event ID 1000 (Application Error) | `STATUS_ACCESS_VIOLATION` — process attempted to read/write a memory address it has no rights to |
| 2 | **System.AccessViolationException** | Event ID 1026 (.NET Runtime) | Managed (.NET) representation of the same 0xc0000005 condition |
| 3 | **Event ID 1001** (APPCRASH, Fault Bucket 1847362910) | Windows Error Reporting | WER telemetry record for the crash — not an independent root-cause code, confirms same crash session |

> **Note:** Event IDs 1000 / 1001 / 1026 are Windows logging event identifiers, not application error codes. The true error codes are the two above.

**Key observation:** Both Event ID 1000 entries show identical fault offset `0x000000000003a4b2` in `KERNELBASE.dll`. A consistent, repeating offset strongly indicates a deterministic code path failure (e.g., a bad pointer passed to a Win32 API), rather than random heap corruption.

---

## Source Log Details

- **Faulting application:** OUTLOOK.EXE, version 16.0.17126.20132
- **Faulting module:** KERNELBASE.dll, version 10.0.22621.3155
- **Fault offset:** 0x000000000003a4b2 (consistent across both crashes)
- **Faulting process path:** C:\Program Files\Microsoft Office\root\Office16\OUTLOOK.EXE
- **Report ID:** a3c2f1d4-89bb-4e21-91d7-f2c3a1b09e44
- **Framework:** .NET v4.0.30319

---

## Ranked Remediation Plan

---

### Fix 1 — Disable/audit COM and VSTO add-ins (highest probability)

Third-party add-ins injecting code into Outlook's process space are the most common cause of access violations at a fixed offset in KERNELBASE.dll.

**Check:**
1. Start Outlook in Safe Mode: `Win + R` → `outlook.exe /safe`
2. If crash does not reproduce → the fault is add-in related
3. Go to **File → Options → Add-ins → COM Add-ins → Go**
4. Disable all, re-enable one at a time to isolate the offender
5. Specifically check: AV/DLP agents (Symantec, McAfee, Defender for Endpoint), PDF plugins, Zoom/Teams meeting add-ins

---

### Fix 2 — Apply all pending Windows and Office updates

`KERNELBASE.dll` version `10.0.22621.3155` (Windows 11 22H2) and Office build `16.0.17126.20132` may carry known defects.

**Check:**
- `Settings → Windows Update` — apply all cumulative updates
- Office: **File → Office Account → Update Options → Update Now**
- > **Verify against Microsoft:** Check the [Windows 11 22H2 update history](https://support.microsoft.com/en-us/topic/windows-11-version-22h2-update-history) for known KERNELBASE.dll access violation fixes at this build level. `[VERIFY AGAINST MICROSOFT DOCS]`

---

### Fix 3 — Repair the Office installation

A corrupted Outlook binary or dependency can produce repeatable access violations.

**Check:**
1. `Control Panel → Programs → Microsoft 365 / Office → Change`
2. Select **Quick Repair** first; if crash persists, run **Online Repair**
3. Alternatively via admin prompt:
   ```
   "C:\Program Files\Common Files\Microsoft Shared\ClickToRun\OfficeC2RClient.exe" /repair
   ```

---

### Fix 4 — Rebuild the Outlook profile and repair data files

A corrupted OST or Outlook profile can cause invalid memory references during mail store access.

**Check:**
1. Run `SCANPST.EXE` against the OST:
   - Path: `C:\Program Files\Microsoft Office\root\Office16\SCANPST.EXE`
   - OST location typically: `%LOCALAPPDATA%\Microsoft\Outlook\`
2. If scan finds errors, repair and relaunch
3. If unresolved: `Control Panel → Mail → Show Profiles → Add` — create a new profile and test

---

### Fix 5 — Check for security software hooking Outlook's process

Endpoint security agents (EDR/DLP/AV) that hook into `KERNELBASE.dll` API calls can cause access violations when their injected code dereferences an invalid pointer.

**Check:**
- Review installed endpoint agents: Defender for Endpoint, CrowdStrike, Carbon Black, Forcepoint DLP
- Check whether crash correlates with a recent agent update (compare agent version deploy date vs. first crash date: 2024-03-15)
- Temporarily test with the agent in audit/passive mode if policy permits — **requires change approval**
- > **Verify against Microsoft:** Cross-reference with Microsoft's known compatibility list for Outlook and endpoint security products. `[VERIFY AGAINST MICROSOFT DOCS]`

---

### Fix 6 — Verify DEP and heap corruption protection settings

If Data Execution Prevention or EMET/Process Mitigation policies are misconfigured, they can generate 0xc0000005 from legitimate code paths.

**Check:**
```powershell
Get-ProcessMitigation -Name OUTLOOK.EXE
```
- Look for `Enable` on `DEP`, `ASLR`, `HeapTerminate` settings
- > **Verify against Microsoft:** Outlook-specific recommended process mitigation settings are documented in the Microsoft 365 security baseline. `[VERIFY AGAINST MICROSOFT DOCS]`

---

## Summary

| Priority | Fix | Confidence |
|----------|-----|------------|
| 1 | Disable add-ins / Safe Mode test | High |
| 2 | Windows + Office updates | High |
| 3 | Office repair | Medium |
| 4 | Profile rebuild / SCANPST | Medium |
| 5 | Endpoint agent conflict | Medium — depends on environment |
| 6 | DEP/mitigation policy | Low — but worth ruling out |

The consistent fault offset across both crash instances makes Fix 1 (add-in isolation) the strongest candidate. Start there before rebuilding profiles or escalating to Microsoft support.
