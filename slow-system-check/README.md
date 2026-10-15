# Slow System Check

Read-only Windows PowerShell script for the first pass when someone says "my system is very slow".
It gathers the usual suspects in one report: RAM pressure, top memory hogs, disk space, uptime,
Wi-Fi quality, latency, download speed, VPN and browser versions. Nothing is modified.

## Documents

- [CLIENT.md](CLIENT.md): send this to the client. What the check does and does not do, how to run and verify it.
- [DEPLOY.md](DEPLOY.md): for you. Pinned release, deployment options, field reference, record keeping.

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
(the current folder, or the home folder if that is not writable). The speed test downloads ~25 MB into memory and discards it.

A report is saved in the current folder as `system-report-<PC>-<date>.txt`. Ask the user to send it back.

## What it generates

One plain-text file, also printed to the screen:

The report is saved **in the folder the script is run from** (the current folder), on every OS:

| How it is run | Report location |
|---|---|
| Windows: double-click `simple-check.cmd` | Next to the `.cmd` file (also with "Run as administrator") |
| Windows: `powershell -File ...\simple-check.ps1` | The folder PowerShell is in, e.g. `C:\Users\<name>\` |
| macOS / Linux: `bash simple-check.sh` | The folder Terminal is in (`pwd`), e.g. `~/` |

File name: `system-report-<PC-NAME>-<yyyy-MM-dd_HHmm>.txt` (`system-report-<PC-NAME>-fallback.txt` for the `.cmd`
fallback). If the current folder is not writable, the report goes to the user's home folder instead.

The last lines on screen show the exact path, e.g. `Done. Report saved to C:\Users\User\system-report-LAPTOP-UFA3VOTQ-2026-10-08_1649.txt`.

Sample report (Windows; values from a real client run, shown in the current format):

```
Slow System Check v1.1 (read-only)
Run at       : 2026-10-08 16:49:37

--- COMPUTER ---
Model        : LENOVO 82JW
OS           : Microsoft Windows 11 Pro (build 26200)
CPU          : AMD Ryzen 7 5800H with Radeon Graphics (16 threads)
Memory       : 63.9 GB total, 13.1 GB free
Disk         : 637 GB free of 952 GB
Last restart : 2026-09-24 23:47:49

--- TOP 5 PROGRAMS BY MEMORY ---
Memory Compression              14727 MB
brave                           13278 MB
Code                             8107 MB
msedge                           5181 MB
svchost                          2455 MB

--- WI-FI ---
SSID : Elephant
Signal : 100%
Rate (Mbps) : 866.7

--- PING 8.8.8.8 (10 tries) ---
Packets: sent 10, received 10, lost 0%
Min/Avg/Max: 63/66/73 ms

--- DOWNLOAD SPEED ---
45 Mbps

--- VPN ---
VPN is CONNECTED:
  Local Area Connection

--- BROWSERS ---
Edge    : 154.0.4258.37
Firefox : 157.0.1
Chrome  : not installed
Brave   : not installed
```

Linux and macOS reports have exactly the same sections and labels.

## Deploy

Use the pinned, hash-checked commands in [DEPLOY.md](DEPLOY.md) (commit `4794caa`).
They download only the script, verify its SHA-256, then run it. Quick copy:

Windows (PowerShell):

```powershell
$sha = '4794caa342d092aa71d197a63b2d7d7cc6da81af'
$d   = Join-Path $env:TEMP 'slow-check'; New-Item -ItemType Directory -Force $d | Out-Null
$f   = Join-Path $d 'simple-check.ps1'
Invoke-WebRequest "https://raw.githubusercontent.com/karandaid/tools/$sha/slow-system-check/simple-check.ps1" -OutFile $f
if ((Get-FileHash $f -Algorithm SHA256).Hash -ne 'B8089D1AEE7A3232E8D9906020D851AC0D41982698B94D29F04921AD6820F771') { throw 'Hash mismatch - do not run' }
powershell.exe -NoProfile -ExecutionPolicy Bypass -File $f
```

macOS / Linux:

```bash
sha=4794caa342d092aa71d197a63b2d7d7cc6da81af
curl -fsSL "https://raw.githubusercontent.com/karandaid/tools/$sha/slow-system-check/simple-check.sh" -o /tmp/simple-check.sh
echo "c914be9768f34a62ed683a5de4e54bc27bb81d7ed7d3e45dc28b4f62c131253a  /tmp/simple-check.sh" | shasum -a 256 -c - && bash /tmp/simple-check.sh
```

(On Linux without `shasum`, use `sha256sum -c -`.)

## Reading the report

Every line of the report is explained in [DEPLOY.md, section 7](DEPLOY.md#what-each-line-means). Quick red flags:

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
