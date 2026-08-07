# End User Communication — Logon Failure / Account Lockout

Date: 2026-08-07  
Incident reference: INC-20260807-CTHOMPSON

## Audience 1 — Non-technical executive

Your access is restored and your data are safe. One user, cthompson, could not sign in from 08:44 to 09:09 after repeated incorrect password attempts locked the account; another source was also trying the wrong password. Helpdesk restored the account at 09:08, and the user signed in successfully at 09:09 on DESKTOP-FB022 with no further issues reported. No action is needed unless the issue returns.

## Audience 2 — Affected end-user team

cthompson could not sign in from 08:44 to 09:09 because repeated wrong password attempts locked the account, and another source was also trying the wrong password. Helpdesk restored the account at 09:08, and cthompson signed in successfully at 09:09 on DESKTOP-FB022 with no further issues reported. If you see the same issue, stop trying to sign in repeatedly and contact the Service Desk.

## Audience 3 — Engineer-to-engineer internal note

Root cause: repeated wrong-password auth attempts for FINBRIDGE\cthompson caused account lockout, which blocked further interactive logon until admin intervention. Contributing context: a second source also submitted wrong credentials after lockout.

Supporting detail:
- Primary host: DESKTOP-FB022.
- Secondary source: 10.10.8.112.
- Failure window: 08:44 to 09:09.
- 08:44:01 Event 4776 on DESKTOP-FB022 returned `0xC000006A` (wrong password).
- 08:44:03, 08:44:28, 08:44:55 Event 4625 interactive failures on DESKTOP-FB022 showed bad password.
- 08:44:56 Event 4740 locked FINBRIDGE\cthompson from caller computer DESKTOP-FB022.
- 08:45:10 Event 4625 logon type 7 failed because account was locked out.
- 08:45:44, 08:46:01, 08:46:33 Event 4771 from 10.10.8.112 returned `0x18` (wrong password).

Exact action taken:
- 09:08:14 Event 4722: account enabled by FINBRIDGE\helpdesk-admin.

Verification step:
- 09:09:01 Event 4624: successful interactive logon for FINBRIDGE\cthompson on DESKTOP-FB022.
- User verified working access; no further issues reported.

Preventive action needed:
- Identify what is using 10.10.8.112 and remove or update cached/saved credentials for cthompson.
- Review 4740 and 4771 for recurrence.
- Confirm account lockout threshold is in policy and operationally acceptable.
- Consider self-service unlock to shorten recovery for isolated lockouts.