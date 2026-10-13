# Slow System Check: Deployment and Assurance Guide

Author: Karandeep Singh (karandaid@gmail.com)

This guide covers how to hand the check to a client, how to make sure they run exactly the code
that was published, and how to show afterwards that no client data was taken.

## 1. What the check does and does not do

**Reads:** computer model, OS version, CPU, RAM, free disk space, last restart time, the names and
memory use of the 5 biggest programs, Wi-Fi name/signal/speed, ping time to 8.8.8.8, download speed,
whether a VPN adapter is up, installed browser versions.

**Never touches:** documents, files, email, passwords, browser history or cookies, screenshots,
keystrokes, clipboard, user accounts, network shares, or any other machine.

**Writes:** one plain-text report on the Desktop (or home folder). Nothing else on disk, no registry,
service, setting or software change. No admin rights needed.

**Network:** two outbound requests only, a ping to 8.8.8.8 and a ~25 MB download from
`speed.cloudflare.com` (discarded in memory). **Nothing is uploaded and nothing is sent to the
author automatically.** The client reads the report and chooses to send the file back.

**Personal details that do appear in the report:** computer name (in the file name), Wi-Fi name
(SSID) and program names. Tell the client they can open the file and remove any line before sending.

## 2. Pinned release (exact commit, not the whole repo)

| Item | Value |
|---|---|
| Repository | https://github.com/karandaid/tools |
| Commit | `9579796c771e1dc94ccf4e3eba5e2158b813b93c` |
| Path | `slow-system-check/` |

SHA-256 of each file at that commit:

```
6ed186c7748c0740470affc061c3188f43c815bfa8fcf410eb420ac41673d02f  simple-check.ps1   (Windows, PowerShell)
3b9548aff0470ac5b630d304ada2a9efe9ec88d911581083b1aeac4e54f102e1  simple-check.cmd   (Windows launcher)
a8e535c39e52eda31a682e92146e2f7694a3530b1b5686ab4c1b9dd38393b118  simple-check.sh    (Linux / macOS)
```

If a hash does not match, do not run the file. Always use the full 40-character commit, never a
branch name, so the code cannot change after you send the instructions.

## 3. Deploying: Windows

Paste into a normal (non-admin) PowerShell window. It downloads only the script at the pinned commit,
checks its hash, then runs it.

```powershell
$sha = '9579796c771e1dc94ccf4e3eba5e2158b813b93c'
$d   = Join-Path $env:TEMP 'slow-check'; New-Item -ItemType Directory -Force $d | Out-Null
$f   = Join-Path $d 'simple-check.ps1'
Invoke-WebRequest "https://raw.githubusercontent.com/karandaid/tools/$sha/slow-system-check/simple-check.ps1" -OutFile $f
if ((Get-FileHash $f -Algorithm SHA256).Hash -ne '6ED186C7748C0740470AFFC061C3188F43C815BFA8FCF410EB420AC41673D02F') { throw 'Hash mismatch - do not run' }
powershell.exe -NoProfile -ExecutionPolicy Bypass -File $f
```

Offline or locked-down PC: email `simple-check.ps1` and `simple-check.cmd` together, ask the client to
check the hash with `Get-FileHash .\simple-check.ps1` (or `certutil -hashfile simple-check.ps1 SHA256`),
then double-click `simple-check.cmd`.

## 4. Deploying: Linux and macOS

```bash
sha=9579796c771e1dc94ccf4e3eba5e2158b813b93c
curl -fsSL "https://raw.githubusercontent.com/karandaid/tools/$sha/slow-system-check/simple-check.sh" -o /tmp/simple-check.sh
echo "a8e535c39e52eda31a682e92146e2f7694a3530b1b5686ab4c1b9dd38393b118  /tmp/simple-check.sh" | shasum -a 256 -c - || exit 1
bash /tmp/simple-check.sh
```

(On Linux `sha256sum -c -` replaces `shasum -a 256 -c -`.)

## 5. If you need the repo itself: fetch only that commit

Do not `git clone` (that downloads all history and all branches). Fetch one commit, no history:

```bash
git init slow-check && cd slow-check
git remote add origin https://github.com/karandaid/tools.git
git fetch --depth 1 origin 9579796c771e1dc94ccf4e3eba5e2158b813b93c
git checkout FETCH_HEAD
git rev-parse HEAD     # must print 9579796c771e1dc94ccf4e3eba5e2158b813b93c
```

Verified: this downloads about 200 KB and produces the same file hashes as listed above.
The repo sets `-text` in `.gitattributes`, so Windows git will not change line endings and the hashes hold.

## 6. Clean up after the run

```powershell
Remove-Item "$env:TEMP\slow-check" -Recurse -Force      # Windows
```
```bash
rm -f /tmp/simple-check.sh                              # Linux / macOS
```

The report stays on the Desktop until the client deletes it.

## 7. Protecting yourself against a false data-theft claim

This is practical guidance, not legal advice. For anything contractual, have a lawyer review it.

1. **Written authorization first.** Before sending anything, get an email from an authorized person
   at the company saying you may diagnose the slowness, that the client runs the check themselves, and
   what you will receive back. Suggested wording:
   > "We authorize Karandeep Singh to review the system report produced by the diagnostic script
   > (version commit 9579796) run by our staff. The script is read-only and does not copy our data.
   > He will receive only the report file we choose to send."
2. **They run it, not you.** No remote desktop, no credentials, no admin access. Then you never
   touched their systems.
3. **Send the pinned commit and hashes** (sections 2 to 4) in the same email. This proves what code
   was given and lets their IT audit it. The script is about 100 lines of readable text.
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

## 8. Reading the report

See `README.md` for the red flags per section and a worked example.
