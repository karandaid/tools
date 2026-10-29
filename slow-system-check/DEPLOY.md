# Slow System Check: Deployment and Assurance Guide

Author: Karandeep Singh (karandaid@gmail.com)

This guide covers how to hand the check to a client, how to make sure they run exactly the code
that was published, and how to show afterwards that no client data was taken.

**Quick reference**

| Client's OS | What to send | Report appears |
|---|---|---|
| Windows | The PowerShell block in section 3 | In the folder PowerShell is open in (usually `C:\Users\<name>`) |
| Windows, no internet / scripts blocked | `simple-check.ps1` + `simple-check.cmd` (section 3, offline) | Next to the two files |
| macOS / Linux | The Terminal block in section 4 | In the folder Terminal is open in (usually `~`) |
| Unknown | Sections 3 and 4 both; the client uses the one for their OS | as above |

**Send the client `CLIENT.md`, not this file.** It is written for them and their IT team. This guide
is for you and includes internal notes (section 8).

## 1. What the check does and does not do

**Reads:** computer model, OS version, CPU, RAM, free disk space, last restart time, the names and
memory use of the 5 biggest programs, Wi-Fi name/signal/speed, ping time to 8.8.8.8, download speed,
whether a VPN adapter is up, installed browser versions.

**Never touches:** documents, files, email, passwords, browser history or cookies, screenshots,
keystrokes, clipboard, user accounts, network shares, or any other machine.

**Writes:** one plain-text report in the folder the script is run from (the user's home folder if that
folder is not writable). Nothing else on disk, no registry,
service, setting or software change. No admin rights needed.

**Consent:** before reading anything, the script shows what it will and will not do and waits for the
client to press Enter. Closing the window at that point cancels it with nothing read or written.

**Network:** two outbound requests only, a ping to 8.8.8.8 and a ~25 MB download from
`speed.cloudflare.com` (discarded in memory). **Nothing is uploaded and nothing is sent to the
author automatically.** The client reads the report and chooses to send the file back.

**Personal details that do appear in the report:** computer name (in the file name), Wi-Fi name
(SSID) and program names. Tell the client they can open the file and remove any line before sending.

## 2. Pinned release (exact commit, not the whole repo)

| Item | Value |
|---|---|
| Repository | https://github.com/karandaid/tools |
| Commit | `4794caa342d092aa71d197a63b2d7d7cc6da81af` |
| Path | `slow-system-check/` |

SHA-256 of each file at that commit:

```
b8089d1aee7a3232e8d9906020d851ac0d41982698b94d29f04921ad6820f771  simple-check.ps1
e7de37fe80a4dc239d23ba983aee296330e0661842b66962422f21c10d0733e1  simple-check.cmd
c914be9768f34a62ed683a5de4e54bc27bb81d7ed7d3e45dc28b4f62c131253a  simple-check.sh
```

If a hash does not match, do not run the file. Always use the full 40-character commit, never a
branch name, so the code cannot change after you send the instructions.

## 3. Deploying: Windows

Paste into a normal (non-admin) PowerShell window. It downloads only the script at the pinned commit,
checks its hash, then runs it. The report is saved in the folder PowerShell is open in. To put it
somewhere specific, run `cd <folder>` first, e.g. `cd $HOME\Desktop`.

```powershell
$sha  = '4794caa342d092aa71d197a63b2d7d7cc6da81af'
$hash = 'B8089D1AEE7A3232E8D9906020D851AC0D41982698B94D29F04921AD6820F771'
$base = 'https://raw.githubusercontent.com/karandaid/tools'
$d    = Join-Path $env:TEMP 'slow-check'
$f    = Join-Path $d 'simple-check.ps1'
New-Item -ItemType Directory -Force $d | Out-Null
Invoke-WebRequest "$base/$sha/slow-system-check/simple-check.ps1" -OutFile $f
if ((Get-FileHash $f).Hash -ne $hash) { throw 'Hash mismatch - do not run' }
powershell.exe -NoProfile -ExecutionPolicy Bypass -File $f
```

Offline or locked-down PC: email `simple-check.ps1` and `simple-check.cmd` together and ask the client to
put them in one folder. Before running, they check both hashes against section 2 from a Command Prompt
in that folder:

```
certutil -hashfile simple-check.ps1 SHA256
certutil -hashfile simple-check.cmd SHA256
```

Then they double-click `simple-check.cmd`. The report is saved next to the two files, also with
"Run as administrator". If PowerShell is blocked, the `.cmd` writes a basic fallback report
(`system-report-<PC-NAME>-fallback.txt`) with the same headings.

## 4. Deploying: Linux and macOS

Paste into Terminal. The report is saved in the folder Terminal is in (`pwd`); `cd` somewhere else
first to change that.

```bash
sha=4794caa342d092aa71d197a63b2d7d7cc6da81af
sum=c914be9768f34a62ed683a5de4e54bc27bb81d7ed7d3e45dc28b4f62c131253a
base=https://raw.githubusercontent.com/karandaid/tools
curl -fsSL "$base/$sha/slow-system-check/simple-check.sh" -o /tmp/simple-check.sh
echo "$sum  /tmp/simple-check.sh" | shasum -a 256 -c - &&
  bash /tmp/simple-check.sh
```

(On Linux `sha256sum -c -` replaces `shasum -a 256 -c -`.)

## 5. If you need the repo itself: fetch only that commit

Do not `git clone` (that downloads all history and all branches). Fetch one commit, no history:

```bash
git init slow-check && cd slow-check
git remote add origin https://github.com/karandaid/tools.git
git fetch --depth 1 origin 4794caa342d092aa71d197a63b2d7d7cc6da81af
git checkout FETCH_HEAD
git rev-parse HEAD     # must print 4794caa342d092aa71d197a63b2d7d7cc6da81af
```

Then run from the folder where you want the report:

```powershell
# Windows
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\slow-system-check\simple-check.ps1
```
```bash
# Linux / macOS
bash slow-system-check/simple-check.sh
```

Verified: this downloads about 210 KB and produces the same file hashes as listed above.
The repo sets `-text` in `.gitattributes`, so Windows git will not change line endings and the hashes hold.

## 6. Clean up after the run

```powershell
Remove-Item "$env:TEMP\slow-check" -Recurse -Force      # Windows
```
```bash
rm -f /tmp/simple-check.sh                              # Linux / macOS
```

The report stays in the folder the script was run from (for the commands above, the folder PowerShell or
Terminal was in, usually `C:\Users\<name>` or `~`). It is not deleted by the clean-up.

## 7. What the client sends back

One text file, `system-report-<PC-NAME>-<yyyy-MM-dd_HHmm>.txt`. The last line on screen shows the exact
path, e.g. `Done. Report saved to C:\Users\User\system-report-LAPTOP-UFA3VOTQ-2026-10-08_1649.txt`.
If the current folder is not writable, it is saved in the user's home folder instead.

Every OS produces the same sections in the same order. The first line names the version, so a report
can always be matched to the exact code:

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
...

--- WI-FI ---            SSID, Signal, Rate (Mbps)
--- PING 8.8.8.8 (10 tries) ---   packets sent/received/lost, min/avg/max ms
--- DOWNLOAD SPEED ---   Mbps
--- VPN ---              connected adapter names, or "No VPN detected"
--- BROWSERS ---         Edge, Firefox, Chrome, Brave versions
```

The full sample is in `README.md`.

### What each line means

`Slow System Check v1.1` and `Run at` identify the script version and when it ran.

Each value below says what it is, where the script reads it on each OS, and how to judge it. The
thresholds are rules of thumb, not hard limits.

**COMPUTER**

| Line | Meaning | Read from (Windows / macOS / Linux) | What to look for |
|---|---|---|---|
| Model | Maker and model of the machine | `Win32_ComputerSystem` / `sysctl hw.model` / `/sys/devices/virtual/dmi/id` | Lets you look up the hardware's specs and age. Shows `unknown` in some VMs |
| OS | Operating system name and build number (on Linux, the kernel version) | `Win32_OperatingSystem` / `sw_vers` / `/etc/os-release`, `uname -r` | Out-of-support or very old builds |
| CPU | Processor name and number of threads (logical cores) | `Win32_Processor` / `sysctl machdep.cpu` / `/proc/cpuinfo`, `nproc` | A low-end or old CPU for the workload |
| Memory | Total RAM, and RAM still available for programs | `Win32_OperatingSystem` / `vm_stat` (free + inactive + speculative) / `MemAvailable` in `/proc/meminfo` | Under about 15% free means memory pressure: the PC slows as it compresses memory and swaps to disk |
| Disk | Free and total space on the system drive (`C:` on Windows, `/` on macOS and Linux) | `Win32_LogicalDisk` / `df` / `df` | Under about 10% free slows updates, swapping and temporary files |
| Last restart | When the machine last booted | `LastBootUpTime` / `kern.boottime` / `uptime -s` | More than about a week: restart first. On Windows, "Shut down" with Fast Startup does not reset this; only "Restart" does |

**TOP 5 PROGRAMS BY MEMORY**

The five programs using the most RAM right now, in MB. All processes with the same name are added
together, so one line covers every tab and helper of a browser. Read from: Windows `Get-Process`
(working set), macOS and Linux `ps` (resident memory). Only program names and memory figures are read,
not window titles, command lines or what the program has open.

- **Memory Compression** (Windows only) is RAM that Windows has compressed to make room. Several GB
  here means the PC is short of memory.
- Browsers (brave, msedge, chrome, firefox) using many GB usually means too many tabs or extensions.
- Because shared memory is counted once per process, totals for multi-process apps can read slightly high.

**WI-FI**

| Line | Meaning | What to look for |
|---|---|---|
| SSID | Name of the connected Wi-Fi network | Confirms which network was tested. Recent macOS versions may show `<redacted>` without Location permission |
| Signal | Signal strength, 0 to 100% (on macOS, converted from dBm) | Under about 60% means weak signal: move closer or use cable |
| Rate (Mbps) | Link speed between the device and the router, not the internet speed (Windows: receive rate) | Far below the plan's speed points to the Wi-Fi, not the internet |

Shows `Not on Wi-Fi (wired or none)` on cable. Read from: Windows `netsh wlan show interfaces`, macOS
`airport` or `system_profiler`, Linux `nmcli`.

**PING 8.8.8.8 (10 tries)**

Ten pings to Google's public DNS server. `Packets` shows how many were sent and received and the
percentage lost; `Min/Avg/Max` is the round-trip time in milliseconds.

- Any loss, or a large gap between Min and Max, points to an unstable connection.
- Average under about 30 ms is good, 30 to 100 ms is acceptable, over 100 ms feels slow. VPNs add latency.
- Some company networks block ping; then 100% loss does not mean the internet is down.

**DOWNLOAD SPEED**

Time to download a 25 MB test file from `speed.cloudflare.com`, in megabits per second. The data is
discarded, not saved. It is a single download, so it can read lower than a full speed test. Compare it
with the internet plan, and with the VPN off if one is connected.

**VPN**

`VPN is CONNECTED:` followed by the adapter names, or `No VPN detected`. Read from: Windows network
adapters that are up and look like a VPN (TAP, TUN, WireGuard, Cisco, Fortinet, Palo Alto and similar),
macOS connected VPN services (`scutil --nc list`), Linux `tun`, `tap`, `wg`, `ppp`, `tailscale` and
`nordlynx` interfaces. A VPN routes all traffic through another server, which often lowers speed and
raises ping. Some third-party VPN apps on macOS are not listed by `scutil`.

**BROWSERS**

Installed version of Edge, Firefox, Chrome and Brave, or `not installed`. Read from the program file's
version (Windows), the app's `Info.plist` (macOS) or `--version` (Linux). Nothing inside the browser is
read: no history, tabs, passwords or extensions. Outdated versions can be slower and are a security risk.

## 8. Protecting yourself against a false data-theft claim

This is practical guidance, not legal advice. For anything contractual, have a lawyer review it.

1. **Written authorization first.** Before sending anything, get an email from an authorized person
   at the company saying you may diagnose the slowness, that the client runs the check themselves, and
   what you will receive back. Suggested wording:
   > "We authorize Karandeep Singh to review the system report produced by the diagnostic script
   > (version commit 4794caa) run by our staff. The script is read-only and does not copy our data.
   > Karandeep Singh will receive only the report file we choose to send."
2. **They run it, not you.** No remote desktop, no credentials, no admin access. Then you never
   touched their systems.
3. **Send the pinned commit and hashes** (sections 2 to 4) in the same email. This proves what code
   was given and lets their IT audit it. Each script is about 45 to 130 lines of readable text.
4. **Offer an audit path.** Their IT can read the script, or run it in a throwaway VM, or watch outbound
   traffic. They will see only the ping and the Cloudflare speed-test download.
5. **Receive only the report.** Accept the single `.txt` file. Do not accept screenshots of their
   screens, exports, logs with business data, or file shares. If they send more, tell them in writing
   that it was not requested and delete it.
6. **Keep a record.** Save the authorization email, the message that sent the instructions, the report
   as received, and the date you deleted it.
7. **Delete when done.** Delete the report after the engagement (or per the contract), and confirm
   deletion in writing.
8. **Sign if they want it.** If they ask for an NDA, sign it. The report content is already limited to
   system performance facts.

## 9. Reading the report

See `README.md` for the red flags per section and a worked example.
