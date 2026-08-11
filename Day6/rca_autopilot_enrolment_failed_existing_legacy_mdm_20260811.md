# RCA and Remediation Runbook: Autopilot Enrolment Failure (Existing Legacy MDM Enrolment)

## Incident Summary
- Device: DESKTOP-FB099
- User: FINBRIDGE\\rthomas
- Enrollment type: Autopilot
- Enrollment state: Failed
- Primary error: 0x80180014 (device already enrolled in MDM)
- Policy state: 0 of 4 profiles applied
- Policy error: 0x80070005 (Access denied)
- Azure AD joined: Yes
- Licensing: Intune P1 and Autopilot licenses present
- Network: Required endpoints reachable, no proxy

## Confirmed Root Cause
A stale legacy manual MDM enrolment record from 2023-11-04 is still bound to the device context. This conflicts with Autopilot enrolment and prevents completion.

## Remediation Objective
Remove stale enrolment artifacts from tenant and device, then run a clean Autopilot enrolment so policy can apply.

## Correct Order of Operations
1. Capture identifiers and validate scope.
2. Remove stale records in Intune admin center.
3. Remove stale records in Microsoft Entra admin center.
4. Clean device-side legacy enrolment artifacts.
5. Reboot and restart Autopilot OOBE.
6. Verify successful enrolment and policy application.

## Detailed Remediation Steps

### 1) Collect device identifiers before cleanup
- Access type: Admin center only
- In Intune admin center:
  - Go to Devices > All devices.
  - Search for DESKTOP-FB099.
  - Record: Device name, serial number, Intune device ID, Azure AD device ID, primary user.
- In Intune admin center:
  - Go to Devices > Windows > Windows enrollment > Devices (Windows Autopilot devices).
  - Find the Autopilot record by serial number and confirm profile assignment.
- Why: Ensures the correct object is cleaned and the Autopilot hardware identity is preserved.

### 2) Retire and delete stale Intune managed device object
- Access type: Admin center only
- In Intune admin center:
  - Go to Devices > All devices > DESKTOP-FB099.
  - Select Retire (wait for command to process if device is online).
  - After retire is issued, delete the device object from Intune if it remains.
- Why: Removes stale MDM management relationship that blocks new enrolment.

### 3) Remove stale Entra device object (if still present)
- Access type: Admin center only
- In Microsoft Entra admin center:
  - Go to Identity > Devices > All devices.
  - Locate the old/stale device object matching DESKTOP-FB099 or recorded device ID.
  - Delete the stale device object.
- Why: Prevents join/enrolment conflicts with old registration state.
- Note: Do not delete the Windows Autopilot device identity (hardware hash record) from Intune unless it is incorrect/corrupt.

### 4) Confirm Autopilot device identity remains assigned
- Access type: Admin center only
- In Intune admin center:
  - Go to Devices > Windows > Windows enrollment > Devices.
  - Confirm DESKTOP-FB099 serial number is present.
  - Confirm the intended Autopilot profile is assigned (FinBridge-Autopilot-Standard).
- Why: Device must still be known to Autopilot for next OOBE cycle.

### 5) Remove legacy work account / MDM connection on the endpoint
- Access type: Device access required (physical or remote interactive session)
- On the device (Windows):
  - Open Settings > Accounts > Access work or school.
  - Select legacy organizational account/MDM connection and click Disconnect.
  - If shown, remove any old management account entries tied to legacy enrolment.
- Why: Clears local enrollment linkage that can immediately re-trigger 0x80180014.

### 6) Remove stale local MDM enrollment artifacts if disconnect is insufficient
- Access type: Device access required (physical or remote, local admin)
- Run elevated checks and cleanup:
  - Verify state with dsregcmd /status.
  - If stale enrollment persists, remove old MDM enrollment artifacts (scheduled tasks, enrollment registry branches, and old MDM certificates) using approved internal support runbook procedures.
- Why: Some legacy enrollments leave local artifacts that survive basic disconnect.
- Control: Perform only through approved enterprise runbook/change procedure.

### 7) Restart and relaunch Autopilot enrollment
- Access type: Device access required (physical or remote)
- Reboot device.
- Return to OOBE (or reset as required by your process) and start Autopilot sign-in flow.
- Complete user sign-in and enrollment status page.

## Verification After Remediation
Use all checks below to confirm success:

1. Enrollment success state
- Access type: Admin center only
- Intune admin center > Devices > All devices:
  - Device appears with current enrollment timestamp.
  - MDM authority shows Microsoft Intune.
  - Primary user and compliance evaluation begin updating.

2. Autopilot completion
- Access type: Device access required (physical or remote)
- During OOBE/ESP:
  - Device setup and account setup complete without reenrollment error.
  - No recurrence of 0x80180014.

3. Policy application success
- Access type: Admin center only (plus optional device check)
- Intune admin center:
  - Target baseline FinBridge-Win11-Security-Baseline reports as applied.
  - Profiles applied moves from 0/4 to expected applied count.
- Optional device validation:
  - Review MDM diagnostic report and event logs for successful policy sync with no access denied on target profile.

## Preventive Action (for other legacy-enrolled devices)
Implement a pre-Autopilot readiness gate in operations:

- Access type: Admin center only
- Before assigning/reusing any Windows device for Autopilot:
  - Check if an existing Intune managed device record already exists for the same hardware/serial.
  - Check if a stale Entra device object exists from legacy/manual enrollment.
  - Retire/delete stale records before Autopilot assignment.

Recommended operational control:
- Add a mandatory service desk checklist step: Legacy MDM conflict check completed (Intune + Entra) before Autopilot reset/redeployment.
- Run a periodic report of devices with legacy manual enrollment markers and remediate in bulk before reuse.

## Expected Outcome
After stale enrollment cleanup in tenant and endpoint, Autopilot enrollment completes, policy applies, and compliance evaluation resumes normally.