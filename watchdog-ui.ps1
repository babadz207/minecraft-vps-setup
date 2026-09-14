Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$BaseDir = "C:\MinecraftVPS"
if (-not (Test-Path $BaseDir)) {
    if ($MyInvocation.MyCommand.Path) {
        $BaseDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    } else {
        $BaseDir = (Get-Location).Path
    }
}

$PrismDir = Join-Path $BaseDir "PrismLauncher"
$PrismExe = Join-Path $PrismDir "prismlauncher.exe"
$instancesDir = Join-Path $PrismDir "instances"
$instConfigFile = Join-Path $BaseDir "instance_config.json"
$accountsFile = Join-Path $PrismDir "accounts.json"
$ServerAddress = "donutsmp.net"

# Doc danh sach tai khoan Microsoft tu accounts.json
$loggedAccounts = @()
if (Test-Path $accountsFile) {
    try {
        $accJson = Get-Content $accountsFile -Raw | ConvertFrom-Json
        foreach ($acc in $accJson.accounts) {
            if ($acc.profile -and $acc.profile.name) {
                $loggedAccounts += $acc.profile.name
            }
        }
    } catch {}
}

# Quet cac instance co san
$availableInstances = @()
if (Test-Path $instancesDir) {
    $availableInstances = @(Get-ChildItem -Path $instancesDir -Directory -ErrorAction SilentlyContinue | Where-Object { 
        Test-Path (Join-Path $_.FullName ".minecraft")
    } | Sort-Object Name)
}
if (-not $availableInstances -or $availableInstances.Count -eq 0) {
    $availableInstances = @([PSCustomObject]@{
        Name = "VPS-AFK-1"
        FullName = (Join-Path $instancesDir "VPS-AFK-1")
    })
}

# Doc cau hinh instance_config.json
$savedActiveCount = [math]::Min(3, $availableInstances.Count)
$savedDelaySeconds = 25
if (Test-Path $instConfigFile) {
    try {
        $cfgJson = Get-Content $instConfigFile -Raw | ConvertFrom-Json
        if ($cfgJson.active_count) { $savedActiveCount = [int]$cfgJson.active_count }
        if ($cfgJson.launch_delay_seconds) { $savedDelaySeconds = [int]$cfgJson.launch_delay_seconds }
    } catch {}
}

# ==============================================================================
# TAO GIAO DIEN WINFORMS (ULTRA LIGHTWEIGHT - NON-GPU VPS)
# ==============================================================================
$form = New-Object System.Windows.Forms.Form
$form.Text = "Quan Ly Auto Check Connect & Instances - donutsmp.net"
$form.Size = New-Object System.Drawing.Size(580, 680)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false
$form.BackColor = [System.Drawing.Color]::FromArgb(24, 24, 37) # Catppuccin Base

# Title Label
$titleLbl = New-Object System.Windows.Forms.Label
$titleLbl.Text = "TRUNG TÂM GIÁM SÁT & AUTO RECONNECT 24/7"
$titleLbl.Font = New-Object System.Drawing.Font("Segoe UI", 13, [System.Drawing.FontStyle]::Bold)
$titleLbl.ForeColor = [System.Drawing.Color]::FromArgb(137, 180, 250)
$titleLbl.Location = New-Object System.Drawing.Point(15, 12)
$titleLbl.Size = New-Object System.Drawing.Size(540, 26)
$titleLbl.TextAlign = "MiddleCenter"
$form.Controls.Add($titleLbl)

# Subtitle
$subLbl = New-Object System.Windows.Forms.Label
$subLbl.Text = "Server: donutsmp.net | Moi Instance 1 Tai khoan | Delay chong tran RAM"
$subLbl.Font = New-Object System.Drawing.Font("Segoe UI", 8.5)
$subLbl.ForeColor = [System.Drawing.Color]::FromArgb(166, 173, 200)
$subLbl.Location = New-Object System.Drawing.Point(15, 38)
$subLbl.Size = New-Object System.Drawing.Size(540, 18)
$subLbl.TextAlign = "MiddleCenter"
$form.Controls.Add($subLbl)

# Cards Container Panel
$cardsPanel = New-Object System.Windows.Forms.Panel
$cardsPanel.Location = New-Object System.Drawing.Point(20, 62)
$cardsPanel.Size = New-Object System.Drawing.Size(525, 220)
$cardsPanel.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 46)
$cardsPanel.BorderStyle = "FixedSingle"
$form.Controls.Add($cardsPanel)

$instControls = @{}
$cardTop = 10

for ($i = 0; $i -lt $availableInstances.Count; $i++) {
    $instObj = $availableInstances[$i]
    $instName = $instObj.Name
    $accName = if ($i -lt $loggedAccounts.Count) { $loggedAccounts[$i] } else { "(Chua dang nhap)" }
    $isChecked = ($i -lt $savedActiveCount)

    # Sub-card panel
    $card = New-Object System.Windows.Forms.Panel
    $card.Location = New-Object System.Drawing.Point(10, $cardTop)
    $card.Size = New-Object System.Drawing.Size(503, 60)
    $card.BackColor = [System.Drawing.Color]::FromArgb(49, 50, 68)
    $cardsPanel.Controls.Add($card)

    # Checkbox
    $cb = New-Object System.Windows.Forms.CheckBox
    $cb.Text = " $instName"
    $cb.Font = New-Object System.Drawing.Font("Segoe UI", 10.5, [System.Drawing.FontStyle]::Bold)
    $cb.ForeColor = [System.Drawing.Color]::White
    $cb.Checked = $isChecked
    $cb.Location = New-Object System.Drawing.Point(10, 8)
    $cb.Size = New-Object System.Drawing.Size(140, 24)
    $card.Controls.Add($cb)

    # Account Label
    $accLbl = New-Object System.Windows.Forms.Label
    $accLbl.Text = "Acc: $accName"
    $accLbl.Font = New-Object System.Drawing.Font("Consolas", 9)
    $accLbl.ForeColor = [System.Drawing.Color]::FromArgb(249, 226, 175)
    $accLbl.Location = New-Object System.Drawing.Point(12, 34)
    $accLbl.Size = New-Object System.Drawing.Size(180, 20)
    $card.Controls.Add($accLbl)

    # Status Badge
    $stBadge = New-Object System.Windows.Forms.Label
    $stBadge.Text = "○ ĐÃ DỪNG"
    $stBadge.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $stBadge.ForeColor = [System.Drawing.Color]::FromArgb(147, 153, 178)
    $stBadge.Location = New-Object System.Drawing.Point(195, 10)
    $stBadge.Size = New-Object System.Drawing.Size(200, 40)
    $card.Controls.Add($stBadge)

    # Mini single start/stop button
    $btnSingle = New-Object System.Windows.Forms.Button
    $btnSingle.Text = "Bật/Tắt"
    $btnSingle.Font = New-Object System.Drawing.Font("Segoe UI", 8.5)
    $btnSingle.Location = New-Object System.Drawing.Point(405, 14)
    $btnSingle.Size = New-Object System.Drawing.Size(85, 30)
    $btnSingle.BackColor = [System.Drawing.Color]::FromArgb(69, 71, 90)
    $btnSingle.ForeColor = [System.Drawing.Color]::White
    $btnSingle.FlatStyle = "Flat"
    $btnSingle.FlatAppearance.BorderSize = 0
    $card.Controls.Add($btnSingle)

    $instControls[$instName] = @{
        Name = $instName
        Account = $accName
        Checkbox = $cb
        Badge = $stBadge
        Button = $btnSingle
        LogFile = (Join-Path $instObj.FullName ".minecraft\logs\latest.log")
        LogPos = 0
        LastLaunch = [DateTime]::MinValue
        SessionStart = [DateTime]::MinValue
        ConsecutiveFails = 0
        IsRunning = $false
        ProcessId = $null
    }

    $cardTop += 68
}

# Settings Row (Delay & Auto status)
$settingsPanel = New-Object System.Windows.Forms.Panel
$settingsPanel.Location = New-Object System.Drawing.Point(20, 290)
$settingsPanel.Size = New-Object System.Drawing.Size(525, 45)
$settingsPanel.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 46)
$form.Controls.Add($settingsPanel)

$delayLbl = New-Object System.Windows.Forms.Label
$delayLbl.Text = "Delay mở bot (giây):"
$delayLbl.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$delayLbl.ForeColor = [System.Drawing.Color]::FromArgb(205, 214, 244)
$delayLbl.Location = New-Object System.Drawing.Point(10, 12)
$delayLbl.Size = New-Object System.Drawing.Size(130, 20)
$settingsPanel.Controls.Add($delayLbl)

$delayTxt = New-Object System.Windows.Forms.TextBox
$delayTxt.Text = "$savedDelaySeconds"
$delayTxt.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$delayTxt.Location = New-Object System.Drawing.Point(145, 10)
$delayTxt.Size = New-Object System.Drawing.Size(50, 26)
$delayTxt.BackColor = [System.Drawing.Color]::FromArgb(49, 50, 68)
$delayTxt.ForeColor = [System.Drawing.Color]::White
$delayTxt.BorderStyle = "FixedSingle"
$settingsPanel.Controls.Add($delayTxt)

$autoStatusLbl = New-Object System.Windows.Forms.Label
$autoStatusLbl.Text = "Chế độ Auto Check: ĐANG TẮT"
$autoStatusLbl.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$autoStatusLbl.ForeColor = [System.Drawing.Color]::FromArgb(243, 139, 168)
$autoStatusLbl.Location = New-Object System.Drawing.Point(220, 12)
$autoStatusLbl.Size = New-Object System.Drawing.Size(290, 20)
$autoStatusLbl.TextAlign = "MiddleRight"
$settingsPanel.Controls.Add($autoStatusLbl)

# Big Action Buttons
# Button 1: Start Auto Check Connect
$btnStartAuto = New-Object System.Windows.Forms.Button
$btnStartAuto.Text = "▶  BẮT ĐẦU AUTO CHECK CONNECT (24/7)"
$btnStartAuto.Font = New-Object System.Drawing.Font("Segoe UI", 10.5, [System.Drawing.FontStyle]::Bold)
$btnStartAuto.Location = New-Object System.Drawing.Point(20, 345)
$btnStartAuto.Size = New-Object System.Drawing.Size(525, 42)
$btnStartAuto.BackColor = [System.Drawing.Color]::FromArgb(46, 204, 113)
$btnStartAuto.ForeColor = [System.Drawing.Color]::FromArgb(17, 17, 27)
$btnStartAuto.FlatStyle = "Flat"
$btnStartAuto.FlatAppearance.BorderSize = 0
$btnStartAuto.Cursor = [System.Windows.Forms.Cursors]::Hand
$form.Controls.Add($btnStartAuto)

# Button 2: STOP ALL INSTANCES
$btnStopAll = New-Object System.Windows.Forms.Button
$btnStopAll.Text = "🛑  DỪNG TẤT CẢ INSTANCE (STOP ALL)"
$btnStopAll.Font = New-Object System.Drawing.Font("Segoe UI", 10.5, [System.Drawing.FontStyle]::Bold)
$btnStopAll.Location = New-Object System.Drawing.Point(20, 395)
$btnStopAll.Size = New-Object System.Drawing.Size(525, 38)
$btnStopAll.BackColor = [System.Drawing.Color]::FromArgb(231, 76, 60)
$btnStopAll.ForeColor = [System.Drawing.Color]::White
$btnStopAll.FlatStyle = "Flat"
$btnStopAll.FlatAppearance.BorderSize = 0
$btnStopAll.Cursor = [System.Windows.Forms.Cursors]::Hand
$form.Controls.Add($btnStopAll)

# Live Log Console
$logLbl = New-Object System.Windows.Forms.Label
$logLbl.Text = "Nhật ký hoạt động (Live Logs):"
$logLbl.Font = New-Object System.Drawing.Font("Segoe UI", 8.5, [System.Drawing.FontStyle]::Bold)
$logLbl.ForeColor = [System.Drawing.Color]::FromArgb(186, 194, 222)
$logLbl.Location = New-Object System.Drawing.Point(20, 440)
$logLbl.Size = New-Object System.Drawing.Size(525, 18)
$form.Controls.Add($logLbl)

$logBox = New-Object System.Windows.Forms.TextBox
$logBox.Location = New-Object System.Drawing.Point(20, 460)
$logBox.Size = New-Object System.Drawing.Size(525, 140)
$logBox.Multiline = $true
$logBox.ReadOnly = $true
$logBox.ScrollBars = "Vertical"
$logBox.BackColor = [System.Drawing.Color]::FromArgb(17, 17, 27)
$logBox.ForeColor = [System.Drawing.Color]::FromArgb(205, 214, 244)
$logBox.Font = New-Object System.Drawing.Font("Consolas", 8.5)
$logBox.BorderStyle = "FixedSingle"
$form.Controls.Add($logBox)

# Footer
$footerLbl = New-Object System.Windows.Forms.Label
$footerLbl.Text = "Tối ưu hóa VPS Non-GPU: Giao diện CPU < 15MB RAM - 0% CPU"
$footerLbl.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$footerLbl.ForeColor = [System.Drawing.Color]::FromArgb(108, 112, 134)
$footerLbl.Location = New-Object System.Drawing.Point(20, 605)
$footerLbl.Size = New-Object System.Drawing.Size(525, 20)
$footerLbl.TextAlign = "MiddleCenter"
$form.Controls.Add($footerLbl)

# State Variables
$global:AutoCheckEnabled = $false
$global:IsBusy = $false

function Append-UiLog([string]$msg) {
    $now = Get-Date -Format "HH:mm:ss"
    $line = "[$now] $msg"
    $logBox.AppendText("$line`r`n")
    $logBox.SelectionStart = $logBox.Text.Length
    $logBox.ScrollToCaret()
}

function Get-RunningInstanceProcess([string]$inst) {
    $procs = Get-CimInstance Win32_Process -Filter "Name='javaw.exe' or Name='java.exe'" -ErrorAction SilentlyContinue
    if (-not $procs) { return $null }
    foreach ($p in $procs) {
        if ($p.CommandLine -and $p.CommandLine -like "*instances\$inst\*") {
            return $p
        }
    }
    if ($availableInstances.Count -eq 1 -and $procs.Count -gt 0) {
        return $procs[0]
    }
    return $null
}

function Refresh-InstanceStatuses() {
    $procs = Get-CimInstance Win32_Process -Filter "Name='javaw.exe' or Name='java.exe'" -ErrorAction SilentlyContinue
    
    foreach ($instName in $instControls.Keys) {
        $item = $instControls[$instName]
        $foundProc = $null
        if ($procs) {
            foreach ($p in $procs) {
                if ($p.CommandLine -and $p.CommandLine -like "*instances\$instName\*") {
                    $foundProc = $p
                    break
                }
            }
            if (-not $foundProc -and $availableInstances.Count -eq 1) {
                $foundProc = $procs[0]
            }
        }

        if ($foundProc) {
            $ramMB = [math]::Round($foundProc.WorkingSetSize / 1MB)
            $item.Badge.Text = "● ĐANG CHẠY`nPID: $($foundProc.ProcessId) | RAM: $ramMB MB"
            $item.Badge.ForeColor = [System.Drawing.Color]::FromArgb(166, 227, 161)
            $item.IsRunning = $true
            $item.ProcessId = $foundProc.ProcessId
            $item.Button.Text = "Dừng bot"
            $item.Button.BackColor = [System.Drawing.Color]::FromArgb(243, 139, 168)
        } else {
            if ($global:AutoCheckEnabled -and $item.Checkbox.Checked) {
                $item.Badge.Text = "⌛ ĐANG CHỜ MỞ...`n(Tự động Reopen)"
                $item.Badge.ForeColor = [System.Drawing.Color]::FromArgb(249, 226, 175)
            } else {
                $item.Badge.Text = "○ ĐÃ DỪNG`n(Chưa kích hoạt)"
                $item.Badge.ForeColor = [System.Drawing.Color]::FromArgb(147, 153, 178)
            }
            $item.IsRunning = $false
            $item.ProcessId = $null
            $item.Button.Text = "Bật bot"
            $item.Button.BackColor = [System.Drawing.Color]::FromArgb(69, 71, 90)
        }
    }
}

function Start-SingleInstance([string]$instName) {
    $item = $instControls[$instName]
    $acc = $item.Account
    $accArg = if ($acc -and $acc -ne "(Chua dang nhap)") { " --profile `"$acc`"" } else { "" }
    Append-UiLog "[$instName] Dang khoi dong Minecraft $accArg -> Server $ServerAddress..."
    
    $env:LP_NUM_THREADS = "2"
    $arg = "--launch `"$instName`" --server $ServerAddress$accArg"
    Start-Process -FilePath $PrismExe -ArgumentList $arg -WindowStyle Normal
    $item.LastLaunch = [DateTime]::Now
    $item.SessionStart = [DateTime]::Now

    if (Test-Path $item.LogFile) {
        $item.LogPos = (Get-Item $item.LogFile).Length
    }
}

function Stop-AllInstancesCleanly() {
    $global:AutoCheckEnabled = $false
    $autoStatusLbl.Text = "Chế độ Auto Check: ĐÃ DỪNG"
    $autoStatusLbl.ForeColor = [System.Drawing.Color]::FromArgb(243, 139, 168)
    $btnStartAuto.Text = "▶  BẮT ĐẦU AUTO CHECK CONNECT (24/7)"
    $btnStartAuto.BackColor = [System.Drawing.Color]::FromArgb(46, 204, 113)

    # 1. Dung Watchdog scripts chay ngam
    $watchdogProcs = Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object { $_.CommandLine -like "*watchdog.ps1*" }
    if ($watchdogProcs) {
        $watchdogProcs | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
    }

    # 2. Dong tat ca tien trinh Minecraft
    $mcProcs = Get-Process -Name "javaw","java" -ErrorAction SilentlyContinue
    if ($mcProcs) {
        $count = $mcProcs.Count
        $mcProcs | Stop-Process -Force -ErrorAction SilentlyContinue
        Append-UiLog "[STOP ALL] Da tat thanh cong $count tien trinh Minecraft (javaw.exe)!"
    } else {
        Append-UiLog "[STOP ALL] Khong co instance Minecraft nao dang chay."
    }

    Refresh-InstanceStatuses
}

# Attach individual button clicks
foreach ($instName in $instControls.Keys) {
    $item = $instControls[$instName]
    $nameLocal = $instName
    $item.Button.Add_Click({
        $p = Get-RunningInstanceProcess $nameLocal
        if ($p) {
            Stop-Process -Id $p.ProcessId -Force -ErrorAction SilentlyContinue
            Append-UiLog "[$nameLocal] Da dung instance theo yeu cau."
        } else {
            Start-SingleInstance $nameLocal
        }
        Start-Sleep -Milliseconds 800
        Refresh-InstanceStatuses
    })
}

# Button Stop All Click
$btnStopAll.Add_Click({
    $ans = [System.Windows.Forms.MessageBox]::Show(
        "Bạn có chắc chắn muốn DỪNG TẤT CẢ các Instance Minecraft đang chạy không?",
        "Xác nhận dừng tất cả",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Question
    )
    if ($ans -eq [System.Windows.Forms.DialogResult]::Yes) {
        Stop-AllInstancesCleanly
        [System.Windows.Forms.MessageBox]::Show(
            "Đã dừng tất cả các bot Minecraft thành công!",
            "Hoàn tất",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )
    }
})

# Button Start Auto Click
$btnStartAuto.Add_Click({
    if ($global:AutoCheckEnabled) {
        # Neu dang chay ma bam -> Tam dung Auto
        $global:AutoCheckEnabled = $false
        $autoStatusLbl.Text = "Chế độ Auto Check: ĐÃ TẠM DỪNG"
        $autoStatusLbl.ForeColor = [System.Drawing.Color]::FromArgb(249, 226, 175)
        $btnStartAuto.Text = "▶  TIẾP TỤC AUTO CHECK CONNECT (24/7)"
        $btnStartAuto.BackColor = [System.Drawing.Color]::FromArgb(46, 204, 113)
        Append-UiLog "[AUTO] Da tam dung tu dong kiem tra ket noi."
        return
    }

    # Luu cau hinh delay va so bot
    $delayVal = 25
    [int]::TryParse($delayTxt.Text.Trim(), [ref]$delayVal) | Out-Null
    if ($delayVal -lt 5) { $delayVal = 25 }

    $checkedInsts = @($availableInstances | Where-Object { $instControls[$_.Name].Checkbox.Checked } | ForEach-Object { $_.Name })
    if ($checkedInsts.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("Vui lòng tích chọn ít nhất 1 Instance để chạy Auto!", "Chưa chọn bot", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
        return
    }

    # Luu vao instance_config.json
    $cfgObj = @{
        active_count = $checkedInsts.Count
        launch_delay_seconds = $delayVal
        instances = $checkedInsts
        updated = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }
    $cfgJson = $cfgObj | ConvertTo-Json -Compress
    [System.IO.File]::WriteAllText($instConfigFile, $cfgJson, [System.Text.Encoding]::UTF8)

    $global:AutoCheckEnabled = $true
    $autoStatusLbl.Text = "Chế độ Auto Check: ĐANG HOẠT ĐỘNG (24/7)"
    $autoStatusLbl.ForeColor = [System.Drawing.Color]::FromArgb(166, 227, 161)
    $btnStartAuto.Text = "⏸  TẠM DỪNG AUTO CHECK CONNECT"
    $btnStartAuto.BackColor = [System.Drawing.Color]::FromArgb(249, 226, 175)

    Append-UiLog "[AUTO] Kich hoat Auto Check Connect cho: $($checkedInsts -join ', ')"
    Append-UiLog "[AUTO] Delay giua cac bot: $delayVal giay (Tranh tran RAM)"

    # Khoi dong cac bot chua chay (gian cach bang delay)
    $btnStartAuto.Enabled = $false
    for ($idx = 0; $idx -lt $checkedInsts.Count; $idx++) {
        $name = $checkedInsts[$idx]
        $p = Get-RunningInstanceProcess $name
        if (-not $p) {
            Start-SingleInstance $name
            if ($idx -lt ($checkedInsts.Count - 1)) {
                Append-UiLog "[AUTO] Cho $delayVal giay de $name on dinh RAM truoc khi bat bot tiep theo..."
                $remaining = $delayVal
                while ($remaining -gt 0) {
                    [System.Windows.Forms.Application]::DoEvents()
                    Start-Sleep -Seconds 1
                    $remaining--
                }
            }
        } else {
            Append-UiLog "[$name] Da dang chay san (PID: $($p.ProcessId))."
        }
    }
    $btnStartAuto.Enabled = $true
    Refresh-InstanceStatuses
})

# Background Monitoring Timer (Chay ngam moi 4 giay)
$dcTriggers = @(
    "Lost connection", "Disconnected from server", "Disconnected:", "Connection reset",
    "Connection refused", "Timed out", "Read timed out", "Connect timed out",
    "io.netty", "Internal Exception:", "SocketException", "ConnectException",
    "forcibly closed by the remote host", "Kicked by server", "Server closed",
    "closed connection", "Connecting too fast", "You are already connected",
    "Failed to verify username", "Invalid session"
)

$monitorTimer = New-Object System.Windows.Forms.Timer
$monitorTimer.Interval = 4000
$monitorTimer.Add_Tick({
    Refresh-InstanceStatuses

    if (-not $global:AutoCheckEnabled -or $global:IsBusy) { return }

    $delayVal = 25
    [int]::TryParse($delayTxt.Text.Trim(), [ref]$delayVal) | Out-Null
    if ($delayVal -lt 5) { $delayVal = 25 }

    foreach ($instName in $instControls.Keys) {
        $item = $instControls[$instName]
        if (-not $item.Checkbox.Checked) { continue }

        $p = Get-RunningInstanceProcess $instName

        # 1. Phat hien bot bi crash hoac tat bat ngo
        if (-not $p) {
            if (([DateTime]::Now - $item.LastLaunch).TotalSeconds -gt ($delayVal + 15)) {
                $item.ConsecutiveFails++
                Append-UiLog "[!] [$instName] Phat hien bot bi crash hoac dong! Dang mo lai..."
                Start-SingleInstance $instName
            }
            continue
        }

        # 2. Ha priority de bao ve CPU
        try {
            $pObj = Get-Process -Id $p.ProcessId -ErrorAction SilentlyContinue
            if ($pObj -and $pObj.PriorityClass -ne [System.Diagnostics.ProcessPriorityClass]::BelowNormal) {
                $pObj.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::BelowNormal
            }
        } catch {}

        # 3. Kiem tra log tim loi ngat ket noi
        $logPath = $item.LogFile
        if (Test-Path $logPath) {
            try {
                $file = [System.IO.File]::Open($logPath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
                if ($file.Length -gt $item.LogPos) {
                    $file.Seek($item.LogPos, [System.IO.SeekOrigin]::Begin) | Out-Null
                    $reader = New-Object System.IO.StreamReader($file)
                    $newText = $reader.ReadToEnd()
                    $item.LogPos = $file.Position
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
                        Append-UiLog "[!] [$instName] PHAT HIEN LOI MANG: $matchedTrigger"
                        Append-UiLog "[$instName] Cho 10s kiem tra mod auto-reconnect..."
                        
                        # Cho 10s kiem tra mod
                        $global:IsBusy = $true
                        for ($s = 0; $s -lt 10; $s++) {
                            [System.Windows.Forms.Application]::DoEvents()
                            Start-Sleep -Seconds 1
                        }

                        $reconnected = $false
                        try {
                            $f2 = [System.IO.File]::Open($logPath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
                            if ($f2.Length -gt $item.LogPos) {
                                $f2.Seek($item.LogPos, [System.IO.SeekOrigin]::Begin) | Out-Null
                                $r2 = New-Object System.IO.StreamReader($f2)
                                $afterTxt = $r2.ReadToEnd()
                                $item.LogPos = $f2.Position
                                $r2.Close()
                                if ($afterTxt -like "*Connecting to*" -or $afterTxt -like "*Connected*" -or $afterTxt -like "*[CHAT]*") {
                                    $reconnected = $true
                                }
                            }
                            $f2.Close()
                        } catch {}

                        if (-not $reconnected) {
                            $item.ConsecutiveFails++
                            Append-UiLog "[!] [$instName] Mod khong the tu phuc hoi. Dang DONG RIENG bot nay de reopen..."
                            Stop-Process -Id $p.ProcessId -Force -ErrorAction SilentlyContinue
                            Start-Sleep -Seconds 3
                            Start-SingleInstance $instName
                        } else {
                            Append-UiLog "[OK] [$instName] Mod da tu ket noi lai thanh cong!"
                        }
                        $global:IsBusy = $false
                    }
                } else {
                    $file.Close()
                }
            } catch {}
        }
    }
})

# Khoi dong timer
$monitorTimer.Start()

# Initial Refresh and Log
Append-UiLog "Trung tam dieu khien da san sang. He thong: $($availableInstances.Count) Instance."
Append-UiLog "Ban co the tich chon instance muon auto va bam [BAT DAU AUTO] hoac bam [DUNG TAT CA]."
Refresh-InstanceStatuses

# Form Clean Closing
$form.Add_FormClosing({
    $monitorTimer.Stop()
    $monitorTimer.Dispose()
})

# Show Dialog
$form.ShowDialog() | Out-Null
$form.Dispose()
