# Slow System Check

**Information for your team**

From: Karandeep Singh (karandaid@gmail.com)

Thank you for letting me look into why your computer is slow. Before changing anything, I need a
few basic facts about the machine. This page explains the small check I'm asking you to run: what it
does, what it does not do, and how you or your IT team can verify that before running it.

## In short

- **You run it yourself.** I don't need remote access, passwords or admin rights.
- **It only reads.** It changes no settings, installs nothing and deletes nothing.
- **It sends nothing.** It saves one text file on your computer. You open it, check it, and decide
  whether to send it to me.
- **It asks first.** It shows what it will do and waits for you to press Enter. Closing the window at
  that point cancels it with nothing read.
- **It takes about 30 seconds.**

## What it reads

| Section | What it shows |
|---|---|
| Computer | Model, operating system, processor, memory (total and free), free disk space, last restart time |
| Top 5 programs by memory | Names of the 5 programs using the most memory, and how much |
| Wi-Fi | Network name, signal strength, connection speed to the router |
| Ping | Response time to Google's public DNS server (8.8.8.8), 10 tries |
| Download speed | Time to download a 25 MB test file from Cloudflare. The file is discarded, not saved |
| VPN | Whether a VPN connection is active |
| Browsers | Installed versions of Edge, Firefox, Chrome and Brave |

## What it does NOT read or do

- No documents, files, email, chats or photos
- No passwords, browser history, cookies, tabs or extensions
- No screenshots, keystrokes or clipboard
- No usernames, other computers or network shares
- No uploads: the only network activity is the ping and the Cloudflare speed test above
- No changes to settings, registry, services or installed software

## How to run it

The commands below download one fixed version of the script, check its fingerprint (SHA-256 hash),
and run it only if the fingerprint matches. The report is saved in the folder the window is open in;
the last line on screen shows the exact path.

**Windows:** open PowerShell (Start menu, type "PowerShell", no need for "Run as administrator") and paste:

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

**Mac or Linux:** open Terminal and paste:

```bash
sha=4794caa342d092aa71d197a63b2d7d7cc6da81af
sum=c914be9768f34a62ed683a5de4e54bc27bb81d7ed7d3e45dc28b4f62c131253a
base=https://raw.githubusercontent.com/karandaid/tools
curl -fsSL "$base/$sha/slow-system-check/simple-check.sh" -o /tmp/simple-check.sh
echo "$sum  /tmp/simple-check.sh" | shasum -a 256 -c - &&
  bash /tmp/simple-check.sh
```

(`-ExecutionPolicy Bypass` only applies to this one run. It does not change your computer's settings.)

If your computer can't download files, I can email you the script instead. Check its fingerprint
with the values below before running it.

## How your IT team can verify it

1. **Read the code.** It is short (about 45 to 130 lines) and plain text. This exact version:
   - Windows: https://github.com/karandaid/tools/blob/4794caa342d092aa71d197a63b2d7d7cc6da81af/slow-system-check/simple-check.ps1
   - Mac/Linux: https://github.com/karandaid/tools/blob/4794caa342d092aa71d197a63b2d7d7cc6da81af/slow-system-check/simple-check.sh
   - Windows launcher: https://github.com/karandaid/tools/blob/4794caa342d092aa71d197a63b2d7d7cc6da81af/slow-system-check/simple-check.cmd
2. **Check the fingerprints.** These SHA-256 values identify this version exactly. If one byte
   changes, the value changes.

   ```
   b8089d1aee7a3232e8d9906020d851ac0d41982698b94d29f04921ad6820f771  simple-check.ps1
   e7de37fe80a4dc239d23ba983aee296330e0661842b66962422f21c10d0733e1  simple-check.cmd
   c914be9768f34a62ed683a5de4e54bc27bb81d7ed7d3e45dc28b4f62c131253a  simple-check.sh
   ```
   Windows: `Get-FileHash <file>` or `certutil -hashfile <file> SHA256`. Mac: `shasum -a 256 <file>`.
   Linux: `sha256sum <file>`.
3. **Test it first** on a spare or virtual machine if you prefer.
4. **Watch the network** while it runs. You will see only a ping to 8.8.8.8 and a download from
   speed.cloudflare.com.

## Before you send the report

Open the text file and read it. It is short. It contains the computer name (in the file name), the
Wi-Fi network name and the names of the top 5 programs. You are welcome to remove or blank out any line
before sending. Please send only that file: no screenshots, documents or other files are needed.

## Afterwards

- To remove the downloaded script: Windows `Remove-Item "$env:TEMP\slow-check" -Recurse -Force`,
  Mac/Linux `rm -f /tmp/simple-check.sh`. The report stays where it was saved until you delete it.
- I use the report only to diagnose this issue and will delete it when we're done. I'll confirm the
  deletion in writing on request.

## Questions

Email karandaid@gmail.com. I'm happy to walk your IT team through the code before you run it.
