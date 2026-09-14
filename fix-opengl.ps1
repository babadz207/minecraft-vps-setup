# ====================================================================
# FIX GLFW ERROR 65542: INJECT MESA3D SOFTWARE OPENGL INTO PRISM & JAVA
# ====================================================================
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13

Write-Host ""
Write-Host "=== FIX GLFW ERROR 65542 (MESA3D SOFTWARE OPENGL INJECTION) ===" -ForegroundColor Yellow
Write-Host "Stopping any running Minecraft or Prism processes..." -ForegroundColor DarkGray
Stop-Process -Name "javaw", "java", "prismlauncher" -Force -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 500

$BaseDir = "C:\MinecraftVPS"
$PrismDir = Join-Path $BaseDir "PrismLauncher"
$TempDir = Join-Path $BaseDir "_temp"
if (-not (Test-Path $TempDir)) { New-Item -ItemType Directory -Path $TempDir -Force | Out-Null }

# 1. Locate or download opengl32.dll (Mesa3D llvmpipe)
$mesaDll = $null
$candidates = @(
    (Join-Path $PrismDir "opengl32.dll"),
    (Join-Path $BaseDir "opengl32.dll"),
    (Join-Path $TempDir "opengl32.dll")
)
foreach ($c in $candidates) {
    if ((Test-Path $c) -and ((Get-Item $c).Length -gt 10000000)) {
        $mesaDll = $c
        break
    }
}

if (-not $mesaDll) {
    $existing = Get-ChildItem -Path $BaseDir -Filter "opengl32.dll" -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.Length -gt 10000000 } | Select-Object -First 1
    if ($existing) { $mesaDll = $existing.FullName }
}

if (-not $mesaDll) {
    Write-Host "[+] Downloading Mesa3D Software OpenGL (llvmpipe)..." -ForegroundColor Cyan
    $mesa7z = Join-Path $TempDir "mesa-llvmpipe-clean.7z"
    $zrExe = Join-Path $TempDir "7zr.exe"
    if (-not (Test-Path $zrExe)) {
        & curl.exe -k -L -A "Mozilla/5.0" "https://www.7-zip.org/a/7zr.exe" -o "$zrExe"
    }
    $mmozeikoUrl = "https://github.com/mmozeiko/build-mesa/releases/download/26.2.2/mesa-llvmpipe-x64-26.2.2.7z"
    & curl.exe -k -L -A "Mozilla/5.0" "$mmozeikoUrl" -o "$mesa7z"
    if (Test-Path $zrExe) {
        & $zrExe e "$mesa7z" "-o$TempDir" "opengl32.dll" -r -y | Out-Null
    }
    $extracted = Join-Path $TempDir "opengl32.dll"
    if ((Test-Path $extracted) -and ((Get-Item $extracted).Length -gt 10000000)) {
        $mesaDll = $extracted
        Copy-Item -Path $extracted -Destination (Join-Path $PrismDir "opengl32.dll") -Force
    }
}

if (-not $mesaDll -or -not (Test-Path $mesaDll)) {
    Write-Host "[X] Could not find or download Mesa3D opengl32.dll!" -ForegroundColor Red
    exit 1
}

Write-Host "[OK] Using Mesa3D opengl32.dll ($([math]::Round((Get-Item $mesaDll).Length/1MB, 1)) MB)" -ForegroundColor Green

# 2. Inject opengl32.dll into ALL Java runtimes found on the system
Write-Host "[+] Scanning and injecting opengl32.dll into all Java runtimes..." -ForegroundColor Cyan
$searchRoots = @(
    $BaseDir,
    "C:\Program Files\Java",
    "C:\Program Files\Eclipse Adoptium",
    "C:\Program Files\Semeru",
    "C:\Program Files (x86)\Java",
    "$env:USERPROFILE\AppData\Local\Programs\PrismLauncher",
    "$env:LOCALAPPDATA\Programs\PrismLauncher"
)
$javaBins = @()
foreach ($root in $searchRoots) {
    if (Test-Path $root) {
        Get-ChildItem -Path $root -Filter "javaw.exe" -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
            $javaBins += $_.DirectoryName
        }
    }
}
$javaBins = $javaBins | Select-Object -Unique

foreach ($bin in $javaBins) {
    try {
        Copy-Item -Path $mesaDll -Destination (Join-Path $bin "opengl32.dll") -Force
        New-Item -ItemType File -Path (Join-Path $bin "javaw.exe.local") -Force -ErrorAction SilentlyContinue | Out-Null
        New-Item -ItemType File -Path (Join-Path $bin "java.exe.local") -Force -ErrorAction SilentlyContinue | Out-Null
        Write-Host "  -> Injected into Java: $bin" -ForegroundColor DarkGreen
    } catch {}
}

# 3. Inject opengl32.dll into ALL Prism Launcher instances (natives, .minecraft, and bin)
Write-Host "[+] Injecting opengl32.dll into all Prism Launcher instances..." -ForegroundColor Cyan
$instancesPath = Join-Path $PrismDir "instances"
if (Test-Path $instancesPath) {
    $instDirs = Get-ChildItem -Path $instancesPath -Directory -ErrorAction SilentlyContinue
    foreach ($inst in $instDirs) {
        $nat = Join-Path $inst.FullName "natives"
        $mc = Join-Path $inst.FullName ".minecraft"
        $mcBin = Join-Path $mc "bin"
        $instBin = Join-Path $inst.FullName "bin"
        New-Item -ItemType Directory -Path $nat, $mc, $mcBin, $instBin -Force -ErrorAction SilentlyContinue | Out-Null
        
        Copy-Item -Path $mesaDll -Destination (Join-Path $inst.FullName "opengl32.dll") -Force
        Copy-Item -Path $mesaDll -Destination (Join-Path $nat "opengl32.dll") -Force
        Copy-Item -Path $mesaDll -Destination (Join-Path $mc "opengl32.dll") -Force
        Copy-Item -Path $mesaDll -Destination (Join-Path $mcBin "opengl32.dll") -Force
        Copy-Item -Path $mesaDll -Destination (Join-Path $instBin "opengl32.dll") -Force
        Write-Host "  -> Injected into instance: $($inst.Name) (natives + .minecraft + bin)" -ForegroundColor DarkGreen
    }
}

# 4. Lock prismlauncher.cfg: Disable automatic Java switching
$prismCfg = Join-Path $PrismDir "prismlauncher.cfg"
if (Test-Path $prismCfg) {
    $lines = Get-Content $prismCfg
    $newLines = @()
    $hasDl = $false
    $hasSw = $false
    foreach ($l in $lines) {
        if ($l -match '^AutomaticJavaDownload=') { $newLines += "AutomaticJavaDownload=false"; $hasDl = $true; continue }
        if ($l -match '^AutomaticJavaSwitch=') { $newLines += "AutomaticJavaSwitch=false"; $hasSw = $true; continue }
        $newLines += $l
    }
    if (-not $hasDl) { $newLines += "AutomaticJavaDownload=false" }
    if (-not $hasSw) { $newLines += "AutomaticJavaSwitch=false" }
    [System.IO.File]::WriteAllLines($prismCfg, $newLines, [System.Text.Encoding]::UTF8)
    Write-Host "[+] Locked prismlauncher.cfg: AutomaticJavaSwitch=false" -ForegroundColor Green
}

Write-Host ""
Write-Host "====================================================================" -ForegroundColor Green
Write-Host " [OK] OpenGL Fix Applied Successfully!" -ForegroundColor Yellow
Write-Host " Mesa3D opengl32.dll has been injected into all Java runtimes and instance directories." -ForegroundColor White
Write-Host " You can now launch Minecraft directly from Prism Launcher without GLFW 65542 errors!" -ForegroundColor Green
Write-Host "====================================================================" -ForegroundColor Green
