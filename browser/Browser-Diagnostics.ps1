<# 
.SYNOPSIS
    Browser Troubleshooting Script

.DESCRIPTION
    Collects DNS resolution, internet connectivity, proxy settings,
    browser cache size, and default browser information. Outputs a
    timestamped report to the Desktop.

.OUTPUTS
    BrowserDiag_<COMPUTERNAME>_<yyyyMMdd_HHmmss>.txt
#>

Write-Host "Script is running"

# Safe Desktop path
$desktop = [Environment]::GetFolderPath("Desktop")
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$computerName = $env:COMPUTERNAME
$reportPath = Join-Path $desktop "BrowserDiag_${computerName}_$timestamp.txt"

function Write-Section {
    param([string]$Title)
    Add-Content -Path $reportPath -Value "`n===================="
    Add-Content -Path $reportPath -Value "$Title"
    Add-Content -Path $reportPath -Value "====================`n"
}

# Start report
"Browser Troubleshooting Report - $computerName" | Out-File -FilePath $reportPath
"Generated: $(Get-Date)" | Add-Content -Path $reportPath

# DNS Resolution
Write-Host "Reached: DNS Resolution"
Write-Section "DNS Resolution Tests"

$testHosts = @(
    "www.microsoft.com",
    "www.google.com",
    "www.github.com"
)

foreach ($host in $testHosts) {
    Add-Content -Path $reportPath -Value "Resolving: $host"
    try {
        Resolve-DnsName $host -ErrorAction Stop | Out-String | Add-Content -Path $reportPath
    } catch {
        Add-Content -Path $reportPath -Value "Failed to resolve $host"
    }
}

# Internet Connectivity
Write-Host "Reached: Internet Connectivity"
Write-Section "Internet Connectivity Tests"

$pingTargets = @(
    "8.8.8.8",
    "1.1.1.1",
    "www.microsoft.com"
)

foreach ($target in $pingTargets) {
    Add-Content -Path $reportPath -Value "Pinging: $target"
    ping $target -n 4 -w 2000 | Out-String | Add-Content -Path $reportPath
}

# Proxy Settings
Write-Host "Reached: Proxy Settings"
Write-Section "Proxy Settings"

try {
    netsh winhttp show proxy | Out-String | Add-Content -Path $reportPath
} catch {
    Add-Content -Path $reportPath -Value "Unable to retrieve proxy settings"
}

# Browser Cache Size (Chrome, Edge, Firefox)
Write-Host "Reached: Browser Cache Size"
Write-Section "Browser Cache Size"

$browserCachePaths = @{
    "Chrome"  = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache"
    "Edge"    = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache"
    "Firefox" = "$env:APPDATA\Mozilla\Firefox\Profiles"
}

foreach ($browser in $browserCachePaths.Keys) {
    Add-Content -Path $reportPath -Value "$browser Cache:"

    $path = $browserCachePaths[$browser]

    if ($browser -eq "Firefox") {
        $profile = Get-ChildItem $path -Directory -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($profile) {
            $path = Join-Path $profile.FullName "cache2"
        }
    }

    if (Test-Path $path) {
        $size = (Get-ChildItem -Recurse -ErrorAction SilentlyContinue $path |
                 Measure-Object -Property Length -Sum).Sum
        $sizeMB = [math]::Round($size / 1MB, 2)
        Add-Content -Path $reportPath -Value "Cache Size: $sizeMB MB"
    } else {
        Add-Content -Path $reportPath -Value "Cache folder not found"
    }
}

# Default Browser
Write-Host "Reached: Default Browser"
Write-Section "Default Browser"

try {
    $defaultBrowser = (Get-ItemProperty "HKCU:\Software\Microsoft\Windows\Shell\Associations\UrlAssociations\http\UserChoice").ProgId
    Add-Content -Path $reportPath -Value "Default Browser ProgID: $defaultBrowser"
} catch {
    Add-Content -Path $reportPath -Value "Unable to determine default browser"
}

Write-Host "Report generated at: $reportPath"
Write-Host "Script complete"
