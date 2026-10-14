<#
.SYNOPSIS
    Read-only health check for a slow Windows PC. Same report layout as simple-check.sh.

.DESCRIPTION
    Reads system info, top 5 programs by memory, Wi-Fi, ping, download speed, VPN and browsers.
    Changes nothing: no registry, services, settings or installs; no admin rights needed.
    The only file written is the report, in the current folder. The speed test downloads ~25 MB to memory.

.NOTES
    Author : Karandeep Singh <karandaid@gmail.com>
    Run    : powershell.exe -ExecutionPolicy Bypass -File .\simple-check.ps1
#>

$ErrorActionPreference = 'SilentlyContinue'
$lines = New-Object System.Collections.Generic.List[string]
function Say([string]$t = '') { $lines.Add($t); Write-Host $t }

Say '--- COMPUTER ---'
$cs  = Get-CimInstance Win32_ComputerSystem
$os  = Get-CimInstance Win32_OperatingSystem
$cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
$dsk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
Say ("Model        : {0} {1}" -f $cs.Manufacturer, $cs.Model)
Say ("OS           : {0} (build {1})" -f $os.Caption, $os.BuildNumber)
Say ("CPU          : {0} ({1} threads)" -f $cpu.Name, $cs.NumberOfLogicalProcessors)
Say ("Memory       : {0:N1} GB total, {1:N1} GB free" -f ($cs.TotalPhysicalMemory/1GB), ($os.FreePhysicalMemory/1MB))
Say ("Disk         : {0:N0} GB free of {1:N0} GB" -f ($dsk.FreeSpace/1GB), ($dsk.Size/1GB))
Say ("Last restart : {0}" -f $os.LastBootUpTime.ToString('yyyy-MM-dd HH:mm:ss'))

Say ''
Say '--- TOP 5 PROGRAMS BY MEMORY ---'
Get-Process | Group-Object ProcessName |
    ForEach-Object { [pscustomobject]@{ n = $_.Name; mb = [math]::Round(($_.Group | Measure-Object WorkingSet64 -Sum).Sum/1MB) } } |
    Sort-Object mb -Descending | Select-Object -First 5 |
    ForEach-Object { Say ("{0,-28} {1,8} MB" -f $_.n, $_.mb) }

Say ''
Say '--- WI-FI ---'
$w = netsh wlan show interfaces 2>$null
function Wf($k) { ($w | Select-String "^\s*$k\s*:" | Select-Object -First 1 | ForEach-Object { ($_.Line -split ':',2)[1].Trim() }) }
if ($w -and (Wf 'SSID')) {
    Say ("SSID : {0}" -f (Wf 'SSID'))
    Say ("Signal : {0}" -f (Wf 'Signal'))
    Say ("Rate (Mbps) : {0}" -f (Wf 'Receive rate \(Mbps\)'))
} else { Say 'Not on Wi-Fi (wired or none)' }

Say ''
Say '--- PING 8.8.8.8 (10 tries) ---'
$p = New-Object System.Net.NetworkInformation.Ping
$rt = @(); for ($i = 0; $i -lt 10; $i++) { $r = $p.Send('8.8.8.8', 2000); if ($r.Status -eq 'Success') { $rt += $r.RoundtripTime } }
Say ("Packets: sent 10, received {0}, lost {1}%" -f $rt.Count, ((10 - $rt.Count) * 10))
if ($rt.Count) { $m = $rt | Measure-Object -Min -Max -Average; Say ("Min/Avg/Max: {0}/{1}/{2} ms" -f $m.Minimum, [math]::Round($m.Average), $m.Maximum) }

Say ''
Say '--- DOWNLOAD SPEED ---'
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $sw = [Diagnostics.Stopwatch]::StartNew()
    $n  = (New-Object Net.WebClient).DownloadData('https://speed.cloudflare.com/__down?bytes=25000000').Length
    Say ("{0:N0} Mbps" -f (($n * 8) / 1e6 / $sw.Elapsed.TotalSeconds))
} catch { Say 'Could not measure download speed' }

Say ''
Say '--- VPN ---'
$vpn = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' -and $_.InterfaceDescription -match 'TAP|TUN|WireGuard|VPN|Wintun|Cisco|Fortinet|Palo Alto' }
if ($vpn) { Say 'VPN is CONNECTED:'; $vpn | ForEach-Object { Say ("  {0}" -f $_.Name) } } else { Say 'No VPN detected' }

Say ''
Say '--- BROWSERS ---'
function Ver($paths) { foreach ($x in $paths) { if (Test-Path $x) { return (Get-Item $x).VersionInfo.ProductVersion } } 'not installed' }
$a = $env:ProgramFiles; $b = ${env:ProgramFiles(x86)}; $c = $env:LocalAppData
Say ("Edge    : {0}" -f (Ver @("$b\Microsoft\Edge\Application\msedge.exe","$a\Microsoft\Edge\Application\msedge.exe")))
Say ("Firefox : {0}" -f (Ver @("$a\Mozilla Firefox\firefox.exe","$b\Mozilla Firefox\firefox.exe")))
Say ("Chrome  : {0}" -f (Ver @("$a\Google\Chrome\Application\chrome.exe","$b\Google\Chrome\Application\chrome.exe","$c\Google\Chrome\Application\chrome.exe")))
Say ("Brave   : {0}" -f (Ver @("$a\BraveSoftware\Brave-Browser\Application\brave.exe","$c\BraveSoftware\Brave-Browser\Application\brave.exe")))

# Save in the folder the script is run from; fall back to the user's home folder if it is not writable
$name   = "system-report-{0}-{1}.txt" -f $env:COMPUTERNAME, (Get-Date -Format 'yyyy-MM-dd_HHmm')
$report = Join-Path (Get-Location).ProviderPath $name
try { $lines | Set-Content -Path $report -Encoding UTF8 -ErrorAction Stop }
catch { $report = Join-Path $HOME $name; $lines | Set-Content -Path $report -Encoding UTF8 }
Write-Host ''
Write-Host "Done. Report saved to $report"
Write-Host 'Please send that file back.'
