# Incident Triage: Desktop Shortcuts Missing on Floor 6

## Incident Snapshot
- Time first reported: 09:14 Monday morning
- Affected area: Floor 6 (Legal)
- Reported symptom: Desktop shortcuts disappeared for at least one or more users
- Recent change context: Win11 migration, Intune enrollment, and Friday deployment of a new document management app

## Likely Cause (Ranked)
1. License/client prerequisite issue
   - Most probable due to post-migration and enrollment timing: app packaging, install context (user vs device), or profile/init script behavior can remove or fail to recreate shortcuts.
2. Permissions/access boundary
   - Plausible if users lost write/read access to profile desktop paths, redirected folders, or Start menu shortcut paths after policy changes.
3. Data indexing lag
   - Lower probability but can look like "missing" when search/start indexing has not completed after profile or app change.
4. Sensitivity label restriction
   - Unlikely direct cause of shortcut disappearance; labels target document handling more than shell shortcut presence.
5. Guest/external sharing limitation
   - Very low relevance to local desktop shortcut artifacts.
6. Genuine Copilot fault (last resort)
   - Least likely. Desktop shortcuts are endpoint shell/app deployment behavior, not Copilot generation behavior.

## Fastest Check (Do First)
- Compare one affected and one unaffected Floor 6 device for the new app's Intune assignment status and install context, then verify whether expected shortcuts exist in Public Desktop and user Desktop paths.

## Is This Actually a Copilot Bug?
- No.
- Justification: Missing shortcuts are a client configuration/deployment artifact tied to Windows profile and app rollout mechanics, not Copilot logic.

## Immediate Action Right Now
- Push a quick remediation package to recreate required legal workflow shortcuts for Floor 6.
- Keep the new app deployment ring frozen until assignment/install context is validated.
- Provide a one-click self-heal script for help desk to run on impacted devices.

## Partner-Facing Update by Lunch (Non-Technical)
- "Shortcut loss is linked to workstation rollout configuration and does not indicate a data-loss event. We can restore user productivity quickly with an automated fix while we correct the underlying deployment setting to prevent recurrence."