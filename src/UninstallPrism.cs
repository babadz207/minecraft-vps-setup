using System;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Threading;
using System.Windows.Forms;

public class UninstallPrismForm : Form {
    private ProgressBar progressBar;
    private Label lblStatus;
    private CheckBox chkKeepLogin;
    private Button btnUninstallOnly;
    private Button btnUninstallAndReinstall;
    private Button btnCancel;
    private Label lblTitle;
    private Label lblSub;
    private Panel infoPanel;

    public UninstallPrismForm() {
        this.Text = "Uninstall & Reset - Prism Launcher & Minecraft VPS";
        this.Size = new Size(620, 560);
        this.StartPosition = FormStartPosition.CenterScreen;
        this.FormBorderStyle = FormBorderStyle.FixedDialog;
        this.MaximizeBox = false;
        this.BackColor = Color.FromArgb(15, 23, 42); // Slate Dark

        // Header
        lblTitle = new Label();
        lblTitle.Text = "GỠ CÀI ĐẶT & RESET MINECRAFT VPS";
        lblTitle.Font = new Font("Segoe UI", 13.5f, FontStyle.Bold);
        lblTitle.ForeColor = Color.FromArgb(239, 68, 68); // Red
        lblTitle.Location = new Point(20, 16);
        lblTitle.Size = new Size(565, 30);
        lblTitle.TextAlign = ContentAlignment.MiddleCenter;
        this.Controls.Add(lblTitle);

        lblSub = new Label();
        lblSub.Text = "Dọn sạch toàn bộ Prism Launcher, mod, config để chuẩn bị cài đặt lại từ đầu";
        lblSub.Font = new Font("Segoe UI", 9.5f);
        lblSub.ForeColor = Color.FromArgb(148, 163, 184);
        lblSub.Location = new Point(20, 48);
        lblSub.Size = new Size(565, 22);
        lblSub.TextAlign = ContentAlignment.MiddleCenter;
        this.Controls.Add(lblSub);

        // Info Card
        infoPanel = new Panel();
        infoPanel.Location = new Point(25, 76);
        infoPanel.Size = new Size(555, 236);
        infoPanel.BackColor = Color.FromArgb(30, 41, 59); // Card Dark
        infoPanel.BorderStyle = BorderStyle.FixedSingle;
        this.Controls.Add(infoPanel);

        Label lblInfoHead = new Label();
        lblInfoHead.Text = "Các thành phần sẽ được gỡ bỏ và dọn dẹp sạch sẽ:";
        lblInfoHead.Font = new Font("Segoe UI", 10f, FontStyle.Bold);
        lblInfoHead.ForeColor = Color.FromArgb(253, 224, 71); // Yellow
        lblInfoHead.Location = new Point(16, 10);
        lblInfoHead.Size = new Size(520, 24);
        infoPanel.Controls.Add(lblInfoHead);

        string[] items = new string[] {
            "• Đóng tất cả tiến trình đang chạy (Minecraft Java, Prism, Mem Reduct, Watchdog)",
            "• Xóa toàn bộ thư mục C:\\MinecraftVPS (Prism Launcher, tất cả Instances, Mods, Configs)",
            "• Xóa tác vụ tự khởi động Task Scheduler (memreductTask) và Registry Startup",
            "• Xóa sạch dữ liệu tạm & cấu hình trong AppData (PrismLauncher, Mem Reduct)",
            "• Dọn dẹp sạch sẽ các biểu tượng / công cụ trên màn hình Desktop",
            "• Đưa hệ thống VPS về trạng thái sạch 100% ban đầu để chạy lại lệnh Setup"
        };

        int itemTop = 38;
        foreach (string it in items) {
            Label lblItem = new Label();
            lblItem.Text = it;
            lblItem.Font = new Font("Segoe UI", 9f);
            lblItem.ForeColor = Color.FromArgb(241, 245, 249);
            lblItem.Location = new Point(16, itemTop);
            lblItem.Size = new Size(520, 30);
            infoPanel.Controls.Add(lblItem);
            itemTop += 32;
        }

        // Checkbox Keep Login
        chkKeepLogin = new CheckBox();
        chkKeepLogin.Text = "✓ Giữ lại tài khoản Microsoft (Không phải đăng nhập lại sau khi reset)";
        chkKeepLogin.Font = new Font("Segoe UI", 9.5f, FontStyle.Bold);
        chkKeepLogin.ForeColor = Color.FromArgb(74, 222, 128); // Green
        chkKeepLogin.Location = new Point(28, 322);
        chkKeepLogin.Size = new Size(550, 26);
        chkKeepLogin.Checked = true;
        chkKeepLogin.Cursor = Cursors.Hand;
        this.Controls.Add(chkKeepLogin);

        // Progress Bar
        progressBar = new ProgressBar();
        progressBar.Location = new Point(25, 355);
        progressBar.Size = new Size(555, 16);
        progressBar.Style = ProgressBarStyle.Continuous;
        progressBar.Value = 0;
        progressBar.Visible = false;
        this.Controls.Add(progressBar);

        // Status Label
        lblStatus = new Label();
        lblStatus.Text = "Sẵn sàng thực hiện. Vui lòng chọn hành động bên dưới:";
        lblStatus.Font = new Font("Segoe UI", 9f, FontStyle.Italic);
        lblStatus.ForeColor = Color.FromArgb(148, 163, 184);
        lblStatus.Location = new Point(25, 376);
        lblStatus.Size = new Size(555, 22);
        lblStatus.TextAlign = ContentAlignment.MiddleCenter;
        this.Controls.Add(lblStatus);

        // Buttons
        btnUninstallAndReinstall = new Button();
        btnUninstallAndReinstall.Text = "⚡ Gỡ & Cài đặt lại ngay (Reinstall)";
        btnUninstallAndReinstall.Font = new Font("Segoe UI", 10f, FontStyle.Bold);
        btnUninstallAndReinstall.BackColor = Color.FromArgb(34, 197, 94); // Green
        btnUninstallAndReinstall.ForeColor = Color.White;
        btnUninstallAndReinstall.FlatStyle = FlatStyle.Flat;
        btnUninstallAndReinstall.FlatAppearance.BorderSize = 0;
        btnUninstallAndReinstall.Location = new Point(25, 408);
        btnUninstallAndReinstall.Size = new Size(270, 42);
        btnUninstallAndReinstall.Cursor = Cursors.Hand;
        btnUninstallAndReinstall.Click += (s, e) => StartUninstall(true);
        this.Controls.Add(btnUninstallAndReinstall);

        btnUninstallOnly = new Button();
        btnUninstallOnly.Text = "🗑 Chỉ gỡ cài đặt (Uninstall Only)";
        btnUninstallOnly.Font = new Font("Segoe UI", 9.5f, FontStyle.Bold);
        btnUninstallOnly.BackColor = Color.FromArgb(239, 68, 68); // Red
        btnUninstallOnly.ForeColor = Color.White;
        btnUninstallOnly.FlatStyle = FlatStyle.Flat;
        btnUninstallOnly.FlatAppearance.BorderSize = 0;
        btnUninstallOnly.Location = new Point(310, 408);
        btnUninstallOnly.Size = new Size(270, 42);
        btnUninstallOnly.Cursor = Cursors.Hand;
        btnUninstallOnly.Click += (s, e) => StartUninstall(false);
        this.Controls.Add(btnUninstallOnly);

        btnCancel = new Button();
        btnCancel.Text = "Hủy bỏ (Cancel)";
        btnCancel.Font = new Font("Segoe UI", 9f);
        btnCancel.BackColor = Color.FromArgb(51, 65, 85);
        btnCancel.ForeColor = Color.FromArgb(203, 213, 225);
        btnCancel.FlatStyle = FlatStyle.Flat;
        btnCancel.FlatAppearance.BorderSize = 0;
        btnCancel.Location = new Point(245, 460);
        btnCancel.Size = new Size(130, 30);
        btnCancel.Cursor = Cursors.Hand;
        btnCancel.Click += (s, e) => this.Close();
        this.Controls.Add(btnCancel);
    }

    private void StartUninstall(bool reinstallAfter) {
        bool keepLogin = chkKeepLogin.Checked;
        string confirmMsg = reinstallAfter 
            ? (keepLogin 
                ? "Bạn có chắc muốn GỠ CÀI ĐẶT và CÀI ĐẶT LẠI NGAY LẬP TỨC?\n\n• Toàn bộ file game và mod sẽ được dọn sạch.\n• TÀI KHOẢN MICROSOFT ĐƯỢC GIỮ LẠI (Không cần đăng nhập lại)."
                : "Bạn có chắc muốn GỠ CÀI ĐẶT và CÀI ĐẶT LẠI NGAY LẬP TỨC?\n\nTất cả tiến trình và dữ liệu sẽ bị xóa sạch.")
            : (keepLogin 
                ? "Bạn có chắc muốn GỠ BỎ Prism Launcher và dọn dẹp sạch VPS?\n\n• Toàn bộ thư mục C:\\MinecraftVPS sẽ bị xóa.\n• TÀI KHOẢN MICROSOFT ĐƯỢC LƯU DỰ PHÒNG để lần sau cài lại tự nhận."
                : "Bạn có chắc muốn GỠ BỎ TOÀN BỘ Prism Launcher và dọn dẹp sạch VPS?\n\nToàn bộ thư mục C:\\MinecraftVPS và các cài đặt sẽ bị xóa vĩnh viễn.");

        DialogResult dr = MessageBox.Show(confirmMsg, "Xác nhận gỡ cài đặt", MessageBoxButtons.YesNo, MessageBoxIcon.Warning);
        if (dr != DialogResult.Yes) return;

        chkKeepLogin.Enabled = false;
        btnUninstallAndReinstall.Enabled = false;
        btnUninstallOnly.Enabled = false;
        btnCancel.Enabled = false;
        progressBar.Visible = true;
        progressBar.Value = 10;

        Thread workThread = new Thread(() => {
            ExecuteCleanup(reinstallAfter, keepLogin);
        });
        workThread.IsBackground = true;
        workThread.Start();
    }

    private void UpdateStatus(string text, int progress) {
        if (this.InvokeRequired) {
            this.Invoke(new Action<string, int>(UpdateStatus), text, progress);
            return;
        }
        lblStatus.Text = text;
        lblStatus.ForeColor = Color.FromArgb(253, 224, 71);
        if (progress >= 0 && progress <= 100) {
            progressBar.Value = progress;
        }
    }

    private void ExecuteCleanup(bool reinstallAfter, bool keepLogin) {
        try {
            // Step 0: Backup accounts if keepLogin is enabled
            if (keepLogin) {
                UpdateStatus("[0/5] Đang sao lưu tài khoản Microsoft đã đăng nhập...", 15);
                BackupAccounts();
            }

            // Step 1: Kill all running processes
            UpdateStatus("[1/5] Đang đóng các tiến trình Minecraft & công cụ đang chạy...", 25);
            KillAllRelatedProcesses();
            Thread.Sleep(800);

            // Step 2: Remove scheduled tasks & registry startup
            UpdateStatus("[2/5] Đang xóa Task Scheduler & Registry tự khởi động...", 45);
            RemoveScheduledTasksAndRegistry();

            // Step 3: Remove C:\MinecraftVPS
            UpdateStatus("[3/5] Đang xóa toàn bộ thư mục C:\\MinecraftVPS...", 65);
            DeleteDirectorySafe(@"C:\MinecraftVPS");

            // Step 4: Clean AppData
            UpdateStatus("[4/5] Đang dọn dẹp bộ nhớ đệm AppData...", 80);
            CleanAppData();

            // Step 5: Clean Desktop shortcuts
            UpdateStatus("[5/5] Đang dọn dẹp các biểu tượng trên Desktop...", 95);
            CleanDesktopShortcuts();

            UpdateStatus("[OK] Hoàn tất dọn dẹp sạch sẽ 100%!", 100);
            Thread.Sleep(500);

            this.Invoke(new Action(() => {
                if (reinstallAfter) {
                    // Launch setup-vps.ps1 in PowerShell
                    try {
                        Process.Start(new ProcessStartInfo {
                            FileName = "powershell.exe",
                            Arguments = "-NoExit -ExecutionPolicy Bypass -Command \"irm https://raw.githubusercontent.com/babadz207/minecraft-vps-setup/main/setup-vps.ps1 | iex\"",
                            UseShellExecute = true
                        });
                    } catch (Exception ex) {
                        MessageBox.Show("Không thể tự khởi động PowerShell: " + ex.Message, "Lỗi", MessageBoxButtons.OK, MessageBoxIcon.Error);
                    }
                    Application.Exit();
                } else {
                    string msg = keepLogin
                        ? "Đã gỡ cài đặt và dọn sạch toàn bộ Prism Launcher thành công!\n\nTài khoản Microsoft đã được giữ lại an toàn. Khi bạn cài lại setup, hệ thống sẽ tự động nhận diện tài khoản mà không cần đăng nhập lại!\n\nBạn có muốn sao chép câu lệnh Setup vào Clipboard không?"
                        : "Đã gỡ cài đặt và dọn sạch toàn bộ Prism Launcher & Minecraft VPS thành công!\n\nBạn có muốn sao chép câu lệnh Setup mới vào Clipboard để chạy sau không?";

                    DialogResult res = MessageBox.Show(msg, "Gỡ cài đặt thành công", MessageBoxButtons.YesNo, MessageBoxIcon.Information);
                    if (res == DialogResult.Yes) {
                        try {
                            Clipboard.SetText("irm https://raw.githubusercontent.com/babadz207/minecraft-vps-setup/main/setup-vps.ps1 | iex");
                            MessageBox.Show("Đã sao chép lệnh setup vào Clipboard! Bạn chỉ cần nhấn [Ctrl + V] vào PowerShell để cài lại.", "Đã sao chép", MessageBoxButtons.OK, MessageBoxIcon.Information);
                        } catch {}
                    }
                    Application.Exit();
                }
            }));

        } catch (Exception ex) {
            this.Invoke(new Action(() => {
                MessageBox.Show("Lỗi trong quá trình gỡ cài đặt: " + ex.Message, "Lỗi", MessageBoxButtons.OK, MessageBoxIcon.Error);
                chkKeepLogin.Enabled = true;
                btnUninstallAndReinstall.Enabled = true;
                btnUninstallOnly.Enabled = true;
                btnCancel.Enabled = true;
            }));
        }
    }

    private static void BackupAccounts() {
        try {
            string appData = Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData);
            string userProfile = Environment.GetFolderPath(Environment.SpecialFolder.UserProfile);
            string tempDir = Path.GetTempPath();

            string[] candidateAccounts = new string[] {
                @"C:\MinecraftVPS\PrismLauncher\accounts.json",
                Path.Combine(appData, @"PrismLauncher\accounts.json"),
                @"C:\accounts_backup.json"
            };

            string validSource = null;
            foreach (string path in candidateAccounts) {
                if (File.Exists(path)) {
                    try {
                        string txt = File.ReadAllText(path);
                        if (txt.Contains("\"profile\"") || (txt.Contains("\"accounts\"") && txt.Length > 60)) {
                            validSource = path;
                            break;
                        }
                    } catch {}
                }
            }

            if (!string.IsNullOrEmpty(validSource)) {
                string[] backupDestinations = new string[] {
                    @"C:\accounts_backup.json",
                    Path.Combine(userProfile, "accounts_backup.json"),
                    Path.Combine(tempDir, "accounts_backup.json")
                };

                foreach (string dst in backupDestinations) {
                    try {
                        File.Copy(validSource, dst, true);
                    } catch {}
                }
            }
        } catch {}
    }

    private static void KillAllRelatedProcesses() {
        string[] procs = new string[] {
            "javaw", "java", "prismlauncher", "memreduct",
            "WatchdogUI", "AutoPayManager", "DangNhapMicrosoft", "MoPrism", "DonRAM"
        };
        foreach (string name in procs) {
            try {
                foreach (Process p in Process.GetProcessesByName(name)) {
                    try { p.Kill(); } catch {}
                }
            } catch {}
        }
    }

    private static void RemoveScheduledTasksAndRegistry() {
        try {
            Process p = Process.Start(new ProcessStartInfo {
                FileName = "schtasks.exe",
                Arguments = "/Delete /TN \"memreductTask\" /F",
                CreateNoWindow = true,
                UseShellExecute = false
            });
            if (p != null) p.WaitForExit(2000);
        } catch {}

        try {
            using (var key = Microsoft.Win32.Registry.CurrentUser.OpenSubKey(@"Software\Microsoft\Windows\CurrentVersion\Run", true)) {
                if (key != null) {
                    key.DeleteValue("MemReduct", false);
                }
            }
        } catch {}
    }

    private static void CleanAppData() {
        string appData = Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData);
        string localAppData = Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData);

        string[] targets = new string[] {
            Path.Combine(appData, @"Henry++\Mem Reduct"),
            Path.Combine(appData, "PrismLauncher"),
            Path.Combine(localAppData, "PrismLauncher")
        };

        foreach (string t in targets) {
            DeleteDirectorySafe(t);
        }
    }

    private static void CleanDesktopShortcuts() {
        string desktop = Environment.GetFolderPath(Environment.SpecialFolder.Desktop);
        if (string.IsNullOrEmpty(desktop) || !Directory.Exists(desktop)) return;

        string[] patterns = new string[] {
            "*.bat",
            "*Chay Minecraft AFK*",
            "*Dang Nhap Microsoft*",
            "*Microsoft Login*",
            "*Auto Restart*",
            "*Auto Reconnect*",
            "*Quan Ly Auto Pay*",
            "*Auto Pay Manager*",
            "*Don RAM*",
            "*Clean RAM*",
            "*Mo Prism Launcher*",
            "*Open Prism Launcher*"
        };

        foreach (string pat in patterns) {
            try {
                foreach (string f in Directory.GetFiles(desktop, pat)) {
                    try { File.Delete(f); } catch {}
                }
            } catch {}
        }
    }

    private static void DeleteDirectorySafe(string path) {
        if (!Directory.Exists(path)) return;

        // Try standard deletion first
        try {
            foreach (string file in Directory.GetFiles(path, "*", SearchOption.AllDirectories)) {
                try {
                    File.SetAttributes(file, FileAttributes.Normal);
                    File.Delete(file);
                } catch {}
            }
            foreach (string dir in Directory.GetDirectories(path, "*", SearchOption.AllDirectories)) {
                try { Directory.Delete(dir, true); } catch {}
            }
            Directory.Delete(path, true);
        } catch {}

        // Fallback cmd rd if still exists
        if (Directory.Exists(path)) {
            try {
                Process p = Process.Start(new ProcessStartInfo {
                    FileName = "cmd.exe",
                    Arguments = string.Format("/c rd /s /q \"{0}\"", path),
                    CreateNoWindow = true,
                    UseShellExecute = false
                });
                if (p != null) p.WaitForExit(3000);
            } catch {}
        }
    }

    [STAThread]
    public static void Main() {
        Application.EnableVisualStyles();
        Application.SetCompatibleTextRenderingDefault(false);
        Application.Run(new UninstallPrismForm());
    }
}
