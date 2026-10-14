#!/usr/bin/env bash
# Read-only health check for a slow Linux or macOS machine. Same report layout as simple-check.ps1.
# Changes nothing on the system; the only file written is the report, in the current folder.
#
# Author: Karandeep Singh <karandaid@gmail.com>
# Run:    bash simple-check.sh
set -u
OS="$(uname -s)"
HOST="$(hostname)"
# Save in the folder the script is run from; fall back to $HOME if it is not writable
OUTDIR="$PWD"; [ -w "$OUTDIR" ] || OUTDIR="$HOME"
REPORT="$OUTDIR/system-report-$HOST-$(date +%Y-%m-%d_%H%M).txt"

have() { command -v "$1" >/dev/null 2>&1; }

report() {
  echo "--- COMPUTER ---"
  if [ "$OS" = "Darwin" ]; then
    echo "Model        : $(sysctl -n hw.model)"
    echo "OS           : $(sw_vers -productName) $(sw_vers -productVersion) (build $(sw_vers -buildVersion))"
    echo "CPU          : $(sysctl -n machdep.cpu.brand_string 2>/dev/null || uname -m) ($(sysctl -n hw.logicalcpu) threads)"
    total=$(sysctl -n hw.memsize); pagesz=$(sysctl -n hw.pagesize)
    free_pages=$(vm_stat | awk '/Pages (free|inactive|speculative)/ {gsub("\\.","",$NF); s+=$NF} END{print s+0}')
    awk -v t="$total" -v f="$((free_pages*pagesz))" 'BEGIN{printf "Memory       : %.1f GB total, %.1f GB free\n", t/2^30, f/2^30}'
    boot=$(sysctl -n kern.boottime | sed -E 's/.*sec = ([0-9]+).*/\1/')
    restart=$(date -r "$boot" '+%Y-%m-%d %H:%M:%S')
  else
    model="$(cat /sys/devices/virtual/dmi/id/sys_vendor 2>/dev/null) $(cat /sys/devices/virtual/dmi/id/product_name 2>/dev/null)"
    echo "Model        : $(echo "$model" | awk 'NF {print; f=1} END{if(!f) print "unknown"}')"
    echo "OS           : $(. /etc/os-release 2>/dev/null; echo "${PRETTY_NAME:-$(uname -s)}") (build $(uname -r))"
    echo "CPU          : $(awk -F: '/model name/ {gsub(/^ +/,"",$2); print $2; exit}' /proc/cpuinfo) ($(nproc) threads)"
    awk '/MemTotal/ {t=$2} /MemAvailable/ {a=$2} END{printf "Memory       : %.1f GB total, %.1f GB free\n", t/2^20, a/2^20}' /proc/meminfo
    restart=$(uptime -s 2>/dev/null)
  fi
  df -Pk / | awk 'NR==2 {printf "Disk         : %.0f GB free of %.0f GB\n", $4/2^20, $2/2^20}'
  echo "Last restart : $restart"

  echo
  echo "--- TOP 5 PROGRAMS BY MEMORY ---"
  ps -axo rss=,comm= | awk '{rss=$1; $1=""; sub(/^ +/,"",$0); n=split($0,p,"/"); m[p[n]]+=rss} END{for(k in m) printf "%d\t%s\n", m[k]/1024, k}' \
    | sort -rn | head -5 | awk -F'\t' '{printf "%-28s %8d MB\n", $2, $1}'

  echo
  echo "--- WI-FI ---"
  wifi=""
  if [ "$OS" = "Darwin" ]; then
    a=/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport
    if [ -x "$a" ] && "$a" -I >/dev/null 2>&1; then
      i=$("$a" -I 2>/dev/null)
      ssid=$(echo "$i" | awk -F': ' '/ SSID/ {print $2}')
      [ -n "$ssid" ] && wifi="SSID : $ssid
Signal : $(echo "$i" | awk '/agrCtlRSSI/ {s=2*($2+100); if(s>100)s=100; if(s<0)s=0; print s"%"}')
Rate (Mbps) : $(echo "$i" | awk '/lastTxRate/ {print $2}')"
    else
      # macOS 14.4+: SSID may show as <redacted> without Location permission
      wifi=$(system_profiler SPAirPortDataType 2>/dev/null | awk '
        /Current Network Information:/ {getline; gsub(/^ +|:$/,""); ssid=$0; cur=1; next}
        cur && /Signal \/ Noise:/ {split($0,a,": "); split(a[2],b," "); s=2*(b[1]+100); if(s>100)s=100; if(s<0)s=0; sig=s"%"}
        cur && /Transmit Rate:/ {split($0,a,": "); rate=a[2]}
        cur && /Other Local Wi-Fi Networks:/ {cur=0}
        END{ if (ssid!="") printf "SSID : %s\nSignal : %s\nRate (Mbps) : %s\n", ssid, sig, rate }')
    fi
  elif have nmcli; then
    wifi=$(nmcli -t -f ACTIVE,SSID,RATE,SIGNAL dev wifi 2>/dev/null | awk -F: '$1=="yes" {split($3,r," "); print "SSID : "$2"\nSignal : "$4"%\nRate (Mbps) : "r[1]; exit}')
  fi
  if [ -n "$wifi" ]; then echo "$wifi"; else echo "Not on Wi-Fi (wired or none)"; fi

  echo
  echo "--- PING 8.8.8.8 (10 tries) ---"
  if have ping; then
    if [ "$OS" = "Darwin" ]; then w=2000; else w=2; fi
    out=$(ping -c 10 -W "$w" 8.8.8.8 2>&1 || true)
    echo "$out" | awk '/packets transmitted/ {gsub(/[,%]/,""); printf "Packets: sent %d, received %d, lost %d%%\n", $1, $4, ($1-$4)*100/$1}'
    echo "$out" | awk -F'[/= ]+' '/min\/avg\/max/ {printf "Min/Avg/Max: %.0f/%.0f/%.0f ms\n", $(NF-4), $(NF-3), $(NF-2)}'
  else echo "ping not installed"; fi

  echo
  echo "--- DOWNLOAD SPEED ---"
  if have curl; then
    curl -s -o /dev/null -m 60 -w '%{speed_download}' 'https://speed.cloudflare.com/__down?bytes=25000000' \
      | awk '{ if ($1>0) printf "%.0f Mbps\n", $1*8/1000000; else print "Could not measure download speed" }'
  else echo "Could not measure download speed (curl not installed)"; fi

  echo
  echo "--- VPN ---"
  if [ "$OS" = "Darwin" ]; then
    vpn=$(scutil --nc list 2>/dev/null | grep '(Connected)' | sed -E 's/.*"([^"]*)".*/\1/')
  else
    vpn=$(ip -o link show up 2>/dev/null | awk -F': ' '{print $2}' | grep -E '^(tun|tap|wg|ppp|tailscale|nordlynx)')
  fi
  if [ -n "${vpn:-}" ]; then echo "VPN is CONNECTED:"; echo "$vpn" | while IFS= read -r v; do echo "  $v"; done; else echo "No VPN detected"; fi

  echo
  echo "--- BROWSERS ---"
  if [ "$OS" = "Darwin" ]; then
    macver() { p="/Applications/$2.app/Contents/Info.plist"; [ -f "$p" ] && v=$(defaults read "${p%.plist}" CFBundleShortVersionString) || v="not installed"; printf '%-8s: %s\n' "$1" "$v"; }
    macver Edge "Microsoft Edge"; macver Firefox Firefox; macver Chrome "Google Chrome"; macver Brave "Brave Browser"
  else
    lv() { v="not installed"; for c in "${@:2}"; do have "$c" && { v=$("$c" --version 2>/dev/null | head -1 | sed -E 's/[^0-9]*([0-9][0-9.]*).*/\1/'); break; }; done; printf '%-8s: %s\n' "$1" "$v"; }
    lv Edge microsoft-edge microsoft-edge-stable; lv Firefox firefox; lv Chrome google-chrome google-chrome-stable chromium; lv Brave brave-browser brave
  fi
}

report 2>&1 | tee "$REPORT"
echo
echo "Done. Report saved to $REPORT"
echo "Please send that file back."
