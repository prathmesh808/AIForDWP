# Detailed RCA: Autopilot Enrolment Failure Due to Legacy MDM Conflict

## Document Control
- Incident type: Autopilot enrolment failure
- Device: DESKTOP-FB099
- User: FINBRIDGE\\rthomas
- Incident date (from export): 2024-03-15
- Analysis date: 2026-08-11
- Prepared by: DWP Analyst
- Status: Final RCA

## Executive Summary
Autopilot enrolment failed because the device already had an existing legacy manual MDM enrolment record (dated 2023-11-04). This pre-existing enrolment conflicted with the new Autopilot enrolment attempt and blocked completion. As a direct consequence, policy processing did not complete and the security baseline profile was not applied.

## Scope and Impact
- Scope: Single endpoint in this case (DESKTOP-FB099).
- Functional impact:
  - Autopilot enrollment failed.
  - Policy deployment failed (0 of 4 profiles applied).
  - Compliance evaluation could not be completed.
- Security/operations impact:
  - Required security baseline was not applied.
  - Device remained in incomplete management/compliance state.

## Supporting Evidence

### 1) Enrollment evidence
- EnrollmentType: Autopilot
- EnrollmentState: Failed
- ErrorCode: 0x80180014
- ErrorDescription: The device is already enrolled in MDM.
- Timestamp: 2024-03-15 09:18:44

Why this matters:
- The export directly states enrolment failed due to an already existing MDM enrollment state.

### 2) Existing MDM enrollment evidence
- MDMEnrolled: Yes (previous enrolment)
- EnrolmentSource: Legacy (manual MDM enrolment, 2023-11-04)

Why this matters:
- Confirms a prior management relationship existed before Autopilot attempted to enroll.

### 3) Policy failure evidence
- ProfilesAttempted: 4
- ProfilesApplied: 0
- LastError: 0x80070005 (Access denied)
- FailedProfile: FinBridge-Win11-Security-Baseline
- Timestamp: 2024-03-15 09:19:01

Why this matters:
- Shows downstream failure after enrolment conflict: no profiles were applied.

### 4) Compliance engine evidence
- EvaluationResult: Could not evaluate
- Reason: Enrolment not complete
- Timestamp: 2024-03-15 09:19:45

Why this matters:
- Confirms compliance process failed because enrollment did not complete.

### 5) Environment elimination evidence
- AzureADJoined: Yes
- IntuneP1License: Yes
- AutopilotLicense: Yes
- M365LicenseFound: Yes
- Network endpoint reachability:
  - login.microsoftonline.com: OK
  - enrollment.manage.microsoft.com: OK
  - enterpriseregistration.windows.net: OK
- ProxyDetected: No

Why this matters:
- Supports elimination of AAD join, licensing, and connectivity as primary causes.

## Timeline of Events (From Diagnostic Export)

- 2023-11-04
  - Legacy manual MDM enrolment established on device.

- 2024-03-15 09:18:44
  - Autopilot enrollment attempt recorded.
  - EnrollmentState = Failed.
  - ErrorCode = 0x80180014.
  - ErrorDescription = device already enrolled in MDM.

- 2024-03-15 09:19:01
  - PolicyManager attempted 4 profiles.
  - ProfilesApplied = 0.
  - LastError = 0x80070005 (Access denied).
  - FailedProfile = FinBridge-Win11-Security-Baseline.

- 2024-03-15 09:19:45
  - ComplianceEngine evaluation failed.
  - Reason = Enrolment not complete.

## 5 Whys Analysis

Problem statement:
- Autopilot enrolment failed and required policies were not applied.

Why 1:
- Why did Autopilot enrolment fail?
- Because EnrollmentState is Failed with 0x80180014 and description indicates existing MDM enrollment.

Why 2:
- Why was there an existing MDM enrollment?
- Because the device had a prior legacy manual MDM enrollment from 2023-11-04.

Why 3:
- Why did this legacy enrollment still exist during Autopilot attempt?
- Because stale enrollment objects/artifacts were not fully retired and cleaned before reuse/redeployment.

Why 4:
- Why were stale enrollment artifacts not removed before Autopilot reuse?
- Because pre-Autopilot readiness controls did not enforce a mandatory legacy enrollment conflict check across Intune and Entra objects.

Why 5:
- Why was this control not enforced operationally?
- Because device redeployment process lacked a formal gate/checklist and periodic hygiene reporting for legacy/manual enrollments.

Root cause (confirmed):
- Residual legacy manual MDM enrollment state (tenant/device) conflicted with Autopilot enrollment.

Contributing factors:
- Absence of mandatory pre-redeployment stale-object cleanup control.
- No enforced verification gate for legacy enrollment conflicts before Autopilot execution.

## Remediation Performed / Required Runbook

### A) Tenant-side cleanup (Admin center only)
1. In Intune admin center, locate stale managed device object for DESKTOP-FB099.
2. Retire the stale object and delete it if still present.
3. In Microsoft Entra admin center, delete stale matching device object if present.
4. Verify Windows Autopilot hardware identity remains present and correctly assigned to profile.

### B) Device-side cleanup (Requires device access: physical or remote)
1. Open Settings > Accounts > Access work or school.
2. Disconnect legacy organizational MDM account.
3. If stale state persists, remove residual local enrollment artifacts using approved enterprise runbook.
4. Reboot device and rerun Autopilot OOBE enrollment flow.

## Verification Plan (Post-remediation)

Success criteria:
- Enrollment completes without 0x80180014.
- Device appears with fresh enrollment timestamp in Intune.
- Target policy set applies (greater than 0 profiles; baseline success).
- Compliance evaluation completes successfully.

Checks:
1. Intune admin center device record shows active current management.
2. Enrollment Status Page completes during OOBE.
3. Security baseline policy (FinBridge-Win11-Security-Baseline) reports success.
4. Compliance state transitions to evaluable/compliant (or clear non-compliant reason unrelated to enrollment).

## Preventive Actions

### Preventive Action 1: Pre-Autopilot conflict gate (mandatory)
- Type: Process control
- Owner: EUC/Endpoint operations
- Action:
  - Before any Autopilot redeployment, check for stale Intune managed device and stale Entra device objects.
  - Retire/delete stale records before reset/reassignment.
- Evidence of completion:
  - Ticket checklist item marked and peer-reviewed.

### Preventive Action 2: Legacy enrollment hygiene reporting
- Type: Operational control
- Owner: Intune platform team
- Action:
  - Weekly report of devices with legacy/manual enrollment markers and duplicate enrollment indicators.
  - Remediate flagged records before device reuse.
- Evidence of completion:
  - Weekly report archive and closure actions logged.

### Preventive Action 3: Standardized redeployment SOP update
- Type: Documentation and governance
- Owner: Service management
- Action:
  - Update Autopilot SOP with explicit "legacy enrollment conflict check" steps.
  - Require approval gate before OOBE/reset handoff.
- Evidence of completion:
  - Published SOP version and service desk training completion.

### Preventive Action 4: Post-enrollment quality checkpoint
- Type: Validation control
- Owner: Service desk / Endpoint engineering
- Action:
  - Validate enrollment success + baseline policy application within defined SLA after Autopilot completion.
- Evidence of completion:
  - Ticket closure template includes successful policy and compliance checks.

## Lessons Learned
- A device can be Azure AD joined, licensed, and network healthy yet still fail Autopilot due to stale management state.
- Enrollment conflict controls must be enforced before redeployment, not discovered after failure.
- Policy and compliance failures here were downstream symptoms of incomplete enrollment, not independent primary causes.

## Final Conclusion
The incident was caused by a pre-existing legacy manual MDM enrollment that conflicted with Autopilot enrollment. Cleanup of stale tenant/device enrollment artifacts and a controlled re-enrollment path are required for recovery. Permanent prevention requires a mandatory pre-Autopilot stale-enrollment gate and ongoing hygiene controls.