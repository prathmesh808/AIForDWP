# Root Cause Analysis (RCA) - Legal-Win11 Document Manager Crash Wave

Date: 2026-08-14
Prepared by: DWP Engineering
Incident Window Analyzed: 2024-03-25 08:00-11:00
Business Area: Legal (Floor 6)
Population: 45 devices

## 1. Incident Statement
Legal users experienced a sudden wave of application crashes in the morning after a software update. Endpoint telemetry and deployment logs indicate the issue is strongly associated with deployment of Document Manager v2.1 and subsequent high disk I/O during first-run behavior.

## 2. Scope and Impact
- Affected collection: Legal-Win11
- Devices in scope: 45
- Primary failing process: DocManager.exe (74% of crashes from 10:00-11:00)
- User impact pattern: repeated app instability/crashes, degraded endpoint experience

## 3. Supporting Evidence

### Telemetry Evidence (Nexthink)
- Stable pre-change indicators:
  - 08:00: DEX 91, crash 0.1%, Disk I/O Normal
  - 09:00: DEX 90, crash 0.2%, Disk I/O Normal
- Post-change degradation:
  - 10:00: DEX 58, crash 6.2%, Disk I/O High
  - 11:00: DEX 55, crash 6.8%, Disk I/O High
- Crash concentration: DocManager.exe contributes 74% of crashes in the degraded window.

### Change Evidence (SCCM)
- 09:38:20 deployment start to Legal-Win11 (45 devices)
- 09:44:07 install complete on 45/45 devices
- 09:44:07 result: Success, 0 failures

### Release Constraint Evidence
- v2.1 vendor note: auto-save indexing can cause high disk I/O and intermittent crashes on devices under 8GB RAM during initial indexing period.
- Fleet composition: 40% of Legal-Win11 devices are 4GB RAM.

## 4. Timeline (UTC/Local as provided)
1. 08:00 normal baseline.
2. 09:00 still normal baseline.
3. 09:38:20 v2.1 deployment starts.
4. 09:44:07 deployment completes successfully across all 45 devices.
5. 10:00 immediate next telemetry interval shows sharp deterioration and crash wave.
6. 11:00 elevated crashes and high disk I/O persist.

## 5. Causal Analysis

## What changed?
- Application version moved from stable v2.0 to v2.1 across entire target group.

## What did not fail?
- Deployment transport/execution in SCCM (0 failures).

## What failed at runtime?
- Endpoint app stability, predominantly DocManager.exe, concurrent with high disk I/O.

## Most likely cause
- v2.1 first-run auto-save indexing workload created excessive disk I/O pressure on constrained-memory endpoints, resulting in intermittent application crashes during initial indexing window.

## 6. 5 Whys
1. Why did Legal users see a crash wave?
- DocManager.exe crash frequency spiked sharply between 10:00 and 11:00.

2. Why did DocManager.exe crash spike at that time?
- Crashes began immediately after v2.1 rollout completed and coincided with high disk I/O.

3. Why was disk I/O high after rollout?
- v2.1 introduces auto-save indexing workload during first-run/index build period.

4. Why did this affect Legal-Win11 significantly?
- A material portion of devices (40%) are 4GB RAM, matching vendor-stated risk profile (under 8GB).

5. Why was this not prevented before broad rollout?
- Rollout guardrails did not include hardware-aware ringing and known-limitation gating for constrained-memory devices.

## 7. Final Hypothesis (Selected)
Document Manager v2.1 caused post-install instability due to resource-intensive auto-save indexing on constrained endpoints, not due to SCCM deployment failure.

Confidence Level: High
Evidence Strength: Strong temporal correlation + process specificity + vendor limitation alignment + successful deployment logs.

## 8. Remediation (Exact Steps and Order)
1. Pause further v2.1 deployments outside already-impacted scope.
2. Build impacted device list from Legal-Win11 by version, crash events, and RAM tier.
3. Prioritize rollback to v2.0 on actively crashing endpoints (especially 4GB devices).
4. Validate stabilization for rolled-back endpoints (crashes and disk I/O).
5. Implement policy/control to disable or defer auto-save indexing for under-8GB devices.
6. Pilot controlled v2.1 redeploy on 8GB-only cohort.
7. Expand gradually to mixed cohort only after pilot stability window passes.

## 9. Verification of Resolution
- Within next two telemetry intervals after rollback/policy change:
  - Crash rate decreases toward baseline (near 0.1%-0.2%).
  - DEX improves toward baseline band (~90).
  - Disk I/O returns to Normal.
  - DocManager.exe no longer dominates crashes.
- No new widespread user reports from Legal floor after business-hour observation window.

## 10. Preventive Actions
- Introduce hardware-aware deployment rings (4GB/8GB/16GB cohorts).
- Add mandatory review of vendor known limitations to CAB checklist.
- Require canary phase on constrained hardware for any release with indexing/cache migrations.
- Define rollback trigger thresholds (DEX drop, crash-rate spike, disk I/O saturation) with automatic deployment hold.

## 11. Notes on Error-Code Interpretation
No Citrix broker/controller error codes were present in the supplied data. No error-code meaning was inferred or invented in this RCA.