# Microsoft 365 Copilot — Rollout Priority Tiers
**Derived from:** `copilot_m365_readiness_checklist_finance_20260812.md`
**Department:** Finance (~200 users)
**Date:** 2026-08-12

---

## Tier 1 — MUST Complete Before Rollout (Blocking)

These items must be verified and signed off before a single Copilot licence is assigned.
Skipping any of them creates a condition where rollout itself causes the harm.

| Item | Checklist ref | Why it is blocking |
|------|---------------|--------------------|
| Break SharePoint permission inheritance on sensitive libraries | 3.3 | Inherited permissions from 2019 are the direct exposure vector. Copilot queries against any content the user can read. Leaving inherited permissions in place means the blast radius of every stale access grant is immediately amplified. |
| Audit and remediate stale/ex-employee access | 3.4 | A leavers account with inherited read access to a payroll library becomes an active Copilot query target the moment a licence is assigned to a current user who shares that inherited permission scope. |
| Finance lead + IT Security sign-off on revised permissions | 3.5 | Without named accountability, the audit is not audit-grade evidence. Required for regulatory defensibility. |
| Revoke "Anyone with the link" and broad org-wide sharing links | 3.6, 3.7 | Broad sharing links extend Copilot's reach to anyone who can click a link — including users outside Finance. These must be scoped before Copilot indexes and makes content discoverable by natural language. |
| Sensitivity labels with encryption applied to highest-sensitivity libraries | 4.2 | Labels with encryption are the last technical control that survives permission misconfiguration. Payroll, board packs, and M&A content must be encrypted at label level so that even a mis-scoped permission does not yield readable Copilot output. |
| DLP policy extended to cover Copilot interactions | 4.4 | Without this, a Finance user pasting payroll data into a Copilot prompt bypasses every existing DLP control. The Copilot interaction channel is new and must be explicitly in scope. |
| MFA enforced for all Finance users | 5.2 | Copilot access is gated by the user's identity session. An unprotected account with Finance SharePoint access becomes a Copilot access point. MFA enforcement is a non-negotiable baseline. |
| Legacy authentication disabled | 5.3 | Legacy auth bypasses Conditional Access and therefore bypasses MFA. Any Finance account with legacy auth active is an unprotected Copilot access path. |

---

## Tier 2 — SHOULD Complete Before Rollout (High Risk if Skipped)

These items are not strict technical blockers — rollout can proceed without them — but skipping
them materially increases the probability of a data or compliance incident in the first 30 days.

| Item | Checklist ref | Risk if skipped |
|------|---------------|-----------------|
| Auto-labelling policy for financial data | 4.3 | Unlabelled files in Finance SharePoint are invisible to label-based DLP and encryption controls. New files created after rollout accumulate without protection until labels are applied manually. |
| Oversharing Insights report reviewed | 3.6 | The report surfaces sharing patterns that manual audits miss. Without it, point-in-time permission fixes may leave long-tail oversharing that Copilot can traverse. |
| External sharing disabled at site-collection level for Finance sites | 3.10 | External shares on Finance sites mean third parties could potentially benefit from Copilot-surfaced summaries if a licensed Finance user forwards a response. |
| OneDrive oversharing check for Finance users | 3.9 | Board-pack or M&A files copied to personal OneDrive and shared broadly are outside the SharePoint permission audit scope. Copilot indexes OneDrive content too. |
| Copilot interaction data retention policy set | 4.5 | Without a retention decision, Copilot prompt and response history accumulates with no defined lifecycle. This creates an unmanaged data store containing Finance-sensitive query outputs. |
| Microsoft 365 Apps at minimum required build | 2.1, 2.2 | Users on older builds or Semi-Annual Channel will have degraded or absent Copilot features, generating support noise and inconsistent user experience from day one. |
| New Teams client deployed | 2.4 | Classic Teams does not support all Copilot in Teams capabilities. Mixed client state in a Finance rollout creates support complexity around which features are available to whom. |
| Service accounts and shared mailboxes excluded from licence group | 5.4 | Assigning Copilot to a shared mailbox is wasteful and can produce unexpected behaviour. Low-effort to exclude; no reason to defer. |
| Finance-specific Acceptable Use addendum approved | 6.1 | Without written policy, there is no basis for action if a Finance user misuses Copilot (e.g. pastes client data into a prompt). Policy must pre-date rollout to be enforceable. |
| Awareness session delivered | 6.2 | Users unfamiliar with what Copilot can access are more likely to treat it as an isolated tool rather than one operating across their full data estate. The M&A meeting scenario in particular needs explicit communication. |

---

## Tier 3 — CAN Complete During or After Rollout (Lower Risk)

These items improve the deployment but do not create data-exposure or compliance risk if deferred
into the first 30 days post-rollout.

| Item | Checklist ref | Why deferral is acceptable |
|------|---------------|---------------------------|
| E5 licence audit for mixed SKUs | 1.2 | If 200 users are confirmed E5, edge-case SKU anomalies can be cleaned up without blocking rollout. A licence mismatch prevents Copilot activation for that individual user — it does not cause data exposure. |
| Copilot add-on licence group structure | 1.4 | The group can be created and refined after the pilot group is running. Structural tidiness, not a safety control. |
| Perpetual Office installs identified | 2.3 | Users on perpetual Office simply won't see Copilot features. No data risk — an adoption gap, not a security gap. |
| Communication Compliance policy for Copilot interactions | (Phase 2 reference) | Adds audit depth for M&A-sensitive interactions but requires policy design effort. Suitable as a 30-day follow-up once the basic DLP policy is in place. |
| Self-service quick-start guide | 6.3 | Increases adoption quality but absence does not create risk. Can be published in week 1 post-launch. |
| Copilot champions nominated | 6.4 | Peer support structure; has no bearing on data safety. Nominate during pilot phase. |
| 30-day review checkpoint | 6.5 | Occurs after rollout by definition. Schedule it now, execute it later. |
| Copilot usage reports enabled | 3.5 (Phase 3) | Telemetry; does not affect whether rollout is safe. Enable on day one of pilot but not a blocker. |

---

## Why Permissions and Oversharing Belong in MUST — Not in SHOULD

Licensing (Section 1) and client version (Section 2) are simpler to verify and are also blocking in
a narrow technical sense: without an E5 licence and the minimum build, Copilot simply does not
activate. However, the consequence of getting them wrong is **a user who cannot use Copilot** —
a productivity gap, not a data incident. The fix is reversible in minutes.

The consequence of getting permissions wrong is categorically different.

**Copilot does not add a permission layer. It removes friction.**

Before Copilot, a Finance analyst with inherited read access to the M&A deal-room library would
need to know the library existed, navigate to it, and open individual documents to extract
information. In practice, most users never discover content they were accidentally granted access to.

After Copilot is assigned, the same analyst can ask: *"Summarise the key terms in the latest
acquisition proposals"* — and receive a coherent answer drawn from documents they were never
intended to read, in seconds, without ever knowing which library the content came from.

The 2019 migration compresses this risk further. Seven years of organisational change — leavers,
restructures, project closures, team moves — have accumulated on top of a permission baseline
that was already inherited rather than explicitly set. The proportion of access grants in Finance
SharePoint that are accurate today is unknown; given no audit has occurred, the default assumption
must be that a meaningful fraction are not.

This is not a scenario where a single misconfigured item causes a single incident. It is a scenario
where every Finance user who receives a Copilot licence becomes a potential query surface for the
entire inherited permission graph of their account — including content they have no business need
to access and were never intended to reach.

That is why permissions and oversharing are in Tier 1, and why they require explicit sign-off from
both the Finance lead and the Head of IT Security before any licence is assigned.

---

## Summary

| Tier | Items | Licence assignment gate |
|------|-------|------------------------|
| MUST — blocking | 8 items across permissions, labelling, and identity | ✋ No licences until all complete |
| SHOULD — high risk if skipped | 10 items across governance, client readiness, policy, comms | ⚠ Complete within pilot phase (days 1–14) |
| CAN — defer | 8 items across structure, telemetry, adoption | ✔ Complete within 30 days post-rollout |
