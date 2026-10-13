@echo off
rem Windows launcher (double-click or cmd.exe). Runs simple-check.ps1 from the same folder.
rem Read-only: changes no settings. If PowerShell is blocked, falls back to built-in tools
rem (same section headings, less detail). Only the report file is written.
rem Author: Karandeep Singh <karandaid@gmail.com>

set "HERE=%~dp0"
if exist "%HERE%simple-check.ps1" (
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%HERE%simple-check.ps1"
  if not errorlevel 1 goto :done
)

echo PowerShell unavailable - using basic fallback.
set "OUT=%USERPROFILE%\Desktop\system-report-%COMPUTERNAME%-fallback.txt"
(
  echo --- COMPUTER ---
  systeminfo | findstr /B /C:"System Manufacturer" /C:"System Model" /C:"OS Name" /C:"OS Version" /C:"Total Physical Memory" /C:"Available Physical Memory" /C:"System Boot Time"
  fsutil volume diskfree C:
  echo.
  echo --- TOP 5 PROGRAMS BY MEMORY ---
  echo (see full list below; sort by the Mem Usage column)
  tasklist /FO TABLE
  echo.
  echo --- WI-FI ---
  netsh wlan show interfaces
  echo.
  echo --- PING 8.8.8.8 (10 tries) ---
  ping -n 10 8.8.8.8
  echo.
  echo --- VPN ---
  ipconfig | findstr /I "TAP Wintun WireGuard VPN"
  echo.
  echo --- BROWSERS ---
  echo Not collected in fallback mode.
) > "%OUT%" 2>&1
echo Done. Report saved to %OUT%
echo Please send that file back.
:done
pause
