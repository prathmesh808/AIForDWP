# RCA - No Group Policy on Floor 3 Win11 Endpoints

Date: 2026-08-07  
Incident Window Referenced in Logs: 2024-03-15 07:40-07:55  
Prepared by: DWP Engineer  
Status: Resolved  
Resolution Confirmed: 07:40 AM (post-fix validation point)

## 1) Executive Summary
Three Windows 11 endpoints on Floor 3 failed to process Group Policy due to inability to reach domain services. The direct technical failure was DNS misdirection: affected machines received decommissioned DNS servers from DHCP scope configuration. After DNS assignment was corrected and validated, Group Policy processing succeeded.

## 2) Business/User Impact
- Scope: 3 of 4 machines in OU=Finance on Floor 3 affected.
- User-facing symptom: "No Group Policy" processing at startup/sign-in.
- Risk exposure during incident: policy drift, missing security and configuration baselines, and delayed user readiness.

## 3) Technical Root Cause
DHCP scope configuration for the Floor 3 subnet still referenced retired DNS infrastructure (for example 172.16.5.5 and old local DNS values), causing domain name resolution failures for DC discovery and SYSVOL access. One device (FB058) was unaffected because DNS was manually pre-configured to the correct server (10.10.0.10).

## 4) Supporting Evidence

### Endpoint/System Log Evidence (Affected Pattern)
- 07:40:08 Netlogon Event 5719 (Error): no domain controller available; DNS query for FINBRIDGE-DC01.finbridge.local returned no response.
- 07:40:09 GroupPolicy Event 1058 (Error): cannot access \\FINBRIDGE-DC01\sysvol\...\gpt.ini (error 0x3).
- 07:40:10 GroupPolicy Event 1030 (Warning): cannot query list of GPOs (error 0x546).
- 07:40:12 GroupPolicy Event 1129 (Error): no network connectivity to a domain controller.
- 07:41:05 DNS Client Event 1014 (Warning): DC name resolution timed out; configured DNS servers did not respond.
- 07:44:01 GroupPolicy Event 1129 (Error): repeat failure due to no DC connectivity.

### Comparison Evidence (Unaffected Reference Endpoint)
- 07:40:05 DHCP Client Event 50036: IP 10.10.3.141, DNS servers assigned 10.10.0.10 (correct new DNS).
- 07:40:11 GroupPolicy Event 1500 (Information): Group Policy settings processed successfully.

### DHCP Server-Side Evidence
- FB055-057 DNS assigned: 172.16.5.5 (Floor 3 local DNS, decommissioned 2024-03-14 overnight).
- FB058 DNS assigned: 10.10.0.10 (central DNS, correct; manually set before migration).
- Differential outcome aligns exactly with DNS source differences.

## 5) Detailed Timeline
- 02:00 (migration wave): legacy DNS infrastructure decommissioned.
- 07:40:08: Netlogon 5719 on affected endpoint indicates DC discovery failure via DNS.
- 07:40:09-07:40:12: GroupPolicy 1058/1030/1129 confirms GPO retrieval failure path (DC/SYSVOL unreachable from client perspective).
- 07:41:05: DNS Client 1014 confirms resolver timeout/no DNS server response.
- 07:42:18: DHCP lease event on affected host shows assignment from outdated DNS configuration.
- 07:44:01: Repeat GroupPolicy 1129 confirms persistence before fix.
- 07:40:05 (reference unaffected endpoint): DHCP assigns correct DNS (10.10.0.10).
- 07:40:11 (reference unaffected endpoint): GroupPolicy 1500 success confirms environment works when DNS is correct.
- 07:40 AM (post-fix validation): issue declared resolved and Group Policy processing verified successful.

## 6) 5 Whys Analysis
1. Why did Group Policy fail on Floor 3 endpoints?
   Because clients could not discover/reach a domain controller and SYSVOL during policy processing.

2. Why could clients not discover/reach DC/SYSVOL?
   Because DNS resolution for FINBRIDGE-DC01.finbridge.local failed or timed out.

3. Why did DNS resolution fail on affected clients?
   Because DHCP assigned decommissioned DNS server addresses to the Floor 3 subnet clients.

4. Why was DHCP assigning decommissioned DNS servers?
   Because DHCP scope option 006 for the Floor 3 subnet was not updated during/after migration.

5. Why was scope option 006 not updated before DNS decommission?
   Because migration change controls/checklists did not enforce dependency validation between DNS retirement and DHCP scope audit/remediation.

## 7) Corrective Actions Implemented
- Updated DHCP scope DNS option (006) for Floor 3 subnet to active resolver 10.10.0.10.
- Removed stale/decommissioned DNS entries from applicable DHCP scope settings.
- Renewed or reissued endpoint leases to obtain corrected DNS settings.
- Validated Group Policy processing success after DNS correction.

## 8) Preventive Actions (CAPA)
1. Add pre-decommission dependency gate:
   DNS server retirement cannot proceed until all DHCP scopes/policies are audited and signed off.

2. Add migration checklist control:
   Mandatory verification of DHCP option 006 at server, scope, and policy inheritance levels.

3. Add automated compliance check:
   Daily job to flag any DHCP scope referencing retired DNS IPs.

4. Add post-change validation standard:
   Sample endpoints per subnet must pass DNS resolution, secure channel, SYSVOL reachability, and GP update checks.

5. Improve change communication:
   Publish authoritative "new DNS" baseline and owner accountability for each subnet.

## 9) Verification and Closure Evidence
- Resolution status: confirmed.
- Validation statement: Group Policy processed successfully after applying recommended DNS/DHCP correction.
- Representative success evidence:
  - GroupPolicy Event 1500 (Information): "Group Policy settings processed successfully."
  - DHCP assignment on healthy reference host shows correct DNS resolver (10.10.0.10).

## 10) Lessons Learned
- Group Policy failures at startup frequently reflect dependency failures (DNS/DC reachability), not GPO object corruption.
- Comparing affected vs unaffected peers in the same OU is a high-value fast isolator.
- DHCP/DNS coupling must be treated as a critical control point during infrastructure migration waves.
