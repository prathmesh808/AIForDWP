# Structured Triage Summary

## Ticket
- T-1001

## Summary (one line)
New Windows 11 laptop prompts for BitLocker recovery key on every boot, indicating repeated pre-boot trust validation failure (to-verify root cause).

## Impact (who/how many/business urgency)
- Who is impacted: Single end user on a new Win11 laptop (to-verify if additional users/devices affected)
- How many affected: One reported device/user at present (to-verify)
- Business urgency: High user productivity impact due to repeated recovery interruptions at startup; potential service desk volume risk if pattern is wider (to-verify)

## Known Facts
- Ticket ID: T-1001
- Device context: New Windows 11 laptop
- Symptom: BitLocker recovery key prompt appears every boot
- Recurrence: Not a one-off event; repeats on each startup

## Missing Information To Gather
- Whether the correct recovery key successfully unlocks the device each time (to-verify)
- Whether any recent firmware/BIOS/UEFI changes were applied after provisioning (to-verify)
- Whether Secure Boot and TPM are enabled and healthy in firmware and OS views (to-verify)
- Whether startup configuration has changed since first successful boot (to-verify)
- Whether device was recently docked/undocked or had hardware changes (to-verify)
- Whether the issue started immediately from day one or after updates/policy application (to-verify)
- Whether similar incidents are being reported on same hardware model/build cohort (to-verify)

## Likely Category
- Endpoint security / BitLocker startup recovery loop (to-verify)

## First Diagnostic Step
- Capture and validate the exact pre-boot recovery prompt details on next boot (recovery key ID and prompt context), then in Windows collect a baseline of BitLocker and TPM status to confirm whether the protector state and platform trust chain are changing between boots (to-verify).
