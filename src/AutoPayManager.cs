using System;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.IO.Compression;
using System.Text;
using System.Windows.Forms;

public class AutoPayManagerForm : Form {
    private string baseDir;
    private string prismDir;
    private string instancesDir;
    private TextBox txtUser;
    private TextBox txtAmount;
    private CheckBox chkEnable;
    private Label lblCurrentStatus;
    private Label lblCommandPreview;
    private Label lblStatusMsg;

    private static readonly string NoRenderGzB64 = "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";

    public AutoPayManagerForm() {
        InitPaths();
        BuildUI();
        LoadCurrentConfig();
    }

    private void InitPaths() {
        baseDir = @"C:\MinecraftVPS";
        if (!Directory.Exists(baseDir)) {
            baseDir = AppDomain.CurrentDomain.BaseDirectory;
        }
        prismDir = Path.Combine(baseDir, "PrismLauncher");
        instancesDir = Path.Combine(prismDir, "instances");
    }

    private void BuildUI() {
        this.Text = "Auto Pay Manager • DonutSMP";
        this.Size = new Size(550, 570);
        this.StartPosition = FormStartPosition.CenterScreen;
        this.FormBorderStyle = FormBorderStyle.FixedDialog;
        this.MaximizeBox = false;
        this.BackColor = Color.FromArgb(15, 23, 42); // Dark Slate

        // Title
        Label lblTitle = new Label();
        lblTitle.Text = "AUTO PAY MANAGER • DONUTSMP";
        lblTitle.Font = new Font("Segoe UI", 14, FontStyle.Bold);
        lblTitle.ForeColor = Color.FromArgb(56, 189, 248); // Sky Blue
        lblTitle.Location = new Point(15, 14);
        lblTitle.Size = new Size(505, 28);
        lblTitle.TextAlign = ContentAlignment.MiddleCenter;
        this.Controls.Add(lblTitle);

        Label lblSub = new Label();
        lblSub.Text = "Automated /pay executor | Meteor Client integration (Delay: 400 ticks)";
        lblSub.Font = new Font("Segoe UI", 9.5f);
        lblSub.ForeColor = Color.FromArgb(148, 163, 184);
        lblSub.Location = new Point(15, 44);
        lblSub.Size = new Size(505, 20);
        lblSub.TextAlign = ContentAlignment.MiddleCenter;
        this.Controls.Add(lblSub);

        // Status Card
        Panel pnlStatus = new Panel();
        pnlStatus.Location = new Point(25, 74);
        pnlStatus.Size = new Size(485, 82);
        pnlStatus.BackColor = Color.FromArgb(30, 41, 59);
        pnlStatus.BorderStyle = BorderStyle.FixedSingle;
        this.Controls.Add(pnlStatus);

        lblCurrentStatus = new Label();
        lblCurrentStatus.Text = "Status: CHECKING...";
        lblCurrentStatus.Font = new Font("Segoe UI", 10.5f, FontStyle.Bold);
        lblCurrentStatus.ForeColor = Color.FromArgb(241, 245, 249);
        lblCurrentStatus.Location = new Point(14, 12);
        lblCurrentStatus.Size = new Size(455, 25);
        pnlStatus.Controls.Add(lblCurrentStatus);

        lblCommandPreview = new Label();
        lblCommandPreview.Text = "Current Command: Not configured";
        lblCommandPreview.Font = new Font("Consolas", 9.5f);
        lblCommandPreview.ForeColor = Color.FromArgb(253, 224, 71); // Amber
        lblCommandPreview.Location = new Point(14, 42);
        lblCommandPreview.Size = new Size(455, 25);
        pnlStatus.Controls.Add(lblCommandPreview);

        // Input Box Panel
        Panel pnlInputs = new Panel();
        pnlInputs.Location = new Point(25, 168);
        pnlInputs.Size = new Size(485, 198);
        pnlInputs.BackColor = Color.FromArgb(30, 41, 59);
        pnlInputs.BorderStyle = BorderStyle.FixedSingle;
        this.Controls.Add(pnlInputs);

        Label lblUserHeader = new Label();
        lblUserHeader.Text = "Recipient Username:";
        lblUserHeader.Font = new Font("Segoe UI", 9.5f, FontStyle.Bold);
        lblUserHeader.ForeColor = Color.FromArgb(226, 232, 240);
        lblUserHeader.Location = new Point(15, 14);
        lblUserHeader.Size = new Size(450, 20);
        pnlInputs.Controls.Add(lblUserHeader);

        txtUser = new TextBox();
        txtUser.Font = new Font("Segoe UI", 10.5f);
        txtUser.BackColor = Color.FromArgb(15, 23, 42);
        txtUser.ForeColor = Color.White;
        txtUser.BorderStyle = BorderStyle.FixedSingle;
        txtUser.Location = new Point(18, 38);
        txtUser.Size = new Size(448, 28);
        pnlInputs.Controls.Add(txtUser);

        Label lblAmountHeader = new Label();
        lblAmountHeader.Text = "Amount to Pay (e.g. 10, 1M, 2M, 500k, 2000000):";
        lblAmountHeader.Font = new Font("Segoe UI", 9.5f, FontStyle.Bold);
        lblAmountHeader.ForeColor = Color.FromArgb(226, 232, 240);
        lblAmountHeader.Location = new Point(15, 78);
        lblAmountHeader.Size = new Size(450, 20);
        pnlInputs.Controls.Add(lblAmountHeader);

        txtAmount = new TextBox();
        txtAmount.Font = new Font("Segoe UI", 10.5f);
        txtAmount.BackColor = Color.FromArgb(15, 23, 42);
        txtAmount.ForeColor = Color.White;
        txtAmount.BorderStyle = BorderStyle.FixedSingle;
        txtAmount.Location = new Point(18, 102);
        txtAmount.Size = new Size(448, 28);
        pnlInputs.Controls.Add(txtAmount);

        chkEnable = new CheckBox();
        chkEnable.Text = " Enable automated /pay execution while AFK (Meteor Spam)";
        chkEnable.Font = new Font("Segoe UI", 9.5f, FontStyle.Bold);
        chkEnable.ForeColor = Color.FromArgb(74, 222, 128); // Light Green
        chkEnable.Location = new Point(18, 150);
        chkEnable.Size = new Size(450, 28);
        chkEnable.Checked = true;
        pnlInputs.Controls.Add(chkEnable);

        // Buttons
        Button btnSave = new Button();
        btnSave.Text = "💾 SAVE CONFIG & RESTART MINECRAFT";
        btnSave.Font = new Font("Segoe UI", 10.5f, FontStyle.Bold);
        btnSave.BackColor = Color.FromArgb(34, 197, 94); // Emerald
        btnSave.ForeColor = Color.White;
        btnSave.FlatStyle = FlatStyle.Flat;
        btnSave.FlatAppearance.BorderSize = 0;
        btnSave.Location = new Point(25, 380);
        btnSave.Size = new Size(485, 44);
        btnSave.Cursor = Cursors.Hand;
        btnSave.Click += (s, e) => { SaveAndRestart(); };
        this.Controls.Add(btnSave);

        Button btnStopAll = new Button();
        btnStopAll.Text = "🛑 STOP ALL RUNNING INSTANCES";
        btnStopAll.Font = new Font("Segoe UI", 9.5f, FontStyle.Bold);
        btnStopAll.BackColor = Color.FromArgb(220, 38, 38); // Red
        btnStopAll.ForeColor = Color.White;
        btnStopAll.FlatStyle = FlatStyle.Flat;
        btnStopAll.FlatAppearance.BorderSize = 0;
        btnStopAll.Location = new Point(25, 434);
        btnStopAll.Size = new Size(485, 38);
        btnStopAll.Cursor = Cursors.Hand;
        btnStopAll.Click += (s, e) => { StopAllInstances(); };
        this.Controls.Add(btnStopAll);

        lblStatusMsg = new Label();
        lblStatusMsg.Text = "Note: Client processes will safely restart to load new configuration.";
        lblStatusMsg.Font = new Font("Segoe UI", 8.5f);
        lblStatusMsg.ForeColor = Color.FromArgb(148, 163, 184);
        lblStatusMsg.Location = new Point(25, 484);
        lblStatusMsg.Size = new Size(485, 24);
        lblStatusMsg.TextAlign = ContentAlignment.MiddleCenter;
        this.Controls.Add(lblStatusMsg);
    }

    private void LoadCurrentConfig() {
        string cfgFile = Path.Combine(instancesDir, @"VPS-AFK-1\.minecraft\meteor-client\pay_config.json");
        if (File.Exists(cfgFile)) {
            try {
                string json = File.ReadAllText(cfgFile);
                string user = ExtractJsonVal(json, "user");
                string amt = ExtractJsonVal(json, "amount");
                bool enabled = json.Contains("\"enabled\":true") || json.Contains("\"enabled\": true");

                txtUser.Text = user;
                txtAmount.Text = amt;
                chkEnable.Checked = enabled;

                if (enabled && !string.IsNullOrEmpty(user)) {
                    lblCurrentStatus.Text = "Status: ● ACTIVE";
                    lblCurrentStatus.ForeColor = Color.FromArgb(74, 222, 128);
                    lblCommandPreview.Text = "Command: /pay " + user + " " + amt + " (Delay: 400 ticks)";
                } else {
                    lblCurrentStatus.Text = "Status: ○ DISABLED";
                    lblCurrentStatus.ForeColor = Color.FromArgb(148, 163, 184);
                    lblCommandPreview.Text = "Auto Pay is currently disabled";
                }
                return;
            } catch {}
        }
        lblCurrentStatus.Text = "Status: ○ NOT CONFIGURED";
        lblCurrentStatus.ForeColor = Color.FromArgb(148, 163, 184);
    }

    private void SaveAndRestart() {
        string user = txtUser.Text.Trim();
        string amt = txtAmount.Text.Trim();
        bool enable = chkEnable.Checked;

        if (enable && string.IsNullOrEmpty(user)) {
            MessageBox.Show("Please enter the recipient username!", "Validation", MessageBoxButtons.OK, MessageBoxIcon.Warning);
            txtUser.Focus();
            return;
        }

        if (enable && string.IsNullOrEmpty(amt)) {
            MessageBox.Show("Please enter the amount to pay (e.g. 10 or 1M)!", "Validation", MessageBoxButtons.OK, MessageBoxIcon.Warning);
            txtAmount.Focus();
            return;
        }

        string cmdStr = enable ? ("/pay " + user + " " + amt) : "";
        string confirmMsg = enable ? 
            string.Format("Confirm Auto Pay settings update:\n- Command: {0}\n- Interval: 400 ticks\n- Scope: All Instances\n\nMinecraft will automatically restart to apply settings!", cmdStr) :
            "Confirm disabling Auto Pay?\n\nMinecraft will automatically restart to apply settings!";

        DialogResult dr = MessageBox.Show(confirmMsg, "Confirm Changes", MessageBoxButtons.YesNo, MessageBoxIcon.Question);
        if (dr != DialogResult.Yes) return;

        lblStatusMsg.Text = "Applying configuration and restarting game clients...";
        lblStatusMsg.ForeColor = Color.FromArgb(253, 224, 71);

        // 1. Terminate running instances
        KillProcesses();

        // 2. Apply Meteor configuration
        ApplyMeteorConfig(user, amt, enable, cmdStr);

        // 3. Relaunch instances with adaptive thread tuning
        LaunchInstances();

        LoadCurrentConfig();
        lblStatusMsg.Text = "[OK] Configuration saved and instances successfully restarted!";
        lblStatusMsg.ForeColor = Color.FromArgb(74, 222, 128);
    }

    private void StopAllInstances() {
        DialogResult dr = MessageBox.Show("Are you sure you want to STOP ALL running Minecraft instances?", "Confirm Stop", MessageBoxButtons.YesNo, MessageBoxIcon.Warning);
        if (dr == DialogResult.Yes) {
            KillProcesses();
            lblStatusMsg.Text = "[OK] All Minecraft instances have been stopped!";
            lblStatusMsg.ForeColor = Color.FromArgb(239, 68, 68);
        }
    }

    private static void KillProcesses() {
        string[] pNames = new string[] { "javaw", "java" };
        foreach (string p in pNames) {
            try {
                foreach (Process proc in Process.GetProcessesByName(p)) {
                    proc.Kill();
                }
            } catch {}
        }
        System.Threading.Thread.Sleep(600);
    }

    private void ApplyMeteorConfig(string user, string amt, bool enable, string cmdStr) {
        if (!Directory.Exists(instancesDir)) return;

        foreach (string instPath in Directory.GetDirectories(instancesDir)) {
            string[] mDirs = new string[] {
                Path.Combine(instPath, @".minecraft\meteor-client"),
                Path.Combine(instPath, @"meteor-client")
            };

            foreach (string meteorDir in mDirs) {
                try {
                    if (!Directory.Exists(meteorDir)) Directory.CreateDirectory(meteorDir);

                    // Write pay_config.json
                    string cfgFile = Path.Combine(meteorDir, "pay_config.json");
                    string json = string.Format("{{\"user\":\"{0}\",\"amount\":\"{1}\",\"enabled\":{2},\"updated\":\"{3}\"}}",
                        user, amt, enable ? "true" : "false", DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss"));
                    File.WriteAllText(cfgFile, json, Encoding.UTF8);

                    // Build NBT
                    byte[] noRenderBytes = Convert.FromBase64String(NoRenderGzB64);
                    byte[] decomp = DecompressGz(noRenderBytes);
                    byte[] noRenderComp = new byte[decomp.Length - 19];
                    Array.Copy(decomp, 18, noRenderComp, 0, noRenderComp.Length);

                    int moduleCount = 1;
                    byte[] spamComp = null;

                    if (enable && !string.IsNullOrEmpty(cmdStr)) {
                        moduleCount = 2;
                        spamComp = BuildSpamNbtBytes(cmdStr, 400);

                        using (MemoryStream sMs = new MemoryStream()) {
                            sMs.WriteByte(10);
                            sMs.WriteByte(0); sMs.WriteByte(0);
                            sMs.Write(spamComp, 0, spamComp.Length);
                            byte[] spamGz = CompressGz(sMs.ToArray());

                            string[] sPaths = new string[] {
                                Path.Combine(meteorDir, @"modules\Spam.nbt"),
                                Path.Combine(meteorDir, @"modules\spam.nbt"),
                                Path.Combine(meteorDir, @"presets\spam.nbt"),
                                Path.Combine(meteorDir, @"presets\spam\default.nbt")
                            };
                            foreach (string sp in sPaths) {
                                string pDir = Path.GetDirectoryName(sp);
                                if (!Directory.Exists(pDir)) Directory.CreateDirectory(pDir);
                                File.WriteAllBytes(sp, spamGz);
                            }
                        }
                    }

                    // Standalone no-render files
                    string[] nrPaths = new string[] {
                        Path.Combine(meteorDir, @"modules\No Render.nbt"),
                        Path.Combine(meteorDir, @"modules\no-render.nbt"),
                        Path.Combine(meteorDir, @"presets\no-render.nbt"),
                        Path.Combine(meteorDir, @"presets\no-render\default.nbt"),
                        Path.Combine(meteorDir, @"no-render.nbt")
                    };
                    foreach (string np in nrPaths) {
                        string pDir = Path.GetDirectoryName(np);
                        if (!Directory.Exists(pDir)) Directory.CreateDirectory(pDir);
                        File.WriteAllBytes(np, noRenderBytes);
                    }

                    // Root modules.nbt
                    using (MemoryStream rMs = new MemoryStream()) {
                        rMs.WriteByte(10); // TAG_Compound
                        rMs.WriteByte(0); rMs.WriteByte(0); // empty name
                        rMs.WriteByte(9);  // TAG_List
                        rMs.WriteByte(0); rMs.WriteByte(7); // length = 7
                        byte[] mBytes = Encoding.UTF8.GetBytes("modules");
                        rMs.Write(mBytes, 0, 7);
                        rMs.WriteByte(10); // type = TAG_Compound
                        rMs.WriteByte((byte)((moduleCount >> 24) & 0xFF));
                        rMs.WriteByte((byte)((moduleCount >> 16) & 0xFF));
                        rMs.WriteByte((byte)((moduleCount >> 8) & 0xFF));
                        rMs.WriteByte((byte)(moduleCount & 0xFF));

                        rMs.Write(noRenderComp, 0, noRenderComp.Length);
                        if (moduleCount == 2 && spamComp != null) {
                            rMs.Write(spamComp, 0, spamComp.Length);
                        }
                        rMs.WriteByte(0); // TAG_End

                        byte[] finalGz = CompressGz(rMs.ToArray());
                        File.WriteAllBytes(Path.Combine(meteorDir, "modules.nbt"), finalGz);
                    }
                } catch {}
            }

            // Also update options.txt in both .minecraft and instance root
            string[] optFiles = new string[] {
                Path.Combine(instPath, @".minecraft\options.txt"),
                Path.Combine(instPath, @"options.txt")
            };
            foreach (string optFile in optFiles) {
                try {
                    if (File.Exists(optFile)) {
                        string[] lines = File.ReadAllLines(optFile);
                        bool hasSim = false;
                        for (int i = 0; i < lines.Length; i++) {
                            if (lines[i].StartsWith("simulationDistance:")) {
                                lines[i] = "simulationDistance:32";
                                hasSim = true;
                            } else if (lines[i].StartsWith("renderDistance:")) {
                                lines[i] = "renderDistance:32";
                            } else if (lines[i].StartsWith("maxFps:")) {
                                lines[i] = "maxFps:120";
                            } else if (lines[i].StartsWith("enableVsync:")) {
                                lines[i] = "enableVsync:true";
                            }
                        }
                        if (!hasSim) {
                            var list = new System.Collections.Generic.List<string>(lines);
                            list.Add("simulationDistance:32");
                            lines = list.ToArray();
                        }
                        File.WriteAllLines(optFile, lines, Encoding.UTF8);
                    }
                } catch {}
            }
        }
    }

    private static byte[] BuildSpamNbtBytes(string payCommand, int delay) {
        using (MemoryStream ms = new MemoryStream()) {
            WriteTagString(ms, "name", "spam");

            ms.WriteByte(10); // TAG_Compound "keybind"
            WriteU16(ms, 7);
            byte[] kb = Encoding.UTF8.GetBytes("keybind");
            ms.Write(kb, 0, 7);
            WriteTagByte(ms, "isKey", 1);
            WriteTagInt(ms, "value", 96);
            ms.WriteByte(0); // TAG_End

            WriteTagByte(ms, "toggleOnKeyRelease", 0);
            WriteTagByte(ms, "chatFeedback", 1);
            WriteTagByte(ms, "favorite", 0);

            ms.WriteByte(10); // TAG_Compound "settings"
            WriteU16(ms, 8);
            byte[] sb = Encoding.UTF8.GetBytes("settings");
            ms.Write(sb, 0, 8);

            ms.WriteByte(9); // TAG_List "groups"
            WriteU16(ms, 6);
            byte[] gb = Encoding.UTF8.GetBytes("groups");
            ms.Write(gb, 0, 6);
            ms.WriteByte(10); // TAG_Compound
            WriteI32(ms, 1);

            ms.WriteByte(8); // TAG_String "name"
            WriteU16(ms, 4);
            byte[] nb = Encoding.UTF8.GetBytes("name");
            ms.Write(nb, 0, 4);
            WriteU16(ms, 7);
            byte[] vb = Encoding.UTF8.GetBytes("default");
            ms.Write(vb, 0, 7);

            ms.WriteByte(9); // TAG_List "settings"
            WriteU16(ms, 8);
            ms.Write(sb, 0, 8);
            ms.WriteByte(10); // TAG_Compound
            WriteI32(ms, 7);

            // setting 1: bypass
            WriteTagString(ms, "name", "bypass");
            WriteTagByte(ms, "value", 0);
            ms.WriteByte(0);

            // setting 2: delay
            WriteTagString(ms, "name", "delay");
            WriteTagInt(ms, "value", delay);
            ms.WriteByte(0);

            // setting 3: disable-on-leave
            WriteTagString(ms, "name", "disable-on-leave");
            WriteTagByte(ms, "value", 0);
            ms.WriteByte(0);

            // setting 4: disable-on-disconnect
            WriteTagString(ms, "name", "disable-on-disconnect");
            WriteTagByte(ms, "value", 0);
            ms.WriteByte(0);

            // setting 5: messages
            WriteTagString(ms, "name", "messages");
            ms.WriteByte(9); // TAG_List "value"
            WriteU16(ms, 5);
            byte[] valB = Encoding.UTF8.GetBytes("value");
            ms.Write(valB, 0, 5);
            ms.WriteByte(8); // TAG_String
            WriteI32(ms, 1);
            byte[] cmdBytes = Encoding.UTF8.GetBytes(payCommand);
            WriteU16(ms, cmdBytes.Length);
            ms.Write(cmdBytes, 0, cmdBytes.Length);
            ms.WriteByte(0);

            // setting 6: random
            WriteTagString(ms, "name", "random");
            WriteTagByte(ms, "value", 0);
            ms.WriteByte(0);

            // setting 7: tick-delay
            WriteTagString(ms, "name", "tick-delay");
            WriteTagByte(ms, "value", 1);
            ms.WriteByte(0);

            ms.WriteByte(0); // end of group
            ms.WriteByte(0); // end of settings
            WriteTagByte(ms, "active", 1);
            ms.WriteByte(0); // end of module

            return ms.ToArray();
        }
    }

    private static void WriteU16(Stream s, int val) {
        s.WriteByte((byte)((val >> 8) & 0xFF));
        s.WriteByte((byte)(val & 0xFF));
    }

    private static void WriteI32(Stream s, int val) {
        s.WriteByte((byte)((val >> 24) & 0xFF));
        s.WriteByte((byte)((val >> 16) & 0xFF));
        s.WriteByte((byte)((val >> 8) & 0xFF));
        s.WriteByte((byte)(val & 0xFF));
    }

    private static void WriteTagString(Stream s, string name, string val) {
        s.WriteByte(8);
        byte[] nb = Encoding.UTF8.GetBytes(name);
        WriteU16(s, nb.Length);
        s.Write(nb, 0, nb.Length);
        byte[] vb = Encoding.UTF8.GetBytes(val);
        WriteU16(s, vb.Length);
        s.Write(vb, 0, vb.Length);
    }

    private static void WriteTagByte(Stream s, string name, byte val) {
        s.WriteByte(1);
        byte[] nb = Encoding.UTF8.GetBytes(name);
        WriteU16(s, nb.Length);
        s.Write(nb, 0, nb.Length);
        s.WriteByte(val);
    }

    private static void WriteTagInt(Stream s, string name, int val) {
        s.WriteByte(3);
        byte[] nb = Encoding.UTF8.GetBytes(name);
        WriteU16(s, nb.Length);
        s.Write(nb, 0, nb.Length);
        WriteI32(s, val);
    }

    private static byte[] CompressGz(byte[] data) {
        using (MemoryStream ms = new MemoryStream()) {
            using (GZipStream gz = new GZipStream(ms, CompressionMode.Compress)) {
                gz.Write(data, 0, data.Length);
            }
            return ms.ToArray();
        }
    }

    private static byte[] DecompressGz(byte[] data) {
        using (MemoryStream msIn = new MemoryStream(data))
        using (GZipStream gz = new GZipStream(msIn, CompressionMode.Decompress))
        using (MemoryStream msOut = new MemoryStream()) {
            gz.CopyTo(msOut);
            return msOut.ToArray();
        }
    }

    private void LaunchInstances() {
        string prismExe = Path.Combine(prismDir, "prismlauncher.exe");
        if (!File.Exists(prismExe)) return;

        // Read accounts
        string[] accounts = new string[0];
        string accFile = Path.Combine(prismDir, "accounts.json");
        if (File.Exists(accFile)) {
            try {
                string aj = File.ReadAllText(accFile);
                var matches = System.Text.RegularExpressions.Regex.Matches(aj, "\"name\"\\s*:\\s*\"([^\"]+)\"");
                accounts = new string[matches.Count];
                for (int i = 0; i < matches.Count; i++) accounts[i] = matches[i].Groups[1].Value;
            } catch {}
        }

        string[] insts = new string[] { "VPS-AFK-1", "VPS-AFK-2", "VPS-AFK-3" };
        int launched = 0;

        foreach (string inst in insts) {
            if (Directory.Exists(Path.Combine(instancesDir, inst))) {
                string acc = (launched < accounts.Length) ? accounts[launched] : "";
                string args = "--launch \"" + inst + "\" --server donutsmp.net" + (!string.IsNullOrEmpty(acc) ? " --profile \"" + acc + "\"" : "");
                
                try {
                    ProcessStartInfo psi = new ProcessStartInfo {
                        FileName = prismExe,
                        Arguments = args,
                        WorkingDirectory = prismDir,
                        UseShellExecute = false,
                        CreateNoWindow = true
                    };
                    psi.EnvironmentVariables["LP_NUM_THREADS"] = (Environment.ProcessorCount <= 4) ? "1" : "2";
                    psi.EnvironmentVariables["MESA_GL_VERSION_OVERRIDE"] = "3.3";
                    Process.Start(psi);
                    launched++;
                    System.Threading.Thread.Sleep(5000); // 5s delay
                } catch {}
            }
        }
    }

    private static string ExtractJsonVal(string json, string key) {
        var m = System.Text.RegularExpressions.Regex.Match(json, "\"" + key + "\"\\s*:\\s*\"([^\"]*)\"");
        return m.Success ? m.Groups[1].Value : "";
    }

    [STAThread]
    public static void Main() {
        Application.EnableVisualStyles();
        Application.SetCompatibleTextRenderingDefault(false);
        Application.Run(new AutoPayManagerForm());
    }
}
