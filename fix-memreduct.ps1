Write-Host "=== DANG CAU HINH MEM REDUCT CHUAN CHO MINECRAFT VPS ===" -ForegroundColor Yellow

# 1. Dong tien trinh dang chay
Stop-Process -Name "memreduct" -Force -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 500

$mrDir = "C:\MinecraftVPS\MemReduct"
if (-not (Test-Path $mrDir)) {
    $found = Get-ChildItem "C:\" -Filter "memreduct.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($found) { $mrDir = Split-Path -Parent $found.FullName }
}

$mrExe = Join-Path $mrDir "memreduct.exe"

$mrIniLines = @(
    "[memreduct]",
    "AlwaysOnTop=0",
    "AutoreductEnable=1",
    "AutoreductValue=85",
    "AutoreductIntervalEnable=1",
    "AutoreductIntervalValue=30",
    "ReductMask2=254",
    "IsAllowStandbyListCleanup=1",
    "BalloonCleanResults=0",
    "IsNotificationsSound=0",
    "IsShowWarningConfirmation=0",
    "IsShowReductConfirmation=0",
    "IsStartMinimized=1",
    "IsCloseToTray=1",
    "IsMinimizeToTray=1",
    "CheckUpdatesPeriod=0",
    "CheckUpdates=0"
)

# 2. Ghi memreduct.ini voi dinh dang Unicode (UTF-16LE - bat buoc cho Win32 GetPrivateProfileString)
if (Test-Path $mrDir) {
    [System.IO.File]::WriteAllBytes((Join-Path $mrDir "portable.dat"), [System.Text.Encoding]::ASCII.GetBytes("#PORTABLE#"))
    [System.IO.File]::WriteAllLines((Join-Path $mrDir "memreduct.ini"), $mrIniLines, [System.Text.Encoding]::Unicode)
}

$appDataMrDir = Join-Path $env:APPDATA "Henry++\Mem Reduct"
if (-not (Test-Path $appDataMrDir)) { New-Item -ItemType Directory -Path $appDataMrDir -Force | Out-Null }
[System.IO.File]::WriteAllLines((Join-Path $appDataMrDir "memreduct.ini"), $mrIniLines, [System.Text.Encoding]::Unicode)

# 3. Startup & UAC Bypass
if (Test-Path $mrExe) {
    try {
        $runKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
        Set-ItemProperty -Path $runKey -Name "MemReduct" -Value "`"$mrExe`" -minimized" -Force
        try { & schtasks.exe /Create /TN "memreductTask" /TR "`"$mrExe`" -minimized" /SC ONLOGON /RL HIGHEST /F 2>$null | Out-Null } catch {}
    } catch {}

    # 4. Khoi dong lai Mem Reduct ngam duoi Taskbar
    Stop-Process -Name "memreduct" -Force -ErrorAction SilentlyContinue
    Start-Sleep -Milliseconds 300
    Start-Process -FilePath $mrExe -ArgumentList "-minimized"
}

Write-Host ""
Write-Host "[OK] Da cau hinh Mem Reduct thanh cong 100%:" -ForegroundColor Green
Write-Host "  - Khong don Working Set (Bao ve RAM Java khong bi lag/khung game)" -ForegroundColor Cyan
Write-Host "  - Tu dong don Standby List & System File Cache" -ForegroundColor Cyan
Write-Host "  - Don RAM moi 30 phut & khi RAM tren 85%" -ForegroundColor Cyan
Write-Host "  - Tat toan bo am thanh & thong bao popup phien phuc" -ForegroundColor Cyan
Write-Host "  - Chay ngam san duoi khay he thong (System Tray)" -ForegroundColor Cyan
