# Copilot End-User Communication Pack (All Tickets)
**Date:** 2026-08-12
**Audience:** End users raising Copilot support tickets

Use the sections below as ready-to-send responses. Each one explains what is happening in plain English and what the user should do next.

---

## Ticket 1: Cannot Summarise NDA in SharePoint ("I don't have access to that content")

Hello,

Thanks for raising this. Copilot can only use files that your account can access directly. In this case, the NDA appears to be in a SharePoint folder you may not currently have access to.

### What this means
This is usually an access/permissions issue, not a Copilot fault.

### Next steps
1. Try opening the exact NDA directly in SharePoint.
2. If the file does not open, request access from the file owner or site owner.
3. After access is granted, retry the same Copilot prompt.
4. If the file opens but Copilot still cannot use it, share the file link with IT so we can check label/policy restrictions.

---

## Ticket 2: New Associate Cannot Find Case Emails in Outlook

Hello,

Thanks for reporting this. For new starters, Copilot may not immediately find mailbox history while indexing and account provisioning complete.

### What this means
This is typically onboarding/indexing delay rather than a Copilot bug.

### Next steps
1. Confirm your Copilot license is assigned.
2. Use Outlook normally for 24 to 72 hours while indexing catches up.
3. Retry with a specific prompt, for example: "Summarise my emails with subject containing <case name> from this week."
4. If still failing after 72 hours, send IT 2 to 3 example email subjects and timestamps for deeper checks.

---

## Ticket 3: Copilot Surfaced Draft from a Matter You Are Not Assigned To

Hello,

Thanks for flagging this. Copilot only returns content your account can already access. If Copilot showed that draft, your account likely has folder access (possibly via inherited or group permissions).

### What this means
This is usually a SharePoint permission scope issue, not a Copilot platform fault.

### Next steps
1. IT will check your effective access on that library/folder.
2. If access is broader than intended, permissions will be corrected.
3. After permissions are updated, Copilot results should reflect the new access boundary.
4. If access is correct but behavior remains unexpected, IT will escalate with evidence.

---

## Ticket 4: Entire Legal Team Lost Copilot Access Suddenly

Hello,

Thanks for reporting this quickly. When an entire team is affected at once, the most common causes are license assignment changes or policy/configuration changes.

### What this means
This may be a tenant configuration issue; a Copilot service issue is possible but not the first assumption.

### Next steps
1. IT will verify Copilot license assignment for all impacted users.
2. IT will check for recent group-based licensing or access policy changes.
3. IT will review Microsoft 365 Service Health for active incidents.
4. We will share a status update once these checks complete and provide an ETA for restoration.

---

## Ticket 5: Copilot Gives Generic Answers for Contract Templates

Hello,

Thanks for the detail. Generic responses usually mean Copilot cannot reliably ground on the template library content yet.

### What this means
Most often this is indexing/access/policy related rather than a Copilot bug.

### Next steps
1. Try a prompt with one exact template filename.
2. Confirm you can open that template directly in SharePoint.
3. If accessible, wait for indexing to complete and retry.
4. If still generic, IT will check sensitivity label rules and tenant search/index status for the library.

---

## Standard Closing Message

If your issue is still not resolved after the steps above, reply with:
1. The exact Copilot prompt used.
2. Screenshot or exact error text.
3. File or email example (name, location, and time).
4. Confirmation whether the content opens directly outside Copilot.

This allows IT to complete a faster root-cause check and escalate with full evidence if needed.
