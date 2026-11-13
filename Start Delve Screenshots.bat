@echo off
title Delve screenshot helper (keep this open while you play)
set "HELPER=%~dp0delve_webhook_helper.ps1"
if not exist "%HELPER%" (
  echo delve_webhook_helper.ps1 must be in the same folder as this file.
  pause
  exit /b 1
)
echo.
echo   1 = Discord screenshots and pings only (default)
echo   2 = also keep a local recording: saves the last 5 s and the next 2 s on hits,
echo       deaths and F8, with the matching logs, to DelveCaptures in the Volt workspace
echo.
choice /c 12 /t 8 /d 1 /m "Mode (1 is picked in 8 s)"
if errorlevel 2 goto capture
powershell -NoProfile -ExecutionPolicy Bypass -File "%HELPER%"
goto done
:capture
title Delve helper + recorder (keep this open while you play)
powershell -NoProfile -ExecutionPolicy Bypass -File "%HELPER%" -Capture
:done
pause
