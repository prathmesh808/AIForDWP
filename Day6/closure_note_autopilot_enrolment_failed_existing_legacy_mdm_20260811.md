# Closure Note: Autopilot Enrolment Failure — Existing Legacy MDM Enrolment

**Device:** DESKTOP-FB099
**User:** FINBRIDGE\rthomas
**Date:** 2026-08-11

---

Resolved. Cause: A stale legacy manual MDM enrolment record dated 2023-11-04 remained bound to the device context in Intune, conflicting with the Autopilot enrolment and producing error 0x80180014 (device already enrolled in MDM) with 0 of 4 profiles applied. Action: Retired and deleted the stale Intune managed device object; removed the stale Entra device object; confirmed the Autopilot hardware hash record and FinBridge-Autopilot-Standard profile assignment remained intact; disconnected the legacy work account via Settings > Accounts > Access work or school on the endpoint; removed residual local MDM artefacts (scheduled tasks, enrolment registry branches, MDM certificates) per approved runbook; rebooted and completed a clean Autopilot OOBE enrolment; verified device appeared in Intune with current enrolment timestamp, MDM authority set to Microsoft Intune, and FinBridge-Win11-Security-Baseline applied with profiles moving from 0/4 to expected applied count. Preventive: Add a mandatory service desk checklist step requiring a legacy MDM conflict check in both Intune and Entra (retire/delete any stale managed device and Entra device objects) before every Autopilot reset or redeployment, and run a periodic bulk report of devices with legacy manual enrolment markers for proactive remediation. User confirmed working.
