# Structured Triage Summary

## Ticket
- T-1008

## Summary (one line)
VPN reports connected but no internal resources are reachable after Win11 upgrade, indicating probable post-upgrade routing or name-resolution path issue (to-verify).

## Impact (who/how many/business urgency)
- Who is impacted: Reported remote user on upgraded Win11 device
- How many affected: One reported user/device currently (to-verify if wider upgrade/VPN cohort impact)
- Business urgency: High for remote access users blocked from internal systems

## Known Facts
- Ticket ID: T-1008
- VPN state: Connects successfully
- Symptom: Internal resources are not reachable
- Timing context: Issue appeared after Win11 upgrade

## Missing Information To Gather
- Whether failure affects all internal resources or specific hosts/services (to-verify)
- Whether issue is name resolution only or both name/IP connectivity (to-verify)
- Whether same user can reach internal resources from another device/network path (to-verify)
- Whether split tunnel/full tunnel policy is expected for this user profile (to-verify)
- Whether other recent Win11-upgraded VPN users report similar symptoms (to-verify)

## Likely Category
- Remote access / VPN post-upgrade connectivity and DNS/routing issue (to-verify)

## First Diagnostic Step
- With VPN connected, run a basic internal connectivity baseline (test both internal name resolution and direct internal IP reachability) to determine whether the immediate fault domain is DNS, routing, or access policy path after upgrade (to-verify).
