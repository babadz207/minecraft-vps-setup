param(
    [string[]]$InstanceNames = @(),
    [string]$InstanceName = "",
    [string]$ServerAddress = "donutsmp.net",
    [int]$RestartDelaySeconds = 10
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $ScriptDir) { $ScriptDir = (Get-Location).Path }

$possiblePaths = @(
    (Join-Path $ScriptDir "PrismLauncher\prismlauncher.exe"),
    (Join-Path $ScriptDir "MinecraftVPS\PrismLauncher\prismlauncher.exe"),
    "C:\MinecraftVPS\PrismLauncher\prismlauncher.exe"
)

$PrismExe = $null
foreach ($p in $possiblePaths) {
    if (Test-Path $p) {
        $PrismExe = $p
        break
    }
}

if (-not $PrismExe) {
    Write-Host "[!] Prism Launcher khong tim thay tai: $PrismExe" -ForegroundColor Red
    Write-Host "Vui long chay setup-vps.ps1 truoc!" -ForegroundColor Yellow
    exit
}

$PrismDir = Split-Path -Parent $PrismExe

# Xu ly danh sach InstanceNames
if ($InstanceName -and $InstanceNames.Count -eq 0) {
    $InstanceNames = @($InstanceName)
}
if ($InstanceNames.Count -eq 1 -and $InstanceNames[0] -like "*,*") {
    $InstanceNames = $InstanceNames[0].Split(',') | ForEach-Object { $_.Trim() }
}
if ($InstanceNames.Count -eq 0) {
    $instancesDir = Join-Path $PrismDir "instances"
    if (Test-Path $instancesDir) {
        $found = Get-ChildItem -Path $instancesDir -Directory -ErrorAction SilentlyContinue | Where-Object {
            Test-Path (Join-Path $_.FullName ".minecraft")
        }
        if ($found) {
            $InstanceNames = @($found | ForEach-Object { $_.Name })
        }
    }
}
if (-not $InstanceNames -or $InstanceNames.Count -eq 0) {
    $InstanceNames = @("VPS-AFK-1")
}

# Doc cau hinh so luong instance va delay tu instance_config.json
$baseDir = Split-Path -Parent $PrismDir
$instConfigFile = Join-Path $baseDir "instance_config.json"
$activeCount = $InstanceNames.Count
$launchDelaySeconds = 25

if (Test-Path $instConfigFile) {
    try {
        $c = Get-Content $instConfigFile -Raw | ConvertFrom-Json
        if ($c.active_count) { $activeCount = [int]$c.active_count }
        if ($c.launch_delay_seconds) { $launchDelaySeconds = [int]$c.launch_delay_seconds }
    } catch {}
}

if ($activeCount -gt 0 -and $InstanceNames.Count -gt $activeCount) {
    $InstanceNames = @($InstanceNames[0..($activeCount - 1)])
}

Clear-Host
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host "   MINECRAFT VPS WATCHDOG 24/7 - AUTO RECONNECT & ANTI-BAN GUARD" -ForegroundColor Yellow
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host "Danh sach Instance : $($InstanceNames -join ', ')" -ForegroundColor White
Write-Host "Server ket noi     : $ServerAddress" -ForegroundColor Green
Write-Host "Delay mo bot       : $launchDelaySeconds giay giua cac Instance (Chong tran RAM)" -ForegroundColor Yellow
Write-Host "Co che giam sat    : Moi Instance 1 Tai khoan, Canh rieng tung bot, Chong Ban" -ForegroundColor Cyan
Write-Host "Nhan Ctrl + C de dung Watchdog." -ForegroundColor DarkGray
Write-Host ""

# Kiem tra tai khoan Microsoft
$accountsFile = Join-Path $PrismDir "accounts.json"
$msaAccounts = @()
if (Test-Path $accountsFile) {
    try {
        $accJson = Get-Content $accountsFile -Raw | ConvertFrom-Json
        foreach ($acc in $accJson.accounts) {
            if ($acc.type -eq "MSA") {
                $msaAccounts += $acc.profile.name
            }
        }
    } catch {}
}

if ($msaAccounts.Count -eq 0) {
    Write-Host ""
    Write-Host "[!] CHUA TIM THAY TAI KHOAN MICROSOFT TRONG PRISM LAUNCHER!" -ForegroundColor Yellow
    Write-Host "Server $ServerAddress yeu cau tai khoan ban quyen Microsoft de tham gia." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Dang tu dong mo Prism Launcher de ban dang nhap..." -ForegroundColor Cyan
    Write-Host "Huong dan dang nhap nhanh:" -ForegroundColor White
    Write-Host "  1. Tren Prism Launcher, bam [Accounts] (goc tren phai) -> [Manage Accounts]" -ForegroundColor White
    Write-Host "  2. Bam [Add Microsoft] o cot phai" -ForegroundColor White
    Write-Host "  3. Bam [Open Page and Copy Code] -> Prism se tu dong copy ma va mo Edge/Chrome tren VPS" -ForegroundColor White
    Write-Host "  4. Nhan Ctrl + V tren Edge/Chrome de dan ma -> Dang nhap tai khoan Microsoft" -ForegroundColor White
    Write-Host "  5. Thay nick xuat hien trong Prism Launcher xong, quay lai day nhan Enter de bat dau AFK!" -ForegroundColor Green
    Write-Host ""
    Start-Process -FilePath $PrismExe
    Read-Host "Nhan [ENTER] sau khi ban da dang nhap Microsoft thanh cong"
} else {
    Write-Host "[OK] Tai khoan Microsoft da dang nhap: $($msaAccounts -join ', ')" -ForegroundColor Green
}

# Gan tai khoan rieng biet cho tung instance (Moi instance 1 account)
$instAccounts = @{}
for ($i = 0; $i -lt $InstanceNames.Count; $i++) {
    $iName = $InstanceNames[$i]
    if ($i -lt $msaAccounts.Count) {
        $instAccounts[$iName] = $msaAccounts[$i]
    } else {
        $instAccounts[$iName] = ""
    }
}

$trackers = @{}
foreach ($inst in $InstanceNames) {
    $logPath = Join-Path $PrismDir "instances\$inst\.minecraft\logs\latest.log"
    $trackers[$inst] = @{
        Name = $inst
        LogFile = $logPath
        LogPos = if (Test-Path $logPath) { (Get-Item $logPath).Length } else { 0 }
        ConsecutiveFails = 0
        SessionStart = [DateTime]::MinValue
        LastLaunch = [DateTime]::MinValue
    }
}

function Wait-AntiBanCoolDown([string]$inst, [int]$fails, [string]$reason) {
    $safeDelay = 25 + (Get-Random -Minimum 5 -Maximum 15)
    if ($fails -eq 2) {
        $safeDelay = 50 + (Get-Random -Minimum 5 -Maximum 15)
    } elseif ($fails -ge 3) {
        $safeDelay = 110 + (Get-Random -Minimum 10 -Maximum 25)
    }

    $now = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$now] [CHONG AUTO-BAN / ANTI-BAN GUARD] [$inst]" -ForegroundColor Yellow -NoNewline
    Write-Host " Ly do: $reason (Lien tiep: $fails lan)" -ForegroundColor White
    Write-Host "[$now] [$inst] -> Nghi $safeDelay giay de server giai phong session cu & tranh rate-limit..." -ForegroundColor Cyan

    $remaining = $safeDelay
    while ($remaining -gt 0) {
        $step = [math]::Min(5, $remaining)
        Start-Sleep -Seconds $step
        $remaining -= $step
        if ($remaining -gt 0) {
            Write-Host "    ...[$inst] con $remaining giay nua se mo lai..." -ForegroundColor DarkGray
        }
    }
    Write-Host "[$now] [OK] [$inst] San sang mo lai Minecraft!" -ForegroundColor Green
}

function Get-InstanceProcess([string]$inst) {
    $procs = Get-CimInstance Win32_Process -Filter "Name='javaw.exe' or Name='java.exe'" -ErrorAction SilentlyContinue
    if (-not $procs) { return $null }
    
    foreach ($p in $procs) {
        if ($p.CommandLine -and $p.CommandLine -like "*instances\$inst\*") {
            return $p
        }
    }
    if ($InstanceNames.Count -eq 1 -and $procs.Count -gt 0) {
        return $procs[0]
    }
    return $null
}

function Launch-Instance([string]$inst) {
    $now = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $accName = $instAccounts[$inst]
    $accDisplay = if ($accName) { "Tai khoan: $accName" } else { "Tai khoan: Mac dinh" }
    Write-Host "[$now] [$inst] Dang khoi chay Minecraft ($accDisplay) -> Server: $ServerAddress..." -ForegroundColor Green
    
    $prelaunchBat = Join-Path $baseDir "bin\prelaunch.bat"
    if (Test-Path $prelaunchBat) {
        try { Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$prelaunchBat`"" -WindowStyle Hidden -Wait } catch {}
    }

    $env:LP_NUM_THREADS = "2"
    
    $argList = "--launch `"$inst`" --server `"$ServerAddress`""
    if ($accName) {
        $argList += " --profile `"$accName`""
    }
    
    $proc = Start-Process -FilePath $PrismExe -ArgumentList $argList -PassThru
    $trackers[$inst].SessionStart = [DateTime]::Now
    $trackers[$inst].LastLaunch = [DateTime]::Now
    
    Write-Host "[$now] [$inst] Cho $launchDelaySeconds giay de bot on dinh RAM va vao server truoc khi tiep tuc..." -ForegroundColor Yellow
    Start-Sleep -Seconds $launchDelaySeconds
    
    if (Test-Path $trackers[$inst].LogFile) {
        $trackers[$inst].LogPos = (Get-Item $trackers[$inst].LogFile).Length
    }
}

# Khoi dong ban dau
foreach ($inst in $InstanceNames) {
    $p = Get-InstanceProcess $inst
    if (-not $p) {
        Launch-Instance $inst
    } else {
        $now = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Write-Host "[$now] [$inst] Minecraft da chay san (PID: $($p.ProcessId))." -ForegroundColor Green
    }
}

$dcTriggers = @(
    "Lost connection",
    "Disconnected from server",
    "Disconnected:",
    "Connection reset",
    "Connection refused",
    "Timed out",
    "Read timed out",
    "Connect timed out",
    "io.netty",
    "Internal Exception:",
    "SocketException",
    "ConnectException",
    "forcibly closed by the remote host",
    "Kicked by server",
    "Server closed",
    "closed connection",
    "Connecting too fast",
    "You are already connected",
    "Failed to verify username",
    "Invalid session"
)

Write-Host "[$([DateTime]::Now.ToString('yyyy-MM-dd HH:mm:ss'))] Watchdog bat dau giam sat 24/7 cho: $($InstanceNames -join ', ')..." -ForegroundColor Cyan

while ($true) {
    foreach ($inst in $InstanceNames) {
        $tracker = $trackers[$inst]
        $p = Get-InstanceProcess $inst
        
        if (-not $p) {
            if (([DateTime]::Now - $tracker.LastLaunch).TotalSeconds -gt 20) {
                $now = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                $tracker.ConsecutiveFails++
                Write-Host "[$now] [!] [$inst] Phat hien Minecraft bi dong hoac crash!" -ForegroundColor Red
                Wait-AntiBanCoolDown $inst $tracker.ConsecutiveFails "Minecraft bi crash hoac dong bat ngo"
                Launch-Instance $inst
            }
            continue
        }
        
        if (([DateTime]::Now - $tracker.SessionStart).TotalSeconds -gt 180 -and $tracker.ConsecutiveFails -gt 0) {
            $tracker.ConsecutiveFails = 0
        }
        
        try {
            $pObj = Get-Process -Id $p.ProcessId -ErrorAction SilentlyContinue
            if ($pObj -and $pObj.PriorityClass -ne [System.Diagnostics.ProcessPriorityClass]::BelowNormal) {
                $pObj.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::BelowNormal
            }
        } catch {}
        
        $logPath = $tracker.LogFile
        if (Test-Path $logPath) {
            try {
                $file = [System.IO.File]::Open($logPath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
                if ($file.Length -gt $tracker.LogPos) {
                    $file.Seek($tracker.LogPos, [System.IO.SeekOrigin]::Begin) | Out-Null
                    $reader = New-Object System.IO.StreamReader($file)
                    $newText = $reader.ReadToEnd()
                    $tracker.LogPos = $file.Position
                    $reader.Close()
                    $file.Close()
                    
                    $isDisconnected = $false
                    $matchedTrigger = ""
                    foreach ($trigger in $dcTriggers) {
                        if ($newText -like "*$trigger*") {
                            $isDisconnected = $true
                            $matchedTrigger = $trigger
                            break
                        }
                    }
                    
                    if ($isDisconnected) {
                        $now = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                        Write-Host "[$now] [!] [$inst] PHAT HIEN LOI MANG / NGAT KET NOI: $matchedTrigger" -ForegroundColor Red
                        Write-Host "[$now] [$inst] Cho 12 giay de kiem tra mod auto-reconnect co the tu ket noi lai..." -ForegroundColor Yellow
                        Start-Sleep -Seconds 12
                        
                        $reconnected = $false
                        try {
                            $file2 = [System.IO.File]::Open($logPath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
                            if ($file2.Length -gt $tracker.LogPos) {
                                $file2.Seek($tracker.LogPos, [System.IO.SeekOrigin]::Begin) | Out-Null
                                $reader2 = New-Object System.IO.StreamReader($file2)
                                $afterText = $reader2.ReadToEnd()
                                $tracker.LogPos = $file2.Position
                                $reader2.Close()
                                if ($afterText -like "*Connecting to*" -or $afterText -like "*Connected*" -or $afterText -like "*[CHAT]*") {
                                    $reconnected = $true
                                }
                            }
                            $file2.Close()
                        } catch {}
                        
                        if (-not $reconnected) {
                            $tracker.ConsecutiveFails++
                            Write-Host "[$now] [!] [$inst] Mod khong the tu phuc hoi loi socket mang." -ForegroundColor Red
                            Write-Host "[$now] [$inst] Dang DONG RIENG instance nay de giai phong socket va REOPEN..." -ForegroundColor Yellow
                            Stop-Process -Id $p.ProcessId -Force -ErrorAction SilentlyContinue
                            Start-Sleep -Seconds 3
                            Wait-AntiBanCoolDown $inst $tracker.ConsecutiveFails "Loi socket/mang - Reopen sach de tranh bi ban"
                            Launch-Instance $inst
                        } else {
                            Write-Host "[$now] [OK] [$inst] Mod da tu dong ket noi lai thanh cong!" -ForegroundColor Green
                        }
                    }
                } else {
                    $file.Close()
                }
            } catch {}
        }
    }
    Start-Sleep -Seconds 4
}
