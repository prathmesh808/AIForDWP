# Structured Triage Summary

## Ticket
- T-1007

## Summary (one line)
OneDrive is stuck on "processing changes" since migration and files are missing locally, suggesting sync state divergence between cloud and endpoint cache (to-verify).

## Impact (who/how many/business urgency)
- Who is impacted: Reported end user relying on OneDrive files
- How many affected: One reported user/device currently (to-verify if broader migration cohort affected)
- Business urgency: High where missing local files block active work

## Known Facts
- Ticket ID: T-1007
- Platform: OneDrive
- Symptom 1: Client stuck on "processing changes"
- Symptom 2: Files missing locally
- Context: Issue reported since migration

## Missing Information To Gather
- Whether files are present in OneDrive web but missing only on local device (to-verify)
- Whether OneDrive account sign-in and tenant are correct post-migration (to-verify)
- Whether sync status shows specific folder/path errors or conflict indicators (to-verify)
- Local storage availability and Files On-Demand behavior on affected folders (to-verify)
- Whether issue affects a specific library/path set or all synced content (to-verify)

## Likely Category
- File sync / OneDrive post-migration synchronization issue (to-verify)

## First Diagnostic Step
- Confirm source-of-truth by checking affected files in OneDrive web first, then review OneDrive sync health/status on the device to determine whether this is local sync-client state, account mapping, or migration content scope related (to-verify).
