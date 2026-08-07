Symptom     : Users see a black screen immediately after login on POOL-FIN-01. Some sessions recover after about 30 seconds, while others disconnect or remain unusable.

Cause       : A graphics stack regression introduced by the 02:00 image update on POOL-FIN-01 caused repeated dwm.exe crashes in igdumd64.dll with exception 0xc0000005 during post-logon desktop composition. These crashes triggered DWM termination and session disconnects.

Scope       : The issue affected POOL-FIN-01 and impacted approximately 40% of users assigned to that pool between about 07:00 and 10:00. POOL-FIN-02 was unaffected.

Workaround  : Restrict or drain new sessions on unstable POOL-FIN-01 hosts and route users to POOL-FIN-02 where capacity permits. Apply software-rendering mitigation on affected hosts and reboot in controlled waves before returning hosts to service.

Permanent fix: Correct the POOL-FIN-01 image graphics stack and driver path using a validated stable version, replacing unstable Intel graphics component version 31.0.101.4146. Validate host behavior post-change before full return to normal routing.

How to spot it: Look for the repeating sequence after logon: LSM Event 21 (logon succeeded), Application Error Event 1000 (dwm.exe faulting module igdumd64.dll, 0xc0000005), DWM Event 9009 (Desktop Window Manager exited), and LSM Event 40 (session disconnected). In unaffected comparison hosts, DWM Event 9011 appears with no matching Application Error Event 1000 in the incident window.
