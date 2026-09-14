Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Determine BaseDir & Paths
$BaseDir = "C:\MinecraftVPS"
if (-not (Test-Path $BaseDir)) {
    if ($MyInvocation.MyCommand.Path) {
        $BaseDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    } else {
        $BaseDir = (Get-Location).Path
    }
}

$PrismDir = Join-Path $BaseDir "PrismLauncher"
$instancesDir = Join-Path $PrismDir "instances"
$targetInstances = @()
if (Test-Path $instancesDir) {
    $targetInstances = @(Get-ChildItem -Path $instancesDir -Directory -ErrorAction SilentlyContinue | Where-Object { 
        Test-Path (Join-Path $_.FullName ".minecraft")
    })
}
if (-not $targetInstances -or $targetInstances.Count -eq 0) {
    $targetInstances = @([PSCustomObject]@{
        Name = "VPS-AFK-1"
        FullName = (Join-Path $instancesDir "VPS-AFK-1")
    })
}

$watchdogBat = Join-Path $BaseDir "run-watchdog.bat"
$runAfkBat = Join-Path $BaseDir "run-afk.bat"
$instConfigFile = Join-Path $BaseDir "instance_config.json"
$accountsFile = Join-Path $PrismDir "accounts.json"

# Doc danh sach tai khoan Microsoft da dang nhap
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

# Doc cau hinh instance_config.json (so instance bat va delay chong tran ram)
$savedActiveCount = [math]::Min(3, $targetInstances.Count)
$savedDelaySeconds = 25
if (Test-Path $instConfigFile) {
    try {
        $cfgJson = Get-Content $instConfigFile -Raw | ConvertFrom-Json
        if ($cfgJson.active_count) { $savedActiveCount = [int]$cfgJson.active_count }
        if ($cfgJson.launch_delay_seconds) { $savedDelaySeconds = [int]$cfgJson.launch_delay_seconds }
    } catch {}
}
if ($savedActiveCount -lt 1) { $savedActiveCount = 1 }
if ($savedActiveCount -gt $targetInstances.Count) { $savedActiveCount = $targetInstances.Count }
if ($savedDelaySeconds -lt 5) { $savedDelaySeconds = 15 }

# Embedded No Render GZ NBT
$noRenderGzB64 = "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"

function Compress-GZipBytes([byte[]]$Data) {
    $msOut = New-Object System.IO.MemoryStream
    $gz = New-Object System.IO.Compression.GZipStream($msOut, [System.IO.Compression.CompressionMode]::Compress)
    $gz.Write($Data, 0, $Data.Length)
    $gz.Close()
    return $msOut.ToArray()
}

function Decompress-GZipBytes([byte[]]$Data) {
    $msIn = New-Object System.IO.MemoryStream(,$Data)
    $gz = New-Object System.IO.Compression.GZipStream($msIn, [System.IO.Compression.CompressionMode]::Decompress)
    $msOut = New-Object System.IO.MemoryStream
    $gz.CopyTo($msOut)
    $gz.Close()
    return $msOut.ToArray()
}

function Build-SpamNbtBytes([string]$PayCommand, [int]$Delay = 400) {
    $ms = New-Object System.IO.MemoryStream
    function Write-U16($val) {
        $ms.WriteByte([byte](($val -shr 8) -band 0xFF))
        $ms.WriteByte([byte]($val -band 0xFF))
    }
    function Write-I32($val) {
        $ms.WriteByte([byte](($val -shr 24) -band 0xFF))
        $ms.WriteByte([byte](($val -shr 16) -band 0xFF))
        $ms.WriteByte([byte](($val -shr 8) -band 0xFF))
        $ms.WriteByte([byte]($val -band 0xFF))
    }
    function Write-TagString([string]$name, [string]$val) {
        $ms.WriteByte(8)
        $nb = [System.Text.Encoding]::UTF8.GetBytes($name)
        Write-U16 $nb.Length
        $ms.Write($nb, 0, $nb.Length)
        $vb = [System.Text.Encoding]::UTF8.GetBytes($val)
        Write-U16 $vb.Length
        $ms.Write($vb, 0, $vb.Length)
    }
    function Write-TagByte([string]$name, [byte]$val) {
        $ms.WriteByte(1)
        $nb = [System.Text.Encoding]::UTF8.GetBytes($name)
        Write-U16 $nb.Length
        $ms.Write($nb, 0, $nb.Length)
        $ms.WriteByte($val)
    }
    function Write-TagInt([string]$name, [int]$val) {
        $ms.WriteByte(3)
        $nb = [System.Text.Encoding]::UTF8.GetBytes($name)
        Write-U16 $nb.Length
        $ms.Write($nb, 0, $nb.Length)
        Write-I32 $val
    }

    Write-TagString "name" "spam"

    $ms.WriteByte(10)
    $kb = [System.Text.Encoding]::UTF8.GetBytes("keybind")
    Write-U16 $kb.Length
    $ms.Write($kb, 0, $kb.Length)
    Write-TagByte "isKey" 1
    Write-TagInt "value" 96
    $ms.WriteByte(0)

    Write-TagByte "toggleOnKeyRelease" 0
    Write-TagByte "chatFeedback" 1
    Write-TagByte "favorite" 0

    $ms.WriteByte(10)
    $sb = [System.Text.Encoding]::UTF8.GetBytes("settings")
    Write-U16 $sb.Length
    $ms.Write($sb, 0, $sb.Length)

    $ms.WriteByte(9)
    $gb = [System.Text.Encoding]::UTF8.GetBytes("groups")
    Write-U16 $gb.Length
    $ms.Write($gb, 0, $gb.Length)
    $ms.WriteByte(10)
    Write-I32 1

    Write-TagString "name" "General"
    Write-TagByte "sectionExpanded" 1

    $ms.WriteByte(9)
    $stb = [System.Text.Encoding]::UTF8.GetBytes("settings")
    Write-U16 $stb.Length
    $ms.Write($stb, 0, $stb.Length)
    $ms.WriteByte(10)
    Write-I32 7

    Write-TagString "name" "messages"
    $ms.WriteByte(9)
    $vb = [System.Text.Encoding]::UTF8.GetBytes("value")
    Write-U16 $vb.Length
    $ms.Write($vb, 0, $vb.Length)
    $ms.WriteByte(8)
    Write-I32 1

    $msgBytes = [System.Text.Encoding]::UTF8.GetBytes($PayCommand)
    Write-U16 $msgBytes.Length
    $ms.Write($msgBytes, 0, $msgBytes.Length)
    $ms.WriteByte(0)

    Write-TagString "name" "delay"
    Write-TagInt "value" $Delay
    $ms.WriteByte(0)

    Write-TagString "name" "disable-on-leave"
    Write-TagByte "value" 0
    $ms.WriteByte(0)

    Write-TagString "name" "disable-on-disconnect"
    Write-TagByte "value" 0
    $ms.WriteByte(0)

    Write-TagString "name" "randomise"
    Write-TagByte "value" 0
    $ms.WriteByte(0)

    Write-TagString "name" "auto-split-messages"
    Write-TagByte "value" 0
    $ms.WriteByte(0)

    Write-TagString "name" "bypass"
    Write-TagByte "value" 0
    $ms.WriteByte(0)

    $ms.WriteByte(0)
    $ms.WriteByte(0)
    Write-TagByte "active" 1
    $ms.WriteByte(0)

    return $ms.ToArray()
}

function Save-AutoPaySettings([string]$TargetUser, [string]$TargetAmount, [bool]$Enable) {
    $noRenderBytes = [Convert]::FromBase64String($noRenderGzB64)
    $noRenderDecomp = Decompress-GZipBytes -Data $noRenderBytes
    $noRenderCompBytes = New-Object byte[] ($noRenderDecomp.Length - 19)
    [Array]::Copy($noRenderDecomp, 18, $noRenderCompBytes, 0, $noRenderCompBytes.Length)

    $moduleCount = 1
    $spamCompBytes = $null
    $spamGzBytes = $null
    if ($Enable -and (-not [string]::IsNullOrWhiteSpace($TargetUser))) {
        $moduleCount = 2
        $cmd = "/pay $TargetUser $TargetAmount"
        $spamCompBytes = Build-SpamNbtBytes -PayCommand $cmd -Delay 400

        $spamStandaloneMs = New-Object System.IO.MemoryStream
        $spamStandaloneMs.WriteByte(10); $spamStandaloneMs.WriteByte(0); $spamStandaloneMs.WriteByte(0)
        $spamStandaloneMs.Write($spamCompBytes, 0, $spamCompBytes.Length)
        $spamGzBytes = Compress-GZipBytes -Data ($spamStandaloneMs.ToArray())
    }

    $rootMs = New-Object System.IO.MemoryStream
    $rootMs.WriteByte(10); $rootMs.WriteByte(0); $rootMs.WriteByte(0)
    $rootMs.WriteByte(9); $rootMs.WriteByte(0); $rootMs.WriteByte(7)
    $rootMs.Write([System.Text.Encoding]::UTF8.GetBytes("modules"), 0, 7)
    $rootMs.WriteByte(10)
    $rootMs.WriteByte([byte](($moduleCount -shr 24) -band 0xFF))
    $rootMs.WriteByte([byte](($moduleCount -shr 16) -band 0xFF))
    $rootMs.WriteByte([byte](($moduleCount -shr 8) -band 0xFF))
    $rootMs.WriteByte([byte]($moduleCount -band 0xFF))

    $rootMs.Write($noRenderCompBytes, 0, $noRenderCompBytes.Length)
    if ($moduleCount -eq 2 -and $spamCompBytes) {
        $rootMs.Write($spamCompBytes, 0, $spamCompBytes.Length)
    }
    $rootMs.WriteByte(0)

    $finalGzModules = Compress-GZipBytes -Data ($rootMs.ToArray())

    # Ghi vao TAT CA cac Instance co san (VPS-AFK-1, VPS-AFK-2, VPS-AFK-3...)
    foreach ($inst in $targetInstances) {
        $mDir = Join-Path $inst.FullName ".minecraft\meteor-client"
        if (-not (Test-Path $mDir)) { New-Item -ItemType Directory -Path $mDir -Force | Out-Null }

        if ($spamGzBytes) {
            $spamDestList = @(
                (Join-Path $mDir "modules\Spam.nbt"),
                (Join-Path $mDir "modules\spam.nbt"),
                (Join-Path $mDir "presets\spam.nbt"),
                (Join-Path $mDir "presets\spam\default.nbt")
            )
            foreach ($sd in $spamDestList) {
                $sp = Split-Path -Parent $sd
                if (-not (Test-Path $sp)) { New-Item -ItemType Directory -Path $sp -Force | Out-Null }
                [System.IO.File]::WriteAllBytes($sd, $spamGzBytes)
            }
            $spamB64 = [Convert]::ToBase64String($spamGzBytes)
            [System.IO.File]::WriteAllText((Join-Path $mDir "config spam auto pay.txt"), $spamB64, [System.Text.Encoding]::UTF8)
        }

        [System.IO.File]::WriteAllBytes((Join-Path $mDir "modules.nbt"), $finalGzModules)

        # Save pay_config.json
        $cfg = @{
            user = $TargetUser
            amount = $TargetAmount
            enabled = $Enable
            updated = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        }
        $json = $cfg | ConvertTo-Json -Compress
        [System.IO.File]::WriteAllText((Join-Path $mDir "pay_config.json"), $json, [System.Text.Encoding]::UTF8)
    }
}

# Read current values if exists (tim tu instance dau tien)
$currentUser = ""
$currentAmount = "1M"
$currentEnabled = $false

foreach ($inst in $targetInstances) {
    $cfgFile = Join-Path $inst.FullName ".minecraft\meteor-client\pay_config.json"
    if (Test-Path $cfgFile) {
        try {
            $saved = Get-Content $cfgFile -Raw | ConvertFrom-Json
            $currentUser = $saved.user
            $currentAmount = $saved.amount
            $currentEnabled = [bool]$saved.enabled
            break
        } catch {}
    }
}

# ==============================================================================
# GUI FORM (Ultra Lightweight WinForms for 4-4 / 8-8 Non-GPU VPS)
# ==============================================================================
$form = New-Object System.Windows.Forms.Form
$form.Text = "Quan Ly Auto Pay & Instances - DonutSMP"
$form.Size = New-Object System.Drawing.Size(460, 620)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false
$form.BackColor = [System.Drawing.Color]::FromArgb(24, 24, 37) # #181825 Catppuccin Base

# Title Label
$titleLbl = New-Object System.Windows.Forms.Label
$titleLbl.Text = "QUẢN LÝ AUTO PAY & INSTANCES"
$titleLbl.Font = New-Object System.Drawing.Font("Segoe UI", 13, [System.Drawing.FontStyle]::Bold)
$titleLbl.ForeColor = [System.Drawing.Color]::FromArgb(137, 180, 250)
$titleLbl.Location = New-Object System.Drawing.Point(20, 12)
$titleLbl.Size = New-Object System.Drawing.Size(410, 28)
$titleLbl.TextAlign = "MiddleCenter"
$form.Controls.Add($titleLbl)

# Subtitle
$subLbl = New-Object System.Windows.Forms.Label
$instNamesStr = ($targetInstances | ForEach-Object { $_.Name }) -join ", "
$subLbl.Text = "DonutSMP AFK - Moi Instance 1 Tai khoan rieng biet"
$subLbl.Font = New-Object System.Drawing.Font("Segoe UI", 8.5)
$subLbl.ForeColor = [System.Drawing.Color]::FromArgb(166, 173, 200)
$subLbl.Location = New-Object System.Drawing.Point(20, 40)
$subLbl.Size = New-Object System.Drawing.Size(410, 18)
$subLbl.TextAlign = "MiddleCenter"
$form.Controls.Add($subLbl)

# Status Panel
$statusPanel = New-Object System.Windows.Forms.Panel
$statusPanel.Location = New-Object System.Drawing.Point(25, 62)
$statusPanel.Size = New-Object System.Drawing.Size(395, 65)
$statusPanel.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 46)
$form.Controls.Add($statusPanel)

$statusLbl1 = New-Object System.Windows.Forms.Label
$statusLbl1.Font = New-Object System.Drawing.Font("Segoe UI", 8.5, [System.Drawing.FontStyle]::Bold)
$statusLbl1.Location = New-Object System.Drawing.Point(8, 6)
$statusLbl1.Size = New-Object System.Drawing.Size(375, 18)
if ($currentEnabled -and (-not [string]::IsNullOrWhiteSpace($currentUser))) {
    $statusLbl1.Text = "● Trạng thái: ĐANG BẬT (/pay $currentUser $currentAmount)"
    $statusLbl1.ForeColor = [System.Drawing.Color]::FromArgb(166, 227, 161)
} else {
    $statusLbl1.Text = "○ Trạng thái: CHƯA BẬT / ĐÃ TẮT"
    $statusLbl1.ForeColor = [System.Drawing.Color]::FromArgb(147, 153, 178)
}
$statusPanel.Controls.Add($statusLbl1)

$accSummaryList = @()
for ($i = 0; $i -lt $targetInstances.Count; $i++) {
    $iName = $targetInstances[$i].Name
    $acc = if ($i -lt $loggedAccounts.Count) { $loggedAccounts[$i] } else { "(Chua login)" }
    $accSummaryList += "$($iName): $acc"
}
$statusLbl2 = New-Object System.Windows.Forms.Label
$statusLbl2.Font = New-Object System.Drawing.Font("Consolas", 8)
$statusLbl2.Location = New-Object System.Drawing.Point(8, 26)
$statusLbl2.Size = New-Object System.Drawing.Size(375, 34)
$statusLbl2.ForeColor = [System.Drawing.Color]::FromArgb(249, 226, 175)
$statusLbl2.Text = "Tai khoan gan lien tung Instance:`n" + ($accSummaryList -join " | ")
$statusPanel.Controls.Add($statusLbl2)

# User Label & Input
$userLbl = New-Object System.Windows.Forms.Label
$userLbl.Text = "Tên người nhận (Username để pay cho):"
$userLbl.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$userLbl.ForeColor = [System.Drawing.Color]::FromArgb(205, 214, 244)
$userLbl.Location = New-Object System.Drawing.Point(25, 135)
$userLbl.Size = New-Object System.Drawing.Size(395, 18)
$form.Controls.Add($userLbl)

$userTxt = New-Object System.Windows.Forms.TextBox
$userTxt.Font = New-Object System.Drawing.Font("Segoe UI", 10.5)
$userTxt.Location = New-Object System.Drawing.Point(25, 155)
$userTxt.Size = New-Object System.Drawing.Size(395, 28)
$userTxt.BackColor = [System.Drawing.Color]::FromArgb(49, 50, 68)
$userTxt.ForeColor = [System.Drawing.Color]::White
$userTxt.BorderStyle = "FixedSingle"
$userTxt.Text = $currentUser
$form.Controls.Add($userTxt)

# Amount Label & Input
$amountLbl = New-Object System.Windows.Forms.Label
$amountLbl.Text = "Số tiền pay (Ví dụ: 1M, 2M, 2000000, 500k...):"
$amountLbl.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$amountLbl.ForeColor = [System.Drawing.Color]::FromArgb(205, 214, 244)
$amountLbl.Location = New-Object System.Drawing.Point(25, 190)
$amountLbl.Size = New-Object System.Drawing.Size(395, 18)
$form.Controls.Add($amountLbl)

$amountTxt = New-Object System.Windows.Forms.TextBox
$amountTxt.Font = New-Object System.Drawing.Font("Segoe UI", 10.5)
$amountTxt.Location = New-Object System.Drawing.Point(25, 210)
$amountTxt.Size = New-Object System.Drawing.Size(395, 28)
$amountTxt.BackColor = [System.Drawing.Color]::FromArgb(49, 50, 68)
$amountTxt.ForeColor = [System.Drawing.Color]::White
$amountTxt.BorderStyle = "FixedSingle"
$amountTxt.Text = if ($currentAmount) { $currentAmount } else { "1M" }
$form.Controls.Add($amountTxt)

# Row: So Instance Bat & Delay khoi dong
$instCountLbl = New-Object System.Windows.Forms.Label
$instCountLbl.Text = "Số Instance bật (1 - $($targetInstances.Count)):"
$instCountLbl.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$instCountLbl.ForeColor = [System.Drawing.Color]::FromArgb(205, 214, 244)
$instCountLbl.Location = New-Object System.Drawing.Point(25, 248)
$instCountLbl.Size = New-Object System.Drawing.Size(190, 18)
$form.Controls.Add($instCountLbl)

$delayLbl = New-Object System.Windows.Forms.Label
$delayLbl.Text = "Delay mở bot (s) (Chống tràn RAM):"
$delayLbl.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$delayLbl.ForeColor = [System.Drawing.Color]::FromArgb(205, 214, 244)
$delayLbl.Location = New-Object System.Drawing.Point(230, 248)
$delayLbl.Size = New-Object System.Drawing.Size(190, 18)
$form.Controls.Add($delayLbl)

$instCountCombo = New-Object System.Windows.Forms.ComboBox
$instCountCombo.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$instCountCombo.Location = New-Object System.Drawing.Point(25, 268)
$instCountCombo.Size = New-Object System.Drawing.Size(185, 28)
$instCountCombo.DropDownStyle = "DropDownList"
$instCountCombo.BackColor = [System.Drawing.Color]::FromArgb(49, 50, 68)
$instCountCombo.ForeColor = [System.Drawing.Color]::White
for ($i = 1; $i -le $targetInstances.Count; $i++) {
    $instCountCombo.Items.Add("$i Instance") | Out-Null
}
$instCountCombo.SelectedIndex = [math]::Max(0, [math]::Min($savedActiveCount - 1, $instCountCombo.Items.Count - 1))
$form.Controls.Add($instCountCombo)

$delayTxt = New-Object System.Windows.Forms.TextBox
$delayTxt.Font = New-Object System.Drawing.Font("Segoe UI", 10.5)
$delayTxt.Location = New-Object System.Drawing.Point(230, 268)
$delayTxt.Size = New-Object System.Drawing.Size(190, 28)
$delayTxt.BackColor = [System.Drawing.Color]::FromArgb(49, 50, 68)
$delayTxt.ForeColor = [System.Drawing.Color]::White
$delayTxt.BorderStyle = "FixedSingle"
$delayTxt.Text = "$savedDelaySeconds"
$form.Controls.Add($delayTxt)

# Button Confirm & Restart
$confirmBtn = New-Object System.Windows.Forms.Button
$confirmBtn.Text = "✔  XÁC NHẬN & RESTART MINECRAFT"
$confirmBtn.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$confirmBtn.Location = New-Object System.Drawing.Point(25, 320)
$confirmBtn.Size = New-Object System.Drawing.Size(395, 42)
$confirmBtn.BackColor = [System.Drawing.Color]::FromArgb(46, 204, 113)
$confirmBtn.ForeColor = [System.Drawing.Color]::FromArgb(17, 17, 27)
$confirmBtn.FlatStyle = "Flat"
$confirmBtn.FlatAppearance.BorderSize = 0
$confirmBtn.Cursor = [System.Windows.Forms.Cursors]::Hand
$form.Controls.Add($confirmBtn)

# Button Disable Auto Pay
$disableBtn = New-Object System.Windows.Forms.Button
$disableBtn.Text = "⛔  Tắt Auto Pay (Chỉ treo AFK giữ No-Render)"
$disableBtn.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$disableBtn.Location = New-Object System.Drawing.Point(25, 372)
$disableBtn.Size = New-Object System.Drawing.Size(395, 34)
$disableBtn.BackColor = [System.Drawing.Color]::FromArgb(243, 139, 168)
$disableBtn.ForeColor = [System.Drawing.Color]::FromArgb(17, 17, 27)
$disableBtn.FlatStyle = "Flat"
$disableBtn.FlatAppearance.BorderSize = 0
$disableBtn.Cursor = [System.Windows.Forms.Cursors]::Hand
$form.Controls.Add($disableBtn)

# Button Stop All Instances
$stopAllBtn = New-Object System.Windows.Forms.Button
$stopAllBtn.Text = "🛑  DỪNG TẤT CẢ INSTANCE (STOP ALL)"
$stopAllBtn.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$stopAllBtn.Location = New-Object System.Drawing.Point(25, 412)
$stopAllBtn.Size = New-Object System.Drawing.Size(395, 34)
$stopAllBtn.BackColor = [System.Drawing.Color]::FromArgb(231, 76, 60)
$stopAllBtn.ForeColor = [System.Drawing.Color]::White
$stopAllBtn.FlatStyle = "Flat"
$stopAllBtn.FlatAppearance.BorderSize = 0
$stopAllBtn.Cursor = [System.Windows.Forms.Cursors]::Hand
$form.Controls.Add($stopAllBtn)

# Progress / Status footer
$footerLbl = New-Object System.Windows.Forms.Label
$footerLbl.Text = "Tối ưu 100% Non-GPU: Mỗi Instance 1 Account - Delay chống tràn RAM"
$footerLbl.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$footerLbl.ForeColor = [System.Drawing.Color]::FromArgb(108, 112, 134)
$footerLbl.Location = New-Object System.Drawing.Point(25, 455)
$footerLbl.Size = New-Object System.Drawing.Size(395, 20)
$footerLbl.TextAlign = "MiddleCenter"
$form.Controls.Add($footerLbl)

# Function to execute Minecraft Restart cleanly
function Restart-MinecraftCleanly() {
    # 1. Kiem tra va tat Watchdog dang chay
    $watchdogProcs = Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object { $_.CommandLine -like "*watchdog.ps1*" }
    if ($watchdogProcs) {
        $watchdogProcs | ForEach-Object {
            Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue
        }
    }

    # 2. Dong hoan toan Minecraft
    Get-Process -Name "javaw","java" -ErrorAction SilentlyContinue | Stop-Process -Force
    Start-Sleep -Seconds 2

    # 3. Mo lai qua Watchdog hoac Batch launcher
    if (Test-Path $watchdogBat) {
        Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$watchdogBat`"" -WindowStyle Normal
    } elseif (Test-Path $runAfkBat) {
        Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$runAfkBat`"" -WindowStyle Normal
    }
}

function Save-InstanceLaunchConfig([int]$count, [int]$delaySec) {
    $instNames = @()
    for ($i = 0; $i -lt $targetInstances.Count; $i++) {
        $instNames += $targetInstances[$i].Name
    }
    $cfgObj = @{
        active_count = $count
        launch_delay_seconds = $delaySec
        instances = $instNames
        updated = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }
    $json = $cfgObj | ConvertTo-Json -Compress
    [System.IO.File]::WriteAllText($instConfigFile, $json, [System.Text.Encoding]::UTF8)
}

# Event Click Confirm
$confirmBtn.Add_Click({
    $targetUser = $userTxt.Text.Trim()
    $targetAmountInput = $amountTxt.Text.Trim()

    if ([string]::IsNullOrWhiteSpace($targetUser)) {
        [System.Windows.Forms.MessageBox]::Show(
            "Vui lòng nhập tên tài khoản (Username) cần pay tiền!",
            "Thiếu thông tin",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        )
        $userTxt.Focus()
        return
    }

    if ([string]::IsNullOrWhiteSpace($targetAmountInput)) {
        [System.Windows.Forms.MessageBox]::Show(
            "Vui lòng nhập số tiền (M) cần pay!",
            "Thiếu thông tin",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        )
        $amountTxt.Focus()
        return
    }

    $selCount = $instCountCombo.SelectedIndex + 1
    $delayVal = 25
    if (-not [int]::TryParse($delayTxt.Text.Trim(), [ref]$delayVal) -or $delayVal -lt 5) {
        $delayVal = 25
    }

    # Kiem tra dinh dang so tien hop le (VD: 1M, 2M, 2000000, 500k...)
    if ($targetAmountInput -notmatch '^[0-9]+(\.[0-9]+)?[kKmMbBtT]?$') {
        [System.Windows.Forms.MessageBox]::Show(
            "Định dạng số tiền không hợp lệ!`n`nVui lòng nhập đúng định dạng số tiền hợp lệ trong game, ví dụ:`n• 1M hoặc 2M`n• 2000000 hoặc 500000`n• 500k hoặc 1.5M",
            "Sai định dạng số tiền",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        )
        $amountTxt.Focus()
        return
    }
    $numPart = $targetAmountInput -replace '[kKmMbBtT]$', ''
    $numVal = 0.0
    if (-not [double]::TryParse($numPart, [ref]$numVal) -or $numVal -le 0) {
        [System.Windows.Forms.MessageBox]::Show(
            "Số tiền pay phải lớn hơn 0!`n`nVí dụ: 1M, 2M, 2000000...",
            "Số tiền không hợp lệ",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        )
        $amountTxt.Focus()
        return
    }
    $targetM = $targetAmountInput.Trim()
    if ($targetM -match '[a-zA-Z]$') {
        $targetM = $targetM.Substring(0, $targetM.Length - 1) + $targetM.Substring($targetM.Length - 1).ToUpper()
    }

    $accLines = @()
    for ($i = 0; $i -lt $selCount; $i++) {
        $iName = $targetInstances[$i].Name
        $acc = if ($i -lt $loggedAccounts.Count) { $loggedAccounts[$i] } else { "(Mặc định)" }
        $accLines += "  • $($iName) -> Tài khoản: $acc"
    }
    $accListStr = $accLines -join "`n"

    $msgConfirm = "XÁC NHẬN THIẾT LẬP AUTO PAY & INSTANCES (DONUTSMP)`n`n" +
                  "• Người nhận       : $targetUser`n" +
                  "• Số tiền          : $targetM`n" +
                  "• Lệnh chat        : /pay $targetUser $targetM (Mỗi 400 ticks)`n" +
                  "• Số Instance chạy : $selCount Instance`n" +
                  "• Delay chống tràn : $delayVal giây giữa các bot`n" +
                  "• Phân chia tài khoản:`n$accListStr`n`n" +
                  "LƯU Ý: Minecraft sẽ được ĐÓNG, lưu cấu hình và TỰ ĐỘNG MỞ LẠI!"

    $ans = [System.Windows.Forms.MessageBox]::Show(
        $msgConfirm,
        "Xác nhận thay đổi",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Question
    )

    if ($ans -eq [System.Windows.Forms.DialogResult]::Yes) {
        $confirmBtn.Enabled = $false
        $disableBtn.Enabled = $false
        $footerLbl.Text = "Dang luu cau hinh & restart Minecraft..."
        $footerLbl.ForeColor = [System.Drawing.Color]::FromArgb(249, 226, 175)
        $form.Refresh()

        try {
            Save-AutoPaySettings -TargetUser $targetUser -TargetAmount $targetM -Enable $true
            Save-InstanceLaunchConfig -count $selCount -delaySec $delayVal

            $footerLbl.Text = "Dang khoi dong lai $selCount bot voi delay $delayVal giay..."
            $form.Refresh()
            Restart-MinecraftCleanly

            [System.Windows.Forms.MessageBox]::Show(
                "Đã cập nhật thành công!`n`nMinecraft đang được mở lại cho $selCount bot (mỗi bot 1 tài khoản riêng, delay $delayVal giây chống tràn RAM)!",
                "Hoàn tất",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Information
            )
            $form.Close()
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Lỗi: $_", "Lỗi", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            $confirmBtn.Enabled = $true
            $disableBtn.Enabled = $true
        }
    }
})

# Event Click Disable
$disableBtn.Add_Click({
    $ans = [System.Windows.Forms.MessageBox]::Show(
        "Bạn có chắc chắn muốn TẮT Auto Pay?`n`nMinecraft sẽ được đóng và mở lại mà không gửi lệnh /pay nữa (No-Render vẫn được giữ nguyên).",
        "Xác nhận tắt Auto Pay",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Warning
    )

    if ($ans -eq [System.Windows.Forms.DialogResult]::Yes) {
        $confirmBtn.Enabled = $false
        $disableBtn.Enabled = $false
        $footerLbl.Text = "Dang tat Auto Pay & khoi dong lai..."
        $form.Refresh()

        try {
            $selCount = $instCountCombo.SelectedIndex + 1
            $delayVal = 25
            [int]::TryParse($delayTxt.Text.Trim(), [ref]$delayVal) | Out-Null
            Save-AutoPaySettings -TargetUser $userTxt.Text.Trim() -TargetAmount "1M" -Enable $false
            Save-InstanceLaunchConfig -count $selCount -delaySec $delayVal
            Restart-MinecraftCleanly
            [System.Windows.Forms.MessageBox]::Show(
                "Đã tắt Auto Pay thành công!`n`nMinecraft đang được mở lại ở trạng thái treo thường.",
                "Đã tắt Auto Pay",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Information
            )
            $form.Close()
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Lỗi: $_", "Lỗi", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            $confirmBtn.Enabled = $true
            $disableBtn.Enabled = $true
        }
    }
})

# Event Click Stop All
$stopAllBtn.Add_Click({
    $ans = [System.Windows.Forms.MessageBox]::Show(
        "Bạn có chắc chắn muốn DỪNG TẤT CẢ các Instance Minecraft đang chạy không?",
        "Xác nhận dừng tất cả",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Question
    )
    if ($ans -eq [System.Windows.Forms.DialogResult]::Yes) {
        $watchdogProcs = Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object { $_.CommandLine -like "*watchdog*" }
        if ($watchdogProcs) {
            $watchdogProcs | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
        }
        $mcProcs = Get-Process -Name "javaw","java" -ErrorAction SilentlyContinue
        if ($mcProcs) {
            $mcProcs | Stop-Process -Force -ErrorAction SilentlyContinue
        }
        [System.Windows.Forms.MessageBox]::Show(
            "Đã dừng tất cả các bot Minecraft thành công!",
            "Hoàn tất",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )
        $footerLbl.Text = "Da dung tat ca Instance thanh cong!"
        $footerLbl.ForeColor = [System.Drawing.Color]::FromArgb(243, 139, 168)
    }
})

# Show Dialog
try {
    [System.Windows.Forms.Application]::EnableVisualStyles()
    $form.ShowDialog() | Out-Null
} catch {
    [System.Windows.Forms.MessageBox]::Show("Loi khi mo ung dung: $_", "Loi", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
} finally {
    $form.Dispose()
}
