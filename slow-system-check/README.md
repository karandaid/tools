# Slow System Check

Read-only Windows PowerShell script for the first pass when someone says "my system is very slow".
It gathers the usual suspects in one report: RAM pressure, top memory hogs, disk space, uptime,
Wi-Fi quality, latency, download speed, VPN and browser versions. Nothing is modified.

## Which file for which OS

| OS | File | Run |
|---|---|---|
| Windows (PowerShell) | `simple-check.ps1` | `powershell.exe -ExecutionPolicy Bypass -File .\simple-check.ps1` |
| Windows (double-click / cmd) | `simple-check.cmd` | Runs the `.ps1` next to it; falls back to built-in tools if PowerShell is blocked |
| Linux and macOS | `simple-check.sh` | `bash simple-check.sh` |

All three are **read-only** and produce the **same report**: identical sections, labels and order
(COMPUTER, TOP 5 PROGRAMS BY MEMORY, WI-FI, PING, DOWNLOAD SPEED, VPN, BROWSERS), so results from any OS compare directly.
The `.cmd` fallback (used only when PowerShell is blocked) keeps the headings but gives raw tool output.

Read-only means: no admin rights, no settings, registry, service or software changes. The only file written is the report
(Desktop, or home folder). The speed test downloads ~25 MB into memory and discards it.

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

Linux / macOS:

```bash
curl -fsSL https://raw.githubusercontent.com/karandaid/tools/main/slow-system-check/simple-check.sh -o /tmp/simple-check.sh
bash /tmp/simple-check.sh
rm /tmp/simple-check.sh
```

Windows without knowing which shell: send `simple-check.cmd` and `simple-check.ps1` together in one folder and have them double-click the `.cmd`.

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
