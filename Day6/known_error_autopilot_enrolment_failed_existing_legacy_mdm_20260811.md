# Known Error: Autopilot Enrolment Failure — Existing Legacy MDM Enrolment

**Record date:** 2026-08-11
**Device reference:** DESKTOP-FB099
**User reference:** FINBRIDGE\rthomas

---

**Symptom**
The user is unable to complete Autopilot enrolment during OOBE. Enrolment fails with error 0x80180014 and 0 of 4 Autopilot profiles are applied, leaving the device unmanaged.

**Cause**
A stale legacy manual MDM enrolment record from a previous enrolment (dated 2023-11-04) remains bound to the device context in Intune. This conflicts with the Autopilot enrolment attempt and returns access denied (0x80070005) when policy tries to apply.

**Scope**
Affects any Windows device being redeployed via Autopilot that retains an existing Intune managed device record or stale Entra device object from a prior manual/legacy MDM enrolment. Requires Intune P1 and Autopilot licensing to be present on the tenant.

**Workaround**
On the device, go to Settings > Accounts > Access work or school, disconnect the legacy organisational account/MDM connection, then reboot and restart the Autopilot OOBE sign-in flow. This clears the local enrolment linkage to allow re-enrolment while the tenant-side cleanup is arranged.

**Permanent fix**
Retire and delete the stale Intune managed device object, remove the stale Entra device object, confirm the Autopilot hardware hash record (FinBridge-Autopilot-Standard profile) remains intact, remove any residual local MDM artefacts (scheduled tasks, registry branches, MDM certificates) per the approved internal runbook, then complete a clean Autopilot enrolment. Implement a mandatory pre-Autopilot readiness gate: check for and clear any existing Intune and Entra records before every Autopilot reset or redeployment.

**How to spot it**
Primary enrolment error code is **0x80180014** (device already enrolled in MDM) combined with policy error **0x80070005** (Access denied) with 0 profiles applied out of expected total. Confirm by locating a duplicate Intune managed device object with an old enrolment timestamp (e.g. 2023-11-04) alongside the current Autopilot device identity, and by checking Settings > Accounts > Access work or school on the endpoint for a pre-existing legacy work account entry.
