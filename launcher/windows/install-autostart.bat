@echo off
echo This optional script adds a shortcut to your Windows Startup folder.
echo Close this window to cancel. Press a key only if you want auto-start.
pause >nul
powershell -NoProfile -File "%~dp0install-autostart.ps1"
if errorlevel 1 echo Auto-start was not confirmed. Open index.html directly instead.
pause
