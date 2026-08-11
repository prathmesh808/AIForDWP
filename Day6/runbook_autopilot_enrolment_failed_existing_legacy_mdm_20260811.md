# Runbook: Autopilot Enrolment Failure — Existing Legacy MDM Enrolment (0x80180014)

| Field | Detail |
|---|---|
| **Title** | Autopilot Enrolment Failure — Existing Legacy MDM Enrolment (0x80180014) |
| **Version** | 1.0 |
| **Date** | 11/08/2026 |
| **Author** | prathameshgavade |
| **Reviewed by** | self |
| **Status** | Draft |
| **Change** | Initial version from RCA |

---

**Applies to:** Windows devices failing Autopilot enrolment with error 0x80180014
**Reference incident:** DESKTOP-FB099 / FINBRIDGE\rthomas

---

## 1. Prerequisites

Tick every box before starting. Do not proceed if any item is unchecked — resolve the gap first.

### Access rights
- [ ] You can sign in to the **Intune admin center** at `https://intune.microsoft.com` and reach **Devices > All devices** without an access-denied error.
- [ ] You can issue **Retire** and **Delete** actions on device objects in Intune (confirm by opening any device record and checking those buttons are not greyed out).
- [ ] You can sign in to the **Microsoft Entra admin center** at `https://entra.microsoft.com` and reach **Identity > Devices > All devices**.
- [ ] You can **delete** device objects in Entra (confirm by opening any device record — a Delete option must be present in the toolbar).
- [ ] You can reach **Devices > Windows > Windows enrollment > Devices** in the Intune admin center (Autopilot devices list).
- [ ] You hold **local administrator rights** on the affected endpoint (required for Steps 18–18a). If not, contact your team lead before proceeding.

### Tools and documents
- [ ] You have a remote interactive session tool available (e.g. Quick Assist, RDP) or physical access to the device for Steps 16–19.
- [ ] You have the **approved internal MDM artefact cleanup runbook** open and ready before starting Step 18a. Do not begin artefact removal without it.
- [ ] You have a text editor open to record identifiers collected in Phase A.

### Mandatory information from the end user / ticket
Collect all of the following from the ticket or by asking the end user **before** opening any admin center. Do not guess or assume.

- [ ] **Device name** (e.g. `DESKTOP-FB099`) — confirm exact name, not a nickname
- [ ] **Serial number** — ask user to read from device underside, BIOS, or check asset register
- [ ] **User UPN** (full sign-in address, e.g. `rthomas@finbridge.com`) — not just display name
- [ ] **Intended Autopilot profile name** — confirm with team lead if unknown (this runbook uses `FinBridge-Autopilot-Standard`)
- [ ] **Intended security baseline name** — confirm with team lead if unknown (this runbook uses `FinBridge-Win11-Security-Baseline`)
- [ ] **User is available at the device** during Phase F (Autopilot OOBE sign-in) — agree a time before starting
- [ ] **Error code confirmed as `0x80180014`** — if a different error code is shown on the device, stop and verify this runbook applies before continuing

---

## 2. Procedure

> **Notation:** Steps marked **[ELEVATED]** require admin center write permissions or local admin rights on the device.

---

### Phase A — Capture identifiers (admin center, no changes yet)

**Step 1.** Open a browser and go to `https://intune.microsoft.com`. Sign in with your admin account.
> Expected result: The Microsoft Intune admin center home page loads. If you receive an access-denied error, stop — your account lacks the required role (see Prerequisites).

**Step 2.** In the left-hand navigation pane, click **Devices**. In the sub-menu that appears, click **All devices**.
> Expected result: The All devices list loads showing enrolled devices.

**Step 3.** In the **Search by name** box at the top of the device list, type the device name (e.g. `DESKTOP-FB099`) and press Enter.
> Expected result: One or more device records matching the name appear.

**Step 4.** Click the device name to open its record. On the **Overview** blade, paste or type the following into your notepad — you will need every value later:
- Device name
- Serial number
- Intune Device ID (labelled "Device ID" on the Overview blade)
- Azure AD Device ID
- Primary user
- Enrolment date

> Expected result: All six values are recorded. The enrolment date should be a legacy date (e.g. 2023-11-04) that predates the current deployment — this confirms a stale record. If the date is today or recent, re-confirm with the ticket that this is the correct stale object before continuing.

**Step 5.** In the left-hand navigation, click **Devices**, then **Windows**, then **Windows enrollment**, then **Devices** (listed under the Windows Autopilot heading).
> Expected result: The Windows Autopilot devices list opens showing hardware hash records.

**Step 6.** In the search box, type the serial number recorded in Step 4 and press Enter.
> Expected result: The Autopilot hardware hash record appears and the **Profile** column shows **FinBridge-Autopilot-Standard**. Note this in your notepad. If the profile column is blank or shows a different value, stop and confirm the correct profile with your team lead before continuing.

---

### Phase B — Remove stale records from Intune [ELEVATED]

**Step 7.** In the left-hand navigation, click **Devices**, then **All devices**. Search for the device name as in Step 3. Click the device name to reopen the stale device record.
> Expected result: The Overview blade of the stale managed device object opens.

**Step 8 [ELEVATED].** In the top toolbar of the device record, click **Retire**. A confirmation dialog appears — click **Yes**.
> Expected result: A notification banner confirms the Retire action was issued. Under **Device actions status** on the Overview blade, the action will show as **Pending** then **Completed** (allow up to 5 minutes if the device is online). If the device is offline the status stays **Pending** — this is acceptable; note it in your ticket and proceed.

**Step 9 [ELEVATED].** In the top toolbar of the same device record, click **Delete**. Confirm the deletion when prompted.
> Expected result: You are returned to the All devices list. Search for the device name again — the stale object must no longer appear. If it still shows after a page refresh, wait 2 minutes and search again.

---

### Phase C — Remove stale Entra device object [ELEVATED]

**Step 10.** Open a new browser tab and go to `https://entra.microsoft.com`. Sign in with your admin account.
> Expected result: The Microsoft Entra admin center home page loads.

**Step 11.** In the left-hand navigation, click **Identity**, then **Devices**, then **All devices**.
> Expected result: The Entra All devices list opens.

**Step 12.** In the search box, type the device name (e.g. `DESKTOP-FB099`) and press Enter. If no result appears by name, clear the box, switch the search filter to **Device ID**, paste the Azure AD Device ID recorded in Step 4, and press Enter.
> Expected result: The stale Entra device object appears in the results.

**Step 13 [ELEVATED].** Click the **checkbox** to the left of the stale device object to select it. Click **Delete** in the toolbar above the list. Confirm when prompted.
> Expected result: The object is removed from the list.
> **Critical warning:** Do **not** open the Intune Autopilot devices list and delete the hardware hash record. That record must remain — only the Entra device object is removed here.

---

### Phase D — Confirm Autopilot identity is still intact

**Step 14.** Switch back to the Intune admin center browser tab. In the left-hand navigation, click **Devices**, then **Windows**, then **Windows enrollment**, then **Devices** (Autopilot devices).
> Expected result: The Autopilot devices list opens.

**Step 15.** Type the serial number recorded in Step 4 in the search box and press Enter.
> Expected result: The hardware hash record is still present and the **Profile** column still shows **FinBridge-Autopilot-Standard**. If the record or profile assignment is missing, **stop immediately — do not touch the device**. Escalate to your team lead with your notepad records.

---

### Phase E — Clean legacy enrolment artefacts on the device

**Step 16.** Connect to the device via your remote session tool (e.g. RDP to the device hostname or IP, or Quick Assist) or sit at the device directly.
> Expected result: You have an interactive desktop session on the device.

**Step 17.** Click the **Start** button (Windows logo, bottom-left). Click the **Settings** gear icon. In Settings, click **Accounts** in the left-hand menu, then click **Access work or school**.
> Expected result: The Access work or school page opens showing any connected accounts.

**Step 18.** Click on the legacy organisational account or MDM connection entry (shown with a briefcase icon, typically referencing the old domain or MDM authority). Click **Disconnect**, then click **Yes** on the confirmation prompt. Repeat for any additional legacy entries.
> Expected result: No legacy MDM or work account entries remain in the Access work or school list. If no entries were present, continue to Step 19.

**Step 19 [ELEVATED].** Right-click the **Start** button and click **Terminal (Admin)**. If Terminal (Admin) is not available, right-click Start and click **Command Prompt (Admin)** or **Windows PowerShell (Admin)**. In the elevated prompt, type the following and press Enter:
```
dsregcmd /status
```
Scroll through the output and find the **`Device State`** section. Record the values of these three fields in your notepad:
- `EnterpriseJoined`
- `MDMUrl`
- `MDMEnrollmentState`

> Expected result:
> - `EnterpriseJoined : YES` (Azure AD joined is correct for this device)
> - `MDMUrl` is blank or not present — if it still shows a legacy MDM URL, proceed to Step 19a
> - `MDMEnrollmentState` shows `0` or is absent — if it shows a non-zero value, proceed to Step 19a
>
> If all three fields show a clean state, skip Step 19a and go to Step 20.

**Step 19a [ELEVATED].** Open the **approved internal MDM artefact cleanup runbook** and follow it to remove stale artefacts in this order:

1. **Scheduled tasks** — Press `Win + R`, type `taskschd.msc`, press Enter. In Task Scheduler, expand `Task Scheduler Library > Microsoft > Windows > EnterpriseMgmt`. Delete any task folder whose name is a GUID matching the old enrolment ID (visible in the `MDMUrl` path or in the registry in the next step). Do not delete folders with a GUID matching any current enrolment.

2. **Registry enrolment branch** — Press `Win + R`, type `regedit.exe`, press Enter. Navigate to:
 `HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Enrollments`
 Each subkey here is a GUID representing an enrolment. Right-click the subkey whose GUID matches the old enrolment and click **Delete**. Do not delete any subkey associated with a new or current enrolment.

3. **MDM certificate** — Press `Win + R`, type `certlm.msc`, press Enter. In the left-hand tree, expand **Personal**, then click **Certificates**. Locate and delete any certificate issued by the old MDM authority that references the stale enrolment GUID. Do not delete Intune or current-enrolment certificates.

> After each removal, run `dsregcmd /status` again in the elevated prompt. Confirm `MDMUrl` is blank and `MDMEnrollmentState` is `0` before proceeding. If the stale state persists after all three removals, stop and escalate — do not reboot.

---

### Phase F — Reboot and relaunch Autopilot

**Step 20.** Confirm the end user is present at the device and ready to sign in. Then on the device click **Start > Power > Restart**.
> Expected result: The device shuts down and reboots. Your remote session will disconnect — this is expected.

**Step 21.** Ask the user to follow the on-screen OOBE flow:
1. Select their **region** and **keyboard layout** when prompted and click **Yes**.
2. At the **Sign in with Microsoft** screen, type the full UPN (e.g. `rthomas@finbridge.com`) and click **Next**, then enter their password.
3. Complete any **MFA prompt** that appears.
4. The **Enrolment Status Page (ESP)** appears with two progress sections: **Device setup** and **Account setup**. Instruct the user to wait and not click anything until both show a green tick.

> Expected result: Both ESP phases complete with green ticks and the user reaches the Windows desktop without any error. Error `0x80180014` must not appear. If the ESP stalls for more than 30 minutes with no visible progress, note which phase it is stuck on and escalate.

---

## 3. Verification

Complete all four checks in order before closing the ticket. Each check tells you exactly where to look and what a pass looks like.

---

**Check 1 — Confirm the device is enrolled in Intune (admin center)**

1. Open a browser and go to `https://intune.microsoft.com`. Sign in with your admin account.
2. In the left-hand navigation, click **Devices**, then click **All devices**.
3. In the **Search by name** box, type the device name (e.g. `DESKTOP-FB099`) and press Enter.
4. Click the device name to open the record.
5. On the **Overview** blade, read the following fields:
   - **Enrolled** date — must show today's date (2026-08-11), not the legacy date (2023-11-04).
   - **MDM** — must show **Microsoft Intune**.
   - **Compliance** — must show **Compliant** or **In grace period** (not "Not evaluated" after more than 15 minutes post-enrolment).

> **Pass:** All three fields match the expected values above.
> **Fail:** If Enrolled date is still legacy, or MDM is blank, or Compliance is stuck on "Not evaluated" after 15 minutes — do not close the ticket; escalate.

---

**Check 2 — Confirm Autopilot ESP completed on the device**

1. Ask the end user: "Did you reach the Windows desktop after the setup screens without any error messages?"
2. Ask: "Did you see any message containing the code `0x80180014` at any point during setup?"

> **Pass:** User confirms they reached the desktop and saw no error codes.
> **Fail:** User reports an error screen, an OOBE loop, or code `0x80180014` — go to Rollback section R2 immediately.

---

**Check 3 — Confirm policy baseline has applied (admin center)**

1. In the Intune admin center at `https://intune.microsoft.com`, ensure you still have the device record open from Check 1. If you closed it, repeat steps 1–4 from Check 1.
2. In the left-hand menu of the device blade, click **Device configuration**.
3. In the configuration profiles list, find the row for **FinBridge-Win11-Security-Baseline**.
4. Read the **State** column for that row.
5. Count the total profiles where **State = Succeeded** and note the number.

> **Pass:** FinBridge-Win11-Security-Baseline shows **Succeeded**. Profile count shows more than 0 profiles succeeded (was 0/4 before remediation).
> **Fail:** FinBridge-Win11-Security-Baseline shows **Error** or **Conflict**, or State shows `0x80070005` — do not close the ticket; escalate with a screenshot of this screen.

---

**Check 4 — Confirm no MDM errors in device event log (device — required before closing)**

1. On the device, press `Win + R` to open the Run dialog. Type `eventvwr.msc` and press Enter. Event Viewer opens.
2. In the left-hand tree, expand the following path by clicking each node in turn:
   `Applications and Services Logs` → `Microsoft` → `Windows` → `DeviceManagement-Enterprise-Diagnostics-Provider` → click **Admin**.
3. The centre pane shows MDM events. In the **Actions** pane on the right, click **Filter Current Log**.
4. In the **Event IDs** field, type `404` and click **OK**. (Event ID 404 = MDM policy application failure.)
5. Scan the filtered list for any event where the **Description** column contains `0x80070005`. Check the **Date and Time** column — only events timestamped **after** today's new enrolment time are relevant.

> **Pass:** No Event ID 404 entries with `0x80070005` appear after the new enrolment timestamp.
> **Fail:** One or more `0x80070005` events appear after enrolment — capture the event details (right-click the event > **Copy** > **Copy Details as Text**) and escalate with that text before closing.

**Optional — Generate full MDM diagnostic report**

Run this if Check 3 or Check 4 shows an anomaly and you need more detail for escalation:
1. On the device, press `Win + R`, type the following exactly, and press Enter:
   ```
   mdmdiagnosticstool.exe -out C:\Temp\MDMDiag
   ```
2. Open File Explorer, navigate to `C:\Temp\MDMDiag\`, and double-click **MDMDiagReport.html** to open it in a browser.
3. On the report page, use `Ctrl + F` to search for `FinBridge-Win11-Security-Baseline`.
4. Under the **Enrolled configuration sources and target resources** section, confirm the baseline row shows no error codes in the **Error** column.

> Attach `MDMDiagReport.html` to the ticket before escalating.

---

## 4. Rollback

> **How to use this section:** Identify which scenario matches your situation, go straight to that block, and execute the numbered steps in order. Each block is self-contained — you do not need to read other blocks. Target: all steps completable in under 3 minutes.

---

**R1 — Autopilot profile is missing or blank after Steps 8–15**
*Symptom: You completed the Intune/Entra cleanup and returned to `https://intune.microsoft.com` > Devices > Windows > Windows enrollment > Devices, searched by serial number, and either the device row is gone or the Profile column is blank.*

1. **Do not reboot the device and do not start OOBE.** Stay in the Intune admin center.
2. Go to `https://intune.microsoft.com`. In the left-hand navigation click **Devices**, then **Windows**, then **Windows enrollment**, then **Devices**.
3. Search the serial number in the search box. If the row is completely missing (hardware hash deleted), go to step 4. If the row exists but the Profile column is blank, go to step 5.
4. *(Hardware hash missing only)* Click **Import** in the top toolbar. Upload the hardware hash CSV for this device using the serial number from your notepad. Wait for the import to complete (the row will reappear in the list — refresh every 60 seconds).
5. Click the device row to open it. Click **Assign profile** in the toolbar (or click the **Profile** field). Select **FinBridge-Autopilot-Standard** from the dropdown and click **Save**.
6. Refresh the Autopilot devices list. Confirm the **Profile** column shows **FinBridge-Autopilot-Standard** before proceeding to OOBE.

> **Escalate if:** The import fails, or the profile cannot be assigned, or the profile column remains blank after saving. Provide the device serial number and Intune Device ID from your notepad.

---

**R2 — Device shows OOBE error screen or loops back to sign-in after Step 21**
*Symptom: The user reports an error during OOBE, the Enrolment Status Page shows a failure, or error `0x80180014` reappears.*

1. **Tell the user: do not click anything, do not restart.** Ask them to leave the screen as-is.
2. If the device can reach a local admin desktop (press `Shift + F10` at OOBE to open a command prompt, or sign in with a local admin account if available), run:
   ```
   dsregcmd /status
   ```
   Copy the full output to your notepad (right-click the window title > **Edit** > **Select All**, then `Ctrl + C`).
3. Go to `https://intune.microsoft.com`. Click **Devices** > **All devices**. Search for the device name. Note whether a new device object is present or absent, and what enrolment state it shows.
4. Go to `https://entra.microsoft.com`. Click **Identity** > **Devices** > **All devices**. Search for the device name. Note whether a device object exists and its registration state.
5. Raise an escalation immediately. Include: device name, serial number, Intune Device ID (from your notepad), `dsregcmd /status` output, and the Intune and Entra device states from steps 3–4.
6. **Do not reset, wipe, or rejoin the device** until the escalation owner has reviewed and authorised next steps.

---

**R3 — Wrong Entra device object was deleted (Step 13)**
*Symptom: You realise after deleting that the Azure AD Device ID of the deleted object does not match the value recorded in your notepad from Step 4.*

1. **Disconnect the affected device from the network immediately** (disable Wi-Fi or unplug the ethernet cable). This prevents the device from attempting authentication with an invalid identity.
2. Open your notepad. Write down the Azure AD Device ID of the incorrectly deleted object — you need this for the escalation.
3. Go to `https://entra.microsoft.com`. Click **Identity** > **Devices** > **Deleted devices** (if visible in the left-hand menu under Devices). Check if the deleted object appears here — some tenants retain a short recovery window. Do **not** attempt to restore it yourself.
4. Raise an escalation immediately. Include: the Azure AD Device ID of the incorrectly deleted object, the device name, and the time of deletion. The escalation owner will determine whether the object can be recovered or the device must be re-registered.
5. Do not reconnect the device to the network until the escalation owner confirms it is safe to do so.

---

**R4 — Device becomes unstable after artefact cleanup (Step 19a)**
*Symptom: After removing scheduled tasks, registry branches, or certificates in Step 19a, the device behaves unexpectedly (freezes, crashes, fails to respond, or shows new errors).*

1. **Stop all further artefact removal immediately.** Close Registry Editor, Task Scheduler, and Certificate Manager.
2. In the elevated command prompt still open on the device, run:
   ```
   dsregcmd /status
   ```
   Right-click the window title > **Edit** > **Select All**, then `Ctrl + C` to copy the full output. Paste it into your notepad.
3. In your notepad, write down the exact list of artefacts you removed (which GUIDs, which registry keys, which certificates — from memory or from the steps you completed in 19a).
4. **Do not reboot the device.** Leave it powered on in its current state.
5. Raise an escalation immediately. Include: device name, serial number, `dsregcmd /status` output, and the list of removed artefacts. The escalation owner needs this to assess recovery options before any reboot.

---

## 5. Notes

**Edge cases**

- **Multiple stale records:** A device may have more than one stale Intune managed device object if it was enrolled and wiped multiple times. Delete all stale records, but confirm each against the serial number before deleting. The hardware hash record in Autopilot must not be deleted.
- **Device offline during Retire (Step 5):** If the device is offline, the Retire command will queue. You can proceed to Step 6 and delete the object without waiting, but note in the ticket that Retire was not confirmed as delivered.
- **Azure AD joined state:** This device was Azure AD joined (confirmed in the RCA). If `dsregcmd /status` shows `AzureAdJoined: NO` after cleanup, the Entra object deletion in Step 8 may have also removed the join record. Escalate before proceeding to OOBE.
- **Licensing check:** If enrolment fails again after cleanup, re-confirm that both Intune P1 and Autopilot licences are assigned to the user in the Microsoft 365 admin center before re-attempting OOBE.

**Warnings**

- Do **not** delete the Windows Autopilot hardware hash record from Intune > Windows enrollment > Devices unless it is confirmed incorrect or corrupt. Deleting it removes the device from Autopilot and requires a full hardware hash re-import.
- Step 11a (artefact cleanup) must only be performed using the approved internal support runbook under change control. Ad-hoc registry edits outside that runbook are not permitted.
- Do not force-reset or wipe the device as a first response. A clean Autopilot re-enrolment following stale record removal is the correct path.

**Preventive action (for other devices)**

Before assigning or reusing any Windows device for Autopilot, complete the following gate check:
1. Search Intune > Devices > All devices for an existing managed device record matching the serial number.
2. Search Entra > Identity > Devices > All devices for a stale device object from a prior enrolment.
3. Retire and delete any stale records found before the Autopilot profile is assigned.

Add a mandatory service desk checklist step: **"Legacy MDM conflict check completed (Intune + Entra)"** — required before every Autopilot reset or redeployment.

Run a periodic report of devices with legacy manual enrolment markers and remediate in bulk ahead of reuse cycles.

**Related incidents**
- Reference incident: DESKTOP-FB099 / FINBRIDGE\rthomas — 2026-08-11
- Error code index: 0x80180014 (device already enrolled in MDM), 0x80070005 (Access denied on policy apply)
