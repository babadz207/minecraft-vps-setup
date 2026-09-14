using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Management;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading;
using System.Windows.Forms;

public class WatchdogForm : Form {
    private string baseDir;
    private string prismDir;
    private string prismExe;
    private string instancesDir;
    private string accountsFile;
    private string configFile;
    private string serverAddress = "donutsmp.net";

    private List<string> loggedAccounts = new List<string>();
    private List<string> availableInstances = new List<string>();

    private class InstanceControlItem {
        public string Name;
        public string Account;
        public CheckBox Checkbox;
        public Label Badge;
        public Button Button;
        public string LogFile;
        public long LogPos;
        public DateTime LastLaunch;
        public bool IsRunning;
        public int ProcessId;
        public bool IsWaitingToStart;
    }

    private Dictionary<string, InstanceControlItem> instControls = new Dictionary<string, InstanceControlItem>();

    private TextBox txtDelay;
    private Label lblAutoStatus;
    private Button btnStartAuto;
    private Button btnStopAll;
    private TextBox txtLog;
    private System.Windows.Forms.Timer monitorTimer;

    private bool autoCheckEnabled = false;
    private bool isExecutingCycle = false;

    private static readonly string[] DcTriggers = new string[] {
        "Lost connection", "Disconnected from server", "Disconnected:", "Connection reset",
        "Connection refused", "Timed out", "Read timed out", "Connect timed out",
        "io.netty", "Internal Exception:", "SocketException", "ConnectException",
        "forcibly closed by the remote host", "Kicked by server", "Server closed",
        "closed connection", "Connecting too fast", "You are already connected",
        "Failed to verify username", "Invalid session", "Flying is not enabled",
        "A fatal error occurred", "End of stream"
    };

    public WatchdogForm() {
        InitEnvironment();
        BuildUI();
        LoadConfig();
        RefreshStatuses();

        monitorTimer = new System.Windows.Forms.Timer();
        monitorTimer.Interval = 4000;
        monitorTimer.Tick += (s, e) => OnMonitorTick();
        monitorTimer.Start();

        AppendLog("Hệ thống khởi động thành công. Tìm thấy " + availableInstances.Count + " Instance.");
        AppendLog("Tích chọn instance muốn auto và nhấn [BẮT ĐẦU AUTO 24/7].");
    }

    private void InitEnvironment() {
        baseDir = @"C:\MinecraftVPS";
        if (!Directory.Exists(baseDir)) {
            baseDir = AppDomain.CurrentDomain.BaseDirectory;
        }
        prismDir = Path.Combine(baseDir, "PrismLauncher");
        prismExe = Path.Combine(prismDir, "prismlauncher.exe");
        instancesDir = Path.Combine(prismDir, "instances");
        accountsFile = Path.Combine(prismDir, "accounts.json");
        configFile = Path.Combine(baseDir, "instance_config.json");

        // Load Accounts
        if (File.Exists(accountsFile)) {
            try {
                string json = File.ReadAllText(accountsFile);
                MatchCollection matches = Regex.Matches(json, "\"name\"\\s*:\\s*\"([^\"]+)\"");
                foreach (Match m in matches) {
                    string acc = m.Groups[1].Value;
                    if (!loggedAccounts.Contains(acc)) {
                        loggedAccounts.Add(acc);
                    }
                }
            } catch {}
        }

        // Scan Instances
        if (Directory.Exists(instancesDir)) {
            foreach (string dir in Directory.GetDirectories(instancesDir)) {
                string name = Path.GetFileName(dir);
                if (Directory.Exists(Path.Combine(dir, ".minecraft"))) {
                    availableInstances.Add(name);
                }
            }
            availableInstances.Sort();
        }

        if (availableInstances.Count == 0) {
            availableInstances.Add("VPS-AFK-1");
            availableInstances.Add("VPS-AFK-2");
            availableInstances.Add("VPS-AFK-3");
        }
    }

    private void BuildUI() {
        this.Text = "Trung Tam Giam Sat & Auto Reconnect 24/7 - DonutSMP";
        this.Size = new Size(620, 720);
        this.StartPosition = FormStartPosition.CenterScreen;
        this.FormBorderStyle = FormBorderStyle.FixedDialog;
        this.MaximizeBox = false;
        this.BackColor = Color.FromArgb(15, 23, 42); // Slate Dark

        // Header Title
        Label lblTitle = new Label();
        lblTitle.Text = "TRUNG TÂM GIÁM SÁT & AUTO RECONNECT 24/7";
        lblTitle.Font = new Font("Segoe UI", 13.5f, FontStyle.Bold);
        lblTitle.ForeColor = Color.FromArgb(56, 189, 248); // Sky Blue
        lblTitle.Location = new Point(15, 12);
        lblTitle.Size = new Size(575, 28);
        lblTitle.TextAlign = ContentAlignment.MiddleCenter;
        this.Controls.Add(lblTitle);

        Label lblSub = new Label();
        lblSub.Text = "Server: donutsmp.net  •  1 Instance = 1 Acc Microsoft  •  Anti-Crash & RAM Guard";
        lblSub.Font = new Font("Segoe UI", 9f);
        lblSub.ForeColor = Color.FromArgb(148, 163, 184);
        lblSub.Location = new Point(15, 40);
        lblSub.Size = new Size(575, 20);
        lblSub.TextAlign = ContentAlignment.MiddleCenter;
        this.Controls.Add(lblSub);

        // Cards Panel
        Panel pnlCards = new Panel();
        pnlCards.Location = new Point(20, 68);
        pnlCards.Size = new Size(565, 225);
        pnlCards.BackColor = Color.FromArgb(30, 41, 59); // Card Dark
        pnlCards.BorderStyle = BorderStyle.FixedSingle;
        this.Controls.Add(pnlCards);

        int top = 8;
        for (int i = 0; i < availableInstances.Count; i++) {
            string instName = availableInstances[i];
            string accName = (i < loggedAccounts.Count) ? loggedAccounts[i] : "(Chưa đăng nhập)";

            Panel card = new Panel();
            card.Location = new Point(8, top);
            card.Size = new Size(547, 64);
            card.BackColor = Color.FromArgb(41, 53, 72);
            pnlCards.Controls.Add(card);

            CheckBox chk = new CheckBox();
            chk.Text = " " + instName;
            chk.Font = new Font("Segoe UI", 10.5f, FontStyle.Bold);
            chk.ForeColor = Color.White;
            chk.Location = new Point(10, 8);
            chk.Size = new Size(130, 24);
            chk.Checked = (i == 0);
            card.Controls.Add(chk);

            Label lblAcc = new Label();
            lblAcc.Text = "Acc: " + accName;
            lblAcc.Font = new Font("Consolas", 9f);
            lblAcc.ForeColor = Color.FromArgb(253, 224, 71); // Amber
            lblAcc.Location = new Point(12, 34);
            lblAcc.Size = new Size(170, 20);
            card.Controls.Add(lblAcc);

            Label lblBadge = new Label();
            lblBadge.Text = "○ ĐÃ DỪNG\n(Chưa kích hoạt)";
            lblBadge.Font = new Font("Segoe UI", 9f, FontStyle.Bold);
            lblBadge.ForeColor = Color.FromArgb(148, 163, 184);
            lblBadge.Location = new Point(190, 8);
            lblBadge.Size = new Size(230, 48);
            card.Controls.Add(lblBadge);

            Button btnSingle = new Button();
            btnSingle.Text = "Bật bot";
            btnSingle.Font = new Font("Segoe UI", 9f, FontStyle.Bold);
            btnSingle.BackColor = Color.FromArgb(51, 65, 85);
            btnSingle.ForeColor = Color.White;
            btnSingle.FlatStyle = FlatStyle.Flat;
            btnSingle.FlatAppearance.BorderSize = 0;
            btnSingle.Location = new Point(430, 14);
            btnSingle.Size = new Size(102, 34);
            btnSingle.Cursor = Cursors.Hand;
            string capturedName = instName;
            btnSingle.Click += (s, e) => ToggleSingleInstance(capturedName);
            card.Controls.Add(btnSingle);

            InstanceControlItem item = new InstanceControlItem();
            item.Name = instName;
            item.Account = accName;
            item.Checkbox = chk;
            item.Badge = lblBadge;
            item.Button = btnSingle;
            item.LogFile = Path.Combine(instancesDir, instName + @"\.minecraft\logs\latest.log");
            item.LogPos = 0;
            item.LastLaunch = DateTime.MinValue;
            item.IsRunning = false;
            item.ProcessId = 0;
            item.IsWaitingToStart = false;

            instControls[instName] = item;
            top += 70;
        }

        // Settings Row
        Panel pnlSettings = new Panel();
        pnlSettings.Location = new Point(20, 302);
        pnlSettings.Size = new Size(565, 46);
        pnlSettings.BackColor = Color.FromArgb(30, 41, 59);
        pnlSettings.BorderStyle = BorderStyle.FixedSingle;
        this.Controls.Add(pnlSettings);

        Label lblDelay = new Label();
        lblDelay.Text = "Delay mở bot (giây):";
        lblDelay.Font = new Font("Segoe UI", 9.5f, FontStyle.Bold);
        lblDelay.ForeColor = Color.FromArgb(226, 232, 240);
        lblDelay.Location = new Point(12, 12);
        lblDelay.Size = new Size(140, 20);
        pnlSettings.Controls.Add(lblDelay);

        txtDelay = new TextBox();
        txtDelay.Text = "25";
        txtDelay.Font = new Font("Segoe UI", 10f);
        txtDelay.BackColor = Color.FromArgb(15, 23, 42);
        txtDelay.ForeColor = Color.White;
        txtDelay.BorderStyle = BorderStyle.FixedSingle;
        txtDelay.Location = new Point(155, 10);
        txtDelay.Size = new Size(55, 26);
        txtDelay.TextAlign = HorizontalAlignment.Center;
        pnlSettings.Controls.Add(txtDelay);

        lblAutoStatus = new Label();
        lblAutoStatus.Text = "Chế độ Auto Check: ĐANG TẮT";
        lblAutoStatus.Font = new Font("Segoe UI", 9.5f, FontStyle.Bold);
        lblAutoStatus.ForeColor = Color.FromArgb(248, 113, 113); // Light Red
        lblAutoStatus.Location = new Point(225, 12);
        lblAutoStatus.Size = new Size(325, 20);
        lblAutoStatus.TextAlign = ContentAlignment.MiddleRight;
        pnlSettings.Controls.Add(lblAutoStatus);

        // Big Buttons
        btnStartAuto = new Button();
        btnStartAuto.Text = "▶  BẮT ĐẦU AUTO CHECK CONNECT (24/7)";
        btnStartAuto.Font = new Font("Segoe UI", 11f, FontStyle.Bold);
        btnStartAuto.BackColor = Color.FromArgb(34, 197, 94); // Emerald
        btnStartAuto.ForeColor = Color.White;
        btnStartAuto.FlatStyle = FlatStyle.Flat;
        btnStartAuto.FlatAppearance.BorderSize = 0;
        btnStartAuto.Location = new Point(20, 358);
        btnStartAuto.Size = new Size(565, 44);
        btnStartAuto.Cursor = Cursors.Hand;
        btnStartAuto.Click += (s, e) => ToggleAuto();
        this.Controls.Add(btnStartAuto);

        btnStopAll = new Button();
        btnStopAll.Text = "🛑  DỪNG TẤT CẢ INSTANCE (STOP ALL)";
        btnStopAll.Font = new Font("Segoe UI", 10f, FontStyle.Bold);
        btnStopAll.BackColor = Color.FromArgb(220, 38, 38); // Red
        btnStopAll.ForeColor = Color.White;
        btnStopAll.FlatStyle = FlatStyle.Flat;
        btnStopAll.FlatAppearance.BorderSize = 0;
        btnStopAll.Location = new Point(20, 410);
        btnStopAll.Size = new Size(565, 38);
        btnStopAll.Cursor = Cursors.Hand;
        btnStopAll.Click += (s, e) => StopAllInstances();
        this.Controls.Add(btnStopAll);

        // Logs Header & Clear Button
        Label lblLogTitle = new Label();
        lblLogTitle.Text = "Nhật ký hoạt động (Live Logs):";
        lblLogTitle.Font = new Font("Segoe UI", 9f, FontStyle.Bold);
        lblLogTitle.ForeColor = Color.FromArgb(148, 163, 184);
        lblLogTitle.Location = new Point(20, 458);
        lblLogTitle.Size = new Size(250, 18);
        this.Controls.Add(lblLogTitle);

        Button btnClearLog = new Button();
        btnClearLog.Text = "Xóa Log";
        btnClearLog.Font = new Font("Segoe UI", 8f);
        btnClearLog.BackColor = Color.FromArgb(51, 65, 85);
        btnClearLog.ForeColor = Color.White;
        btnClearLog.FlatStyle = FlatStyle.Flat;
        btnClearLog.FlatAppearance.BorderSize = 0;
        btnClearLog.Location = new Point(515, 454);
        btnClearLog.Size = new Size(70, 24);
        btnClearLog.Cursor = Cursors.Hand;
        btnClearLog.Click += (s, e) => { txtLog.Clear(); };
        this.Controls.Add(btnClearLog);

        // Log Console
        txtLog = new TextBox();
        txtLog.Location = new Point(20, 482);
        txtLog.Size = new Size(565, 165);
        txtLog.Multiline = true;
        txtLog.ReadOnly = true;
        txtLog.ScrollBars = ScrollBars.Vertical;
        txtLog.BackColor = Color.FromArgb(11, 15, 25);
        txtLog.ForeColor = Color.FromArgb(226, 232, 240);
        txtLog.Font = new Font("Consolas", 9f);
        txtLog.BorderStyle = BorderStyle.FixedSingle;
        this.Controls.Add(txtLog);

        // Footer
        Label lblFooter = new Label();
        lblFooter.Text = "Tối ưu hóa VPS Non-GPU: Giao diện C# WinGUI • 0% CPU • Không mở Terminal";
        lblFooter.Font = new Font("Segoe UI", 8.5f);
        lblFooter.ForeColor = Color.FromArgb(100, 116, 139);
        lblFooter.Location = new Point(20, 654);
        lblFooter.Size = new Size(565, 20);
        lblFooter.TextAlign = ContentAlignment.MiddleCenter;
        this.Controls.Add(lblFooter);

        this.FormClosing += (s, e) => {
            monitorTimer.Stop();
            monitorTimer.Dispose();
        };
    }

    private void LoadConfig() {
        if (File.Exists(configFile)) {
            try {
                string json = File.ReadAllText(configFile);
                int delay = 25;
                Match mD = Regex.Match(json, "\"launch_delay_seconds\"\\s*:\\s*(\\d+)");
                if (mD.Success) int.TryParse(mD.Groups[1].Value, out delay);
                txtDelay.Text = delay.ToString();

                Match mA = Regex.Match(json, "\"active_count\"\\s*:\\s*(\\d+)");
                if (mA.Success) {
                    int count = 1;
                    int.TryParse(mA.Groups[1].Value, out count);
                    for (int i = 0; i < availableInstances.Count; i++) {
                        string name = availableInstances[i];
                        if (instControls.ContainsKey(name)) {
                            instControls[name].Checkbox.Checked = (i < count);
                        }
                    }
                }
            } catch {}
        }
    }

    private void SaveConfig() {
        try {
            int delay = GetDelaySeconds();
            List<string> checkedList = new List<string>();
            foreach (var kvp in instControls) {
                if (kvp.Value.Checkbox.Checked) checkedList.Add(kvp.Key);
            }

            StringBuilder sb = new StringBuilder();
            sb.Append("{");
            sb.Append("\"active_count\":" + checkedList.Count + ",");
            sb.Append("\"launch_delay_seconds\":" + delay + ",");
            sb.Append("\"instances\":[");
            for (int i = 0; i < checkedList.Count; i++) {
                sb.Append("\"" + checkedList[i] + "\"");
                if (i < checkedList.Count - 1) sb.Append(",");
            }
            sb.Append("],");
            sb.Append("\"updated\":\"" + DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss") + "\"");
            sb.Append("}");

            File.WriteAllText(configFile, sb.ToString(), Encoding.UTF8);
        } catch {}
    }

    private int GetDelaySeconds() {
        int delay = 25;
        if (int.TryParse(txtDelay.Text.Trim(), out delay)) {
            if (delay < 5) delay = 5;
            return delay;
        }
        return 25;
    }

    private void AppendLog(string msg) {
        if (this.InvokeRequired) {
            this.BeginInvoke(new Action<string>(AppendLog), msg);
            return;
        }
        string line = "[" + DateTime.Now.ToString("HH:mm:ss") + "] " + msg;
        if (txtLog.TextLength > 30000) {
            txtLog.Text = txtLog.Text.Substring(10000);
        }
        txtLog.AppendText(line + Environment.NewLine);
        txtLog.SelectionStart = txtLog.TextLength;
        txtLog.ScrollToCaret();
    }

    private Dictionary<string, ProcessInfo> GetRunningProcesses() {
        Dictionary<string, ProcessInfo> result = new Dictionary<string, ProcessInfo>();
        try {
            using (var searcher = new ManagementObjectSearcher("SELECT ProcessId, CommandLine, WorkingSetSize FROM Win32_Process WHERE Name='javaw.exe' OR Name='java.exe'")) {
                foreach (ManagementObject mo in searcher.Get()) {
                    uint pid = (uint)mo["ProcessId"];
                    string cmdLine = mo["CommandLine"] as string ?? "";
                    ulong mem = (ulong)(mo["WorkingSetSize"] ?? 0);

                    foreach (string inst in availableInstances) {
                        if (cmdLine.IndexOf(@"instances\" + inst + @"\", StringComparison.OrdinalIgnoreCase) >= 0 ||
                            cmdLine.IndexOf(@"instances/" + inst + @"/", StringComparison.OrdinalIgnoreCase) >= 0) {
                            ProcessInfo pi = new ProcessInfo();
                            pi.ProcessId = (int)pid;
                            pi.WorkingSetMB = (long)(mem / (1024 * 1024));
                            result[inst] = pi;
                            break;
                        }
                    }
                }
            }
        } catch {}

        return result;
    }

    private class ProcessInfo {
        public int ProcessId;
        public long WorkingSetMB;
    }

    private void RefreshStatuses() {
        var procMap = GetRunningProcesses();

        foreach (var kvp in instControls) {
            string name = kvp.Key;
            var item = kvp.Value;

            if (procMap.ContainsKey(name)) {
                var pi = procMap[name];
                item.IsRunning = true;
                item.ProcessId = pi.ProcessId;
                item.IsWaitingToStart = false;

                item.Badge.Text = string.Format("● ĐANG CHẠY\nPID: {0} | RAM: {1} MB", pi.ProcessId, pi.WorkingSetMB);
                item.Badge.ForeColor = Color.FromArgb(74, 222, 128); // Emerald Light
                item.Button.Text = "Dừng bot";
                item.Button.BackColor = Color.FromArgb(239, 68, 68); // Red
            } else {
                item.IsRunning = false;
                item.ProcessId = 0;

                if (autoCheckEnabled && item.Checkbox.Checked && item.IsWaitingToStart) {
                    item.Badge.Text = "⌛ ĐANG CHỜ MỞ...\n(Chờ RAM ổn định)";
                    item.Badge.ForeColor = Color.FromArgb(253, 224, 71); // Amber
                } else if (autoCheckEnabled && item.Checkbox.Checked) {
                    item.Badge.Text = "⌛ ĐANG CHỜ MỞ...\n(Tự động Reopen)";
                    item.Badge.ForeColor = Color.FromArgb(253, 224, 71); // Amber
                } else {
                    item.Badge.Text = "○ ĐÃ DỪNG\n(Chưa kích hoạt)";
                    item.Badge.ForeColor = Color.FromArgb(148, 163, 184); // Slate Light
                }

                item.Button.Text = "Bật bot";
                item.Button.BackColor = Color.FromArgb(51, 65, 85);
            }
        }
    }

    private void ToggleSingleInstance(string instName) {
        if (!instControls.ContainsKey(instName)) return;
        var item = instControls[instName];

        if (item.IsRunning && item.ProcessId > 0) {
            try {
                Process p = Process.GetProcessById(item.ProcessId);
                p.Kill();
                AppendLog("[" + instName + "] Đã dừng tiến trình bot (PID: " + item.ProcessId + ").");
            } catch {
                AppendLog("[" + instName + "] Không thể tắt bot hoặc bot đã dừng trước đó.");
            }
            Thread.Sleep(500);
            RefreshStatuses();
        } else {
            StartSingleInstance(instName);
            RefreshStatuses();
        }
    }

    private void StartSingleInstance(string instName) {
        if (!File.Exists(prismExe)) {
            AppendLog("[LỖI] Không tìm thấy Prism Launcher tại: " + prismExe);
            return;
        }

        var item = instControls[instName];
        string accArg = (!string.IsNullOrEmpty(item.Account) && item.Account != "(Chưa đăng nhập)") 
            ? " --profile \"" + item.Account + "\"" : "";

        AppendLog("[" + instName + "] Đang khởi động bot " + accArg + " -> Server " + serverAddress + "...");

        try {
            ProcessStartInfo psi = new ProcessStartInfo();
            psi.FileName = prismExe;
            psi.Arguments = "--launch \"" + instName + "\" --server " + serverAddress + accArg;
            psi.WorkingDirectory = prismDir;
            psi.UseShellExecute = true;
            psi.EnvironmentVariables["LP_NUM_THREADS"] = "2";

            Process.Start(psi);
            item.LastLaunch = DateTime.Now;
            item.IsWaitingToStart = false;

            if (File.Exists(item.LogFile)) {
                try {
                    item.LogPos = new FileInfo(item.LogFile).Length;
                } catch {}
            }
        } catch (Exception ex) {
            AppendLog("[LỖI] Không thể khởi động " + instName + ": " + ex.Message);
        }
    }

    private void ToggleAuto() {
        if (autoCheckEnabled) {
            // Tạm dừng Auto
            autoCheckEnabled = false;
            lblAutoStatus.Text = "Chế độ Auto Check: ĐÃ TẠM DỪNG";
            lblAutoStatus.ForeColor = Color.FromArgb(253, 224, 71);
            btnStartAuto.Text = "▶  TIẾP TỤC AUTO CHECK CONNECT (24/7)";
            btnStartAuto.BackColor = Color.FromArgb(34, 197, 94);
            AppendLog("[AUTO] Đã tạm dừng tự động kiểm tra kết nối.");
            RefreshStatuses();
            return;
        }

        // Bắt đầu Auto
        List<string> selected = new List<string>();
        foreach (var kvp in instControls) {
            if (kvp.Value.Checkbox.Checked) selected.Add(kvp.Key);
        }

        if (selected.Count == 0) {
            MessageBox.Show("Vui lòng tích chọn ít nhất 1 Instance để chạy Auto!", "Thông Báo", MessageBoxButtons.OK, MessageBoxIcon.Warning);
            return;
        }

        SaveConfig();
        autoCheckEnabled = true;
        lblAutoStatus.Text = "Chế độ Auto Check: ĐANG HOẠT ĐỘNG (24/7)";
        lblAutoStatus.ForeColor = Color.FromArgb(74, 222, 128);
        btnStartAuto.Text = "⏸  TẠM DỪNG AUTO CHECK CONNECT";
        btnStartAuto.BackColor = Color.FromArgb(234, 179, 8); // Amber

        int delaySec = GetDelaySeconds();
        AppendLog("[AUTO] Đã kích hoạt Auto Reconnect cho: " + string.Join(", ", selected.ToArray()));
        AppendLog("[AUTO] Delay khởi động giữa các bot: " + delaySec + " giây (Chống tràn RAM).");

        // Khởi động bot tuần tự trong luồng nền để không treo UI
        ThreadPool.QueueUserWorkItem((state) => {
            var procMap = GetRunningProcesses();
            for (int i = 0; i < selected.Count; i++) {
                if (!autoCheckEnabled) break;
                string instName = selected[i];

                if (procMap.ContainsKey(instName)) {
                    AppendLog("[" + instName + "] Đã đang chạy sẵn (PID: " + procMap[instName].ProcessId + ").");
                } else {
                    this.BeginInvoke(new Action(() => {
                        StartSingleInstance(instName);
                        RefreshStatuses();
                    }));

                    if (i < selected.Count - 1 && autoCheckEnabled) {
                        AppendLog("[AUTO] Chờ " + delaySec + "s để " + instName + " ổn định RAM trước khi mở bot kế...");
                        for (int w = 0; w < delaySec; w++) {
                            if (!autoCheckEnabled) break;
                            Thread.Sleep(1000);
                        }
                    }
                }
            }
            this.BeginInvoke(new Action(RefreshStatuses));
        });
    }

    private void StopAllInstances() {
        DialogResult dr = MessageBox.Show(
            "Bạn có chắc chắn muốn DỪNG TẤT CẢ các bot Minecraft đang chạy không?",
            "Xác Nhận Dừng Tất Cả",
            MessageBoxButtons.YesNo,
            MessageBoxIcon.Warning
        );

        if (dr != DialogResult.Yes) return;

        autoCheckEnabled = false;
        lblAutoStatus.Text = "Chế độ Auto Check: ĐÃ DỪNG";
        lblAutoStatus.ForeColor = Color.FromArgb(248, 113, 113);
        btnStartAuto.Text = "▶  BẮT ĐẦU AUTO CHECK CONNECT (24/7)";
        btnStartAuto.BackColor = Color.FromArgb(34, 197, 94);

        int count = 0;
        try {
            foreach (Process p in Process.GetProcessesByName("javaw")) {
                try { p.Kill(); count++; } catch {}
            }
            foreach (Process p in Process.GetProcessesByName("java")) {
                try { p.Kill(); count++; } catch {}
            }
        } catch {}

        AppendLog("[STOP ALL] Đã tắt thành công " + count + " tiến trình Minecraft!");
        Thread.Sleep(600);
        RefreshStatuses();
    }

    private void OnMonitorTick() {
        RefreshStatuses();

        if (!autoCheckEnabled || isExecutingCycle) return;

        int delaySec = GetDelaySeconds();
        var procMap = GetRunningProcesses();

        foreach (var kvp in instControls) {
            string instName = kvp.Key;
            var item = kvp.Value;
            if (!item.Checkbox.Checked) continue;

            // 1. Kiểm tra nếu tiến trình bị tắt / crash đột ngột
            if (!procMap.ContainsKey(instName)) {
                if ((DateTime.Now - item.LastLaunch).TotalSeconds > (delaySec + 15)) {
                    AppendLog("[!] [" + instName + "] Phát hiện bot bị crash hoặc tắt! Đang mở lại...");
                    StartSingleInstance(instName);
                }
                continue;
            }

            // 2. Tối ưu hạ CPU Priority xuống BelowNormal
            int pid = procMap[instName].ProcessId;
            try {
                Process p = Process.GetProcessById(pid);
                if (p.PriorityClass != ProcessPriorityClass.BelowNormal) {
                    p.PriorityClass = ProcessPriorityClass.BelowNormal;
                }
            } catch {}

            // 3. Quét log tìm ngắt kết nối
            if (File.Exists(item.LogFile)) {
                try {
                    FileInfo fi = new FileInfo(item.LogFile);
                    if (fi.Length > item.LogPos) {
                        string newContent = "";
                        using (FileStream fs = new FileStream(item.LogFile, FileMode.Open, FileAccess.Read, FileShare.ReadWrite)) {
                            fs.Seek(item.LogPos, SeekOrigin.Begin);
                            using (StreamReader sr = new StreamReader(fs, Encoding.UTF8)) {
                                newContent = sr.ReadToEnd();
                                item.LogPos = fs.Position;
                            }
                        }

                        string matched = null;
                        foreach (string dc in DcTriggers) {
                            if (newContent.IndexOf(dc, StringComparison.OrdinalIgnoreCase) >= 0) {
                                matched = dc;
                                break;
                            }
                        }

                        if (!string.IsNullOrEmpty(matched)) {
                            AppendLog("[!] [" + instName + "] PHÁT HIỆN LỖI MẠNG: " + matched);
                            AppendLog("[" + instName + "] Chờ 10s kiểm tra mod auto-reconnect...");

                            isExecutingCycle = true;
                            ThreadPool.QueueUserWorkItem((state) => {
                                Thread.Sleep(10000);

                                bool reconnected = false;
                                try {
                                    if (File.Exists(item.LogFile)) {
                                        using (FileStream fs2 = new FileStream(item.LogFile, FileMode.Open, FileAccess.Read, FileShare.ReadWrite)) {
                                            if (fs2.Length > item.LogPos) {
                                                fs2.Seek(item.LogPos, SeekOrigin.Begin);
                                                using (StreamReader sr2 = new StreamReader(fs2, Encoding.UTF8)) {
                                                    string after = sr2.ReadToEnd();
                                                    item.LogPos = fs2.Position;
                                                    if (after.IndexOf("Connecting to", StringComparison.OrdinalIgnoreCase) >= 0 ||
                                                        after.IndexOf("Connected", StringComparison.OrdinalIgnoreCase) >= 0 ||
                                                        after.IndexOf("[CHAT]", StringComparison.OrdinalIgnoreCase) >= 0) {
                                                        reconnected = true;
                                                    }
                                                }
                                            }
                                        }
                                    }
                                } catch {}

                                if (!reconnected) {
                                    AppendLog("[!] [" + instName + "] Mod không thể tự kết nối lại. Đóng riêng bot này để reopen...");
                                    try {
                                        Process pToKill = Process.GetProcessById(pid);
                                        pToKill.Kill();
                                    } catch {}

                                    Thread.Sleep(3000);
                                    this.BeginInvoke(new Action(() => {
                                        StartSingleInstance(instName);
                                        RefreshStatuses();
                                    }));
                                } else {
                                    AppendLog("[OK] [" + instName + "] Mod đã tự kết nối lại thành công!");
                                }

                                isExecutingCycle = false;
                            });
                        }
                    }
                } catch {}
            }
        }
    }

    [STAThread]
    public static void Main() {
        Application.EnableVisualStyles();
        Application.SetCompatibleTextRenderingDefault(false);
        Application.Run(new WatchdogForm());
    }
}
