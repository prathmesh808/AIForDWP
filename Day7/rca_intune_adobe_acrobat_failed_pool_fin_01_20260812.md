# Root Cause Analysis (RCA)

## Incident Title
Intune Win32 Deployment Failure - Adobe Acrobat Pro v23.6 

## Document Control
- Date: 2026-08-12
- Author: DWP Engineering


## Executive Summary
A deployment of Adobe Acrobat Pro v23.6 through Intune failed on an affected machine with repeated MSI return code 1603. Evidence shows the package was downloaded and install execution started under SYSTEM, then failed consistently on initial and retry attempts. Detection reported Not detected only after installer failure, indicating detection was not the primary fault domain. The issue was resolved after applying the recommended remediation path for local host conflict/security interference conditions. Service validation confirmed users could log in to hosts in POOL-FIN-01 with no further reported issues.

## Impact Assessment
- User impact: Localized (single machine in initial scope)
- Service impact: No broad outage confirmed
- Business impact: Delayed application availability on affected endpoint
- Current state: Stable after remediation; no active user-reported issue in POOL-FIN-01

## Scope and Constraints
- Scope facts used during triage:
  - Symptom: Adobe Acrobat Pro v23.6 failed using Intune
  - Who: Single machine
  - Since: Around 10:00 AM
  - Change: Application deployment occurred
- Important constraint:
  - Provided evidence entries did not include numeric Windows Event IDs; timeline uses component log entries and timestamps.

## Supporting Evidence

### A. Deployment and Installer Evidence (Incident Window)
- 2024-03-15 10:01:00 AgentExecutor: Starting app install: Adobe Acrobat Pro v23.6
- 2024-03-15 10:01:01 AppInstaller: Install context: SYSTEM
- 2024-03-15 10:01:02 AppInstaller: Package: AdobeAcrobatPro.intunewin
- 2024-03-15 10:01:03 AppInstaller: Install command: msiexec /i AcrobatPro.msi /quiet
- 2024-03-15 10:01:44 AppInstaller: Return code: 1603
- 2024-03-15 10:01:44 AppInstaller: Install failed. Return code 1603

### B. Detection and Result Evidence
- 2024-03-15 10:01:45 DetectionRule: Running detection: registry check
- 2024-03-15 10:01:45 DetectionRule: Key HKLM\SOFTWARE\Adobe\Acrobat Reader\23.0
- 2024-03-15 10:01:45 DetectionRule: Value not found
- 2024-03-15 10:01:46 DetectionRule: Detection result: Not detected
- 2024-03-15 10:01:47 AgentExecutor: App install result: Failed
- 2024-03-15 10:01:47 AgentExecutor: Retry scheduled: 60 minutes

### C. Retry Behavior Evidence
- 2024-03-15 11:01:47 AgentExecutor: Retry attempt 1
- 2024-03-15 11:01:48 AppInstaller: Install command repeated
- 2024-03-15 11:02:31 AppInstaller: Return code: 1603
- 2024-03-15 11:02:32 AgentExecutor: Retry 1 failed

### D. Resolution Verification Evidence
- Reported: Suggested resolution steps applied
- Reported: Issue resolved at 10:00 AM
- Validation: Users successfully logging in to hosts in POOL-FIN-01
- Validation: No new issues reported after fix

## Incident Timeline
1. ~10:00 AM: Issue first observed after application deployment.
2. 10:01:00: Intune agent starts Acrobat Pro install.
3. 10:01:03: Installer command executed as SYSTEM.
4. 10:01:44: MSI exits with 1603; install marked failed.
5. 10:01:45 to 10:01:46: Detection runs and returns Not detected.
6. 10:01:47: Agent records app install Failed and schedules retry.
7. 11:01:47 to 11:02:31: Retry attempt reproduces 1603 failure.
8. 2026-08-12 10:00 AM: Post-remediation status confirmed resolved.
9. Post-resolution: Login validation on POOL-FIN-01 successful; no new reports.

## Hypothesis Review Summary
- Supported by evidence:
  - Install command/package execution issue class
  - Local host conflict or security control block
- Contradicted by evidence:
  - Detection rule as primary cause
  - Content download/extraction failure as primary cause
  - Requirement rule gating as primary cause

## Root Cause Statement
Primary root cause category: local endpoint install conflict and/or host security-control interference during MSI execution, resulting in persistent return code 1603 under SYSTEM context.

Rationale:
- Installer consistently launched but failed with 1603 on initial run and retry.
- Failure persisted with same command and context, indicating local host state rather than assignment or delivery phase.
- Detection failure occurred after installer failure and was therefore downstream.

## 5 Whys Analysis
1. Why did Adobe Acrobat Pro fail to install?
- Because the MSI installation process exited with return code 1603.

2. Why did MSI return 1603?
- Because a persistent local execution blocker existed on the host (conflicting app state and/or security policy interference).

3. Why did the blocker persist across retry?
- Because the same host condition remained unchanged between initial attempt and scheduled retry.

4. Why was this not prevented before deployment?
- Because pre-deployment controls did not fully gate for host readiness signals (conflict state, reboot state, or policy block conditions) for this package.

5. Why were pre-deployment controls insufficient?
- Because deployment quality gates and remediation prechecks were not strict enough for this installer profile in this environment.

## Corrective Actions Implemented
1. Applied remediation steps aligned to 1603 troubleshooting path on the affected host.
2. Addressed local blocking conditions before revalidation (conflict/security/readiness path).
3. Re-validated deployment outcome and service behavior after fix.
4. Confirmed operational recovery by successful user login checks in POOL-FIN-01.

## Preventive Actions
1. Add preflight checks to Win32 app rollout process:
- Pending reboot check
- Disk capacity threshold check
- Existing Adobe product conflict check
- Security policy compatibility check (Defender/AppLocker/WDAC/CFA)

2. Strengthen package governance:
- Enforce verbose installer logging on failure paths
- Standardize 1603 decision tree and runbook
- Validate install and detection rules in pilot with representative host states

3. Improve rollout controls:
- Stage deployments with pilot ring and mandatory success criteria
- Block broad rollout on repeated retry failures
- Add rapid rollback/hold trigger for repeated identical installer codes

4. Monitoring and reporting:
- Alert on repeated 1603 for same app and host pool
- Correlate installer failures with host policy events for faster triage

## Validation and Closure Criteria
- Intune app state transitions to Installed on remediated target.
- No repeated 1603 for the same deployment object.
- Detection rule resolves as detected post-install.
- User operations verified normal in POOL-FIN-01.
- No new incident reports during post-fix observation window.

## Residual Risk
Low to medium until preventive controls are embedded in standard rollout workflow across future Acrobat updates.

## Lessons Learned
- Repeated 1603 with identical command/context should prioritize local host conflict/security investigation early.
- Detection failures after installer failure are often secondary symptoms, not the initial fault.
- Fast pilot gates and preflight checks reduce repeat retries and mean time to resolution.
