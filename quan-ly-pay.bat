@echo off
if exist "C:\MinecraftVPS\bin\AutoPayManager.exe" (
    start "" "C:\MinecraftVPS\bin\AutoPayManager.exe"
    exit /b 0
)
if exist "%~dp0bin\AutoPayManager.exe" (
    start "" "%~dp0bin\AutoPayManager.exe"
    exit /b 0
)
set "SCRIPT=C:\MinecraftVPS\quan-ly-pay.ps1"
if not exist "%SCRIPT%" set "SCRIPT=%~dp0quan-ly-pay.ps1"
powershell -ExecutionPolicy Bypass -WindowStyle Hidden -File "%SCRIPT%"
exit /b 0
