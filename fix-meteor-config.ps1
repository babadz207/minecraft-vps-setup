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

function Patch-BeatrixZip([string]$ZipPath) {
    if (-not (Test-Path $ZipPath) -or ((Get-Item $ZipPath).Length -lt 1000000)) { return }
    try {
        Add-Type -AssemblyName System.IO.Compression -ErrorAction SilentlyContinue
        Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue
        $z = [System.IO.Compression.ZipFile]::Open($ZipPath, [System.IO.Compression.ZipArchiveMode]::Update)
        $entry = $z.GetEntry("pack.mcmeta")
        $needPatch = $true
        if ($entry) {
            try {
                $sr = New-Object System.IO.StreamReader($entry.Open(), [System.Text.Encoding]::UTF8)
                $txt = $sr.ReadToEnd()
                $sr.Dispose()
                if ($txt -match '"pack_format":\s*75' -and -not ($txt -match 'overlays') -and ($txt -match '"min_format":\s*1')) {
                    $needPatch = $false
                }
            } catch {}
        }
        if ($needPatch) {
            if ($entry) { $entry.Delete() }
            $newE = $z.CreateEntry("pack.mcmeta")
            $stream = $newE.Open()
            $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
            $writer = New-Object System.IO.StreamWriter($stream, $utf8NoBom)
            $meta = @'
{
  "pack": {
    "description": [
      "",
      {"text": "beatrix_pack", "bold": true, "color": "#FFFF00"},
      {"text": " V1.9", "bold": true, "color": "#FFFFFF"},
      {"text": " | ", "color": "gray"},
      {"text": "Crystal", "color": "#FF003D"},
      {"text": "\n"},
      {"text": "Custom by", "color": "#A565FF"},
      {"text": " beatrix_shop", "color": "#FE88FF"}
    ],
    "pack_format": 75,
    "min_format": 1,
    "max_format": 9999,
    "supported_formats": {"min_inclusive": 1, "max_inclusive": 9999}
  }
}
'@
            $writer.Write($meta)
            $writer.Flush()
            $writer.Dispose()
            $stream.Dispose()
        }
        $z.Dispose()
    } catch {}
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

# CRUCIAL: Meteor Client System.load calls NbtIo.read(Path) which expects RAW UNCOMPRESSED NBT!
$finalRawModules = $rootMs.ToArray()
$spamRawBytes = if ($spamStandaloneMs) { $spamStandaloneMs.ToArray() } else { $null }

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

        # Standalone No Render files (UNCOMPRESSED NBT)
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

        # Standalone Spam files
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

        # Root modules.nbt (RAW UNCOMPRESSED NBT)
        [System.IO.File]::WriteAllBytes((Join-Path $mDir "modules.nbt"), $finalRawModules)
        $profDefaultDir = Join-Path $mDir "profiles\default"
        if (-not (Test-Path $profDefaultDir)) { New-Item -ItemType Directory -Path $profDefaultDir -Force | Out-Null }
        [System.IO.File]::WriteAllBytes((Join-Path $profDefaultDir "modules.nbt"), $finalRawModules)

        # pay_config.json
        $payJson = @{
            user = $curUser
            amount = $curAmt
            enabled = $enablePay
            updated = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        } | ConvertTo-Json -Compress
        [System.IO.File]::WriteAllText((Join-Path $mDir "pay_config.json"), $payJson, [System.Text.Encoding]::UTF8)
    }
    [System.IO.File]::WriteAllText((Join-Path $BaseDir "pay_config.json"), $payJson, [System.Text.Encoding]::UTF8)
    $dDir = Join-Path $BaseDir "data"
    if (-not (Test-Path $dDir)) { New-Item -ItemType Directory -Path $dDir -Force | Out-Null }
    [System.IO.File]::WriteAllText((Join-Path $dDir "pay_config.json"), $payJson, [System.Text.Encoding]::UTF8)

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

            # Remove conflicting sodium-0.8.13 (breaks iris <= 1.10.7)
            Remove-Item (Join-Path $md "sodium-fabric-0.8.13*") -Force -ErrorAction SilentlyContinue

            # Ensure compatible sodium-0.8.7 is present
            $sodiumFile = Join-Path $md "sodium-fabric-0.8.7+mc1.21.11.jar"
            if (-not (Test-Path $sodiumFile) -or ((Get-Item $sodiumFile).Length -lt 1000000)) {
                Write-Host "  -> Installing compatible Sodium 0.8.7 (fixes Iris conflict)..." -ForegroundColor Yellow
                $sUrl = "https://raw.githubusercontent.com/babadz207/minecraft-vps-setup/main/bin/sodium-fabric-0.8.7%2Bmc1.21.11.jar"
                try {
                    & curl.exe -k -L --connect-timeout 10 -o $sodiumFile $sUrl
                } catch {}
                if (-not (Test-Path $sodiumFile) -or ((Get-Item $sodiumFile).Length -lt 1000000)) {
                    & curl.exe -k -L --connect-timeout 10 -o $sodiumFile "https://drive.usercontent.google.com/download?id=1GU1zQZ4XzTTSlP34NoHWCbvompxrylvH&export=download&confirm=t"
                }
                if (Test-Path $sodiumFile) {
                    Write-Host "  -> [OK] Sodium 0.8.7 installed successfully!" -ForegroundColor Green
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
        $optMap["maxFps"] = "120"
        $optMap["enableVsync"] = "true"
        $optMap["entityDistanceScaling"] = "0.5"
        $optMap["pauseOnLostFocus"] = "false"
        $optMap["clouds"] = "0"
        $optMap["renderClouds"] = "false"
        $optMap["resourcePacks"] = '["vanilla","file/beatrix_shop.zip"]'
        $optMap["incompatibleResourcePacks"] = '[]'
        $optMap["key_key.autosell.toggle"] = 'key.keyboard.left.bracket'
        
        $lines = @()
        foreach ($k in $optMap.Keys) {
            $lines += "$k`:$($optMap[$k])"
        }
        [System.IO.File]::WriteAllLines($optPath, $lines, [System.Text.Encoding]::UTF8)
    }

    # 6.4. Ensure clean beatrix_shop.zip with native pack_format 34 and clean up old variations
    $rpDir = Join-Path $inst.FullName ".minecraft\resourcepacks"
    if (Test-Path $rpDir) {
        $zipPacks = @(
            Join-Path $rpDir "beatrix_shop.zip",
            Join-Path $rpDir "beatrix_shop 1.9v1.zip",
            Join-Path $rpDir "beatrix_shop 1.9v1 (1).zip"
        )
        $sourceZip = $null
        foreach ($zp in $zipPacks) {
            if ((Test-Path $zp) -and ((Get-Item $zp).Length -gt 10000000)) {
                $sourceZip = $zp
                break
            }
        }
        if ($sourceZip) {
            $cleanZip = Join-Path $rpDir "beatrix_shop.zip"
            if ($sourceZip -ne $cleanZip) {
                Copy-Item -Path $sourceZip -Destination $cleanZip -Force
            }
            Patch-BeatrixZip $cleanZip
            Remove-Item -Path (Join-Path $rpDir "beatrix_shop 1.9v1.zip") -Force -ErrorAction SilentlyContinue
            Remove-Item -Path (Join-Path $rpDir "beatrix_shop 1.9v1 (1).zip") -Force -ErrorAction SilentlyContinue
            Remove-Item -Path (Join-Path $rpDir "beatrix_shop") -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    # 6.5. Update instance.cfg (allocate 2.5GB RAM, unlock CPU & set PreLaunchCommand guard)
    $instCfgPath = Join-Path $inst.FullName "instance.cfg"
    if (Test-Path $instCfgPath) {
        $cfgLines = Get-Content $instCfgPath
        $newCfg = @()
        $hasOverrideCmd = $false
        $hasPreLaunch = $false
        foreach ($cl in $cfgLines) {
            if ($cl -match '^MaxMemAlloc=') {
                $newCfg += "MaxMemAlloc=2560"
            } elseif ($cl -match '^MinMemAlloc=') {
                $newCfg += "MinMemAlloc=512"
            } elseif ($cl -match '^JvmArgs=') {
                $newCfg += "JvmArgs=-XX:+UseG1GC -XX:G1ReservePercent=15 -XX:MaxGCPauseMillis=100 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -Dsun.java2d.opengl=false -Dsun.java2d.d3d=false"
            } elseif ($cl -match '^OverrideCommands=') {
                $newCfg += "OverrideCommands=true"
                $hasOverrideCmd = $true
            } elseif ($cl -match '^PreLaunchCommand=') {
                $newCfg += 'PreLaunchCommand=cmd.exe /c "C:/MinecraftVPS/bin/prelaunch.bat"'
                $hasPreLaunch = $true
            } else {
                $newCfg += $cl
            }
        }
        if (-not $hasOverrideCmd) { $newCfg += "OverrideCommands=true" }
        if (-not $hasPreLaunch) { $newCfg += 'PreLaunchCommand=cmd.exe /c "C:/MinecraftVPS/bin/prelaunch.bat"' }
        [System.IO.File]::WriteAllLines($instCfgPath, $newCfg, [System.Text.Encoding]::UTF8)
    }

    # 6.6. Update sodium-options.json (Multi-thread chunk builder & disable deferral)
    $sOptFile = Join-Path (Join-Path $inst.FullName ".minecraft\config") "sodium-options.json"
    $sJson = @'
{
  "quality": {
    "weather_quality": "FAST",
    "leaves_quality": "FAST"
  },
  "performance": {
    "chunk_builder_threads": 0,
    "always_defer_chunk_updates": false,
    "animate_only_visible_textures": true
  }
}
'@
    [System.IO.File]::WriteAllText($sOptFile, $sJson, [System.Text.Encoding]::UTF8)

    Write-Host "  -> Updated: $($inst.Name) (2.5GB RAM, 4 CPU Cores, Multi-thread Chunks)" -ForegroundColor Green
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
