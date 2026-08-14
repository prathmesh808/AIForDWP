# Incident Triage: Copilot Returned Unexpected Client Matter (Floor 6 Legal)

## Incident Snapshot
- Time first reported: 09:14 Monday morning
- Affected area: Floor 6 (Legal)
- Reported symptom: A paralegal states Copilot surfaced a client matter they believe they never had access to
- Risk posture: High sensitivity due to legal confidentiality and potential data boundary concerns

## Likely Cause (Ranked)
1. Permissions/access boundary
   - Most probable because Copilot responses are grounded in what the user can access. If access inheritance, group membership, or site/library permissions changed, Copilot may legitimately retrieve content that appears unexpected to the user.
2. Data indexing lag
   - Possible if recent permission removals were not fully reflected yet in index/access cache layers, causing short-lived mismatch between expected and effective access state.
3. Sensitivity label restriction
   - Possible if label policy behavior changed in a way users interpret as inconsistent access control, though this more often blocks access than broadens it.
4. Guest/external sharing limitation
   - Possible edge case if matter content is in a shared workspace with external/guest rules that created unintended visibility.
5. License/client prerequisite issue
   - Lower probability for this specific symptom; licensing/client issues usually block Copilot capability rather than reveal unexpected records.
6. Genuine Copilot fault (last resort)
   - Keep as last resort only after permissions, index freshness, and policy paths are disproven with evidence.

## Fastest Check (Do First)
- Run "View permissions/effective access" on the exact source document surfaced by Copilot for the reporting user account at the time of incident.

## Is This Actually a Copilot Bug?
- Unclear (currently).
- Justification: This can be a real access-boundary issue without a Copilot defect. If effective access confirms the user did have permission, Copilot behavior is expected. If effective access shows no permission and the citation/source is verified, then escalate as potential Copilot fault.

## Immediate Action Right Now
- Treat as a potential confidentiality incident until disproven.
- Temporarily restrict Copilot access for the reporting account and preserve evidence (prompt, response text, citation/source, timestamp, account, tenant region).
- Notify Legal and Security that investigation is active with containment in place.

## Partner-Facing Update by Lunch (Non-Technical)
- "We are treating this as a potential confidentiality boundary event and have already contained risk for the reporting user while we verify access records. Most events of this type are caused by document permission configuration, not Copilot system failure. We will provide confirmed findings with remediation and assurance steps today."