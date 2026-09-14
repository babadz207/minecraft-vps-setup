@echo off
chcp 65001 >nul
title Huong Dan Dang Nhap Microsoft - Prism Launcher
set "APP_DIR=C:\MinecraftVPS\PrismLauncher"
if not exist "%APP_DIR%" set "APP_DIR=%~dp0\PrismLauncher"
cd /d "%APP_DIR%"
cls
echo ===============================================================================
echo   HUONG DAN DANG NHAP MICROSOFT DE VAO SERVER DONUTSMP.NET (CHI LAM 1 LAN)
echo ===============================================================================
echo.
echo Server donutsmp.net yeu cau tai khoan ban quyen Minecraft (Microsoft).
echo.
echo Buoc 1: Giao dien Prism Launcher dang duoc mo len.
echo Buoc 2: Nhin goc tren ben phai cua Prism Launcher, bam [Accounts] -^> [Manage Accounts].
echo Buoc 3: Bam nut [Add Microsoft] o cot ben phai.
echo Buoc 4: Bam nut [Open Page and Copy Code] tren hop thoai Prism Launcher.
echo         -^> Prism Launcher se TU DONG sao chep ma Code va tu mo trinh duyet
echo            Microsoft Edge hoac Chrome ngay tren man hinh VPS!
echo Buoc 5: Tren Edge / Chrome vua mo ra trang https://microsoft.com/link:
echo         -^> Nhan to hop phim [Ctrl + V] de dan ma Code vao -^> Bam Tiep tuc.
echo         -^> Dang nhap tai khoan Microsoft so huu game Minecraft cua ban va xac nhan.
echo Buoc 6: Nick Minecraft cua ban se lap tuc xuat hien trong danh sach Accounts.
echo.
echo (Ghi chu: Neu thich, ban cung co the vao link tren dien thoai/may tinh ca nhan deu duoc).
echo.
echo Sau khi dang nhap xong, ban chi can chay [Auto Restart 24-7 (Watchdog).bat] de treo bot!
echo ===============================================================================
echo.
start "" prismlauncher.exe
pause
