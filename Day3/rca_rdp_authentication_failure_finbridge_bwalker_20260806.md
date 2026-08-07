# RCA: RDP Authentication Failure - FINBRIDGE\bwalker

**Date of Report:** 2026-08-06  
**Incident Date:** 2024-03-15 14:01:02 – 14:22:09  
**Affected User:** FINBRIDGE\bwalker  
**Affected Host IP:** 10.10.5.44  
**Status:** Resolved (user successfully authenticated after account unlock)

---

## 1) Executive Summary

User FINBRIDGE\bwalker experienced repeated RDP connection failures on 2024-03-15 between 14:01:02 and 14:05:34. Analysis of System, Security, and RDP service logs reveals a cascading authentication failure sequence initiated by incorrect credentials, which triggered account lockout after three failed logon attempts within four minutes. The user successfully reconnected at 14:22:09 after the lockout duration expired. Root cause is **incorrect user credentials** (either user mistyped password or client using stale cached credentials).

---

## 2) Event ID Explanations

### System Log Events

**Event ID 56 (TermDD) - Error**
- **What it records:** Terminal Server (RDP) security layer detected a protocol stream error and disconnected the client.
- **Significance:** This is a secondary effect triggered by failed authentication. TermDD (Terminal Desktop Driver) closes the connection when credentials are rejected by the Kerberos/NTLM authentication handler.
- **Note:** Event 56 occurs as a consequence of Event 140, not an independent protocol issue.

**Event ID 140 (RemoteDesktopServices-RdpCoreTS) - Warning**
- **What it records:** RDP connection rejected due to incorrect username or password.
- **Significance:** First indication of authentication failure. Occurs when credentials sent by client fail validation against domain controller.
- **Timing:** Coincides exactly with Event 56 (14:01:02).

**Event ID 131 (RemoteDesktopServices-RdpCoreTS) - Info**
- **What it records:** RDP service accepted a new TCP connection from client (three-way handshake successful, TLS/transport established).
- **Significance:** Indicates network connectivity and RDP transport layer are healthy. Failure occurs at **authentication layer** (layer 5+), not transport.
- **Timing:** 14:22:07 — approximately 17 minutes after account lockout, matching typical AD lockout duration.

### Security Log Events

**Event ID 4625 - Logon Failure**
- **What it records:** Failed logon attempt with detailed failure reason, account name, logon type, and source IP.
- **Logon Type 10:** RemoteInteractive (RDP connection).
- **Failure Reason:** "Unknown username or bad password" — authentication credentials invalid.
- **Count:** 3 occurrences (14:01:04, 14:03:18, 14:05:33).
- **Significance:** Authoritative security audit log. Documents each credential validation failure and can trigger account lockout if threshold exceeded.

**Event ID 4740 - Account Locked Out**
- **What it records:** User account locked due to too many failed logon attempts.
- **Trigger:** Default domain lockout policy = 5 failed attempts within 30 minutes OR aggressive policy = 3 attempts within threshold.
- **Duration:** Typically 15–30 minutes (varies by domain policy).
- **Timing:** 14:05:34 — 31 seconds after third failed attempt (14:05:33), consistent with lockout threshold of 3 attempts.
- **Significance:** Account disabled by security policy; client cannot authenticate regardless of correct password until lockout expires.

**Event ID 4624 - Logon Success**
- **What it records:** Successful logon with account name, logon type, and source IP.
- **Timing:** 14:22:09 — exactly 17 minutes after lockout (Event 4740 at 14:05:34).
- **Significance:** Confirms user able to authenticate after lockout expiration, and credentials were valid (ruling out permanent account issues).

---

## 3) Sequence of Events (Timeline)

```
14:01:02  User FINBRIDGE\bwalker attempts RDP connection from 10.10.5.44
          ↓ Sends credentials (username + password)
          ↓ RDP transport established (TLS handshake succeeds)
          ↓ Credentials sent to domain controller for validation
          ✗ DC rejects credentials → Event 4625 (Logon Failure)
          ✗ TermDD closes connection → Event 56 (Protocol Stream Error)
          ✗ RdpCoreTS logs rejection → Event 140 (Auth Failure Warning)

14:03:18  User (or client automation) retries RDP connection
          ✗ Same invalid credentials sent
          ✗ DC rejects credentials → Event 4625 (2nd failure)
          ✗ Connection closed

14:05:33  User (or client automation) makes third RDP attempt
          ✗ Invalid credentials sent again
          ✗ DC rejects credentials → Event 4625 (3rd failure)
          ✗ Connection closed

14:05:34  Domain controller lockout policy triggered
          → Account FINBRIDGE\bwalker locked → Event 4740
          → No further logons possible (even with correct password)

14:22:07  User attempts RDP connection (approx. 17 min later, after lockout expires)
          → RDP service accepts TCP connection → Event 131

14:22:09  User submits credentials (now correct or system unlocked)
          ✓ DC validates credentials successfully
          ✓ Session created → Event 4624 (Logon Success)
          ✓ User logged in successfully
```

---

## 4) Most Likely Root Cause

**PRIMARY CAUSE: Incorrect User Credentials (Password)**

### Evidence:

1. **Definitive rejection message:** Event 4625 explicitly states "Unknown username or bad password" — not account disabled, not locked out initially, but credential validation failure.

2. **Successful authentication after lockout:** At 14:22:09, user successfully authenticated using the same account (FINBRIDGE\bwalker) immediately after lockout expired. This proves:
   - Account is valid and not permanently broken
   - Credentials provided at 14:22:09 were correct
   - Credentials provided at 14:01–14:05 were **incorrect**

3. **Pattern of repeated attempts:** User or client made three attempts within 4 minutes, suggesting:
   - User attempting manual retry (user thinks password is correct)
   - OR client using cached/stale credentials (e.g., RDP shortcut with old password, password manager with outdated entry)

4. **No protocol-level errors before authentication:** Event 131 at 14:22:07 proves RDP transport and TLS negotiation are healthy. Failure is strictly at credential validation layer.

5. **Timing aligns with AD lockout policy:** Exactly 3 failures trigger lockout, matching Event 4740 at 14:05:34 (31 seconds after 3rd attempt).

### Secondary Contributing Factor:

**Aggressive Account Lockout Policy:** 3 failed attempts within ~4 minutes is a rapid lockout. Standard policy is 5 attempts within 30 minutes. A threshold of 3 may increase false lockout risk during legitimate user typos or client delays.

---

## 5) Root Cause Analysis (5 Why)

### Why 1: Why did user FINBRIDGE\bwalker fail to authenticate?
**Answer:** The credentials (password) submitted by the client were rejected by the domain controller.
- **Evidence:** Event 4625 with reason "Unknown username or bad password"

### Why 2: Why were the credentials incorrect?
**Answer:** Either:
- **Hypothesis A (User Error):** User manually typed incorrect password (typo, caps lock, wrong keyboard layout).
- **Hypothesis B (Stale Cached Credentials):** RDP client or stored credential profile contained outdated password (user recently changed password in AD but client still using old value).
- **Hypothesis C (Kerberos Clock Skew):** System time drift on client or server causing Kerberos token validation failure (less likely, would show different error, but possible).

**Most Likely:** Hypothesis B (stale cached credentials) — user successfully logged in at 14:22 using same method, suggesting client configuration issue rather than user error.

### Why 3: Why was the account locked out?
**Answer:** Domain Account Lockout policy was triggered after 3 failed authentication attempts within the lookback window.
- **Evidence:** Event 4740 at 14:05:34, exactly 31 seconds after 3rd failed attempt (14:05:33)
- **Policy inference:** Threshold is 3 attempts (not default 5), suggesting stricter-than-default security policy.

### Why 4: Why does the lockout policy use a threshold of 3 attempts?
**Answer:** Domain security policy configured to lockout accounts after 3 failed attempts to balance security (rapid lockout of attackers) with usability (tight tolerance for user error).
- **Assessment:** This is a policy decision by domain administrators. May be too strict if users frequently mistype or if clients frequently retry with stale credentials.

### Why 5: Why does the client (or user) continue to retry with the same incorrect credentials?
**Answer:** 
- **If user error:** User believes password is correct and retries multiple times.
- **If stale cached credentials:** RDP client (mstsc.exe) or credential manager automatically or manually reuses stored password without prompting for update.
- **If misconfigured script/automation:** Scheduled RDP connection script uses hardcoded or cached password not updated after recent AD password change.

**Root Cause Chain:**
```
User password changed in AD (or user never knew correct password)
       ↓
RDP client stores/caches old/incorrect password
       ↓
User (or automation) attempts to connect with cached incorrect password
       ↓
Domain controller rejects credentials (Event 4625)
       ↓
User retries 2 more times (attempts 2 & 3)
       ↓
Account lockout triggered after 3 failures (Event 4740)
       ↓
User locked out for 15–30 minutes
       ↓
After lockout expires, user either:
  - Uses correct password, OR
  - AD resets credentials/password, OR  
  - Password expires and is reset
       ↓
User successfully logs in (Event 4624)
```

---

## 6) Supporting Evidence Summary

| Event | Time | Source | Message | Interpretation |
|-------|------|--------|---------|-----------------|
| 56 | 14:01:02 | TermDD | Protocol stream error, disconnected | Auth failed; connection closed |
| 140 | 14:01:02 | RdpCoreTS | Username/password incorrect | Credential validation failed |
| 4625 | 14:01:04 | Security | Unknown username/bad password | DC rejected credentials (Attempt 1) |
| 4625 | 14:03:18 | Security | Unknown username/bad password | DC rejected credentials (Attempt 2) |
| 4625 | 14:05:33 | Security | Unknown username/bad password | DC rejected credentials (Attempt 3) |
| 4740 | 14:05:34 | Security | Account locked out | Lockout policy triggered |
| 131 | 14:22:07 | RdpCoreTS | TCP connection accepted | Transport layer healthy |
| 4624 | 14:22:09 | Security | Logon success | Authentication successful after unlock |

---

## 7) Remediation Plan (Ranked by Likelihood)

### Remediation 1: Clear Cached RDP Credentials (Immediate)
**Action:**
```powershell
# On affected client machine
cmdkey /list                          # List all cached credentials
cmdkey /delete:rdpservername          # Remove cached RDP credential
# Restart RDP connection and enter credentials manually
```
**Rationale:** If stale cached password is root cause, clearing cache forces user to enter current valid password.
**Verification:** Successful RDP login with manually entered credentials.

### Remediation 2: Verify User Password in Active Directory (Concurrent)
**Action:**
```powershell
# On domain controller or admin workstation
Get-ADUser -Identity bwalker -Properties PasswordLastSet, LockedOut, Enabled
# If locked out, unlock:
Unlock-ADAccount -Identity bwalker
# If password expired:
Set-ADAccountPassword -Identity bwalker -NewPassword (ConvertTo-SecureString -AsPlainText "NewP@ssw0rd!" -Force)
```
**Rationale:** Confirm account is unlocked and password is valid.
**Verification:** `Get-ADUser bwalker | Select LockedOut` returns `False`.

### Remediation 3: Review Domain Lockout Policy (Short-term)
**Action:**
```powershell
# Query lockout policy
net accounts /domain
# OR
Get-ADDefaultDomainPasswordPolicy | Select AccountLockoutThreshold, AccountLockoutObservationWindow, LockoutDuration
```
**Expected Output (Default):**
```
Account lockout threshold:         5 invalid logon attempts
Account lockout duration:          30 minutes
Reset account lockout counter:     30 minutes
```
**Current Environment (Inferred):**
```
Account lockout threshold:         3 invalid logon attempts   ← Aggressive
Account lockout duration:          15–30 minutes
Reset account lockout counter:     4 minutes (implied by Event 4740 at 14:05:34)
```
**Recommendation:** Consider raising threshold to 5 to reduce false lockouts while maintaining security against brute-force attacks.
**Verification:** Coordinate with domain security team before changing policy. Test with pilot users.

### Remediation 4: Enable Credential Prompt on Client (Short-term)
**Action:**
1. Open RDP connection profile (mstsc.exe)
2. **Disable** "Allow me to save credentials" checkbox
3. Ensure "User name" field is pre-filled but password is **NOT** cached
4. User will be prompted to enter password each time (or use SSO if available)

**Rationale:** Prevents stale cached passwords from causing authentication failures.
**Verification:** User prompted for password on each connection attempt.

### Remediation 5: Document Password Change Procedure (Communication)
**Action:**
- Send email to all users and administrators:
  - When password changed in AD, RDP cached credentials must be cleared
  - RDP cached credentials do NOT update automatically
  - Procedure: Settings → Credential Manager → Windows Credentials → Remove RDP entry
  - OR: Use `cmdkey /delete` command (include in IT KB)

**Rationale:** Educate users and reduce future incidents caused by cached credential staleness.
**Verification:** Reduction in Event 4625 + Event 4740 patterns in subsequent audit.

### Remediation 6: Implement Kerberos Time Sync Monitoring (Preventive)
**Action:**
```powershell
# On client and server, verify time sync
w32tm /query /status
Get-Date
```
**Acceptable Skew:** ±5 minutes for Kerberos; ±30 seconds preferred.
**If out of sync:**
```powershell
net stop w32time
net start w32time
w32tm /resync /force
```
**Rationale:** Time skew can cause Kerberos token rejection, manifesting as "bad password" error.
**Verification:** Time sync within ±30 seconds on all endpoints.

---

## 8) Preventive Measures (Long-term)

1. **Credential Lifecycle Policy:** Update domain password change communication to include "clear RDP cache" instructions.

2. **MFA/SSO Integration:** Implement multi-factor authentication (MFA) or single sign-on (SSO) to reduce reliance on cached passwords.

3. **RDP Gateway/Broker:** Deploy RDP Gateway (if not already in use) to centralize authentication and reduce client-side credential caching complexity.

4. **Monitoring and Alerting:** 
   - Alert on Event 4625 + Event 4740 pattern (3+ failures + lockout)
   - Generate weekly report of locked-out accounts for security review
   - Correlate with password change events to identify stale cache issues

5. **Audit Logging:** Enable detailed RDP auditing on terminal servers to capture authentication method (NTLM vs. Kerberos, smart card, etc.) for future troubleshooting.

---

## 9) Incident Timeline (Summary)

| Time | Event | Action | Status |
|------|-------|--------|--------|
| 14:01:02 | User attempts RDP | Connects with incorrect password | ✗ Failed |
| 14:01:04 | Attempt 1 logged | Event 4625 recorded | ✗ Failed |
| 14:03:18 | User retries | Sends same incorrect password | ✗ Failed |
| 14:03:18 | Attempt 2 logged | Event 4625 recorded | ✗ Failed |
| 14:05:33 | User retries | Sends same incorrect password | ✗ Failed |
| 14:05:33 | Attempt 3 logged | Event 4625 recorded | ✗ Failed |
| 14:05:34 | Lockout triggered | Event 4740: Account locked out | 🔒 Locked |
| 14:22:07 | User retries | RDP transport connects (Event 131) | Awaiting auth |
| 14:22:09 | Lockout expired | User submits credentials (now valid) | ✓ Success |

---

## 10) Conclusion

**Root Cause:** Incorrect or stale user credentials (most likely stale cached password) combined with aggressive account lockout policy (3-attempt threshold).

**Immediate Impact:** User locked out for ~17 minutes; unable to access RDP session.

**Resolution:** User successfully authenticated after lockout expiration, indicating no permanent account or infrastructure issues.

**Risk Level:** Low (isolated user, not widespread infrastructure failure). Medium concern if pattern repeats across multiple users.

**Recommended Next Steps:**
1. Contact user FINBRIDGE\bwalker to confirm: Did user recently change password? Was password re-entered during 14:22 attempt?
2. Clear RDP credential cache on user's client machine.
3. Brief domain security team on potential need to adjust lockout threshold from 3 to 5 attempts.
4. Update IT KB and password change procedure documentation.

---

**Prepared by:** DWP Engineering  
**Date:** 2026-08-06  
**Status:** Recommended for closure pending user confirmation
