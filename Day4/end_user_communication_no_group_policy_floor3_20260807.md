# End-User Communications - No Group Policy Incident (Floor 3)

Date: 2026-08-07  
Source of facts: Incident analysis and RCA for Floor 3 DNS/DHCP scope issue

## Audience 1 - Non-Technical Executive
Your access and data are safe. At about 07:40, 3 of 4 Finance PCs on Floor 3 did not receive required sign-in settings because those PCs were given an outdated network address source. We corrected the central assignment, removed old entries, refreshed affected PCs, and confirmed successful processing. One PC was unaffected because it already had the correct setting before migration. No action is required unless you still see sign-in policy issues.

## Audience 2 - Affected End-User Team (10 People, Non-Technical)
Your access and data are safe. Around 07:40, 3 of 4 Finance computers on Floor 3 could not load sign-in settings because they were pointed to an old network address source after migration; one computer was fine because it already used the new correct setting. We fixed the central assignment, removed old values, refreshed affected devices, and confirmed settings now apply successfully. If you see the same issue again, restart once and report it immediately. Contact the DWP Service Desk.

## Audience 3 - Engineer-to-Engineer Internal Note
Status: Resolved and validated.

Scope/impact facts:
- Symptom: "No Group Policy" on 3 of 4 Win11 Finance endpoints on Floor 3.
- Onset: ~07:40.
- Comparator: 1 peer endpoint unaffected.

Root cause:
- DHCP scope for Floor 3 subnet still referenced decommissioned DNS infrastructure (observed stale values included 172.16.5.5 and old local DNS assignment such as 10.10.3.250), causing DC name-resolution failure and downstream GP failure.
- Unaffected endpoint had correct DNS 10.10.0.10 pre-set before migration.

Exact action taken:
- Updated DHCP scope option 006 (DNS Servers) for Floor 3 subnet.
- Removed stale/decommissioned DNS entries.
- Set active/correct resolver to 10.10.0.10.
- Renewed/reissued leases on affected clients so corrected DNS was applied.

Config detail:
- Correct DNS target: 10.10.0.10.
- Incorrect/stale DNS observed in affected path: 172.16.5.5 (decommissioned) and old local DNS assignment path including 10.10.3.250.

Verification steps/evidence:
- Affected pattern pre-fix included Netlogon 5719, DNS Client 1014, GroupPolicy 1058/1030/1129.
- Post-fix validation confirmed Group Policy success (GroupPolicy Event 1500: "Group Policy settings processed successfully").
- Resolution confirmed at 07:40 AM validation checkpoint.

Preventive action required:
- Enforce DNS decommission dependency gate: do not retire DNS nodes until all DHCP scopes/policies are audited clean.
- Add mandatory DHCP option 006 validation to migration checklist (server-level, scope-level, and policy inheritance).
- Add recurring compliance check to detect scopes pointing to retired DNS IPs.
- Require post-change subnet sampling: DNS resolution, secure channel, SYSVOL reachability, and gpupdate success before closure.
