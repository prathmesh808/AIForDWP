# No Group Policy - Hypothesis Analysis (Floor 3, Win11)

Date: 2026-08-07  
Analyst: DWP Engineer  
Status: Initial hypothesis only (no single cause selected yet)

## Scope Facts Used
- Symptom: No Group Policy
- Who: Three Windows 11 machines on Floor 3
- Since: ~07:40 this morning
- Change: Nil

## Ranked Likely Causes (Most Probable First)

### 1) Floor 3 network path issue to AD/DNS/DC (switch/VLAN/uplink/port path degradation)
**Why this fits scope facts**
- Multiple endpoints affected in one physical location strongly suggests shared infrastructure.
- Time-bound onset (~07:40) is consistent with a network event (uplink flap, VLAN issue, switch config push, STP reconvergence) even when no user-visible "change" is recorded.
- Group Policy dependency chain starts with AD/DNS reachability; loss here presents as "No Group Policy" quickly across nearby devices.

**Single fastest check**
- From one affected machine, run: `nltest /dsgetdc:<domain_fqdn>`.
- If this fails or times out, shared AD/DC path issue is immediately likely; if successful, this cause drops in rank.

### 2) DNS resolution failure/misdirection for domain services on affected segment
**Why this fits scope facts**
- GPO processing depends on correct DNS SRV/A resolution for domain controllers.
- Segment-specific DNS misconfiguration (wrong DNS server via DHCP, resolver outage for that subnet) can affect only Floor 3 devices at the same time.
- Sudden onset without declared change is common when DHCP lease renewal picks up bad DNS options.

**Single fastest check**
- On one affected machine, run: `nslookup -type=SRV _ldap._tcp.dc._msdcs.<domain_fqdn>`.
- Missing/incorrect records or timeouts quickly confirm/eliminate DNS as the immediate blocker.

### 3) Time synchronization/Kerberos skew on affected machines
**Why this fits scope facts**
- GPO retrieval and SYSVOL access rely on Kerberos trust; significant clock skew breaks authentication and appears as policy non-application.
- Three systems can drift together if they share a local NTP issue or were offline and resumed around the same period.
- Onset time can align with boot/resume/user sign-in wave near start of day.

**Single fastest check**
- On one affected machine, run: `w32tm /query /status` and compare clock offset versus domain time.
- Large offset (typically >5 min) rapidly confirms or rules out Kerberos time skew as the primary cause.

### 4) Domain controller-side AD/SYSVOL/NETLOGON availability incident
**Why this fits scope facts**
- If one site-preferred DC is unhealthy, clients in a location may fail GPO while other areas appear normal.
- "No change" at endpoint level is compatible with backend degradation.
- Sudden start time suggests backend service interruption rather than gradual endpoint drift.

**Single fastest check**
- On one affected endpoint, run: `echo %logonserver%`.
- Then immediately test `\\<logonserver>\SYSVOL` access in File Explorer or `dir \\<logonserver>\SYSVOL`.
- Access failure strongly supports DC/SYSVOL availability issue; success weakens this hypothesis.

### 5) OU/security filtering/WMI filtering scope miss affecting these three endpoints
**Why this fits scope facts**
- "No Group Policy" can be perceived when devices are no longer in expected scope due to OU move, denied security group, or WMI filter mismatch.
- Three machines could share an OU or device group tied to a location/team on Floor 3.
- No declared change does not exclude automated admin actions (scripted OU/group updates) outside local awareness.

**Single fastest check**
- On one affected machine, run: `gpresult /r /scope computer`.
- If expected GPOs are absent with filtering/permission indicators, scope/filtering becomes likely; if expected GPOs are listed but not applying, this cause drops.

## Notes
- This is a ranked hypothesis list only; no root cause committed yet.
- Next triage step should execute the five checks in order and re-rank based on evidence.

## Evidence Assessment Against Each Hypothesis (No Winner Selected Yet)

### 1) Floor 3 network path issue to AD/DNS/DC (switch/VLAN/uplink/port path degradation)
**Judgement:** Contradicts

**Why this judgement**
- Affected machine shows no DC reachability, but evidence points to bad DNS assignment rather than a shared physical path failure.
- One peer on same floor/OU succeeds at the same time window when using correct DNS, which weakens a common path-outage hypothesis.

**Cited events**
- DESKTOP-FB031: Netlogon Event 5719 at 07:40:08 (DNS query for DC returned no response).
- DESKTOP-FB031: DHCP Client Event 50036 at 07:42:18 (DNS assigned as old/decommissioned server).
- DESKTOP-FB029: GroupPolicy Event 1500 at 07:40:11 (policy processed successfully).

### 2) DNS resolution failure/misdirection for domain services on affected segment
**Judgement:** Supports

**Why this judgement**
- Logs explicitly show DNS timeout for the DC name and no DNS server response.
- DHCP assignment on affected machine references old/decommissioned DNS server.
- Unaffected peer has correct DNS assignment and successful GP processing in same window.

**Cited events**
- DESKTOP-FB031: DNS Client Event 1014 at 07:41:05 (name resolution for FINBRIDGE-DC01 timed out; configured DNS servers did not respond).
- DESKTOP-FB031: DHCP Client Event 50036 at 07:42:18 (DNS assigned: 10.10.3.250, old DNS).
- DESKTOP-FB031: Netlogon Event 5719 at 07:40:08 (no DC available; DNS query no response).
- DESKTOP-FB029: DHCP Client Event 50036 at 07:40:05 (DNS assigned: 10.10.0.10, correct).
- DESKTOP-FB029: GroupPolicy Event 1500 at 07:40:11 (success).

### 3) Time synchronization/Kerberos skew on affected machines
**Judgement:** Contradicts

**Why this judgement**
- Failures occur at DNS/DC discovery stage before Kerberos policy application could succeed.
- There are direct DNS/DC reachability errors and no time-skew indicators in supplied events.

**Cited events**
- DESKTOP-FB031: Netlogon Event 5719 at 07:40:08 (cannot set secure channel; DC not available due to DNS no response).
- DESKTOP-FB031: DNS Client Event 1014 at 07:41:05 (DNS timeout/no DNS server response).

### 4) Domain controller-side AD/SYSVOL/NETLOGON availability incident
**Judgement:** Contradicts

**Why this judgement**
- If DC/SYSVOL were broadly unavailable, similarly scoped peer would likely fail as well.
- Peer with correct DNS resolves and applies policy successfully in same timeframe, suggesting DC service was available.

**Cited events**
- DESKTOP-FB029: GroupPolicy Event 1500 at 07:40:11 (successful policy processing).
- DESKTOP-FB029: DHCP Client Event 50036 at 07:40:05 (correct DNS assignment prior to successful GP).
- DESKTOP-FB031: GroupPolicy Event 1058 at 07:40:09 (cannot access SYSVOL path), consistent with name-resolution path failure for that client.

### 5) OU/security filtering/WMI filtering scope miss affecting these three endpoints
**Judgement:** Contradicts

**Why this judgement**
- Error pattern indicates connectivity and name-resolution failure, not filtering denial semantics.
- One machine in same OU succeeds when pointed to correct DNS, which is inconsistent with OU/WMI/security filter mis-scope as primary factor.

**Cited events**
- DESKTOP-FB031: GroupPolicy Event 1129 at 07:40:12 and 07:44:01 (no network connectivity to a domain controller).
- DESKTOP-FB031: GroupPolicy Event 1030 at 07:40:10 and Event 1058 at 07:40:09/07:40:11 (cannot query/list and cannot access SYSVOL path).
- DESKTOP-FB029: GroupPolicy Event 1500 at 07:40:11 (same OU peer success with correct DNS context).

## Appended Update - Event Details, Surviving Hypothesis, and Resolution

### Incident Event Details (Affected Machine: DESKTOP-FB031)
- 07:40:08 Netlogon Event 5719 (Error): secure channel to FINBRIDGE could not be established; DNS query for FINBRIDGE-DC01.finbridge.local returned no response.
- 07:40:09 GroupPolicy Event 1058 (Error): failed to access \\FINBRIDGE-DC01\sysvol\finbridge.local\Policies\{3A1B2C4D-E5F6-7890-ABCD-EF1234567890}\gpt.ini, code 0x3.
- 07:40:10 GroupPolicy Event 1030 (Warning): failed to query list of GPOs, code 0x546.
- 07:40:12 GroupPolicy Event 1129 (Error): no network connectivity to a domain controller.
- 07:41:05 DNS Client Event 1014 (Warning): name resolution for FINBRIDGE-DC01.finbridge.local timed out; configured DNS servers did not respond.
- 07:42:18 DHCP Client Event 50036 (Information): lease obtained with DNS server 10.10.3.250 (old/decommissioned).
- 07:44:01 GroupPolicy Event 1129 (Error): repeat failure due to no DC connectivity.

### Comparison Evidence (Same OU, Unaffected: DESKTOP-FB029)
- 07:40:05 DHCP Client Event 50036: DNS assigned 10.10.0.10 (correct).
- 07:40:11 GroupPolicy Event 1500 (Information): Group Policy processed successfully.

### Surviving Hypothesis
DNS resolution failure or misdirection on Floor 3 endpoints caused by stale DHCP scope DNS settings that still reference decommissioned DNS infrastructure.

### Detailed Resolution Steps
1. Contain impact immediately on affected devices.
	Set temporary DNS to 10.10.0.10, renew lease, flush DNS cache, and run Group Policy refresh so users recover while server-side fix is completed.

2. Correct DHCP scope configuration for Floor 3 subnet.
	Update option 006 (DNS Servers): remove decommissioned DNS entries and set active resolver 10.10.0.10.

3. Validate effective DHCP option inheritance.
	Confirm no server-level or policy-level override reintroduces old DNS values to this scope.

4. Reissue client addressing.
	Force lease renewals on affected machines (or reboot where remote renewal is unavailable) so corrected DNS is applied.

5. Verify AD and Group Policy dependency chain.
	Confirm DNS resolver settings are correct, DC records resolve, secure channel is healthy, SYSVOL is reachable, and GP update completes.

6. Validate logs after remediation.
	Confirm no recurrence of Event 5719, 1014, 1058, 1030, or 1129 and verify successful GroupPolicy informational events.

7. Implement prevention controls.
	Add migration checklist controls for DHCP option validation and block DNS decommission until all scopes are audited clean.

### Closure Validation Criteria
- Previously affected devices receive correct DNS from DHCP.
- Group Policy applies successfully on sampled devices in the affected OU.
- No repeat DNS/DC/GP connectivity failures during observation window.