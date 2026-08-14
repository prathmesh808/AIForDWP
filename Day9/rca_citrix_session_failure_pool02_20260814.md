# Root Cause Analysis (RCA) - Citrix Session Failure - FinBridge Pool-02

Date: 2026-08-14
Incident Type: Citrix VDI session launch failure
Environment: FinBridge Citrix site
Affected Scope: Pool-02 users

## 1) Executive summary

Between approximately 06:15 and 08:58, FinBridge Pool-02 experienced major session launch disruption. Evidence shows large-scale machine unregistration in Pool-02 (22 unregistered of 25) and repeated inability of VDAs to contact Delivery Controller `dc-vdi-02` on TCP 80, returning connection refused. At incident observation time, `Citrix Broker Service` on `dc-vdi-02` was stopped. Pool-01 remained healthy via `dc-vdi-01`.

Selected root cause for this incident:
`Citrix Broker Service` outage on `dc-vdi-02` caused Pool-02 VDA registration failures, resulting in insufficient registered machines and broker launch failures.

## 2) Scope and impact

- Affected users: 22 of 30 in Pool-02.
- Unaffected comparison group: Pool-01 in same site.
- Business effect: Session launches failing for majority of Pool-02 users.
- User-facing error path: broker timeout waiting for registration response followed by launch failure error 1030 text `No machines available in the desktop group`.

## 3) Supporting evidence

### Broker log evidence
- 08:58:03: launch requested for user `jsmith` in Pool-02.
- 08:58:04: broker queried available machines in Pool-02.
- 08:58:34: timeout waiting for machine registration response (30000 ms).
- 08:58:34: launch failed with error 1030 and text `No machines available in the desktop group`.

### Catalog/registration evidence
- Pool-02: 25 provisioned, 3 registered, 22 unregistered, maintenance mode 0.
- Pool-01: 20 provisioned, 19 registered, 1 unregistered.

### VDA error sample evidence (Pool-02)
- `VDI-P02-014`: last registration attempt 06:15:22 failed.
- `VDI-P02-017`: last registration attempt 06:16:01 failed.
- Common error text: unable to contact Delivery Controller.
- Destination and failure mode: `dc-vdi-02.finbridge.local:80` connection refused.

### Controller health evidence
- `dc-vdi-02`: Citrix Broker Service stopped, last known running yesterday 23:40.
- `dc-vdi-02`: Windows Update installed today 00:15; reboot required flag set; host not rebooted.
- `dc-vdi-01`: Citrix Broker Service running, uptime 14 days.

## 4) Timeline (evidence-based)

- Yesterday 23:40: `dc-vdi-02` Broker Service last known running.
- Today 00:15: Windows Update installed on `dc-vdi-02`; reboot required flag set.
- Today ~06:15 to 06:16: sampled Pool-02 VDA registration attempts fail to `dc-vdi-02:80` (connection refused).
- Today 08:58:03 to 08:58:34: user launch in Pool-02 times out and fails with error 1030 text `No machines available in the desktop group`.

## 5) 5-Why analysis

1. Why did users fail to launch sessions in Pool-02?
   - Broker could not allocate available registered machines for launch.
2. Why were machines not available for allocation?
   - Most Pool-02 machines were unregistered (22/25).
3. Why were machines unregistered?
   - VDAs failed registration attempts due to inability to contact DDC endpoint `dc-vdi-02:80` (connection refused).
4. Why was the controller endpoint refusing connections?
   - `Citrix Broker Service` on `dc-vdi-02` was stopped at incident time.
5. Why was the broker service stopped and not recovered before business impact?
   - Service outage persisted without timely restoration, with a pending reboot/update state present and no evidence of successful post-maintenance service health validation.

## 6) Root cause statement

Most probable root cause (selected):
Service-level outage of `Citrix Broker Service` on `dc-vdi-02` caused registration failure for Pool-02 VDAs (connection refused to controller endpoint), leading to large-scale unregistration and launch failures.

Note on certainty:
This RCA is based on provided incident data and aligns strongly with observed evidence. It does not rely on unverified interpretation of error code internals beyond the error text present in the log.

## 7) Remediation plan (exact order of operations)

1. Incident control and communications
- Freeze non-essential changes on Pool-02 and `dc-vdi-02`.
- Notify support channels of active restoration and possible reconnect events.

2. Controller state confirmation
- On `dc-vdi-02`, verify:
  - `Get-Service BrokerService`
  - `netstat -ano | findstr :80`

3. Immediate service restoration
- Start broker service:
  - `Start-Service BrokerService`
- Confirm service remains running for at least 5-10 minutes.

4. Reboot path if service instability persists
- If service fails to start or stops again, perform controlled reboot of `dc-vdi-02`.
- After reboot, verify Broker Service auto-start and listener readiness.

5. Registration recovery
- Trigger/allow VDA registration refresh on impacted Pool-02 machines.
- Restart Citrix Desktop Service on stuck VDAs per runbook, only where needed.

6. Functional validation
- Run controlled test launches from affected user set.
- Confirm no recurrence of broker registration timeout for Pool-02.

## 8) Verification of resolution

Required checks:
- `dc-vdi-02` Broker Service continuously running.
- TCP 80 reachable from sampled Pool-02 VDAs.
- Pool-02 registered count recovers from 3 toward expected operational level.
- Launch success for test users in Pool-02.
- No new broker entries showing 30000 ms registration timeout and launch failure error for the same pattern.

Recommended verification cadence:
- T+0: immediate post-fix checks.
- T+15 min: registration and launch trend check.
- T+30 min: stability check.
- T+24h: confirm no repeat alerts/incidents.

## 9) Preventive actions

1. Patch/reboot compliance for Delivery Controllers
- Enforce same-window reboot completion after updates affecting controller hosts.

2. Monitoring and alerting
- Alert on Broker Service stop events.
- Alert when registration ratio in any pool crosses defined threshold (for example, registered < 70%).

3. Controller resilience validation
- Validate Pool-02 VDA controller lists and failover behavior across available DDCs.

4. Change closure gate
- Add mandatory post-maintenance validation checklist:
  - Broker Service running
  - Listener active
  - Registration baseline healthy
  - Test launch successful

## 10) Residual risk

- If controller assignment is overly pinned to a single DDC, future single-controller failures can re-create pool-localized outages.
- If reboot-required states are left pending after updates, service degradation windows may recur.
