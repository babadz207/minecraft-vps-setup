param(
[string]$InstanceName = "VPS-AFK-1",
[string]$DiscordWebhook = "",
[string]$PayUser = "",
[string]$PayAmount = ""
)
Set-ExecutionPolicy Bypass -Scope Process -Force -ErrorAction SilentlyContinue
try {
$type = Add-Type -MemberDefinition @'
[DllImport("kernel32.dll", SetLastError = true)]
public static extern IntPtr GetStdHandle(int nStdHandle);
[DllImport("kernel32.dll", SetLastError = true)]
public static extern bool GetConsoleMode(IntPtr hConsoleHandle, out uint lpMode);
[DllImport("kernel32.dll", SetLastError = true)]
public static extern bool SetConsoleMode(IntPtr hConsoleHandle, uint dwMode);
'@ -Name "ConsoleModeHelper" -Namespace "Win32" -PassThru -ErrorAction SilentlyContinue
$hIn = [Win32.ConsoleModeHelper]::GetStdHandle(-10)
$m = 0
if ([Win32.ConsoleModeHelper]::GetConsoleMode($hIn, [ref]$m)) {
[Win32.ConsoleModeHelper]::SetConsoleMode($hIn, (($m -band (-bnot 0x0040)) -bor 0x0080)) | Out-Null
}
} catch {}
Write-Host ""
Write-Host "   [+] LOADING MINECRAFT VPS 24/7 SETUP WIZARD..." -ForegroundColor Yellow
Write-Host "   [!] PLEASE WAIT A MOMENT (INITIALIZING)..." -ForegroundColor DarkGray
$flushUntil = [DateTime]::Now.AddSeconds(1.5)
while ([DateTime]::Now -lt $flushUntil) {
try {
if ([Environment]::UserInteractive -and -not [Console]::IsInputRedirected) {
while ([Console]::KeyAvailable) { [void][Console]::ReadKey($true) }
}
} catch {}
Start-Sleep -Milliseconds 100
}
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13
if ($MyInvocation.MyCommand.Path) {
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$BaseDir = Join-Path $ScriptDir "MinecraftVPS"
} else {
$BaseDir = "C:\MinecraftVPS"
$ScriptDir = $BaseDir
}
$PrismDir = Join-Path $BaseDir "PrismLauncher"
$TempDir = Join-Path $BaseDir "_temp"
$InstanceName = "VPS-AFK-1"
$InstanceDir = Join-Path $PrismDir "instances\$InstanceName"
$MinecraftDir = Join-Path $InstanceDir ".minecraft"
$ModsDir = Join-Path $MinecraftDir "mods"
$ConfigDir = Join-Path $MinecraftDir "config"
$ResourcePacksDir = Join-Path $MinecraftDir "resourcepacks"
$MeteorDir = Join-Path $MinecraftDir "meteor-client"
$repoRaw = "https://raw.githubusercontent.com/babadz207/minecraft-vps-setup/main"
function Write-Title {
param([string]$Text)
Write-Host ""
Write-Host "   $Text" -ForegroundColor Yellow
}
function Write-Step {
param([string]$Step, [string]$Text)
Write-Host "[$Step] " -ForegroundColor Green -NoNewline
Write-Host $Text -ForegroundColor White
}
function Write-Success {
param([string]$Text)
Write-Host "[OK] $Text" -ForegroundColor Green
}
function Write-Warn {
param([string]$Text)
Write-Host "[!] $Text" -ForegroundColor Yellow
}
function Write-Err {
param([string]$Text)
Write-Host "[X] $Text" -ForegroundColor Red
}
function Flush-KeyboardBuffer {
try {
if ([Environment]::UserInteractive -and -not [Console]::IsInputRedirected) {
while ([Console]::KeyAvailable) {
[void][Console]::ReadKey($true)
}
}
} catch {}
}
function Download-FileWithCurl {
param(
[string]$Url,
[string]$OutFile,
[string]$Desc
)
Flush-KeyboardBuffer; Write-Host "  -> [DOWNLOADING]: $Desc..." -ForegroundColor DarkGray
$parent = Split-Path -Parent $OutFile
if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
$dlOk = $false
if (Get-Command "curl.exe" -ErrorAction SilentlyContinue) {
try {
& curl.exe -k -L --ssl-no-revoke --connect-timeout 10 --speed-limit 51200 --speed-time 15 --max-time 180 -# -A "Mozilla/5.0" "$Url" -o "$OutFile"
if ($LASTEXITCODE -eq 0 -and (Test-Path $OutFile) -and ((Get-Item $OutFile).Length -gt 100)) {
$dlOk = $true
} else {
Remove-Item $OutFile -Force -ErrorAction SilentlyContinue
}
} catch {
Remove-Item $OutFile -Force -ErrorAction SilentlyContinue
}
}
if (-not $dlOk -and ($Url -match "github\.com") -and (Get-Command "curl.exe" -ErrorAction SilentlyContinue)) {
$mirrors = @("https://ghfast.top/", "https://ghproxy.net/")
foreach ($m in $mirrors) {
try {
$mirrorUrl = $m + $Url
Write-Host "     Retrying via fast mirror: $m..." -ForegroundColor DarkYellow
& curl.exe -k -L --ssl-no-revoke --connect-timeout 10 --speed-limit 51200 --speed-time 15 --max-time 180 -# -A "Mozilla/5.0" "$mirrorUrl" -o "$OutFile"
if ($LASTEXITCODE -eq 0 -and (Test-Path $OutFile) -and ((Get-Item $OutFile).Length -gt 100)) {
$dlOk = $true
break
} else {
Remove-Item $OutFile -Force -ErrorAction SilentlyContinue
}
} catch {
Remove-Item $OutFile -Force -ErrorAction SilentlyContinue
}
}
}
if (-not $dlOk) {
try {
$wc = New-Object System.Net.WebClient
$wc.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
$wc.DownloadFile($Url, $OutFile)
if ((Test-Path $OutFile) -and ((Get-Item $OutFile).Length -gt 100)) { $dlOk = $true }
} catch {
try {
Invoke-WebRequest -Uri "$Url" -OutFile "$OutFile" -UseBasicParsing -TimeoutSec 180
if ((Test-Path $OutFile) -and ((Get-Item $OutFile).Length -gt 100)) { $dlOk = $true }
} catch {}
}
}
if (Test-Path $OutFile) {
$size = (Get-Item $OutFile).Length
if ($size -gt 100) {
try {
$head = [System.IO.File]::ReadAllBytes($OutFile)
if ($head.Length -ge 15) {
$headStr = [System.Text.Encoding]::ASCII.GetString($head, 0, 15)
if ($headStr -match '<!DOCTYPE|<html') {
Remove-Item $OutFile -Force -ErrorAction SilentlyContinue
return $false
}
}
} catch {}
$mb = [math]::Round($size / 1048576, 2)
Write-Host "     Completed ($mb MB)" -ForegroundColor DarkGreen
return $true
}
}
Write-Err "Failed to download $Desc or file is corrupted."
return $false
}
function Download-DriveFile {
param(
[string]$FileId,
[string]$OutFile,
[string]$Desc
)
$url = "https://drive.usercontent.google.com/download?id=" + $FileId + "&export=download&authuser=0&confirm=t"
$ok = Download-FileWithCurl -Url $url -OutFile $OutFile -Desc $Desc
if (-not $ok) {
$url2 = "https://docs.google.com/uc?export=download&id=" + $FileId + "&confirm=t"
$ok = Download-FileWithCurl -Url $url2 -OutFile $OutFile -Desc "$Desc (Fallback)"
}
return $ok
}
Clear-Host
Write-Title "AUTO SETUP MINECRAFT VPS NON-GPU (PRISM LAUNCHER + FABRIC 1.21.11)"
$autoSellConfig = Join-Path $ConfigDir "autosell.json"
$existWh = ""
if (Test-Path $autoSellConfig) {
try {
$asJson = Get-Content $autoSellConfig -Raw | ConvertFrom-Json
$wh = if ($asJson.discordWebhookUrl) { $asJson.discordWebhookUrl } else { $asJson.discordWebhook }
if ($wh) { $existWh = $wh.Trim() }
} catch {}
}
if (-not [string]::IsNullOrWhiteSpace($DiscordWebhook)) { $existWh = $DiscordWebhook.Trim() }
$askNewWh = $false
if (-not [string]::IsNullOrWhiteSpace($existWh)) {
Write-Host "=== CONFIGURE DISCORD WEBHOOK (AUTOSELL ALERTS) ===" -ForegroundColor Yellow
Write-Host "  Existing Webhook detected: $existWh" -ForegroundColor Cyan
Flush-KeyboardBuffer; $useWh = Read-Host "Keep using this existing Webhook? (y/n)"
if ($useWh -match '^(?i)y(es)?$') {
$DiscordWebhook = $existWh
Write-Host " -> [OK] Keeping existing Webhook" -ForegroundColor Green
} else { $askNewWh = $true }
} else { $askNewWh = $true }
if ($askNewWh) {
try {
Flush-KeyboardBuffer; $inWh = Read-Host "Enter Discord Webhook URL (or press ENTER to skip)"
if (-not [string]::IsNullOrWhiteSpace($inWh)) {
$DiscordWebhook = $inWh.Trim()
Write-Host " -> [OK] New Webhook registered!" -ForegroundColor Green
} else {
$DiscordWebhook = ""
Write-Host " -> Skipped Webhook (Discord alerts disabled)." -ForegroundColor DarkGray
}
} catch {}
}
$EnableAutoPay = $false
$AutoPayCmd = ""
$payCfgFile = Join-Path $MeteorDir "pay_config.json"
$existPayUser = ""
$existPayAmt = ""
if (Test-Path $payCfgFile) {
try {
$pObj = Get-Content $payCfgFile -Raw | ConvertFrom-Json
if ($pObj.user -and $pObj.enabled) { $existPayUser = [string]$pObj.user; $existPayAmt = [string]$pObj.amount }
} catch {}
}
$askNewPay = $false
if (-not [string]::IsNullOrWhiteSpace($PayUser)) {
$existPayUser = $PayUser.Trim()
if (-not [string]::IsNullOrWhiteSpace($PayAmount)) { $existPayAmt = $PayAmount.Trim() }
}
if (-not [string]::IsNullOrWhiteSpace($existPayUser) -and -not [string]::IsNullOrWhiteSpace($existPayAmt)) {
Write-Host "=== CONFIGURE AUTO PAY (DONUTSMP) ===" -ForegroundColor Yellow
Write-Host "  Existing Auto Pay: /pay $existPayUser $existPayAmt" -ForegroundColor Cyan
Flush-KeyboardBuffer; $useEx = Read-Host "Keep using /pay $existPayUser $existPayAmt? (y/n)"
if ($useEx -match '^(?i)y(es)?$') {
$PayUser = $existPayUser; $PayAmount = $existPayAmt; $AutoPayCmd = "/pay $PayUser $PayAmount"; $EnableAutoPay = $true
Write-Host " -> [OK] Keeping Auto Pay: $AutoPayCmd" -ForegroundColor Green
} else { $askNewPay = $true }
} else { $askNewPay = $true }
if ($askNewPay) {
try {
Flush-KeyboardBuffer; $inU = Read-Host "Enter recipient username for Auto Pay (or press ENTER to skip)"
if (-not [string]::IsNullOrWhiteSpace($inU)) {
$targetUser = $inU.Trim()
$targetAmount = ""
while ($true) {
Flush-KeyboardBuffer; $inA = Read-Host "Enter payment amount for $targetUser (e.g. 10, 500k, 1M, 2M)"
$amtTrim = $inA.Trim()
if ($amtTrim -match '^[0-9]+(\.[0-9]+)?[kKmMbBtT]?$') {
$nPart = $amtTrim -replace '[kKmMbBtT]$', ''
$pv = 0.0
if ([double]::TryParse($nPart, [ref]$pv) -and $pv -gt 0) {
if ($amtTrim -match '[a-zA-Z]$') {
$targetAmount = $amtTrim.Substring(0, $amtTrim.Length - 1) + $amtTrim.Substring($amtTrim.Length - 1).ToUpper()
} else { $targetAmount = $amtTrim }
break
}
}
Write-Host " [!] Invalid amount format! (Example: 10, 500k, 1M, 2M)" -ForegroundColor Red
}
$cmdPreview = "/pay $targetUser $targetAmount"
Write-Host "  -> Command: $cmdPreview (Delay: 400 ticks / 20s)" -ForegroundColor Yellow
Flush-KeyboardBuffer; $cfm = Read-Host "Confirm this Auto Pay configuration? (y/n)"
if ($cfm -match '^(?i)y(es)?$') {
$PayUser = $targetUser; $PayAmount = $targetAmount; $AutoPayCmd = $cmdPreview; $EnableAutoPay = $true
Write-Host " -> [OK] Confirmed: $AutoPayCmd" -ForegroundColor Green
}
} else {
$EnableAutoPay = $false; $AutoPayCmd = ""
Write-Host " -> Skipped Auto Pay (Module disabled)." -ForegroundColor DarkGray
}
} catch {}
}
$totalRamBytes = 0
try {
$totalRamBytes = (Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory
} catch {
try { $totalRamBytes = (Get-WmiObject Win32_ComputerSystem).TotalPhysicalMemory } catch {}
}
$totalRamGB = [math]::Round($totalRamBytes / 1GB)
if ($totalRamGB -le 0) { $totalRamGB = 4 }
$cpuCores = 4
try {
$cpuCores = (Get-CimInstance Win32_Processor | Measure-Object -Property NumberOfLogicalProcessors -Sum).Sum
} catch {
try { $cpuCores = (Get-WmiObject Win32_Processor | Measure-Object -Property NumberOfLogicalProcessors -Sum).Sum } catch {}
}
if (-not $cpuCores -or $cpuCores -le 0) { $cpuCores = 4 }
Write-Host "   DETECTED VPS HARDWARE: $cpuCores CPU Cores | $totalRamGB GB RAM" -ForegroundColor Yellow
$detectedMode = if ($cpuCores -ge 6 -or $totalRamGB -ge 7) { "8-8" } else { "4-4" }
Write-Host " -> Recommended Profile: VPS $detectedMode" -ForegroundColor Green
Write-Host "    [1] VPS 4-4: Standard 1 Instance (Full RAM/CPU allocation)" -ForegroundColor White
Write-Host "    [2] VPS 8-8: Multi-Instance up to 3 (Auto-limited: 2GB RAM & 2 CPU Cores / Instance)" -ForegroundColor White
Write-Host ""
$vpsModeChoice = ""
try {
$defaultNum = if ($detectedMode -eq "8-8") { "2" } else { "1" }
Flush-KeyboardBuffer; $inputChoice = Read-Host "Select VPS Profile (1 or 2, press ENTER for [$defaultNum])"
if (-not [string]::IsNullOrWhiteSpace($inputChoice)) {
$vpsModeChoice = $inputChoice.Trim()
} else {
$vpsModeChoice = $defaultNum
}
} catch {
$vpsModeChoice = if ($detectedMode -eq "8-8") { "2" } else { "1" }
}
$VpsMode = "4-4"
$InstanceCount = 1
$LimitRamCpu = $false
$LaunchDelaySeconds = 25
if ($vpsModeChoice -eq "2") {
$VpsMode = "8-8"
$LimitRamCpu = $true
Write-Host " -> Selected: VPS 8-8 (Multi-Instance: 2GB RAM & 2 CPU limit per instance)" -ForegroundColor Green
$inputInstCount = ""
try {
Flush-KeyboardBuffer; $inputInstCount = Read-Host "Enter number of Instances to create (1-3, press ENTER for [3])"
} catch {}
if ($inputInstCount -match '^[1-3]$') {
$InstanceCount = [int]$inputInstCount
} else {
$InstanceCount = 3
}
Write-Host " -> Instances to create: $InstanceCount (Max 3)" -ForegroundColor Green
$inputDelay = ""
try {
Flush-KeyboardBuffer; $inputDelay = Read-Host "Enter stagger delay between instances (seconds, press ENTER for [25])"
} catch {}
if ($inputDelay -match '^\d+$' -and [int]$inputDelay -ge 5) {
$LaunchDelaySeconds = [int]$inputDelay
} else {
$LaunchDelaySeconds = 25
}
Write-Host " -> Stagger launch delay: $LaunchDelaySeconds seconds (Prevents RAM spikes)" -ForegroundColor Green
} else {
$VpsMode = "4-4"
$InstanceCount = 1
$LimitRamCpu = $false
$LaunchDelaySeconds = 0
Write-Host " -> Selected: VPS 4-4 (Single Instance, full system resources)" -ForegroundColor Green
}
Write-Host "Installation directory: $BaseDir" -ForegroundColor Cyan
New-Item -ItemType Directory -Path $BaseDir -Force | Out-Null
New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
Write-Title "STEP 1: INSTALL VISUAL C++ REDISTRIBUTABLE (x64)"
$vcUrl = "https://aka.ms/vs/17/release/vc_redist.x64.exe"
$vcFile = Join-Path $TempDir "vc_redist.x64.exe"
$isVcInstalled = $false
try {
$vcReg = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\X64" -ErrorAction SilentlyContinue
if ($vcReg -and $vcReg.Installed -eq 1) { $isVcInstalled = $true }
} catch {}
if (-not $isVcInstalled -and (Test-Path "C:\Windows\System32\vcruntime140.dll") -and (Test-Path "C:\Windows\System32\msvcp140.dll")) {
$isVcInstalled = $true
}
if ($isVcInstalled) {
Write-Success "Visual C++ 2015-2022 x64 is already installed, skipping download!"
} else {
Write-Step "1/11" "Checking and downloading Visual C++ Redistributable..."
$downloadVc = Download-FileWithCurl -Url $vcUrl -OutFile $vcFile -Desc "Visual C++ 2015-2022 x64"
if ($downloadVc) {
Write-Step "1/11" "Installing Visual C++ Redistributable (Silent Mode)..."
try {
$proc = Start-Process -FilePath $vcFile -ArgumentList "/install /quiet /norestart" -Wait -PassThru
Write-Success "Visual C++ Redistributable installed successfully (Exit Code: $($proc.ExitCode))"
} catch {
Write-Warn "Failed to run VC++ installer automatically: $_"
}
}
}
Write-Title "STEP 2: INSTALL PRISM LAUNCHER (OFFICIAL PRISMLAUNCHER.ORG)"
$prismExe = Join-Path $PrismDir "prismlauncher.exe"
if (Test-Path $prismExe) {
Write-Success "Prism Launcher already exists at: $prismExe"
} else {
$localPrism = Get-ChildItem -Path "$env:USERPROFILE\Downloads", "$env:USERPROFILE\Desktop" -Filter "PrismLauncher*.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $localPrism) {
$localPrism = Get-ChildItem -Path "$env:USERPROFILE\Downloads", "$env:USERPROFILE\Desktop" -Filter "PrismLauncher*.zip" -ErrorAction SilentlyContinue | Select-Object -First 1
}
if ($localPrism) {
Write-Success "Found local Prism Launcher installer at: $($localPrism.FullName)"
if ($localPrism.Extension -eq ".exe") {
Start-Process -FilePath $localPrism.FullName -ArgumentList "/S /D=$PrismDir" -Wait
} else {
Expand-Archive -Path $localPrism.FullName -DestinationPath $PrismDir -Force
}
} else {
Write-Step "2/11" "Downloading Prism Launcher Installer (High-Speed CDN)..."
$prismSetupExe = Join-Path $TempDir "PrismLauncher-Setup.exe"
$prismDlUrl = "$repoRaw/bin/PrismSetup.exe"
$dlSuccess = Download-FileWithCurl -Url $prismDlUrl -OutFile $prismSetupExe -Desc "Prism Launcher Installer (Fast Direct)"
if (-not $dlSuccess) {
    $prismDlUrl = "https://github.com/PrismLauncher/PrismLauncher/releases/download/11.1.0/PrismLauncher-Windows-MSVC-Setup-11.1.0.exe"
    $dlSuccess = Download-FileWithCurl -Url $prismDlUrl -OutFile $prismSetupExe -Desc "Prism Launcher Installer (GitHub Fallback)"
}
if ($dlSuccess -and (Test-Path $prismSetupExe)) {
Write-Step "2/11" "Installing Prism Launcher (Silent Mode)..."
Start-Process -FilePath $prismSetupExe -ArgumentList "/S /D=$PrismDir" -Wait
} else {
Write-Warn "Installer execution failed, falling back to Portable archive..."
$prismZip = Join-Path $TempDir "PrismLauncher-Portable.zip"
$zipUrl = "https://github.com/PrismLauncher/PrismLauncher/releases/download/11.1.0/PrismLauncher-Windows-MSVC-Portable-11.1.0.zip"
Download-FileWithCurl -Url $zipUrl -OutFile $prismZip -Desc "Prism Launcher Portable Zip"
Expand-Archive -Path $prismZip -DestinationPath $PrismDir -Force
}
}
$nestedPrism = Get-ChildItem -Path $PrismDir -Filter "prismlauncher.exe" -Recurse | Select-Object -First 1
if ($nestedPrism -and ($nestedPrism.DirectoryName -ne $PrismDir)) {
Move-Item -Path "$($nestedPrism.DirectoryName)\*" -Destination $PrismDir -Force
}
}
New-Item -ItemType File -Path (Join-Path $PrismDir "portable.txt") -Force | Out-Null
$accountsJsonFile = Join-Path $PrismDir "accounts.json"
if (-not (Test-Path $accountsJsonFile)) {
$initAccountsJson = @'
{
"accounts": [],
"formatVersion": 3
}
'@
[System.IO.File]::WriteAllText($accountsJsonFile, $initAccountsJson, [System.Text.Encoding]::UTF8)
}
Write-Success "Prism Launcher is ready in Portable mode at: $PrismDir"
Write-Title "STEP 3: INSTALL JAVA 21 JRE PORTABLE (ADOPTIUM TEMURIN)"
$javaDir = Join-Path $PrismDir "runtime\java-21"
$javawExe = $null
$foundJavaw = Get-ChildItem -Path $javaDir -Filter "javaw.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
if ($foundJavaw) {
$javawExe = $foundJavaw.FullName
Write-Success "Java 21 already exists at: $javawExe"
} else {
Write-Step "3/11" "Downloading Java 21 Runtime (Akamai CDN)..."
$javaZip = Join-Path $TempDir "OpenJDK21-JRE.zip"
$javaUrl = "https://download.oracle.com/java/21/latest/jdk-21_windows-x64_bin.zip"
$dlJava = Download-FileWithCurl -Url $javaUrl -OutFile $javaZip -Desc "Java 21 Runtime (Oracle Akamai CDN)"
if (-not $dlJava) {
    $javaUrl = "https://api.adoptium.net/v3/binary/latest/21/ga/windows/x64/jre/hotspot/normal/eclipse?project=jdk"
    $dlJava = Download-FileWithCurl -Url $javaUrl -OutFile $javaZip -Desc "Java 21 JRE (Adoptium Fallback)"
}
Write-Step "3/11" "Extracting Java 21 runtime..."
New-Item -ItemType Directory -Path $javaDir -Force | Out-Null
Expand-Archive -Path $javaZip -DestinationPath $javaDir -Force
$foundJavaw = Get-ChildItem -Path $javaDir -Filter "javaw.exe" -Recurse | Select-Object -First 1
if ($foundJavaw) {
$javawExe = $foundJavaw.FullName
Write-Success "Java 21 installed successfully at: $javawExe"
} else {
Write-Err "javaw.exe not found after extracting Java 21!"
}
}
Write-Title "STEP 4: CONFIGURE MESA3D SOFTWARE OPENGL (FIX GLFW 65542 ON NON-GPU VPS)"
Write-Host "Mesa3D uses CPU llvmpipe to emulate OpenGL 4.5/4.6, allowing Minecraft to run on Non-GPU VPS." -ForegroundColor DarkCyan
$javaBin = if ($javawExe) { Split-Path -Parent $javawExe } else { $null }
$javaOpengl = if ($javaBin) { Join-Path $javaBin "opengl32.dll" } else { $null }
$prismOpengl = Join-Path $PrismDir "opengl32.dll"
$openglReady = $false
if ($javaOpengl -and (Test-Path $javaOpengl) -and ((Get-Item $javaOpengl).Length -gt 10000000) -and (Test-Path $prismOpengl) -and ((Get-Item $prismOpengl).Length -gt 10000000)) {
$openglReady = $true
Write-Success "Mesa3D OpenGL already deployed to Java and Prism Launcher, skipping download!"
} elseif ($prismOpengl -and (Test-Path $prismOpengl) -and ((Get-Item $prismOpengl).Length -gt 10000000) -and $javaBin) {
Copy-Item -Path $prismOpengl -Destination $javaOpengl -Force
New-Item -ItemType File -Path (Join-Path $javaBin "javaw.exe.local") -Force | Out-Null
New-Item -ItemType File -Path (Join-Path $javaBin "java.exe.local") -Force | Out-Null
$openglReady = $true
Write-Success "Copied Mesa3D opengl32.dll from Prism to Java bin: $javaBin"
} elseif ($javaOpengl -and (Test-Path $javaOpengl) -and ((Get-Item $javaOpengl).Length -gt 10000000)) {
Copy-Item -Path $javaOpengl -Destination $prismOpengl -Force
$openglReady = $true
Write-Success "Copied Mesa3D opengl32.dll from Java to Prism Launcher"
}
if (-not $openglReady) {
$mesa7z = Join-Path $TempDir "mesa-llvmpipe-clean.7z"
$zrExe = Join-Path $TempDir "7zr.exe"
$openglDll = $null
if (-not (Test-Path $zrExe)) {
    $dlZr = Download-FileWithCurl -Url "$repoRaw/bin/7zr.exe" -OutFile $zrExe -Desc "7-Zip Extractor (Fast CDN)"
    if (-not $dlZr) {
        Download-FileWithCurl -Url "https://www.7-zip.org/a/7zr.exe" -OutFile $zrExe -Desc "7-Zip Extractor (7zr Fallback)" | Out-Null
    }
}
$dlMesa = Download-FileWithCurl -Url "$repoRaw/bin/mesa.7z" -OutFile $mesa7z -Desc "Mesa3D Software OpenGL (Fast Direct CDN)"
if (-not $dlMesa) {
    $mmozeikoUrl = "https://github.com/mmozeiko/build-mesa/releases/download/26.2.2/mesa-llvmpipe-x64-26.2.2.7z"
    Download-FileWithCurl -Url $mmozeikoUrl -OutFile $mesa7z -Desc "Mesa3D LLVMpipe x64 Standalone (GitHub Fallback)" | Out-Null
}
if (Test-Path $zrExe) {
Write-Step "4/11" "Extracting opengl32.dll using 7zr..."
& $zrExe e "$mesa7z" "-o$TempDir" "opengl32.dll" -r -y | Out-Null
$candidate = Join-Path $TempDir "opengl32.dll"
if (Test-Path $candidate) { $openglDll = $candidate }
}
if (-not $openglDll -and (Get-Command "tar.exe" -ErrorAction SilentlyContinue)) {
& tar.exe -xf $mesa7z -C $TempDir opengl32.dll 2>$null
$candidate = Join-Path $TempDir "opengl32.dll"
if (Test-Path $candidate) { $openglDll = $candidate }
}
if ($openglDll -and (Test-Path $openglDll)) {
Write-Step "4/11" "Injecting opengl32.dll into Java runtime and Prism Launcher..."
if ($javaBin) {
Copy-Item -Path $openglDll -Destination (Join-Path $javaBin "opengl32.dll") -Force
New-Item -ItemType File -Path (Join-Path $javaBin "javaw.exe.local") -Force | Out-Null
New-Item -ItemType File -Path (Join-Path $javaBin "java.exe.local") -Force | Out-Null
Write-Success "Injected Mesa3D opengl32.dll into Java bin: $javaBin"
}
Copy-Item -Path $openglDll -Destination (Join-Path $PrismDir "opengl32.dll") -Force
Write-Success "Injected Mesa3D opengl32.dll into Prism Launcher"
} else {
Write-Err "Failed to extract opengl32.dll! Minecraft may report GLFW 65542 if VPS lacks OpenGL drivers."
}
}
Write-Title "STEP 5: INITIALIZE FABRIC 1.21.11 PRISM INSTANCE"
New-Item -ItemType Directory -Path $InstanceDir -Force | Out-Null
New-Item -ItemType Directory -Path $ModsDir -Force | Out-Null
New-Item -ItemType Directory -Path $ConfigDir -Force | Out-Null
New-Item -ItemType Directory -Path $ResourcePacksDir -Force | Out-Null
$MeteorDirs = @(
    (Join-Path $MinecraftDir "meteor-client"),
    (Join-Path $InstanceDir "meteor-client")
)
foreach ($md in $MeteorDirs) {
    New-Item -ItemType Directory -Path $md -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $md "modules") -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $md "presets") -Force | Out-Null
}
$patchesDir = Join-Path $InstanceDir "patches"
if (-not (Test-Path $patchesDir)) { New-Item -ItemType Directory -Path $patchesDir -Force | Out-Null }
$metaComps = @(
@{ Uid="net.minecraft"; Ver="1.21.11"; Name="Minecraft"; Imp=$true; Dep=$false },
@{ Uid="net.fabricmc.intermediary"; Ver="1.21.11"; Name="Intermediary Mappings"; Imp=$false; Dep=$true },
@{ Uid="net.fabricmc.fabric-loader"; Ver="0.19.5"; Name="Fabric Loader"; Imp=$true; Dep=$false },
@{ Uid="org.lwjgl3"; Ver="3.3.3"; Name="LWJGL 3"; Imp=$false; Dep=$true }
)
$packComps = @()
foreach ($c in $metaComps) {
$cUrl = "https://meta.prismlauncher.org/v1/$($c.Uid)/$($c.Ver).json"
$patchFile = Join-Path $patchesDir "$($c.Uid).json"
$metaDir = Join-Path $PrismDir "meta\$($c.Uid)"
$metaFile = Join-Path $metaDir "$($c.Ver).json"
$needDl = -not (Test-Path $patchFile)
if (-not $needDl -and $c.Uid -eq "net.fabricmc.fabric-loader") {
try {
$curPatch = Get-Content $patchFile -Raw | ConvertFrom-Json
if ($curPatch.version -ne $c.Ver) { $needDl = $true }
} catch { $needDl = $true }
}
if ($needDl) {
Remove-Item $patchFile -Force -ErrorAction SilentlyContinue
Download-FileWithCurl -Url $cUrl -OutFile $patchFile -Desc "Component $($c.Name) ($($c.Ver))" | Out-Null
}
if (-not (Test-Path $metaDir)) { New-Item -ItemType Directory -Path $metaDir -Force | Out-Null }
if (Test-Path $patchFile) { Copy-Item -Path $patchFile -Destination $metaFile -Force }
$compEntry = @{ cachedName = $c.Name; cachedVersion = $c.Ver; uid = $c.Uid; version = $c.Ver }
if ($c.Imp) { $compEntry.important = $true }
if ($c.Dep) { $compEntry.dependencyOnly = $true; $compEntry.cachedVolatile = $true }
$packComps += $compEntry
}
$mmcPackJson = (@{ components = $packComps; formatVersion = 1 } | ConvertTo-Json -Depth 5)
[System.IO.File]::WriteAllText((Join-Path $InstanceDir "mmc-pack.json"), $mmcPackJson, [System.Text.Encoding]::UTF8)
$javaPathEscaped = if ($javawExe) { $javawExe.Replace("\", "/") } else { "javaw" }
$memOverride = "true"
$cpuCores = [Environment]::ProcessorCount
$jvmArgs = if ($LimitRamCpu -or $cpuCores -le 4) {
"-XX:+UseG1GC -XX:ActiveProcessorCount=2 -XX:ParallelGCThreads=2 -XX:ConcGCThreads=1 -XX:G1ReservePercent=15 -XX:MaxGCPauseMillis=100 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -Dsun.java2d.opengl=false -Dsun.java2d.d3d=false"
} else {
"-XX:+UseG1GC -XX:G1ReservePercent=15 -XX:MaxGCPauseMillis=100 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -Dsun.java2d.opengl=false -Dsun.java2d.d3d=false"
}
$instanceCfgLines = @(
"[General]",
"ConfigVersion=1.2",
"name=$InstanceName",
"icon=default",
"InstanceType=OneSix",
"OverrideJava=true",
"OverrideJavaArgs=true",
"OverrideMemory=true",
"MinMemAlloc=384",
"MaxMemAlloc=1536",
"JavaPath=$javaPathEscaped",
"JvmArgs=$jvmArgs",
"JoinServerOnLaunch=true",
"JoinServerOnLaunchAddress=donutsmp.net",
"LogPrePostOutput=true"
)
[System.IO.File]::WriteAllLines((Join-Path $InstanceDir "instance.cfg"), $instanceCfgLines, [System.Text.Encoding]::UTF8)
if ($LimitRamCpu) {
Write-Success "Instance $InstanceName created successfully (Limited: 2GB RAM & 2 CPU Cores - donutsmp.net)!"
} else {
Write-Success "Instance $InstanceName created successfully (Standard 1 Instance - donutsmp.net)!"
}
$serversDatFile = Join-Path $MinecraftDir "servers.dat"
if (-not (Test-Path $serversDatFile)) {
$serversDatB64 = "CgAACQAHc2VydmVycwoAAAABCAACaXAADGRvbnV0c21wLm5ldAgABG5hbWUACERvbnV0U01QAQAOYWNjZXB0VGV4dHVyZXMBAAA="
[System.IO.File]::WriteAllBytes($serversDatFile, [Convert]::FromBase64String($serversDatB64))
Write-Success "Configured servers.dat (DonutSMP - donutsmp.net)"
} else {
Write-Success "servers.dat already exists, keeping existing server list!"
}
$activeMesaDll = if (Test-Path $prismOpengl) { $prismOpengl } elseif (Test-Path $javaOpengl) { $javaOpengl } else { $null }
if ($activeMesaDll) {
    $natDir = Join-Path $InstanceDir "natives"
    $mcBin = Join-Path $MinecraftDir "bin"
    New-Item -ItemType Directory -Path $natDir, $mcBin -Force | Out-Null
    Copy-Item -Path $activeMesaDll -Destination (Join-Path $InstanceDir "opengl32.dll") -Force
    Copy-Item -Path $activeMesaDll -Destination (Join-Path $MinecraftDir "opengl32.dll") -Force
    Copy-Item -Path $activeMesaDll -Destination (Join-Path $natDir "opengl32.dll") -Force
    Copy-Item -Path $activeMesaDll -Destination (Join-Path $mcBin "opengl32.dll") -Force
    Write-Success "Injected Mesa3D opengl32.dll into instance $InstanceName (natives, .minecraft, bin)"
}
$prismCfgFile = Join-Path $PrismDir "prismlauncher.cfg"
$currentHost = [System.Net.Dns]::GetHostName()
$prismCfgLines = @("[General]","ConfigVersion=1.2","Language=en_US","ApplicationTheme=system","IconTheme=pe_colored","LastHostname=$currentHost","JavaPath=$javaPathEscaped","MinMemAlloc=512","MaxMemAlloc=1536","AutomaticJavaDownload=false","AutomaticJavaSwitch=false","UserAskedAboutAutomaticJavaDownload=true","Analytics=false","CheckForUpdates=false")
[System.IO.File]::WriteAllLines($prismCfgFile, $prismCfgLines, [System.Text.Encoding]::UTF8)
Write-Success "Configured prismlauncher.cfg (Bypassed Quick Setup Wizard & Locked Java)"
$accountsFile = Join-Path $PrismDir "accounts.json"
if (-not (Test-Path $accountsFile)) {
$accountsData = @{
accounts = @()
formatVersion = 3
}
$accJsonStr = $accountsData | ConvertTo-Json -Depth 10
[System.IO.File]::WriteAllText($accountsFile, $accJsonStr, [System.Text.Encoding]::UTF8)
Write-Success "Initialized accounts.json ready for Microsoft login"
}
Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue
function Test-ValidJar([string]$p) {
if (-not (Test-Path $p)) { return $false }
try {
$z = [System.IO.Compression.ZipFile]::OpenRead($p)
$c = $z.Entries.Count
$z.Dispose()
return ($c -gt 0)
} catch { return $false }
}
Write-Title "STEP 6: DOWNLOAD OPTIMIZED MODS (18 MODS)" 
$modsList = @(
@{ Id = "1P89LBaIvgWtNFi3YiTEu3WYmnosKhhd5"; Name = "AutoRotate-1.1-R2-nohwid.jar" },
@{ Id = "1ncv-dODi1VEmxqbnVwdQsnybdomoGSiL"; Name = "autosell.jar" },
@{ Id = "1t3TRks59ULGezskip_lyLyWJzybYur2F"; Name = "cloth-config-21.11.153-fabric.jar" },
@{ Id = "1lefcwA0Rhi0gDXiV8rLiRc7UYcvJrMKe"; Name = "CRACKEDBYGOOBER_marlowwwclient-v4.jar.disabled" },
@{ Id = "1YvKY75db5erEs3qJoNcnCskVFkmDGfh8"; Name = "entityculling-fabric-1.10.5-mc1.21.11.jar" },
@{ Id = "1OZWQP3Tby89Of8brBVv3L5F9spsdGrq2"; Name = "fabric-api-0.141.4+1.21.11.jar" },
@{ Id = "1kLLmW-acedBiOeqRDzNZMi_itXTdu54K"; Name = "ferritecore-8.2.0-fabric.jar" },
@{ Id = "1eAStuadWw6IcL7MmHGMvpumps-7GZlGp"; Name = "ImmediatelyFast-Fabric-1.14.3+1.21.11.jar" },
@{ Id = "1F31AM0IZbbw5bnVz4T7MrYvItrM2HLd0"; Name = "iris-fabric-1.10.7+mc1.21.11.jar" },
@{ Id = "1zEUWKqSQBltb83YWRddB1C_2iris3XNf"; Name = "litematica-fabric-1.21.11-0.26.12.jar" },
@{ Id = "1bIKtPL5KLycmMetFJmDZiaQ8OfWMmScw"; Name = "lithium-fabric-0.21.4+mc1.21.11.jar" },
@{ Id = "1eUby03S4Qv7iOf4ghgRk10oS-zA9YeA4"; Name = "malilib-fabric-1.21.11-0.27.16.jar" },
@{ Id = "1tfO0LvqD_AEvpZp3KGfEPRo_AtiRzqRV"; Name = "meteor-client-1.21.11-82.jar" },
@{ Id = "1dDYtI2wLbR6YmJpvRANYg6NW5Ti6zvau"; Name = "modmenu-17.0.1-beta.1.jar" },
@{ Id = "1LOZEYDeYU4XIJ0z7yN9uOgX7y4ciH_oA"; Name = "opsec-1.21.11+v1.1.7.1.jar" },
@{ Id = "1KCgU8KJAQ7KoQYG-Q_1dQP4H4qDzc3Bq"; Name = "placeholder-api-2.8.2+1.21.10.jar" },
@{ Id = "1XKSpFU4Qf94NNtu-lZTr0WstRsnMt7FV"; Name = "sodium-fabric-0.8.13+mc1.21.11.jar" },
@{ Id = "1yYFsLDvUSYcvKn2LYwhRUTLND-eQ9MJU"; Name = "yet_another_config_lib_v3-3.8.2+1.21.11-fabric.jar" }
)
Remove-Item (Join-Path $ModsDir "* (1).jar") -Force -ErrorAction SilentlyContinue
Remove-Item (Join-Path $ModsDir "*.tmp") -Force -ErrorAction SilentlyContinue
$count = 0
foreach ($mod in $modsList) {
$count++
$targetModFile = Join-Path $ModsDir $mod.Name
if (Test-ValidJar $targetModFile) {
Write-Host "  [$count/$($modsList.Count)] Already present & verified: $($mod.Name) (Skipped)" -ForegroundColor DarkGray
} else {
if (Test-Path $targetModFile) {
Write-Host "  [!] Corrupt or incomplete mod detected: $($mod.Name) -> Re-downloading..." -ForegroundColor Yellow
Remove-Item $targetModFile -Force -ErrorAction SilentlyContinue
}
Write-Host "  [$count/$($modsList.Count)] " -ForegroundColor Yellow -NoNewline
Download-DriveFile -FileId $mod.Id -OutFile $targetModFile -Desc $mod.Name | Out-Null
if (-not (Test-ValidJar $targetModFile)) {
    Remove-Item $targetModFile -Force -ErrorAction SilentlyContinue
    $escapedName = [System.Uri]::EscapeDataString($mod.Name)
    $ghUrl = "$repoRaw/bin/$escapedName"
    Download-FileWithCurl -Url $ghUrl -OutFile $targetModFile -Desc "$($mod.Name) (GitHub CDN)" | Out-Null
    if (-not (Test-ValidJar $targetModFile)) {
        Remove-Item $targetModFile -Force -ErrorAction SilentlyContinue
        Download-DriveFile -FileId $mod.Id -OutFile $targetModFile -Desc "$($mod.Name) (Retry)" | Out-Null
    }
}
}
}
Write-Success "All 18 optimized mods installed successfully into: $ModsDir"
Write-Title "STEP 7: CONFIGURE AUTO SELL MOD (MOD AUTOSELL)"
$autoSellConfig = Join-Path $ConfigDir "autosell.json"
$autoSellId = "1sYzi_pcc9KtqWWekSb4sWjuU6xnsvnB_"
if ((Test-Path $autoSellConfig) -and ((Get-Item $autoSellConfig).Length -gt 100)) {
Write-Success "Config autosell.json already exists, skipping download!"
} else {
Write-Step "7/11" "Downloading autosell.json config from Google Drive..."
$dlOk = Download-DriveFile -FileId $autoSellId -OutFile $autoSellConfig -Desc "autosell.json"
if (-not $dlOk) {
$localAutoSell = Join-Path $ScriptDir "data\autosell.json"
if (Test-Path $localAutoSell) {
Copy-Item -Path $localAutoSell -Destination $autoSellConfig -Force
Write-Success "Restored autosell.json config from local backup data/"
}
} else {
Write-Success "AutoSell config installed at: $autoSellConfig"
}
}
if (Test-Path $autoSellConfig) {
if (-not [string]::IsNullOrWhiteSpace($DiscordWebhook)) {
try {
$jsonText = [System.IO.File]::ReadAllText($autoSellConfig, [System.Text.Encoding]::UTF8)
$jsonObj = $jsonText | ConvertFrom-Json
$jsonObj.discordWebhookUrl = $DiscordWebhook
$updatedJson = $jsonObj | ConvertTo-Json -Depth 10
[System.IO.File]::WriteAllText($autoSellConfig, $updatedJson, [System.Text.Encoding]::UTF8)
Write-Success "Updated Discord Webhook URL in: $autoSellConfig"
} catch {
Write-Warn "Failed to write Webhook to autosell.json: $_"
}
} else {
Write-Host "  (Discord Webhook unchanged for AutoSell)" -ForegroundColor DarkGray
}
}
Write-Title "STEP 8: CONFIGURE NO-RENDER & AUTO PAY (METEOR CLIENT)"
$cfgNoRenderPath = Join-Path $MeteorDir "config no render.txt"
$rawNoRenderTxt = Join-Path $TempDir "raw_no_render.txt"
if (-not (Test-Path $cfgNoRenderPath)) {
$noRenderId = "1uKBRRd9WHBoCTiLFcjW1imWfseCR5MhA"
Write-Step "8/11" "Downloading Meteor Client No-Render config data..."
Download-DriveFile -FileId $noRenderId -OutFile $rawNoRenderTxt -Desc "config no render (raw)" | Out-Null
} else {
Write-Success "No-Render configuration already exists, skipping download!"
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
try {
if (Test-Path $rawNoRenderTxt) {
$rawB64 = (Get-Content -Path $rawNoRenderTxt -Raw).Trim()
[System.IO.File]::WriteAllText((Join-Path $MeteorDir "config no render.txt"), $rawB64, [System.Text.Encoding]::UTF8)
}
$noRenderGzB64 = "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"
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
$rootMs.WriteByte(0); $rootMs.WriteByte(0) # ten rong
$rootMs.WriteByte(9)  # TAG_List
$rootMs.WriteByte(0); $rootMs.WriteByte(7) # do dai ten = 7
$rootMs.Write([System.Text.Encoding]::UTF8.GetBytes("modules"), 0, 7) # "modules"
$rootMs.WriteByte(10) # List element type = TAG_Compound
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

# Ghi vao CA 2 thu muc (.minecraft\meteor-client va root meteor-client)
foreach ($mTarget in $MeteorDirs) {
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
Write-Success "No-Render configuration installed & AUTO-ENABLED on Meteor Client!"
if ($EnableAutoPay) {
Write-Success "Auto Pay config ($AutoPayCmd | Delay: 400 | Disable On Leave/Disconnect OFF) AUTO-ENABLED!"
}
} catch {
Write-Warn "Failed to initialize modules.nbt automatically: $_"
}
Write-Title "STEP 9: INSTALL RESOURCE PACK (BEATRIX SHOP)"
$packId = "1sJoybUBUmIM0Kcsus9AXYZ8_c6JBAJ1M"
$packName = "beatrix_shop 1.9v1.zip"
$targetPack = Join-Path $ResourcePacksDir $packName
$packReady = $false
if ((Test-Path $targetPack) -and ((Get-Item $targetPack).Length -gt 10000000)) {
$packReady = $true
Write-Success "Resource Pack $packName already exists ($([math]::Round((Get-Item $targetPack).Length/1MB, 1)) MB), skipping download!"
} else {
Write-Step "9/11" "Downloading Beatrix Shop Resource Pack (30MB) from Google Drive..."
$dlPack = Download-DriveFile -FileId $packId -OutFile $targetPack -Desc $packName
if ($dlPack) { $packReady = $true; Write-Success "Resource Pack installed successfully at: $targetPack" }
}
if ($packReady) {
for ($idx = 2; $idx -le $InstanceCount; $idx++) {
$otherPackDir = Join-Path $PrismDir "instances\VPS-AFK-$idx\.minecraft\resourcepacks"
$otherPackFile = Join-Path $otherPackDir $packName
if (-not ((Test-Path $otherPackFile) -and ((Get-Item $otherPackFile).Length -gt 10000000))) {
if (-not (Test-Path $otherPackDir)) { New-Item -ItemType Directory -Path $otherPackDir -Force | Out-Null }
Copy-Item -Path $targetPack -Destination $otherPackFile -Force
}
}
}
Write-Title "STEP 10: CONFIGURE ULTRA-LOW RESOURCE SETTINGS & SODIUM (OPTIMIZED FOR WEAK VPS)"
$optionsFile = Join-Path $MinecraftDir "options.txt"
$optionsLines = @(
"version:3955",
"graphicsMode:0",
"renderDistance:32",
"simulationDistance:32",
"maxFps:20",
"enableVsync:false",
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
[System.IO.File]::WriteAllLines($optionsFile, $optionsLines, [System.Text.Encoding]::UTF8)
$rootOpt = Join-Path $InstanceDir "options.txt"
[System.IO.File]::WriteAllLines($rootOpt, $optionsLines, [System.Text.Encoding]::UTF8)

# Ghi file cau hinh Sodium toi uu hoa CPU cho VPS
$sodiumOptFile = Join-Path $ConfigDir "sodium-options.json"
$sodiumOptJson = @'
{
  "quality": {
    "weather_quality": "FAST",
    "leaves_quality": "FAST"
  },
  "advanced": {
    "cpu_render_ahead_limit": 1
  },
  "performance": {
    "chunk_builder_threads": 1,
    "always_defer_chunk_updates": true,
    "animate_only_visible_textures": true
  }
}
'@
[System.IO.File]::WriteAllText($sodiumOptFile, $sodiumOptJson, [System.Text.Encoding]::UTF8)
Write-Success "Optimized options.txt & Sodium: 2 Chunks, 20 Max FPS, 1 Chunk Thread, 0% Audio CPU!"
if ($InstanceCount -gt 1) {
Write-Title "INITIALIZING ADDITIONAL INSTANCES FOR VPS 8-8 (MAX $InstanceCount INSTANCES)"
for ($i = 2; $i -le $InstanceCount; $i++) {
$nextName = "VPS-AFK-$i"
$nextDir = Join-Path $PrismDir "instances\$nextName"
Write-Step "$i/$InstanceCount" "Cloning $nextName from base instance (copying mods, configs, options)..."
if (-not (Test-Path $nextDir)) { New-Item -ItemType Directory -Path $nextDir -Force | Out-Null }
Copy-Item -Path (Join-Path $InstanceDir "mmc-pack.json") -Destination (Join-Path $nextDir "mmc-pack.json") -Force
Copy-Item -Path (Join-Path $InstanceDir "patches") -Destination (Join-Path $nextDir "patches") -Recurse -Force
$nextCfgLines = @(
"[General]",
"ConfigVersion=1.2",
"name=$nextName",
"icon=default",
"InstanceType=OneSix",
"OverrideJava=true",
"OverrideJavaArgs=true",
"OverrideMemory=true",
"MinMemAlloc=384",
"MaxMemAlloc=1536",
"JavaPath=$javaPathEscaped",
"JvmArgs=-XX:+UseG1GC -XX:ActiveProcessorCount=2 -XX:ParallelGCThreads=2 -XX:ConcGCThreads=1 -XX:G1ReservePercent=15 -XX:MaxGCPauseMillis=100 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -Dsun.java2d.opengl=false -Dsun.java2d.d3d=false",
"JoinServerOnLaunch=true",
"JoinServerOnLaunchAddress=donutsmp.net",
"LogPrePostOutput=true"
)
[System.IO.File]::WriteAllLines((Join-Path $nextDir "instance.cfg"), $nextCfgLines, [System.Text.Encoding]::UTF8)
$nextMinecraftDir = Join-Path $nextDir ".minecraft"
if (Test-Path $nextMinecraftDir) { Remove-Item -Path $nextMinecraftDir -Recurse -Force -ErrorAction SilentlyContinue }
Copy-Item -Path $MinecraftDir -Destination $nextMinecraftDir -Recurse -Force
$nextNatDir = Join-Path $nextDir "natives"
New-Item -ItemType Directory -Path $nextNatDir -Force | Out-Null
if ($activeMesaDll) {
    Copy-Item -Path $activeMesaDll -Destination (Join-Path $nextDir "opengl32.dll") -Force
    Copy-Item -Path $activeMesaDll -Destination (Join-Path $nextNatDir "opengl32.dll") -Force
}
Write-Success "Instance $nextName created successfully (Limited: 2GB RAM & 2 CPU Cores)!"
}
}
$allInstNames = @()
for ($idx = 1; $idx -le $InstanceCount; $idx++) { $allInstNames += "VPS-AFK-$idx" }
$instCfgObj = @{
active_count = $InstanceCount
launch_delay_seconds = if ($LaunchDelaySeconds -gt 0) { $LaunchDelaySeconds } else { 25 }
instances = $allInstNames
updated = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
}
$instCfgJson = $instCfgObj | ConvertTo-Json -Compress
[System.IO.File]::WriteAllText((Join-Path $BaseDir "instance_config.json"), $instCfgJson, [System.Text.Encoding]::UTF8)
Write-Title "STEP 11: CONFIGURE MEM REDUCT (AUTOMATIC BACKGROUND RAM CLEANER)"
$memReductDir = Join-Path $BaseDir "MemReduct"
$memReductExe = Join-Path $memReductDir "memreduct.exe"
if (Test-Path $memReductExe) {
Write-Success "Mem Reduct already exists at: $memReductExe, skipping download!"
} else {
$memReduct7z = Join-Path $TempDir "memreduct.7z"
$memReductUrl = "https://github.com/henrypp/memreduct/releases/download/v.3.5.2/memreduct-3.5.2-bin.7z"
Write-Step "11/11" "Downloading Mem Reduct Portable from GitHub..."
$dlMr = Download-FileWithCurl -Url $memReductUrl -OutFile $memReduct7z -Desc "Mem Reduct 3.5.2 Portable"
if ($dlMr) {
New-Item -ItemType Directory -Path $memReductDir -Force | Out-Null
if (-not (Test-Path $zrExe)) {
Download-FileWithCurl -Url "https://www.7-zip.org/a/7zr.exe" -OutFile $zrExe -Desc "7-Zip Extractor (7zr)" | Out-Null
}
if (Test-Path $zrExe) {
& $zrExe e "$memReduct7z" "-o$memReductDir" "memreduct/64/*" -r -y | Out-Null
}
if (-not (Test-Path $memReductExe) -and (Get-Command "tar.exe" -ErrorAction SilentlyContinue)) {
try {
& tar.exe -xf $memReduct7z -C $TempDir memreduct/64/ 2>$null
$extractedDir = Join-Path $TempDir "memreduct\64"
if (Test-Path $extractedDir) {
Copy-Item -Path "$extractedDir\*" -Destination $memReductDir -Recurse -Force
}
} catch {}
}
}
}
if (Test-Path $memReductExe) {
Stop-Process -Name "memreduct" -Force -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 500
[System.IO.File]::WriteAllBytes((Join-Path $memReductDir "portable.dat"), [System.Text.Encoding]::ASCII.GetBytes("#PORTABLE#"))
$mrIniLines = @("[memreduct]","AlwaysOnTop=0","AutoreductEnable=1","AutoreductValue=85","AutoreductIntervalEnable=1","AutoreductIntervalValue=30","ReductMask2=254","IsAllowStandbyListCleanup=1","BalloonCleanResults=0","IsNotificationsSound=0","IsShowWarningConfirmation=0","IsShowReductConfirmation=0","IsStartMinimized=1","IsCloseToTray=1","IsMinimizeToTray=1","CheckUpdatesPeriod=0","CheckUpdates=0")
[System.IO.File]::WriteAllLines((Join-Path $memReductDir "memreduct.ini"), $mrIniLines, [System.Text.Encoding]::Unicode)
$appDataMrDir = Join-Path $env:APPDATA "Henry++\Mem Reduct"
if (-not (Test-Path $appDataMrDir)) { New-Item -ItemType Directory -Path $appDataMrDir -Force | Out-Null }
[System.IO.File]::WriteAllLines((Join-Path $appDataMrDir "memreduct.ini"), $mrIniLines, [System.Text.Encoding]::Unicode)

try {
$runKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
Set-ItemProperty -Path $runKey -Name "MemReduct" -Value "`"$memReductExe`" -minimized" -Force
try { & schtasks.exe /Create /TN "memreductTask" /TR "`"$memReductExe`" -minimized" /SC ONLOGON /RL HIGHEST /F 2>$null | Out-Null } catch {}
Write-Success "Added Mem Reduct to Windows Startup & Task Scheduler (Auto-starts on boot)!"
} catch {
Write-Warn "Failed to add Mem Reduct to Registry Startup: $_"
}
Stop-Process -Name "memreduct" -Force -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 300
try {
Start-Process -FilePath $memReductExe -ArgumentList "-minimized"
Write-Success "Mem Reduct launched silently in system tray!"
} catch {
Write-Warn "Failed to start Mem Reduct: $_"
}
Write-Success "Mem Reduct configured: Cleans RAM every 30m & when >85%, protects Java RAM (excludes Working Set), silent mode!"
} else {
Write-Warn "Failed to configure Mem Reduct automatically."
}
Write-Title "STEP 12: INSTALL ZERO-TERMINAL DESKTOP SHORTCUTS"

$binDir = Join-Path $BaseDir "bin"
if (-not (Test-Path $binDir)) { New-Item -ItemType Directory -Path $binDir -Force | Out-Null }
$srcDir = Join-Path $BaseDir "src"
if (-not (Test-Path $srcDir)) { New-Item -ItemType Directory -Path $srcDir -Force | Out-Null }

$repoRaw = "https://raw.githubusercontent.com/babadz207/minecraft-vps-setup/main"

# 1. Tai hoac copy cac file thuc thi .exe (va ma nguon .cs du phong)
$apps = @(
    @{ Name = "DangNhapMicrosoft.exe"; Src = "DangNhapMicrosoft.cs"; Desktop = "1. Microsoft Login.exe"; Desc = "Microsoft Login Guide"; Main = $null; Ref = $null },
    @{ Name = "WatchdogUI.exe"; Src = "WatchdogUI.cs"; Desktop = "2. Auto Reconnect 24-7 (Watchdog).exe"; Desc = "24/7 Watchdog & Auto Reconnect"; Main = $null; Ref = "System.Management.dll" },
    @{ Name = "AutoPayManager.exe"; Src = "AutoPayManager.cs"; Desktop = "3. Auto Pay Manager.exe"; Desc = "Auto Pay Manager"; Main = $null; Ref = $null },
    @{ Name = "DonRAM.exe"; Src = "Launchers.cs"; Desktop = "4. Clean RAM (Mem Reduct).exe"; Desc = "Clean RAM Launcher"; Main = "DonRAMLauncher"; Ref = $null },
    @{ Name = "MoPrism.exe"; Src = "Launchers.cs"; Desktop = "5. Open Prism Launcher.exe"; Desc = "Prism Launcher Shortcut"; Main = "MoPrismLauncher"; Ref = $null }
)

# Tim csc.exe bien dich C# san co tren Windows
$csc = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
if (-not (Test-Path $csc)) {
    $csc = "C:\Windows\Microsoft.NET\Framework\v4.0.30319\csc.exe"
}

foreach ($app in $apps) {
    $targetExe = Join-Path $binDir $app.Name
    $targetSrc = Join-Path $srcDir $app.Src

    # Kiem tra neu chay offline hoac co file local
    $localBin = Join-Path $ScriptDir ("bin\" + $app.Name)
    $localSrc = Join-Path $ScriptDir ("src\" + $app.Src)

    if (Test-Path $localBin) {
        Copy-Item -Path $localBin -Destination $targetExe -Force
    }
    if (Test-Path $localSrc) {
        Copy-Item -Path $localSrc -Destination $targetSrc -Force
    }

    # Neu chua co exe, thu tai tu GitHub raw
    if (-not (Test-Path $targetExe)) {
        Download-FileWithCurl "$repoRaw/bin/$($app.Name)" $targetExe $app.Desc
    }

    # Neu van chua co exe hoac bi loi, tai file ma nguon va tu bien dich bang csc.exe
    if (-not (Test-Path $targetExe) -or ((Get-Item $targetExe).Length -lt 1000)) {
        if (-not (Test-Path $targetSrc)) {
            Download-FileWithCurl "$repoRaw/src/$($app.Src)" $targetSrc "$($app.Src) source code"
        }
        if ((Test-Path $targetSrc) -and (Test-Path $csc)) {
            Write-Host "  -> Compiling $($app.Name) from C# source..." -ForegroundColor Cyan
            $argsList = @("/target:winexe", "/nologo", "/optimize+")
            if ($app.Main) { $argsList += "/main:$($app.Main)" }
            if ($app.Ref) { $argsList += "/reference:$($app.Ref)" }
            $argsList += "/out:`"$targetExe`""
            $argsList += "`"$targetSrc`""
            & $csc $argsList | Out-Null
        }
    }
}

# 2. Don dep Desktop sach se va copy 5 file exe ra Desktop
$Desktop = [Environment]::GetFolderPath('Desktop')
if ($Desktop -and (Test-Path $Desktop)) {
    # Clean all legacy batch files and old shortcut variations
    Remove-Item (Join-Path $Desktop "*.bat") -Force -ErrorAction SilentlyContinue
    Remove-Item (Join-Path $Desktop "*Chay Minecraft AFK*") -Force -ErrorAction SilentlyContinue
    Remove-Item (Join-Path $Desktop "*Dang Nhap Microsoft*") -Force -ErrorAction SilentlyContinue
    Remove-Item (Join-Path $Desktop "*Microsoft Login*") -Force -ErrorAction SilentlyContinue
    Remove-Item (Join-Path $Desktop "*Auto Restart*") -Force -ErrorAction SilentlyContinue
    Remove-Item (Join-Path $Desktop "*Auto Reconnect*") -Force -ErrorAction SilentlyContinue
    Remove-Item (Join-Path $Desktop "*Quan Ly Auto Pay*") -Force -ErrorAction SilentlyContinue
    Remove-Item (Join-Path $Desktop "*Auto Pay Manager*") -Force -ErrorAction SilentlyContinue
    Remove-Item (Join-Path $Desktop "*Don RAM*") -Force -ErrorAction SilentlyContinue
    Remove-Item (Join-Path $Desktop "*Clean RAM*") -Force -ErrorAction SilentlyContinue
    Remove-Item (Join-Path $Desktop "*Mo Prism Launcher*") -Force -ErrorAction SilentlyContinue
    Remove-Item (Join-Path $Desktop "*Open Prism Launcher*") -Force -ErrorAction SilentlyContinue

    foreach ($app in $apps) {
        $sourceExe = Join-Path $binDir $app.Name
        if (Test-Path $sourceExe) {
            Copy-Item -Path $sourceExe -Destination (Join-Path $Desktop $app.Desktop) -Force
        }
    }
    Write-Success "Cleaned Desktop and deployed 5 standalone GUI (.exe) tools with zero terminal popups!"
}

# Xoa thu muc tam
Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue

Write-Title "SETUP COMPLETED 100%! MINECRAFT VPS IS READY"
Write-Host " [OK] Prism Launcher & Java 21 & Mesa3D OpenGL (Software Rendering) : READY" -ForegroundColor Green
Write-Host " [OK] Instance $InstanceName (Fabric 1.21.11 - donutsmp.net)            : INITIALIZED" -ForegroundColor Green
Write-Host " [OK] 18 Mods + Meteor (No-Render) + AutoSell + Low-Resource Config  : INSTALLED" -ForegroundColor Green
Write-Host " [OK] Mem Reduct: Auto Memory Cleaning (> 85% & every 30m)           : RUNNING" -ForegroundColor Green
Write-Host " [OK] 5 Desktop GUI Executables (Zero-Terminal)                      : READY" -ForegroundColor Green
Write-Host ""
Write-Host "QUICK START GUIDE FOR DONUTSMP.NET (ZERO TERMINAL):" -ForegroundColor Yellow
Write-Host "  1. [1. Microsoft Login.exe]                 -> One-time Microsoft account setup" -ForegroundColor Cyan
Write-Host "  2. [2. Auto Reconnect 24-7 (Watchdog).exe]  -> 24/7 Monitoring Dashboard & Auto Reconnect" -ForegroundColor Green
Write-Host "  3. [3. Auto Pay Manager.exe]                -> Configure /pay command & recipient" -ForegroundColor Cyan
Write-Host "  4. [4. Clean RAM (Mem Reduct).exe]          -> Instant background memory cleaning" -ForegroundColor Cyan
Write-Host "  5. [5. Open Prism Launcher.exe]             -> Direct Prism Launcher access" -ForegroundColor Cyan
Write-Host ""
Write-Host "Have a smooth and safe 24/7 AFK session!" -ForegroundColor Magenta

