# Windows 11 Intune Compliance Policy – Security Baseline Translation

**Author:** DWP Engineer  
**Date:** 2026-08-11  
**Scope:** Windows 11 managed devices enrolled in Microsoft Intune  
**Grace Period:** 7 days applied to all settings  

> **How to create a compliance policy (confirmed path):**  
> `Microsoft Intune admin center` → **Devices** (left nav) → **Compliance** (under *Manage devices*) → **Policies** tab → **+ Create policy** → Platform: `Windows 10 and later` → **Create** → enter a name → **Next** → **Compliance settings**  
>
> The Compliance blade tabs are: **Policies · Notifications · Retire noncompliant devices · Compliance settings · Scripts · Monitor**  
> Settings are grouped into named sections within the **Compliance settings** step of the wizard, as shown for each requirement below.

---

## Basics Step – Policy Name and Description

The first step of the wizard (**Basics**) has three fields: **Name**, **Description**, and **Platform** (read-only once selected).

### Recommended Description

```
Enforces the DWP Windows 11 security baseline for all corporate-managed endpoints.
Covers: BitLocker, Secure Boot, OS minimum build (22621.2861), Defender real-time protection,
Windows Firewall (all profiles), PIN/password, and tamper/attestation checks.

Scope     : All Windows 11 Intune-enrolled devices (exclude kiosk/shared device group)
Owner     : DWP Digital Workplace Engineering
Grace period : 7 days (non-compliant → blocked from Conditional Access)
Review date  : Monthly – update Minimum OS version after each Patch Tuesday
Change ref   : [insert CHG/ticket number]
```

> **Why this matters:** The Description field is visible to other admins in the Compliance policy list and in audit exports. A clear description reduces the risk of another engineer unknowingly duplicating, disabling, or overwriting the policy. It also satisfies audit requirements for policy ownership and review cadence.

---

## Requirement 1 – BitLocker Must Be Enabled on the OS Drive

| Field | Detail |
|---|---|
| **Setting Name** | `Require BitLocker` |
| **UI Path** | Compliance settings → **Device Health** → Require BitLocker |
| **Value** | `Require` |
| **Effect** | Marks the device non-compliant if BitLocker Drive Encryption is not active on the operating system volume (C:\). Complements the BitLocker configuration profile but does not enforce encryption itself — it only reports status. |
| **False-Positive Risk** | Devices mid-encryption (encryption in progress) report as non-compliant until the process completes. Fresh Autopilot builds or devices recently re-imaged are particularly susceptible during the first login cycle. |
| **Recommendation** | Rely on the 7-day grace period to absorb in-progress encryption. Pair with a BitLocker configuration profile (Endpoint Security → Disk Encryption) that silently enables encryption so compliance is achieved before the grace period expires. |

---

## Requirement 2 – Secure Boot Must Be Enabled

| Field | Detail |
|---|---|
| **Setting Name** | `Require Secure Boot to be enabled on the device` |
| **UI Path** | Compliance settings → **Device Health** → Require Secure Boot to be enabled on the device |
| **Value** | `Require` |
| **Effect** | Verifies the UEFI firmware Secure Boot flag is active, preventing unsigned boot loaders and kernel-mode drivers from loading during startup. |
| **False-Positive Risk** | Legacy BIOS devices (non-UEFI) cannot report Secure Boot state and will always show as non-compliant. Dual-boot Linux configurations often require Secure Boot to be disabled. Virtual machines on older hypervisors may not expose the Secure Boot state correctly to the attestation service. |
| **Recommendation** | Confirm all estate hardware is UEFI-capable before enforcing. Exclude known legacy-BIOS device groups via a scoping assignment filter. If virtual desktop workloads are in scope, verify that the AVD/VDI session host SKU supports and reports Secure Boot via TPM attestation. |

> ✅ Both BitLocker and Secure Boot sit under **Device Health** in the current compliance policy wizard — not under System Security or Device Security.

---

## Requirement 3 – Minimum OS Build (N-1): 22621.2861

| Field | Detail |
|---|---|
| **Setting Name** | `Minimum OS version` |
| **UI Path** | Compliance settings → **Device Properties** → Minimum OS version |
| **Value** | `10.0.22621.2861` |
| **Effect** | Flags any Windows 11 22H2 device running a build older than 22621.2861 as non-compliant, ensuring the fleet is no more than one cumulative update behind the current known-good release (22621.3155). |
| **False-Positive Risk** | Devices with Windows Update paused or deferred via policy, devices on a WSUS ring that hasn't approved the required update, and newly enrolled devices pending their first update scan can all flag falsely. |
| **Recommendation** | Align the Intune Update Ring policy to target the same build. Set a 7-day deferral on Update Rings to give devices time to update after enrolment before compliance is evaluated. Review and increment the minimum build value monthly as new cumulative updates are released. |

---

## Requirement 4 – Windows Defender Real-Time Protection Must Be On

**UI Path:** Compliance settings → **System Security** → Defender

All four fields visible in the Defender section of the wizard are listed below with their required DWP baseline values.

| Setting (as shown in wizard) | Required Value | Reason |
|---|---|---|
| **Microsoft Defender Antimalware** | `Require` | Confirms Defender Antimalware service is running on the device |
| **Microsoft Defender Antimalware minimum version** | `Not configured` | Leave as default — enforcing a specific version number causes false positives whenever Microsoft releases an engine update and devices haven't yet received it |
| **Microsoft Defender Antimalware security intelligence up-to-date** | `Require` | Ensures virus/threat definitions are current; a device with outdated signatures is a compliance risk even if real-time protection is on |
| **Real-time protection** | `Require` | Core requirement — marks device non-compliant if real-time scanning is disabled |

| Field | Detail |
|---|---|
| **Effect** | Together these settings confirm that Defender is installed, running, carrying current definitions, and actively scanning in real time. A device fails compliance if any of the three `Require` fields are not met. |
| **False-Positive Risk** | Third-party AV products (e.g. CrowdStrike Falcon, Sophos) may register as the active AV and disable Defender real-time protection, causing non-compliance. Signature up-to-date check can also flag briefly after a definitions update is released but before the device has pulled it down. |
| **Recommendation** | If a third-party AV is in use, verify it correctly registers its real-time protection status with Windows Security Centre. Keep `Minimum version` as `Not configured` to avoid breaking compliance every Defender engine release. The 7-day grace period covers transient definition staleness. |

---

## Requirement 5 – Firewall Must Be Enabled for All Profiles

| Field | Detail |
|---|---|
| **Setting Name** | `Firewall` |
| **UI Path** | Compliance settings → **System Security** → Device Security → Firewall |
| **Value** | `Require` (applied to all three network profiles: Domain, Private, Public) |
| **Effect** | Ensures Windows Firewall is active on each network profile type. A device is non-compliant if any single profile reports the firewall as off, even if the other two are enabled. |
| **False-Positive Risk** | Third-party firewall products (e.g. Sophos, Palo Alto Cortex) may disable Windows Firewall when they take over the firewall role, but do not always register with Windows Security Centre in a way that satisfies this check. GPO-managed firewall policies that turn off the Windows Firewall service entirely (common in legacy domains) will cause persistent non-compliance. |
| **Recommendation** | Audit for any existing GPO or configuration profile that disables Windows Firewall. If a third-party firewall is the approved tool, either exclude affected devices or switch the compliance signal to one specific to that product. Do not disable this check entirely — use the exclusion group pattern instead. |

---

## Requirement 6 – A PIN or Password Must Be Configured

**UI Path:** Compliance settings → **System Security** → Password

All eight fields visible in the Password section of the wizard are listed below with their required DWP baseline values.

| Setting (as shown in wizard) | Required Value | Notes |
|---|---|---|
| **Require a password to unlock mobile devices** | `Require` | Master toggle — must be set to Require before the other fields activate |
| **Simple passwords** | `Block` | Prevents PINs like 1234 or 1111 |
| **Password type** | `Alphanumeric` | Stronger than "Device default"; enforces at least one letter and one number |
| **Minimum password length** | `8` | Wizard default is 4 — this must be raised to meet DWP baseline |
| **Maximum minutes of inactivity before password is required** | `5` | Auto-locks after 5 minutes of inactivity; wizard default is "Not configured" |
| **Password expiration (days)** | `90` (or `0` if Windows Hello for Business is deployed) | Wizard default is 41 — set to 90 for standard accounts; 0 disables expiry for WHfB |
| **Number of previous passwords to prevent reuse** | `5` | Prevents cycling back to recent passwords; wizard default is 5 — retain this value |
| **Require password when device returns from idle state (Mobile and Holographic)** | `Not configured` | This setting applies to Mobile/Holographic only and has no effect on Windows 11 desktops/laptops |

| Field | Detail |
|---|---|
| **Effect** | Together these settings ensure Windows 11 devices have a strong, regularly rotated lock-screen credential. Simple passwords are blocked, idle devices lock after 5 minutes, and users cannot immediately cycle back to a previous password. |
| **False-Positive Risk** | Shared-use kiosk devices intentionally configured without passwords will always flag. Windows Hello for Business-only deployments with no fallback password may report incorrectly depending on the Intune reporting API version. Devices where the user has not yet completed OOBE will briefly show non-compliant. |
| **Recommendation** | Create a separate compliance policy for kiosk/shared devices with relaxed password requirements, scoped via an Entra ID device group. For WHfB deployments, set Password expiration to `0` and ensure WHfB is fully provisioned before compliance evaluation runs — the 7-day grace period helps here. |

> ✅ Password settings are under **System Security → Password** in the current wizard. There is no separate "Device Lock" section for Windows 10/11 compliance policies.

---

## Requirement 7 – Tamper Detection (Windows 11 Equivalent of Jailbreak/Root Check)

> ❌ **"Jailbroken or rooted" does NOT exist as a setting in the Windows 10/11 compliance policy wizard.**  
> That toggle only appears when the platform is **iOS/iPadOS** or **Android**. If you are looking for it in your Windows policy, you will not find it — this is expected behaviour.  
>
> For Windows 11, tamper detection is split across **two separate sections** of the compliance wizard. Configure both as described below to achieve the same protection.

---

### Part A – Device Health Attestation (Built-in, no extra licence needed)

**UI Path:** Compliance settings → **Device Health**

All three fields in this section contribute to tamper detection:

| Setting (as shown in wizard) | Required Value | What it checks |
|---|---|---|
| **Require BitLocker** | `Require` | BitLocker protects at-rest data; tampering with the boot stack breaks the TPM seal |
| **Require Secure Boot to be enabled on the device** | `Require` | Blocks unsigned boot loaders and rootkits from loading before Windows starts |
| **Require code integrity** | `Require` | Verifies that drivers and system files have not been tampered with at boot time using TPM measurements |

These three settings together use the Windows **Health Attestation Service (HAS)**. The device's TPM records measurements at every boot. If any measurement deviates from the known-good baseline (indicating a tampered boot chain), the device fails attestation and is marked non-compliant.

---

### Part B – Microsoft Defender for Endpoint Risk Score (Requires MDE P1/P2 licence)

**UI Path:** Compliance settings → **Microsoft Defender for Endpoint**

| Setting (as shown in wizard) | Required Value | Available options |
|---|---|---|
| **Require the device to be at or under the machine risk score** | `Clear` | `Clear` · `Low` · `Medium` · `High` |

| Option | Meaning |
|---|---|
| `Clear` | No active threats detected — most restrictive, recommended for DWP baseline |
| `Low` | Minor threats present but remediated — allows devices with low-severity alerts |
| `Medium` | Active medium-severity threats — not recommended for compliance enforcement |
| `High` | Least restrictive — effectively not enforcing tamper detection |

> Set to **`Clear`** for the DWP security baseline. This marks any device with an unresolved MDE alert as non-compliant, providing the strongest tamper signal beyond what attestation alone can detect.

---

### Combined Effect

| Layer | Technology | Catches |
|---|---|---|
| Device Health (Part A) | TPM + Windows HAS | Boot-level tampering, rootkits, unsigned drivers, disabled Secure Boot |
| MDE Risk Score (Part B) | Defender for Endpoint sensors | Runtime threats, malware, suspicious behaviour, post-boot compromise |

Using both layers together is the Windows 11 equivalent of the jailbreak/root check on mobile platforms.

| Field | Detail |
|---|---|
| **False-Positive Risk** | **Part A:** Developer machines with Hyper-V nested virtualisation, WSL2 kernel, or custom test-signed drivers may fail code integrity checks. Devices without TPM 2.0 cannot generate an attestation report and will always show non-compliant. **Part B:** Devices that recently had an MDE alert that is now remediated may remain flagged until the risk score is recalculated (can take up to 24 hours). |
| **Recommendation** | Pre-requisite check before enabling Part B: confirm all Windows 11 devices are onboarded to MDE and the MDE–Intune connector is active in the tenant (`Endpoint security → Microsoft Defender for Endpoint`). Without the connector, the risk score field has no effect. Use the 7-day grace period to allow risk scores to clear after remediation. |

---

## Grace Period Configuration

| Setting | Value |
|---|---|
| **Grace period** | `7 days` |
| **UI Path** | Compliance policy wizard → **Actions for noncompliance** step → row `Mark device noncompliant` → set **Schedule (days after noncompliance)** to `7` |
| **Effect** | Devices that fall out of compliance are not immediately blocked from conditional access. They receive a 7-day window to self-remediate before the non-compliant state is enforced by any conditional access policies. |
| **Recommendation** | Supplement the grace period with an automated notification action: `Actions for noncompliance` → `Send email to end user` on day 1, and optionally again on day 5. This prompts users to resolve issues before enforcement kicks in. |

---

## Summary Table

| # | Requirement | Intune Setting Name | Value |
|---|---|---|---|
| 1 | BitLocker on OS drive | `Require BitLocker` | Require |
| 2 | Secure Boot enabled | `Require Secure Boot to be enabled on the device` | Require |
| 3 | Minimum OS build N-1 | `Minimum OS version` | `10.0.22621.2861` |
| 4 | Defender real-time protection | `Require real-time protection` | Require |
| 5 | Firewall all profiles | `Windows Firewall` (all profiles) | Require |
| 6 | PIN or password configured | `Password required` | Require |
| 7 | Tamper detection (no jailbreak setting on Windows) | `Require code integrity` (Device Health) + `Machine risk score: Clear` (MDE) | Require / Clear |
| – | Grace period | `Mark device noncompliant` (actions) | 7 days |

---

## Compliance Policy Wizard – Section Reference

Use this as a navigation guide when building the policy. Sections appear in this order inside the **Compliance settings** step.

| Wizard Section | Settings Configured Here |
|---|---|
| **Device Health** | Require BitLocker · Require Secure Boot · Require code integrity |
| **Device Properties** | Minimum OS version · Maximum OS version · Valid OS builds |
| **System Security → Password** | Require password · min length · password type · expiry |
| **System Security → Device Security** | Firewall · TPM · Antivirus · Antispyware |
| **System Security → Microsoft Defender** | Real-time protection · antimalware version · security intelligence |
| **Microsoft Defender for Endpoint** | Machine risk score (requires MDE integration in tenant) |
| **Actions for noncompliance** *(separate wizard step)* | Grace period (Mark device noncompliant: 7 days) · email notifications |

> ⚠️ The **Notifications** tab visible on the Compliance blade (top of the page) is for creating reusable email templates only — it is not where you configure the grace period. The grace period is set inside each individual policy under **Actions for noncompliance**.

---

## Post-Assignment Validation Steps

### Step 1 – Where to Find a Device's Compliance Status for This Policy

Two paths to the same result — use whichever is faster:

**From the policy:**
```
Intune admin center → Devices → Compliance → Policies tab
→ click this policy → Device status tab
→ find the device by name in the list
→ Status column shows: Compliant / Not compliant / In grace period / Not evaluated
```

**From the device:**
```
Intune admin center → Devices → All devices
→ search for and click the device name
→ Compliance tab (left nav within the device blade)
→ find this policy in the list → click it to see per-setting pass/fail detail
```

The **per-setting view** (second path) is essential for troubleshooting — it shows exactly which individual settings are failing, not just the overall status.

---

### Step 2 – What Each Compliance Status Means for Conditional Access

| Status | What it means | Conditional Access impact |
|---|---|---|
| **Compliant** | Device meets every setting in the policy | Access to all resources protected by CA policies is granted as normal |
| **In grace period** | Device has failed one or more settings but the 7-day grace period has not expired | **Access is still granted.** The device is treated as compliant by CA until the grace period expires. User may receive a notification email (if configured) but is not blocked. |
| **Not compliant** | Device has failed one or more settings AND the grace period has expired | **Access is blocked** by any CA policy that requires a compliant device. User sees an error when accessing M365 services and is directed to the Company Portal to remediate. |
| **Not evaluated** | Policy has been assigned but the device has not yet checked in, or the device was enrolled after the policy was scoped | CA treats this the same as Not compliant if the CA policy requires compliance. Device must sync before a status is assigned. |

> **Key point:** During the 7-day grace period a device is *reported* as non-compliant in the Intune dashboard but CA policies still grant access. A device only gets blocked when status is **Not compliant** (grace period expired) or **Not evaluated** (depending on CA configuration).

---

### Step 3 – BitLocker Showing Non-Compliant Despite Being Enabled

If the per-setting view shows `Require BitLocker` as **Not compliant** but you can confirm BitLocker is on, there are three common causes:

---

#### Cause 1: Encryption is in progress (not yet complete)

BitLocker reports as non-compliant until the drive is **100% encrypted**. A device mid-encryption is genuinely unprotected for the unencrypted portion.

| | Detail |
|---|---|
| **Fastest check** | On the device, run in PowerShell: `manage-bde -status C:` — look for `Percentage Encrypted`. Any value below 100% means encryption is still in progress. |
| **Fix** | Wait for encryption to complete. The 7-day grace period is designed to absorb this. Do not exclude the device from the policy. |

---

#### Cause 2: TPM attestation report has not refreshed

Intune reads BitLocker compliance status via the **Health Attestation Service**, not directly from the device. After BitLocker is enabled the HAS report must be refreshed. If the device has not re-attested since BitLocker was turned on, Intune is still reading the old (pre-encryption) report.

| | Detail |
|---|---|
| **Fastest check** | In Intune: **Devices → All devices → [device] → Hardware** tab → scroll to `TPM version`. If blank or missing, the device is not producing attestation reports. If populated, force a sync: **Devices → All devices → [device] → Sync** then wait 15 minutes and re-check compliance. |
| **Fix** | Force a device sync from the Intune portal or from **Settings → Accounts → Access work or school → Info → Sync**. The re-attestation cycle runs automatically on the next check-in. |

---

#### Cause 3: BitLocker is enabled but the OS drive protection is suspended or has no TPM protector

BitLocker can be "on" in a suspended state (common after BIOS/firmware updates or BitLocker troubleshooting). Intune's compliance check requires the drive to be **actively protected**, not merely enabled. Similarly, if BitLocker was configured with a password-only protector and no TPM, the HAS cannot verify it and reports non-compliant.

| | Detail |
|---|---|
| **Fastest check** | On the device, run in PowerShell: `manage-bde -status C:` — check `Protection Status`. If it shows `Protection Off` (even though `Conversion Status` is `Fully Encrypted`), BitLocker is suspended. Also check `Key Protectors` — a TPM protector must be listed. |
| **Fix** | To resume: `manage-bde -protectors -enable C:` — or reboot the device (BitLocker auto-resumes on next boot in most cases). If no TPM protector exists, the BitLocker configuration profile needs to be reviewed to enforce TPM-based protection. |

---

### First 24-Hour Monitoring Checklist

Run these checks at 2 hours, 6 hours, and 24 hours after policy assignment.

| Check | Where | What to act on |
|---|---|---|
| Overall non-compliant device count | Compliance policy → **Monitor** tab → Device status | If count is rising and not falling, investigate before grace period masks the real number |
| Top failing settings | Compliance policy → **Monitor** tab → Setting compliance | If `Require BitLocker` is the top failure, run Cause 1–3 checks above on a sample device |
| Grace period device count | Same Monitor tab | High grace-period count is acceptable in hour 1–2; should reduce steadily as devices sync and update |
| CA block events | **Entra ID → Sign-in logs** → filter `Status: Failure`, `Failure reason: Device is not compliant` | Any block during business hours means users are actively locked out — escalate immediately |
| Devices with status "Not evaluated" | Compliance policy → Device status → filter by Not evaluated | These devices have not checked in yet; trigger a sync via Intune or ask the user to open Company Portal |

---

*Document generated for DWP internal use. Review against live Intune tenant before policy deployment.*
