# Microsoft 365 Copilot — Readiness Checklist
**Department:** Finance (~200 users)
**Date:** 2026-08-12
**Sensitivity:** High — payroll, board packs, M&A documents, client financial data
**Status:** Pre-deployment

---

> **Read before proceeding**
> SharePoint permissions for this tenant were inherited from a 2019 migration and have never been
> audited. Copilot surfaces any content the querying user can access — it does not add a permission
> layer, it removes the effort required to find content that is already accessible. Overly permissive
> permissions are therefore the highest-consequence risk in this deployment. **Sections 3 and 4 are
> mandatory blockers. Do not assign Copilot licenses until both sections are signed off.**

---

## Section 1 — Licensing Prerequisites

| # | Check | How to verify | ☐ |
|---|-------|---------------|---|
| 1.1 | All ~200 Finance users hold an active M365 E5 licence | M365 Admin Center → Billing → Licences → filter by user/group | ☐ |
| 1.2 | No users are on F1/F3 or Business plans — these are ineligible for Copilot | Same licence report; confirm no mixed SKUs in the Finance group | ☐ |
| 1.3 | Microsoft 365 Copilot add-on is available in the tenant (purchased, not yet assigned) | M365 Admin Center → Billing → Your products | ☐ |
| 1.4 | A security group exists (or is created) for Finance Copilot licence assignment — do not assign to all 200 at once | Azure AD / Entra ID → Groups | ☐ |
| 1.5 | Pilot group of 10–15 users identified from Finance; members confirmed to have clean permissions (verified in Section 3) | Sign-off from Finance lead | ☐ |

---

## Section 2 — Microsoft 365 Apps Client Version

| # | Check | How to verify | ☐ |
|---|-------|---------------|---|
| 2.1 | All Finance devices are on Microsoft 365 Apps **Version 2307 (Build 16626) or later** — minimum required for Copilot features in Word, Excel, PowerPoint, Outlook, Teams | Intune → Apps → Microsoft 365 Apps → Versions report; or run `Get-AppvClientApplication` / check via winver + Apps version in any Office app → File → Account | ☐ |
| 2.2 | Update channel is **Current Channel** or **Monthly Enterprise Channel** — Semi-Annual Enterprise Channel does not receive Copilot features at parity | Microsoft 365 Apps Admin Center → Inventory → channel distribution | ☐ |
| 2.3 | No devices are running perpetual Office 2019 or 2021 licences — Copilot is not available on perpetual installs | Intune device app inventory or Config Manager software inventory | ☐ |
| 2.4 | Teams desktop client is up to date (new Teams — classic Teams does not support all Copilot in Teams features) | Teams Admin Center → Teams devices or user self-check: Teams → Settings → About | ☐ |

---

## Section 3 — SharePoint and OneDrive Permissions ⚠ BLOCKER

> **This section must be fully completed and signed off before Copilot licences are assigned.**
> The 2019 migration left permissions in an inherited state across Finance SharePoint sites.
> Any user who can read a document can have Copilot answer questions using its content.
> The checks below are non-negotiable for a high-sensitivity Finance deployment.

### 3a — Site and Library Permission Audit

| # | Check | How to verify | ☐ |
|---|-------|---------------|---|
| 3.1 | Generate a full permissions report for all SharePoint site collections used by Finance | SharePoint Admin Center → Active Sites → Export; or PnP PowerShell: `Get-PnPSiteCollectionAdmin` + `Get-PnPListPermissions` for each library | ☐ |
| 3.2 | Identify every library/folder where permissions are **inherited** rather than explicitly set — flag all inherited from ≤ 2019 | PnP PowerShell: `Get-PnPList` → `HasUniqueRoleAssignments` = False indicates inherited | ☐ |
| 3.3 | Break inheritance and set **explicit, role-based membership** on: payroll libraries, board-pack libraries, M&A deal-room libraries, client financial data folders | SharePoint site → Library Settings → Permissions → Stop Inheriting Permissions; assign named security groups only | ☐ |
| 3.4 | Validate the resulting access list against current Finance org chart and HR leavers list — remove any stale user accounts or ex-employee entries | Cross-reference with HR-provided current employee list | ☐ |
| 3.5 | Finance lead and Head of IT Security review and sign off the revised permission list for each sensitive library | Written sign-off required | ☐ |

### 3b — Oversharing Checks

| # | Check | How to verify | ☐ |
|---|-------|---------------|---|
| 3.6 | Run **SharePoint Advanced Management — Oversharing Insights** report (included in E5) to surface files/folders shared broadly | SharePoint Admin Center → Reports → Sharing → Oversharing Insights | ☐ |
| 3.7 | Identify all **"Anyone with the link"** and **"People in your organisation"** sharing links on Finance sites — revoke or scope to named individuals | SharePoint Admin Center → Sharing reports; or Purview Data Security Posture Management | ☐ |
| 3.8 | Identify files shared externally on Finance sites — confirm each is intentional and within policy; revoke unintended external shares | SharePoint Admin Center → Active Sites → External sharing column | ☐ |
| 3.9 | Check OneDrive for Business for Finance users: ensure no payroll, M&A, or board-pack files have been synced to personal OneDrive and shared broadly | Purview Content Explorer → filter by sensitivity label + OneDrive location | ☐ |
| 3.10 | Disable **"Anyone with the link"** sharing at the site-collection level for all Finance-owned SharePoint sites | SharePoint Admin Center → Active Sites → select site → Sharing → set to "Specific people" | ☐ |

---

## Section 4 — Sensitivity Labelling ⚠ BLOCKER

> Copilot respects sensitivity labels. Labels with encryption restrict Copilot from using that content
> for users who do not have decryption rights. Proper labelling is therefore the second line of defence
> after permissions — and is required before licences are assigned.

| # | Check | How to verify | ☐ |
|---|-------|---------------|---|
| 4.1 | Microsoft Purview sensitivity labels are published to Finance users | Purview → Information Protection → Labels → published to Finance group | ☐ |
| 4.2 | A **Highly Confidential** (or equivalent) label with encryption is applied to: payroll libraries, board-pack libraries, M&A deal rooms | Purview Content Explorer or manual check in SharePoint library → view labels on files | ☐ |
| 4.3 | Auto-labelling policy is configured to detect and label financial data patterns (payroll exports, account numbers, financial statements) in SharePoint and OneDrive | Purview → Auto-labelling → SharePoint/OneDrive scope | ☐ |
| 4.4 | DLP policy covers Copilot interactions — ensure sensitive financial classifiers (e.g. UK financial data, payroll) trigger alerts or blocks when matched in Copilot prompts/responses | Purview → DLP → create or extend policy to include "Microsoft 365 Copilot" as a location | ☐ |
| 4.5 | Copilot interaction data retention policy is set per your records-management policy (decide: retain for audit or delete on schedule) | Purview → Retention policies → Microsoft 365 Copilot interactions | ☐ |

---

## Section 5 — Identity and MFA Readiness

| # | Check | How to verify | ☐ |
|---|-------|---------------|---|
| 5.1 | All 200 Finance users are on **Azure AD / Entra ID** (cloud or hybrid-synced) — no on-prem-only accounts | Entra ID → Users → filter by Finance group; confirm UPN is present | ☐ |
| 5.2 | MFA is enforced for all Finance users — Conditional Access policy or Security Defaults; no per-user legacy MFA only | Entra ID → Security → Conditional Access → confirm Finance users are in scope of an MFA policy | ☐ |
| 5.3 | No Finance accounts have **legacy authentication** enabled — legacy auth bypasses MFA and is a Copilot access risk | Entra ID → Sign-in logs → filter by "Client app: Other clients" → should be zero for Finance | ☐ |
| 5.4 | Service accounts and shared mailboxes in Finance are excluded from Copilot licence assignment — Copilot requires a named user account | Confirm shared mailboxes are not in the Copilot licence group | ☐ |

---

## Section 6 — End-User Comms and Enablement

| # | Check | Notes | ☐ |
|---|-------|-------|---|
| 6.1 | Finance-specific Copilot Acceptable Use addendum drafted and approved — must cover: do not paste raw payroll or client data into prompts; do not use Copilot to draft regulatory or legal responses without review; do not use Copilot in M&A deal-related meetings without explicit approval | Attach as addendum to existing AI Usage Charter | ☐ |
| 6.2 | 30-minute awareness session delivered to Finance team before licence assignment — cover: what Copilot can see (anything you can access), what it cannot see (content above your permissions), and what the AUP prohibits | IT + Finance manager co-deliver | ☐ |
| 6.3 | Self-service quick-start guide published: top 3 Finance-relevant use cases (e.g. summarise email threads, draft finance report sections from templates, search SharePoint via natural language) | Share via Finance Teams channel | ☐ |
| 6.4 | 2–3 Finance Copilot champions nominated from the pilot group to support peer questions post-rollout | Finance manager nominates | ☐ |
| 6.5 | 30-day post-rollout review scheduled: review Copilot usage telemetry, DLP alert queue, and champion feedback | M365 Admin Center → Reports → Copilot usage | ☐ |

---

## Sign-Off Summary

| Section | Owner | Signed off | Date |
|---------|-------|-----------|------|
| 3 — Permissions (BLOCKER) | SharePoint admin + Finance lead + Head of IT Security | ☐ | |
| 4 — Sensitivity labelling (BLOCKER) | IT Security / M365 admin | ☐ | |
| 1 — Licensing | M365 admin | ☐ | |
| 2 — Client versions | Endpoint / Intune admin | ☐ | |
| 5 — Identity / MFA | Identity / Entra admin | ☐ | |
| 6 — Comms and enablement | IT + Finance manager | ☐ | |

**Copilot add-on licences must not be assigned until Sections 3 and 4 are signed off.**
