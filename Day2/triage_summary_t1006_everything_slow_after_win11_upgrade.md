# Structured Triage Summary

## Ticket
- T-1006

## Summary (one line)
User reports system-wide slowness two days after Win11 upgrade, indicating likely post-upgrade resource contention or configuration/performance regression (to-verify).

## Impact (who/how many/business urgency)
- Who is impacted: Reported end user on upgraded device
- How many affected: One reported user/device currently (to-verify if common post-upgrade trend)
- Business urgency: Medium to High depending on extent of work disruption

## Known Facts
- Ticket ID: T-1006
- Symptom wording: "Everything is slow"
- Timing: Win11 upgrade completed two days ago
- Scope indication: Appears device-wide from user description

## Missing Information To Gather
- Whether slowness is constant or tied to specific apps/workloads (to-verify)
- Current CPU, memory, and disk utilization during slowdown (to-verify)
- Free disk space and pending restart/update state (to-verify)
- Whether endpoint security scans or indexing are active post-upgrade (to-verify)
- Whether other recently upgraded users report similar behavior (to-verify)

## Likely Category
- Endpoint performance / post-Win11-upgrade degradation (to-verify)

## First Diagnostic Step
- Reproduce the slowness with Task Manager open and record top CPU/Memory/Disk consumers over a 2-minute interval to identify whether the primary bottleneck is process, memory pressure, or disk contention (to-verify).
