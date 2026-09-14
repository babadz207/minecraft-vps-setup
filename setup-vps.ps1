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
Write-Host "   [+] DANG LOAD BO CAI DAT MINECRAFT VPS 24/7..." -ForegroundColor Yellow
Write-Host "   [!] VUI LONG CHO GIAY LAT (DANG KHOA PHIM BAM)..." -ForegroundColor DarkGray
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
Flush-KeyboardBuffer; Write-Host "  -> [⏳ DANG TAI]: $Desc..." -ForegroundColor DarkGray
$parent = Split-Path -Parent $OutFile
if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
$dlOk = $false
if (Get-Command "curl.exe" -ErrorAction SilentlyContinue) {
try {
& curl.exe -k -L --ssl-no-revoke --http1.1 --connect-timeout 15 --max-time 300 -# -A "Mozilla/5.0" "$Url" -o "$OutFile"
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
try {
$mirrorUrl = "https://ghproxy.net/" + $Url
Write-Host "     Thu tai qua mirror toc do cao: $mirrorUrl..." -ForegroundColor DarkYellow
& curl.exe -k -L --ssl-no-revoke --http1.1 --connect-timeout 15 --max-time 300 -# -A "Mozilla/5.0" "$mirrorUrl" -o "$OutFile"
if ($LASTEXITCODE -eq 0 -and (Test-Path $OutFile) -and ((Get-Item $OutFile).Length -gt 100)) {
$dlOk = $true
} else {
Remove-Item $OutFile -Force -ErrorAction SilentlyContinue
}
} catch {
Remove-Item $OutFile -Force -ErrorAction SilentlyContinue
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
Write-Host "     Hoan tat ($mb MB)" -ForegroundColor DarkGreen
return $true
}
}
Write-Err "Khong the tai file $Desc hoac file bi loi."
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
Write-Host "=== CAU HINH DISCORD WEBHOOK AUTOSELL ===" -ForegroundColor Yellow
Write-Host "  Dang co san Webhook: $existWh" -ForegroundColor Cyan
Flush-KeyboardBuffer; $useWh = Read-Host "Tiep tuc su dung Webhook nay khong? (y/n)"
if ($useWh -match '^(?i)y(es)?$') {
$DiscordWebhook = $existWh
Write-Host " -> [OK] Tiep tuc su dung Webhook da luu" -ForegroundColor Green
} else { $askNewWh = $true }
} else { $askNewWh = $true }
if ($askNewWh) {
try {
Flush-KeyboardBuffer; $inWh = Read-Host "Nhap Discord Webhook moi (hoac nhan ENTER de bo qua)"
if (-not [string]::IsNullOrWhiteSpace($inWh)) {
$DiscordWebhook = $inWh.Trim()
Write-Host " -> Da ghi nhan Webhook moi!" -ForegroundColor Green
} else {
$DiscordWebhook = ""
Write-Host " -> Bo qua Webhook (Khong dung Webhook)." -ForegroundColor DarkGray
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
Write-Host "=== CAU HINH AUTO PAY (DONUTSMP) ===" -ForegroundColor Yellow
Write-Host "  Dang co san: /pay $existPayUser $existPayAmt" -ForegroundColor Cyan
Flush-KeyboardBuffer; $useEx = Read-Host "Tiep tuc su dung /pay $existPayUser $existPayAmt khong? (y/n)"
if ($useEx -match '^(?i)y(es)?$') {
$PayUser = $existPayUser; $PayAmount = $existPayAmt; $AutoPayCmd = "/pay $PayUser $PayAmount"; $EnableAutoPay = $true
Write-Host " -> [OK] Tiep tuc su dung: $AutoPayCmd" -ForegroundColor Green
} else { $askNewPay = $true }
} else { $askNewPay = $true }
if ($askNewPay) {
try {
Flush-KeyboardBuffer; $inU = Read-Host "Nhap ten user muon Auto Pay (hoac nhan ENTER de bo qua)"
if (-not [string]::IsNullOrWhiteSpace($inU)) {
$targetUser = $inU.Trim()
$targetAmount = ""
while ($true) {
Flush-KeyboardBuffer; $inA = Read-Host "Nhap so tien muon pay cho $targetUser (vi du: 1M, 2M, 2000000, 500k...)"
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
Write-Host " [!] Dinh dang khong hop le! (Vi du: 1M, 2M, 2000000, 500k...)" -ForegroundColor Red
}
$cmdPreview = "/pay $targetUser $targetAmount"
Write-Host "  -> Lenh: $cmdPreview (Delay: 400 ticks)" -ForegroundColor Yellow
Flush-KeyboardBuffer; $cfm = Read-Host "Xac nhan cau hinh Auto Pay nay? (y/n)"
if ($cfm -match '^(?i)y(es)?$') {
$PayUser = $targetUser; $PayAmount = $targetAmount; $AutoPayCmd = $cmdPreview; $EnableAutoPay = $true
Write-Host " -> [OK] Da xac nhan: $AutoPayCmd" -ForegroundColor Green
}
} else {
$EnableAutoPay = $false; $AutoPayCmd = ""
Write-Host " -> Bo qua Auto Pay (Khong bat spam)." -ForegroundColor DarkGray
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
Write-Host "   NHẬN DIỆN CẤU HÌNH VPS: $cpuCores CPU Cores | $totalRamGB GB RAM" -ForegroundColor Yellow
$detectedMode = if ($cpuCores -ge 6 -or $totalRamGB -ge 7) { "8-8" } else { "4-4" }
Write-Host " -> He thong tu dong nhan dien: VPS $detectedMode" -ForegroundColor Green
Write-Host "    [1] VPS 4-4: Mac dinh 1 Instance duy nhat (KHONG gioi han RAM/CPU)" -ForegroundColor White
Write-Host "    [2] VPS 8-8: Toi da 3 Instance (TU DONG GIOI HAN: 2GB RAM & 2 CPU Cores / Instance)" -ForegroundColor White
Write-Host ""
$vpsModeChoice = ""
try {
$defaultNum = if ($detectedMode -eq "8-8") { "2" } else { "1" }
Flush-KeyboardBuffer; $inputChoice = Read-Host "Chon che do VPS (1 hoac 2, nhan ENTER de lay [$defaultNum])"
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
Write-Host " -> Che do da chon: VPS 8-8 (Moi Instance 1 Account - Tu gioi han 2GB RAM & 2 CPU / Instance)" -ForegroundColor Green
$inputInstCount = ""
try {
Flush-KeyboardBuffer; $inputInstCount = Read-Host "Nhap so luong Instance muon tao (1, 2 hoac 3, nhan ENTER de lay toi da [3])"
} catch {}
if ($inputInstCount -match '^[1-3]$') {
$InstanceCount = [int]$inputInstCount
} else {
$InstanceCount = 3
}
Write-Host " -> So luong Instance se tao: $InstanceCount (Toi da 3)" -ForegroundColor Green
$inputDelay = ""
try {
Flush-KeyboardBuffer; $inputDelay = Read-Host "Nhap thoi gian delay giua cac bot de tranh tran RAM (giay, nhan ENTER de lay [25])"
} catch {}
if ($inputDelay -match '^\d+$' -and [int]$inputDelay -ge 5) {
$LaunchDelaySeconds = [int]$inputDelay
} else {
$LaunchDelaySeconds = 25
}
Write-Host " -> Thoi gian delay giua cac bot: $LaunchDelaySeconds giay (Chong tran RAM)" -ForegroundColor Green
} else {
$VpsMode = "4-4"
$InstanceCount = 1
$LimitRamCpu = $false
$LaunchDelaySeconds = 0
Write-Host " -> Che do da chon: VPS 4-4 (1 Instance mac dinh, KHONG gioi han RAM/CPU)" -ForegroundColor Green
}
Write-Host "Thu muc cai dat: $BaseDir" -ForegroundColor Cyan
New-Item -ItemType Directory -Path $BaseDir -Force | Out-Null
New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
Write-Title "BUOC 1: CAI DAT VISUAL C++ REDISTRIBUTABLE (x64)"
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
Write-Success "Visual C++ 2015-2022 x64 da duoc cai dat tren he thong, bo qua tai xuong!"
} else {
Write-Step "1/10" "Dang kiem tra va tai Visual C++ Redistributable..."
$downloadVc = Download-FileWithCurl -Url $vcUrl -OutFile $vcFile -Desc "Visual C++ 2015-2022 x64"
if ($downloadVc) {
Write-Step "1/10" "Dang cai dat Visual C++ Redistributable (Silent Mode)..."
try {
$proc = Start-Process -FilePath $vcFile -ArgumentList "/install /quiet /norestart" -Wait -PassThru
Write-Success "Visual C++ Redistributable da duoc cai dat (Exit Code: $($proc.ExitCode))"
} catch {
Write-Warn "Khong the chay trinh cai dat VC++ tu dong: $_"
}
}
}
Write-Title "BUOC 2: CAI DAT PRISM LAUNCHER (OFFICIAL PRISMLAUNCHER.ORG)"
$prismExe = Join-Path $PrismDir "prismlauncher.exe"
if (Test-Path $prismExe) {
Write-Success "Prism Launcher da ton tai tai: $prismExe"
} else {
$localPrism = Get-ChildItem -Path "$env:USERPROFILE\Downloads", "$env:USERPROFILE\Desktop" -Filter "PrismLauncher*.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $localPrism) {
$localPrism = Get-ChildItem -Path "$env:USERPROFILE\Downloads", "$env:USERPROFILE\Desktop" -Filter "PrismLauncher*.zip" -ErrorAction SilentlyContinue | Select-Object -First 1
}
if ($localPrism) {
Write-Success "Phat hien file Prism Launcher san co tai: $($localPrism.FullName)"
if ($localPrism.Extension -eq ".exe") {
Start-Process -FilePath $localPrism.FullName -ArgumentList "/S /D=$PrismDir" -Wait
} else {
Expand-Archive -Path $localPrism.FullName -DestinationPath $PrismDir -Force
}
} else {
Write-Step "2/10" "Dang tai Prism Launcher Installer tu trang chu prismlauncher.org..."
$prismSetupExe = Join-Path $TempDir "PrismLauncher-Setup.exe"
$prismDlUrl = "https://github.com/PrismLauncher/PrismLauncher/releases/download/11.1.0/PrismLauncher-Windows-MSVC-Setup-11.1.0.exe"
try {
$headers = @{'User-Agent'='Mozilla/5.0'}
$rel = Invoke-RestMethod -Uri 'https://api.github.com/repos/PrismLauncher/PrismLauncher/releases/latest' -Headers $headers
$asset = $rel.assets | Where-Object { $_.name -like '*Windows-MSVC-Setup*.exe' } | Select-Object -First 1
if ($asset) { $prismDlUrl = $asset.browser_download_url }
} catch {}
$dlSuccess = Download-FileWithCurl -Url $prismDlUrl -OutFile $prismSetupExe -Desc "Prism Launcher Installer"
if ($dlSuccess -and (Test-Path $prismSetupExe)) {
Write-Step "2/10" "Dang cai dat Prism Launcher (Silent Mode)..."
Start-Process -FilePath $prismSetupExe -ArgumentList "/S /D=$PrismDir" -Wait
} else {
Write-Warn "Khong the cai Setup, chuyen sang tai ban Portable zip..."
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
Write-Success "Prism Launcher da san sang o che do Portable tai: $PrismDir"
Write-Title "BUOC 3: CAI DAT JAVA 21 PORTABLE (ADOPTIUM TEMURIN)"
$javaDir = Join-Path $PrismDir "runtime\java-21"
$javawExe = $null
$foundJavaw = Get-ChildItem -Path $javaDir -Filter "javaw.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
if ($foundJavaw) {
$javawExe = $foundJavaw.FullName
Write-Success "Java 21 da ton tai tai: $javawExe"
} else {
Write-Step "3/10" "Dang tai Java 21 JRE Portable tu Adoptium Temurin..."
$javaZip = Join-Path $TempDir "OpenJDK21-JRE.zip"
$javaUrl = "https://api.adoptium.net/v3/binary/latest/21/ga/windows/x64/jre/hotspot/normal/eclipse?project=jdk"
Download-FileWithCurl -Url $javaUrl -OutFile $javaZip -Desc "Java 21 OpenJDK JRE x64"
Write-Step "3/10" "Dang giai nen Java 21..."
New-Item -ItemType Directory -Path $javaDir -Force | Out-Null
Expand-Archive -Path $javaZip -DestinationPath $javaDir -Force
$foundJavaw = Get-ChildItem -Path $javaDir -Filter "javaw.exe" -Recurse | Select-Object -First 1
if ($foundJavaw) {
$javawExe = $foundJavaw.FullName
Write-Success "Java 21 da duoc cai dat thanh cong tai: $javawExe"
} else {
Write-Err "Khong tim thay javaw.exe sau khi giai nen Java 21!"
}
}
Write-Title "BUOC 4: CAI DAT MESA3D SOFTWARE OPENGL (FIX LOI GLFW 65542 TREN VPS)"
Write-Host "Mesa3D su dung CPU de gia lap OpenGL 4.5/4.6 giup Minecraft chay muot ma tren VPS khong GPU." -ForegroundColor DarkCyan
$javaBin = if ($javawExe) { Split-Path -Parent $javawExe } else { $null }
$javaOpengl = if ($javaBin) { Join-Path $javaBin "opengl32.dll" } else { $null }
$prismOpengl = Join-Path $PrismDir "opengl32.dll"
$openglReady = $false
if ($javaOpengl -and (Test-Path $javaOpengl) -and ((Get-Item $javaOpengl).Length -gt 10000000) -and (Test-Path $prismOpengl) -and ((Get-Item $prismOpengl).Length -gt 10000000)) {
$openglReady = $true
Write-Success "Mesa3D OpenGL da duoc tiem san vao Java va Prism Launcher, bo qua tai xuong!"
} elseif ($prismOpengl -and (Test-Path $prismOpengl) -and ((Get-Item $prismOpengl).Length -gt 10000000) -and $javaBin) {
Copy-Item -Path $prismOpengl -Destination $javaOpengl -Force
New-Item -ItemType File -Path (Join-Path $javaBin "javaw.exe.local") -Force | Out-Null
New-Item -ItemType File -Path (Join-Path $javaBin "java.exe.local") -Force | Out-Null
$openglReady = $true
Write-Success "Da copy Mesa3D opengl32.dll tu Prism sang Java bin: $javaBin"
} elseif ($javaOpengl -and (Test-Path $javaOpengl) -and ((Get-Item $javaOpengl).Length -gt 10000000)) {
Copy-Item -Path $javaOpengl -Destination $prismOpengl -Force
$openglReady = $true
Write-Success "Da copy Mesa3D opengl32.dll tu Java sang Prism Launcher"
}
if (-not $openglReady) {
$mesa7z = Join-Path $TempDir "mesa-llvmpipe-clean.7z"
$zrExe = Join-Path $TempDir "7zr.exe"
$openglDll = $null
if (-not (Test-Path $zrExe)) {
Download-FileWithCurl -Url "https://www.7-zip.org/a/7zr.exe" -OutFile $zrExe -Desc "7-Zip Extractor (7zr)" | Out-Null
}
$mmozeikoUrl = "https://github.com/mmozeiko/build-mesa/releases/download/26.2.2/mesa-llvmpipe-x64-26.2.2.7z"
Download-FileWithCurl -Url $mmozeikoUrl -OutFile $mesa7z -Desc "Mesa3D LLVMpipe x64 Standalone" | Out-Null
if (Test-Path $zrExe) {
Write-Step "4/10" "Dang trich xuat opengl32.dll bang 7zr..."
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
Write-Step "4/10" "Dang tiem opengl32.dll vao Java runtime va Prism Launcher..."
if ($javaBin) {
Copy-Item -Path $openglDll -Destination (Join-Path $javaBin "opengl32.dll") -Force
New-Item -ItemType File -Path (Join-Path $javaBin "javaw.exe.local") -Force | Out-Null
New-Item -ItemType File -Path (Join-Path $javaBin "java.exe.local") -Force | Out-Null
Write-Success "Da tiem Mesa3D opengl32.dll vao Java bin: $javaBin"
}
Copy-Item -Path $openglDll -Destination (Join-Path $PrismDir "opengl32.dll") -Force
Write-Success "Da tiem Mesa3D opengl32.dll vao Prism Launcher"
} else {
Write-Err "Khong the trich xuat opengl32.dll! Minecraft co the se bao loi GLFW 65542 neu VPS thieu driver OpenGL."
}
}
Write-Title "BUOC 5: KHOI TAO INSTANCE FABRIC 1.21.11 CHO PRISM LAUNCHER"
New-Item -ItemType Directory -Path $InstanceDir -Force | Out-Null
New-Item -ItemType Directory -Path $ModsDir -Force | Out-Null
New-Item -ItemType Directory -Path $ConfigDir -Force | Out-Null
New-Item -ItemType Directory -Path $ResourcePacksDir -Force | Out-Null
New-Item -ItemType Directory -Path $MeteorDir -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $MeteorDir "modules") -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $MeteorDir "presets") -Force | Out-Null
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
$memOverride = if ($LimitRamCpu) { "true" } else { "false" }
$jvmArgs = if ($LimitRamCpu) {
"-XX:+UseG1GC -XX:ActiveProcessorCount=2 -XX:ParallelGCThreads=2 -XX:ConcGCThreads=1 -XX:+ParallelRefProcEnabled -XX:+AlwaysPreTouch -Dsun.java2d.opengl=false"
} else {
"-XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:+AlwaysPreTouch -Dsun.java2d.opengl=false"
}
$instanceCfgLines = @(
"[General]",
"ConfigVersion=1.2",
"name=$InstanceName",
"icon=default",
"InstanceType=OneSix",
"OverrideJava=true",
"OverrideJavaArgs=true",
"OverrideMemory=$memOverride",
"MinMemAlloc=512",
"MaxMemAlloc=2048",
"JavaPath=$javaPathEscaped",
"JvmArgs=$jvmArgs",
"JoinServerOnLaunch=true",
"JoinServerOnLaunchAddress=donutsmp.net",
"LogPrePostOutput=true"
)
[System.IO.File]::WriteAllLines((Join-Path $InstanceDir "instance.cfg"), $instanceCfgLines, [System.Text.Encoding]::UTF8)
if ($LimitRamCpu) {
Write-Success "Instance $InstanceName da duoc tao thanh cong (Gioi han: 2GB RAM & 2 CPU Cores - donutsmp.net)!"
} else {
Write-Success "Instance $InstanceName da duoc tao thanh cong (KHONG gioi han RAM/CPU - donutsmp.net)!"
}
$serversDatFile = Join-Path $MinecraftDir "servers.dat"
if (-not (Test-Path $serversDatFile)) {
$serversDatB64 = "CgAACQAHc2VydmVycwoAAAABCAACaXAADGRvbnV0c21wLm5ldAgABG5hbWUACERvbnV0U01QAQAOYWNjZXB0VGV4dHVyZXMBAAA="
[System.IO.File]::WriteAllBytes($serversDatFile, [Convert]::FromBase64String($serversDatB64))
Write-Success "Da cau hinh servers.dat (DonutSMP - donutsmp.net)"
} else {
Write-Success "servers.dat da ton tai, giu nguyen danh sach server!"
}
$prismCfgFile = Join-Path $PrismDir "prismlauncher.cfg"
$currentHost = [System.Net.Dns]::GetHostName()
$prismCfgLines = @("[General]","ConfigVersion=1.2","Language=en_US","ApplicationTheme=system","IconTheme=pe_colored","LastHostname=$currentHost","JavaPath=$javaPathEscaped","MinMemAlloc=512","MaxMemAlloc=1536","AutomaticJavaDownload=true","AutomaticJavaSwitch=true","UserAskedAboutAutomaticJavaDownload=true","Analytics=false","CheckForUpdates=false")
[System.IO.File]::WriteAllLines($prismCfgFile, $prismCfgLines, [System.Text.Encoding]::UTF8)
Write-Success "Da cau hinh prismlauncher.cfg (Bo qua 100% Quick Setup Wizard)"
$accountsFile = Join-Path $PrismDir "accounts.json"
if (-not (Test-Path $accountsFile)) {
$accountsData = @{
accounts = @()
formatVersion = 3
}
$accJsonStr = $accountsData | ConvertTo-Json -Depth 10
[System.IO.File]::WriteAllText($accountsFile, $accJsonStr, [System.Text.Encoding]::UTF8)
Write-Success "Da khoi tao accounts.json san sang dang nhap Microsoft cho donutsmp.net"
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
Write-Title "BUOC 6: TAI 18 MODS TU GOOGLE DRIVE"
$modsList = @(
@{ Id = "1P89LBaIvgWtNFi3YiTEu3WYmnosKhhd5"; Name = "AutoRotate-1.1-R2-nohwid.jar" },
@{ Id = "1ncv-dODi1VEmxqbnVwdQsnybdomoGSiL"; Name = "autosell.jar" },
@{ Id = "1t3TRks59ULGezskip_lyLyWJzybYur2F"; Name = "cloth-config-21.11.153-fabric.jar" },
@{ Id = "1lefcwA0Rhi0gDXiV8rLiRc7UYcvJrMKe"; Name = "CRACKEDBYGOOBER_marlowwwclient-v4.jar.disabled" },
@{ Id = "1YvKY75db5erEs3qJoNcnCskVFkmDGfh8"; Name = "entityculling-fabric-1.10.5-mc1.21.11.jar" },
@{ Id = "1OZWQP3Tby89Of8brBVv3L5F9spsdGrq2"; Name = "fabric-api-0.141.4+1.21.11.jar" },
@{ Id = "1kLLmW-acedBiOeqRDzNZMi_itXTdu54K"; Name = "ferritecore-8.2.0-fabric.jar" },
@{ Id = "1eAStuadWw6IcL7MmHGMvpumps-7GZlGp"; Name = "ImmediatelyFast-Fabric-1.14.3+1.21.11.jar" },

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
Remove-Item (Join-Path $ModsDir "iris-fabric*") -Force -ErrorAction SilentlyContinue
Remove-Item (Join-Path $ModsDir "* (1).jar") -Force -ErrorAction SilentlyContinue
Remove-Item (Join-Path $ModsDir "*.tmp") -Force -ErrorAction SilentlyContinue
$count = 0
foreach ($mod in $modsList) {
$count++
$targetModFile = Join-Path $ModsDir $mod.Name
if (Test-ValidJar $targetModFile) {
Write-Host "  [$count/$($modsList.Count)] Da co san & nguyen ven: $($mod.Name) (Bo qua)" -ForegroundColor DarkGray
} else {
if (Test-Path $targetModFile) {
Write-Host "  [!] Phat hien mod loi hoac chua xong: $($mod.Name) -> Dang tai lai..." -ForegroundColor Yellow
Remove-Item $targetModFile -Force -ErrorAction SilentlyContinue
}
Write-Host "  [$count/$($modsList.Count)] " -ForegroundColor Yellow -NoNewline
Download-DriveFile -FileId $mod.Id -OutFile $targetModFile -Desc $mod.Name | Out-Null
if (-not (Test-ValidJar $targetModFile)) {
Remove-Item $targetModFile -Force -ErrorAction SilentlyContinue
Download-DriveFile -FileId $mod.Id -OutFile $targetModFile -Desc "$($mod.Name) (Thu lai)" | Out-Null
}
}
}
Write-Success "Tat ca 18 Mods da duoc tai vao: $ModsDir"
Write-Title "BUOC 7: CAI DAT CONFIG AUTO SELL (MOD AUTOSELL)"
$autoSellConfig = Join-Path $ConfigDir "autosell.json"
$autoSellId = "1sYzi_pcc9KtqWWekSb4sWjuU6xnsvnB_"
if ((Test-Path $autoSellConfig) -and ((Get-Item $autoSellConfig).Length -gt 100)) {
Write-Success "Config autosell.json da ton tai, bo qua tai xuong tu Drive!"
} else {
Write-Step "7/10" "Dang tai config autosell.json moi tu Google Drive..."
$dlOk = Download-DriveFile -FileId $autoSellId -OutFile $autoSellConfig -Desc "autosell.json"
if (-not $dlOk) {
$localAutoSell = Join-Path $ScriptDir "data\autosell.json"
if (Test-Path $localAutoSell) {
Copy-Item -Path $localAutoSell -Destination $autoSellConfig -Force
Write-Success "Da copy config autosell.json tu ban sao luu data/"
}
} else {
Write-Success "Config AutoSell da duoc cai dat tai: $autoSellConfig"
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
Write-Success "Da tu dong cap nhat Discord Webhook vao: $autoSellConfig"
} catch {
Write-Warn "Khong the ghi Webhook vao autosell.json: $_"
}
} else {
Write-Host "  (Khong thay doi Discord Webhook cho AutoSell)" -ForegroundColor DarkGray
}
}
Write-Title "BUOC 8: CAI DAT CONFIG NO RENDER & AUTO PAY CHO METEOR CLIENT"
$cfgNoRenderPath = Join-Path $MeteorDir "config no render.txt"
$rawNoRenderTxt = Join-Path $TempDir "raw_no_render.txt"
if (-not (Test-Path $cfgNoRenderPath)) {
$noRenderId = "1uKBRRd9WHBoCTiLFcjW1imWfseCR5MhA"
Write-Step "8/10" "Dang tai du lieu config no-render cua Meteor Client..."
Download-DriveFile -FileId $noRenderId -OutFile $rawNoRenderTxt -Desc "config no render (raw)" | Out-Null
} else {
Write-Success "Config No-Render da ton tai, bo qua tai xuong tu Drive!"
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
$destList = @(
(Join-Path $MeteorDir "modules\No Render.nbt"),
(Join-Path $MeteorDir "modules\no-render.nbt"),
(Join-Path $MeteorDir "presets\no-render.nbt"),
(Join-Path $MeteorDir "presets\no-render\default.nbt"),
(Join-Path $MeteorDir "no-render.nbt")
)
foreach ($dst in $destList) {
$p = Split-Path -Parent $dst
if (-not (Test-Path $p)) { New-Item -ItemType Directory -Path $p -Force | Out-Null }
[System.IO.File]::WriteAllBytes($dst, $noRenderBytes)
}
$moduleCount = 1
$spamCompBytes = $null
if ($EnableAutoPay -and (-not [string]::IsNullOrWhiteSpace($AutoPayCmd))) {
$moduleCount = 2
$spamCompBytes = Build-SpamNbtBytes -PayCommand $AutoPayCmd -Delay 400
$spamStandaloneMs = New-Object System.IO.MemoryStream
$spamStandaloneMs.WriteByte(10)
$spamStandaloneMs.WriteByte(0); $spamStandaloneMs.WriteByte(0)
$spamStandaloneMs.Write($spamCompBytes, 0, $spamCompBytes.Length)
$spamGzBytes = Compress-GZipBytes -Data ($spamStandaloneMs.ToArray())
$spamDestList = @(
(Join-Path $MeteorDir "modules\Spam.nbt"),
(Join-Path $MeteorDir "modules\spam.nbt"),
(Join-Path $MeteorDir "presets\spam.nbt"),
(Join-Path $MeteorDir "presets\spam\default.nbt")
)
foreach ($sd in $spamDestList) {
$sp = Split-Path -Parent $sd
if (-not (Test-Path $sp)) { New-Item -ItemType Directory -Path $sp -Force | Out-Null }
[System.IO.File]::WriteAllBytes($sd, $spamGzBytes)
}
$spamB64 = [Convert]::ToBase64String($spamGzBytes)
[System.IO.File]::WriteAllText((Join-Path $MeteorDir "config spam auto pay.txt"), $spamB64, [System.Text.Encoding]::UTF8)
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
[System.IO.File]::WriteAllBytes((Join-Path $MeteorDir "modules.nbt"), $finalGzModules)
$payCfgObj = @{
user = $PayUser
amount = $PayAmount
enabled = $EnableAutoPay
updated = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
}
$payJson = $payCfgObj | ConvertTo-Json -Compress
[System.IO.File]::WriteAllText((Join-Path $MeteorDir "pay_config.json"), $payJson, [System.Text.Encoding]::UTF8)
Write-Success "Config No-Render da duoc cai dat & TU DONG BAT SAN tren Meteor Client!"
if ($EnableAutoPay) {
Write-Success "Config Auto Pay ($AutoPayCmd | Delay: 400 | Tat Disable On Leave & Disconnect) da duoc TU DONG BAT SAN!"
}
} catch {
Write-Warn "Khong the khoi tao modules.nbt tu dong: $_"
}
Write-Title "BUOC 9: CAI DAT RESOURCE PACK (BEATRIX SHOP)"
$packId = "1sJoybUBUmIM0Kcsus9AXYZ8_c6JBAJ1M"
$packName = "beatrix_shop 1.9v1.zip"
$targetPack = Join-Path $ResourcePacksDir $packName
$packReady = $false
if ((Test-Path $targetPack) -and ((Get-Item $targetPack).Length -gt 10000000)) {
$packReady = $true
Write-Success "Resource Pack $packName da ton tai ($([math]::Round((Get-Item $targetPack).Length/1MB, 1)) MB), bo qua tai xuong!"
} else {
Write-Step "9/10" "Dang tai Resource Pack beatrix_shop (30MB) tu Google Drive..."
$dlPack = Download-DriveFile -FileId $packId -OutFile $targetPack -Desc $packName
if ($dlPack) { $packReady = $true; Write-Success "Resource Pack da duoc cai dat tai: $targetPack" }
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
Write-Title "BUOC 10: TAO CAU HINH OPTIONS.TXT SIEU NHE CHO VPS"
$optionsFile = Join-Path $MinecraftDir "options.txt"
if (-not (Test-Path $optionsFile)) {
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
[System.IO.File]::WriteAllLines($optionsFile, $optionsLines, [System.Text.Encoding]::UTF8)
Write-Success "Da cau hinh options.txt (Sodium): Render Distance 32 Chunks, Simulation Distance 32 Chunks, 120 FPS, VSync ON, Active Resource Pack!"
} else {
Write-Success "options.txt da ton tai, giu nguyen cac cai dat tuy chinh cua ban!"
}
if ($InstanceCount -gt 1) {
Write-Title "KHOI TAO THEM INSTANCE CHO VPS 8-8 (TOI DA $InstanceCount INSTANCE)"
for ($i = 2; $i -le $InstanceCount; $i++) {
$nextName = "VPS-AFK-$i"
$nextDir = Join-Path $PrismDir "instances\$nextName"
Write-Step "$i/$InstanceCount" "Dang khoi tao $nextName tu instance goc (sao chep mods, configs, options)..."
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
"MinMemAlloc=512",
"MaxMemAlloc=2048",
"JavaPath=$javaPathEscaped",
"JvmArgs=-XX:+UseG1GC -XX:ActiveProcessorCount=2 -XX:ParallelGCThreads=2 -XX:ConcGCThreads=1 -XX:+ParallelRefProcEnabled -XX:+AlwaysPreTouch -Dsun.java2d.opengl=false",
"JoinServerOnLaunch=true",
"JoinServerOnLaunchAddress=donutsmp.net",
"LogPrePostOutput=true"
)
[System.IO.File]::WriteAllLines((Join-Path $nextDir "instance.cfg"), $nextCfgLines, [System.Text.Encoding]::UTF8)
$nextMinecraftDir = Join-Path $nextDir ".minecraft"
if (Test-Path $nextMinecraftDir) { Remove-Item -Path $nextMinecraftDir -Recurse -Force -ErrorAction SilentlyContinue }
Copy-Item -Path $MinecraftDir -Destination $nextMinecraftDir -Recurse -Force
Remove-Item (Join-Path $nextMinecraftDir "mods\iris-fabric*") -Force -ErrorAction SilentlyContinue
Write-Success "Instance $nextName da duoc tao thanh cong (Gioi han: 2GB RAM & 2 CPU Cores)!"
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
Write-Title "BUOC 11: CAI DAT VA CAU HINH MEM REDUCT (GIAI PHONG RAM TU DONG CHO VPS)"
$memReductDir = Join-Path $BaseDir "MemReduct"
$memReductExe = Join-Path $memReductDir "memreduct.exe"
if (Test-Path $memReductExe) {
Write-Success "Mem Reduct da ton tai tai: $memReductExe, bo qua tai xuong!"
} else {
$memReduct7z = Join-Path $TempDir "memreduct.7z"
$memReductUrl = "https://github.com/henrypp/memreduct/releases/download/v.3.5.2/memreduct-3.5.2-bin.7z"
Write-Step "11/11" "Dang tai Mem Reduct Portable tu GitHub..."
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
$mrIniLines = @("[memreduct]","AlwaysOnTop=0","AutoreductEnable=1","AutoreductValue=85","AutoreductIntervalEnable=1","AutoreductIntervalValue=30","ReductMask2=26","IsAllowStandbyListCleanup=1","BalloonCleanResults=0","IsNotificationsSound=0","IsShowWarningConfirmation=0","IsShowReductConfirmation=0","IsStartMinimized=1","IsCloseToTray=1","IsMinimizeToTray=1","CheckUpdatesPeriod=0","CheckUpdates=0")
[System.IO.File]::WriteAllLines((Join-Path $memReductDir "memreduct.ini"), $mrIniLines, [System.Text.Encoding]::Unicode)
$appDataMrDir = Join-Path $env:APPDATA "Henry++\Mem Reduct"
if (-not (Test-Path $appDataMrDir)) { New-Item -ItemType Directory -Path $appDataMrDir -Force | Out-Null }
[System.IO.File]::WriteAllLines((Join-Path $appDataMrDir "memreduct.ini"), $mrIniLines, [System.Text.Encoding]::Unicode)

try {
$runKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
Set-ItemProperty -Path $runKey -Name "MemReduct" -Value "`"$memReductExe`" -minimized" -Force
try { & schtasks.exe /Create /TN "memreductTask" /TR "`"$memReductExe`" -minimized" /SC ONLOGON /RL HIGHEST /F 2>$null | Out-Null } catch {}
Write-Success "Da them Mem Reduct vao Windows Startup & Skip UAC (Tu khoi dong ngam cung VPS)!"
} catch {
Write-Warn "Khong the them vao Registry Startup: $_"
}
Stop-Process -Name "memreduct" -Force -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 300
try {
Start-Process -FilePath $memReductExe -ArgumentList "-minimized"
Write-Success "Mem Reduct da duoc khoi chay ngam duoi khay he thong!"
} catch {
Write-Warn "Khong the khoi chay Mem Reduct: $_"
}
Write-Success "Mem Reduct da duoc cau hinh chuan: Don RAM moi 30 phut & khi > 85%, bao ve RAM Java (bo Working Set), tat thong bao!"
} else {
Write-Warn "Khong the cai dat Mem Reduct tu dong."
}
Write-Title "TAO SCRIPT HO TRO VA PHIM TAT 1-CLICK TREN DESKTOP"
Remove-Item (Join-Path $BaseDir "run-afk.bat") -Force -ErrorAction SilentlyContinue
$openPrismBat = Join-Path $BaseDir "open-prism.bat"
$openPrismBatLines = @(
"@echo off",
"title Prism Launcher",
'set "APP_DIR=C:\MinecraftVPS\PrismLauncher"',
'if not exist "%APP_DIR%" set "APP_DIR=%~dp0\PrismLauncher"',
'cd /d "%APP_DIR%"',
'start "" prismlauncher.exe',
"exit"
)
[System.IO.File]::WriteAllLines($openPrismBat, $openPrismBatLines, [System.Text.Encoding]::ASCII)
$loginMsBat = Join-Path $BaseDir "login-microsoft.bat"
$loginMsBatLines = @(
"@echo off",
"chcp 65001 >nul",
"title Dang Nhap Tai Khoan Microsoft - Prism Launcher",
'set "APP_DIR=C:\MinecraftVPS\PrismLauncher"',
'if not exist "%APP_DIR%" set "APP_DIR=%~dp0\PrismLauncher"',
'cd /d "%APP_DIR%"',
"echo   HUONG DAN DANG NHAP MICROSOFT (CHI LAM 1 LAN DAU)",
"echo 1. Tren Prism Launcher: Bam goc tren phai [Accounts] -^> [Manage Accounts].",
"echo 2. Bam [Add Microsoft] o cot ben phai.",
"echo 3. Bam [Open Page and Copy Code] -^> Trinh duyet mo trang microsoft.com/link.",
"echo 4. Nhan Ctrl+V dan ma Code -^> Dang nhap tai khoan Microsoft cua ban.",
"echo 5. Nick Minecraft se tu xuat hien tren Prism Launcher! Terminal se tu dong!",
'start "" prismlauncher.exe',
'echo Dang cho dang nhap Microsoft... (Tu dong dong terminal khi xong)',
'powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "& { $f = ''accounts.json''; while ($true) { Start-Sleep -Seconds 2; if (Test-Path $f) { try { $j = Get-Content $f -Raw | ConvertFrom-Json; if ($j.accounts -and $j.accounts.Count -gt 0) { exit } } catch {} } } }"',
'exit'
)
[System.IO.File]::WriteAllLines($loginMsBat, $loginMsBatLines, [System.Text.Encoding]::UTF8)
$watchdogUiPs1 = Join-Path $BaseDir "watchdog-ui.ps1"
$watchdogUiGzB64 = "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"
$watchdogUiBytes = Decompress-GZipBytes -Data ([Convert]::FromBase64String($watchdogUiGzB64))
if ($watchdogUiBytes.Length -gt 3 -and ($watchdogUiBytes[0] -ne 0xEF -or $watchdogUiBytes[1] -ne 0xBB -or $watchdogUiBytes[2] -ne 0xBF)) {
$watchdogUiBytes = [byte[]]@(0xEF, 0xBB, 0xBF) + $watchdogUiBytes
}
[System.IO.File]::WriteAllBytes($watchdogUiPs1, $watchdogUiBytes)
$watchdogBat = Join-Path $BaseDir "run-watchdog.bat"
$watchdogBatLines = @(
"@echo off",
"chcp 65001 >nul",
"title Auto Check Connect 24-7 - donutsmp.net",
'cd /d "%~dp0"',
'set "SCRIPT=C:\MinecraftVPS\watchdog-ui.ps1"',
'if not exist "%SCRIPT%" set "SCRIPT=%~dp0watchdog-ui.ps1"',
'powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%SCRIPT%"',
"exit"
)
[System.IO.File]::WriteAllLines($watchdogBat, $watchdogBatLines, [System.Text.Encoding]::UTF8)
$runMrBat = Join-Path $BaseDir "run-memreduct.bat"
$runMrBatLines = @(
"@echo off",
"title Mem Reduct",
'set "APP_DIR=C:\MinecraftVPS\MemReduct"',
'if not exist "%APP_DIR%" set "APP_DIR=%~dp0\MemReduct"',
'cd /d "%APP_DIR%"',
'start "" memreduct.exe -minimized',
"exit"
)
[System.IO.File]::WriteAllLines($runMrBat, $runMrBatLines, [System.Text.Encoding]::ASCII)
$payPs1 = Join-Path $BaseDir "quan-ly-pay.ps1"
$payBat = Join-Path $BaseDir "quan-ly-pay.bat"
$payAppGzB64 = "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"
$payAppBytes = Decompress-GZipBytes -Data ([Convert]::FromBase64String($payAppGzB64))
if ($payAppBytes.Length -gt 3 -and ($payAppBytes[0] -ne 0xEF -or $payAppBytes[1] -ne 0xBB -or $payAppBytes[2] -ne 0xBF)) {
$payAppBytes = [byte[]]@(0xEF, 0xBB, 0xBF) + $payAppBytes
}
[System.IO.File]::WriteAllBytes($payPs1, $payAppBytes)
$payBatLines = @(
"@echo off",
"title Quan Ly Auto Pay (DonutSMP)",
'set "SCRIPT=C:\MinecraftVPS\quan-ly-pay.ps1"',
'if not exist "%SCRIPT%" set "SCRIPT=%~dp0quan-ly-pay.ps1"',
'powershell -ExecutionPolicy Bypass -WindowStyle Hidden -File "%SCRIPT%"',
"exit"
)
[System.IO.File]::WriteAllLines($payBat, $payBatLines, [System.Text.Encoding]::ASCII)
$Desktop = [Environment]::GetFolderPath('Desktop')
if ($Desktop -and (Test-Path $Desktop)) {
Remove-Item (Join-Path $Desktop "*Chay Minecraft AFK*") -Force -ErrorAction SilentlyContinue
Remove-Item (Join-Path $Desktop "2. Auto Restart*") -Force -ErrorAction SilentlyContinue
Remove-Item (Join-Path $Desktop "3. Quan Ly Auto Pay*") -Force -ErrorAction SilentlyContinue
Remove-Item (Join-Path $Desktop "4. Don RAM*") -Force -ErrorAction SilentlyContinue
Remove-Item (Join-Path $Desktop "5. Mo Prism Launcher*") -Force -ErrorAction SilentlyContinue
Copy-Item -Path $loginMsBat -Destination (Join-Path $Desktop "1. Dang Nhap Microsoft.bat") -Force
Copy-Item -Path $watchdogBat -Destination (Join-Path $Desktop "3. Auto Restart 24-7 (Watchdog).bat") -Force
Copy-Item -Path $payBat -Destination (Join-Path $Desktop "4. Quan Ly Auto Pay.bat") -Force
Copy-Item -Path $runMrBat -Destination (Join-Path $Desktop "5. Don RAM (Mem Reduct).bat") -Force
Copy-Item -Path $openPrismBat -Destination (Join-Path $Desktop "6. Mo Prism Launcher.bat") -Force
Write-Success "Da don sach file cu thua va cap nhat 5 phim tat tren Desktop VPS!"
}
Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue
Write-Title "HOAN TAT CAI DAT 100%! MINECRAFT VPS DA SAN SANG"
Write-Host " [OK] Prism Launcher & Java 21 & Mesa3D OpenGL (Fix GLFW 65542) : SAN SANG" -ForegroundColor Green
Write-Host " [OK] Instance $InstanceName (Fabric 1.21.11 - donutsmp.net)        : DA KHOI TAO" -ForegroundColor Green
Write-Host " [OK] 18 Mods + Meteor (No-Render) + AutoSell + Beatrix Shop Pack   : DA CAI DAT" -ForegroundColor Green
Write-Host " [OK] Mem Reduct: Chay ngam tu dong giai phong RAM moi 30 phut      : DANG CHAY" -ForegroundColor Green
Write-Host " [OK] Da tao 5 phim tat 1-click truc tiep ngoai Desktop!" -ForegroundColor Green
Write-Host ""
Write-Host "QUY TRINH BAT DAU AFK TREN DONUTSMP.NET:" -ForegroundColor Yellow
Write-Host "  1. [1. Dang Nhap Microsoft.bat]          -> Login nick (chi lam 1 lan dau)" -ForegroundColor Cyan
Write-Host "  2. [3. Auto Restart 24-7 (Watchdog).bat] -> Vao game & auto reconnect 24/7!" -ForegroundColor Green
Write-Host "  3. [4. Quan Ly Auto Pay.bat]             -> Doi nick nhan tien / so tien" -ForegroundColor Cyan
Write-Host "  4. [5. Don RAM (Mem Reduct).bat]         -> Giai phong RAM (chay ngam)" -ForegroundColor Cyan
Write-Host "  5. [6. Mo Prism Launcher.bat]            -> Mo Prism Launcher" -ForegroundColor Cyan
Write-Host ""
Write-Host "Chuc ban treo bot AFK thanh cong!" -ForegroundColor Magenta