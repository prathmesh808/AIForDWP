# Floor 6 Incident Communication Pack

## Shared Facts Used In All Versions
- Three issues were reported on Floor 6 this morning: login delays/failures, missing desktop icons, and one Copilot response showing an unexpected client matter.
- Login disruption was linked to a device-access policy mismatch; desktop icon loss was linked to user profile loading; Copilot unexpected matter is being handled as an access-boundary issue.
- There is no evidence of data loss from the login or desktop icon issues.
- The two productivity issues were stabilized and access restored with targeted fixes.
- The Copilot access-boundary review remains open under Legal and Security oversight, with containment and retesting in progress.
- Stronger rollout controls, faster rollback triggers, and updated service desk/runbook procedures are being applied to reduce recurrence.

## Audience 1 — Non-Technical Executive
Your access and data are safe. This morning Floor 6 experienced three issues: login delays, missing desktop icons, and one Copilot response showing an unexpected client matter. The first two were stabilized and access was restored; no data loss was found in those areas. The Copilot item is still under Legal and Security review with containment and retesting in progress. We are strengthening rollout and rollback controls to prevent repeat disruption. No action is required from you now.

## Audience 2 — Affected End-User Team
Your access and data are safe. This morning Floor 6 had three problems at once: some people had slow login, some lost desktop icons, and one Copilot result showed a client matter that looked unexpected. Login and desktop icon issues were fixed and no data loss was found there. The Copilot item is still being checked with Legal and Security while safeguards stay in place. If you see the same issue again, stop and report it right away with time, screenshot, and what you were doing. Contact the Service Desk.

## Audience 3 — Engineer-to-Engineer Internal Note
Scope summary:
- Floor 6 had concurrent incidents: login failure/slowness, missing desktop icons, and Copilot unexpected client matter citation.

Root cause position:
- Login incident: CA/device-compliance boundary mismatch (Intune/Entra policy-state intersection) caused deny/latency behavior at sign-in.
- Missing desktop icons: profile load/mapping issue (including SID/ProfileList mapping behavior) caused incorrect desktop context.
- Copilot incident: permissions boundary mismatch (direct/inherited/group path) on cited legal content; confidentiality handling active.

Exact actions taken:
- Login: scoped temporary access exception, forced device sync/compliance reevaluation, corrected failing prerequisites, then restored normal policy enforcement.
- Desktop icons: validated profile path/mapping, protected desktop artifacts, corrected profile mapping state where needed, restored required icon set, and validated against unaffected baseline.
- Copilot: captured prompt/response/citation evidence, temporarily restricted reporting user Copilot access for containment, traced effective access/inheritance/group path, removed unintended grant path at narrowest scope, retested denied/authorized controls, and maintained legal/security communication.

Config/detail reference points:
- Login checks: Entra sign-in decision + device compliance state correlation at incident timestamp.
- Desktop checks: ProfileList SID mapping, profile path alignment, user/public desktop artifact presence and permissions.
- Copilot checks: cited source effective access, inheritance chain, Entra group membership path, Purview audit operations for incident window.

Verification performed:
- Login: successful sign-in without policy denial recurrence on remediated cohort.
- Desktop icons: expected profile path and icon visibility restored; affected/unaffected comparison normalized.
- Copilot: reporting-user access corrected on cited source and citation behavior retested; authorized-user path preserved.

Current open item:
- Copilot confidentiality case remains open pending final legal/security sign-off after containment/retest evidence review.

Preventive actions required:
- Enforce pre-deployment canary gates, in-flight monitoring thresholds, explicit rollback triggers, and post-deployment closure criteria.
- Require mandatory evidence capture at intake (prompt/response/citation/timestamp/access snapshot).
- Maintain updated runbooks and service desk procedures for faster, repeatable triage and recovery.