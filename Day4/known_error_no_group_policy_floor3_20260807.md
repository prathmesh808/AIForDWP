Symptom     : On affected devices, users experienced "No Group Policy" processing at startup/sign-in. Group Policy retrieval failed because the client could not reach required domain resources.

Cause       : The verified root cause was stale DHCP scope DNS configuration on the Floor 3 subnet. DHCP option 006 still referenced decommissioned DNS infrastructure, causing DC name-resolution failure and loss of SYSVOL/GPO access.

Scope       : 3 of 4 Windows 11 machines in OU=Finance on Floor 3 were affected during the incident window. One device (FB058) was unaffected because DNS was manually pre-configured to 10.10.0.10 before migration.

Workaround  : Use the correct DNS resolver value (10.10.0.10) on affected endpoints to restore domain name resolution and policy processing. In this incident, corrected DNS assignment enabled successful Group Policy processing.

Permanent fix: Updated DHCP scope option 006 for the Floor 3 subnet to 10.10.0.10 and removed stale/decommissioned DNS entries. Renewed/reissued affected client leases so endpoints received corrected DNS settings.

How to spot it: Look for Netlogon 5719, DNS Client 1014, and GroupPolicy 1058/1030/1129 during startup/sign-in, including messages such as "no domain controller available," DNS timeout/no response, and SYSVOL access failure (gpt.ini, error 0x3). Confirm recovery with GroupPolicy Event 1500 ("Group Policy settings processed successfully") and DHCP Client Event 50036 showing DNS 10.10.0.10.
