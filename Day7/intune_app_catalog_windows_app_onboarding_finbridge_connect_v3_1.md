# Intune App Catalog Onboarding Guide: FinBridge Connect v3.1 (Windows .intunewin)

Purpose: Provide a step-by-step process a DWP engineer can execute to add a Windows app to the Intune app catalog before any phased rollout starts.

Worked example used throughout:
- Application name: FinBridge Connect v3.1
- Package type: Windows .intunewin
- Install command: FinBridgeConnect_Setup.exe /silent
- Uninstall command: FinBridgeConnect_Setup.exe /uninstall /silent
- Detection method: Registry key
- Detection value: HKLM\SOFTWARE\FinBridge\Connect\Version = 3.1

Important version note:
- Intune UI labels and menu placement can differ by tenant version, service update, and portal experience.
- In every step below where a label is shown, verify the live label in your own tenant before proceeding.

## 1. Add the app in Intune (navigation + app type selection)

1. Sign in to Microsoft Intune admin center.
   - Typical path: https://intune.microsoft.com

2. Navigate to Apps > All apps > Add.
   - UI label check: In some tenants this may appear as Apps > Windows > Add, or include a separate Create flow.
   - Verify the live labels in your tenant and proceed with the equivalent Add app action.

3. On Select app type, choose the app type based on source:
   - Platform: Windows
   - For FinBridge Connect v3.1 (.intunewin): choose Windows app (Win32).
   - For Microsoft Store-delivered apps: choose Microsoft Store app (new).
   - For a web link shortcut: choose Web link.
   - UI label check: Some tenants still show older naming or additional app-type variants. Confirm the option that maps to Win32 .intunewin for this scenario.

4. Review common Windows app type options that may appear in the App type list.
   - Windows app (Win32): for .intunewin packaged apps (use this for FinBridge Connect v3.1).
   - Microsoft Store app (new): for apps sourced directly from Microsoft Store integration.
   - Microsoft 365 Apps for Windows 10 and later: for Office app suite deployment.
   - Web link: for publishing a URL shortcut in Company Portal.
   - Built-in app: for selected first-party app scenarios provided by Intune.
   - UI label check: Your tenant may show fewer/more options, renamed options, or options in a different order. Always verify live in your own tenant and choose the option that matches the source package type.

5. Select and upload the .intunewin package for FinBridge Connect v3.1.
   - On the Add App page, select Select app package file.
   - In the App package file pane, use Select a file and browse to the FinBridge Connect v3.1 .intunewin package.
   - After the package is selected, review the metadata Intune reads from the file before continuing:
     - Name
     - Platform
     - Size
     - MAM Enabled
   - Confirm the displayed package details match the file you intended to upload.
   - Select OK to attach the package and continue to the next wizard section.
   - UI label check: Browse/select controls may be named differently (for example, Select app package file).

## 2. Complete required fields for the Windows .intunewin app

6. Fill in App information.
   - Name: FinBridge Connect v3.1
   - Description: FinBridge secure connectivity client for enterprise access.
   - Publisher: FinBridge
   - App version: 3.1
   - Information URL: Add vendor product/support page URL (for example, https://finbridge.example.com/connect).
   - Privacy URL: Add vendor privacy statement URL (for example, https://finbridge.example.com/privacy).
   - Developer: FinBridge
   - Owner: DWP Endpoint Engineering (or your owning support team).
   - Notes: Add operational notes such as package source, silent switches, and change ticket ID.
   - Required vs optional guidance: Name is required; URL/Developer/Owner/Notes fields are often optional but strongly recommended for supportability.
   - Recommendation: Add a clear, supportable description for service desk visibility.
   - UI label check: Section may be named App information, Properties, or Basic information.

7. Configure Program settings.
   - Install command: FinBridgeConnect_Setup.exe /silent
   - Uninstall command: FinBridgeConnect_Setup.exe /uninstall /silent
   - Allow available uninstall: Yes (recommended so pilot users/support can remove the app from Company Portal when assignment type is Available).
   - Install behavior: System
   - Device restart behavior: App install may force a device restart (or set according to vendor guidance and your change window policy).
   - Why System context here: device-wide install, consistent behavior for all users, and fewer permission-related failures.
   - UI label check: Install behavior may appear as Install context (System/User), and Device restart behavior wording can differ by tenant UI version.

8. Set Requirements.
   - Check operating system architecture: No.
   - Architecture setting meaning in this worked example: Allow this app to be installed on all systems.
   - When to choose Yes instead: Use Yes only when the package is limited to a specific architecture such as 64-bit.
   - Minimum operating system: Windows 11 22H2.
   - Disk space required (MB): Leave blank unless the vendor provides a tested minimum disk requirement.
   - Physical memory required (MB): Leave blank unless the vendor provides a tested minimum RAM requirement.
   - Minimum number of logical processors required: Leave blank unless the vendor documents a processor-count dependency.
   - Minimum CPU speed required (MHz): Leave blank unless the vendor documents a CPU speed dependency.
   - Configure additional requirement rules: None specified for this worked example.
   - Recommendation: Keep requirements strict enough to prevent deployment to unsupported devices, but avoid adding hardware minimums unless they are validated by vendor guidance or packaging test results.
   - UI label check: This section may be split across tabs or grouped with eligibility filters.

9. Add Detection rules (required so Intune can confirm installation).
   - Rules format: Manually configure detection rules
   - Rule type: Registry
   - Key path: HKEY_LOCAL_MACHINE\SOFTWARE\FinBridge\Connect
   - Value name: Version
   - Detection method: String comparison equals
   - Operator: Equals
   - Expected value: 3.1
   - Associated with a 32-bit app on 64-bit clients: No (set Yes only if the app is 32-bit and writes to 32-bit registry/file locations).
   - Result meaning: App is considered installed only when Version exactly matches 3.1.
   - UI label check: Registry rule fields may be shown with abbreviated labels (for example, Key path, Value, Data), and the 32-bit association toggle wording can vary between tenant versions.

10. Understand alternative detection rule options (for future apps).
   - Registry key/value: good for apps that stamp version to registry.
   - MSI product code: good for MSI installers with stable product codes.
   - File or folder path: good for portable or custom installers.
   - Choose the most reliable artifact that always exists only when install succeeded.

11. Configure Dependencies (wizard step after Detection rules).
   - Add dependency apps only when this app requires another app to be installed first.
   - Example use case: VC++ runtime, .NET Desktop Runtime, or a required VPN component.
   - For FinBridge Connect v3.1 in this worked example: leave Dependencies empty unless a prerequisite is mandatory.
   - UI label check: The page may show Automatically install options for each dependency and may include tenant-specific wording.

12. Configure Supersedence (wizard step after Dependencies).
   - Use Supersedence when FinBridge Connect v3.1 should replace or upgrade an older app package.
   - Choose whether the previous version should be upgraded in place or uninstalled and replaced.
   - For first-time onboarding with no prior managed version: leave Supersedence empty.
   - UI label check: Supersedence terms and action labels can vary by tenant version.

13. Configure Return codes.
   - Confirm which exit codes Intune should treat as Success, Soft reboot, Hard reboot, Retry, or Failed.
   - Common mapping used by many teams:
     - 0 = Success
     - 3010 = Soft reboot
     - 1641 = Hard reboot
     - 1618 = Retry (another install in progress)
   - Any unclassified critical code should remain Failed.
   - UI label check: Some tenants pre-populate defaults; validate and adjust only if your packaging standard requires it.

14. Review and create the app.
   - Confirm metadata, commands, requirements, detection, and return codes.
   - Confirm Dependencies and Supersedence are intentionally configured (or intentionally empty).
   - Select Create.
   - Wait for package processing to complete.

## 3. Assignment basics (pilot first)

15. Open the new app and go to Assignments.
   - UI label check: Assignment controls may appear under Properties > Assignments in some tenant layouts.

16. Understand assignment types.
   - Required: Installs automatically on targeted devices/users.
   - Available for enrolled devices: Publishes to Company Portal so users can install on demand.
   - Uninstall: Removes the app from targeted devices/users.

17. Assign FinBridge Connect v3.1 to a small pilot group first.
   - Recommended first target: controlled IT pilot group (for example, 20 to 100 devices/users).
   - Do not assign directly to the full 10,000-device fleet.
   - Why pilot first:
     - Detect packaging or detection-rule defects early.
     - Validate install time and reboot/user impact.
     - Reduce organization-wide risk and rollback scope.

18. Save assignments and allow policy sync time.
   - UI label check: Save/Review + save wording can vary by experience.

## 4. Verification steps

19. Confirm the app appears correctly in the catalog.
   - Go to Apps > All apps.
   - Search for FinBridge Connect v3.1.
   - Open it and confirm:
     - Publisher and version are correct.
     - Program commands are present.
     - Detection rule matches HKLM\SOFTWARE\FinBridge\Connect\Version = 3.1.

20. Check install status from Intune admin center.
   - Open app > Monitor.
   - Review Device install status and User install status for pilot targets.
   - Filter to pilot group members when possible.
   - UI label check: Monitor views and status blade names vary by tenant version.

21. Validate on at least one assigned test device.
   - On the test Windows 11 device, trigger a sync (Settings > Accounts > Access work or school > connected account > Info > Sync, or via Company Portal sync).
   - Confirm FinBridge Connect installs silently.
   - Confirm registry value exists:
     - Path: HKLM\SOFTWARE\FinBridge\Connect
     - Value: Version
     - Data: 3.1

22. Interpret status values correctly.
   - Installed: Intune detected the app as successfully installed (detection rule met).
   - Failed: Install attempt did not complete successfully, or app installed but detection rule failed.
   - Not applicable: Device/user does not meet requirements or assignment scope (for example, wrong OS/architecture, excluded, or non-targeted context).

23. Gate for rollout readiness.
   - Proceed to phased rollout only after pilot results are stable (high install success, low failure rate, and validated user impact).
   - If failures appear, fix packaging, commands, requirements, detection, or return code mapping before expanding assignments.

## Quick engineer checklist

24. Before declaring catalog onboarding complete, confirm all items below:
   - Correct app type selected for .intunewin (Windows app (Win32)).
   - App information fields are complete and accurate.
   - Install/uninstall commands tested and correctly entered.
   - Install context chosen appropriately (System for this example).
   - Requirements match supported OS and architecture.
   - Detection rule correctly validates Version = 3.1 at HKLM\SOFTWARE\FinBridge\Connect.
   - Dependencies and Supersedence reviewed and intentionally configured (or intentionally left blank).
   - Return code mapping reviewed against packaging standard.
   - Assignment set to pilot group first, not enterprise-wide.
   - Monitor status reviewed and at least one test device validated end-to-end.
