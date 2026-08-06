# Root Cause Analysis — Account Lockout
**Incident Reference:** INC-20260806-JSMITH  
**Date of Incident:** 2026-08-06  
**Time Window:** 08:02 – 08:24  
**Affected User:** jsmith (FINBRIDGE domain)  
**Affected Device:** DESKTOP-FB001  
**Prepared by:** DWP Analyst  
**Date of RCA:** 2026-08-06  

---

## 1. Incident Summary

User jsmith was locked out of their domain account at 08:06:01 after two consecutive interactive logon failures on DESKTOP-FB001. The account remained locked for approximately 16 minutes until unlocked by `FINBRIDGE\helpdesk-admin` at 08:22:10. The user successfully authenticated at 08:23:44. Total disruption window: **~22 minutes**.

---

## 2. Impact

| Area | Detail |
|---|---|
| User affected | jsmith |
| Duration of lockout | ~16 minutes (08:06 – 08:22) |
| Total disruption | ~22 minutes (first failure at 08:02 to successful logon at 08:23) |
| Helpdesk resource consumed | 1 helpdesk-admin action required to unlock account |
| Business impact | User unable to access workstation or any domain resources during lockout period |

---

## 3. Timeline of Events

| Time | Event ID | Type | Description |
|---|---|---|---|
| 08:02:14 | 4625 | Audit Failure | jsmith failed interactive logon (Type 2) on DESKTOP-FB001 — bad password |
| 08:04:22 | 4625 | Audit Failure | jsmith failed interactive logon (Type 2) on DESKTOP-FB001 — bad password |
| 08:06:01 | 4740 | Audit Failure | jsmith account locked out, triggered from DESKTOP-FB001 |
| 08:07:45 | 4625 | Audit Failure | jsmith attempted workstation unlock (Type 7) — failed; account already locked |
| 08:22:10 | 4722 | Audit Success | Account re-enabled by FINBRIDGE\helpdesk-admin |
| 08:23:44 | 4624 | Audit Success | jsmith successfully logged on interactively (Type 2) |

---

## 4. Evidence Analysis

### 4.1 Why this was not a brute-force or malicious attempt

- Both failures originated from **DESKTOP-FB001** — the user's own assigned workstation.
- Logon type was **2 (Interactive)** — physical keyboard/console access, not remote or scripted.
- The gap between attempts was **2 minutes**, consistent with manual re-entry, not automated attack.
- No failures were observed from any other source IP, workstation, or service account context.
- The account was successfully authenticated after unlock with no further failures.

### 4.2 Most likely cause

The user entered an incorrect password twice at the console. Probable contributing factors, in order of likelihood:

1. **Password recently changed** — muscle memory caused the old password to be typed.
2. **Caps Lock active** — Windows logon screens do not clearly indicate Caps Lock state on all configurations.
3. **Typing error** — general keystroke mistake, particularly on first logon of the day.

### 4.3 Policy observation

The account locked out after only **2 failed attempts**. Standard Microsoft baseline guidance recommends a threshold of **10 attempts**. A threshold of 2 significantly increases the probability of accidental self-lockout and generates unnecessary helpdesk load.

---

## 5. Five Whys Analysis

### Problem Statement
User jsmith was locked out of their domain account on 2026-08-06, losing access to their workstation for 22 minutes and requiring helpdesk intervention.

---

**Why 1 — Why was the account locked out?**  
Because the Active Directory account lockout policy locked the account after the maximum number of failed logon attempts was reached (threshold: 2 failures).

---

**Why 2 — Why were there failed logon attempts?**  
Because jsmith entered an incorrect password twice at the DESKTOP-FB001 console during interactive logon. The failure reason logged was "Unknown username or bad password," indicating a credential mismatch, not an expired or disabled account.

---

**Why 3 — Why did jsmith enter the wrong password?**  
Most likely because jsmith's password had been recently changed and they entered the previous password from memory, or because Caps Lock was active and the case-sensitive input did not match the stored credential. No password reset event (4723/4724) is present in the 30-minute window, but a prior reset cannot be ruled out without reviewing earlier logs.

---

**Why 4 — Why did the lockout occur after only 2 failures?**  
Because the domain Group Policy Object (GPO) for the Account Lockout Threshold is configured at 2 invalid attempts. This is below Microsoft's recommended baseline of 10 and means a single accidental mis-type on the second attempt is sufficient to lock the account, leaving no tolerance for normal human error.

---

**Why 5 — Why is the lockout threshold set so low?**  
Likely because the policy was configured to a strict value at some point to satisfy a security requirement or audit finding, without sufficient consideration of the operational impact on end users. There is no evidence of a documented business justification for a threshold of 2, and no compensating control (such as self-service unlock) is in place, meaning every lockout requires helpdesk intervention.

---

## 6. Root Cause

**Primary root cause:** The domain Account Lockout Threshold GPO is set to 2 invalid attempts — an overly aggressive value that converts normal user credential errors into full account lockouts requiring helpdesk intervention.

**Contributing factor:** The user entered an incorrect password, most likely due to a recently changed password or Caps Lock state, which would not have caused a lockout under a standard threshold policy.

---

## 7. Corrective Actions

| # | Action | Owner | Priority | Target Date |
|---|---|---|---|---|
| 1 | Review and raise the Account Lockout Threshold GPO to a minimum of 10 attempts, aligned to Microsoft Security Baseline | Identity & Access Management | High | Within 5 working days |
| 2 | Review prior 30 days of 4740 events to quantify how many lockouts are self-inflicted vs. suspicious | Security Operations | Medium | Within 10 working days |
| 3 | Investigate and document the business justification for the current threshold of 2; if none exists, remediate immediately | IAM / Security | High | Within 5 working days |
| 4 | Evaluate feasibility of self-service account unlock (e.g., Azure AD SSPR or on-prem equivalent) to reduce helpdesk volume | Service Desk / IAM | Medium | Within 30 days |
| 5 | Confirm whether jsmith's password was recently changed; if so, provide user guidance on password change best practices (log out of all sessions, note new credential before closing reset screen) | Service Desk | Low | At next contact with user |

---

## 8. Preventive Recommendations

- **Implement Self-Service Password Reset (SSPR):** Allows users to unlock their own accounts without helpdesk involvement, reducing MTTR and helpdesk load.
- **Enable Caps Lock indicator on logon screen:** Verify that the Windows logon UI is configured to display a Caps Lock warning — this is a Group Policy setting (`Interactive logon: Display user information when the session is locked`).
- **Alerting on 4740 events:** Ensure SIEM or monitoring tooling generates alerts for account lockout events. Multiple lockouts for the same account within a short window may indicate a credential-stuffing attempt and should be escalated differently from single self-lockouts.
- **User communication:** When a password is reset by helpdesk, send a follow-up reminder to the user about signing out of all cached sessions and not relying on saved credentials.

---

## 9. Lessons Learned

| Lesson | Application |
|---|---|
| A lockout threshold of 2 provides negligible security benefit over 10, but dramatically increases self-lockout rate | Apply Microsoft Security Baseline values unless a documented risk decision justifies deviation |
| All 4740 lockout events were sourced from the user's own workstation — no malicious actor involved | Lockout source and logon type are critical fields for triage; same-machine interactive lockouts are almost always user error |
| 16 minutes elapsed between lockout and helpdesk unlock | SSPR would have reduced this to near-zero without consuming helpdesk resource |

---

## 10. Sign-off

| Role | Name | Date |
|---|---|---|
| Analyst | DWP Analyst | 2026-08-06 |
| Service Desk Lead | | |
| IAM Owner | | |
| Security | | |
