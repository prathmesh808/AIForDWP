#requires -Version 5.1
[CmdletBinding()]
param(
    [datetime]$IncidentStart = (Get-Date).Date.AddHours(9),
    [string]$UserUpn = "",
    [string]$CitationUrl = "",
    [string]$PromptText = "",
    [string]$ResponseSnippet = "",
    [string]$OutputRoot = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message"
}

function Save-Text {
    param(
        [string]$Path,
        [string]$Content
    )
    $folder = Split-Path -Parent $Path
    if (-not (Test-Path $folder)) {
        New-Item -ItemType Directory -Path $folder -Force | Out-Null
    }
    $Content | Out-File -FilePath $Path -Encoding UTF8 -Force
}

function Save-CommandOutput {
    param(
        [string]$Path,
        [scriptblock]$Command
    )
    try {
        $output = & $Command 2>&1 | Out-String
        Save-Text -Path $Path -Content $output
    }
    catch {
        Save-Text -Path $Path -Content ("FAILED: {0}" -f $_.Exception.Message)
    }
}

function Save-ObjectJson {
    param(
        [string]$Path,
        [object]$Object
    )
    try {
        $json = $Object | ConvertTo-Json -Depth 8
        Save-Text -Path $Path -Content $json
    }
    catch {
        Save-Text -Path $Path -Content ("FAILED: {0}" -f $_.Exception.Message)
    }
}

function Save-ObjectCsv {
    param(
        [string]$Path,
        [object]$Object
    )
    try {
        $folder = Split-Path -Parent $Path
        if (-not (Test-Path $folder)) {
            New-Item -ItemType Directory -Path $folder -Force | Out-Null
        }
        $Object | Export-Csv -Path $Path -NoTypeInformation -Encoding UTF8 -Force
    }
    catch {
        Save-Text -Path ($Path + ".error.txt") -Content ("FAILED: {0}" -f $_.Exception.Message)
    }
}

function Get-LinkDetails {
    param([string]$FolderPath)

    if (-not (Test-Path $FolderPath)) {
        return @()
    }

    $shell = New-Object -ComObject WScript.Shell
    $links = Get-ChildItem -Path $FolderPath -Filter "*.lnk" -File -ErrorAction SilentlyContinue
    $results = @()

    foreach ($link in $links) {
        try {
            $shortcut = $shell.CreateShortcut($link.FullName)
            $results += [pscustomobject]@{
                LinkName       = $link.Name
                LinkPath       = $link.FullName
                TargetPath     = $shortcut.TargetPath
                Arguments      = $shortcut.Arguments
                WorkingDir     = $shortcut.WorkingDirectory
                LastWriteTime  = $link.LastWriteTime
            }
        }
        catch {
            $results += [pscustomobject]@{
                LinkName       = $link.Name
                LinkPath       = $link.FullName
                TargetPath     = "ERROR"
                Arguments      = ""
                WorkingDir     = ""
                LastWriteTime  = $link.LastWriteTime
            }
        }
    }

    return $results
}

$computerName = $env:COMPUTERNAME
$timeStamp = Get-Date -Format "yyyyMMdd_HHmmss"
if ([string]::IsNullOrWhiteSpace($OutputRoot)) {
    $OutputRoot = Join-Path -Path $PSScriptRoot -ChildPath ("Evidence_{0}_{1}" -f $computerName, $timeStamp)
}

New-Item -ItemType Directory -Path $OutputRoot -Force | Out-Null
$transcriptPath = Join-Path $OutputRoot "transcript.txt"
Start-Transcript -Path $transcriptPath -Force | Out-Null

try {
    Write-Info "Collecting incident evidence to: $OutputRoot"

    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    $manifest = [pscustomobject]@{
        CollectedAtUtc  = (Get-Date).ToUniversalTime().ToString("o")
        ComputerName    = $computerName
        IncidentStart   = $IncidentStart.ToString("o")
        UserUpn         = $UserUpn
        CitationUrl     = $CitationUrl
        RanAsAdmin      = $isAdmin
        ScriptVersion   = "1.0"
    }
    Save-ObjectJson -Path (Join-Path $OutputRoot "manifest.json") -Object $manifest

    $metaFolder = Join-Path $OutputRoot "01_system"
    $logFolder = Join-Path $OutputRoot "02_logs"
    $profileFolder = Join-Path $OutputRoot "03_profile_shortcuts"
    $copilotFolder = Join-Path $OutputRoot "04_copilot_context"

    New-Item -ItemType Directory -Path $metaFolder -Force | Out-Null
    New-Item -ItemType Directory -Path $logFolder -Force | Out-Null
    New-Item -ItemType Directory -Path $profileFolder -Force | Out-Null
    New-Item -ItemType Directory -Path $copilotFolder -Force | Out-Null

    Write-Info "Collecting system and identity context"
    Save-CommandOutput -Path (Join-Path $metaFolder "whoami.txt") -Command { whoami /all }
    Save-CommandOutput -Path (Join-Path $metaFolder "hostname.txt") -Command { hostname }
    Save-CommandOutput -Path (Join-Path $metaFolder "systeminfo.txt") -Command { systeminfo }
    Save-CommandOutput -Path (Join-Path $metaFolder "ipconfig_all.txt") -Command { ipconfig /all }
    Save-CommandOutput -Path (Join-Path $metaFolder "route_print.txt") -Command { route print }
    Save-CommandOutput -Path (Join-Path $metaFolder "w32tm_status.txt") -Command { w32tm /query /status }
    Save-CommandOutput -Path (Join-Path $metaFolder "w32tm_source.txt") -Command { w32tm /query /source }
    Save-CommandOutput -Path (Join-Path $metaFolder "dsreg_status.txt") -Command { dsregcmd /status }

    Save-ObjectCsv -Path (Join-Path $metaFolder "local_users.csv") -Object (Get-LocalUser | Select-Object Name, Enabled, LastLogon)
    Save-ObjectCsv -Path (Join-Path $metaFolder "installed_apps_wmi.csv") -Object (Get-CimInstance Win32_Product | Select-Object Name, Version, Vendor)

    Write-Info "Collecting event logs for login and profile symptoms"
    $securityEvents = Get-WinEvent -FilterHashtable @{
        LogName   = 'Security'
        Id        = 4624, 4625, 4634
        StartTime = $IncidentStart
    } -ErrorAction SilentlyContinue | Select-Object TimeCreated, Id, LevelDisplayName, Message
    Save-ObjectCsv -Path (Join-Path $logFolder "security_4624_4625_4634.csv") -Object $securityEvents

    $profileEvents = Get-WinEvent -FilterHashtable @{
        LogName      = 'Application'
        ProviderName = 'Microsoft-Windows-User Profiles Service'
        StartTime    = $IncidentStart
    } -ErrorAction SilentlyContinue | Select-Object TimeCreated, Id, LevelDisplayName, Message
    Save-ObjectCsv -Path (Join-Path $logFolder "user_profile_service_application.csv") -Object $profileEvents

    $gpEvents = Get-WinEvent -FilterHashtable @{
        LogName   = 'Microsoft-Windows-GroupPolicy/Operational'
        StartTime = $IncidentStart
    } -ErrorAction SilentlyContinue | Select-Object TimeCreated, Id, LevelDisplayName, Message
    Save-ObjectCsv -Path (Join-Path $logFolder "group_policy_operational.csv") -Object $gpEvents

    $perfEvents = Get-WinEvent -FilterHashtable @{
        LogName   = 'Microsoft-Windows-Diagnostics-Performance/Operational'
        Id        = 100, 101, 102, 200, 201
        StartTime = $IncidentStart
    } -ErrorAction SilentlyContinue | Select-Object TimeCreated, Id, LevelDisplayName, Message
    Save-ObjectCsv -Path (Join-Path $logFolder "diagnostics_performance.csv") -Object $perfEvents

    $mdmEvents = Get-WinEvent -FilterHashtable @{
        LogName   = 'Microsoft-Windows-DeviceManagement-Enterprise-Diagnostics-Provider/Admin'
        StartTime = $IncidentStart
    } -ErrorAction SilentlyContinue | Select-Object TimeCreated, Id, LevelDisplayName, Message
    Save-ObjectCsv -Path (Join-Path $logFolder "mdm_enterprise_admin.csv") -Object $mdmEvents

    Write-Info "Collecting profile mapping and shortcut evidence"
    $profileListPath = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList'
    Save-CommandOutput -Path (Join-Path $profileFolder "profilelist_reg_export.txt") -Command { reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList" /s }

    $profileMappings = Get-ChildItem -Path $profileListPath -ErrorAction SilentlyContinue | ForEach-Object {
        $props = Get-ItemProperty -Path $_.PSPath -ErrorAction SilentlyContinue
        [pscustomobject]@{
            Sid               = $_.PSChildName
            ProfileImagePath  = $props.ProfileImagePath
            RefCount          = $props.RefCount
            State             = $props.State
            HasBakSuffix      = $_.PSChildName.EndsWith('.bak')
        }
    }
    Save-ObjectCsv -Path (Join-Path $profileFolder "profile_mappings.csv") -Object $profileMappings

    $currentUserDesktop = Join-Path $env:USERPROFILE "Desktop"
    $publicDesktop = Join-Path $env:PUBLIC "Desktop"

    Save-CommandOutput -Path (Join-Path $profileFolder "desktop_paths.txt") -Command {
        "CurrentUserDesktop=$currentUserDesktop`nPublicDesktop=$publicDesktop"
    }

    Save-ObjectCsv -Path (Join-Path $profileFolder "current_user_desktop_files.csv") -Object (
        Get-ChildItem -Path $currentUserDesktop -File -ErrorAction SilentlyContinue | Select-Object Name, FullName, Length, LastWriteTime
    )

    Save-ObjectCsv -Path (Join-Path $profileFolder "public_desktop_files.csv") -Object (
        Get-ChildItem -Path $publicDesktop -File -ErrorAction SilentlyContinue | Select-Object Name, FullName, Length, LastWriteTime
    )

    Save-ObjectCsv -Path (Join-Path $profileFolder "current_user_desktop_links.csv") -Object (Get-LinkDetails -FolderPath $currentUserDesktop)
    Save-ObjectCsv -Path (Join-Path $profileFolder "public_desktop_links.csv") -Object (Get-LinkDetails -FolderPath $publicDesktop)

    Save-CommandOutput -Path (Join-Path $profileFolder "icacls_current_user_desktop.txt") -Command { icacls "$currentUserDesktop" }
    Save-CommandOutput -Path (Join-Path $profileFolder "icacls_public_desktop.txt") -Command { icacls "$publicDesktop" }

    Write-Info "Collecting Copilot incident context placeholders and local traces"
    $copilotStatement = @"
Copilot incident evidence statement
---------------------------------
User UPN: $UserUpn
Incident start: $($IncidentStart.ToString('o'))
Citation URL: $CitationUrl
Prompt text: $PromptText
Response snippet: $ResponseSnippet

Engineer action required (cloud-side):
1) Purview Audit search export for incident window.
2) SharePoint effective access screenshot for cited source.
3) Inheritance chain screenshot.
4) Entra group membership export for user and access groups.
"@
    Save-Text -Path (Join-Path $copilotFolder "copilot_incident_statement.txt") -Content $copilotStatement

    Save-CommandOutput -Path (Join-Path $copilotFolder "edge_version.txt") -Command {
        Get-Item "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\msedge.exe" -ErrorAction SilentlyContinue | Out-String
    }

    Save-CommandOutput -Path (Join-Path $copilotFolder "office_signin_accounts_hint.txt") -Command {
        Get-ChildItem "$env:LOCALAPPDATA\Microsoft\IdentityCache" -ErrorAction SilentlyContinue | Select-Object Name, LastWriteTime
    }

    $summary = @"
Evidence collection complete.
Output folder: $OutputRoot
Admin context: $isAdmin

Collected for issues:
1) Login failures/slow sign-in: security, profile, GP, performance, MDM logs.
2) Missing desktop shortcuts: profile mapping, desktop file inventories, .lnk targets, ACLs.
3) Copilot unexpected matter: local incident statement + cloud evidence checklist scaffold.
"@
    Save-Text -Path (Join-Path $OutputRoot "SUMMARY.txt") -Content $summary

    Write-Info "Evidence collection completed successfully"
}
finally {
    Stop-Transcript | Out-Null
}
