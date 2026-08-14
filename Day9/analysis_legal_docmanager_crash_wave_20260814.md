# Detailed Analysis - Legal-Win11 App Crash Wave

Date: 2026-08-14
Analyst: DWP Engineering
Incident Type: Post-deployment application instability
Scope: Legal (Floor 6), Legal-Win11 collection (45 devices)

## 1. Executive Summary
A crash wave began immediately after deployment of Legal Document Manager v2.1 to Legal-Win11. SCCM shows successful installation on all 45 devices with no deployment failures, while Nexthink shows a sharp degradation in endpoint experience starting at 10:00 with high disk I/O and a crash spike dominated by DocManager.exe.

Most likely explanation is not deployment transport failure, but post-install runtime instability in the new app version under known hardware constraints.

## 2. Source Data Used

### Source A - Nexthink DEX Export
- Device group: Legal-Win11 (45 devices)
- 08:00: DEX 91, crash rate 0.1%, Disk I/O Normal
- 09:00: DEX 90, crash rate 0.2%, Disk I/O Normal
- 10:00: DEX 58, crash rate 6.2%, Disk I/O High
- 11:00: DEX 55, crash rate 6.8%, Disk I/O High
- Top crashing process (10:00-11:00): DocManager.exe (74% of crashes)

### Source B - SCCM Deployment Log
- 09:38:20: Deployment started: Legal Document Manager v2.1 to Legal-Win11 (45 devices)
- 09:44:07: Install completed: 45/45 devices
- 09:44:07: Install result: Success, 0 failures

### Package/Environment Details
- Previous stable version: Document Manager v2.0 (stable for 6 weeks)
- New version: Document Manager v2.1
- Vendor note: v2.1 auto-save indexing may cause high disk I/O and intermittent crashes on devices under 8GB RAM during initial index build
- Fleet RAM profile: 60% at 8GB, 40% at 4GB

## 3. Correlated Timeline
1. 09:38 deployment begins.
2. 09:44 deployment completes successfully on all targets.
3. 10:00 first full telemetry interval post-deployment shows DEX collapse and crash spike.
4. 11:00 instability persists with high disk I/O.

Interpretation: temporal alignment is strong between deployment completion and onset of DocManager-dominated crashes.

## 4. Ranked Hypotheses (Most Likely First)

## Hypothesis 1 (Most Probable)
v2.1 auto-save indexing overload on lower-memory endpoints is driving high disk I/O and DocManager.exe instability.

Why it fits:
- Vendor explicitly documents this behavior for under-8GB devices.
- 40% of fleet is 4GB (materially exposed).
- Crash process concentration (DocManager.exe at 74%) matches app-specific failure.
- Disk I/O moved from Normal to High exactly when crash wave begins.
- SCCM install success rules out broad deployment transport failure.

Fastest confirm/eliminate check:
- Compare crash rate and disk queue metrics split by RAM tier (4GB vs 8GB) for 10:00-11:00.
- Validate DocManager v2.1 process indexing activity and crash events on a 4GB sample.

Specific remediation if confirmed:
- Ring rollback impacted population to v2.0 immediately.
- Disable or defer auto-save indexing policy/feature for low-memory devices before redeploying v2.1.
- Re-release v2.1 in controlled rings with RAM-based targeting.

## Hypothesis 2
General v2.1 application defect unrelated to RAM, amplified by first-run indexing workload.

Why it fits:
- Crash surge tightly follows version change.
- Process-specific failure points to app binary/feature interaction.
- Could affect both 4GB and some 8GB devices if defect is broad.

Fastest confirm/eliminate check:
- Compare crash incidence among 8GB devices that should be less constrained.
- Reproduce on a clean 8GB test VM with v2.1 and monitor first-run behavior.

Specific remediation if confirmed:
- Pause v2.1 deployment tenant-wide.
- Engage vendor with crash dumps and telemetry.
- Maintain production on v2.0 pending hotfix.

## Hypothesis 3
Coincident endpoint storage performance degradation contributed to crashes, independent of application release quality.

Why it fits:
- High disk I/O is directly observed during failure window.
- Severe I/O contention can destabilize user-mode apps.
- Could be amplified by background tasks that started around same time.

Fastest confirm/eliminate check:
- Check whether non-DocManager processes also show elevated crash/freeze rates in same window.
- Review endpoint storage latency trends and background job schedules.

Specific remediation if confirmed:
- Throttle competing disk-intensive tasks.
- Stagger heavy workloads and application first-run indexing windows.
- Apply storage optimization/cleanup and retry controlled rollout.

## 5. Finalized Working Hypothesis
Selected: Hypothesis 1 - v2.1 auto-save indexing behavior on under-8GB endpoints.

Confidence: High based on timing, process concentration, I/O pattern, and explicit vendor limitation note.

## 6. Remediation Plan (Exact Order of Operations)
1. Change freeze: stop any additional v2.1 rollout waves to other collections.
2. Identify impacted set: Legal-Win11 devices with DocManager v2.1 and high crash telemetry, prioritizing 4GB endpoints.
3. Containment: rollback impacted devices to v2.0.
4. Stabilization: confirm crash rate reduction and disk I/O normalization on rolled-back devices.
5. Configuration hardening: define policy to disable/defer v2.1 auto-save indexing on under-8GB devices.
6. Pilot: redeploy v2.1 to a small 8GB-only ring first.
7. Guarded expansion: add mixed RAM ring only if pilot remains stable through observation window.

## 7. Verification Checks After Remediation
- Crash KPI: DocManager.exe crash share and absolute crash rate return near pre-incident baseline.
- Experience KPI: DEX score recovers toward >= 90 baseline range for Legal-Win11.
- Resource KPI: disk I/O returns from High to Normal during business hours.
- Deployment KPI: no new SCCM failures and no new crash wave in post-change window.

## 8. Preventive Action
Implement hardware-aware deployment rings and pre-deployment risk gates:
- Ring criteria must include RAM tier and storage health.
- New releases with known resource-intensive first-run behaviors must pilot on constrained hardware separately.
- Require vendor-known-limitation checks in CAB release checklist before production deployment.

## 9. Important Scope/Assurance Note
No explicit Citrix broker/controller error codes were included in this dataset. Analysis is based strictly on Nexthink DEX and SCCM deployment evidence for the Legal-Win11 application incident.