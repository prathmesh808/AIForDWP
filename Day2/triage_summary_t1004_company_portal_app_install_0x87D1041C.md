# Structured Triage Summary

## Ticket
- T-1004

## Summary (one line)
Company app fails to install from Company Portal with error 0x87D1041C, indicating an app deployment or client compliance/install-state issue (to-verify).

## Impact (who/how many/business urgency)
- Who is impacted: Reported user attempting to install a company app
- How many affected: One reported user/device at present (to-verify if wider app deployment impact)
- Business urgency: Medium to High depending on app criticality for daily role tasks (to-verify)

## Known Facts
- Ticket ID: T-1004
- Channel: Company Portal
- Symptom: App installation fails
- Reported error code: 0x87D1041C

## Missing Information To Gather
- Exact app name and version targeted for installation (to-verify)
- Whether failure occurs on one device or multiple devices/users (to-verify)
- Device compliance and check-in status at time of install attempt (to-verify)
- Available storage and pending restart state on affected device (to-verify)
- Whether the same app installs successfully for a known-good user/device cohort (to-verify)

## Likely Category
- Endpoint management / Intune Company Portal app deployment failure (to-verify)

## First Diagnostic Step
- Initiate a fresh Company Portal sync/check-in and immediately retry install while capturing the updated install status details to determine whether the failure is assignment, requirement, or local install-state related (to-verify).
