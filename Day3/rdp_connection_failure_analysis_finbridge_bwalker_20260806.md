# RDP Connection Failure Analysis - FINBRIDGE\\bwalker

Date: 2026-08-06  
Incident Window: 2024-03-15 14:01:02 to 14:22:09  
Source Client IP: 10.10.5.44

## Distinct Error Codes/Signals Present

1. Event ID 56 (TermDD, System): protocol stream/security layer disconnect.
2. Event ID 140 (RemoteDesktopServices-RdpCoreTS, System): connection failed due to incorrect username/password.
3. Event ID 4625 (Security): failed logon (Logon Type 10, RemoteInteractive), reason shown as unknown username or bad password.
4. Event ID 4740 (Security): account locked out.

Notes:
- Event ID 131 and Event ID 4624 are not failures; they indicate later successful connection/logon.
- No NTSTATUS substatus/error hex value (for example 0xC000006A or 0xC0000064) is included in the provided lines, so exact credential-failure subtype cannot be stated with certainty from this data alone.

## Ranked Remediation Plan (Most Likely Fix First)

1. Clear cached or incorrect credentials on source client 10.10.5.44.
   - Specific check: Remove saved RDP credentials in Credential Manager or with cmdkey, reconnect using explicit FINBRIDGE\\bwalker (or UPN), then confirm no new Event 4625 appears from source IP 10.10.5.44.

2. Unlock account and validate lockout-threshold behavior.
   - Specific check: On domain controller security logs, confirm Event 4740 lockout source/caller aligns to 10.10.5.44, unlock account, and verify bad-password count resets after successful sign-in.

3. Validate AD account state and password validity.
   - Specific check: Confirm user is not disabled/expired/restricted and test one interactive authentication from a known-good endpoint.

4. Check for background processes on 10.10.5.44 replaying old credentials.
   - Specific check: Inspect mapped drives, scheduled tasks, services, Outlook/mobile clients, and saved Windows credentials; after password reset, monitor whether Event 4625/4740 recur without manual RDP attempts.

5. Investigate Event 56 as a secondary protocol/TLS symptom if failures continue after credential fixes.
   - Specific check: Correlate timestamp-adjacent Schannel/RDP TLS events, verify NLA/TLS configuration compatibility, and retest with an updated RDP client.
   - Uncertainty statement: Event 56 is broad; in this sequence it is likely secondary to authentication failure, but this must be verified against Microsoft documentation.

6. Verify time sync and name-resolution path (lower likelihood, quick elimination).
   - Specific check: Confirm client/server/DC clock skew is within Kerberos tolerance and DNS/DC resolution is correct; retest RDP.

## Evidence-Based Interpretation

The observed sequence is consistent with repeated credential failure leading to lockout, followed by later success:
- Multiple Event 4625 failures
- Event 4740 lockout
- Later Event 4624 success

This strongly prioritizes credential and lockout remediation first, then protocol-level troubleshooting.

## Items to Verify Against Microsoft Documentation

- TermDD Event ID 56 precise meaning in your OS build and whether Microsoft documents it as generic or condition-specific.
- Exact Security Event 4625 Status/SubStatus mapping for this incident (if available in full event XML/details) to distinguish bad password versus unknown user.
- Recommended NLA/TLS baseline and related RDP Core/Schannel event correlation guidance for your Windows version.
