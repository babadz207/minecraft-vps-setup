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
            $optMap["resourcePacks"] = '["vanilla","file/beatrix_shop.zip"]'
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
