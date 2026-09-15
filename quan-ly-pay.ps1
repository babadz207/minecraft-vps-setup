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
    Write-TagInt "modifiers" 0
    $ms.WriteByte(0)

    Write-TagByte "toggleOnKeyRelease" 0
    Write-TagByte "chatFeedback" 0
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

    # CRUCIAL: Meteor Client System.load calls NbtIo.read(Path) which expects RAW UNCOMPRESSED NBT!
    $finalRawModules = $rootMs.ToArray()
    $spamRawBytes = if ($spamStandaloneMs) { $spamStandaloneMs.ToArray() } else { $null }

    # Ghi vao TAT CA cac Instance co san (VPS-AFK-1, VPS-AFK-2, VPS-AFK-3...)
    foreach ($inst in $targetInstances) {
        $mDirs = @(
            (Join-Path $inst.FullName ".minecraft\meteor-client"),
            (Join-Path $inst.FullName "meteor-client")
        )
        foreach ($mDir in $mDirs) {
            if (-not (Test-Path $mDir)) { New-Item -ItemType Directory -Path $mDir -Force | Out-Null }

            # Standalone no-render files (UNCOMPRESSED NBT)
            $noRenderDestList = @(
                (Join-Path $mDir "modules\No Render.nbt"),
                (Join-Path $mDir "modules\no-render.nbt"),
                (Join-Path $mDir "presets\no-render.nbt"),
                (Join-Path $mDir "presets\no-render\default.nbt")
            )
            foreach ($nd in $noRenderDestList) {
                $np = Split-Path -Parent $nd
                if (-not (Test-Path $np)) { New-Item -ItemType Directory -Path $np -Force | Out-Null }
                [System.IO.File]::WriteAllBytes($nd, $noRenderDecomp)
            }

            if ($spamRawBytes) {
                $spamDestList = @(
                    (Join-Path $mDir "modules\Spam.nbt"),
                    (Join-Path $mDir "modules\spam.nbt"),
                    (Join-Path $mDir "presets\spam.nbt"),
                    (Join-Path $mDir "presets\spam\default.nbt")
                )
                foreach ($sd in $spamDestList) {
                    $sp = Split-Path -Parent $sd
                    if (-not (Test-Path $sp)) { New-Item -ItemType Directory -Path $sp -Force | Out-Null }
                    [System.IO.File]::WriteAllBytes($sd, $spamRawBytes)
                }
                $spamB64 = [Convert]::ToBase64String($spamGzBytes)
                [System.IO.File]::WriteAllText((Join-Path $mDir "config spam auto pay.txt"), $spamB64, [System.Text.Encoding]::UTF8)
            }

            [System.IO.File]::WriteAllBytes((Join-Path $mDir "modules.nbt"), $finalRawModules)
            $profDefaultDir = Join-Path $mDir "profiles\default"
            if (-not (Test-Path $profDefaultDir)) { New-Item -ItemType Directory -Path $profDefaultDir -Force | Out-Null }
            [System.IO.File]::WriteAllBytes((Join-Path $profDefaultDir "modules.nbt"), $finalRawModules)

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

        # Update options.txt in both .minecraft and root
        $optDirs = @(
            (Join-Path $inst.FullName ".minecraft"),
            $inst.FullName
        )
        foreach ($od in $optDirs) {
            $optPath = Join-Path $od "options.txt"
            $optMap = @{}
            if (Test-Path $optPath) {
                Get-Content $optPath | ForEach-Object {
                    if ($_ -match '^([^:]+):(.*)$') {
                        $optMap[$matches[1].Trim()] = $matches[2].Trim()
                    }
                }
            }
            $optMap["renderDistance"] = "32"
            $optMap["simulationDistance"] = "32"
            $optMap["maxFps"] = "120"
            $optMap["enableVsync"] = "true"
            $optMap["resourcePacks"] = '["vanilla","file/beatrix_shop 1.9v1 (1).zip","file/beatrix_shop 1.9v1.zip","file/beatrix_shop.zip"]'
            $optMap["incompatibleResourcePacks"] = '[]'
            $optMap["key_key.autosell.toggle"] = 'key.keyboard.left.bracket'
            $lines = @()
            foreach ($k in $optMap.Keys) { $lines += "$k`:$($optMap[$k])" }
            [System.IO.File]::WriteAllLines($optPath, $lines, [System.Text.Encoding]::UTF8)
        }
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
