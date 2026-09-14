# ==============================================================================
# FIX-METEOR-CONFIG.PS1 - FIX NO RENDER, AUTO PAY SPAM & CHUNK DISTANCE
# Repository: https://github.com/babadz207/minecraft-vps-setup
# ==============================================================================
param(
    [string]$PayUser = "",
    [string]$PayAmount = "",
    [int]$RenderDistance = 32,
    [int]$SimulationDistance = 32
)

Set-ExecutionPolicy Bypass -Scope Process -Force -ErrorAction SilentlyContinue
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13

Write-Host ""
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "   METEOR CLIENT & CHUNK DISTANCE CONFIGURATION FIXER   " -ForegroundColor Yellow
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host ""

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
    $targetInstances = @(Get-ChildItem -Path $instancesDir -Directory -ErrorAction SilentlyContinue)
}
if (-not $targetInstances -or $targetInstances.Count -eq 0) {
    $targetInstances = @([PSCustomObject]@{
        Name = "VPS-AFK-1"
        FullName = (Join-Path $instancesDir "VPS-AFK-1")
    })
}

# 1. Check existing Auto Pay config
$existingPayFile = Join-Path $instancesDir "VPS-AFK-1\.minecraft\meteor-client\pay_config.json"
if (-not (Test-Path $existingPayFile)) {
    $existingPayFile = Join-Path $instancesDir "VPS-AFK-1\meteor-client\pay_config.json"
}
$curUser = ""
$curAmt = ""
if (Test-Path $existingPayFile) {
    try {
        $pj = Get-Content $existingPayFile -Raw | ConvertFrom-Json
        if ($pj.user) { $curUser = [string]$pj.user }
        if ($pj.amount) { $curAmt = [string]$pj.amount }
    } catch {}
}

if (-not [string]::IsNullOrWhiteSpace($PayUser)) {
    $curUser = $PayUser.Trim()
    if (-not [string]::IsNullOrWhiteSpace($PayAmount)) { $curAmt = $PayAmount.Trim() }
}

# Prompt if interactive and user not supplied
if ([string]::IsNullOrWhiteSpace($curUser)) {
    Write-Host "[?] Configure Auto Pay /pay command (Meteor Spam):" -ForegroundColor Yellow
    $inU = Read-Host " -> Recipient username (or press ENTER to keep disabled)"
    if (-not [string]::IsNullOrWhiteSpace($inU)) {
        $curUser = $inU.Trim()
        $inA = Read-Host " -> Amount to pay $curUser (e.g. 10, 500k, 1M, 2M)"
        if (-not [string]::IsNullOrWhiteSpace($inA)) { $curAmt = $inA.Trim() } else { $curAmt = "1M" }
    }
}

$enablePay = (-not [string]::IsNullOrWhiteSpace($curUser)) -and (-not [string]::IsNullOrWhiteSpace($curAmt))
$payCmd = if ($enablePay) { "/pay $curUser $curAmt" } else { "" }

Write-Host ""
Write-Host "[+] Target Settings:" -ForegroundColor Green
Write-Host "  - No Render       : ACTIVE (All animations/particles/entities hidden)" -ForegroundColor White
if ($enablePay) {
    Write-Host "  - Auto Pay (Spam) : ACTIVE ($payCmd | Delay: 400 ticks / 20s)" -ForegroundColor White
} else {
    Write-Host "  - Auto Pay (Spam) : DISABLED" -ForegroundColor DarkGray
}
Write-Host "  - Render Distance : $RenderDistance Chunks (Farm machines loaded)" -ForegroundColor White
Write-Host "  - Simulation Dist : $SimulationDistance Chunks (Farm ticking enabled)" -ForegroundColor White
Write-Host ""

# 2. Stop running Minecraft instances to prevent RAM overwrite on exit
Write-Host "[1/4] Closing running Minecraft instances..." -ForegroundColor Yellow
$procs = @("javaw", "java")
foreach ($p in $procs) {
    Get-Process -Name $p -ErrorAction SilentlyContinue | ForEach-Object {
        try { Stop-Process -Id $_.Id -Force } catch {}
    }
}
Start-Sleep -Milliseconds 800

# 3. Helper functions for NBT construction
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
        $ms.WriteByte(8); $nb = [System.Text.Encoding]::UTF8.GetBytes($name); Write-U16 $nb.Length; $ms.Write($nb, 0, $nb.Length); $vb = [System.Text.Encoding]::UTF8.GetBytes($val); Write-U16 $vb.Length; $ms.Write($vb, 0, $vb.Length)
    }
    function Write-TagByte([string]$name, [byte]$val) {
        $ms.WriteByte(1); $nb = [System.Text.Encoding]::UTF8.GetBytes($name); Write-U16 $nb.Length; $ms.Write($nb, 0, $nb.Length); $ms.WriteByte($val)
    }
    function Write-TagInt([string]$name, [int]$val) {
        $ms.WriteByte(3); $nb = [System.Text.Encoding]::UTF8.GetBytes($name); Write-U16 $nb.Length; $ms.Write($nb, 0, $nb.Length); Write-I32 $val
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

# 4. Build NBT
Write-Host "[2/4] Generating optimized Meteor modules.nbt..." -ForegroundColor Yellow
$noRenderGzB64 = "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"
$noRenderBytes = [Convert]::FromBase64String($noRenderGzB64)
$noRenderDecomp = Decompress-GZipBytes -Data $noRenderBytes
$noRenderCompBytes = New-Object byte[] ($noRenderDecomp.Length - 19)
[Array]::Copy($noRenderDecomp, 18, $noRenderCompBytes, 0, $noRenderCompBytes.Length)

$moduleCount = 1
$spamCompBytes = $null
$spamGzBytes = $null
if ($enablePay) {
    $moduleCount = 2
    $spamCompBytes = Build-SpamNbtBytes -PayCommand $payCmd -Delay 400
    $spamStandaloneMs = New-Object System.IO.MemoryStream
    $spamStandaloneMs.WriteByte(10); $spamStandaloneMs.WriteByte(0); $spamStandaloneMs.WriteByte(0)
    $spamStandaloneMs.Write($spamCompBytes, 0, $spamCompBytes.Length)
    $spamGzBytes = Compress-GZipBytes -Data ($spamStandaloneMs.ToArray())
}

$rootMs = New-Object System.IO.MemoryStream
$rootMs.WriteByte(10) # TAG_Compound
$rootMs.WriteByte(0); $rootMs.WriteByte(0) # empty name
$rootMs.WriteByte(9)  # TAG_List
$rootMs.WriteByte(0); $rootMs.WriteByte(7) # length 7
$rootMs.Write([System.Text.Encoding]::UTF8.GetBytes("modules"), 0, 7)
$rootMs.WriteByte(10) # TAG_Compound
$rootMs.WriteByte([byte](($moduleCount -shr 24) -band 0xFF))
$rootMs.WriteByte([byte](($moduleCount -shr 16) -band 0xFF))
$rootMs.WriteByte([byte](($moduleCount -shr 8) -band 0xFF))
$rootMs.WriteByte([byte]($moduleCount -band 0xFF))
$rootMs.Write($noRenderCompBytes, 0, $noRenderCompBytes.Length)
if ($moduleCount -eq 2 -and $spamCompBytes) {
    $rootMs.Write($spamCompBytes, 0, $spamCompBytes.Length)
}
$rootMs.WriteByte(0) # TAG_End
$finalGzModules = Compress-GZipBytes -Data ($rootMs.ToArray())

# 5. Write to ALL meteor directories across all instances
Write-Host "[3/4] Writing configuration to all instances..." -ForegroundColor Yellow
foreach ($inst in $targetInstances) {
    # Target BOTH paths: .minecraft\meteor-client AND root meteor-client
    $mDirs = @(
        (Join-Path $inst.FullName ".minecraft\meteor-client"),
        (Join-Path $inst.FullName "meteor-client")
    )
    foreach ($mDir in $mDirs) {
        if (-not (Test-Path $mDir)) { New-Item -ItemType Directory -Path $mDir -Force | Out-Null }

        # Standalone No Render files
        $noRenderDestList = @(
            (Join-Path $mDir "modules\No Render.nbt"),
            (Join-Path $mDir "modules\no-render.nbt"),
            (Join-Path $mDir "presets\no-render.nbt"),
            (Join-Path $mDir "presets\no-render\default.nbt")
        )
        foreach ($nd in $noRenderDestList) {
            $np = Split-Path -Parent $nd
            if (-not (Test-Path $np)) { New-Item -ItemType Directory -Path $np -Force | Out-Null }
            [System.IO.File]::WriteAllBytes($nd, $noRenderBytes)
        }

        # Standalone Spam files
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

        # Root modules.nbt
        [System.IO.File]::WriteAllBytes((Join-Path $mDir "modules.nbt"), $finalGzModules)

        # pay_config.json
        $payJson = @{
            user = $curUser
            amount = $curAmt
            enabled = $enablePay
            updated = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        } | ConvertTo-Json -Compress
        [System.IO.File]::WriteAllText((Join-Path $mDir "pay_config.json"), $payJson, [System.Text.Encoding]::UTF8)
    }

    # 5.5. Ensure iris-fabric-1.10.7+mc1.21.11.jar is present to eliminate screen flickering / nhap nhay
    $modsDirs = @(
        (Join-Path $inst.FullName ".minecraft\mods"),
        (Join-Path $inst.FullName "mods")
    )
    foreach ($md in $modsDirs) {
        if (Test-Path (Split-Path -Parent $md)) {
            if (-not (Test-Path $md)) { New-Item -ItemType Directory -Path $md -Force | Out-Null }
            $irisFile = Join-Path $md "iris-fabric-1.10.7+mc1.21.11.jar"
            if (-not (Test-Path $irisFile) -or ((Get-Item $irisFile).Length -lt 1000000)) {
                Write-Host "  -> Restoring missing Iris mod to eliminate screen flickering..." -ForegroundColor Yellow
                $irisUrl = "https://raw.githubusercontent.com/babadz207/minecraft-vps-setup/main/bin/iris-fabric-1.10.7%2Bmc1.21.11.jar"
                try {
                    & curl.exe -k -L --connect-timeout 10 -o $irisFile $irisUrl
                } catch {}
                if (-not (Test-Path $irisFile) -or ((Get-Item $irisFile).Length -lt 1000000)) {
                    # Fallback Google Drive
                    & curl.exe -k -L --connect-timeout 10 -o $irisFile "https://drive.usercontent.google.com/download?id=1F31AM0IZbbw5bnVz4T7MrYvItrM2HLd0&export=download&confirm=t"
                }
                if (Test-Path $irisFile) {
                    Write-Host "  -> [OK] Iris Shader companion mod restored (flickering fixed)!" -ForegroundColor Green
                }
            }
            $autoSellFile = Join-Path $md "autosell.jar"
            if (-not (Test-Path $autoSellFile) -or ((Get-Item $autoSellFile).Length -ne 48776)) {
                Write-Host "  -> Updating to latest autosell.jar..." -ForegroundColor Yellow
                $asUrl = "https://raw.githubusercontent.com/babadz207/minecraft-vps-setup/main/bin/autosell.jar"
                try {
                    & curl.exe -k -L --connect-timeout 10 -o $autoSellFile $asUrl
                } catch {}
                if (-not (Test-Path $autoSellFile) -or ((Get-Item $autoSellFile).Length -lt 40000)) {
                    & curl.exe -k -L --connect-timeout 10 -o $autoSellFile "https://drive.usercontent.google.com/download?id=1MdbtjTgnxfy81LnO9LkcszCjt8f05z4u&export=download&confirm=t"
                }
                if (Test-Path $autoSellFile) {
                    Write-Host "  -> [OK] Latest autosell.jar updated successfully!" -ForegroundColor Green
                }
            }
        }
    }

    # 6. Update options.txt in BOTH .minecraft and root
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
        $optMap["renderDistance"] = "$RenderDistance"
        $optMap["simulationDistance"] = "$SimulationDistance"
        $optMap["maxFps"] = "260"
        $optMap["enableVsync"] = "false"
        $optMap["entityDistanceScaling"] = "0.5"
        $optMap["pauseOnLostFocus"] = "false"
        $optMap["clouds"] = "0"
        $optMap["renderClouds"] = "false"
        
        $lines = @()
        foreach ($k in $optMap.Keys) {
            $lines += "$k`:$($optMap[$k])"
        }
        [System.IO.File]::WriteAllLines($optPath, $lines, [System.Text.Encoding]::UTF8)
    }

    Write-Host "  -> Updated: $($inst.Name)" -ForegroundColor Green
}

# 7. Relaunch Minecraft
Write-Host "[4/4] Starting Minecraft with new settings..." -ForegroundColor Yellow
$watchdogBat = Join-Path $BaseDir "run-watchdog.bat"
$watchdogExe = Join-Path $BaseDir "bin\WatchdogUI.exe"
if (Test-Path $watchdogExe) {
    Start-Process -FilePath $watchdogExe -WorkingDirectory $BaseDir
    Write-Host "[OK] Watchdog launched!" -ForegroundColor Green
} elseif (Test-Path $watchdogBat) {
    Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$watchdogBat`"" -WorkingDirectory $BaseDir -WindowStyle Hidden
    Write-Host "[OK] Watchdog launched (bat)!" -ForegroundColor Green
} else {
    $prismExe = Join-Path $PrismDir "prismlauncher.exe"
    if (Test-Path $prismExe) {
        Start-Process -FilePath $prismExe -ArgumentList "--launch VPS-AFK-1 --server donutsmp.net" -WorkingDirectory $PrismDir
        Write-Host "[OK] Prism Launcher launched!" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "========================================================" -ForegroundColor Green
Write-Host "   ALL SETTINGS SUCCESSFULLY APPLIED & PERSISTED!       " -ForegroundColor Green
Write-Host "========================================================" -ForegroundColor Green
Write-Host " - No Render       : [ON] (Items, blocks, mobs hidden)" -ForegroundColor White
Write-Host " - Spam (Auto Pay) : [$(if ($enablePay){'ON'}else{'OFF'})] $($payCmd)" -ForegroundColor White
Write-Host " - Render Distance : $RenderDistance Chunks (Farm loaded)" -ForegroundColor White
Write-Host " - Simulation Dist : $SimulationDistance Chunks (Farm ticking)" -ForegroundColor White
Write-Host ""
