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

# Ensure accounts.json is restored from backup if missing
$prismAccFile = Join-Path $PrismDir "accounts.json"
if (-not (Test-Path $prismAccFile) -or ((Get-Item $prismAccFile).Length -lt 60)) {
    $bkps = @("C:\accounts_backup.json", (Join-Path $env:USERPROFILE "accounts_backup.json"), (Join-Path $env:TEMP "accounts_backup.json"))
    foreach ($b in $bkps) {
        if ((Test-Path $b) -and ((Get-Item $b).Length -gt 60)) {
            try {
                $bText = [System.IO.File]::ReadAllText($b)
                if ($bText -match '"profile"' -or ($bText -match '"accounts"' -and $bText.Length -gt 100)) {
                    Copy-Item -Path $b -Destination $prismAccFile -Force
                    break
                }
            } catch {}
        }
    }
}

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

function Patch-BeatrixZip([string]$ZipPath) {
    if (-not (Test-Path $ZipPath) -or ((Get-Item $ZipPath).Length -lt 1000000)) { return }
    try {
        Add-Type -AssemblyName System.IO.Compression -ErrorAction SilentlyContinue
        Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue
        $fullPath = (Resolve-Path $ZipPath).Path
        $z = [System.IO.Compression.ZipFile]::Open($fullPath, [System.IO.Compression.ZipArchiveMode]::Update)
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
    $ms.WriteByte(10) # TAG_Compound "keybind"
    $kb = [System.Text.Encoding]::UTF8.GetBytes("keybind")
    Write-U16 $kb.Length
    $ms.Write($kb, 0, $kb.Length)
    Write-TagByte "isKey" 1
    Write-TagInt "value" 96
    Write-TagInt "modifiers" 0
    $ms.WriteByte(0) # TAG_End
    Write-TagByte "toggleOnKeyRelease" 0
    Write-TagByte "chatFeedback" 0
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
    $spamRawBytes = $spamStandaloneMs.ToArray()
    $spamGzBytes = Compress-GZipBytes -Data $spamRawBytes
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

# CRUCIAL: Meteor Client System.load calls NbtIo.read(Path) which expects RAW UNCOMPRESSED NBT!
$finalRawModules = $rootMs.ToArray()

$payCfgObj = @{
    user = $PayUser
    amount = $PayAmount
    enabled = $EnableAutoPay
    updated = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
}
$payJson = $payCfgObj | ConvertTo-Json -Compress

# Standardized options matching other running VPS
$optionsLines = @(
    "version:4671",
    "ao:false",
    "biomeBlendRadius:0",
    "chunkSectionFadeInTime:0.0",
    "cutoutLeaves:false",
    "enableVsync:false",
    "entityDistanceScaling:0.5",
    "entityShadows:false",
    "forceUnicodeFont:false",
    "japaneseGlyphVariants:false",
    "fov:0.325",
    "fovEffectScale:1.0",
    "darknessEffectScale:1.0",
    "glintSpeed:0.5",
    "glintStrength:0.75",
    'graphicsPreset:"fast"',
    "prioritizeChunkUpdates:0",
    "fullscreen:false",
    "gamma:0.5",
    "guiScale:0",
    "maxAnisotropyBit:1",
    "textureFiltering:1",
    "maxFps:120",
    "improvedTransparency:false",
    'inactivityFpsLimit:"afk"',
    "mipmapLevels:0",
    "narrator:0",
    "particles:2",
    "reducedDebugInfo:false",
    'renderClouds:"false"',
    "cloudRange:0",
    "renderDistance:32",
    "simulationDistance:32",
    "screenEffectScale:1.0",
    'soundDevice:""',
    "vignette:true",
    "weatherRadius:10",
    "autoJump:false",
    "rotateWithMinecart:false",
    "operatorItemsTab:false",
    "autoSuggestions:true",
    "chatColors:true",
    "chatLinks:true",
    "chatLinksPrompt:true",
    "discrete_mouse_scroll:false",
    "invertXMouse:false",
    "invertYMouse:false",
    "realmsNotifications:true",
    "showSubtitles:false",
    "directionalAudio:false",
    "touchscreen:false",
    "bobView:true",
    "toggleCrouch:false",
    "toggleSprint:false",
    "toggleAttack:false",
    "toggleUse:false",
    "sprintWindow:7",
    "darkMojangStudiosBackground:false",
    "hideLightningFlashes:false",
    "hideSplashTexts:false",
    "mouseSensitivity:0.5",
    "damageTiltStrength:1.0",
    "highContrast:false",
    "highContrastBlockOutline:false",
    "narratorHotkey:true",
    'resourcePacks:["vanilla","file/beatrix_shop.zip"]',
    'incompatibleResourcePacks:[]',
    "lastServer:",
    "lang:en_us",
    "chatVisibility:0",
    "chatOpacity:1.0",
    "chatLineSpacing:0.0",
    "textBackgroundOpacity:0.5",
    "backgroundForChatOnly:true",
    "hideServerAddress:false",
    "advancedItemTooltips:false",
    "pauseOnLostFocus:true",
    "overrideWidth:0",
    "overrideHeight:0",
    "chatHeightFocused:1.0",
    "chatDelay:0.0",
    "chatHeightUnfocused:0.4375",
    "chatScale:1.0",
    "chatWidth:1.0",
    "notificationDisplayTime:1.0",
    "useNativeTransport:true",
    'mainHand:"right"',
    "attackIndicator:1",
    "tutorialStep:none",
    "mouseWheelSensitivity:1.0",
    "rawMouseInput:true",
    "allowCursorChanges:true",
    "glDebugVerbosity:1",
    "skipMultiplayerWarning:true",
    "hideMatchedNames:true",
    "joinedFirstServer:true",
    "syncChunkWrites:true",
    "showAutosaveIndicator:true",
    "allowServerListing:true",
    "onlyShowSecureChat:false",
    "saveChatDrafts:false",
    "panoramaScrollSpeed:1.0",
    "telemetryOptInExtra:false",
    "onboardAccessibility:false",
    "menuBackgroundBlurriness:5",
    "startedCleanly:true",
    'musicToast:"never"',
    'musicFrequency:"DEFAULT"',
    "key_key.attack:key.mouse.left",
    "key_key.use:key.mouse.right",
    "key_key.forward:key.keyboard.w",
    "key_key.left:key.keyboard.a",
    "key_key.back:key.keyboard.s",
    "key_key.right:key.keyboard.d",
    "key_key.jump:key.keyboard.space",
    "key_key.sneak:key.keyboard.left.shift",
    "key_key.sprint:key.keyboard.left.control",
    "key_key.drop:key.keyboard.q",
    "key_key.inventory:key.keyboard.e",
    "key_key.chat:key.keyboard.t",
    "key_key.playerlist:key.keyboard.tab",
    "key_key.pickItem:key.mouse.middle",
    "key_key.command:key.keyboard.slash",
    "key_key.socialInteractions:key.keyboard.p",
    "key_key.toggleGui:key.keyboard.f1",
    "key_key.toggleSpectatorShaderEffects:key.keyboard.f4",
    "key_key.screenshot:key.keyboard.f2",
    "key_key.togglePerspective:key.keyboard.f5",
    "key_key.smoothCamera:key.keyboard.unknown",
    "key_key.fullscreen:key.keyboard.f11",
    "key_key.spectatorOutlines:key.keyboard.unknown",
    "key_key.spectatorHotbar:key.mouse.middle",
    "key_key.swapOffhand:key.keyboard.f",
    "key_key.saveToolbarActivator:key.keyboard.c",
    "key_key.loadToolbarActivator:key.keyboard.x",
    "key_key.advancements:key.keyboard.l",
    "key_key.quickActions:key.keyboard.g",
    "key_key.debug.overlay:key.keyboard.f3",
    "key_key.debug.modifier:key.keyboard.f3",
    "key_key.hotbar.1:key.keyboard.1",
    "key_key.hotbar.2:key.keyboard.2",
    "key_key.hotbar.3:key.keyboard.3",
    "key_key.hotbar.4:key.keyboard.4",
    "key_key.hotbar.5:key.keyboard.5",
    "key_key.hotbar.6:key.keyboard.6",
    "key_key.hotbar.7:key.keyboard.7",
    "key_key.hotbar.8:key.keyboard.8",
    "key_key.hotbar.9:key.keyboard.9",
    "key_key.debug.reloadChunk:key.keyboard.a",
    "key_key.debug.showHitboxes:key.keyboard.b",
    "key_key.debug.clearChat:key.keyboard.d",
    "key_key.debug.crash:key.keyboard.c",
    "key_key.debug.showChunkBorders:key.keyboard.g",
    "key_key.debug.showAdvancedTooltips:key.keyboard.h",
    "key_key.debug.copyRecreateCommand:key.keyboard.i",
    "key_key.debug.spectate:key.keyboard.n",
    "key_key.debug.switchGameMode:key.keyboard.f4",
    "key_key.debug.debugOptions:key.keyboard.f6",
    "key_key.debug.focusPause:key.keyboard.p",
    "key_key.debug.dumpDynamicTextures:key.keyboard.s",
    "key_key.debug.reloadResourcePacks:key.keyboard.t",
    "key_key.debug.profiling:key.keyboard.l",
    "key_key.debug.copyLocation:key.keyboard.c",
    "key_key.debug.dumpVersion:key.keyboard.v",
    "key_key.debug.profilingChart:key.keyboard.1",
    "key_key.debug.fpsCharts:key.keyboard.2",
    "key_key.debug.networkCharts:key.keyboard.3",
    "key_key.meteor-client.open-gui:key.keyboard.right.shift",
    "key_key.meteor-client.open-commands:key.keyboard.period",
    "key_key.autorotate.toggle:key.keyboard.r",
    "key_key.autorotate.open_config:key.keyboard.k",
    "key_key.autosell.toggle:key.keyboard.left.bracket",
    "key_key.autosell.reconnect.toggle:key.keyboard.f6",
    "key_key.autosell.testlag:key.keyboard.f7",
    "key_key.autosell.stats.toggle:key.keyboard.f8",
    "key_key.autosell.itemcounter.toggle:key.keyboard.l",
    "key_key.entityculling.toggle:key.keyboard.unknown",
    "key_key.entityculling.toggleBoxes:key.keyboard.unknown",
    "key_key.modmenu.open_menu:key.keyboard.unknown",
    "key_iris.keybind.reload:key.keyboard.r",
    "key_iris.keybind.toggleShaders:key.keyboard.k",
    "key_iris.keybind.shaderPackSelection:key.keyboard.o",
    "key_iris.keybind.wireframe:key.keyboard.unknown",
    "soundCategory_master:0.0",
    "soundCategory_music:0.0",
    "soundCategory_record:0.0",
    "soundCategory_weather:0.0",
    "soundCategory_block:0.0",
    "soundCategory_hostile:1.0",
    "soundCategory_neutral:1.0",
    "soundCategory_player:1.0",
    "soundCategory_ambient:1.0",
    "soundCategory_voice:1.0",
    "soundCategory_ui:1.0",
    "modelPart_cape:true",
    "modelPart_jacket:true",
    "modelPart_left_sleeve:true",
    "modelPart_right_sleeve:true",
    "modelPart_left_pants_leg:true",
    "modelPart_right_pants_leg:true",
    "modelPart_hat:true"
)

$sodiumOptJson = @'
{
  "quality": {
    "weather_quality": "FAST",
    "leaves_quality": "FAST"
  },
  "performance": {
    "chunk_builder_threads": 1,
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

    # Disable mods that crash on software OpenGL or spam chat, and install force close loading screen
    $modsDirs = @(
        (Join-Path $mcDir "mods"),
        (Join-Path $instDir.FullName "mods")
    )
    foreach ($mDir in $modsDirs) {
        if (Test-Path $mDir) {
            Get-ChildItem -Path $mDir -Filter "iris-fabric*.jar" -ErrorAction SilentlyContinue | Where-Object { $_.Extension -eq ".jar" } | ForEach-Object {
                Move-Item -Path $_.FullName -Destination ($_.FullName + ".disabled") -Force -ErrorAction SilentlyContinue
            }
            Get-ChildItem -Path $mDir -Filter "opsec*.jar" -ErrorAction SilentlyContinue | Where-Object { $_.Extension -eq ".jar" } | ForEach-Object {
                Move-Item -Path $_.FullName -Destination ($_.FullName + ".disabled") -Force -ErrorAction SilentlyContinue
            }
            # Ensure forcecloseloadingscreen mod is present to skip getting stuck at "Loading terrain..."
            $fcJar = Join-Path $mDir "forcecloseloadingscreen-2.3.4.jar"
            if (-not (Test-Path $fcJar) -or ((Get-Item $fcJar).Length -lt 50000)) {
                $localFc = Join-Path $binDir "forcecloseloadingscreen-2.3.4.jar"
                if (Test-Path $localFc) {
                    Copy-Item -Path $localFc -Destination $fcJar -Force -ErrorAction SilentlyContinue
                } else {
                    $fcUrl = "https://raw.githubusercontent.com/babadz207/minecraft-vps-setup/main/bin/forcecloseloadingscreen-2.3.4.jar"
                    try { & curl.exe -k -L --connect-timeout 10 -o $fcJar $fcUrl } catch {}
                }
            }
            # Ensure latest autosell.jar from GitHub or local bin
            $asJar = Join-Path $mDir "autosell.jar"
            $latestAsSize = 49348
            if (-not (Test-Path $asJar) -or ((Get-Item $asJar).Length -ne $latestAsSize)) {
                $localAs = Join-Path $binDir "autosell.jar"
                if ((Test-Path $localAs) -and ((Get-Item $localAs).Length -eq $latestAsSize)) {
                    Copy-Item -Path $localAs -Destination $asJar -Force -ErrorAction SilentlyContinue
                } else {
                    $asUrl = "https://raw.githubusercontent.com/babadz207/minecraft-vps-setup/main/bin/autosell.jar"
                    try { & curl.exe -k -L --connect-timeout 10 -o $asJar $asUrl } catch {}
                    if (Test-Path $asJar) {
                        Copy-Item -Path $asJar -Destination (Join-Path $binDir "autosell.jar") -Force -ErrorAction SilentlyContinue
                    }
                }
            }
        }
    }

    # Sync Resource Pack: Ensure clean beatrix_shop.zip with native pack_format 75
    $rpDir = Join-Path $mcDir "resourcepacks"
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

            # Clean up old redundant/broken variations to keep folder clean and prevent Minecraft confusion
            Remove-Item -Path (Join-Path $rpDir "beatrix_shop 1.9v1.zip") -Force -ErrorAction SilentlyContinue
            Remove-Item -Path (Join-Path $rpDir "beatrix_shop 1.9v1 (1).zip") -Force -ErrorAction SilentlyContinue
            Remove-Item -Path (Join-Path $rpDir "beatrix_shop") -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    $mTargets = @(
        (Join-Path $mcDir "meteor-client"),
        (Join-Path $instDir.FullName "meteor-client")
    )

    foreach ($mTarget in $mTargets) {
        if (-not (Test-Path $mTarget)) { New-Item -ItemType Directory -Path $mTarget -Force | Out-Null }
        
        # Write UNCOMPRESSED No Render NBT to standalone module paths
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
            [System.IO.File]::WriteAllBytes($dst, $noRenderDecomp)
        }

        if ($spamRawBytes) {
            $spamDestList = @(
                (Join-Path $mTarget "modules\Spam.nbt"),
                (Join-Path $mTarget "modules\spam.nbt"),
                (Join-Path $mTarget "presets\spam.nbt"),
                (Join-Path $mTarget "presets\spam\default.nbt")
            )
            foreach ($sd in $spamDestList) {
                $sp = Split-Path -Parent $sd
                if (-not (Test-Path $sp)) { New-Item -ItemType Directory -Path $sp -Force | Out-Null }
                [System.IO.File]::WriteAllBytes($sd, $spamRawBytes)
            }
            $spamB64 = [Convert]::ToBase64String($spamGzBytes)
            [System.IO.File]::WriteAllText((Join-Path $mTarget "config spam auto pay.txt"), $spamB64, [System.Text.Encoding]::UTF8)
        }

        # Write RAW UNCOMPRESSED modules.nbt to root and profiles/default
        [System.IO.File]::WriteAllBytes((Join-Path $mTarget "modules.nbt"), $finalRawModules)
        $profDefaultDir = Join-Path $mTarget "profiles\default"
        if (-not (Test-Path $profDefaultDir)) { New-Item -ItemType Directory -Path $profDefaultDir -Force | Out-Null }
        [System.IO.File]::WriteAllBytes((Join-Path $profDefaultDir "modules.nbt"), $finalRawModules)

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

    # Ensure instance.cfg has JoinServerOnLaunch=true
    $instCfg = Join-Path $instDir.FullName "instance.cfg"
    if (Test-Path $instCfg) {
        $cText = [System.IO.File]::ReadAllText($instCfg)
        $mod = $false
        if ($cText -notmatch "JoinServerOnLaunch=true") {
            if ($cText -match "JoinServerOnLaunch=") {
                $cText = $cText -replace "JoinServerOnLaunch=[^\r\n]*", "JoinServerOnLaunch=true"
            } else {
                $cText += "`r`nJoinServerOnLaunch=true"
            }
            $mod = $true
        }
        if ($cText -notmatch "JoinServerOnLaunchAddress=donutsmp.net") {
            if ($cText -match "JoinServerOnLaunchAddress=") {
                $cText = $cText -replace "JoinServerOnLaunchAddress=[^\r\n]*", "JoinServerOnLaunchAddress=donutsmp.net"
            } else {
                $cText += "`r`nJoinServerOnLaunchAddress=donutsmp.net"
            }
            $mod = $true
        }
        if ($mod) {
            [System.IO.File]::WriteAllText($instCfg, $cText, [System.Text.Encoding]::UTF8)
        }
    }
}

# Central pay_config.json
[System.IO.File]::WriteAllText((Join-Path $BaseDir "pay_config.json"), $payJson, [System.Text.Encoding]::UTF8)
$dataDir = Join-Path $BaseDir "data"
if (-not (Test-Path $dataDir)) { New-Item -ItemType Directory -Path $dataDir -Force | Out-Null }
[System.IO.File]::WriteAllText((Join-Path $dataDir "pay_config.json"), $payJson, [System.Text.Encoding]::UTF8)

exit 0
