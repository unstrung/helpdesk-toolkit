<# 
.SYNOPSIS
    PC Health Report Tool

.DESCRIPTION
    Collects CPU load, memory usage, disk space, key services,
    Windows version, and installed updates into a single report.

.OUTPUTS
    PCHealth_<COMPUTERNAME>_<yyyyMMdd_HHmmss>.txt
#>

Write-Host "Script is running"

# Safe Desktop path
$desktop = [Environment]::GetFolderPath("Desktop")
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$computerName = $env:COMPUTERNAME
$reportPath = Join-Path $desktop "PCHealth_${computerName}_$timestamp.txt"

function Write-Section {
    param([string]$Title)
    Add-Content -Path $reportPath -Value "`n===================="
    Add-Content -Path $reportPath -Value "$Title"
    Add-Content -Path $reportPath -Value "====================`n"
}

# Start report
"PC Health Report - $computerName" | Out-File -FilePath $reportPath
"Generated: $(Get-Date)" | Add-Content -Path $reportPath

# CPU
Write-Host "Reached: CPU"
Write-Section "CPU Usage"
try {
    $cpu = (Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples.CookedValue
    "CPU Load: {0:N2}%%" -f $cpu | Add-Content -Path $reportPath
} catch {
    "CPU data unavailable" | Add-Content -Path $reportPath
}

# Memory
Write-Host "Reached: Memory"
Write-Section "Memory Usage"
try {
    $os = Get-CimInstance Win32_OperatingSystem
    $total = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
    $free  = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
    $used  = [math]::Round($total - $free, 2)

    "Total RAM: $total GB" | Add-Content -Path $reportPath
    "Used RAM:  $used GB"  | Add-Content -Path $reportPath
    "Free RAM:  $free GB"  | Add-Content -Path $reportPath
} catch {
    "Memory data unavailable" | Add-Content -Path $reportPath
}

# Disk
Write-Host "Reached: Disk"
Write-Section "Disk Space"
try {
    Get-PSDrive -PSProvider FileSystem |
        Select-Object Name, @{n="UsedGB";e={[math]::Round($_.Used/1GB,2)}},
                             @{n="FreeGB";e={[math]::Round($_.Free/1GB,2)}} |
        Out-String | Add-Content -Path $reportPath
} catch {
    "Disk data unavailable" | Add-Content -Path $reportPath
}

# Key services
Write-Host "Reached: Services"
Write-Section "Key Services Status"
$services = "Spooler","Dnscache","LanmanWorkstation","LanmanServer","wuauserv"
try {
    Get-Service -Name $services -ErrorAction SilentlyContinue |
        Out-String | Add-Content -Path $reportPath
} catch {
    "Service data unavailable" | Add-Content -Path $reportPath
}

# Windows version
Write-Host "Reached: Windows Version"
Write-Section "Windows Version"
try {
    Get-CimInstance Win32_OperatingSystem |
        Select-Object Caption, Version, BuildNumber |
        Out-String | Add-Content -Path $reportPath
} catch {
    "Windows version unavailable" | Add-Content -Path $reportPath
}

# Installed updates
Write-Host "Reached: Updates"
Write-Section "Installed Updates (Hotfixes)"
try {
    Get-HotFix | Sort-Object InstalledOn -Descending |
        Out-String | Add-Content -Path $reportPath
} catch {
    "Hotfix data unavailable" | Add-Content -Path $reportPath
}

Write-Host "Report generated at: $reportPath"
Write-Host "Script complete"
