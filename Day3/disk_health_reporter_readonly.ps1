<#
Disk Health Reporter (Read-Only)
PowerShell version target: 5.1

VERIFY BEFORE RUNNING:
1) Verify you run in a PowerShell session with permission to read storage data. Some sections may show partial results without admin rights.
2) Verify the Storage module/cmdlets are available on the endpoint (Get-PhysicalDisk, Get-StorageReliabilityCounter).
3) Verify this endpoint has supported storage providers; virtualized or legacy devices may not expose SMART/reliability counters.
4) Verify your expectation for "disk optimization status": this script reports status/telemetry only and never starts defrag/retrim.

This script is strictly read-only:
- No disk optimization actions
- No defragmentation or retrim commands
- No registry/service/configuration changes
- No system state changes
#>

[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Continue'

# Section 1: Reports disk health.
# Reads disk and volume health data from Windows storage cmdlets/CIM and prints
# a consolidated view without changing anything on the system.
function Get-DiskHealthReport {
    $result = [ordered]@{}

    try {
        $result['Disks'] = Get-Disk |
            Select-Object Number, FriendlyName, SerialNumber, BusType, PartitionStyle, OperationalStatus, HealthStatus,
                @{Name='SizeGB';Expression={ [math]::Round($_.Size / 1GB, 2) }}
    }
    catch {
        $result['Disks'] = [pscustomobject]@{ Error = $_.Exception.Message }
    }

    try {
        $result['Volumes'] = Get-Volume |
            Where-Object { $_.DriveLetter -ne $null } |
            Select-Object DriveLetter, FileSystem, HealthStatus, OperationalStatus,
                @{Name='SizeGB';Expression={ [math]::Round($_.Size / 1GB, 2) }},
                @{Name='FreeGB';Expression={ [math]::Round($_.SizeRemaining / 1GB, 2) }},
                @{Name='FreePercent';Expression={ if ($_.Size -gt 0) { [math]::Round(($_.SizeRemaining / $_.Size) * 100, 2) } else { $null } }}
    }
    catch {
        $result['Volumes'] = [pscustomobject]@{ Error = $_.Exception.Message }
    }

    try {
        if (Get-Command -Name Get-PhysicalDisk -ErrorAction SilentlyContinue) {
            $result['PhysicalDisks'] = Get-PhysicalDisk |
                Select-Object FriendlyName, SerialNumber, MediaType, CanPool, OperationalStatus, HealthStatus,
                    @{Name='SizeGB';Expression={ [math]::Round($_.Size / 1GB, 2) }}
        }
        else {
            $result['PhysicalDisks'] = [pscustomobject]@{ Info = 'Get-PhysicalDisk is not available on this endpoint.' }
        }
    }
    catch {
        $result['PhysicalDisks'] = [pscustomobject]@{ Error = $_.Exception.Message }
    }

    try {
        if ((Get-Command -Name Get-StorageReliabilityCounter -ErrorAction SilentlyContinue) -and
            (Get-Command -Name Get-PhysicalDisk -ErrorAction SilentlyContinue)) {

            $reliability = foreach ($pd in Get-PhysicalDisk) {
                try {
                    $c = Get-StorageReliabilityCounter -PhysicalDisk $pd -ErrorAction Stop
                    [pscustomobject]@{
                        FriendlyName                  = $pd.FriendlyName
                        TemperatureCelsius            = $c.Temperature
                        ReadErrorsTotal               = $c.ReadErrorsTotal
                        WriteErrorsTotal              = $c.WriteErrorsTotal
                        Wear                          = $c.Wear
                        PowerOnHours                  = $c.PowerOnHours
                        StartStopCycleCount           = $c.StartStopCycleCount
                        ReallocatedSectors            = $c.ReallocatedSectors
                        UncorrectableReadErrorsTotal  = $c.UncorrectableReadErrorsTotal
                        UncorrectableWriteErrorsTotal = $c.UncorrectableWriteErrorsTotal
                    }
                }
                catch {
                    [pscustomobject]@{
                        FriendlyName = $pd.FriendlyName
                        Error        = $_.Exception.Message
                    }
                }
            }
            $result['ReliabilityCounters'] = $reliability
        }
        else {
            $result['ReliabilityCounters'] = [pscustomobject]@{ Info = 'Storage reliability counters are not available on this endpoint.' }
        }
    }
    catch {
        $result['ReliabilityCounters'] = [pscustomobject]@{ Error = $_.Exception.Message }
    }

    return [pscustomobject]$result
}

# Section 2: Disk optimisation status.
# Reports optimization scheduling/status signals only. It never triggers any
# optimization, analyze, retrim, or defragmentation operation.
function Get-DiskOptimizationStatus {
    $result = [ordered]@{}

    try {
        $task = Get-ScheduledTask -TaskPath '\Microsoft\Windows\Defrag\' -TaskName 'ScheduledDefrag' -ErrorAction Stop
        $taskInfo = Get-ScheduledTaskInfo -TaskPath '\Microsoft\Windows\Defrag\' -TaskName 'ScheduledDefrag' -ErrorAction Stop

        $result['ScheduledOptimizationTask'] = [pscustomobject]@{
            TaskName       = $task.TaskName
            TaskPath       = $task.TaskPath
            State          = $task.State
            Enabled        = $task.Settings.Enabled
            LastRunTime    = $taskInfo.LastRunTime
            NextRunTime    = $taskInfo.NextRunTime
            LastTaskResult = $taskInfo.LastTaskResult
            Note           = 'Status only. This script does not start this task.'
        }
    }
    catch {
        $result['ScheduledOptimizationTask'] = [pscustomobject]@{ Error = $_.Exception.Message }
    }

    try {
        $volInfo = Get-Volume |
            Where-Object { $_.DriveLetter -ne $null } |
            Select-Object DriveLetter, FileSystem, DriveType, HealthStatus,
                @{Name='OptimizationTypeHint';Expression={
                    if ($_.DriveType -eq 'Fixed') { 'Likely optimized by Storage Optimizer schedule (HDD defrag / SSD retrim handled by OS).' }
                    elseif ($_.DriveType -eq 'Removable') { 'Usually not targeted by scheduled optimization.' }
                    else { 'Not typically part of standard fixed-disk optimization policy.' }
                }}

        $result['VolumeOptimizationOverview'] = $volInfo
    }
    catch {
        $result['VolumeOptimizationOverview'] = [pscustomobject]@{ Error = $_.Exception.Message }
    }

    return [pscustomobject]$result
}

try {
    Write-Host '=== Disk Health Reporter (Read-Only) ==='
    Write-Host ''

    $health = Get-DiskHealthReport
    $opt = Get-DiskOptimizationStatus

    Write-Host '--- Section 1: Reports disk health ---'
    Write-Host ''

    Write-Host '[Disks]'
    $health.Disks | Format-Table -AutoSize
    Write-Host ''

    Write-Host '[Volumes]'
    $health.Volumes | Format-Table -AutoSize
    Write-Host ''

    Write-Host '[Physical Disks]'
    $health.PhysicalDisks | Format-Table -AutoSize
    Write-Host ''

    Write-Host '[Reliability Counters / SMART-like Telemetry]'
    $health.ReliabilityCounters | Format-Table -AutoSize
    Write-Host ''

    Write-Host '--- Section 2: Disk optimisation status ---'
    Write-Host ''

    Write-Host '[Scheduled Optimization Task Status]'
    $opt.ScheduledOptimizationTask | Format-List
    Write-Host ''

    Write-Host '[Volume Optimization Overview]'
    $opt.VolumeOptimizationOverview | Format-Table -AutoSize
    Write-Host ''

    Write-Host 'Section 3 guarantee: Read-only mode maintained. No defragmentation actions were executed.'
}
catch {
    Write-Error $_.Exception.Message
}
