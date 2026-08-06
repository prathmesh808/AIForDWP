Root cause: Win11 upgrade removed legacy VPN client; Intune did not redeploy new client due to detection-rule gap.
Action taken: Manually removed stale VPN registry entries under HKLM\SOFTWARE\<vendor>, then force-triggered Intune sync.
Config detail: New VPN client deployed; split-tunnel config applied.
Verification: Connectivity confirmed to all internal subnets.
Data impact: No data loss.
Preventive action needed: Close the Intune detection-rule gap so Win11 upgrade scenarios trigger automatic redeployment of the new VPN client.
