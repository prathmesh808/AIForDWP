# Logon Failure Incident: Scope-Only Hypothesis

Date: 2026-08-07  
Prepared by: DWP Engineer  
Assessment basis: Scope facts only. No commitment to a single cause yet.

## Scope Facts
- Symptom: User cthompson not able to login.
- Who: cthompson only; one user affected.
- Since: Approximately 08:40 this morning.
- Change: Nil.

## Scope Interpretation
The strongest signal in the scope is the blast radius: one user only. That makes a broad platform outage, tenant-wide authentication issue, or major change-induced regression less likely than a user-specific credential, account state, or endpoint sign-in issue.

## Ranked Likely Causes (Most Probable First)

### 1) Credential mismatch at sign-in
Why this fits the scope facts:
- Single-user impact is most consistent with something specific to cthompson rather than a shared service failure.
- Sudden start at 08:40 with no declared infrastructure change fits a wrong password, stale remembered password, keyboard issue, or unnoticed password change/use of old credentials.
- This is the highest-frequency explanation for an isolated login failure when nothing else is reported broken.

Single fastest check to confirm or eliminate it:
- Attempt one controlled sign-in with a known-good password, or verify in sign-in logs whether the failure reason is bad username/password.

### 2) Account lockout
Why this fits the scope facts:
- Account lockout naturally affects one user only.
- It can start suddenly in the morning if the user made repeated attempts, or if a saved credential on one device began replaying failures.
- No reported change is required for this to happen.

Single fastest check to confirm or eliminate it:
- Check the account status in Active Directory or Entra ID to see whether cthompson is currently locked out.

### 3) Account state issue such as expired password, disabled account, or sign-in restriction
Why this fits the scope facts:
- These conditions are highly user-specific and align with a one-user-only symptom.
- They can appear to start "this morning" if a password expiry threshold, scheduled restriction, or admin action took effect overnight even when no broader service change occurred.
- This remains plausible because the scope says only that the user cannot log in, not what error message they receive.

Single fastest check to confirm or eliminate it:
- Review the account properties for password expiry, disabled state, hours restrictions, and any sign-in policy blocks on cthompson.

### 4) Device-side sign-in issue on the user's endpoint
Why this fits the scope facts:
- If cthompson is failing only from one workstation or laptop, the blast radius would still be exactly one user.
- Cached credential corruption, local profile issues, broken trust to the domain at the endpoint, or network path problems to authentication services can all present as "cannot login."
- No formal change record is needed for a local sign-in path failure to begin mid-morning.

Single fastest check to confirm or eliminate it:
- Have cthompson try the same account from a different known-good device or sign-in path and compare the result.

### 5) Identity replication or backend authentication inconsistency affecting only this account
Why this fits the scope facts:
- Lower probability than the causes above, but still compatible with a single-user symptom if one account object is out of sync or being evaluated inconsistently.
- The sudden timing fits a backend inconsistency becoming visible when the user first signs in this morning.
- This is ranked lower because there is no wider blast radius and no change signal.

Single fastest check to confirm or eliminate it:
- Compare the latest authentication attempts across the authoritative identity source and the domain controller or sign-in service handling the request for mismatch or replication delay.

## Current Position
- Do not commit to one cause yet.
- Start with the checks in ranked order because they eliminate the most common and fastest-resolving isolated-user causes first.

## Recommended First Triage Sequence
1. Confirm the exact failure message and whether the issue occurs on only one device.
2. Check for bad password vs lockout in authentication logs.
3. Check account state: locked, disabled, expired, or restricted.
4. If account state is healthy, test from a second known-good endpoint.
5. Only then investigate replication or backend inconsistency.

---

## Evidence Review Against Each Hypothesis

Evidence window reviewed: 2024-03-15 08:44-09:12 on DESKTOP-FB022 security log, with related authentication events for FINBRIDGE\cthompson.

### 1) Credential mismatch at sign-in
Judgement: Supported

Determining event(s):
- 08:44:01 - Event 4776 - Error code 0xC000006A (wrong password) for FINBRIDGE\cthompson from DESKTOP-FB022.
- 08:44:03 - Event 4625 - Interactive logon failure with reason "Unknown user name or bad password" from DESKTOP-FB022.
- 08:45:44 - Event 4771 - Kerberos pre-authentication failed with code 0x18 (wrong password) from source IP 10.10.8.112.

Why this judgement:
- The logs explicitly record wrong-password failures in both credential validation and interactive logon paths.
- The repeated bad-password pattern across Event 4776, Event 4625, and Event 4771 is directly consistent with the hypothesis.

### 2) Account lockout
Judgement: Supported

Determining event(s):
- 08:44:56 - Event 4740 - User account FINBRIDGE\cthompson locked out; caller computer DESKTOP-FB022.
- 08:45:10 - Event 4625 - Unlock attempt failed with reason "Account locked out" from DESKTOP-FB022.

Why this judgement:
- The evidence confirms the account entered a locked state during the incident window.
- After the lockout occurred, at least part of the ongoing login failure symptom is directly explained by the locked account state.

### 3) Account state issue such as expired password, disabled account, or sign-in restriction
Judgement: Contradicted

Determining event(s):
- 08:44:01 - Event 4776 - Error code 0xC000006A (wrong password).
- 08:44:03 - Event 4625 - Failure reason "Unknown user name or bad password."
- 08:44:56 - Event 4740 - Account locked out.

Why this judgement:
- The failure codes point to bad credentials, not password expiry, disabled account, or policy/time restriction.
- The fact that the account was processed and then locked out indicates the identity existed and was being evaluated normally, which argues against disabled-or-restricted-state explanations for the primary symptom.

### 4) Device-side sign-in issue on the user's endpoint
Judgement: Neutral

Determining event(s):
- 08:44:03 - Event 4625 - Interactive logon failure from DESKTOP-FB022.
- 08:44:28 - Event 4625 - Interactive logon failure from DESKTOP-FB022.
- 08:45:44 - Event 4771 - Wrong-password Kerberos pre-authentication failure from source IP 10.10.8.112, which differs from DESKTOP-FB022.

Why this judgement:
- The interactive failures from DESKTOP-FB022 mean the endpoint is part of the incident path.
- However, the separate wrong-password events from 10.10.8.112 mean the evidence does not isolate the problem to the user's workstation alone.
- The logs support that DESKTOP-FB022 was one source of failed attempts, but they do not specifically prove a device-side fault such as trust break, cache corruption, or local sign-in subsystem issue.

### 5) Identity replication or backend authentication inconsistency affecting only this account
Judgement: Contradicted

Determining event(s):
- 08:44:01 - Event 4776 - Wrong-password result 0xC000006A.
- 08:45:44 - Event 4771 - Wrong-password result 0x18.
- 08:44:56 - Event 4740 - Account lockout recorded.

Why this judgement:
- The authentication systems are returning a consistent and specific outcome: wrong password, followed by lockout.
- That pattern is not what would usually indicate replication delay or inconsistent backend evaluation; it suggests the backend understood the account state and enforced it consistently.

## Position After Evidence Review
- Do not select a winner yet.
- The evidence narrows the field materially: hypotheses 1 and 2 are supported, hypothesis 4 remains possible but unproven, and hypotheses 3 and 5 are contradicted by the observed event pattern.