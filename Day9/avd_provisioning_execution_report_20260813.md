# Azure Virtual Desktop Provisioning Report (Day 9)

Date: 2026-08-13
Engineer role: DWP Engineer
Tenant: zippyops.in
Subscription: 63fee90f-7f38-4604-8fbe-c05f7f0ad4a6
Resource Group: DWPAI-LAB-RG
Region: East US

## 1. Objective
Provision Azure Virtual Desktop end to end for a Windows 11 workplace migration scenario with:
- Pooled host pool `POOL-FIN-01`
- Breadth-first load balancing
- Max 5 sessions per host
- Desktop application group linked to workspace `FinBridge-Workspace`
- One Windows 11 multi-session host with Trusted Launch, Secure Boot, and vTPM
- Microsoft Entra ID join model (no on-prem AD)
- User access for `p50@zippyops.in` to both direct VM login and published AVD desktop

## 2. Pre-checks Performed
1. Verified active account and subscription context.
2. Verified RBAC for signed-in identity (`traininguser70@zippyops.in`).
3. Confirmed role at subscription scope: Owner.
4. Confirmed ability to create role assignments before provisioning access roles.

## 3. Control Plane Provisioning (AVD)
Created and validated in `eastus`:
1. Host pool: `POOL-FIN-01`
   - Type: Pooled
   - Load balancer: BreadthFirst
   - Max sessions: 5
2. Desktop app group: `DAG-POOL-FIN-01`
3. Workspace: `FinBridge-Workspace`
4. Registered app group to workspace.

Also set host pool custom RDP properties for Entra-based auth:
- `enablerdsaadauth:i:1;targetisaadjoined:i:1;`

## 4. Session Host Provisioning
Initial VM path was attempted with direct VM creation and manual registration, then corrected to a template-driven path to produce a healthy host registration.

Final successful host VM in pool:
- VM name: `finavd-1`
- Location: eastus
- Size: Standard_B2ms
- Image: MicrosoftWindowsDesktop:windows-11:win11-24h2-avd:latest
- Security type: TrustedLaunch
- Secure Boot: true
- vTPM: true
- AADLoginForWindows extension: installed and succeeded

## 5. Host Registration and Health Validation
Validated session host state from ARM endpoint:
- Host entry: `POOL-FIN-01/finavd-1`
- Status: `Available`
- Health checks: succeeded (including domain and trust checks)
- Heartbeat observed during validation

## 6. Access/RBAC Assignments Completed
For user `p50@zippyops.in`:
1. Role: `Desktop Virtualization User`
   - Scope: app group `DAG-POOL-FIN-01`
2. Role: `Virtual Machine User Login`
   - Scope: VM `finavd-1`

These assignments provide:
- Access to published desktop via AVD client
- Direct Entra-based VM sign-in permissions

## 7. Network/Connection Notes
- `finavd-1` has private IP only (no public IP).
- Direct RDP requires private network path (VPN, Bastion, jump host, or equivalent).
- Last captured private IP: `10.0.0.6`

## 8. Commands and Troubleshooting Notes
During execution, some long-running operations in this terminal environment were interrupted by command wait/cancellation behavior. To complete provisioning reliably:
1. Commands were split into smaller verified steps.
2. Resource state was checked after each step.
3. Session host status was validated through ARM (`sessionHosts` API) instead of assumption.
4. Entra login extension and host health were re-validated until final `Available` state.

## 9. Script(s) Created and Stored in Day9
1. `Day9/avd_register_sessionhost.ps1`
   - Purpose: helper script to install/register AVD components inside a VM.
   - Current status: retained for reference in Day9 per request.

## 10. Final State Summary
Provisioning target is met with one healthy pooled session host available in:
- Host pool: `POOL-FIN-01`
- Workspace: `FinBridge-Workspace`
- App group: `DAG-POOL-FIN-01`
- Session host status: `Available`
- User access roles assigned: Yes (`p50@zippyops.in`)
