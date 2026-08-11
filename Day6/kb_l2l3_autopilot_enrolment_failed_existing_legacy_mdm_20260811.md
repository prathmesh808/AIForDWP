# L2/L3 Knowledge Base: Autopilot Enrolment Failure — Existing Legacy MDM Enrolment (0x80180014)

| Field | Detail |
|---|---|
| **Version** | 1.0 |
| **Date** | 11/08/2026 |
| **Author** | prathameshgavade |
| **Reviewed by** | self |
| **Status** | Draft |
| **Change** | Initial version from RCA — DESKTOP-FB099 / FINBRIDGE\rthomas |

---

## 1. Background

Windows Autopilot is the mechanism by which FinBridge provisions and configures new or re-deployed Windows endpoints without manual imaging. When a device is switched on for the first time (or after a reset), it contacts Microsoft Intune during OOBE (Out-of-Box Experience), downloads its assigned Autopilot profile, and applies security baselines and configuration policies automatically via the Enrolment Status Page (ESP).

For Autopilot enrolment to succeed, the device must have **no existing MDM management relationship** in Intune. If a managed device object from a prior manual or legacy MDM enrolment still exists in the tenant, Intune rejects the new enrolment with error `0x80180014`. This matters because the device ships to the user in an unmanaged, unconfigured state — no security baseline, no compliance evaluation, no policy — until the conflict is resolved.

---

## 2. Symptom

### What the engineer observes
- Autopilot enrolment state in Intune shows **Failed**.
- Primary enrolment error: **`0x80180014`** — *MDMEnrollmentFailed — device already enrolled in MDM*.
- Policy error on the device object: **`0x80070005`** — *Access denied*.
- Profile application count: **0 of 4** profiles applied.
- A second (older) managed device object for the same device name or serial number exists in Intune with a legacy enrolment date.
- Azure AD joined state: **Yes** (join is present; it is only the MDM enrolment that fails).
- Licensing: Intune P1 and Autopilot licences confirmed assigned to user.
- Network: All required Autopilot and Intune endpoints reachable; no proxy blocking.

### What the user reports
- Computer stopped during first-time setup and shows a problem screen.
- Setup screen has not progressed for several minutes.
- Error code visible on screen (may read out as a long number starting with `0x80`).
- User has not been able to reach the Windows desktop.

---

## 3. Root Cause

A stale legacy manual MDM enrolment record — enrolled **2023-11-04** — remains bound to the device context in Intune. When Autopilot attempts to register the new MDM management relationship, Intune detects the existing record and returns `0x80180014` (device already enrolled). Because the MDM channel cannot be established, the ESP cannot download or apply policy, producing `0x80070005` (Access denied) on all four target profiles.

**Evidence that confirms this specific cause (not another):**

| Evidence | Where to find it | What it shows |
|---|---|---|
| Error `0x80180014` on Autopilot enrolment | Intune > Devices > All devices > device record > Overview blade > **Enrolment error** field | Device rejected because already enrolled |
| A second Intune device object with enrolment date 2023-11-04 | Intune > Devices > All devices > search by device name — two rows returned | Stale legacy record still active |
| Error `0x80070005` on policy state | Intune > Devices > All devices > device record > **Device configuration** blade > State column | Access denied on policy apply — MDM channel not established |
| `0 of 4` profiles applied | Same Device configuration blade > profile applied count | No policy applied at all — total MDM failure, not partial |
| `MDMUrl` populated with legacy value in `dsregcmd /status` | Device > elevated command prompt > `dsregcmd /status` > `Device State` section > `MDMUrl` field | Local device still bound to old MDM endpoint |
| Event ID 75 / 76 in DeviceManagement log | Device > Event Viewer — see Detection section | MDM enrolment attempted and failed at device level |

---

## 4. Detection

Work through every step below before acting. Target: complete all steps in under 3 minutes using the PowerShell commands provided. If all checks confirm positive, this runbook applies. If any check does not match, stop and investigate the differing signal before proceeding.

---

### Quick-extract commands (run these first — under 60 seconds)

Run the following PowerShell commands on the affected device from an **elevated PowerShell prompt** to extract the key evidence without clicking through Event Viewer. Copy all output to your notepad before proceeding.

**Command 1 — Pull all relevant MDM enrolment and policy failure events in one shot:**
```powershell
Get-WinEvent -LogName "Microsoft-Windows-DeviceManagement-Enterprise-Diagnostics-Provider/Admin" |
  Where-Object { $_.Id -in @(75, 76, 305, 404) } |
  Select-Object TimeCreated, Id, Message |
  Format-List
```
> Expected on a failed device: Events with ID 75 and/or 76 containing `0x80180014`, followed by ID 404 events containing `0x80070005`. Event ID 305 may appear if the Autopilot profile could not be processed.

**Command 2 — Pull Azure AD join and MDM binding state:**
```powershell
dsregcmd /status
```
> Pipe through `findstr` to extract only the key fields quickly:
```powershell
dsregcmd /status | findstr /i "AzureAdJoined EnterpriseJoined MDMUrl MDMEnrollmentState"
```

**Command 3 — Pull User Device Registration events (Azure AD join failures):**
```powershell
Get-WinEvent -LogName "Microsoft-Windows-User Device Registration/Admin" |
  Where-Object { $_.Id -in @(201, 202, 204, 211) } |
  Select-Object TimeCreated, Id, Message |
  Format-List
```
> Expected on a failed device: Event ID 201 (join attempt) with no matching 202 (join success), or event 204/211 indicating token acquisition or tenant discovery failure. If these events are absent or show success, the Azure AD join is healthy and the failure is MDM-only.

**Command 4 — Check for stale MDM enrolment registry entries:**
```powershell
Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Enrollments" |
  Select-Object Name, @{N="LastWrite";E={$_.LastWriteTime}} |
  Sort-Object LastWrite
```
> Expected on a failed device: Two or more subkeys present. The older subkey (earlier LastWrite timestamp) is the stale legacy enrolment. The GUID of that subkey is the enrolment ID to target during cleanup.

**Command 5 — Query Intune device state via Microsoft Graph (run from any machine with Graph access):**
```powershell
# Requires: Install-Module Microsoft.Graph -Scope CurrentUser (if not already installed)
Connect-MgGraph -Scopes "DeviceManagementManagedDevices.Read.All"
Get-MgDeviceManagementManagedDevice -Filter "deviceName eq 'DESKTOP-FB099'" |
  Select-Object DeviceName, SerialNumber, EnrolledDateTime, ManagementState, ComplianceState, Id
```
> Expected on a failed device: Two records returned for the same device name — one with a legacy `EnrolledDateTime` (2023-11-04) and `ManagementState` of `retirePending` or `unhealthy`, and one with a current failed state. If only one record returns, the duplicate has already been cleared.

---

### Detection Step 1 — Confirm enrolment error code in Intune portal

**Portal:** `https://intune.microsoft.com`
**Path:** Left nav > **Devices** > **All devices** > search device name > click device > **Overview** blade
**Field:** **Enrolment state** and **Enrolment error**

- Enrolment state must show **Failed**.
- Enrolment error code must show **`0x80180014`**.

> `0x80180014` = `MDMEnrollmentFailed — The device is already enrolled`. If you see `0x80180026` (device not in allowed group) or `0x80070774` (Autopilot profile not found), this runbook does not apply — investigate the specific code.

---

### Detection Step 2 — Confirm duplicate stale device object in Intune

**Portal:** `https://intune.microsoft.com`
**Path:** Left nav > **Devices** > **All devices** > type device name in search box > press Enter

- If **two rows** return for the same device name, a stale record is present.
- Click the older row. On the **Overview** blade, check the **Enrolled** date — must be older than the current deployment (e.g. 2023-11-04).

**PowerShell equivalent (faster):**
```powershell
Connect-MgGraph -Scopes "DeviceManagementManagedDevices.Read.All"
Get-MgDeviceManagementManagedDevice -Filter "deviceName eq 'DESKTOP-FB099'" |
  Select-Object DeviceName, Id, EnrolledDateTime, ManagementState | Format-Table
```
> If only one row returns, the duplicate is gone or the cause is different. Do not proceed with this runbook.

---

### Detection Step 3 — Confirm policy error `0x80070005` and zero profiles applied

**Portal:** `https://intune.microsoft.com`
**Path:** Left nav > **Devices** > **All devices** > device name > left blade menu > **Device configuration**

- Profile applied count must show **0** successes (e.g. 0/4).
- At least one profile must show error code **`0x80070005`** (Access denied) in the State detail column.

> `0x80070005` = `ERROR_ACCESS_DENIED`. On a failed MDM channel, all profiles fail with this code. If only one profile fails with `0x80070005` and others succeed, the failure is profile-specific — this runbook does not apply.

---

### Detection Step 4 — Confirm stale Entra device object

**Portal:** `https://entra.microsoft.com`
**Path:** Left nav > **Identity** > **Devices** > **All devices** > search device name

- Check **Registered** date — must match the legacy enrolment date from Detection Step 2.
- Check **MDM** column — may still reference the old MDM authority.

**PowerShell equivalent:**
```powershell
Connect-MgGraph -Scopes "Directory.Read.All"
Get-MgDevice -Filter "displayName eq 'DESKTOP-FB099'" |
  Select-Object DisplayName, DeviceId, RegisteredDateTime, ManagementType | Format-Table
```
> If no Entra object exists, skip the Entra deletion step in Resolution but continue all other steps.

---

### Detection Step 5 — Confirm stale local MDM binding on the device

**Access:** Elevated command prompt or PowerShell on the device.

Run Command 2 from the Quick-extract section above, or the full command:
```powershell
dsregcmd /status | findstr /i "AzureAdJoined EnterpriseJoined MDMUrl MDMEnrollmentState"
```

**Required field values to confirm this cause:**

| Field | Failing device value | Healthy device value |
|---|---|---|
| `AzureAdJoined` | `YES` | `YES` |
| `EnterpriseJoined` | `YES` | `YES` |
| `MDMUrl` | Legacy MDM URL (non-blank, non-Intune) | `https://enrollment.manage.microsoft.com/enrollmentserver/discovery.svc` |
| `MDMEnrollmentState` | Non-zero (e.g. `1` or `3`) | `0` |

> If `MDMUrl` is blank and `MDMEnrollmentState` is `0`, the local binding is already cleared. Skip Phase E of Resolution.

---

### Detection Step 6 — Confirm failure event chain in device event logs

Run Command 1 from the Quick-extract section, or use Event Viewer manually:

**Log 1 — MDM enrolment and policy failures:**
**Event Viewer path:** `Applications and Services Logs` → `Microsoft` → `Windows` → `DeviceManagement-Enterprise-Diagnostics-Provider` → **Admin**

**Log 2 — Azure AD join events:**
**Event Viewer path:** `Applications and Services Logs` → `Microsoft` → `Windows` → `User Device Registration` → **Admin**

**Required Event IDs and what to look for:**

| Event ID | Log | Meaning | Exact text / code to find in Description |
|---|---|---|---|
| **75** | DeviceManagement-Enterprise-Diagnostics-Provider/Admin | MDM enrolment session started | Look for `MDM Enroll` with result code `0x80180014` |
| **76** | DeviceManagement-Enterprise-Diagnostics-Provider/Admin | MDM enrolment session ended with error | Must contain `0x80180014` — *"The device is already enrolled"* |
| **305** | DeviceManagement-Enterprise-Diagnostics-Provider/Admin | Autopilot profile processing issue | Contains `AutopilotManager` and a non-zero error code; present if profile could not be applied during OOBE |
| **404** | DeviceManagement-Enterprise-Diagnostics-Provider/Admin | MDM policy/configuration application failed | Must contain `0x80070005` — *"Access is denied"* |
| **201** | User Device Registration/Admin | Azure AD join attempted | Present — join was attempted |
| **202** | User Device Registration/Admin | Azure AD join succeeded | Should be present; if absent alongside 201, the join itself failed (different cause) |

**Expected failure pattern on this device:**
```
Event 75  — MDM enrolment started
Event 76  — MDM enrolment failed: 0x80180014 "already enrolled"
Event 404 — Policy apply failed: 0x80070005 "Access denied" (repeats per profile)
Event 305 — Autopilot profile not applied (may appear)
Event 201 — Azure AD join attempted (join is separate and may succeed)
Event 202 — Azure AD join succeeded (confirms join ≠ cause)
```

> Screenshot or copy event details before making any changes: right-click each event > **Copy** > **Copy Details as Text**.

---

### Detection Step 7 — Healthy baseline comparison (unaffected control device)

Before acting, compare the failing device output against a **known-good enrolled device** on the same tenant to confirm the failure is device-specific and not a tenant-wide outage.

On a healthy enrolled device, run:
```powershell
dsregcmd /status | findstr /i "AzureAdJoined EnterpriseJoined MDMUrl MDMEnrollmentState"
```
And:
```powershell
Get-WinEvent -LogName "Microsoft-Windows-DeviceManagement-Enterprise-Diagnostics-Provider/Admin" |
  Where-Object { $_.Id -in @(75, 76, 305, 404) } |
  Select-Object TimeCreated, Id, Message | Format-List
```

**Healthy baseline — what a successfully enrolled device shows:**

| Signal | Healthy value |
|---|---|
| `AzureAdJoined` | `YES` |
| `MDMUrl` | `https://enrollment.manage.microsoft.com/enrollmentserver/discovery.svc` |
| `MDMEnrollmentState` | `0` |
| Event ID 75 | Present — enrolment started |
| Event ID 76 | Present — enrolment completed with result `0x0` (success) |
| Event ID 404 | Absent (no policy failures) |
| Event ID 305 | Absent or present with result `0x0` |
| Event ID 202 (User Device Registration) | Present — Azure AD join succeeded |
| Intune > All devices | Single device record with current enrolment date, MDM = Microsoft Intune, Compliance = Compliant |

> If the healthy device shows the same `0x80180014` events, the issue may be tenant-wide. Do not proceed with single-device cleanup — raise a P1 and investigate Intune service health at `https://admin.microsoft.com` > **Health** > **Service health**.

---

### Detection Step 8 — Rule out licensing and network as the cause

**Licensing — PowerShell check:**
```powershell
Connect-MgGraph -Scopes "User.Read.All"
Get-MgUserLicenseDetail -UserId "rthomas@finbridge.com" |
  Select-Object SkuPartNumber | Format-Table
```
> Output must include a SKU that contains Intune (e.g. `SPE_E3`, `EMS`, `INTUNE_A`). If absent, licence assignment is the root cause — stop and assign before MDM cleanup.

**Network — PowerShell check:**
```powershell
Test-NetConnection -ComputerName enrollment.manage.microsoft.com -Port 443
Test-NetConnection -ComputerName enterpriseregistration.windows.net -Port 443
Test-NetConnection -ComputerName login.microsoftonline.com -Port 443
```
> All three must return `TcpTestSucceeded : True`. If any return `False`, a firewall or proxy is blocking Autopilot endpoints — investigate network before MDM cleanup.

> If licensing and network both pass, the stale MDM record is confirmed as the cause. Proceed to Resolution.

---

## 5. Resolution

> Steps marked **[ELEVATED]** require Intune/Entra admin write permissions or local admin rights on the device. Do not proceed with a step if you do not hold the required access — escalate.
>
> Every phase includes a **PowerShell alternative** for speed. Portal steps and PowerShell steps achieve the same outcome — use whichever is faster for your situation.

---

### Phase A — Record all identifiers before making any change

**Remediation action:** Collect device identifiers — no changes made in this phase.

**Portal:** `https://intune.microsoft.com`
**Path:** Left nav > **Devices** > **All devices** > type device name in search > click device record > **Overview** blade

Record all seven values in your notepad before touching anything:
- Device name
- Serial number
- Intune Device ID (labelled "Device ID" on Overview blade)
- Azure AD Device ID
- Primary user UPN
- Enrolment date of the stale record
- Autopilot profile name

**Then confirm Autopilot hardware hash:**
**Path:** Left nav > **Devices** > **Windows** > **Windows enrollment** > **Devices** *(under Windows Autopilot heading)* > search by serial number
- Record: Profile column value (must show `FinBridge-Autopilot-Standard`)

**PowerShell alternative — collect all identifiers in one command:**
```powershell
Connect-MgGraph -Scopes "DeviceManagementManagedDevices.Read.All"
Get-MgDeviceManagementManagedDevice -Filter "deviceName eq 'DESKTOP-FB099'" |
  Select-Object DeviceName, SerialNumber, Id, AzureAdDeviceId, EnrolledDateTime, ManagementState, UserId |
  Format-List
```
> Copy all output to notepad. The `Id` field = Intune Device ID. `AzureAdDeviceId` = Azure AD Device ID.

> **Stop condition:** If the Autopilot hardware hash row is not found or has no profile assigned, do not proceed — escalate to confirm profile assignment.

---

### Phase B — Retire and delete the stale Intune managed device object [ELEVATED]

**Remediation action:** Delete stale Autopilot / MDM registration from Intune.

**Portal:** `https://intune.microsoft.com`
**Path:** Left nav > **Devices** > **All devices** > search device name > click the **stale** device record (older enrolment date)

**Step B1.** Click **Retire** in the top toolbar > click **Yes** to confirm.
> Expected result: Notification banner confirms Retire issued. **Device actions status** on Overview blade changes from **Pending** → **Completed** within 5 minutes (online device). Offline device stays **Pending** — acceptable; note in ticket and continue.

**Step B2.** Click **Delete** in the top toolbar > click **Yes** to confirm.
> Expected result: Navigate back to **All devices**, search device name — only one row remains. If two rows still appear after a 2-minute page refresh, wait and refresh again.

**PowerShell alternative — retire then delete via Graph:**
```powershell
Connect-MgGraph -Scopes "DeviceManagementManagedDevices.ReadWrite.All"

# Replace with the Intune Device ID of the STALE record recorded in Phase A
$staleDeviceId = "<PASTE-STALE-INTUNE-DEVICE-ID-HERE>"

# Retire the stale device
Invoke-MgRetireDeviceManagementManagedDevice -ManagedDeviceId $staleDeviceId

# Wait 30 seconds then delete
Start-Sleep -Seconds 30
Remove-MgDeviceManagementManagedDevice -ManagedDeviceId $staleDeviceId

# Confirm only one record remains
Get-MgDeviceManagementManagedDevice -Filter "deviceName eq 'DESKTOP-FB099'" |
  Select-Object DeviceName, Id, EnrolledDateTime | Format-Table
```
> Expected result: Only one row returned with today's enrolment date.

---

### Phase C — Delete the stale Entra device object [ELEVATED]

**Remediation action:** Remove duplicate Entra device object.

**Portal:** `https://entra.microsoft.com`
**Path:** Left nav > **Identity** > **Devices** > **All devices** > search device name or Azure AD Device ID from Phase A

**Step C1.** Click the **checkbox** next to the stale device object. Click **Delete** in the toolbar. Confirm when prompted.
> Expected result: Object removed from list.
> **Critical:** Do not go to the Intune Autopilot devices list and delete the hardware hash record — that must remain.

**PowerShell alternative:**
```powershell
Connect-MgGraph -Scopes "Directory.ReadWrite.All"

# Replace with Azure AD Device ID of the STALE Entra object recorded in Phase A
$staleAadDeviceId = "<PASTE-STALE-AZURE-AD-DEVICE-ID-HERE>"

$entraDevice = Get-MgDevice -Filter "deviceId eq '$staleAadDeviceId'"
Remove-MgDevice -DeviceId $entraDevice.Id

# Confirm removal
Get-MgDevice -Filter "displayName eq 'DESKTOP-FB099'" |
  Select-Object DisplayName, DeviceId, RegisteredDateTime | Format-Table
```
> Expected result: Only one Entra device object returned, or none (if the device re-registers fresh during OOBE).

---

### Phase D — Verify Autopilot hardware hash and profile assignment are intact

**Remediation action:** Confirm hardware hash record present; assign correct Autopilot profile if missing.

**Portal:** `https://intune.microsoft.com`
**Path:** Left nav > **Devices** > **Windows** > **Windows enrollment** > **Devices** *(Windows Autopilot Devices)* > search by serial number

**Step D1.** Confirm the serial number row is present. Read the **Profile** column — must show `FinBridge-Autopilot-Standard`.

- **If profile is blank:** Click the device row > click **Assign profile** in the toolbar > select **FinBridge-Autopilot-Standard** > click **Save**. Refresh and confirm.
- **If the row is completely missing:** Go to **Rollback R1** immediately. Do not proceed.

> Expected result: Hardware hash record present with `FinBridge-Autopilot-Standard` in the Profile column.

---

### Phase D2 — Check Enrollment Status Page configuration

**Remediation action:** Confirm ESP is configured and will not block enrolment unexpectedly.

**Portal:** `https://intune.microsoft.com`
**Path:** Left nav > **Devices** > **Windows** > **Windows enrollment** > **Enrollment Status Page** > click **Default** profile

Confirm the following settings:
- **Show app and profile configuration progress** = **Yes**
- **Block device use until all apps and profiles are installed** — note current setting (do not change unless directed by your team lead)
- **Allow users to reset device if installation error occurs** — note current setting

> This is a read-only check. Do not modify ESP settings without a change request. If the ESP is blocking enrolment due to a misconfigured app requirement, escalate — this runbook does not cover ESP app assignment failures.

---

### Phase D3 — Verify MDM User Scope in Entra

**Remediation action:** Confirm the affected user is in scope for Intune MDM auto-enrolment.

**Portal:** `https://entra.microsoft.com`
**Path:** Left nav > **Identity** > **Mobility (MDM and MAM)** > **Microsoft Intune** > **MDM User Scope**

Confirm:
- **MDM User Scope** is set to **All** or **Some** (with the affected user's group included).
- If set to **None**, MDM auto-enrolment is disabled for all users — this is a separate root cause. Do not proceed with MDM cleanup; escalate to fix the scope setting first.
- If set to **Some**, click **Groups** and confirm the affected user's group (e.g. `SG-Intune-Licensed-Users`) is listed.

**PowerShell check:**
```powershell
Connect-MgGraph -Scopes "Policy.Read.All"
Get-MgPolicyMobileDeviceManagementPolicy | Select-Object AppliesTo, Description | Format-List
```
> `AppliesTo` must not return `none`. If it does, MDM scope is the root cause — escalate.

---

### Phase E — Disconnect legacy work account on the device

**Remediation action:** Remove stale local MDM work account connection.

**Access:** Interactive session on device (RDP or physical)
**Path on device:** **Start** > **Settings** (gear icon) > **Accounts** > **Access work or school**

**Step E1.** Click the legacy organisational account or MDM connection entry (briefcase icon, references old domain or MDM authority). Click **Disconnect** > click **Yes** on confirmation. Repeat for any additional legacy entries.
> Expected result: No legacy entries remain in the Access work or school list. If no entries were present, continue to Phase F.

---

### Phase F — Confirm and clean local MDM artefacts [ELEVATED]

**Remediation action:** Remove stale local MDM enrolment artefacts (scheduled tasks, registry, certificates).

**Step F1.** Open an elevated PowerShell prompt (right-click Start > **Terminal (Admin)**) and run:
```powershell
dsregcmd /status | findstr /i "MDMUrl MDMEnrollmentState"
```
> If both return blank / `0`, skip to Phase G.
> If stale values remain, continue to Step F2.

**Step F2 — Identify the stale enrolment GUID:**
```powershell
# List all enrolment subkeys with timestamps — the oldest is the stale legacy record
Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Enrollments" |
  Select-Object Name, LastWriteTime | Sort-Object LastWriteTime
```
> Record the GUID of the **oldest** subkey. This is `$staleGuid` used in the steps below.

**Step F3 — Remove stale scheduled tasks:**
```powershell
$staleGuid = "<PASTE-STALE-GUID-HERE>"
Unregister-ScheduledTask -TaskPath "\Microsoft\Windows\EnterpriseMgmt\$staleGuid\" -TaskName * -Confirm:$false
```
> Or manually: `Win + R` > `taskschd.msc` > expand `Task Scheduler Library > Microsoft > Windows > EnterpriseMgmt` > right-click the folder matching the stale GUID > **Delete**.

**Step F4 — Remove stale registry enrolment branch:**
```powershell
$staleGuid = "<PASTE-STALE-GUID-HERE>"
Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\Enrollments\$staleGuid" -Recurse -Force
```
> Or manually: `Win + R` > `regedit.exe` > navigate to `HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Enrollments` > right-click the subkey matching the stale GUID > **Delete**.

**Step F5 — Remove stale MDM certificate:**
```powershell
# List certificates in the local machine Personal store and find the stale MDM cert
Get-ChildItem Cert:\LocalMachine\My | Where-Object { $_.Issuer -like "*<OldMDMAuthority>*" } |
  Select-Object Thumbprint, Subject, Issuer, NotAfter
```
> Replace `<OldMDMAuthority>` with the issuer name visible in the certificate. Then delete:
```powershell
$thumbprint = "<PASTE-THUMBPRINT-HERE>"
Remove-Item -Path "Cert:\LocalMachine\My\$thumbprint" -Force
```
> Or manually: `Win + R` > `certlm.msc` > **Personal** > **Certificates** > locate certificate issued by the old MDM authority referencing the stale enrolment GUID > right-click > **Delete**.

**Step F6 — Confirm clean state:**
```powershell
dsregcmd /status | findstr /i "MDMUrl MDMEnrollmentState"
```
> Both fields must return blank or `0`. If stale values persist after all removals, stop and escalate — do not reboot.

---

### Phase G — Reboot and retry OOBE enrolment

**Remediation action:** Retry OOBE enrolment after stale record cleanup.

**Step G1.** Confirm the user is present at the device. On the device click **Start** > **Power** > **Restart**.
> Expected result: Device reboots. Remote session disconnects — expected.

**Step G2.** User completes OOBE in this order:
1. Select **region** and **keyboard layout** > click **Yes**.
2. At **Sign in with Microsoft**, type the full UPN (`rthomas@finbridge.com`) > enter password > complete any MFA prompt.
3. **Enrolment Status Page (ESP)** appears showing two progress bars — **Device setup** and **Account setup**. User must wait without clicking anything until both bars show green ticks.

> Expected result: User reaches the Windows desktop. Error `0x80180014` must not appear at any point during OOBE or ESP.
> If ESP stalls for more than 30 minutes without progress, note which phase is stuck and go to Rollback R2.

---

## 6. Verification

All five checks must pass before the ticket can be closed. Use the quick-validation PowerShell block first — it covers checks 1, 3, and 4 in under 60 seconds — then complete checks 2 and 5 manually.

---

### Quick validation commands (run immediately after OOBE completes)

**Run from any machine with Graph access:**
```powershell
Connect-MgGraph -Scopes "DeviceManagementManagedDevices.Read.All","DeviceManagementConfiguration.Read.All"

# Check 1: Confirm single device record with current enrolment date
Get-MgDeviceManagementManagedDevice -Filter "deviceName eq 'DESKTOP-FB099'" |
  Select-Object DeviceName, SerialNumber, EnrolledDateTime, ManagementState, ComplianceState | Format-Table

# Check 3: Confirm policy profile states
$deviceId = (Get-MgDeviceManagementManagedDevice -Filter "deviceName eq 'DESKTOP-FB099'").Id
Get-MgDeviceManagementManagedDeviceConfigurationState -ManagedDeviceId $deviceId |
  Select-Object DisplayName, State | Format-Table
```

**Run on the device (elevated PowerShell):**
```powershell
# Check 4: Confirm no new MDM failure events after enrolment
$enrolmentTime = (Get-Date).AddHours(-2)  # Adjust window if needed
Get-WinEvent -LogName "Microsoft-Windows-DeviceManagement-Enterprise-Diagnostics-Provider/Admin" |
  Where-Object { $_.Id -in @(75,76,404) -and $_.TimeCreated -gt $enrolmentTime } |
  Select-Object TimeCreated, Id, Message | Format-List
```
> Expected on success: Check 1 returns one row with today's date. Check 3 shows `FinBridge-Win11-Security-Baseline` with State = `succeeded`. Check 4 returns no output (no new failure events).

---

**Check 1 — Single Intune device record with current enrolment date**

**Portal:** `https://intune.microsoft.com`
**Path:** Left nav > **Devices** > **All devices** > search device name > click device > **Overview** blade

| Field | Required value | Fail condition |
|---|---|---|
| Enrolled date | 2026-08-11 (today) | Still shows 2023-11-04 — stale record was not deleted |
| MDM | Microsoft Intune | Blank or other authority — enrolment failed |
| Compliance | Compliant or In grace period | "Not evaluated" after 15+ minutes — policy sync failed |
| Management state | Managed | Retire pending or unhealthy — retire was not completed |

> Fail action: If enrolled date is still legacy, repeat Phase B. If management state is unhealthy, escalate.

---

**Check 2 — Autopilot ESP completed without error**

Ask the user directly:
1. "Did you reach the normal Windows desktop after the setup screens?"
2. "Did you see any error screen or a code starting with `0x80`?"

| Answer | Result |
|---|---|
| Reached desktop, no errors | Pass |
| Error screen appeared / code seen | Fail — go to Rollback R2 |
| ESP is still loading | Wait up to 30 minutes total; if still stuck, go to Rollback R2 |

---

**Check 3 — Policy baseline applied**

**Portal:** `https://intune.microsoft.com`
**Path:** Left nav > **Devices** > **All devices** > device name > left blade menu > **Device configuration**

| Check | Required value | Fail condition |
|---|---|---|
| FinBridge-Win11-Security-Baseline > State | **Succeeded** | Error or Conflict — take screenshot, escalate |
| Total profiles with State = Succeeded | > 0 (was 0/4 before fix) | Still 0/4 — MDM channel not established, escalate |

---

**Check 4 — No MDM failure events in device event log after new enrolment**

**Portal / tool:** Device — elevated PowerShell or Event Viewer
**Event Viewer path:** `Applications and Services Logs` → `Microsoft` → `Windows` → `DeviceManagement-Enterprise-Diagnostics-Provider` → **Admin**

Filter Event IDs `75, 76, 404` and confirm no entries timestamped after the new enrolment carry `0x80180014` or `0x80070005`.

| Expected | Pass |
|---|---|
| Event ID 75 + 76 with result `0x0` after enrolment time | Enrolment succeeded |
| Event ID 404 absent after enrolment time | No policy failures |
| Event ID 75/76 with `0x80180014` after enrolment time | Fail — go to Rollback R2 |

---

**Check 5 — Autopilot hardware hash record still present with correct profile**

**Portal:** `https://intune.microsoft.com`
**Path:** Left nav > **Devices** > **Windows** > **Windows enrollment** > **Devices** *(Windows Autopilot Devices)* > search by serial number

| Field | Required value |
|---|---|
| Serial number row | Present |
| Profile column | FinBridge-Autopilot-Standard |
| Group tag | As expected per deployment spec |

> If profile is blank after successful enrolment, reassign `FinBridge-Autopilot-Standard` via the **Assign profile** button on the device row.

---

### Final success criteria

The incident is resolved and the ticket may be closed **only when all of the following are simultaneously true:**

- [ ] `Get-MgDeviceManagementManagedDevice` returns exactly **one** record for the device name with `EnrolledDateTime` = today and `ManagementState` = `managed`
- [ ] `Get-MgDeviceManagementManagedDeviceConfigurationState` returns `FinBridge-Win11-Security-Baseline` with `State` = `succeeded`
- [ ] No Event ID 75/76 entries containing `0x80180014` appear after the new enrolment timestamp
- [ ] No Event ID 404 entries containing `0x80070005` appear after the new enrolment timestamp
- [ ] User confirms they can sign in and use the device normally
- [ ] Intune > **Devices** > **All devices** shows **one** device record — not two

If any criterion is not met, do not close the ticket. Escalate with the specific failing check identified.

---

## 7. Rollback

> **When to use rollback:** Trigger rollback the moment you observe the symptom described at the top of each block. Do not continue with the resolution phases while a rollback condition is active. Each block is self-contained — read only the block that matches your situation.

---

**R1 — Autopilot hardware hash row missing or profile blank after Phase C or D**

**Trigger:** You searched `https://intune.microsoft.com` > **Devices** > **Windows** > **Windows enrollment** > **Devices** by serial number and the row is missing OR the Profile column is blank.

**Do not reboot the device or start OOBE.**

**Option A — Row is completely missing (hash was accidentally deleted):**

1. Go to `https://intune.microsoft.com`. Left nav > **Devices** > **Windows** > **Windows enrollment** > **Devices** *(Windows Autopilot Devices)*.
2. Click **Import** in the top toolbar.
3. Upload the hardware hash CSV for the device using the serial number from your Phase A notes.
4. Refresh the list every 60 seconds until the row reappears (may take up to 5 minutes).
5. Once the row appears, continue to Option B step 2 to assign the profile.

**Option B — Row exists but Profile column is blank:**

1. Go to `https://intune.microsoft.com` > **Devices** > **Windows** > **Windows enrollment** > **Devices** *(Windows Autopilot Devices)* > search by serial number.
2. Click the device row to open it.
3. Click **Assign profile** in the top toolbar (or click the **Profile** field directly).
4. Select **FinBridge-Autopilot-Standard** from the dropdown.
5. Click **Save**.
6. Refresh the list. Confirm the **Profile** column shows `FinBridge-Autopilot-Standard`.

**PowerShell alternative — assign profile via Graph:**
```powershell
Connect-MgGraph -Scopes "DeviceManagementServiceConfig.ReadWrite.All"

# Get the Autopilot device record by serial number
$serialNumber = "<PASTE-SERIAL-NUMBER-HERE>"
$autopilotDevice = Get-MgDeviceManagementWindowsAutopilotDeviceIdentity |
  Where-Object { $_.SerialNumber -eq $serialNumber }

# Get the profile ID for FinBridge-Autopilot-Standard
$profile = Get-MgDeviceManagementWindowsAutopilotDeploymentProfile |
  Where-Object { $_.DisplayName -eq "FinBridge-Autopilot-Standard" }

# Assign the profile
$params = @{ "@odata.id" = "https://graph.microsoft.com/v1.0/deviceManagement/windowsAutopilotDeploymentProfiles/$($profile.Id)" }
New-MgDeviceManagementWindowsAutopilotDeviceIdentityDeploymentProfileAssignedDeviceByRef `
  -WindowsAutopilotDeviceIdentityId $autopilotDevice.Id -BodyParameter $params
```

**Quick validation after R1:**
```powershell
Get-MgDeviceManagementWindowsAutopilotDeviceIdentity |
  Where-Object { $_.SerialNumber -eq "<SERIAL-NUMBER>" } |
  Select-Object SerialNumber, DeploymentProfileAssignmentStatus | Format-List
```
> Must return `DeploymentProfileAssignmentStatus = assigned`. Proceed to OOBE only after this confirms.

> **Escalate if:** Import fails, profile cannot be assigned, or PowerShell command errors. Provide serial number and Intune Device ID to escalation owner.

---

**R2 — Device shows OOBE error, ESP failure, or `0x80180014` recurs after Phase G**

**Trigger:** User reports an error screen during setup, ESP shows a failure message, the setup loops back to the sign-in screen, or error code `0x80180014` appears again.

1. **Tell the user: stop, do not click anything, do not restart.** Leave the screen exactly as it is.

2. If a command prompt is reachable (press `Shift + F10` at the OOBE screen, or sign in with a local admin account if available), run:
```powershell
dsregcmd /status | findstr /i "AzureAdJoined MDMUrl MDMEnrollmentState"
```
Copy the output to your notepad (right-click window title > **Edit** > **Select All** > `Ctrl + C`).

3. **Check Intune for a new device record:**
**Portal:** `https://intune.microsoft.com`
**Path:** Left nav > **Devices** > **All devices** > search device name
Note: how many rows, enrolment state of each, and timestamp.

```powershell
Connect-MgGraph -Scopes "DeviceManagementManagedDevices.Read.All"
Get-MgDeviceManagementManagedDevice -Filter "deviceName eq 'DESKTOP-FB099'" |
  Select-Object DeviceName, Id, EnrolledDateTime, ManagementState | Format-Table
```

4. **Check Entra for a device object:**
**Portal:** `https://entra.microsoft.com`
**Path:** Left nav > **Identity** > **Devices** > **All devices** > search device name
Note: registration state and registered date.

```powershell
Connect-MgGraph -Scopes "Directory.Read.All"
Get-MgDevice -Filter "displayName eq 'DESKTOP-FB099'" |
  Select-Object DisplayName, DeviceId, RegisteredDateTime, ApproximateLastSignInDateTime | Format-Table
```

5. **Raise an escalation immediately.** Include:
   - Device name and serial number
   - Intune Device ID (from Phase A notes)
   - Output of `dsregcmd /status` from step 2
   - Intune device record state from step 3
   - Entra device object state from step 4

6. **Do not reset, wipe, or rejoin the device** without explicit authorisation from the escalation owner.

---

**R3 — Wrong Entra device object deleted in Phase C**

**Trigger:** After deletion in Phase C, you compare the Azure AD Device ID of the deleted object against your Phase A notes and the IDs do not match.

1. **Disconnect the affected device from the network immediately** — disable Wi-Fi (click the network icon in the system tray > toggle Wi-Fi off) or unplug the ethernet cable. Do this before any other step.

2. Note the Azure AD Device ID of the incorrectly deleted object from your Phase A notepad.

3. **Check for recovery window:**
**Portal:** `https://entra.microsoft.com`
**Path:** Left nav > **Identity** > **Devices** > **Deleted devices**

```powershell
Connect-MgGraph -Scopes "Directory.ReadWrite.All"
# List recently deleted devices — recovery window is typically 30 days
Get-MgDirectoryDeletedItemAsDevice | Where-Object { $_.DisplayName -eq "DESKTOP-FB099" } |
  Select-Object DisplayName, DeviceId, DeletedDateTime | Format-Table
```
> Do not attempt to restore the object yourself — show the output to the escalation owner and let them decide.

4. **Raise an escalation immediately** with: Azure AD Device ID of the deleted object, device name, and exact time of deletion.

5. **Do not reconnect the device to the network** until the escalation owner confirms the identity state is safe.

---

**R4 — Device unstable after artefact removal in Phase F**

**Trigger:** After removing scheduled tasks, registry branches, or certificates in Steps F3–F5, the device freezes, shows new error screens, fails to respond, or new unexpected events appear in the event log.

1. **Stop all further artefact removal immediately.** Close Registry Editor, Task Scheduler, and Certificate Manager without saving any further changes.

2. Run the following in the elevated PowerShell prompt and copy all output to your notepad:
```powershell
dsregcmd /status
Get-WinEvent -LogName "Microsoft-Windows-DeviceManagement-Enterprise-Diagnostics-Provider/Admin" -MaxEvents 30 |
  Select-Object TimeCreated, Id, Message | Format-List
```

3. Write down the exact list of artefacts you removed (GUID values, full registry key paths, certificate thumbprints and subjects).

4. **Do not reboot the device.** Leave it powered on in its current state — a reboot with a partially cleaned artefact set may worsen the state.

5. **Raise an escalation immediately** with:
   - Device name and serial number
   - `dsregcmd /status` output from step 2
   - Event log output from step 2
   - Complete list of removed artefacts from step 3

**Quick check to assess blast radius before escalating:**
```powershell
# Confirm which enrolment subkeys remain after partial cleanup
Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Enrollments" |
  Select-Object Name, LastWriteTime | Format-Table

# Confirm which MDM certificates remain
Get-ChildItem Cert:\LocalMachine\My |
  Where-Object { $_.Subject -like "*MDM*" -or $_.Issuer -like "*Intune*" } |
  Select-Object Thumbprint, Subject, Issuer | Format-Table
```
> Include this output in the escalation.

---

## 8. Preventive Action

Controls are ordered by point in the deployment lifecycle: pre-deployment → in-flight → post-deployment → knowledge. Do not remove any control — they are cumulative layers.

---

**Preventive 1 — Mandatory pre-Autopilot readiness gate (service desk process)**

| Attribute | Detail |
|---|---|
| **Owner** | Service desk lead |
| **Timing** | Before deployment — ticket must not move to "Ready for user" without all three checks passing |
| **Mode** | Manual (automation path noted below) |

Add the following three checkboxes to the Autopilot deployment request ticket template in the ITSM tool. The ticket workflow must block transition to "Ready for user" status if any box is unchecked.

- [ ] `https://intune.microsoft.com` > **Devices** > **All devices** — searched by serial number. **Pass:** zero rows returned, or stale record already retired and deleted. **Fail:** a managed device record with an old enrolment date exists — retire and delete before continuing.
- [ ] `https://entra.microsoft.com` > **Identity** > **Devices** > **All devices** — searched by device name. **Pass:** zero or one object with a current registration date. **Fail:** a stale object with a legacy registered date exists — delete before continuing.
- [ ] `https://intune.microsoft.com` > **Devices** > **Windows** > **Windows enrollment** > **Devices** — searched by serial number. **Pass:** row present with `FinBridge-Autopilot-Standard` in Profile column. **Fail:** row missing or profile blank — resolve before continuing.

**Pass criteria:** All three boxes checked by an engineer before ticket progresses.
**Fail action:** Ticket remains in "Pending MDM conflict check" status; engineer resolves the specific failed check and re-ticks.
**Automation approach:** A Logic App or Power Automate flow triggered on ticket creation could run the three Graph queries automatically and pre-populate pass/fail status on the ticket. [REQUIRES: ITSM Graph integration / Logic App]

---

**Preventive 2 — Periodic bulk report of legacy-enrolled devices**

| Attribute | Detail |
|---|---|
| **Owner** | Endpoint operations engineer |
| **Timing** | Before deployment — monthly sweep, and mandatory before any bulk Autopilot re-deployment batch |
| **Mode** | Manual (automation path noted below) |

Run the following PowerShell command monthly to identify devices with legacy manual enrolment markers that are also registered in Autopilot — these are the devices at risk of causing `0x80180014` on next deployment:

```powershell
Connect-MgGraph -Scopes "DeviceManagementManagedDevices.Read.All","DeviceManagementServiceConfig.Read.All"

# Get all manually-enrolled devices with last check-in older than 90 days
$cutoff = (Get-Date).AddDays(-90)
$legacyDevices = Get-MgDeviceManagementManagedDevice |
  Where-Object { $_.EnrollmentType -eq "userEnrollment" -and $_.LastSyncDateTime -lt $cutoff } |
  Select-Object DeviceName, SerialNumber, Id, EnrolledDateTime, LastSyncDateTime

# Cross-reference against Autopilot device list
$autopilotDevices = Get-MgDeviceManagementWindowsAutopilotDeviceIdentity |
  Select-Object SerialNumber

$conflicts = $legacyDevices | Where-Object { $_.SerialNumber -in $autopilotDevices.SerialNumber }
$conflicts | Export-Csv -Path "C:\Reports\AutopilotConflictRisk_$(Get-Date -Format yyyyMMdd).csv" -NoTypeInformation
$conflicts | Format-Table DeviceName, SerialNumber, EnrolledDateTime, LastSyncDateTime
```

**Pass criteria:** CSV output is empty — zero devices with legacy enrolment markers appear in the Autopilot list.
**Fail criteria:** One or more rows returned — each device in the output must be retired and deleted from Intune (and its Entra object removed) before it is assigned to a new user.
**Fail action:** Endpoint operations engineer raises a bulk remediation task, completes retire/delete for all flagged devices, and reruns the report to confirm zero results before the batch proceeds.
**Automation approach:** Schedule as a monthly Azure Automation runbook that exports the CSV to a SharePoint folder and emails the endpoint operations team if row count > 0. [REQUIRES: Azure Automation account with Managed Identity and Intune Graph permissions]

---

**Preventive 3 — In-flight enrolment conflict alert**

| Attribute | Detail |
|---|---|
| **Owner** | DWP engineer (on-call) |
| **Timing** | During deployment — alert fires within 15 minutes of a `0x80180014` failure event |
| **Mode** | Automated [REQUIRES: Microsoft Endpoint Analytics or Azure Monitor / Log Analytics workspace connected to Intune] |

Configure a custom alert rule that fires whenever Autopilot enrolment fails with `0x80180014` so conflicts are caught at failure time rather than when the user raises a ticket.

**Alert rule definition (Azure Monitor / Log Analytics — if Intune diagnostic logs are exported to a workspace):**
```kusto
// KQL query for alert rule — run on a 15-minute schedule
IntuneDeviceComplianceOrg
| where TimeGenerated > ago(15m)
| where ErrorCode == "0x80180014"
| project TimeGenerated, DeviceName, UserPrincipalName, EnrollmentType, ErrorCode
```

**If using Microsoft Endpoint Analytics:**
- Navigate to `https://intune.microsoft.com` > **Reports** > **Endpoint analytics** > create a custom report filtered on enrolment failures with error code `0x80180014`.

**Pass criteria:** Zero alerts in the deployment window.
**Fail criteria (alert threshold):** ≥ 1 device returns `0x80180014` within the deployment window — alert fires to the on-call DWP engineer.
**Fail action:** On-call engineer checks Intune > **Devices** > **All devices** for a duplicate stale record on the flagged device and initiates this runbook within 30 minutes of the alert.

---

**Preventive 4 — Pre-deployment smoke test gate**

| Attribute | Detail |
|---|---|
| **Owner** | Release engineer |
| **Timing** | Before deployment — completed on one pilot device before the batch is released |
| **Mode** | Manual |

Before releasing any batch Autopilot deployment, run a single pilot device through the full Autopilot OOBE on a test user account. This validates that the Autopilot profile, ESP configuration, and MDM user scope are all functional before the batch fires.

**Pass criteria:** Pilot device completes OOBE and ESP with both Device setup and Account setup showing green ticks. `Get-MgDeviceManagementManagedDevice` returns `ManagementState = managed` and `ComplianceState` is not `unknown` for the pilot device.
**Fail criteria:** Pilot device fails OOBE with any error code, or ESP stalls beyond 30 minutes.
**Fail action:** Release engineer halts the batch, raises an incident, and does not proceed until the pilot device completes successfully. The batch deployment date is rescheduled via the change manager.

---

**Preventive 5 — Post-deployment validation before closing the change**

| Attribute | Detail |
|---|---|
| **Owner** | DWP engineer |
| **Timing** | After deployment — run within 2 hours of the last device completing OOBE |
| **Mode** | Manual (PowerShell command provided) |

After the deployment batch completes, run the following to confirm all devices are in a healthy enrolled state before the change record is closed:

```powershell
Connect-MgGraph -Scopes "DeviceManagementManagedDevices.Read.All"

# Adjust the filter to match today's deployment batch by enrolment date
$today = (Get-Date).Date
Get-MgDeviceManagementManagedDevice |
  Where-Object { $_.EnrolledDateTime -ge $today } |
  Select-Object DeviceName, SerialNumber, ManagementState, ComplianceState, EnrolledDateTime |
  Format-Table
```

**Pass criteria:** All devices in the batch show `ManagementState = managed`. Zero devices show `ManagementState = retirePending` or `unhealthy`. Zero devices have an enrolment error visible in their Intune Overview blade.
**Fail criteria:** Any device shows `ManagementState ≠ managed`, or any device has a duplicate stale record (two rows returned for the same device name).
**Fail action:** DWP engineer initiates this runbook for each failing device before the change record is closed. Change manager does not mark the change as successful until the post-deployment validation passes.

---

**Preventive 6 — Rollback trigger threshold**

| Attribute | Detail |
|---|---|
| **Owner** | Release engineer / change manager |
| **Timing** | During deployment — monitored throughout the deployment window |
| **Mode** | Manual trigger based on observable threshold |

Define a concrete rollback trigger so the team does not have to make a judgement call under pressure during a failing batch deployment.

**Rollback trigger (manual):** If **≥ 20%** of devices in the deployment batch fail Autopilot OOBE with any error code within the deployment window, the release engineer must halt remaining deployments and escalate to the change manager for a rollback decision.
**Observable signal:** `Get-MgDeviceManagementManagedDevice` filtered to today's enrolments — count rows where `ManagementState ≠ managed`, divide by total batch size. If ≥ 20%, trigger rollback.
**Rollback action:** Suspend the deployment batch in the ITSM tool. Do not wipe or reset any additional devices. Raise a P1 and engage the endpoint operations team to investigate the root cause before resuming.
**Automation approach:** A Logic App monitoring the Graph `managedDevices` endpoint could calculate the failure rate on a 15-minute cycle and post an alert to the team channel if the threshold is crossed. [REQUIRES: Logic App with Graph polling and Teams webhook]

---

**Preventive 7 — Knowledge update from this incident**

| Attribute | Detail |
|---|---|
| **Owner** | DWP engineer who resolved the incident |
| **Timing** | After deployment — must be completed within 5 business days of incident closure |
| **Mode** | Manual |

After each occurrence of this failure pattern, the resolving engineer must complete the following:

**Pass criteria:** All four items completed and verified by the service desk lead within 5 business days.
**Fail criteria:** Any item incomplete after 5 business days — service desk lead escalates to the endpoint operations team lead.

- [ ] This KB article reviewed and updated if any step in the Resolution or Detection sections behaved differently from what is documented. Version number incremented and change log updated.
- [ ] The ITSM ticket template (Preventive 1) reviewed to confirm the three checklist items still reflect the correct portal paths — Intune and Entra portal navigation paths change periodically.
- [ ] The bulk conflict report script (Preventive 2) re-run to confirm the resolved device no longer appears in the output.
- [ ] If this is the **second or more** occurrence in 30 days: escalate to the endpoint operations team lead to investigate whether the Autopilot deployment process has a systemic gap, and raise a formal process change request.

---

## 9. Related Incidents and Articles

| Reference | Type | Detail |
|---|---|---|
| DESKTOP-FB099 / FINBRIDGE\rthomas — 2026-08-11 | Reference incident | Original incident this article was derived from |
| RCA: `rca_autopilot_enrolment_failed_existing_legacy_mdm_20260811.md` | RCA document | Full root cause analysis and remediation runbook |
| Runbook: `runbook_autopilot_enrolment_failed_existing_legacy_mdm_20260811.md` | Runbook | Step-by-step engineer runbook with rollback |
| Known error: `known_error_autopilot_enrolment_failed_existing_legacy_mdm_20260811.md` | Known error record | DWP knowledge base known error entry |
| Error `0x80180026` | Related error code | Device not in allowed Azure AD group for Autopilot — different cause, similar symptom |
| Error `0x80070774` | Related error code | Autopilot profile not found — caused by missing hardware hash, not stale MDM record |

---

*End of article. Raise a PR or change request to update this article if a new variant of this failure is encountered.*
