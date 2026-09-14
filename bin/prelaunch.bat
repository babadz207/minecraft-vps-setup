@echo off
setlocal
set "BIN_DIR=%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%BIN_DIR%sync-configs.ps1"
endlocal
exit /b 0
