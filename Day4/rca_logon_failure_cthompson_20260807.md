# Root Cause Analysis — Logon Failure / Account Lockout

**Incident Reference:** INC-20260807-CTHOMPSON  
**Date of Incident:** 2026-08-07  
**Time Window:** 08:44 – 09:09  
**Affected User:** cthompson (FINBRIDGE domain)  
**Affected Device:** DESKTOP-FB022  
**Prepared by:** DWP Engineer  
**Date of RCA:** 2026-08-07

---

## 1. Incident Summary

User cthompson was unable to log on beginning at approximately 08:44. Security logs show repeated bad-password failures from DESKTOP-FB022, followed by an account lockout at 08:44:56. After the lockout, an additional stream of wrong-password Kerberos pre-authentication failures was recorded from a second source IP, 10.10.8.112, indicating a separate credential source was also attempting authentication with invalid credentials.

At 09:08:14, `FINBRIDGE\helpdesk-admin` re-enabled the account, and at 09:09:01 cthompson successfully logged on interactively to DESKTOP-FB022. User access was verified restored and no further issues were reported.

---

## 2. Impact

| Area | Detail |
|---|---|
| User affected | cthompson |
| Scope | Single user only |
| Primary symptom | Unable to log on interactively |
| Start of confirmed failure window | 08:44:01 |
| Resolution time | 09:09:01 |
| Total disruption window | ~25 minutes |
| Helpdesk action required | 1 administrative account restoration action |
| Business impact | User unable to access workstation and domain-backed resources until administrative recovery was completed |

---

## 3. Timeline of Events

| Time | Event ID | Type | Description |
|---|---|---|---|
| 08:44:01 | 4776 | Audit Failure | Domain credential validation failed for FINBRIDGE\cthompson from DESKTOP-FB022 with error `0xC000006A` (wrong password) |
| 08:44:03 | 4625 | Audit Failure | Interactive logon failed on DESKTOP-FB022; failure reason: unknown user name or bad password |
| 08:44:28 | 4625 | Audit Failure | Second interactive logon failure on DESKTOP-FB022; failure reason: unknown user name or bad password |
| 08:44:55 | 4625 | Audit Failure | Third interactive logon failure on DESKTOP-FB022; failure reason: unknown user name or bad password |
| 08:44:56 | 4740 | Audit Failure | Account FINBRIDGE\cthompson locked out; caller computer DESKTOP-FB022 |
| 08:45:10 | 4625 | Audit Failure | Workstation unlock attempt failed on DESKTOP-FB022; failure reason: account locked out |
| 08:45:44 | 4771 | Audit Failure | Kerberos pre-authentication failed for FINBRIDGE\cthompson from source IP 10.10.8.112 with failure code `0x18` (wrong password) |
| 08:46:01 | 4771 | Audit Failure | Repeat Kerberos pre-authentication failure from source IP 10.10.8.112 with failure code `0x18` |
| 08:46:33 | 4771 | Audit Failure | Repeat Kerberos pre-authentication failure from source IP 10.10.8.112 with failure code `0x18` |
| 09:08:14 | 4722 | Audit Success | Account FINBRIDGE\cthompson enabled by FINBRIDGE\helpdesk-admin |
| 09:09:01 | 4624 | Audit Success | Interactive logon succeeded for FINBRIDGE\cthompson on DESKTOP-FB022 |

---

## 4. Supporting Evidence Analysis

### 4.1 Evidence that the initial login failure was credential-driven

- **08:44:01 - Event 4776** recorded error code `0xC000006A`, which explicitly indicates **wrong password** during domain credential validation.
- **08:44:03, 08:44:28, and 08:44:55 - Event 4625** recorded repeated interactive failures on DESKTOP-FB022 with failure reason **unknown user name or bad password**.
- This event pattern supports a user-specific credential failure rather than a general domain outage, workstation trust failure, or disabled-account condition at incident start.

### 4.2 Evidence that the account entered a lockout state

- **08:44:56 - Event 4740** confirms the account was locked out, with **DESKTOP-FB022** identified as the caller computer.
- **08:45:10 - Event 4625** then records a workstation unlock attempt failing specifically because the **account was locked out**.
- This establishes that the symptom changed from bad-password failures to enforced lockout after the repeated unsuccessful sign-in attempts.

### 4.3 Evidence of a second credential source after lockout

- **08:45:44, 08:46:01, and 08:46:33 - Event 4771** show Kerberos pre-authentication failures from **10.10.8.112**, not DESKTOP-FB022.
- The failure code `0x18` again indicates **wrong password**.
- This means invalid credentials were still being presented from another source after the local lockout event.
- Based on the evidence alone, this second source may have been another device, a background process, a mapped resource, or a saved credential replay. The logs provided do not identify the exact system or process, so that point remains a contributing suspicion rather than a confirmed root cause.

### 4.4 Evidence of successful restoration

- **09:08:14 - Event 4722** records account re-enable activity by `FINBRIDGE\helpdesk-admin`.
- **09:09:01 - Event 4624** confirms successful interactive logon for cthompson on DESKTOP-FB022.
- User verification confirmed successful access and no further issues were reported.

---

## 5. What This RCA Confirms

Confirmed:
- The user's inability to log in was real and attributable to authentication failures recorded in security logs.
- The account was locked out at 08:44:56 after repeated bad-password attempts.
- Administrative restoration occurred at 09:08:14.
- Successful interactive login resumed at 09:09:01.

Confirmed with lower certainty as contributing context:
- Another source, IP 10.10.8.112, also submitted wrong credentials for the same account after the lockout.

Not confirmed from the supplied evidence:
- Whether the original bad password attempts were caused by user typing error, a recently changed password, Caps Lock, or a saved credential.
- What exact system or process was using 10.10.8.112.
- Whether the account was formally unlocked, re-enabled, or restored through a local operational workaround beyond what Event 4722 explicitly records.

---

## 6. Root Cause

**Primary root cause:** Repeated wrong-password authentication attempts for FINBRIDGE\cthompson caused the account to enter a locked-out state, which prevented further successful logon attempts until administrative intervention was applied.

**Contributing factor:** Additional wrong-password Kerberos attempts continued from source IP 10.10.8.112 after the lockout, indicating that a second credential source may also have been using stale or invalid credentials for the same user account.

**Resolution action recorded:** `FINBRIDGE\helpdesk-admin` performed an account restoration action logged as Event 4722 at 09:08:14, after which the user successfully logged on at 09:09:01.

---

## 7. Five Whys Analysis

### Problem Statement
User cthompson was unable to log on to DESKTOP-FB022 on 2026-08-07 and required helpdesk intervention before access was restored.

---

**Why 1 — Why was cthompson unable to log on?**  
Because the account was in a locked-out state during the incident window, preventing successful authentication.

---

**Why 2 — Why did the account become locked out?**  
Because repeated authentication attempts with an incorrect password were submitted for FINBRIDGE\cthompson.

---

**Why 3 — Why were incorrect passwords being submitted repeatedly?**  
Because invalid credentials were entered or replayed from DESKTOP-FB022, and the same account also saw additional wrong-password Kerberos attempts from source IP 10.10.8.112.

---

**Why 4 — Why did incorrect-password attempts from one or more sources result in a user-visible outage?**  
Because the authentication controls enforced account lockout after repeated failures, converting incorrect credential use into a full denial of access for the user.

---

**Why 5 — Why was the incident not prevented or shortened automatically?**  
Because there was no immediate self-service recovery path and no confirmed early identification of the secondary credential source that continued presenting bad credentials after the lockout.

---

## 8. Corrective and Preventive Actions

| # | Action | Owner | Priority | Target |
|---|---|---|---|---|
| 1 | Identify what system was using source IP 10.10.8.112 and review it for cached or saved credentials tied to cthompson | DWP / Infrastructure | High | Next working day |
| 2 | Clear or update any stored credentials, mapped-drive secrets, scheduled task credentials, service prompts, or application caches associated with cthompson on the identified secondary source | DWP / Endpoint Support | High | Next working day |
| 3 | Review recent 4740 and 4771 events for cthompson to ensure there is no recurring post-resolution lockout pattern | IAM / Service Desk | High | Same day |
| 4 | Confirm whether current account lockout thresholds are aligned with organizational policy and operational tolerance | IAM / Security | Medium | Within 5 working days |
| 5 | Evaluate self-service unlock or equivalent user recovery controls to reduce helpdesk dependency for isolated credential lockouts | IAM / Service Management | Medium | Within 30 days |
| 6 | Provide user guidance to sign out of stale sessions and verify current password use across mobile, VPN, mail, and other connected applications if a password change recently occurred | Service Desk | Low | At next user contact |

---

## 9. Preventive Recommendations

- Monitor for repeated **Event 4771** or **Event 4776** failures against a single account from multiple sources within a short window, as this is a useful early signal of cached or stale credentials.
- Correlate **Event 4740** lockout events with source workstation and follow-on pre-authentication events to distinguish user typing error from background credential replay.
- Maintain an operational checklist for isolated login failures that includes checking for secondary IP sources, not only the user workstation.
- Where policy permits, reduce recovery time by implementing a user self-service restoration path for routine credential lockouts.

---

## 10. Lessons Learned

| Lesson | Application |
|---|---|
| Single-user login failures can still involve multiple authentication sources | Triage should include both the user device and any secondary IPs present in Kerberos or NTLM events |
| A lockout event alone is not always the whole story | Follow-on Event 4771 entries can reveal stale credentials still being replayed elsewhere |
| Resolution evidence should include both the admin action and the first successful logon | This provides a clean closure point for the incident timeline |

---

## 11. Closure Statement

The incident was resolved at **09:09** after administrative account restoration recorded at **09:08:14** and a successful interactive logon recorded at **09:09:01**. User access was verified on DESKTOP-FB022 and no further issues were reported at closure.