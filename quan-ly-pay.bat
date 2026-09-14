@echo off
title Quan Ly Auto Pay (DonutSMP)
set "SCRIPT=C:\MinecraftVPS\quan-ly-pay.ps1"
if not exist "%SCRIPT%" set "SCRIPT=%~dp0quan-ly-pay.ps1"
powershell -ExecutionPolicy Bypass -WindowStyle Hidden -File "%SCRIPT%"
exit
