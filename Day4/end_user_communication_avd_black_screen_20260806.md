Audience 1 — Non-technical executive

Your access and data are safe. Today 07:00-10:00, about 40% of people using POOL-FIN-01 saw a black screen after sign-in; POOL-FIN-02 was unaffected. The 02:00 overnight update on POOL-FIN-01 introduced an unstable display component (version 31.0.101.4146). We stopped new logins there, routed users to POOL-FIN-02, applied a safe display mode, rebooted in waves, and corrected the image. By 10:00, logins were stable with no repeats. If this reappears, reconnect and contact Service Desk.

Audience 2 — Affected end-user team (10 people, non-technical)

Your access and data are safe, and this issue is resolved. From 07:00 to 10:00, about 40% of users on POOL-FIN-01 saw a black screen after sign-in while POOL-FIN-02 stayed normal because the 02:00 overnight update on POOL-FIN-01 introduced an unstable display component (version 31.0.101.4146). We paused new logins on POOL-FIN-01, moved people to POOL-FIN-02, used a safe display mode, rebooted in waves, and corrected the image; by 10:00 logins were stable with no repeats. If you see it again, reconnect, then contact Service Desk.

Audience 3 — Engineer-to-engineer internal note

Access/data posture: safe; incident resolved.

Impact and scope:
- Window: 07:00-10:00 local.
- Symptom: post-logon black screen on POOL-FIN-01.
- Blast radius: ~40% of users on POOL-FIN-01.
- Control: POOL-FIN-02 unaffected.

Root cause:
- 02:00 image update on POOL-FIN-01 introduced graphics stack instability.
- Fault signature: dwm.exe crashing in igdumd64.dll (0xc0000005), with DWM exit and session disconnect sequence.
- Config detail tied to remediation path: unstable Intel graphics component version 31.0.101.4146 in updated image baseline.

Exact action taken:
- Immediate containment: restricted/drained new sessions on POOL-FIN-01.
- Traffic action: routed sessions to POOL-FIN-02 where capacity allowed.
- Mitigation: forced software-rendering path on affected hosts.
- Recovery execution: controlled wave reboots.
- Permanent remediation: corrected image graphics stack/driver path (replace unstable 31.0.101.4146 with validated stable version), then returned hosts in waves.

Verification and closure:
- By 10:00, successful user logins on POOL-FIN-01.
- No recurring black-screen reports.
- No repeat crash pattern observed in post-remediation validation window.

Preventive action required:
- Add mandatory post-image smoke tests (fresh logon, reconnect, idle resume, Teams/video, Office launch).
- Add image promotion blocker for DWM crash signature (Event 1000 with dwm.exe + igdumd64.dll).
- Add correlated alerting for Event 1000 + Event 9009 during rollout window.
- Enforce phased canary rollout with pause/verify gates and rollback-ready prior image.
