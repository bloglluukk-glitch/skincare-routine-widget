@echo off
powershell -NoProfile -File "%~dp0skincare-widget.ps1"
if errorlevel 1 (
  echo Launcher blocked or failed. Open index.html directly; do not disable security protections.
  pause
)
