# Closure Note — Finance Shared Drive Access Failure

Date: 2026-08-07  
Incident: All Finance users (45 users, DESKTOP-FB*, OU=Finance) unable to access shared drive S: (`\\finbridge-fs01\Finance`) from ~08:00.

---

Resolved. Cause: `Map-FinBridgeDrives.ps1` deployed via Intune executed as SYSTEM before the Workstation service (LanmanWorkstation) had entered running state — UNC path resolution failed with error 53 at 08:00:03; Workstation service did not start until 08:00:05. Defect introduced 2024-03-14 when drive mapping was migrated from GPO logon script (USER context) to Intune Platform Script (SYSTEM context) without updating the script or validating functionality in the new context. Action: Changed Intune Platform Script setting "Run this script using the logged on credentials" from No (SYSTEM) to Yes (logged-on user) for `Map-FinBridgeDrives.ps1`; incremented script version to force re-run on all affected DESKTOP-FB* devices; pushed device sync via Intune. Preventive: Harden `Map-FinBridgeDrives.ps1` with a Workstation service readiness guard; audit all Intune Platform Scripts running as SYSTEM that perform UNC operations; add execution-context functional validation as a mandatory gate on any GPO-to-Intune script migration change record; create KEDB entry for SYSTEM-context error 53 drive mapping pattern. User confirmed working.
