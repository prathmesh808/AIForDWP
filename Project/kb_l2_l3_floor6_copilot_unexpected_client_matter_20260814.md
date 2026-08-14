# L2/L3 Knowledge Base: Floor 6 Copilot Unexpected Client Matter

Version: v 1.0  
Date: 14/08/2026  
Status: Draft

## Background
Copilot responses are grounded on content the signed-in user can access. Access is determined by document permissions, inheritance from parent locations, and group membership. In legal content areas, even small permission drift can expose sensitive matter names or references to the wrong audience. Fast diagnosis matters because this is a confidentiality-risk incident, not only a usability issue.

## Symptom
Engineer observes:
- A Floor 6 user reports Copilot cited a client matter they believe they should not see.
- Citation includes a source link or source ID pointing to legal repository content.

User reports:
- Copilot showed an unexpected client matter.
- User is unsure whether this content should be visible.

## Root Cause
Specific technical cause:
- Permissions/access boundary mismatch allowed the reporting user context to retrieve a cited source through direct, inherited, or group-based grants.

Evidence that confirms it:
- Effective access on cited source returns allowed for reporting user when business expectation is denied.
- Parent inheritance or group membership trace shows an unintended access path.
- Comparison check shows affected user retrieves source while denied-control user does not.

## Detection
Run this 3-minute confirmation path before making any change.

1. Open Purview audit log at `https://purview.microsoft.com` > Solutions > Audit > Audit search.
- Event IDs: not used for this cloud workflow; use Operation field.
- Set filters: `Date range = Last 1 hour`, `Users = reporting user UPN`, `Workload = SharePoint or OneDrive`.
- Fields to read: `CreationDate`, `User`, `Operation`, `ObjectId`, `SiteUrl`.
- Match condition: audit rows exist for the cited source around incident time.

2. Open the exact citation link in SharePoint, then go to `Details pane > Manage access > Advanced permissions > Check Permissions`.
- Fields to read: `principal`, `permission level`, `access source`.
- Match condition: reporting user has `Allow` (direct, inherited, or group) where business expectation is deny.

3. In the same permissions page, open parent permissions to trace inheritance to library and site.
- Fields to read: `inherits from`, `granted group`, `permission level` at each layer.
- Match condition: a concrete inherited path explains the user allow state.

4. Open Entra at `https://entra.microsoft.com` > Identity > Users > reporting user > Groups.
- Fields to read: `group name`, `membership type`, `assignment source`.
- Match condition: reporting user is in at least one group present in the access path from step 3.

5. Run comparison check on same cited source.
- Pair: reporting user (affected) vs denied-control user (expected denied).
- Path: SharePoint `Advanced permissions > Check Permissions` for both users.
- Fields to compare: `effective permission level`, `access source`.
- Confirm this incident type only if affected user = allow and control user = deny on the same source.

Decision rule:
- Confirm permissions-boundary incident if steps 2, 4, and 5 all match.
- If step 2 shows deny for reporting user, do not change permissions; branch to citation-identity or context-ambiguity investigation.

## Resolution
Target execution time: 5-10 minutes for one reported case.

1. Open `https://admin.microsoft.com` > `Users` > `Active users` > select reporting user > `Licenses and apps`.
- Action: Turn off Copilot service for the reporting user and click `Save changes`. [ELEVATED]
- Expected result: Containment is active for reporting user.

2. Open the exact citation link from the incident evidence in SharePoint.
- Action: Navigate `Details pane > Manage access > Advanced permissions`.
- Expected result: Item-level permissions page is open for the cited source.

3. In SharePoint `Advanced permissions` page.
- Action: Click `Check Permissions`, enter reporting user UPN, and record the result. [ELEVATED]
- Expected result: Current effective permission state is captured.

4. Open `https://entra.microsoft.com` > `Identity` > `Users` > reporting user > `Groups`.
- Action: Identify groups that match principals shown on SharePoint permissions page. [ELEVATED]
- Expected result: Access path from group membership is identified.

5. Return to SharePoint `Advanced permissions` on cited source.
- Action: Remove the unintended principal at item scope first, then click `OK` or `Save`. [ELEVATED]
- Expected result: Unauthorized permission path is removed at narrowest scope.

6. In SharePoint `Check Permissions`.
- Action: Run check for reporting user and denied-control user on same source. [ELEVATED]
- Expected result: Reporting user is denied and denied-control user remains denied.

7. Open `https://purview.microsoft.com` > `Solutions` > `Audit` > `Audit search`.
- Action: Set `Date range = Last 15 minutes`, `Users = reporting user`, `Workload = SharePoint, OneDrive`, then click `Search`.
- Expected result: No post-change unauthorized access operation appears for the cited source.

8. Open `https://admin.microsoft.com` > `Users` > `Active users` > reporting user > `Licenses and apps`.
- Action: Re-enable Copilot service only after steps 6 and 7 pass, then click `Save changes`. [ELEVATED]
- Expected result: Service is safely restored with corrected boundary.

## Verification
1. SharePoint permission verification.
- Path: cited source > `Manage access > Advanced permissions > Check Permissions`.
- Pass criteria: reporting user has no read permission for cited source.

2. Control-user permission verification.
- Path: same `Check Permissions` dialog for denied-control user and authorized-control user.
- Pass criteria: denied-control user is denied; authorized-control user retains expected access.

3. Purview audit verification.
- Path: `https://purview.microsoft.com` > `Solutions > Audit > Audit search`.
- Filters: `Last 1 hour`, `Users = reporting user`, `Workload = SharePoint/OneDrive`.
- Pass criteria: no new unauthorized source access operation after remediation time.

4. Prompt retest verification.
- Path: Copilot session for reporting user, then authorized-control user.
- Pass criteria: reporting user does not get unauthorized citation; authorized-control user behavior remains normal.

5. Queue verification.
- Path: ITSM incident queue filter `Location = Floor 6`, `Category = confidentiality/access`, `Time = Last 60 minutes`.
- Pass criteria: no repeat incident created after fix confirmation.

## Rollback
Use immediately if legitimate access is broken or remediation scope is wrong.

Target rollback time: under 3 minutes.

1. Open SharePoint cited source > `Manage access > Advanced permissions`.
- Action: Re-add removed principal(s) from pre-change evidence and click `OK` or `Save`. [ELEVATED]
- Expected result: prior item-level access state restored.

2. In same SharePoint permissions page.
- Action: Restore previous inheritance state exactly as captured in before-change evidence. [ELEVATED]
- Expected result: parent-child permission model returns to pre-change baseline.

3. Open `https://entra.microsoft.com` > `Identity > Groups` > affected group > `Members`.
- Action: Re-add any user removed in error and save. [ELEVATED]
- Expected result: legitimate group-based business access restored.

4. Open `https://admin.microsoft.com` > `Users > Active users > reporting user > Licenses and apps`.
- Action: Keep Copilot service disabled during rollback validation. [ELEVATED]
- Expected result: confidentiality exposure remains contained.

5. Open `https://purview.microsoft.com` > `Solutions > Audit > Audit search`.
- Action: Run `Last 15 minutes` search for reporting user and cited source and export result.
- Expected result: rollback activity trace is captured for escalation.

## Preventive
1. Legal-content access boundary gate in change workflow.
- Owner: change manager; Timing: before deployment; Mode: manual now, automate via ITSM mandatory evidence rule [REQUIRES: ITSM workflow validation].
- Pass/Fail: pass only if affected-vs-control Check Permissions results are attached for each changed legal source; fail if any result is missing.
- If fail: block change closure and return to release engineer for evidence completion.

2. Automated alert for high-risk permission expansion.
- Owner: release engineer; Timing: during deployment; Mode: automated [REQUIRES: Purview alert policy plus legal-site scope list].
- Pass/Fail: fail when permission-change operations on scoped legal repositories add any broad group (>50 members) with read or higher access.
- If fail: auto-open P2 incident, freeze rollout, and notify DWP engineer plus service desk lead.

3. Mandatory citation evidence capture at intake.
- Owner: service desk lead; Timing: during deployment and incident intake; Mode: manual now, automatable via required form fields [REQUIRES: ITSM form update].
- Pass/Fail: pass only if prompt text, response text, citation ID/link, timestamp, and user UPN are populated; fail if any field is blank.
- If fail: ticket cannot move to in-progress triage and is returned to intake queue.

4. Periodic effective-access reviews for sensitive repositories.
- Owner: DWP engineer; Timing: after deployment (weekly); Mode: manual now, automate via scheduled access report [REQUIRES: scripted access review export].
- Pass/Fail: pass if 100 percent of sampled sensitive repositories show no unauthorized allow path for denied-control account; fail if any unauthorized allow is found.
- If fail: create corrective change within 1 business day and notify change manager.

5. Pre-deployment smoke-test gate (additional layer).
- Owner: release engineer; Timing: before deployment; Mode: manual now, automate with test harness [REQUIRES: reproducible Copilot test script].
- Pass/Fail: pass only if denied-control user gets denied and authorized-control user gets allowed on 3 test matters; fail if any test deviates.
- If fail: do not start rollout window.

6. In-flight monitoring during rollout window (additional layer).
- Owner: DWP engineer; Timing: during deployment; Mode: automated [REQUIRES: near-real-time Purview query dashboard].
- Pass/Fail: fail when 2 or more unexpected-client-matter tickets occur in 30 minutes for same floor and matching repository scope.
- If fail: pause rollout and start incident bridge immediately.

7. Post-deployment validation gate (additional layer).
- Owner: change manager; Timing: after deployment; Mode: manual checklist now, automate with closure guard [REQUIRES: change-close policy rule].
- Pass/Fail: pass only if no new confidentiality/access incidents for 60 minutes and verification evidence is attached; fail otherwise.
- If fail: keep change open and continue controlled remediation.

8. Rollback trigger threshold (additional layer).
- Owner: service desk lead; Timing: during deployment; Mode: manual trigger now, automatable by rule [REQUIRES: incident threshold automation].
- Pass/Fail: trigger rollback if any unauthorized citation is reproducible after fix or if impacted users >= 2 for same source within 15 minutes.
- If fail threshold met: execute rollback runbook immediately and escalate to Legal/Security.

9. Knowledge update control from incident learnings (additional layer).
- Owner: service desk lead; Timing: after deployment and incident closure; Mode: manual now, automate as mandatory closure task [REQUIRES: KB-task enforcement in ITSM].
- Pass/Fail: pass only if runbook, L1 article, and L2-L3 KB are version-updated and linked to incident within 2 business days.
- If fail: block final closure and assign update action to DWP engineer.

## Related
- FinalProject/runbook_floor6_copilot_unexpected_client_matter_20260814.md
- FinalProject/rca_floor6_copilot_unexpected_client_matter_20260814.md
- FinalProject/floor6_copilot_unexpected_client_matter_detailed_analysis_20260814.md
- FinalProject/floor6_copilot_unexpected_client_matter_scope_only_hypothesis_20260814.md
- FinalProject/incident_triage_floor6_copilot_unexpected_client_matter.md