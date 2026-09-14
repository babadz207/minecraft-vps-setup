# sync-configs.ps1 - Fast Pre-Launch Configuration Sync for Minecraft VPS
# Ensures 32-chunk render, 120 FPS, VSync ON, No-Render, and Spam Auto Pay are ALWAYS active
param(
    [string]$BaseDir = "C:\MinecraftVPS"
)

$ErrorActionPreference = "SilentlyContinue"

if (-not (Test-Path $BaseDir)) {
    if ($MyInvocation.MyCommand.Path) {
        $ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
        $candidate = Split-Path -Parent $ScriptDir
        if (Test-Path (Join-Path $candidate "PrismLauncher")) { $BaseDir = $candidate }
    }
}

$PrismDir = Join-Path $BaseDir "PrismLauncher"
$InstancesDir = Join-Path $PrismDir "instances"
if (-not (Test-Path $InstancesDir)) { exit 0 }

# 1. Read Auto Pay configuration
$payCfgFiles = @(
    (Join-Path $BaseDir "pay_config.json"),
    (Join-Path $BaseDir "data\pay_config.json"),
    (Join-Path $InstancesDir "VPS-AFK-1\.minecraft\meteor-client\pay_config.json"),
    (Join-Path $InstancesDir "VPS-AFK-1\meteor-client\pay_config.json")
)

$PayUser = ""
$PayAmount = ""
$EnableAutoPay = $false

foreach ($cf in $payCfgFiles) {
    if (Test-Path $cf) {
        try {
            $pObj = Get-Content $cf -Raw | ConvertFrom-Json
            if ($pObj.user) {
                $PayUser = [string]$pObj.user
                $PayAmount = if ($pObj.amount) { [string]$pObj.amount } else { "1M" }
                $EnableAutoPay = [bool]$pObj.enabled
                break
            }
        } catch {}
    }
}

$AutoPayCmd = ""
if ($EnableAutoPay -and (-not [string]::IsNullOrWhiteSpace($PayUser))) {
    if ([string]::IsNullOrWhiteSpace($PayAmount)) { $PayAmount = "1M" }
    $AutoPayCmd = "/pay $PayUser $PayAmount"
}

# 2. Base64 No-Render GZip payload
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
        $ms.WriteByte(8); $nb = [System.Text.Encoding]::UTF8.GetBytes($name); Write-U16 $nb.Length; $ms.Write($nb, 0, $nb.Length); $vb = [System.Text.Encoding]::UTF8.GetBytes($val); Write-U16 $vb.Length; $ms.Write($vb, 0, $vb.Length)
    }
    function Write-TagByte([string]$name, [byte]$val) {
        $ms.WriteByte(1); $nb = [System.Text.Encoding]::UTF8.GetBytes($name); Write-U16 $nb.Length; $ms.Write($nb, 0, $nb.Length); $ms.WriteByte($val)
    }
    function Write-TagInt([string]$name, [int]$val) {
        $ms.WriteByte(3); $nb = [System.Text.Encoding]::UTF8.GetBytes($name); Write-U16 $nb.Length; $ms.Write($nb, 0, $nb.Length); Write-I32 $val
    }

    Write-TagString "name" "spam"
    $ms.WriteByte(10) # TAG_Compound "keybind"
    $kb = [System.Text.Encoding]::UTF8.GetBytes("keybind")
    Write-U16 $kb.Length
    $ms.Write($kb, 0, $kb.Length)
    Write-TagByte "isKey" 1
    Write-TagInt "value" 96
    $ms.WriteByte(0) # TAG_End
    Write-TagByte "toggleOnKeyRelease" 0
    Write-TagByte "chatFeedback" 1
    Write-TagByte "favorite" 0

    $ms.WriteByte(10) # TAG_Compound "settings"
    $sb = [System.Text.Encoding]::UTF8.GetBytes("settings")
    Write-U16 $sb.Length
    $ms.Write($sb, 0, $sb.Length)

    $ms.WriteByte(9) # TAG_List "groups"
    $gb = [System.Text.Encoding]::UTF8.GetBytes("groups")
    Write-U16 $gb.Length
    $ms.Write($gb, 0, $gb.Length)
    $ms.WriteByte(10) # List element type = TAG_Compound
    Write-I32 1 # 1 group
    Write-TagString "name" "General"
    Write-TagByte "sectionExpanded" 1

    $ms.WriteByte(9) # TAG_List "settings"
    $stb = [System.Text.Encoding]::UTF8.GetBytes("settings")
    Write-U16 $stb.Length
    $ms.Write($stb, 0, $stb.Length)
    $ms.WriteByte(10) # List element type = TAG_Compound
    Write-I32 7 # 7 settings

    # 1. messages
    Write-TagString "name" "messages"
    $ms.WriteByte(9); $vb = [System.Text.Encoding]::UTF8.GetBytes("value"); Write-U16 $vb.Length; $ms.Write($vb, 0, $vb.Length)
    $ms.WriteByte(8); Write-I32 1
    $msgBytes = [System.Text.Encoding]::UTF8.GetBytes($PayCommand)
    Write-U16 $msgBytes.Length; $ms.Write($msgBytes, 0, $msgBytes.Length)
    $ms.WriteByte(0)

    # 2. delay
    Write-TagString "name" "delay"; Write-TagInt "value" $Delay; $ms.WriteByte(0)

    # 3. disable-on-leave
    Write-TagString "name" "disable-on-leave"; Write-TagByte "value" 0; $ms.WriteByte(0)

    # 4. disable-on-disconnect
    Write-TagString "name" "disable-on-disconnect"; Write-TagByte "value" 0; $ms.WriteByte(0)

    # 5. randomise
    Write-TagString "name" "randomise"; Write-TagByte "value" 0; $ms.WriteByte(0)

    # 6. auto-split-messages
    Write-TagString "name" "auto-split-messages"; Write-TagByte "value" 0; $ms.WriteByte(0)

    # 7. bypass
    Write-TagString "name" "bypass"; Write-TagByte "value" 0; $ms.WriteByte(0)

    $ms.WriteByte(0) # end group settings
    $ms.WriteByte(0) # end General group
    Write-TagByte "active" 1
    $ms.WriteByte(0) # end module
    return $ms.ToArray()
}

# 3. Prepare NBT payloads
$noRenderBytes = [Convert]::FromBase64String($noRenderGzB64)
$noRenderDecomp = Decompress-GZipBytes -Data $noRenderBytes
$noRenderCompBytes = New-Object byte[] ($noRenderDecomp.Length - 19)
[Array]::Copy($noRenderDecomp, 18, $noRenderCompBytes, 0, $noRenderCompBytes.Length)

$moduleCount = 1
$spamCompBytes = $null
$spamGzBytes = $null

if ($EnableAutoPay -and (-not [string]::IsNullOrWhiteSpace($AutoPayCmd))) {
    $moduleCount = 2
    $spamCompBytes = Build-SpamNbtBytes -PayCommand $AutoPayCmd -Delay 400
    $spamStandaloneMs = New-Object System.IO.MemoryStream
    $spamStandaloneMs.WriteByte(10)
    $spamStandaloneMs.WriteByte(0); $spamStandaloneMs.WriteByte(0)
    $spamStandaloneMs.Write($spamCompBytes, 0, $spamCompBytes.Length)
    $spamGzBytes = Compress-GZipBytes -Data ($spamStandaloneMs.ToArray())
}

$rootMs = New-Object System.IO.MemoryStream
$rootMs.WriteByte(10) # TAG_Compound
$rootMs.WriteByte(0); $rootMs.WriteByte(0) # empty name
$rootMs.WriteByte(9)  # TAG_List
$rootMs.WriteByte(0); $rootMs.WriteByte(7) # length = 7
$rootMs.Write([System.Text.Encoding]::UTF8.GetBytes("modules"), 0, 7) # "modules"
$rootMs.WriteByte(10) # TAG_Compound
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

$payCfgObj = @{
    user = $PayUser
    amount = $PayAmount
    enabled = $EnableAutoPay
    updated = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
}
$payJson = $payCfgObj | ConvertTo-Json -Compress

# Standardized options matching other running VPS
$optionsLines = @(
    "version:3955",
    "graphicsMode:0",
    "renderDistance:32",
    "simulationDistance:32",
    "maxFps:120",
    "enableVsync:true",
    "guiScale:0",
    "fullscreen:false",
    "entityDistanceScaling:0.5",
    "particles:2",
    "clouds:0",
    "soundCategory_master:0.0",
    "soundCategory_music:0.0",
    "soundCategory_ambient:0.0",
    "soundCategory_weather:0.0",
    "soundCategory_block:0.0",
    "soundCategory_hostile:0.0",
    "soundCategory_neutral:0.0",
    "soundCategory_player:0.0",
    "soundCategory_record:0.0",
    "soundCategory_voice:0.0",
    "pauseOnLostFocus:false",
    "fov:30.0",
    "gamma:1.0",
    "renderClouds:false",
    'resourcePacks:["vanilla","file/beatrix_shop 1.9v1.zip"]',
    'incompatibleResourcePacks:["file/beatrix_shop 1.9v1.zip"]'
)

$sodiumOptJson = @'
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

$serversDatB64 = "CgAACQAHc2VydmVycwoAAAABCAACaXAADGRvbnV0c21wLm5ldAgABG5hbWUACERvbnV0U01QAQAOYWNjZXB0VGV4dHVyZXMBAAA="

# 4. Sync each instance
$instDirs = Get-ChildItem -Path $InstancesDir -Directory -ErrorAction SilentlyContinue
foreach ($instDir in $instDirs) {
    $mcDir = Join-Path $instDir.FullName ".minecraft"
    if (-not (Test-Path $mcDir)) { continue }

    $mTargets = @(
        (Join-Path $mcDir "meteor-client"),
        (Join-Path $instDir.FullName "meteor-client")
    )

    foreach ($mTarget in $mTargets) {
        if (-not (Test-Path $mTarget)) { New-Item -ItemType Directory -Path $mTarget -Force | Out-Null }
        
        $destList = @(
            (Join-Path $mTarget "modules\No Render.nbt"),
            (Join-Path $mTarget "modules\no-render.nbt"),
            (Join-Path $mTarget "presets\no-render.nbt"),
            (Join-Path $mTarget "presets\no-render\default.nbt"),
            (Join-Path $mTarget "no-render.nbt")
        )
        foreach ($dst in $destList) {
            $p = Split-Path -Parent $dst
            if (-not (Test-Path $p)) { New-Item -ItemType Directory -Path $p -Force | Out-Null }
            [System.IO.File]::WriteAllBytes($dst, $noRenderBytes)
        }

        if ($spamGzBytes) {
            $spamDestList = @(
                (Join-Path $mTarget "modules\Spam.nbt"),
                (Join-Path $mTarget "modules\spam.nbt"),
                (Join-Path $mTarget "presets\spam.nbt"),
                (Join-Path $mTarget "presets\spam\default.nbt")
            )
            foreach ($sd in $spamDestList) {
                $sp = Split-Path -Parent $sd
                if (-not (Test-Path $sp)) { New-Item -ItemType Directory -Path $sp -Force | Out-Null }
                [System.IO.File]::WriteAllBytes($sd, $spamGzBytes)
            }
            $spamB64 = [Convert]::ToBase64String($spamGzBytes)
            [System.IO.File]::WriteAllText((Join-Path $mTarget "config spam auto pay.txt"), $spamB64, [System.Text.Encoding]::UTF8)
        }

        [System.IO.File]::WriteAllBytes((Join-Path $mTarget "modules.nbt"), $finalGzModules)
        [System.IO.File]::WriteAllText((Join-Path $mTarget "pay_config.json"), $payJson, [System.Text.Encoding]::UTF8)
    }

    # Write options.txt to .minecraft and instance root
    $optMc = Join-Path $mcDir "options.txt"
    $optInst = Join-Path $instDir.FullName "options.txt"
    [System.IO.File]::WriteAllLines($optMc, $optionsLines, [System.Text.Encoding]::UTF8)
    [System.IO.File]::WriteAllLines($optInst, $optionsLines, [System.Text.Encoding]::UTF8)

    # Write sodium-options.json
    $cfgDir = Join-Path $mcDir "config"
    if (-not (Test-Path $cfgDir)) { New-Item -ItemType Directory -Path $cfgDir -Force | Out-Null }
    [System.IO.File]::WriteAllText((Join-Path $cfgDir "sodium-options.json"), $sodiumOptJson, [System.Text.Encoding]::UTF8)

    # Write servers.dat if missing
    $sDat = Join-Path $mcDir "servers.dat"
    if (-not (Test-Path $sDat)) {
        [System.IO.File]::WriteAllBytes($sDat, [Convert]::FromBase64String($serversDatB64))
    }
}

# Central pay_config.json
[System.IO.File]::WriteAllText((Join-Path $BaseDir "pay_config.json"), $payJson, [System.Text.Encoding]::UTF8)
$dataDir = Join-Path $BaseDir "data"
if (-not (Test-Path $dataDir)) { New-Item -ItemType Directory -Path $dataDir -Force | Out-Null }
[System.IO.File]::WriteAllText((Join-Path $dataDir "pay_config.json"), $payJson, [System.Text.Encoding]::UTF8)

exit 0
