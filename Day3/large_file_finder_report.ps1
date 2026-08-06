<#
Large File Finder Report (Read-Only)
PowerShell version target: 5.1

VERIFY BEFORE RUNNING:
1) Verify the scan root path in -Path. Scanning large roots (for example C:\) can take time.
2) Verify you have read permissions for all target folders; inaccessible folders are skipped with warnings.
3) Verify the threshold in -ThresholdMB matches your reporting requirement (default is 100 MB).
4) Verify whether you want to include hidden/system files using -IncludeHidden.

This script is strictly read-only:
- No file creation, modification, move, or delete
- No registry/service/configuration changes
- No system state changes
#>

[CmdletBinding()]
param(
    # Section 2: Threshold input (default 100 MB).
    # This value defines the minimum file size (in MB) to include in the report.
    [Parameter()]
    [ValidateRange(1, 1048576)]
    [int]$ThresholdMB = 100,

    # Optional scan root path. Defaults to the current directory.
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Path = (Get-Location).Path,

    # Optional switch to include hidden/system files in the scan.
    [Parameter()]
    [switch]$IncludeHidden
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Continue'

# Convert threshold once for consistent size comparisons.
[long]$thresholdBytes = $ThresholdMB * 1MB

# Section 1: Report large files.
# Recursively reads files from the target path, filters files greater than or equal
# to the threshold, and prints a sorted report (largest first).
function Get-LargeFileReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScanPath,

        [Parameter(Mandatory = $true)]
        [long]$MinBytes,

        [Parameter(Mandatory = $true)]
        [bool]$ShowHidden
    )

    if (-not (Test-Path -LiteralPath $ScanPath)) {
        throw "Path not found: $ScanPath"
    }

    $warnings = New-Object System.Collections.Generic.List[string]

    $gciParams = @{
        LiteralPath = $ScanPath
        File        = $true
        Recurse     = $true
        ErrorAction = 'SilentlyContinue'
        ErrorVariable = '+scanErrors'
    }

    if ($ShowHidden) {
        $gciParams['Force'] = $true
    }

    $scanErrors = @()
    $files = Get-ChildItem @gciParams

    foreach ($err in $scanErrors) {
        $warnings.Add($err.Exception.Message)
    }

    $result = $files |
        Where-Object { $_.Length -ge $MinBytes } |
        Sort-Object -Property Length -Descending |
        Select-Object @{Name='SizeMB';Expression={ [math]::Round($_.Length / 1MB, 2) }}, @{Name='SizeGB';Expression={ [math]::Round($_.Length / 1GB, 3) }}, LastWriteTime, FullName

    [pscustomobject]@{
        ScanPath      = $ScanPath
        ThresholdMB   = [math]::Round($MinBytes / 1MB, 2)
        TotalFound    = @($result).Count
        AccessWarnings = $warnings
        Items         = $result
    }
}

try {
    Write-Host '=== Large File Finder Report (Read-Only) ==='
    Write-Host ("Scan Path: {0}" -f $Path)
    Write-Host ("Threshold: {0} MB" -f $ThresholdMB)
    Write-Host ("Include Hidden/System: {0}" -f [bool]$IncludeHidden)
    Write-Host ''

    $report = Get-LargeFileReport -ScanPath $Path -MinBytes $thresholdBytes -ShowHidden ([bool]$IncludeHidden)

    if ($report.TotalFound -eq 0) {
        Write-Host 'No files found at or above the threshold.'
    }
    else {
        $report.Items | Format-Table -AutoSize
        Write-Host ''
        Write-Host ("Total large files found: {0}" -f $report.TotalFound)
    }

    if ($report.AccessWarnings.Count -gt 0) {
        Write-Warning ("Some locations could not be read. Warning count: {0}" -f $report.AccessWarnings.Count)
        # Show unique warning messages for quick triage, still read-only.
        $report.AccessWarnings |
            Sort-Object -Unique |
            Select-Object -First 10 |
            ForEach-Object { Write-Warning $_ }
    }
}
catch {
    Write-Error $_.Exception.Message
}
