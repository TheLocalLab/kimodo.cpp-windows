@echo off
REM Double-click launcher for kimodo.cpp (calls the PowerShell launcher, keeps window open).
REM Usage: Launch-Kimodo.bat [generate args pass through to the .ps1]
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Launch-Kimodo.ps1" %*
if errorlevel 1 (
  echo.
  echo FAILED - see error above.
  pause
  exit /b 1
)
echo.
pause
