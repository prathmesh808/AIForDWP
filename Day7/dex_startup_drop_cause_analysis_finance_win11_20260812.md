# DEX Startup Performance Drop — Cause Analysis
**Date:** 2026-08-12
**Device group:** Finance-Win11 (215 devices)
**Trigger event:** Security baseline config profile deployed 2026-08-04 02:00

---

## Ranked Causes — Most Probable First

---

### 1. Startup Compliance Logging Script Running Synchronously at Login

**Why it fits the evidence:**
The config change explicitly added a startup script for compliance logging. Startup scripts that run synchronously hold the login process open until they complete — the desktop does not become usable until the script finishes. The degradation began on the exact morning after the script was deployed (2026-08-04), with startup time jumping from 17.5 to 41.3 seconds — a 23.8-second addition consistent with a script completing before the session is handed to the user. IT-Win11 received no config change and shows zero degradation across the same period, ruling out any infrastructure or network cause.

**Fastest check:**
On an affected Finance-Win11 device, open **Event Viewer → Applications and Services Logs → Microsoft → Windows → GroupPolicy → Operational**. Look for startup script execution events on 2026-08-04 onwards and note the duration reported. A duration of 20–25 seconds here would confirm this as the cause.

---

### 2. Additional Defender Scan Policy Executing at Login

**Why it fits the evidence:**
The same config change also applied an additional Defender scan policy. If that policy triggers a scan at startup — before the desktop is marked as usable — it would add significant time to every login. The sustained nature of the drop across 2026-08-04 to 2026-08-06 (41–44 seconds each day, not a one-off spike) is consistent with a scan running on every login rather than a one-time event. Again, IT-Win11 was excluded from this policy and shows no change.

**Fastest check:**
On an affected device, open **Windows Security → Protection History** and filter by date from 2026-08-04. Check whether a quick or full scan is recorded at login time each day. Alternatively, check **Event Viewer → Applications and Services Logs → Microsoft → Windows → Windows Defender → Operational** for scan start/end events immediately after login.

---

### 3. Security Baseline Profile Applying Multiple Policy Settings During First-Login Processing

**Why it fits the evidence:**
New security baseline profiles often contain a large number of configuration service provider (CSP) or Group Policy settings that are processed and applied during the first login after deployment. This processing can add several seconds to login time. However, this cause would typically produce the largest delay on the first day only (2026-08-04), then reduce as settings are already applied on subsequent logins. The data shows the slowdown persisting at roughly the same level across three days, making this less likely than the script or scan as the sole cause — though it may contribute alongside cause 1 or 2.

**Fastest check:**
Compare startup times on a freshly enrolled Finance-Win11 device (where baseline was already applied before the test) against a device that received the change on 2026-08-04. If the freshly enrolled device shows no delay, first-login processing is eliminated. Also check **Event Viewer → System** for Winlogon or UserInit delays on 2026-08-04 vs 2026-08-03.

---

## Evidence Anchor

All three causes share one critical characteristic: they only affect Finance-Win11 because the config change was only deployed to Finance-Win11. The IT-Win11 comparison group (stable at 84–85 score throughout) eliminates any external factor — network, hardware, time of day — as a competing explanation. The cause is within the config change itself.
