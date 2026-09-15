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
    'resourcePacks:["vanilla","file/beatrix_shop 1.9v1 (1).zip","file/beatrix_shop 1.9v1.zip","file/beatrix_shop.zip"]',
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

    # Sync Resource Pack: Ensure all 3 variations exist and are patched with format 75
    $rpDir = Join-Path $mcDir "resourcepacks"
    if (Test-Path $rpDir) {
        $zipPacks = @(
            Join-Path $rpDir "beatrix_shop 1.9v1 (1).zip",
            Join-Path $rpDir "beatrix_shop 1.9v1.zip",
            Join-Path $rpDir "beatrix_shop.zip"
        )
        $sourceZip = $null
        foreach ($zp in $zipPacks) {
            if ((Test-Path $zp) -and ((Get-Item $zp).Length -gt 10000000)) {
                $sourceZip = $zp
                break
            }
        }
        if ($sourceZip) {
            foreach ($zp in $zipPacks) {
                if (-not (Test-Path $zp)) { Copy-Item -Path $sourceZip -Destination $zp -Force }
                Patch-BeatrixZip $zp
            }
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
