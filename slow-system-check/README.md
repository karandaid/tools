# Slow System Check

Read-only Windows PowerShell script for the first pass when someone says "my system is very slow".
It gathers the usual suspects in one report: RAM pressure, top memory hogs, disk space, uptime,
Wi-Fi quality, latency, download speed, VPN and browser versions. Nothing is modified.

## Usage

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\simple-check.ps1
```

A report is saved to the Desktop as `system-report-<PC>-<date>.txt`. Ask the user to send it back.

## Deploy

Send the client one of these (they paste it into a normal, non-admin PowerShell window):

```powershell
# Option 1: download and run from the repo (public repo)
$d = "$env:TEMP\slow-check"; New-Item -ItemType Directory -Force $d | Out-Null
iwr https://raw.githubusercontent.com/karandaid/tools/main/slow-system-check/simple-check.ps1 -OutFile "$d\simple-check.ps1"
powershell.exe -ExecutionPolicy Bypass -File "$d\simple-check.ps1"

# Option 2: from a clone
git clone https://github.com/karandaid/tools.git
cd tools\slow-system-check
powershell.exe -ExecutionPolicy Bypass -File .\simple-check.ps1
```

Or email/chat them `simple-check.ps1` and have them right-click, then Run with PowerShell
(or use the `-ExecutionPolicy Bypass` command in Usage above). The script takes about 30 seconds.

Clean up afterwards:

```powershell
Remove-Item "$env:TEMP\slow-check" -Recurse -Force
```

## Reading the report

| Section | Red flag |
|---|---|
| Memory | Low free RAM, or "Memory Compression" in the top programs list using many GB |
| Top 5 programs | Browsers/IDEs holding many GB (too many tabs/extensions) |
| Last restart | Weeks of uptime (pending updates, leaks) |
| Disk C: | Under ~10% free |
| Wi-Fi / Ping / Download | Weak signal, loss, ping spikes, low Mbps |
| VPN | Connected VPN can add latency and cut throughput |
| Browsers | Outdated versions |

## Example finding (from a real run)

63.9 GB RAM with only 13.1 GB free, Memory Compression at ~14.7 GB, Brave ~13 GB, VS Code ~8 GB,
Edge ~5 GB and 15+ days since last restart: memory pressure, not the network. Wi-Fi and ping were fine
(66 ms avg, 0% loss); download was 45 Mbps with an OpenVPN adapter connected.

## Author

Karandeep Singh — karandaid@gmail.com
