<# 
.SYNOPSIS
    Network Diagnostic Tool

.DESCRIPTION
    Collects IP configuration, DNS settings, default gateway,
    ping tests, and traceroute output, then writes a report to a text file.

.OUTPUTS
    NetworkReport_<COMPUTERNAME>_<yyyyMMdd_HHmmss>.txt
#>

Write-Host "Script is running"

# Safe Desktop path (works even if Desktop is redirected or missing)
$desktop = [Environment]::GetFolderPath("Desktop")
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$computerName = $env:COMPUTERNAME
$reportPath = Join-Path $desktop "NetworkReport_${computerName}_$timestamp.txt"

function Write-Section {
    param([string]$Title)
    Add-Content -Path $reportPath -Value "`n===================="
    Add-Content -Path $reportPath -Value "$Title"
    Add-Content -Path $reportPath -Value "====================`n"
}

# Start report
"Network Diagnostic Report - $computerName" | Out-File -FilePath $reportPath
"Generated: $(Get-Date)" | Add-Content -Path $reportPath

Write-Host "Reached: IPConfig"
Write-Section "IP Configuration"
ipconfig /all | Out-String | Add-Content -Path $reportPath

Write-Host "Reached: DNS"
Write-Section "DNS Client Settings"
Get-DnsClient | Format-List | Out-String | Add-Content -Path $reportPath

Write-Host "Reached: Gateway"
Write-Section "Network Adapters & Default Gateway"
Get-NetIPConfiguration | Format-List | Out-String | Add-Content -Path $reportPath

# Ping tests with timeouts
Write-Host "Reached: Ping"
Write-Section "Ping Tests"

$gateway = (Get-NetRoute -DestinationPrefix "0.0.0.0/0" |
            Sort-Object RouteMetric |
            Select-Object -First 1).NextHop

"Default Gateway: $gateway" | Add-Content -Path $reportPath

if ($gateway) {
    "Ping to Default Gateway ($gateway)" | Add-Content -Path $reportPath
    ping $gateway -n 4 -w 2000 | Out-String | Add-Content -Path $reportPath
}

"Ping to 8.8.8.8 (Google DNS)" | Add-Content -Path $reportPath
ping 8.8.8.8 -n 4 -w 2000 | Out-String | Add-Content -Path $reportPath
