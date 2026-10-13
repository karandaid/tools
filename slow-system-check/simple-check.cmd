@echo off
rem Windows launcher: double-click or run from cmd.exe.
rem Runs simple-check.ps1 (same folder) without changing the execution policy system-wide.
rem If PowerShell is blocked, falls back to built-in cmd tools.
rem Author: Karandeep Singh <karandaid@gmail.com>

set "HERE=%~dp0"
if exist "%HERE%simple-check.ps1" (
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%HERE%simple-check.ps1"
  if not errorlevel 1 goto :eof
)

echo PowerShell run failed or script missing - using basic fallback.
set "OUT=%USERPROFILE%\Desktop\system-report-%COMPUTERNAME%.txt"
(
  echo --- COMPUTER ---
  systeminfo | findstr /B /C:"OS Name" /C:"OS Version" /C:"System Model" /C:"Total Physical Memory" /C:"Available Physical Memory" /C:"System Boot Time"
  echo.
  echo --- DISK ---
  fsutil volume diskfree C:
  echo.
  echo --- TOP PROCESSES (tasklist, largest memory last column) ---
  tasklist /FO TABLE
  echo.
  echo --- WI-FI ---
  netsh wlan show interfaces
  echo.
  echo --- PING GOOGLE DNS ---
  ping -n 10 8.8.8.8
) > "%OUT%" 2>&1
echo Done. Report saved to %OUT%
echo Please send that file back.
pause
