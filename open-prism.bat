@echo off
title Prism Launcher
set "APP_DIR=C:\MinecraftVPS\PrismLauncher"
if not exist "%APP_DIR%" set "APP_DIR=%~dp0\PrismLauncher"
if not exist "%APP_DIR%" set "APP_DIR=%~dp0\MinecraftVPS\PrismLauncher"
cd /d "%APP_DIR%"
start "" prismlauncher.exe
exit
