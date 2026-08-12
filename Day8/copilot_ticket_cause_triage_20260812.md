# Copilot Ticket Cause Triage (DWP Engineer)
**Date:** 2026-08-12

## Ticket 1
**Ticket:** Paralegal asked Copilot to summarise a client NDA in SharePoint and got "I don't have access to that content." The file is in a folder she has never opened before.

- **Likely cause (ranked):**
  1. permissions/access boundary
  2. sensitivity label restriction
  3. data indexing lag
- **Fastest check:** Confirm whether the paralegal can open that exact NDA directly in SharePoint with her own account.
- **Is this actually a Copilot bug?:** **No**. The error explicitly indicates an access boundary, and the user reports the content is in a folder she has not previously accessed.

## Ticket 2
**Ticket:** New associate (started this week): Copilot in Outlook cannot find case emails needed for context.

- **Likely cause (ranked):**
  1. data indexing lag
  2. license/client prerequisite issue
  3. permissions/access boundary
- **Fastest check:** Verify the Copilot license is assigned to the new associate in M365 Admin Center.
- **Is this actually a Copilot bug?:** **No**. For a new starter, indexing lag and provisioning timing are more likely than a platform defect.

## Ticket 3
**Ticket:** Partner saw Copilot surface and summarise a draft settlement from a matter they are not assigned to and did not realize they could access that folder.

- **Likely cause (ranked):**
  1. permissions/access boundary
  2. genuine Copilot fault
- **Fastest check:** Check the partner's effective permissions on that folder/library (including inherited and group-based access).
- **Is this actually a Copilot bug?:** **No**. This most strongly indicates over-permissioned content access; Copilot is typically honoring existing permissions.

## Ticket 4
**Ticket:** Legal ops manager reports all 40 Legal team users suddenly lost Copilot access this morning; it worked last week.

- **Likely cause (ranked):**
  1. license/client prerequisite issue
  2. permissions/access boundary
  3. genuine Copilot fault
- **Fastest check:** Check whether Copilot licenses are still assigned to the Legal user group (or were removed by group-based licensing changes).
- **Is this actually a Copilot bug?:** **Unclear**. A tenant-wide change can be caused by licensing/policy updates or a service incident, so rule out licensing first.

## Ticket 5
**Ticket:** Contract specialist gets vague/generic answers about clauses in the contract templates library; Copilot does not seem to read documents.

- **Likely cause (ranked):**
  1. data indexing lag
  2. permissions/access boundary
  3. sensitivity label restriction
  4. license/client prerequisite issue
- **Fastest check:** Ask Copilot to cite or summarize one specific known template file by exact name, then verify that file is indexed/searchable in SharePoint.
- **Is this actually a Copilot bug?:** **No**. Generic responses usually indicate missing usable grounding content (indexing/access/policy), not a confirmed Copilot defect.
