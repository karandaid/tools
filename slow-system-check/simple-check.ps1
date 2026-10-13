<#
.SYNOPSIS
    Quick, read-only health check for a slow Windows PC. Writes a plain-text report to the Desktop.

.DESCRIPTION
    Collects: computer model/OS/CPU/RAM/disk/uptime, top 5 programs by memory,
    Wi-Fi details, ping latency, rough download speed, VPN status and browser versions.
    Nothing is changed on the machine. Send the generated report file back to the author.

.NOTES
    Author : Karandeep Singh <karandaid@gmail.com>
    Run    : powershell.exe -ExecutionPolicy Bypass -File .\simple-check.ps1
    Works on Windows PowerShell 5.1+.
#>

$ErrorActionPreference = 'SilentlyContinue'
$computer = $env:COMPUTERNAME
$stamp    = Get-Date -Format 'yyyy-MM-dd_HHmm'
$report   = Join-Path ([Environment]::GetFolderPath('Desktop')) "system-report-$computer-$stamp.txt"

Start-Transcript -Path $report | Out-Null

# --- COMPUTER ---
Write-Host "--- COMPUTER ---"
$cs = Get-CimInstance Win32_ComputerSystem
$os = Get-CimInstance Win32_OperatingSystem
$cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
$disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
"Model        : $($cs.Manufacturer) $($cs.Model)"
"Windows      : $($os.Caption) build $($os.BuildNumber)"
"CPU          : $($cpu.Name)"
"Memory       : {0:N1} GB total, {1:N1} GB free" -f ($cs.TotalPhysicalMemory/1GB), ($os.FreePhysicalMemory/1MB)
"Disk C:      : {0:N0} GB free of {1:N0} GB" -f ($disk.FreeSpace/1GB), ($disk.Size/1GB)
"Last restart : $($os.LastBootUpTime.ToString('yyyy-MM-dd h:mm:ss tt'))"

# --- TOP 5 PROGRAMS BY MEMORY ---
Write-Host ""
Write-Host "--- TOP 5 PROGRAMS BY MEMORY ---"
Get-Process | Group-Object ProcessName |
    ForEach-Object { [pscustomobject]@{ Program = $_.Name; MB = [math]::Round(($_.Group | Measure-Object WorkingSet64 -Sum).Sum/1MB) } } |
    Sort-Object MB -Descending | Select-Object -First 5 | Format-Table -AutoSize | Out-String | Write-Host

# --- WI-FI ---
Write-Host "--- WI-FI ---"
netsh wlan show interfaces | Select-String -Pattern '^\s*(SSID|Radio type|Receive rate|Transmit rate|Signal)\b' |
    ForEach-Object { $_.Line.Trim() -replace '^(\S.*?)\s*:\s*', '$1 : ' } |
    ForEach-Object { $_ }

# --- PING ---
Write-Host ""
Write-Host "--- PING GOOGLE DNS (10 tries) ---"
ping -n 10 8.8.8.8 | Select-String 'Packets|Minimum'

# --- DOWNLOAD SPEED ---
Write-Host ""
Write-Host "--- DOWNLOAD SPEED ---"
try {
    $url = 'https://speed.cloudflare.com/__down?bytes=25000000'
    $sw = [Diagnostics.Stopwatch]::StartNew()
    $bytes = (New-Object Net.WebClient).DownloadData($url).Length
    $sw.Stop()
    "{0:N0} Mbps" -f (($bytes * 8) / 1MB / $sw.Elapsed.TotalSeconds)
} catch { "Could not measure download speed" }

# --- VPN ---
Write-Host ""
Write-Host "--- VPN ---"
$vpn = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' -and $_.InterfaceDescription -match 'TAP|TUN|WireGuard|VPN|Wintun|Cisco|Fortinet|Palo Alto' }
if ($vpn) {
    "VPN is CONNECTED:"
    $vpn | ForEach-Object { "  $($_.Name) ($($_.InterfaceDescription))" }
} else { "No VPN detected" }

# --- BROWSERS ---
Write-Host ""
Write-Host "--- BROWSERS ---"
function Get-Ver($paths) { foreach ($p in $paths) { if (Test-Path $p) { return (Get-Item $p).VersionInfo.ProductVersion } } 'not installed' }
$pf = $env:ProgramFiles; $pf86 = ${env:ProgramFiles(x86)}
"Edge    : $(Get-Ver @("$pf86\Microsoft\Edge\Application\msedge.exe","$pf\Microsoft\Edge\Application\msedge.exe"))"
"Firefox : $(Get-Ver @("$pf\Mozilla Firefox\firefox.exe","$pf86\Mozilla Firefox\firefox.exe"))"
"Chrome  : $(Get-Ver @("$pf\Google\Chrome\Application\chrome.exe","$pf86\Google\Chrome\Application\chrome.exe","$env:LocalAppData\Google\Chrome\Application\chrome.exe"))"

Write-Host ""
Write-Host "Done. Report saved to $report"
Write-Host "Please send that file back."
Stop-Transcript | Out-Null
