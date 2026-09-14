@echo off
chcp 65001 >nul
title Auto Check Connect 24-7 - donutsmp.net
cd /d "%~dp0"
set "SCRIPT=C:\MinecraftVPS\watchdog-ui.ps1"
if not exist "%SCRIPT%" set "SCRIPT=%~dp0watchdog-ui.ps1"
powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%SCRIPT%"
exit
