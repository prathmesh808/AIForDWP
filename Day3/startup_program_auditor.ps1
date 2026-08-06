<#
Startup Program Auditor
PowerShell version target: 5.1

VERIFY BEFORE RUNNING:
1) Verify whether you want read-only behavior or changes:
   - Default behavior is dry run listing only.
   - Using -Disable makes changes to startup entries.
2) Verify you run as Administrator if you need to disable machine-wide entries (HKLM / All Users startup folder).
3) Verify the program name passed to -ProgramName is specific enough to avoid unintended matches.
4) Verify endpoint policy allows modifying startup entries.

Safety and idempotency:
- Dry run mode does not change system state.
- Disable mode only moves/relocates startup entries into DWP-disabled locations.
- Re-running disable on the same program is idempotent: already-disabled items are skipped.
#>

[CmdletBinding()]
param(
    # Section: Dry run flag.
    # When set, the script only lists startup programs and performs no changes.
    [Parameter()]
    [switch]$DryRun,

    # Section: Disable flag.
    # When set with -ProgramName, matching startup entries are disabled safely.
    [Parameter()]
    [switch]$Disable,

    # Section: Program name input for disable mode.
    # Matching is case-insensitive and uses wildcard-style contains matching.
    [Parameter()]
    [string]$ProgramName
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Continue'

# Section: Internal constants used for disabled-entry storage.
# These locations are used to move startup entries without deleting them.
$DisabledRegistrySuffix = 'Run-Disabled-DWPAuditor'
$DisabledFolderName = 'Startup-Disabled-DWPAuditor'

# Section: Registry and folder startup sources.
# This defines where startup entries are discovered for current user and all users.
$RegistrySources = @(
    [pscustomobject]@{ Scope = 'CurrentUser'; Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' },
    [pscustomobject]@{ Scope = 'LocalMachine'; Path = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Run' },
    [pscustomobject]@{ Scope = 'LocalMachine'; Path = 'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Run' }
)

$FolderSources = @(
    [pscustomobject]@{ Scope = 'CurrentUser'; Path = (Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\Startup') },
    [pscustomobject]@{ Scope = 'AllUsers'; Path = (Join-Path $env:ProgramData 'Microsoft\Windows\Start Menu\Programs\StartUp') }
)

# Section: Logging helper for consistent console output.
# Keeps output structured for both dry run and disable operations.
function Write-Log {
    param(
        [Parameter(Mandatory = $true)][string]$Message,
        [Parameter()][ValidateSet('INFO', 'WARN', 'ERROR')][string]$Level = 'INFO'
    )

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    Write-Host ("[{0}] [{1}] {2}" -f $timestamp, $Level, $Message)
}

# Section: Reads startup entries from registry Run keys.
# Returns each value as a startup item object for reporting and optional disable.
function Get-RegistryStartupItems {
    $items = @()

    foreach ($source in $RegistrySources) {
        if (-not (Test-Path -LiteralPath $source.Path)) {
            continue
        }

        try {
            $keyItem = Get-Item -LiteralPath $source.Path -ErrorAction Stop
            $props = Get-ItemProperty -LiteralPath $source.Path -ErrorAction Stop

            foreach ($prop in $props.PSObject.Properties) {
                if ($prop.Name -in @('PSPath', 'PSParentPath', 'PSChildName', 'PSDrive', 'PSProvider')) {
                    continue
                }

                $items += [pscustomobject]@{
                    ItemType     = 'RegistryRun'
                    Scope        = $source.Scope
                    Name         = $prop.Name
                    Command      = [string]$prop.Value
                    SourcePath   = $source.Path
                    Exists       = $true
                    IsDisabled   = $false
                    DisabledPath = ($source.Path -replace '\\Run$', "\\$DisabledRegistrySuffix")
                }
            }
        }
        catch {
            Write-Log -Level 'WARN' -Message ("Unable to read registry source {0}: {1}" -f $source.Path, $_.Exception.Message)
        }
    }

    return $items
}

# Section: Reads startup entries from Startup folders.
# Returns file-based startup items (.lnk/.exe/.bat/.cmd/.ps1/.vbs etc.) for reporting and optional disable.
function Get-FolderStartupItems {
    $items = @()

    foreach ($source in $FolderSources) {
        if (-not (Test-Path -LiteralPath $source.Path)) {
            continue
        }

        try {
            $files = Get-ChildItem -LiteralPath $source.Path -File -ErrorAction Stop
            foreach ($file in $files) {
                $items += [pscustomobject]@{
                    ItemType     = 'StartupFolderFile'
                    Scope        = $source.Scope
                    Name         = $file.BaseName
                    Command      = $file.FullName
                    SourcePath   = $file.FullName
                    Exists       = $true
                    IsDisabled   = $false
                    DisabledPath = (Join-Path (Split-Path -Path $source.Path -Parent) $DisabledFolderName)
                }
            }
        }
        catch {
            Write-Log -Level 'WARN' -Message ("Unable to read startup folder {0}: {1}" -f $source.Path, $_.Exception.Message)
        }
    }

    return $items
}

# Section: Reads already disabled entries for idempotency checks.
# This allows the script to skip entries that were already disabled in previous runs.
function Get-AlreadyDisabledItems {
    $disabled = @()

    foreach ($source in $RegistrySources) {
        $disabledKey = $source.Path -replace '\\Run$', "\\$DisabledRegistrySuffix"
        if (-not (Test-Path -LiteralPath $disabledKey)) {
            continue
        }

        try {
            $props = Get-ItemProperty -LiteralPath $disabledKey -ErrorAction Stop
            foreach ($prop in $props.PSObject.Properties) {
                if ($prop.Name -in @('PSPath', 'PSParentPath', 'PSChildName', 'PSDrive', 'PSProvider')) {
                    continue
                }

                $disabled += [pscustomobject]@{
                    ItemType   = 'RegistryRun'
                    Scope      = $source.Scope
                    Name       = $prop.Name
                    Command    = [string]$prop.Value
                    SourcePath = $disabledKey
                    IsDisabled = $true
                }
            }
        }
        catch {
            Write-Log -Level 'WARN' -Message ("Unable to read disabled registry key {0}: {1}" -f $disabledKey, $_.Exception.Message)
        }
    }

    foreach ($source in $FolderSources) {
        $disabledFolder = Join-Path (Split-Path -Path $source.Path -Parent) $DisabledFolderName
        if (-not (Test-Path -LiteralPath $disabledFolder)) {
            continue
        }

        try {
            $files = Get-ChildItem -LiteralPath $disabledFolder -File -ErrorAction Stop
            foreach ($file in $files) {
                $disabled += [pscustomobject]@{
                    ItemType   = 'StartupFolderFile'
                    Scope      = $source.Scope
                    Name       = $file.BaseName
                    Command    = $file.FullName
                    SourcePath = $file.FullName
                    IsDisabled = $true
                }
            }
        }
        catch {
            Write-Log -Level 'WARN' -Message ("Unable to read disabled startup folder {0}: {1}" -f $disabledFolder, $_.Exception.Message)
        }
    }

    return $disabled
}

# Section: Disables a registry startup item by moving it to a disabled key.
# This is reversible and idempotent because existing disabled values are detected and skipped.
function Disable-RegistryStartupItem {
    param(
        [Parameter(Mandatory = $true)]$Item
    )

    $targetKey = $Item.DisabledPath

    try {
        if (-not (Test-Path -LiteralPath $targetKey)) {
            New-Item -Path $targetKey -Force | Out-Null
        }

        $existing = Get-ItemProperty -LiteralPath $targetKey -Name $Item.Name -ErrorAction SilentlyContinue
        if ($null -ne $existing) {
            Write-Log -Level 'INFO' -Message ("Already disabled (registry): {0}" -f $Item.Name)
            return 'SkippedAlreadyDisabled'
        }

        $value = (Get-ItemProperty -LiteralPath $Item.SourcePath -Name $Item.Name -ErrorAction Stop).$($Item.Name)
        Set-ItemProperty -LiteralPath $targetKey -Name $Item.Name -Value $value -Type String -ErrorAction Stop
        Remove-ItemProperty -LiteralPath $Item.SourcePath -Name $Item.Name -ErrorAction Stop

        Write-Log -Level 'INFO' -Message ("Disabled (registry): {0}" -f $Item.Name)
        return 'Disabled'
    }
    catch {
        Write-Log -Level 'ERROR' -Message ("Failed to disable registry item {0}: {1}" -f $Item.Name, $_.Exception.Message)
        return 'Error'
    }
}

# Section: Disables a startup-folder item by moving it to a disabled folder.
# This is reversible and idempotent because existing moved files are detected and skipped.
function Disable-FolderStartupItem {
    param(
        [Parameter(Mandatory = $true)]$Item
    )

    try {
        $sourceFile = Get-Item -LiteralPath $Item.SourcePath -ErrorAction Stop
        $targetFolder = $Item.DisabledPath

        if (-not (Test-Path -LiteralPath $targetFolder)) {
            New-Item -Path $targetFolder -ItemType Directory -Force | Out-Null
        }

        $targetFile = Join-Path $targetFolder $sourceFile.Name
        if (Test-Path -LiteralPath $targetFile) {
            Write-Log -Level 'INFO' -Message ("Already disabled (startup folder): {0}" -f $Item.Name)
            return 'SkippedAlreadyDisabled'
        }

        Move-Item -LiteralPath $sourceFile.FullName -Destination $targetFile -ErrorAction Stop
        Write-Log -Level 'INFO' -Message ("Disabled (startup folder): {0}" -f $Item.Name)
        return 'Disabled'
    }
    catch {
        Write-Log -Level 'ERROR' -Message ("Failed to disable startup-folder item {0}: {1}" -f $Item.Name, $_.Exception.Message)
        return 'Error'
    }
}

# Section: Lists startup items and already-disabled items.
# Used for dry run reporting so engineers can review current startup posture safely.
function Show-StartupReport {
    $activeItems = @(Get-RegistryStartupItems + Get-FolderStartupItems)
    $disabledItems = @(Get-AlreadyDisabledItems)

    Write-Host ''
    Write-Host '=== Startup Program Auditor: Dry Run Report ==='
    Write-Host ''

    Write-Host '[Active Startup Items]'
    if ($activeItems.Count -eq 0) {
        Write-Host 'No active startup items found.'
    }
    else {
        $activeItems |
            Sort-Object Scope, ItemType, Name |
            Select-Object Scope, ItemType, Name, Command |
            Format-Table -AutoSize
    }

    Write-Host ''
    Write-Host '[Already Disabled By DWP Auditor]'
    if ($disabledItems.Count -eq 0) {
        Write-Host 'No DWP-disabled startup items found.'
    }
    else {
        $disabledItems |
            Sort-Object Scope, ItemType, Name |
            Select-Object Scope, ItemType, Name, Command |
            Format-Table -AutoSize
    }

    Write-Host ''
    Write-Host ("Totals: Active={0}, DisabledByAuditor={1}" -f $activeItems.Count, $disabledItems.Count)
}

# Section: Disables matching startup items by program name.
# Matching is case-insensitive using wildcard contains semantics for practical operations.
function Disable-StartupPrograms {
    param(
        [Parameter(Mandatory = $true)]
        [string]$NameFilter
    )

    $activeItems = @(Get-RegistryStartupItems + Get-FolderStartupItems)
    $matches = @(
        $activeItems | Where-Object {
            $_.Name -like "*$NameFilter*" -or $_.Command -like "*$NameFilter*"
        }
    )

    if ($matches.Count -eq 0) {
        Write-Log -Level 'WARN' -Message ("No active startup items matched filter: {0}" -f $NameFilter)
        return
    }

    Write-Log -Level 'INFO' -Message ("Matched startup items: {0}" -f $matches.Count)

    $disabledCount = 0
    $skippedCount = 0
    $errorCount = 0

    foreach ($item in $matches) {
        if ($item.ItemType -eq 'RegistryRun') {
            $status = Disable-RegistryStartupItem -Item $item
        }
        elseif ($item.ItemType -eq 'StartupFolderFile') {
            $status = Disable-FolderStartupItem -Item $item
        }
        else {
            $status = 'Error'
        }

        switch ($status) {
            'Disabled' { $disabledCount++ }
            'SkippedAlreadyDisabled' { $skippedCount++ }
            default { $errorCount++ }
        }
    }

    Write-Host ''
    Write-Host '=== Disable Summary ==='
    Write-Host ("Filter: {0}" -f $NameFilter)
    Write-Host ("Disabled: {0}" -f $disabledCount)
    Write-Host ("Skipped (already disabled): {0}" -f $skippedCount)
    Write-Host ("Errors: {0}" -f $errorCount)
}

# Section: Entry-point validation and mode selection.
# Ensures safe defaults and valid parameter combinations before operations begin.
if (-not $DryRun -and -not $Disable) {
    $DryRun = $true
}

if ($Disable -and [string]::IsNullOrWhiteSpace($ProgramName)) {
    throw 'Disable mode requires -ProgramName.'
}

if ($DryRun -and $Disable) {
    Write-Log -Level 'WARN' -Message 'Both -DryRun and -Disable were specified. Disable mode will run; dry run listing skipped.'
}

if ($Disable) {
    Write-Log -Level 'INFO' -Message 'Starting disable operation.'
    Disable-StartupPrograms -NameFilter $ProgramName
}
else {
    Write-Log -Level 'INFO' -Message 'Starting dry run listing operation.'
    Show-StartupReport
}
