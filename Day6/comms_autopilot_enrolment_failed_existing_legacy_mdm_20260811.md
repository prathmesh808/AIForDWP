# End-User Communications: Autopilot Enrolment Failure — Existing Legacy MDM Enrolment
**Incident reference:** DESKTOP-FB099 / FINBRIDGE\rthomas
**Date:** 2026-08-11

---

## Audience 1 — Non-Technical Executive

Your access and data are safe and have not been affected.

A device assigned to your organisation needed to be re-enrolled into our management system before it could be fully set up. An old record from a previous setup was still on file and briefly prevented the new setup from completing. This has been identified and is being resolved by the support team. No action is required from you.

---

## Audience 2 — Affected End-User Team

Hi team,

Your access and data are safe — nothing has been lost or compromised.

One of our devices (DESKTOP-FB099) could not finish setting itself up because an old management record from a previous configuration was still registered against it, blocking the new setup from completing. The support team is actively resolving this.

If your own device shows a setup or sign-in failure during startup, please do not restart it repeatedly — raise a ticket with the service desk straight away so we can investigate quickly.

**Contact:** IT Service Desk

---

## Audience 3 — Engineer-to-Engineer Internal Note

**Device:** DESKTOP-FB099
**User:** FINBRIDGE\rthomas
**Date:** 2026-08-11

### Root Cause
Stale legacy manual MDM enrolment record (enrolled 2023-11-04) still bound to the device context in Intune. Conflicted with incoming Autopilot enrolment flow, producing:
- Primary error: `0x80180014` — device already enrolled in MDM
- Policy error: `0x80070005` — Access denied
- Result: 0/4 Autopilot profiles applied; Azure AD join was present; licensing (Intune P1 + Autopilot) confirmed OK; network endpoints reachable, no proxy in path.

### Action Taken (correct order of operations)
1. **Identifiers captured** — Device name, serial number, Intune device ID, Azure AD device ID, and primary user recorded from Intune > Devices > All devices before any changes.
2. **Autopilot hardware hash confirmed** — Serial verified present in Intune > Devices > Windows > Windows enrollment > Devices; profile assignment (FinBridge-Autopilot-Standard) confirmed intact before cleanup.
3. **Stale Intune managed device object retired and deleted** — Intune > Devices > All devices > DESKTOP-FB099 > Retire, then deleted remaining object. Removes MDM management relationship blocking new enrolment.
4. **Stale Entra device object removed** — Entra admin center > Identity > Devices > All devices; located old object by device name/ID and deleted. Hardware hash record in Autopilot was **not** touched.
5. **Legacy work account disconnected on endpoint** — Settings > Accounts > Access work or school > Disconnect on legacy organisational/MDM entry. Clears local enrolment linkage that would immediately re-trigger `0x80180014`.
6. **Local MDM artefacts cleaned (if disconnect insufficient)** — `dsregcmd /status` used to verify state; stale scheduled tasks, enrolment registry branches, and old MDM certificates removed per approved internal runbook under change control.
7. **Device rebooted and Autopilot OOBE restarted** — User completed sign-in and Enrolment Status Page (ESP) flow.

### Verification Steps
- Intune > Devices > All devices: device present with current enrolment timestamp; MDM authority = Microsoft Intune; compliance evaluation started.
- OOBE/ESP completed without recurrence of `0x80180014`.
- Intune: FinBridge-Win11-Security-Baseline reports as applied; profiles applied moved from 0/4 to expected applied count.
- Optional: MDM diagnostic report and device event logs reviewed — no Access Denied on target profile; policy sync clean.

### Config Detail
- Autopilot profile: **FinBridge-Autopilot-Standard**
- Target compliance baseline: **FinBridge-Win11-Security-Baseline**
- Legacy enrolment date on stale record: **2023-11-04**

### Preventive Action Required
Implement a mandatory pre-Autopilot readiness gate before any device is assigned or reused for Autopilot:
- Check Intune for an existing managed device record against the same serial/hardware.
- Check Entra for a stale device object from prior manual/legacy enrolment.
- Retire and delete any stale records **before** Autopilot profile assignment.

Operational controls to add:
1. **Service desk checklist step:** "Legacy MDM conflict check completed (Intune + Entra)" — mandatory before every Autopilot reset or redeployment.
2. **Periodic bulk report:** run a report of devices carrying legacy manual enrolment markers and remediate in bulk ahead of reuse cycles.
