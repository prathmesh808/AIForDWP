# Runbook: Floor 6 Copilot Unexpected Client Matter

## Version Header
- Title: Floor 6 Copilot Unexpected Client Matter Runbook
- Version: 1.0
- Date: 07/08/2026
- Author: Sathishbabu
- Reviewed: self
- Status: draft
- Change: initial version from RCA

## Purpose
Guide DWP engineers to triage and remediate a reported Copilot response that surfaced an unexpected client matter, with clear containment, evidence capture, access-boundary validation, and recovery actions.

## Scope
- Incident pattern: User reports Copilot returned client matter content they believe is unauthorized.
- Source RCA: rca_floor6_copilot_unexpected_client_matter_20260814.md.

## 1) Prerequisites

Use this checklist before starting. Do not begin Procedure until all mandatory items are checked.

### 1.1 Access checklist
- [ ] [ELEVATED] You can sign in to Microsoft 365 admin center (`https://admin.microsoft.com`) with a role that can restrict and restore user Copilot access.
- [ ] [ELEVATED] You can sign in to SharePoint admin center (`https://<tenant>-admin.sharepoint.com`) and edit item/library/site permissions.
- [ ] [ELEVATED] You can sign in to Entra admin center (`https://entra.microsoft.com`) and view/edit relevant group memberships.
- [ ] You can sign in to Microsoft Purview portal (`https://purview.microsoft.com`) and run Audit search.
- [ ] You can update the incident ticket timeline in ITSM.

### 1.2 Tools and systems checklist
- [ ] Browser session open to Microsoft 365 admin center.
- [ ] Browser session open to Entra admin center.
- [ ] Browser session open to SharePoint admin center and affected legal site/library.
- [ ] Browser session open to Purview Audit search.
- [ ] Secure evidence template ready for prompt, citation, permission, and audit captures.

### 1.3 Mandatory information from reporting user checklist
- [ ] Reporting user UPN and display name.
- [ ] Exact incident timestamp with time zone.
- [ ] Exact Copilot prompt text.
- [ ] Full Copilot response text.
- [ ] Citation list with source links or source IDs.
- [ ] Screenshot or export of reported Copilot response if available.

### 1.4 Safety and governance checklist
- [ ] Legal notification owner confirmed.
- [ ] Security notification owner confirmed.
- [ ] Rollback approver confirmed before permission edits.
- [ ] Confidential evidence storage location confirmed.

## 2) Procedure

1. Open the incident ticket and paste reporting user UPN, timestamp, prompt text, response text, and citation IDs.
Expected result: Baseline incident evidence is recorded.

2. In ITSM, post initial advisory to Legal and Security distribution owners.
Expected result: Stakeholders are notified before access changes.

3. [ELEVATED] Open `https://admin.microsoft.com` > Users > Active users > select reporting user > Licenses and apps.
Expected result: Reporting user profile and service assignment page is open.

4. [ELEVATED] In reporting user service assignment, apply temporary Copilot access restriction and save.
Expected result: Further retrieval attempts by reporting user are contained.

5. Open the exact cited source link from the Copilot response in browser.
Expected result: Target document or record under investigation is open.

6. [ELEVATED] In the cited item, open Details pane > Manage access > Advanced permissions.
Expected result: Item-level permission page is visible.

7. [ELEVATED] On advanced permissions page, run Effective access check for reporting user.
Expected result: Allowed/denied result is captured for the cited item.

8. [ELEVATED] In the same permission page, open parent container permissions and record inheritance state.
Expected result: Inheritance path and permission source are visible.

9. [ELEVATED] Open `https://entra.microsoft.com` > Identity > Users > select reporting user > Groups.
Expected result: User group membership list is visible.

10. [ELEVATED] For each access-granting group identified, open group details and record membership path.
Expected result: Group-based permission chain is confirmed or ruled out.

11. Open `https://purview.microsoft.com` > Solutions > Audit > Audit search.
Expected result: Audit search interface is open.

12. In Purview Audit search, set date range around incident timestamp and user filter to reporting user.
Expected result: Incident-window audit events are query-ready.

13. Run audit search for relevant operations (file accessed, sharing changed, permission changed) and export results.
Expected result: Time-bounded audit evidence is captured.

14. [ELEVATED] Remove unintended permission at the narrowest scope (item first, then container only if required) and save.
Expected result: Unauthorized access path is removed.

15. [ELEVATED] Re-run Effective access on same item for reporting user.
Expected result: Access is denied where expected.

16. Re-run the original prompt in controlled retest using reporting user context after containment adjustment.
Expected result: Unauthorized citation no longer appears.

17. Run same prompt with authorized control account.
Expected result: Authorized retrieval behavior remains intact.

18. [ELEVATED] Restore normal Copilot access assignment for reporting user in `admin.microsoft.com` if verification passed.
Expected result: User service access returns to normal state.

19. Update incident ticket with before/after permission snapshots, audit export reference, retest outcome, and timestamps.
Expected result: Complete auditable technical timeline is available.

20. Send final closure note to Legal and Security with verification evidence summary.
Expected result: Stakeholders receive confirmed remediation and assurance outcome.

## 3) Verification

1. Open cited source in SharePoint and navigate `Details pane > Manage access > Advanced permissions > Check Permissions`.
Pass criteria: Check Permissions for reporting user shows no read access on cited item.

2. Open `https://purview.microsoft.com` > `Solutions` > `Audit` > `Audit search`.
Pass criteria: Audit search page is open for evidence validation.

3. In Purview Audit search set `Date range = Last 1 hour`, set `Users = reporting user`, and set activities to file access and permission changes, then run search.
Pass criteria: No new unauthorized access event to the cited source appears after remediation timestamp.

4. Re-run original prompt in reporting user context and capture citations.
Pass criteria: Original unauthorized source link or ID is absent from the returned citation list.

5. Re-run same prompt with authorized control account and capture citations.
Pass criteria: Authorized account still returns expected legal content without retrieval failure.

6. Open ITSM queue with filter `Location = Floor 6` and `Category = confidentiality/access` for `Last 60 minutes`.
Pass criteria: No new related incident is created after fix confirmation.

7. Confirm incident evidence package includes prompt text, response text, citation IDs, permission snapshots, and Purview audit export.
Pass criteria: Complete verification evidence is attached to ticket.

## 4) Rollback

Use immediately if remediation blocks legitimate access or causes broader legal workflow impact.

Target rollback execution time: under 3 minutes.

1. [ELEVATED] Open cited source `Advanced permissions` page and reapply pre-change permission entry from captured evidence.
Expected result: Prior item-level access rule is restored.

2. [ELEVATED] On same permission page, click `Delete unique permissions` or restore inheritance state to pre-change value.
Expected result: Parent/child permission model returns to pre-change state.

3. [ELEVATED] Open `https://entra.microsoft.com` > `Identity` > `Groups` > target group > `Members`, then re-add any user removed in error.
Expected result: Legitimate group-based access is restored.

4. [ELEVATED] Open `https://admin.microsoft.com` > `Users` > `Active users` > reporting user > `Licenses and apps`, then keep Copilot access restricted if risk is still uncertain.
Expected result: Potential confidentiality exposure remains contained during rollback validation.

5. Open SharePoint `Check Permissions` for reporting and control users on the cited source.
Expected result: Access behavior matches pre-change baseline immediately.

6. Open `https://purview.microsoft.com` > `Solutions` > `Audit` > `Audit search`, run `Last 15 minutes` check for reporting user and cited source.
Expected result: Post-rollback access activity is captured for escalation record.

7. Update ITSM timeline with rollback start/end time, reverted objects, and escalate to Security, Legal, and platform owner.
Expected result: Incident command is re-established with complete rollback trace.

## 5) Notes

- If Effective Access already shows denied before remediation, do not edit permissions first; validate citation-source identity and similarly named content paths.
- If citation points to a different but authorized item with similar naming, treat as prompt/context ambiguity rather than boundary breach.
- If denied-access test account can still reproduce cited retrieval after boundary correction, escalate as potential Copilot defect.
- Preserve all evidence before any permission change to support legal and audit review.
- Related files:
  - rca_floor6_copilot_unexpected_client_matter_20260814.md
  - floor6_copilot_unexpected_client_matter_detailed_analysis_20260814.md
  - floor6_copilot_unexpected_client_matter_scope_only_hypothesis_20260814.md
  - incident_triage_floor6_copilot_unexpected_client_matter.md