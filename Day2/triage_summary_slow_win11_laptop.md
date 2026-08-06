# Triage Summary: Slow Windows 11 Laptop

## Likely Causes
1. Resource saturation
   - CPU, memory, or disk heavily used by Teams, Outlook, browser tabs, startup apps, or background sync.
2. Endpoint/security overhead
   - Antivirus scan, patching, or device compliance/policy tasks running in the background.
3. Storage or hardware constraints
   - Low free disk space, degraded SSD/HDD performance, or thermal throttling.

## 3 Questions To Ask
1. "When did this start, and is it constant or only at specific times (for example after login or during calls)?"
2. "Is the slowness device-wide, or mainly in one app such as Outlook, Teams, browser, or a line-of-business app?"
3. "Any recent updates, new software, VPN/network changes, or low disk space alerts?"

## First Diagnostic Step
1. Reproduce the issue while Task Manager is open.
2. Press `Ctrl+Shift+Esc` and open `Processes`.
3. Sort by `CPU`, then `Memory`, then `Disk`.
4. Observe for 2 minutes and note top 3 processes.

## What To Record
1. Process names and peak CPU/RAM/Disk values.
2. Whether disk usage is sustained near 100%.
3. Free space on C: (target more than 20% free).

## Interpretation Quick Guide
1. High CPU by one process: app/service bottleneck.
2. High memory with swapping: memory pressure.
3. High disk near 100%: storage contention or drive issue.

## Analyst One-Liner
"Initial triage indicates likely performance bottleneck from CPU/Memory/Disk saturation, with top impact process(es): [X, Y, Z]; next action is targeted remediation of the highest consumer and validation post-restart."
