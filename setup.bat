@echo off
chcp 65001 >nul
title Auto Setup Minecraft VPS Non-GPU (Fabric 1.21.11 + Prism Launcher)
cd /d "%~dp0"

echo ===============================================================================
echo   DANG KHOI CHAY AUTO SETUP MINECRAFT VPS NON-GPU
echo ===============================================================================
echo.
echo Dang goi PowerShell voi quyen Bypass ExecutionPolicy...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup-vps.ps1"

echo.
echo Nhan phim bat ky de thoat...
pause >nul
