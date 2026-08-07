Symptom     : User cthompson was unable to log on interactively to DESKTOP-FB022. During the incident window, a workstation unlock attempt also failed because the account was locked out.

Cause       : Repeated wrong-password authentication attempts for FINBRIDGE\cthompson caused the account to enter a locked-out state, which prevented further successful logon attempts until administrative intervention was applied. Additional wrong-password Kerberos attempts continued from source IP 10.10.8.112 after the lockout.

Scope       : This incident affected one user only: cthompson in the FINBRIDGE domain. The confirmed affected workstation was DESKTOP-FB022, with additional wrong-password authentication activity observed from source IP 10.10.8.112.

Workaround  : Restore the account administratively, as recorded by Event 4722 for FINBRIDGE\helpdesk-admin at 09:08:14. Confirm service restoration by verifying a successful interactive logon, which in this case was Event 4624 at 09:09:01 on DESKTOP-FB022.

Permanent fix: Identify what system was using source IP 10.10.8.112 and remove or update any cached or saved credentials associated with cthompson on that source. Review recent 4740 and 4771 events for recurrence and confirm that account lockout thresholds are aligned with organizational policy and operational tolerance.

How to spot it: Look for Event 4776 with error `0xC000006A` (wrong password), repeated Event 4625 failures showing "unknown user name or bad password," Event 4740 showing the account lockout, and Event 4625 showing "account locked out." In this incident, follow-on Event 4771 entries from 10.10.8.112 with failure code `0x18` (wrong password) were also present after the lockout.