# Immediate Fix and Floor 6 Message (Standalone Update)

Date: 2026-08-14
Scope: Login/performance disruption linked to Friday app deployment cohort on Floor 6.

## Most-Likely Cause (Reasoned)
Most likely cause is a Friday deployment ring and prerequisite sequencing issue interacting with sign-in policy/compliance checks.

Reasoning:
- The issue appears in the same floor cohort that received the Friday deployment.
- Monday morning onset matches first-business-day login pressure after rollout.
- Mixed symptoms (hard fail for some, heavy delay for others) fit policy/prerequisite drift across devices.

## Immediate Technical Action (Executable Command Set)
Use this command path to remove affected devices from the rollout ring, place them in rollback scope, and force policy sync.

```powershell
# Requires Microsoft Graph PowerShell SDK
# Required scopes:
# DeviceManagementManagedDevices.ReadWrite.All
# GroupMember.ReadWrite.All

Connect-MgGraph -Scopes "DeviceManagementManagedDevices.ReadWrite.All","GroupMember.ReadWrite.All"

# Fill with your tenant values
$rolloutRingGroupId  = "<entra-group-id-for-friday-app-ring>"
$rollbackGroupId     = "<entra-group-id-for-rollback-or-uninstall-scope>"
$affectedDeviceNames = @("L6-LAP-104","L6-LAP-118","L6-LAP-123")

# Resolve device objects by display name
$affectedDevices = foreach ($name in $affectedDeviceNames) {
    Get-MgDevice -Filter "displayName eq '$name'" -ConsistencyLevel eventual
}

# Step 1: Remove from rollout ring
foreach ($d in $affectedDevices) {
    Remove-MgGroupMemberByRef -GroupId $rolloutRingGroupId -DirectoryObjectId $d.Id
}

# Step 2: Add to rollback scope
foreach ($d in $affectedDevices) {
    New-MgGroupMemberByRef -GroupId $rollbackGroupId -BodyParameter @{ "@odata.id" = "https://graph.microsoft.com/v1.0/devices/$($d.Id)" }
}

# Step 3: Force Intune device sync so policy/app changes apply quickly
foreach ($d in $affectedDevices) {
    $md = Get-MgDeviceManagementManagedDevice -Filter "azureADDeviceId eq '$($d.DeviceId)'"
    if ($md) {
        Invoke-MgDeviceManagementManagedDeviceSyncDevice -ManagedDeviceId $md.Id
    }
}
```

## Evidence to Confirm Deployment as Cause
- Affected devices are members of the Friday rollout cohort.
- Affected devices share app/prerequisite failure markers not seen in unaffected controls.
- Sign-in outcomes improve after rollout-ring removal plus rollback assignment and sync.

## Evidence to Rule Out Deployment as Cause
- Same failure pattern appears on devices not targeted by Friday rollout.
- No app-state or prerequisite differences between affected and unaffected cohorts.
- Ring removal and rollback assignment do not improve sign-in success or latency.

## Plain-Language Note to Floor 6 (Ready to Send)
Floor 6 team,

We have identified the most likely source of this morning’s login and performance disruption and have already applied a containment change to affected devices. Your data remains safe, and there is no indication of data loss from the login or desktop issues.

What happens now: we are validating each affected device after the containment step and restoring normal access in a controlled sequence. We will send another update as soon as validation confirms stable sign-in behavior across the floor.

If you still see login delays or cannot sign in, contact the Service Desk and include the time, your device name, and a screenshot of any message shown.
