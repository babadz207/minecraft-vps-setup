@echo off
chcp 65001 >nul
title Mem Reduct
cd /d "%~dp0"
if exist "MinecraftVPS\MemReduct\memreduct.exe" (
    cd /d "%~dp0\MinecraftVPS\MemReduct"
) else if exist "MemReduct\memreduct.exe" (
    cd /d "%~dp0\MemReduct"
)
start "" memreduct.exe -minimized
exit
