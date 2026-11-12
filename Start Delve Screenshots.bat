@echo off
title Delve screenshot helper (keep this open while you play)
set "HELPER=%~dp0delve_webhook_helper.ps1"
if not exist "%HELPER%" (
  echo delve_webhook_helper.ps1 must be in the same folder as this file.
  pause
  exit /b 1
)
powershell -NoProfile -ExecutionPolicy Bypass -File "%HELPER%"
pause
