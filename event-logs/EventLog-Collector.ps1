<# 
.SYNOPSIS
    Event Log Collector Tool

.DESCRIPTION
    Collects key Windows event logs (System, Application, Security, Windows Update,
    and Crash logs) and exports them into a timestamped folder on the Desktop.

.OUTPUTS
    EventLogs_<COMPUTERNAME>_<yyyyMMdd_HHmmss>\
#>

Write-Host "Script is running"

# Safe Desktop path
$desktop = [Environment]::GetFolderPath("Desktop")
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$computerName = $env:COMPUTERNAME
$folderName = "EventLogs_${computerName}_$timestamp"
$exportPath = Join-Path $desktop $folderName

# Create export folder
New-Item -ItemType Directory -Path $exportPath -Force | Out-Null

function Export-Log {
    param(
        [string]$LogName,
        [string]$FileName
    )

    Write-Host "Exporting $LogName..."
    try {
        wevtutil epl $LogName (Join-Path $exportPath $FileName) /ow:true
    } catch {
        Write-Host "Failed to export $LogName"
    }
}

Write-Host "Reached: System Logs"
Export-Log -LogName "System" -FileName "System.evtx"

Write-Host "Reached: Application Logs"
Export-Log -LogName "Application" -FileName "Application.evtx"

Write-Host "Reached: Security Logs"
Export-Log -LogName "Security" -FileName "Security.evtx"

Write-Host "Reached: Windows Update Logs"
Export-Log -LogName "Microsoft-Windows-WindowsUpdateClient/Operational" -FileName "WindowsUpdate.evtx"

Write-Host "Reached: Crash Logs"
Export-Log -LogName "Microsoft-Windows-WER-SystemErrorReporting/Operational" -FileName "CrashReports.evtx"

# Export Reliability Monitor events (non-hanging)
Write-Host "Reached: Reliability Events"
try {
    Get-WinEvent -FilterHashtable @{LogName="Microsoft-Windows-Reliability-Analysis-Engine/Operational"} -MaxEvents 200 |
        Export-Clixml -Path (Join-Path $exportPath "ReliabilityEvents.xml")
} catch {
    Write-Host "Failed to export Reliability events"
}

Write-Host "Event logs exported to: $exportPath"
Write-Host "Script complete"
