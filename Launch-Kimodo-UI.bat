@echo off
REM Launches the kimodo.cpp demo web UI at http://127.0.0.1:8094
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Launch-Kimodo.ps1" -Mode demo %*
if errorlevel 1 (
  echo.
  echo FAILED - see error above. Install Go from https://go.dev/dl/ if missing.
  pause
  exit /b 1
)
pause
