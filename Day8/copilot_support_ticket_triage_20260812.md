# Copilot Support Ticket Triage
**Date:** 2026-08-12  
**Engineer role:** DWP Engineer  
**Scope:** Microsoft 365 Copilot support tickets — structured triage

---

## Triage Key

| Cause Category | Description |
|---|---|
| Permissions/access boundary | User or Copilot service lacks permission to the resource |
| Data indexing lag | Content not yet indexed by Microsoft Search / semantic index |
| Sensitivity label restriction | Label policy blocks Copilot from processing the content |
| License/client prerequisite issue | Missing or unassigned Copilot licence, or unsupported client version |
| Guest/external sharing limitation | Cross-tenant or guest-link content is outside Copilot's boundary |
| Genuine Copilot fault | Verified platform defect — last resort only |

---

## Ticket 1

**Reported by:** Finance lead  
**Symptom:** Copilot won't summarise the Q3 board pack in SharePoint. "It's right there, I can see it myself."

| Field | Assessment |
|---|---|
| **Likely cause (ranked)** | 1. Sensitivity label restriction — board packs are high-value documents frequently labelled Confidential/Highly Confidential, which can block Copilot processing<br>2. Permissions/access boundary — the user's visible access may be via a link-share or legacy permission that Copilot's service account does not honour<br>3. Data indexing lag — if the file was recently uploaded or moved, the semantic index may not yet cover it |
| **Fastest check** | Open the file in SharePoint and inspect the sensitivity label banner. If a Confidential or higher label is applied, check whether the tenant's Copilot label policy permits processing at that classification. |
| **Is this actually a Copilot bug?** | No — sensitivity label restrictions and access-boundary gaps are the expected explanation. No evidence of a platform defect. |

---

## Ticket 2

**Reported by:** New hire (started yesterday)  
**Symptom:** Copilot in Outlook seems to know nothing about my recent emails.

| Field | Assessment |
|---|---|
| **Likely cause (ranked)** | 1. Data indexing lag — a brand-new mailbox has little or no content indexed by the Microsoft 365 semantic index; full indexing typically takes 24–72 hours<br>2. License/client prerequisite issue — the Copilot licence may not yet have been assigned as part of onboarding provisioning |
| **Fastest check** | Confirm the Copilot for Microsoft 365 licence is assigned to the user in the M365 Admin Centre (Users → Active users → Licences). If assigned, advise the user to wait 24–72 hours for indexing to complete. |
| **Is this actually a Copilot bug?** | No — indexing lag for new accounts is expected behaviour, not a defect. |

---

## Ticket 3

**Reported by:** HR manager  
**Symptom:** Asked Copilot in Word to pull data from a sensitive salary review spreadsheet; received "I don't have access to that content."

| Field | Assessment |
|---|---|
| **Likely cause (ranked)** | 1. Sensitivity label restriction — salary review files are routinely labelled at a high classification; if the label policy excludes Copilot grounding, this error is expected and by design<br>2. Permissions/access boundary — the spreadsheet may reside in a site or library where the HR manager's effective permissions are read-only through a group, and Copilot enforces item-level permissions strictly |
| **Fastest check** | Check the sensitivity label on the Excel file. If it is Confidential or Highly Confidential, verify the Copilot label policy in Microsoft Purview (Information Protection → Sensitivity labels → Copilot settings) to confirm whether that label tier is permitted for Copilot grounding. |
| **Is this actually a Copilot bug?** | No — the error message is the correct Copilot response when a label or permission boundary is enforced. |

---

## Ticket 4

**Reported by:** Sales rep  
**Symptom:** Copilot in Teams can't find a client contract that was shared via a guest link from another organisation.

| Field | Assessment |
|---|---|
| **Likely cause (ranked)** | 1. Guest/external sharing limitation — Copilot does not index or ground responses on content shared via external guest links or cross-tenant shares; only content within the user's own tenant index is in scope |
| **Fastest check** | Confirm the file's origin: if the share link points to the external org's SharePoint or OneDrive tenant, Copilot cannot access it by design. Advise the user to request the file be copied into their own tenant SharePoint library. |
| **Is this actually a Copilot bug?** | No — cross-tenant guest-link content is explicitly outside Copilot's grounding boundary; this is expected behaviour. |

---

## Ticket 5

**Reported by:** IT admin  
**Symptom:** Copilot suddenly stopped working for the whole Finance team this morning; was fine yesterday.

| Field | Assessment |
|---|---|
| **Likely cause (ranked)** | 1. License/client prerequisite issue — a licence assignment change, group-based licence removal, or an automated licence reconciliation job overnight may have removed the Copilot licence from the Finance security group<br>2. Permissions/access boundary — a group policy or Conditional Access change overnight may be blocking the Copilot service principal<br>3. Genuine Copilot fault — a tenant-scoped service incident is possible if the above are ruled out, but must be checked last |
| **Fastest check** | In M365 Admin Centre, filter active users by the Finance department and check Copilot licence assignment status. Also check the M365 Service Health dashboard for any active Copilot incidents affecting the tenant. |
| **Is this actually a Copilot bug?** | Unclear — a team-wide sudden outage could indicate either a licence/policy change or a genuine service incident. Licence check and Service Health should be verified before escalating to Microsoft. |

---

## Ticket 6

**Reported by:** Manager  
**Symptom:** Copilot found and summarised a file the manager does not remember opening, from a folder they forgot they had access to.

| Field | Assessment |
|---|---|
| **Likely cause (ranked)** | 1. Permissions/access boundary — Copilot correctly respects the user's existing permissions; if the manager has legitimate access to the folder (via group membership, inherited site permissions, etc.), Copilot is permitted to surface that content. This is working as designed. |
| **Fastest check** | Review the manager's effective permissions on the folder in SharePoint (Site Settings → Site permissions → Check permissions for user). Confirm access is legitimate and not the result of over-provisioning. |
| **Is this actually a Copilot bug?** | No — Copilot surfacing content the user has permission to access is correct behaviour. If the access itself is unintended, the issue is an over-permissioned SharePoint structure, not a Copilot defect. |

---

## Ticket 7

**Reported by:** Analyst  
**Symptom:** Copilot gives generic answers and does not appear to use any internal SharePoint content.

| Field | Assessment |
|---|---|
| **Likely cause (ranked)** | 1. License/client prerequisite issue — the user may have a standard M365 licence without the Copilot for Microsoft 365 add-on; without it, Copilot operates in web-grounded mode only and cannot access tenant content<br>2. Permissions/access boundary — the analyst may not have been granted access to the relevant SharePoint sites, so there is nothing tenant-specific to ground on<br>3. Data indexing lag — if the analyst's account or the SharePoint content is newly provisioned, the semantic index may not yet be populated |
| **Fastest check** | Confirm the Copilot for Microsoft 365 licence is assigned (M365 Admin Centre). If assigned, verify the analyst has at least read access to one or more SharePoint sites containing internal content. |
| **Is this actually a Copilot bug?** | No — generic responses without tenant grounding are the expected behaviour when the licence is missing or no accessible indexed content exists. |

---

## Ticket 8

**Reported by:** Executive assistant  
**Symptom:** Copilot in Outlook cannot see a shared mailbox calendar that the EA manages on behalf of the director.

| Field | Assessment |
|---|---|
| **Likely cause (ranked)** | 1. Permissions/access boundary — Copilot grounds Outlook interactions on the signed-in user's own mailbox index; delegate/shared mailbox calendars are a separate mailbox object and are not automatically included in the user's Copilot grounding scope<br>2. License/client prerequisite issue — the shared mailbox itself does not hold a Copilot licence; Copilot does not process shared mailbox data unless the delegate's own licence and explicit configuration permits it |
| **Fastest check** | Check whether the shared mailbox has a Copilot licence assigned. Shared mailboxes used by Copilot-licensed delegates still require the mailbox to be within the grounding boundary — verify this in the M365 Admin Centre and review Microsoft's current shared mailbox support guidance for Copilot. |
| **Is this actually a Copilot bug?** | No — Copilot's inability to access delegate/shared mailbox calendars reflects a documented access boundary, not a platform defect. |

---

*Document generated by DWP Engineer triage session — 2026-08-12*
