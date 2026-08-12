# Incident Hypothesis - Intune Adobe Acrobat Pro v23.6 Deployment Failure

Date: 2026-08-12  
Role: DWP Engineer  
Method: Scope-facts-only hypothesis ranking (no final root-cause commitment)

## Scope Facts
- Symptom: Adobe Acrobat Pro v23.6 failed using Intune (analysis requested)
- Impact: Single machine
- Since: ~10:00 this morning
- Recent change: Application deployed
- Timing clue: Intune app install result = Failed

## Ranked Most Likely Causes (Most Probable First)

### 1) Install command or installer switch mismatch
Why this fits scope facts:
- A hard Intune Failed result right after deployment is most commonly caused by command-line/silent switch issues.
- Single-device impact can occur when endpoint state (paths, preinstalled components, quoting behavior) differs.

Single fastest check:
- Review Intune Management Extension app install log for this app at the failure timestamp and capture exact installer command + exit code.

### 2) Detection rule mismatch (false failed state)
Why this fits scope facts:
- Win32 detection misconfiguration is a frequent reason Intune reports Failed even when install activity occurred.
- One machine can fail detection if install path/version differs from expected rule.

Single fastest check:
- Run the exact configured detection rule manually on the affected device and verify true/false outcome.

### 3) Client content download/extraction failure
Why this fits scope facts:
- Immediate failed enforcement after deployment can be caused by local content retrieval, hash, or extraction issues.
- Single-machine scope strongly supports a local cache/network condition.

Single fastest check:
- Check IME logs for download/hash/decompression errors for this package around ~10:00.

### 4) Requirement rule not met at runtime
Why this fits scope facts:
- If requirement thresholds are marginal (OS build, architecture, free disk, prerequisites), one device can fail while others pass.
- The failure timing aligns with enforcement start after deployment.

Single fastest check:
- Compare configured requirement rules against live device values in one pass (OS/build/arch/free space/prereq state).

### 5) Local install conflict or security control block
Why this fits scope facts:
- Single-device failures are often caused by existing Adobe remnants, pending reboot, AV/AppLocker/CFA restrictions.
- These commonly surface as installer failure immediately after policy enforcement.

Single fastest check:
- Check installer exit code and Event Logs for access denied/block/pending reboot indicators at the same timestamp.

## Weighting Rationale (Timing-Clue Driven)
- Highest weight: causes that directly produce explicit Intune install Failed states (installer command, detection logic, content handling).
- Medium weight: requirement evaluation mismatches.
- Lower but plausible: endpoint-specific software/security conflicts.

## Position Statement
- This is a ranked hypothesis set only.
- No single root cause is committed at this stage.

## Appended Update - Incident Event Details (Evidence Window)
- 2024-03-15 10:01:00 AgentExecutor: Starting app install: Adobe Acrobat Pro v23.6
- 2024-03-15 10:01:01 AppInstaller: Install context: SYSTEM
- 2024-03-15 10:01:02 AppInstaller: Package: AdobeAcrobatPro.intunewin
- 2024-03-15 10:01:03 AppInstaller: Install command: msiexec /i AcrobatPro.msi /quiet
- 2024-03-15 10:01:44 AppInstaller: Return code: 1603
- 2024-03-15 10:01:44 AppInstaller: Install failed. Return code 1603.
- 2024-03-15 10:01:45 DetectionRule: Running detection: registry check
- 2024-03-15 10:01:45 DetectionRule: Key: HKLM\SOFTWARE\Adobe\Acrobat Reader\23.0
- 2024-03-15 10:01:45 DetectionRule: Value: not found
- 2024-03-15 10:01:46 DetectionRule: Detection result: Not detected
- 2024-03-15 10:01:47 AgentExecutor: App install result: Failed
- 2024-03-15 10:01:47 AgentExecutor: Retry scheduled: 60 minutes
- 2024-03-15 11:01:47 AgentExecutor: Retry attempt 1: Adobe Acrobat Pro v23.6
- 2024-03-15 11:01:48 AppInstaller: Install command: msiexec /i AcrobatPro.msi /quiet
- 2024-03-15 11:02:31 AppInstaller: Return code: 1603
- 2024-03-15 11:02:32 AgentExecutor: Retry 1 failed. Next retry: 60 minutes

## Appended Update - Reviewed Hypotheses Against Evidence

### 1) Install command or installer switch mismatch
Evidence judgement: Support
- Determining evidence:
	- 2024-03-15 10:01:03 AppInstaller install command executed
	- 2024-03-15 10:01:44 AppInstaller return code 1603
	- 2024-03-15 11:02:31 AppInstaller return code 1603 on retry
- Reason:
	- Consistent hard installer failure on initial and retry attempts is compatible with command-line/package execution issues.

### 2) Detection rule mismatch (false failed state)
Evidence judgement: Contradicts
- Determining evidence:
	- 2024-03-15 10:01:44 AppInstaller install already failed with 1603
	- 2024-03-15 10:01:46 Detection result is Not detected after failure
	- 2024-03-15 10:01:47 AgentExecutor marks failed
- Reason:
	- Detection runs after installer failure; not-detected is expected and not the primary cause of failure.

### 3) Client content download/extraction failure
Evidence judgement: Contradicts
- Determining evidence:
	- 2024-03-15 10:01:02 package identified
	- 2024-03-15 10:01:03 install command starts
	- 2024-03-15 10:01:44 failure is explicit installer return code 1603
- Reason:
	- Provided evidence shows installer execution phase failure, not content download/hash/extraction failure.

### 4) Requirement rule not met at runtime
Evidence judgement: Contradicts
- Determining evidence:
	- 2024-03-15 10:01:01 install context SYSTEM
	- 2024-03-15 10:01:03 installer launch occurs
	- 2024-03-15 10:01:44 installer returns 1603
- Reason:
	- Runtime requirements typically block install before execution; here execution occurs and fails within MSI.

### 5) Local install conflict or security control block
Evidence judgement: Support
- Determining evidence:
	- 2024-03-15 10:01:44 installer returns 1603
	- 2024-03-15 10:01:47 retry scheduled
	- 2024-03-15 11:02:31 retry returns 1603 again
- Reason:
	- Repeated failure under same context and command indicates persistent local host condition.

Note:
- Numeric Windows Event IDs were not present in the supplied evidence lines. Timestamps and log component entries were used for determination.

## Appended Update - Surviving Hypothesis and Detailed Resolution Steps

Surviving hypothesis after elimination:
- Local install conflict or security control block on the affected host causing persistent MSI return code 1603.

### Resolution Steps

1) Capture complete failure artifacts
- Re-run installer with verbose logging:
	- msiexec /i "AcrobatPro.msi" /quiet /l*v "C:\Windows\Temp\AcrobatPro_Install.log"
- Collect Intune Management Extension logs for incident window.
- Export Application and System event logs for the same timeframe.

2) Remove common 1603 preconditions
- Check pending reboot indicators:
	- HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending
	- HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\PendingFileRenameOperations
- Confirm write access for SYSTEM to temp/cache locations.
- Verify free disk space on system volume.

3) Resolve Adobe product-state conflicts
- Inventory existing Adobe Reader/Acrobat installations and remnants.
- Remove conflicting legacy builds using supported uninstall methods.
- Reboot if uninstall process requires it.
- Retry installation with same Intune package.

4) Validate and remediate security policy blocks
- Review Defender, AppLocker, WDAC, and Controlled Folder Access events at failure time.
- If blocked, apply temporary targeted allow policy for installer path/hash/publisher.
- Retry install and confirm status change.
- Replace temporary allowance with approved permanent policy after validation.

5) Harden deployment package if issue persists
- Add pre-install cleanup/remediation logic for known Adobe conflicts.
- Add explicit handling notes for 1603 in deployment documentation.
- Keep install context as SYSTEM and verify deterministic source paths.
- Pilot updated package before wider assignment.

6) Validate successful recovery
- Confirm installer return code success.
- Confirm detection key is present post-install.
- Confirm Intune status transitions from Failed to Installed.
- Confirm user can launch Adobe Acrobat Pro in-session.

7) Prevent recurrence
- Gate rollout with preflight checks (reboot, disk, conflict, security readiness).
- Pause wider rollout until pilot success criteria are met.
- Publish a standard 1603 troubleshooting runbook for Adobe Win32 deployments.
