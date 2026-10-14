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

**Writes:** one plain-text report in the folder the script is run from (the user's home folder if that
folder is not writable). Nothing else on disk, no registry,
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
| Commit | `1bc42994fb83e8b8ff50968e6aa53281109bc58a` |
| Path | `slow-system-check/` |

SHA-256 of each file at that commit:

```
8f720364ad1ea380ef8de0f507c6eeea94f27d36b067436bd656c0aa78c5c2c2  simple-check.ps1   (Windows, PowerShell)
c5ea82e672a5fbdb25a37980034ca3e59d6a637cab9a260933e061ffbb1185b4  simple-check.cmd   (Windows launcher)
653848bbe80efcb154c053c671478036e050ee26a1be1a291bb62d6ba175417e  simple-check.sh    (Linux / macOS)
```

If a hash does not match, do not run the file. Always use the full 40-character commit, never a
branch name, so the code cannot change after you send the instructions.

## 3. Deploying: Windows

Paste into a normal (non-admin) PowerShell window. It downloads only the script at the pinned commit,
checks its hash, then runs it.

```powershell
$sha = '1bc42994fb83e8b8ff50968e6aa53281109bc58a'
$d   = Join-Path $env:TEMP 'slow-check'; New-Item -ItemType Directory -Force $d | Out-Null
$f   = Join-Path $d 'simple-check.ps1'
Invoke-WebRequest "https://raw.githubusercontent.com/karandaid/tools/$sha/slow-system-check/simple-check.ps1" -OutFile $f
if ((Get-FileHash $f -Algorithm SHA256).Hash -ne '8F720364AD1EA380EF8DE0F507C6EEEA94F27D36B067436BD656C0AA78C5C2C2') { throw 'Hash mismatch - do not run' }
powershell.exe -NoProfile -ExecutionPolicy Bypass -File $f
```

Offline or locked-down PC: email `simple-check.ps1` and `simple-check.cmd` together, ask the client to
check the hash with `Get-FileHash .\simple-check.ps1` (or `certutil -hashfile simple-check.ps1 SHA256`),
then double-click `simple-check.cmd`. The report is saved next to the two files.

## 4. Deploying: Linux and macOS

```bash
sha=1bc42994fb83e8b8ff50968e6aa53281109bc58a
curl -fsSL "https://raw.githubusercontent.com/karandaid/tools/$sha/slow-system-check/simple-check.sh" -o /tmp/simple-check.sh
echo "653848bbe80efcb154c053c671478036e050ee26a1be1a291bb62d6ba175417e  /tmp/simple-check.sh" | shasum -a 256 -c - || exit 1
bash /tmp/simple-check.sh
```

(On Linux `sha256sum -c -` replaces `shasum -a 256 -c -`.)

## 5. If you need the repo itself: fetch only that commit

Do not `git clone` (that downloads all history and all branches). Fetch one commit, no history:

```bash
git init slow-check && cd slow-check
git remote add origin https://github.com/karandaid/tools.git
git fetch --depth 1 origin 1bc42994fb83e8b8ff50968e6aa53281109bc58a
git checkout FETCH_HEAD
git rev-parse HEAD     # must print 1bc42994fb83e8b8ff50968e6aa53281109bc58a
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

The report stays in the folder the script was run from (for the commands above, the folder PowerShell or
Terminal was in, usually `C:\Users\<name>` or `~`). It is not deleted by the clean-up.

## 7. Protecting yourself against a false data-theft claim

This is practical guidance, not legal advice. For anything contractual, have a lawyer review it.

1. **Written authorization first.** Before sending anything, get an email from an authorized person
   at the company saying you may diagnose the slowness, that the client runs the check themselves, and
   what you will receive back. Suggested wording:
   > "We authorize Karandeep Singh to review the system report produced by the diagnostic script
   > (version commit 1bc4299) run by our staff. The script is read-only and does not copy our data.
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
