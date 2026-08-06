# Personal AI Usage Charter — DWP Desktop/Endpoint Engineer
**Version 1.0 | Effective: 2026-08-03 | Owner: [Your Name]**

---

## 1 · Tasks I WILL use public AI assistants for

| Category | Examples |
|---|---|
| Script drafting | PowerShell for local admin tasks, scheduled task templates, registry query scripts on non-production test machines |
| Generic troubleshooting | Decoding Windows Event IDs, interpreting generic error codes, understanding Group Policy ADMX settings |
| Documentation & formatting | Drafting runbook sections, formatting Markdown/HTML, writing plain-English summaries of technical steps |
| Learning & research | Explaining concepts (e.g. BitLocker recovery modes, WSUS architecture), comparing tools, understanding RFCs |
| Code review of sanitised samples | Reviewing logic of a script after all real hostnames, usernames, and paths have been replaced with placeholders |

**Guiding test:** "If this prompt appeared verbatim in a news article, would it expose any DWP system, citizen, or colleague detail?" If yes, do not send it.

---

## 2 · Tasks I will NOT use public AI assistants for

- **Anything involving real citizen data** — names, NINos (National Insurance Numbers), claim references, addresses, dates of birth, or any field sourced from a DWP line-of-business system.
- **Live infrastructure details** — actual hostnames, IP addresses, subnet ranges, AD domain names, SCCM/Intune tenant IDs, or service account names.
- **Security artefacts** — firewall rules, vulnerability scan output, patch exemption details, incident reports, or anything from a protective-marking category (OFFICIAL-SENSITIVE and above).
- **Credentials of any kind** — passwords, API keys, certificates, PAT tokens, or MFA recovery codes, even "just for testing".
- **Third-party contract or procurement information** — supplier names tied to specific contracts, pricing, SLA details.
- **Drafting communications on behalf of DWP** — emails, service announcements, or change records that carry DWP authority without human review and sign-off.

---

## 3 · Data-handling rule for end-user PII and credentials

> **NEVER paste, type, or describe real PII or credentials into any public AI chat, prompt box, or API call.**

**Practical steps:**
1. **Sanitise before prompting.** Replace all real values with tokens: `HOSTNAME_01`, `USER_A`, `CLAIM_REF_X`. Keep a local mapping note if you need to re-substitute.
2. **Check auto-complete and clipboard.** Before submitting a prompt, re-read it; auto-fill and copy-paste errors are the most common leak vector.
3. **Treat AI chat history as a public log.** Do not rely on "clear history" — assume everything sent has been retained. Act accordingly.
4. **Credentials are never acceptable placeholders.** Even a fake-looking password string in a script example must not be a real one. Use `<REPLACE_WITH_VAULT_SECRET>` markers instead.
5. **If in doubt, stop.** Raise with your line manager or the DWP Security Team before proceeding.

---

## 4 · Personal 'generate then verify' rule for scripts and system changes

Any script or configuration change produced with AI assistance must pass **all four gates** before it touches a managed device or service:

| Gate | What I must do |
|---|---|
| **G1 — Read every line** | Read the full output. Do not run anything I cannot explain line by line. |
| **G2 — Static check** | Run a linter or syntax check locally (e.g. `PSScriptAnalyzer`, `shellcheck`) and resolve all warnings. |
| **G3 — Test in isolation** | Execute in a non-production environment (local VM, sandbox tenant, or test OU) and confirm the outcome matches intent before wider deployment. |
| **G4 — Peer review for high-risk changes** | For any change touching system security settings, scheduled tasks, firewall rules, or user accounts — get a second pair of eyes from a colleague before promotion to production. |

**Non-negotiable:** AI tools can hallucinate cmdlets, incorrect flags, and logic errors. I own the output the moment I run it. "The AI wrote it" is not a valid incident explanation.

---

*This charter supplements, and does not replace, DWP's official Acceptable Use Policy and AI governance guidance. Review and update this document whenever DWP policy changes or when a new AI tool is adopted.*
