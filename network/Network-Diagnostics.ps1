<# 
.SYNOPSIS
    Network Diagnostic Tool

.DESCRIPTION
    Collects IP configuration, DNS settings, default gateway,
    ping tests, and traceroute output, then writes a report to a text file.

.OUTPUTS
    NetworkReport_<COMPUTERNAME>_<yyyyMMdd_HHmmss>.txt
#>

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$computerName = $env:COMPUTERNAME
$reportPath = "$env:USERPROFILE\Desktop\NetworkReport_${computerName}_$timestamp.txt"

function Write-Section {
    param([string]$Title)
    Add-Content -Path $reportPath -Value "`n===================="
    Add-Content -Path $reportPath -Value "$Title"
    Add-Content -Path $reportPath -Value "====================`n"
}

# Start report
"Network Diagnostic Report - $computerName" | Out-File -FilePath $reportPath
"Generated: $(Get-Date)" | Add-Content -Path $reportPath

# IP configuration
Write-Section "IP Configuration"
ipconfig /all | Out-String | Add-Content -Path $reportPath

# DNS settings
Write-Section "DNS Client Settings"
Get-DnsClient | Format-List | Out-String | Add-Content -Path $reportPath

# Network adapters & gateway
Write-Section "Network Adapters & Default Gateway"
Get-NetIPConfiguration | Format-List | Out-String | Add-Content -Path $reportPath

# Ping tests
Write-Section "Ping Tests"
$gateway = (Get-NetRoute -DestinationPrefix "0.0.0.0/0" |
            Sort-Object RouteMetric |
            Select-Object -First 1).NextHop

"Default Gateway: $gateway" | Add-Content -Path $reportPath

if ($gateway) {
    "Ping to Default Gateway ($gateway)" | Add-Content -Path $reportPath
    ping $gateway | Out-String | Add-Content -Path $reportPath
}

"Ping to 8.8.8.8 (Google DNS)" | Add-Content -Path $reportPath
ping 8.8.8.8 | Out-String | Add-Content -Path $reportPath

"Ping to www.microsoft.com" | Add-Content -Path $reportPath
ping www.microsoft.com | Out-String | Add-Content -Path $reportPath

# Traceroute
Write-Section "Traceroute to www.microsoft.com"
tracert www.microsoft.com | Out-String | Add-Content -Path $reportPath

# Summary
Write-Section "Summary"
"Review IP config, DNS, gateway reachability, and traceroute hops to identify where connectivity fails." |
    Add-Content -Path $reportPath

Write-Host "Network report generated at: $reportPath"
