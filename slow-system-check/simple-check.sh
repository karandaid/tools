#!/usr/bin/env bash
# Quick, read-only health check for a slow Linux or macOS machine.
# Writes a plain-text report to ~/Desktop (or $HOME) and prints it.
#
# Author: Karandeep Singh <karandaid@gmail.com>
# Run:    bash simple-check.sh
set -u
OS="$(uname -s)"
HOST="$(hostname)"
OUTDIR="$HOME/Desktop"; [ -d "$OUTDIR" ] || OUTDIR="$HOME"
REPORT="$OUTDIR/system-report-$HOST-$(date +%Y-%m-%d_%H%M).txt"

have() { command -v "$1" >/dev/null 2>&1; }

report() {
  echo "--- COMPUTER ---"
  if [ "$OS" = "Darwin" ]; then
    echo "Model        : $(sysctl -n hw.model)"
    echo "OS           : $(sw_vers -productName) $(sw_vers -productVersion) (build $(sw_vers -buildVersion))"
    echo "CPU          : $(sysctl -n machdep.cpu.brand_string 2>/dev/null || uname -m)"
    total=$(sysctl -n hw.memsize)
    pagesz=$(sysctl -n hw.pagesize)
    free_pages=$(vm_stat | awk '/Pages (free|inactive|speculative)/ {gsub("\\.","",$NF); s+=$NF} END{print s+0}')
    awk -v t="$total" -v f="$((free_pages*pagesz))" 'BEGIN{printf "Memory       : %.1f GB total, %.1f GB free/reclaimable\n", t/2^30, f/2^30}'
    echo "Last restart : $(sysctl -n kern.boottime | sed -E 's/.*= ([^}]*)\}.*/\1/' | xargs -I{} date -r {} 2>/dev/null)"
  else
    echo "Model        : $(cat /sys/devices/virtual/dmi/id/product_name 2>/dev/null || echo unknown)"
    echo "OS           : $(. /etc/os-release 2>/dev/null; echo "${PRETTY_NAME:-$(uname -sr)}") (kernel $(uname -r))"
    echo "CPU          : $(awk -F: '/model name/ {gsub(/^ +/,"",$2); print $2; exit}' /proc/cpuinfo) ($(nproc) threads)"
    awk '/MemTotal/ {t=$2} /MemAvailable/ {a=$2} /SwapTotal/ {st=$2} /SwapFree/ {sf=$2}
         END{printf "Memory       : %.1f GB total, %.1f GB available\nSwap         : %.1f GB used of %.1f GB\n", t/2^20, a/2^20, (st-sf)/2^20, st/2^20}' /proc/meminfo
    echo "Last restart : $(uptime -s 2>/dev/null || who -b | awk '{print $3, $4}')"
  fi
  df -h / | awk 'NR==2 {printf "Disk /       : %s free of %s (%s used)\n", $4, $2, $5}'
  echo "Load average: $(uptime | sed -E 's/.*load averages?: //')"

  echo
  echo "--- TOP 5 PROGRAMS BY MEMORY ---"
  if [ "$OS" = "Darwin" ]; then
    ps -axo rss=,comm= | awk '{rss=$1; $1=""; n=split($0,p,"/"); name=p[n]; sub(/^ +/,"",name); m[name]+=rss} END{for(k in m) printf "%-28s %8.0f MB\n", k, m[k]/1024}' | sort -rn -k2 | head -5
  else
    ps -eo rss=,comm= | awk '{rss=$1; $1=""; sub(/^ +/,"",$0); m[$0]+=rss} END{for(k in m) printf "%-28s %8.0f MB\n", k, m[k]/1024}' | sort -rn -k2 | head -5
  fi
  echo
  echo "--- TOP 5 PROGRAMS BY CPU (right now) ---"
  ps -axo pcpu=,comm= | sort -rn | head -5

  echo
  echo "--- WI-FI ---"
  if [ "$OS" = "Darwin" ]; then
    /System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -I 2>/dev/null \
      | grep -E ' SSID|lastTxRate|agrCtlRSSI|channel' || echo "No Wi-Fi info available (wired, or airport tool removed)"
  elif have nmcli; then
    nmcli -t -f ACTIVE,SSID,RATE,SIGNAL dev wifi 2>/dev/null | grep '^yes' | awk -F: '{print "SSID : "$2"\nRate : "$3"\nSignal : "$4"%"}' | grep . || echo "Not on Wi-Fi (wired or none)"
  elif have iwconfig; then
    iwconfig 2>/dev/null | grep -E 'ESSID|Bit Rate|Signal'
  else
    echo "No Wi-Fi tool found"
  fi

  echo
  echo "--- PING GOOGLE DNS (10 tries) ---"
  ping -c 10 8.8.8.8 2>&1 | tail -2

  echo
  echo "--- DOWNLOAD SPEED ---"
  if have curl; then
    curl -s -o /dev/null -m 60 -w '%{speed_download}' 'https://speed.cloudflare.com/__down?bytes=25000000' \
      | awk '{printf "%.0f Mbps\n", $1*8/1000000}'
  else
    echo "curl not installed"
  fi

  echo
  echo "--- VPN ---"
  if [ "$OS" = "Darwin" ]; then
    vpn=$(ifconfig 2>/dev/null | grep -E '^(utun|ppp|ipsec)[0-9]*:' | cut -d: -f1 | tr '\n' ' ')
    scutil --nc list 2>/dev/null | grep -i Connected
  else
    vpn=$(ip -o link show up 2>/dev/null | awk -F': ' '{print $2}' | grep -E '^(tun|tap|wg|ppp|tailscale|nordlynx)' | tr '\n' ' ')
  fi
  if [ -n "${vpn:-}" ]; then echo "VPN interface(s) up: $vpn"; else echo "No VPN detected"; fi

  echo
  echo "--- BROWSERS ---"
  ver() { "$@" 2>/dev/null | head -1 || true; }
  if [ "$OS" = "Darwin" ]; then
    for a in "Google Chrome" "Microsoft Edge" "Firefox" "Brave Browser" "Safari"; do
      p="/Applications/$a.app/Contents/Info.plist"
      [ -f "$p" ] && echo "$a : $(defaults read "${p%.plist}" CFBundleShortVersionString)" || echo "$a : not installed"
    done
  else
    for b in google-chrome chromium microsoft-edge firefox brave-browser; do
      have "$b" && echo "$b : $(ver "$b" --version)" || echo "$b : not installed"
    done
  fi
}

report 2>&1 | tee "$REPORT"
echo
echo "Done. Report saved to $REPORT"
echo "Please send that file back."
