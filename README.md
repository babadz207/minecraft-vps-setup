# Bộ Tool Auto Setup Minecraft VPS Non-GPU (Fabric 1.21.11 + Prism Launcher)
### Chuyên Dụng Treo AFK 24/7 Server DonutSMP (`donutsmp.net`)

> **Giải pháp tối ưu hóa 100% cho VPS không có card đồ họa (GPU):**
> - Fix triệt để lỗi **`GLFW error 65542: The driver does not appear to support OpenGL`**.
> - Tích hợp giả lập đồ họa bằng CPU **Mesa3D Software OpenGL (llvmpipe)**.
> - Cài đặt tự động **Prism Launcher Portable**, **Java 21 Portable (Adoptium Temurin)**, và **Visual C++ Redistributable 2015-2022**.
> - Tích hợp sẵn kết nối server bản quyền **`donutsmp.net`** (tự động đưa vào `servers.dat` và `instance.cfg`).
> - Hỗ trợ đăng nhập tài khoản **Microsoft chính thức** tiện lợi qua mã Device Code (`microsoft.com/link`).
> - Cài đặt toàn bộ **17 Mods tối ưu** (tự động loại bỏ Iris Shader để tránh crash trên VPS không có GPU), **Config AutoSell mới nhất**, **Config No-Render (Meteor Client)**, và **Resource Pack Beatrix Shop** từ Google Drive.
> - Cấu hình sẵn **Sodium**: Render Distance 32 Chunks, Simulation Distance 32 Chunks, 120 FPS, VSync ON.
> - Cài đặt và cấu hình sẵn **Mem Reduct**: Dọn RAM tự động khi > 85% & mỗi 30 phút, bảo vệ RAM Java, tắt âm thanh và thông báo bong bóng.
> - Tích hợp **Watchdog 24/7**: Tự động mở lại game sau 10s khi crash hoặc tự động reconnect khi bị kick/văng khỏi server DonutSMP!

---

## 🚀 1. Lệnh 1 Dòng Duy Nhất Trên VPS Mới (Không Cần Tải Gì Trước)

Nếu bạn vừa thuê một VPS mới tinh (hoàn toàn trống), chỉ cần mở **PowerShell** (Run as Administrator) trên VPS, dán đúng **1 dòng lệnh sau rồi bấm Enter**:

```powershell
[Net.ServicePointManager]::SecurityProtocol=3072; irm https://raw.githubusercontent.com/babadz207/minecraft-vps-setup/main/setup-vps.ps1 | iex
```

*Hoặc nếu mạng VPS của bạn bị lỗi TLS/EOF với `irm`, dùng lệnh `curl` có sẵn trên Windows:*
```powershell
curl.exe -sL https://raw.githubusercontent.com/babadz207/minecraft-vps-setup/main/setup-vps.ps1 | iex
```

*(Hoặc nếu đang có sẵn thư mục tool, bạn có thể chạy `setup.bat` hoặc gõ `.\setup-vps.ps1`)*

> [!NOTE]
> **Cơ Chế Cập Nhật Thông Minh (Smart Update & Idempotency)**:
> - **Nếu file/thành phần đã có đầy đủ**: Tool tự động **BỎ QUA TẢI LẠI** đối với các file nặng như Visual C++, Prism Launcher, Java 21, Mesa3D OpenGL (`opengl32.dll`), toàn bộ 18 Mods, Resource Pack Beatrix Shop (~30MB), `accounts.json` (giữ nguyên nick đã đăng nhập), `servers.dat`, `options.txt` (giữ nguyên cài đặt game). Quá trình chạy lại trên VPS đã cài chỉ mất vài giây!
> - **Nếu có bản cập nhật script/công cụ**: Tool sẽ **TỰ ĐỘNG CẬP NHẬT** ngay lập tức các script điều khiển, giao diện và cấu hình (`run-afk.bat`, `watchdog-ui.ps1`, `login-microsoft.bat`, `quan-ly-pay.ps1/bat`, `run-memreduct.bat`, `open-prism.bat`, `prismlauncher.cfg`, `memreduct.ini`) để đảm bảo luôn dùng phiên bản mới nhất, fix lỗi triệt để!


> [!TIP]
> **Các tùy chọn cấu hình tự động khi chạy lệnh**:
> 1. **Tự động nhận diện cấu hình VPS 4-4 vs VPS 8-8**:
>    - **VPS 4-4 (<= 4 Cores, <= 6GB RAM)**: Mặc định tạo **1 Instance duy nhất** (`VPS-AFK-1`), **KHÔNG GIỚI HẠN RAM & CPU** (Minecraft tự do sử dụng toàn bộ tài nguyên VPS).
>    - **VPS 8-8 (>= 6 Cores, >= 7GB RAM)**: Cho phép tạo **tối đa 3 Instance** (`VPS-AFK-1`, `VPS-AFK-2`, `VPS-AFK-3`), **TỰ ĐỘNG GIỚI HẠN RAM & CPU** cho mỗi instance (2GB RAM + 2 CPU Cores qua JVM `-XX:ActiveProcessorCount=2` & `LP_NUM_THREADS=2`), đảm bảo chạy cùng lúc 3 bot mà CPU & RAM không bao giờ bị quá tải!
> 2. **Quản lý tài khoản riêng biệt cho từng Instance**:
>    - Mỗi instance liên kết với 1 tài khoản Microsoft riêng qua `--profile <Account>`.
> 3. **Tùy chỉnh Delay mở bot**:
>    - Tùy chỉnh số giây delay giữa các instance (mặc định 25 giây) để tránh việc mở cùng lúc làm CPU vọt 100% hoặc tràn RAM VPS.
> 4. **Giao diện Auto Check Connect 24/7 (Watchdog UI)**:
>    - Tích hợp sẵn giao diện GUI trực quan: chọn các instance cần auto, xem live RAM/PID, và **nút DỪNG TẤT CẢ INSTANCE khẩn cấp**.
> 5. **Discord Webhook cho AutoSell**:
>    `Nhap Discord Webhook (hoac nhan ENTER de bo qua): `
>    - Dán link Webhook: Tool tự động điền vào config `autosell.json`!
>    - Nhấn **ENTER**: Bỏ qua Webhook.
> 6. **Auto Pay DonutSMP (Meteor Client Spam)**:
>    `Nhap ten user muon Auto Pay (hoac nhan ENTER de bo qua): `
>    - Nhập tên nick (ví dụ `kajiuxz`): Tool sẽ hỏi tiếp số M (`Nhap so M muon pay: 1`).
>    - Tool hiển thị lệnh sẽ chạy (`/pay kajiuxz 1M`, Delay 400 ticks) và hỏi xác nhận: `Xac nhan cau hinh Auto Pay nay? (y/n)`.
>    - Trả lời **`y`**: Tool cấu hình duy nhất 1 lệnh `/pay <user> <M>`, đặt delay chuẩn 400 ticks, tắt `disable-on-leave` và `disable-on-disconnect`, đồng thời **TỰ ĐỘNG BẬT SẴN** module Spam khi vào game!
>    - Nhấn **ENTER** ở bước nhập tên hoặc chọn **`n`**: Bỏ qua tính năng Auto Pay.
> 7. **Tự động BẬT SẴN No-Render**: Config No-Render được tích hợp trực tiếp vào `modules.nbt` với trạng thái `active: 1`, game vừa mở lên là No-Render đã tự động bật ngay lập tức, tiết kiệm 80% CPU!
> 8. **Tích hợp sẵn App Quản Lý Auto Pay**: Đặt sẵn ngoài màn hình Desktop, áp dụng đồng bộ cho tất cả các Instance trong 1 cú click!

---

## 🖥️ 3. Desktop Applications (Zero-Terminal & Ultra-Optimized)

After running the auto setup, your VPS Desktop will be cleaned of all legacy `.bat` files and populated with **5 pure Windows GUI (`.exe`) applications**. Double-clicking any tool will **NEVER open or flash a black command prompt/terminal window**:

| Desktop Application | Subsystem | Features & Capabilities (Zero Terminal Popups) |
| :--- | :--- | :--- |
| **`1. Microsoft Login.exe`** | **WinGUI** | Clean step-by-step Microsoft authentication guide with 1-click buttons to launch Prism Launcher and open `microsoft.com/link`. |
| **`2. Auto Reconnect 24-7 (Watchdog).exe`** | **WinGUI Pro Max** | **24/7 Monitoring Dashboard**: Individual instance cards, live PID & RAM meters, auto-detect disconnects via `latest.log`, automated safe reconnect, and **STOP ALL INSTANCES**. |
| **`3. Auto Pay Manager.exe`** | **WinGUI Pro Max** | Fast configuration for recipient username and payment amount (`10`, `1M`, `2M`, `500k`...), automated Meteor Client NBT generator, and safe instance relaunch! |
| **`4. Clean RAM (Mem Reduct).exe`** | **Silent Launcher** | Instantly runs Mem Reduct minimized to the system tray to clear standby cache, with zero console window. |
| **`5. Open Prism Launcher.exe`** | **Silent Launcher** | Direct launcher for Prism Launcher to adjust instance settings, view console, or manage mods. |

---

### ⚡ Low-Resource VPS Optimizations Built-In:
- **Render Distance**: Set to **2 Chunks** (saves ~99% chunk mesh rendering vs 32 chunks).
- **Max FPS**: Capped at **20 FPS** (cuts Mesa3D software CPU rasterization by **83%**).
- **Sodium CPU Tuning**: `chunk_builder_threads: 1`, `always_defer_chunk_updates: true`, `animate_only_visible_textures: true`.
- **Mesa3D llvmpipe Tuning**: Adaptive thread scaling (`LP_NUM_THREADS=1` on <= 4-core VPS) prevents software rendering from starving the CPU.
- **Process Detection**: Native Win32 API + PID caching eliminates periodic WMI calls, keeping Watchdog CPU consumption at **0.00%**.
- **Process Priority**: Minecraft processes are automatically set to `BelowNormal` priority to protect Remote Desktop (RDP) responsiveness.
- **Audio Thread Offloading**: All Minecraft audio channels set to `0.0`, completely eliminating sound mixer CPU threads.

---

### 🎮 How to Use `2. Auto Reconnect 24-7 (Watchdog).exe`:
1. Double-click **`2. Auto Reconnect 24-7 (Watchdog).exe`** on Desktop.
2. The dashboard displays all detected instances (`VPS-AFK-1`, `2`, `3`) with linked account tags and live status badges (`● RUNNING`, `○ STOPPED`, `⌛ WAITING`).
3. Set your preferred **Launch Delay** (default: 25s) to prevent CPU and RAM spikes.
4. Check the instances you want to run, then click **`▶ START AUTO RECONNECT (24/7)`**.
5. The watchdog will launch each bot sequentially, continuously monitor `latest.log` every 5 seconds for network drops, and automatically restart disconnected bots safely.
6. Click **`🛑 STOP ALL RUNNING INSTANCES`** anytime for an immediate emergency shutdown.

---

### 💡 How to Use `3. Auto Pay Manager.exe`:
1. Double-click **`3. Auto Pay Manager.exe`** on Desktop.
2. The current pay command and active status are read directly from Meteor Client's config.
3. Enter the **Recipient Username** and **Amount** (e.g. `10` or `1M`).
4. Keep **Enable automated /pay** checked.
5. Click **`💾 SAVE CONFIG & RESTART MINECRAFT`**.
6. The application generates the binary NBT configurations (`modules.nbt`, `Spam.nbt`), applies them across all instances, and safely restarts the clients!

---

## 📦 4. Danh Sách Thành Phần Được Cài Đặt Tự Động

| Thành phần | Chi tiết & Nguồn | Mục đích trên VPS |
| :--- | :--- | :--- |
| **Visual C++ x64** | `https://aka.ms/vs/17/release/vc_redist.x64.exe` | Thư viện C++ runtime bắt buộc cho Java, Prism Launcher và Mesa3D |
| **Prism Launcher** | GitHub Latest Release (Portable Mode) | Launcher quản lý instance và tài khoản cực nhẹ, không cài rác hệ thống |
| **Java 21 OpenJDK** | Eclipse Temurin 21 JRE x64 Portable | Môi trường chạy Minecraft 1.21+ chuẩn nhất, không cần cài Java ngoài hệ thống |
| **Mesa3D llvmpipe** | `pal1000/mesa-dist-win` | Giả lập OpenGL 4.5 bằng CPU, bypass triệt để lỗi `GLFW error 65542` khi không có GPU |
| **Fabric 1.21.11** | Instance `VPS-AFK-1` | **Fabric Loader 0.19.5 (Bản mới nhất)** tương thích 100% với Fabric API & AutoSell |
| **17 Fabric Mods** | Tải từ Google Drive | Đầy đủ mod tối ưu (Sodium, FerriteCore, Lithium,...), Meteor Client, AutoSell,... (Đã loại bỏ Iris gây xung đột) |
| **Config AutoSell** | `.minecraft\config\autosell.json` | Cấu hình tự động bán đồ, whitelist, auto-coordinates (tự điền Webhook nếu có) |
| **Meteor No-Render** | `.minecraft\meteor-client\modules.nbt` | Cấu hình tắt render giảm 80% CPU, **tự động kích hoạt (active: 1)** khi mở game |
| **Meteor Auto Pay (Spam)** | `.minecraft\meteor-client\modules.nbt` | Tự động spam `/pay <user> <amount>` mỗi 400 ticks, tắt disconnect, **tự kích hoạt sẵn** |
| **Resource Pack** | `beatrix_shop 1.9v1.zip` | Đã đặt trong `resourcepacks` và kích hoạt sẵn trong `options.txt` |
| **Mem Reduct** | `henrypp/memreduct` v3.5.2 Portable | Tự động dọn RAM hệ thống mỗi 30 phút & khi RAM > 85%, giữ RAM Java an toàn |


---

## 🧩 5. Danh Sách 18 Mods Tự Động Cài Đặt

1. **AutoRotate-1.1-R2-nohwid.jar**: Mod tự động xoay bot theo kịch bản.
2. **autosell.jar**: Mod tự động bán đồ (AutoSell) tích hợp webhook Discord và thống kê.
3. **cloth-config-21.11.153-fabric.jar**: Thư viện cấu hình mod.
4. **CRACKEDBYGOOBER_marlowwwclient-v4.jar.disabled**: Mod hỗ trợ thêm (để ở trạng thái disabled theo drive).
5. **entityculling-fabric-1.10.5-mc1.21.11.jar**: Ẩn render entity ngoài tầm nhìn, tiết kiệm tối đa CPU.
6. **fabric-api-0.141.4+1.21.11.jar**: Nền tảng Fabric API.
7. **ferritecore-8.2.0-fabric.jar**: Giảm 40-50% lượng RAM sử dụng của Minecraft.
8. **ImmediatelyFast-Fabric-1.14.3+1.21.11.jar**: Tối ưu hóa render giao diện HUD và phông chữ.
9. **iris-fabric-1.10.7+mc1.21.11.jar**: Mod hỗ trợ shader / rendering engine.
10. **litematica-fabric-1.21.11-0.26.12.jar**: Mod hiển thị bản thiết kế schematic.
11. **lithium-fabric-0.21.4+mc1.21.11.jar**: Tối ưu hóa logic game và CPU tick.
12. **malilib-fabric-1.21.11-0.27.16.jar**: Thư viện dùng chung cho Litematica.
13. **meteor-client-1.21.11-82.jar**: Meteor Client hỗ trợ tính năng No-Render và tiện ích AFK.
14. **modmenu-17.0.1-beta.1.jar**: Giao diện quản lý mod trực quan trong game.
15. **opsec-1.21.11+v1.1.7.1.jar**: Mod bảo mật & che giấu thông tin bot.
16. **placeholder-api-2.8.2+1.21.10.jar**: Thư viện text placeholder.
17. **sodium-fabric-0.8.13+mc1.21.11.jar**: Mod tăng tốc render mạnh nhất cho Minecraft.
18. **yet_another_config_lib_v3-3.8.2+1.21.11-fabric.jar**: Thư viện giao diện cấu hình mod.

---

## ⚙️ 6. Chi Tiết Cấu Hình Mem Reduct Chuẩn Xác

Tool đã cấu hình tự động 100% file `memreduct.ini` và Registry:
- **Tab Tray icon**:
  - BỎ TÍCH: `Show memory cleaning results` (tránh tràn lịch sử thông báo trên VPS).
  - BỎ TÍCH: `Enable notifications sound` (tắt chuông thông báo mỗi khi dọn RAM).
- **Tab Memory cleaning**:
  - **Memory management**:
    - TÍCH CHỌN `Clean when above: (%)` -> Đặt **85%**.
    - TÍCH CHỌN `Clean every: (min.)` -> Đặt **30 phút**.
  - **Vùng nhớ dọn dẹp (Memory regions to be cleaned)**:
    - **BỎ TÍCH: `Working set`** (Cực kỳ quan trọng để bảo vệ bộ nhớ RAM của Java Minecraft, không gây giật lag hay khựng game).
    - **TÍCH CHỌN: `Standby list*`**, **`Standby list (without priority)`**, **`System file cache`**.
- Mem Reduct chạy ngầm tự động khởi động cùng VPS, giúp VPS hoạt động mượt mà liên tục hàng tháng trời không lo tràn RAM.
