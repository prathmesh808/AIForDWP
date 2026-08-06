# Structured Triage Summary

## Summary (one line)
Company app installation fails in Company Portal with error 0x87D1041C, indicating a deployment, policy, or local install-state issue to-verify.

## Impact (who/how many/business urgency)
1. Who: One reported end user attempting to install a company app.
2. How many: One reported device/user currently; wider impact to-verify.
3. Business urgency: Medium to high depending on whether the app is required for core duties, to-verify.

## Known facts
1. Install initiated from Company Portal.
2. Installation fails rather than completes.
3. Reported error code is 0x87D1041C.

## Missing information to gather
1. Exact app name, version, and business criticality, to-verify.
2. Whether the same failure occurs after retry and reboot, to-verify.
3. Whether other users/devices can install the same app successfully, to-verify.
4. Device compliance and last successful management check-in status, to-verify.
5. Available disk space and pending restart/update state, to-verify.
6. Whether the user is on expected network path (corporate network/VPN) during install, to-verify.

## Likely catagory
Endpoint management issue in Company Portal app deployment/install flow, to-verify.

## First diagnostic step
Force a manual Company Portal sync/check-in, immediately retry the install, and capture the new install status details to determine whether the failure points to assignment/policy targeting, requirement mismatch, or local install-state, to-verify.
