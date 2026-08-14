# JAMF Pro Configuration Profile: macOS Security Baseline Translation

Author: DWP Engineer  
Date: 2026-08-14  
Scope: 25 macOS devices (Design team fleet)  
Target management platform: JAMF Pro

## Validation rule before implementation

JAMF Pro UI labels and payload grouping can change across versions, and Apple can move controls between classic profile payloads, restrictions, and managed software update channels.

Where this document marks an item as **UI label may vary**, verify in your own JAMF instance before trusting the exact label text or menu location. Follow the same discipline used in the Intune labs on Day 6.

## How to create and deploy the baseline profile (directional path)

The exact UI wording may differ by JAMF version. In most tenants, the flow is:

`JAMF Pro` -> `Computers` -> `Configuration Profiles` -> `New`  
Set profile metadata -> add payloads -> configure values below -> `Scope` to Design fleet smart/static group -> save -> monitor deployment status.

If your tenant uses alternative navigation labels, treat the path above as directional only and confirm in your live console.

## Basics step - recommended profile name and description

Suggested profile name:

`DWP - macOS Security Baseline - Design Fleet - 2026-08`

Suggested description:

```
Enforces DWP macOS baseline controls for the Design team fleet.
Controls: FileVault, Gatekeeper, minimum macOS version (N-1), firewall,
password after sleep/screensaver, and automatic security updates.

Scope: 25 Design team managed Macs
Owner: DWP Digital Workplace Engineering
Rollout: Pilot 5 devices, then full deployment
Review cadence: Monthly (minimum OS target and update behavior)
Change ref: [insert CHG/ticket]
```

Why this matters:
Clear metadata prevents duplicate or conflicting profiles and helps audit teams validate ownership, review cadence, and intent.

## Baseline mapping summary

| # | Requirement | Payload type (where it normally lives) | Value to set | Effect | False-positive risk | Version-label warning |
|---|---|---|---|---|---|---|
| 1 | FileVault enabled | Security and Privacy -> FileVault payload | Enable FileVault; escrow personal/institutional key to JAMF; defer enablement only if user workflow needs it | Encrypts startup disk at rest | Device can look unhealthy while encryption is still in progress; escrow delay can look like non-compliance | UI label may vary |
| 2 | Gatekeeper enabled (identified developers only) | Restrictions or Security and Privacy controls for app source policy | Allow App Store and identified developers only; disallow Anywhere | Blocks unsigned/untrusted app execution | Newly notarized internal tools or signing-chain delays can create temporary false alarms | UI label may vary |
| 3 | Minimum macOS version N-1 | Usually enforced through smart group logic + update policy, not one profile toggle | Define compliant minimum as current stable minus one point release | Keeps devices patched close to secure baseline | Staged rollout rings and inventory lag can report healthy devices as behind | UI label may vary |
| 4 | Firewall enabled | Security and Privacy -> Firewall payload | Enable firewall; optionally enable stealth mode per policy | Reduces inbound attack surface | Security tools or scripts may temporarily change firewall state during install/update | UI label may vary |
| 5 | Password required after sleep/screensaver | Security and Privacy, Restrictions, or login/security payload controls depending on version | Require password immediately or after approved short timeout | Prevents unattended access after lock/sleep | Session timing and profile refresh lag can briefly misreport status | UI label may vary |
| 6 | Automatic security updates enabled | Software Update payload and/or managed software update policy | Enable automatic check/download/install for security updates and system data files | Reduces patch latency and drift | Device offline/asleep, low disk, or approved app-compat deferrals can trigger false concerns | UI label may vary |

## Requirement 1 - FileVault disk encryption must be enabled

| Field | Detail |
|---|---|
| Payload type | Security and Privacy -> FileVault payload (name can differ by version) |
| Value | Enable FileVault; escrow recovery key(s) to JAMF; enforce at login if deferral period expires |
| Effect | Startup volume is encrypted at rest and unreadable without authorized unlock credential/recovery path |
| False-positive risk | Encryption in progress, delayed inventory update, escrow receipt lag |
| Version-label warning | UI label may vary |

Implementation notes:
1. For design users, prefer deferred enablement with a short enforcement window to avoid interrupting active rendering sessions.
2. Require key escrow so helpdesk can support recovery without local key loss risk.
3. Confirm token requirements for the first FileVault-enabled user are met before broad scope.

Fast verification checks:
1. JAMF inventory shows FileVault status as enabled.
2. Recovery key escrow record appears in JAMF for sampled devices.
3. Local validation (sample device): `fdesetup status`.

## Requirement 2 - Gatekeeper enabled (identified developers only)

| Field | Detail |
|---|---|
| Payload type | Restrictions or Security and Privacy app execution controls |
| Value | Enforce App Store and identified developers; do not allow Anywhere |
| Effect | Prevents unsigned or untrusted binaries from being launched by default |
| False-positive risk | Internal tools signed incorrectly, newly notarized packages pending trust propagation |
| Version-label warning | UI label may vary |

Implementation notes:
1. Validate critical design tools and plugins are signed/notarized before enforcing globally.
2. Build an exception process using approved packaging/signing, not by weakening Gatekeeper globally.
3. Pilot with five devices representing key design workflows.

Fast verification checks:
1. Sample local check: `spctl --status` should report assessments enabled.
2. Attempt launch of a known unsigned test binary should be blocked.

## Requirement 3 - Minimum macOS version (current stable minus one point release)

Important constraint:
This control is often not a single profile setting in JAMF. It is commonly implemented with smart group criteria and remediation/update policy.

| Field | Detail |
|---|---|
| Payload type | Compliance logic via smart groups + software update policy (not always a direct payload field) |
| Value | Set compliant threshold to current stable minus one point release (N-1) |
| Effect | Keeps fleet within approved patch proximity |
| False-positive risk | Staged patch rings, inventory timestamp lag, machine offline at scan time |
| Version-label warning | UI label may vary |

Implementation pattern:
1. Define an approved minimum version value for this month.
2. Create a smart group for devices below that version.
3. Scope update remediation policy to the below-minimum group.
4. Re-evaluate monthly after Apple stable release updates.

Fast verification checks:
1. Spot-check smart group population against known device versions.
2. Confirm remediation policy is scoped only to below-minimum devices.

## Requirement 4 - Firewall must be enabled

| Field | Detail |
|---|---|
| Payload type | Security and Privacy -> Firewall |
| Value | Enable firewall; consider stealth mode based on supportability needs |
| Effect | Reduces unsolicited inbound connection exposure |
| False-positive risk | Temporary toggles during security tooling installs, stale inventory snapshot |
| Version-label warning | UI label may vary |

Implementation notes:
1. Keep policy consistent with remote support tooling requirements.
2. If using stealth mode, validate it does not interfere with approved management/monitoring behavior.

Fast verification checks:
1. Local sample check: `/usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate`.
2. Inventory reflects firewall enabled after next check-in.

## Requirement 5 - Login password required after sleep/screensaver

| Field | Detail |
|---|---|
| Payload type | Security and Privacy / Restrictions / login security controls (location varies) |
| Value | Require password immediately or within approved short timeout after sleep/screensaver |
| Effect | Prevents unauthorized access when a user steps away |
| False-positive risk | Profile application delay, session state lag after first login, nonstandard shared-device configs |
| Version-label warning | UI label may vary |

Implementation notes:
1. For high-sensitivity teams, use immediate requirement.
2. For user experience balance, a short timeout can be used if policy allows.
3. Keep lock behavior aligned with physical office risk profile.

Fast verification checks:
1. Lock and wake test on sampled device confirms password prompt behavior.
2. Confirm no conflicting local scripts are overriding lock settings.

## Requirement 6 - Automatic security updates enabled

| Field | Detail |
|---|---|
| Payload type | Software Update payload and/or managed software update policy |
| Value | Enable automatic security updates and system data file updates; enforce regular install cadence |
| Effect | Speeds patch adoption and reduces known-vulnerability exposure window |
| False-positive risk | Endpoint offline/asleep during schedule, disk-space pressure, temporary approved deferrals |
| Version-label warning | UI label may vary |

Implementation notes:
1. For design endpoints, set update windows around non-production hours.
2. Pair policy with user notifications before forced restart behavior.
3. Keep one controlled deferral ring for critical creative app compatibility validation.

Fast verification checks:
1. Confirm managed software update settings applied in profile status.
2. Validate sample device update logs show successful checks and installs.

## Recommended deployment model for 25-device design fleet

1. Pilot ring: 5 devices covering key design roles and app stacks.
2. Observe for 3 to 5 business days for compliance stability and workflow impact.
3. Expand to remaining 20 devices in one wave if pilot is clean.
4. Keep one break-glass exclusion group with formal approval controls.

## Assignment and scoping guidance

1. Use a dedicated smart group for Design managed Macs.
2. Exclude lab or kiosk endpoints if their intended posture differs.
3. Avoid overlapping profiles with contradictory security controls.
4. Document profile precedence when multiple profiles can touch same domain.

## Post-assignment validation workflow

### Step 1 - Verify profile deployment status

Directionally in JAMF:
1. Open the profile.
2. Review device deployment/install status.
3. Confirm all 25 devices are either completed or in-progress with expected timing.

### Step 2 - Verify per-control outcomes on sampled devices

Use a representative sample from pilot/full fleet and check:
1. FileVault status and key escrow.
2. Gatekeeper assessment state.
3. OS version against approved minimum.
4. Firewall state.
5. Password-after-sleep behavior.
6. Software update automation state.

### Step 3 - Validate remediation targeting

1. Confirm below-minimum OS smart group membership accuracy.
2. Confirm update remediation policy is scoped correctly.
3. Confirm compliant devices are not repeatedly targeted by remediation actions.

## Troubleshooting guide for common false positives

### Case 1 - FileVault appears non-compliant but user says it is enabled

Most common causes:
1. Encryption still in progress.
2. Recovery key escrow has not synced yet.
3. Inventory data is stale.

Fast checks:
1. `fdesetup status`.
2. Confirm key escrow record in JAMF.
3. Trigger inventory update and recheck.

### Case 2 - Gatekeeper flags after approved tool install

Most common causes:
1. Tool not notarized or signed chain incomplete.
2. Trust services cache delay.

Fast checks:
1. Validate code signature and notarization status of package/app.
2. Re-test after policy/inventory refresh cycle.

### Case 3 - Device fails minimum OS version unexpectedly

Most common causes:
1. Inventory check-in lag.
2. Device in approved deferral ring.
3. Update scan/install not completed.

Fast checks:
1. Confirm local OS version.
2. Compare with smart group criteria and timestamp.
3. Validate update policy run history.

### Case 4 - Firewall appears off briefly

Most common causes:
1. Temporary changes during security tooling updates.
2. Conflicting local scripts/configuration profile.

Fast checks:
1. Validate current local firewall state.
2. Check recent policy/script executions affecting firewall domain.

## First 24-hour monitoring checklist

Run at 2h, 6h, and 24h after deployment change:

| Check | What to review | Action trigger |
|---|---|---|
| Profile install coverage | Number of devices successfully receiving profile | If install coverage is below expected by wave timing, investigate scope/connectivity |
| Top failing controls | Which control fails most often | If one control dominates, run targeted troubleshooting on sample devices |
| Below-minimum OS group trend | Group size over time | If group size rises post-deployment, verify update channel and policy execution |
| User-impact incidents | Helpdesk tickets from Design fleet | If lockouts or tool launch blocks rise, validate Gatekeeper and password settings |
| Escrow completeness | Devices with missing FileVault key escrow | If missing escrow persists, pause expansion and fix escrow workflow |

## Monthly operational review tasks

1. Update minimum OS target to maintain N-1 posture.
2. Reconfirm Gatekeeper compatibility for newly introduced design tools/plugins.
3. Audit exception groups and remove expired exceptions.
4. Validate profile still maps cleanly after JAMF or macOS platform changes.

## Operational caution

This document provides a strong implementation template, but exact control names and locations must be validated in your own JAMF Pro tenant before production rollout. Any field marked or implied as version-sensitive should be confirmed live rather than copied blindly.
