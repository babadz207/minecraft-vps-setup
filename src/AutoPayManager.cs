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
        string[] candidates = new string[] {
            Path.Combine(instancesDir, @"VPS-AFK-1\.minecraft\meteor-client\pay_config.json"),
            Path.Combine(instancesDir, @"VPS-AFK-1\meteor-client\pay_config.json"),
            Path.Combine(baseDir, "pay_config.json"),
            Path.Combine(baseDir, @"data\pay_config.json")
        };
        foreach (string cfgFile in candidates) {
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
                                File.WriteAllBytes(sp, sMs.ToArray());
                            }
                        }
                    }

                    // Standalone no-render files (UNCOMPRESSED NBT)
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
                        File.WriteAllBytes(np, decomp);
                    }

                    // Root modules.nbt (RAW UNCOMPRESSED NBT for Meteor Client System.load)
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

                        byte[] finalRaw = rMs.ToArray();
                        File.WriteAllBytes(Path.Combine(meteorDir, "modules.nbt"), finalRaw);

                        string profDir = Path.Combine(meteorDir, @"profiles\default");
                        if (!Directory.Exists(profDir)) Directory.CreateDirectory(profDir);
                        File.WriteAllBytes(Path.Combine(profDir, "modules.nbt"), finalRaw);
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
                        bool hasSim = false; bool hasAsKey = false;
                        for (int i = 0; i < lines.Length; i++) {
                            if (lines[i].StartsWith("simulationDistance:")) {
                                lines[i] = "simulationDistance:32";
                                hasSim = true;
                            } else if (lines[i].StartsWith("renderDistance:")) {
                                lines[i] = "renderDistance:32";
                            } else if (lines[i].StartsWith("maxFps:")) {
                                lines[i] = "maxFps:120";
                            } else if (lines[i].StartsWith("enableVsync:")) {
                                lines[i] = "enableVsync:false";
                            } else if (lines[i].StartsWith("mipmapLevels:")) {
                                lines[i] = "mipmapLevels:0";
                            } else if (lines[i].StartsWith("ao:")) {
                                lines[i] = "ao:false";
                            } else if (lines[i].StartsWith("entityShadows:")) {
                                lines[i] = "entityShadows:false";
                            } else if (lines[i].StartsWith("resourcePacks:")) {
                                lines[i] = "resourcePacks:[\"vanilla\",\"file/beatrix_shop.zip\"]";
                            } else if (lines[i].StartsWith("incompatibleResourcePacks:")) {
                                lines[i] = "incompatibleResourcePacks:[]";
                            } else if (lines[i].StartsWith("key_key.autosell.toggle:")) {
                                lines[i] = "key_key.autosell.toggle:key.keyboard.left.bracket";
                                hasAsKey = true;
                            }
                        }
                        if (!hasAsKey) { var l = new System.Collections.Generic.List<string>(lines); l.Add("key_key.autosell.toggle:key.keyboard.left.bracket"); lines = l.ToArray(); }
                        if (!hasSim) {
                            var list = new System.Collections.Generic.List<string>(lines);
                            list.Add("simulationDistance:32");
                            lines = list.ToArray();
                        }
                        File.WriteAllLines(optFile, lines, Encoding.UTF8);
                    }
                } catch {}
            }

            // Ensure beatrix_shop pack.mcmeta has native pack_format 34 (Minecraft 1.21.1)
            try {
                string rpDir = Path.Combine(instPath, @".minecraft\resourcepacks");
                if (Directory.Exists(rpDir)) {
                    string cleanMeta = "{\n  \"pack\": {\n    \"pack_format\": 34,\n    \"supported_formats\": {\"min_inclusive\": 1, \"max_inclusive\": 100},\n    \"description\": \"beatrix_shop 1.9\"\n  }\n}";
                    string cleanZip = Path.Combine(rpDir, "beatrix_shop.zip");
                    string old1 = Path.Combine(rpDir, "beatrix_shop 1.9v1.zip");
                    string old2 = Path.Combine(rpDir, "beatrix_shop 1.9v1 (1).zip");
                    if (!File.Exists(cleanZip)) {
                        if (File.Exists(old1) && new FileInfo(old1).Length > 10000000) File.Copy(old1, cleanZip, true);
                        else if (File.Exists(old2) && new FileInfo(old2).Length > 10000000) File.Copy(old2, cleanZip, true);
                    }
                    if (File.Exists(cleanZip) && new FileInfo(cleanZip).Length > 1000000) {
                        try {
                            using (ZipArchive za = ZipFile.Open(cleanZip, ZipArchiveMode.Update)) {
                                ZipArchiveEntry ze = za.GetEntry("pack.mcmeta");
                                if (ze != null) ze.Delete();
                                ZipArchiveEntry ne = za.CreateEntry("pack.mcmeta");
                                using (StreamWriter sw = new StreamWriter(ne.Open(), new UTF8Encoding(false))) {
                                    sw.Write(cleanMeta);
                                }
                            }
                        } catch {}
                    }
                    // Clean up old redundant files and folders
                    try {
                        if (File.Exists(old1)) File.Delete(old1);
                        if (File.Exists(old2)) File.Delete(old2);
                        string extFolder = Path.Combine(rpDir, "beatrix_shop");
                        if (Directory.Exists(extFolder)) Directory.Delete(extFolder, true);
                    } catch {}
                }
            } catch {}

            // Disable mods that crash on software OpenGL or spam chat
            try {
                string[] modFolders = new string[] {
                    Path.Combine(instPath, @".minecraft\mods"),
                    Path.Combine(instPath, @"mods")
                };
                foreach (string md in modFolders) {
                    if (Directory.Exists(md)) {
                        foreach (string jf in Directory.GetFiles(md, "iris-fabric*.jar")) {
                            try { File.Move(jf, jf + ".disabled"); } catch {}
                        }
                        foreach (string jf in Directory.GetFiles(md, "opsec*.jar")) {
                            try { File.Move(jf, jf + ".disabled"); } catch {}
                        }
                        // Ensure forcecloseloadingscreen mod is copied if available
                        string srcFc = Path.Combine(baseDir, @"bin\forcecloseloadingscreen-2.3.4.jar");
                        string dstFc = Path.Combine(md, "forcecloseloadingscreen-2.3.4.jar");
                        if (File.Exists(srcFc) && (!File.Exists(dstFc) || new FileInfo(dstFc).Length < 50000)) {
                            try { File.Copy(srcFc, dstFc, true); } catch {}
                        }
                    }
                }
            } catch {}

            // Write sodium-options.json with always_defer_chunk_updates: false
            try {
                string cfgDir = Path.Combine(instPath, @".minecraft\config");
                if (!Directory.Exists(cfgDir)) Directory.CreateDirectory(cfgDir);
                string sodJson = "{\n  \"quality\": {\n    \"weather_quality\": \"FAST\",\n    \"leaves_quality\": \"FAST\"\n  },\n  \"performance\": {\n    \"chunk_builder_threads\": 1,\n    \"always_defer_chunk_updates\": true,\n    \"animate_only_visible_textures\": true\n  }\n}";
                File.WriteAllText(Path.Combine(cfgDir, "sodium-options.json"), sodJson, Encoding.UTF8);
            } catch {}
        }

        // Central pay_config.json & sync invocation
        try {
            string centralJson = string.Format("{{\"user\":\"{0}\",\"amount\":\"{1}\",\"enabled\":{2},\"updated\":\"{3}\"}}",
                user, amt, enable ? "true" : "false", DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss"));
            File.WriteAllText(Path.Combine(baseDir, "pay_config.json"), centralJson, Encoding.UTF8);
            string dDir = Path.Combine(baseDir, "data");
            if (!Directory.Exists(dDir)) Directory.CreateDirectory(dDir);
            File.WriteAllText(Path.Combine(dDir, "pay_config.json"), centralJson, Encoding.UTF8);

            string syncScript = Path.Combine(baseDir, @"bin\sync-configs.ps1");
            if (File.Exists(syncScript)) {
                ProcessStartInfo psi = new ProcessStartInfo("powershell.exe", "-NoProfile -ExecutionPolicy Bypass -File \"" + syncScript + "\" -BaseDir \"" + baseDir + "\"");
                psi.CreateNoWindow = true;
                psi.UseShellExecute = false;
                Process p = Process.Start(psi);
                if (p != null) p.WaitForExit(3000);
            }
        } catch {}
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
            WriteTagInt(ms, "modifiers", 0);
            ms.WriteByte(0); // TAG_End

            WriteTagByte(ms, "toggleOnKeyRelease", 0);
            WriteTagByte(ms, "chatFeedback", 0);
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

            WriteTagString(ms, "name", "General");
            WriteTagByte(ms, "sectionExpanded", 1);

            ms.WriteByte(9); // TAG_List "settings"
            WriteU16(ms, 8);
            ms.Write(sb, 0, 8);
            ms.WriteByte(10); // TAG_Compound
            WriteI32(ms, 7);

            // setting 1: messages
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

            // setting 5: randomise
            WriteTagString(ms, "name", "randomise");
            WriteTagByte(ms, "value", 0);
            ms.WriteByte(0);

            // setting 6: auto-split-messages
            WriteTagString(ms, "name", "auto-split-messages");
            WriteTagByte(ms, "value", 0);
            ms.WriteByte(0);

            // setting 7: bypass
            WriteTagString(ms, "name", "bypass");
            WriteTagByte(ms, "value", 0);
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
