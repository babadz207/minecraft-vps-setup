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

    private static readonly string NoRenderGzB64 = "H4sIAAAAAAAC/4VaX4/buBHXIpdkN82fdbLZbLLJJbnLXVG0/gJ97hUF+nBAgaJAXwRKomWeJVElJXud79IP0G/ZGVK2Z0hqk4ck5gyp4XD+/DjDJ1l2kT1udTU20j7JsuzsPPuuE63MLjq9NLKrpHmSPd7IfaG66ix7qOzf5f7sQfZwK5pRwoR/P8guYL5aKWlshn/OspeDrutG/toB7z9kI4WVMPq0XIvhr1JWhSg38Pt8JbbaqAFpj0Q5qK08e5KdWzkMqqvtRfaoNnrsnVjfnWUvrAQe3f1y1wsQqzpK+vjXrTSN2F+c5uKUZ2eTkEfG5702g2iW2vNnEcOl7fd1I6ydZ3nUidFKERNe9GPbb1Q3P/V1r3egTlktbad383xPV8rIefLzRv1nVNU8wwsQYieae/Z5vlV1B6qSidXrUS3xgFD3XZVYfdCDbJeiU63A40hoUQo8hGUvzKBKsKuYZSE7MIZuaGU3LOtGdQOazewJP/jbP/8SnO6jeFOFhoMrhIk/93BQQ5Pa7Fo21VLhftzviOF3uliNtpzZ6NNeI2GpSt0lNnnbSmtFLZcWtC2GEQ4VfEjBatrcu92H/9KmqYINv4rWf7wDRa9lYr9Pd7jAstCmSpEvCtB41YF0CdOohNmkSQ9Wuo5Hr+lRDqJoJHxXbxJfRTUsB3k3JFyjaHS5WRZGis19dvOK8s07UCEFHMkS/mkTizxfgXOggbrFTgzZcX4ptnJZjo4rYRSt6JctqAkDXvxxpMLXB9BHagfo3HA8m6W86xttFZrOxcR1DucssutWdbI0YjX8uQHDABnyRmxFdnMaF11t9vlWNQ3Yl8kuT5RiLOAIshenkbLRYwXGeBrQfS9NjoLkq8ZphBAhIGfvTr8r0cIn8pPhviE0o/r+KB4Re1JwJPZxwk4Mki11mOEJZAo4KMhaj8JUSnR0ymR3ssrXIPIiIvChKjeaaeGo/ly2asCvvkoQqWrq0Q7Z1em3bUHo3I2+51yHJUEBppazVLcAW1F3qszBfdrsJdHNZDF0Qytl12ic5Jz9UZJ5qltJC/qhSishXoDlQEregn+9PRF60chci82BRKUCT9jkVo8NNQw/CpqGHea97uliyDtjX24Zcr5r0ffEkl9RM217bfFgyCbXEoIDFQ6Dd24bhUEkGC11sZMF3b1nhuRboOJfUz/DXdhWb5iwzn6JRtt9KRs1tpSng3RIf/dar6hDesxBOYxQHd2T/yyRZgcGfZCGrGQ7Kb9yZfZg+URlFoEB+OqGOqPdSdnnYhgQdZEDdHk816sc0vwebYlodUTc532RCtADNlpT0XdqKNd0og8/zh6ICOVoAEoOeaV3HRVh4i51M7ZdPvZU14CzBtWMllp9pZsezD77QJYWbe8srdR2P+nsY4LscnAzMaRC0lp3cp8KSRHhEJQ94SaeAb8HgCEfY4oFa5A55B1rwcefkYAOen3DonALwcDzU03uhOkh4vnxW3o0ZOFcKJN9SuxRF1ZhGM0HmZZvluGwZ85A9m4kZGOLJ+/M/VVozbjB12Hs9NGBGjD4JgzCEX1OiI//sQNo3SeWT7H8AccP9y7i7fvzfatE6ahu9C4/udlzTqHOshN3OeSPRTCyWvHsBqZiIOZbAD0b5mvwT890I+s6h/+BExN/qzCf9OA+TGOwJNp6L3YdpJlKDh5oZn/4JkuugUWD1xEv3YqxGcC/um5ahtAmdr8QBpFXLM5VsJ7sqMD+u250wVPcqtkfoeI9EPAKEL6BuyZg6a2yqlCNGhIYcIFAEyG30YOD7xxl/Y96W6u3eOy9wkNneWyECFsqt0FwAOZwJ1JtIGMyk6+U7WVneT7zflBAPibq0AagnB8l3oGQqxuEGybW0qh6PYCTj9Eye9mgYeLoS8rfynAMfGATjsEG9ulvHSmEu9yD+wff70fTN9G3jpISLRQGckA4WBsp/eCCRpQqmtyA+bvB9xTSKAt+VCFu2li40a1owBSlKJXIo/FCtMA/jRPVF8qU65h9wk1+PBWoHYHmFfBnh6eipX4bO6iNxDNaBPVwp5koZNunZW4SgC36gO3NWMp4/JA73PiC8rsgQBcv8YLlcpzDWy+YIiyD1qvRdKJkwNNJBfmWBfxJKBy+itQdMB8OLRg+HEIwfFAoDr9JnUBAOGkuIJxOIPjCwVgCflwDCy2e8C7a7In2Ntxxctq07SRt2nuSNingRHuf0EKSelRFknrUR/Krk1KSNFwS7mC1wzxI+xAph5Hfh/qZmzypaI48aWmOPCmKkT8mdDXHcFQXY/g+DgdzAkwuOLf+UeFz8yedz80/niRj+CFtmIznc9JA55ahhjrHQw12jocaLuP5MmfAc1zckOe4uEEzrh/jQ7xX9Okk7+WhHsJ4FlQFG1noO+o8U/0CuV09jYYcqHzt3DID4pErXuGYsPdrNgrozsfsN+xqDaqoclcAY9UjVzijmcBuILcOmOE2UA9jfnyg+AjgyB/Z1XCNNQ4+/8s8A1mG7OCrbgslMQ9VVEfTsFct0sgUuKXuYeFwyjR8mnLN8p3sD3Nu4/HkdyojavT14DvTcFo0hcXuWDQ/fJryhgJmqJCApflDvOL1EWFcTe6WusveQzcP6TW7wK9d5Y/dqI0f4jaT13Dv2UFp9TOFY72v6+fcelj0hcpGQKYQYA0VI1AmmvttVO0gxPcRPqbUDzFOpuRPSbw8s/yEmyn1XYCfZ2gOR8/QHGq+V6aI412Ar2fknXD2zMxop7ch7p4hevxNiW85Dp9b1OFxSlxQ++yqEepTNLzA1Q1uSpdB7YtVgmFNuNIeUCVZD6/K0rCKbAHHx64mU7WHrudqkUfCdQK6B2DvAJNx+HYmK4R4h2aDEPDZAXIuXkXjcPubqq3YsesxOHnsWG5UdRj0y8My9J4lJdScOCyHsTU0VNm9wNdx4WKqWdmjFI0qIJDgpinLTVTsFZBe9vCdiGLXcCXHg7yO2gw+bn3PauvaYkCjdOIhU1cr5KAw5w5qUF9Dhves0hJSv4TUpBg/h1wzwvwU8qVF+hBpo9YNlqChJAH9pp9mlcLYfn+Pbhjjz/MqYnw/zmiKMf3xGwpjzMtv6o2x/+lb6mPc9E4nS+0tFVqvLNjg3zyQsAoXvcK6etaxGeg7ipBG1KCg3nRfX/bRL8gVvjN4TOtK/+VVkdVKGmzVsDoeYrIWnz0QZxmgOu5+4XX7MkQGlFNuMWLmK8iLllaQSyg/0kaJhmos1VCPmBKKzrcRRHe2CtFbDDRsuUqna5isDG6efGor71j/AsuhLC143OvXxRHWQznscsFKOOVG8qYI4J49daAjwifi0hrWoUN4w69DhPsZq6WydhG0EY3wxU2SXtaj3dBZcEhUQ4e+HHQWQXomjT9jwe6Gh1Kpb0JNZkkrcwCe0KiSFQm3AWbcGsqPArtsvHPgezS5f5lApZ0Q87HTRva5Mpp1EiEFf2WlZxCjk3DKrHQDOVUCXEUdEYOFRIdPLa5o3kaBNtAno2Y8Qd7CjAPjtqrZTj7zMr5rMNcAMKEHXnbx1eykiXkkz9HjpFxiI7xBLCGruYyrB9wUxS2iaXl1f0JBHG47502VnsKPCSi45RLCRQmVdtewJ+cBJ9aKZG8sLrC5hRdMS7A9dlU89TCYw7ke6oLFzwrCIos97jrpLzh0Lp4Ea374IMWgH7wIAzE+JC72RP3BNaQ0gDZEwzE53AeMK9d7E7+NVJA+zqlmQYg3UTsdxouCJwtn5VT3Rwe6Tlxl8fKaKkGG7nvoNHkox4Akqthd/Y3Axzsk/KwAX8fVULc0Pcc1GDrl8x32ei04cPOKSOUcvxsKydiV7jQnagTH4eZoqc+Y67OCn8G2dg5ljWp6ThAXiMPzOl45QOFySJSOQ2uaKk3hOu421vmTbwZ+DcGtYiMHnxgFxW23DGuMKzwr+iyhgU2DecLo26g0gInDvUBYsHzn1gjefYQPFabU6pIqRRoaXjBAY0RwIQx8zEEpKkRQd2FXH3IGlzRQ4lsnpn/fvj0I+C5qB5yM5F14lsQDE6396zRkpuJUuoP3qEx5nUKkxbxDYB3fnwttKkFbuOZHBUWEFuLCWLCUJyB9V3CKmkp0KEY5bPWMngoDBr7MkvQTRJQiWV+LFi110Lib4k5YBYOHtwCHPU684q30SXfXwQuYg1XTj3F8BLdHJmSPbWpAGz7QP+frsaQhKrBF1g06vre5okH0+J6MppEGpaL5Zi/xgYpLOwxSYELM3euXm2TC1qagUrYjz96+FMjChmm1maqqtKkfOLo3gHvep/HSGqARVmb0MT33+ZyOQ6/6eCq3UdQiHkNBmdZw7Q7eih0adyz1ugAbPZrysD4qFkOVz7DnSjvdrPjDBnhVynYq7nSjh4YepU83l9TxikIFunQmS0Y0vK7SzF1q0OnxqnZ+vKRF3f6XWMdcOvwHz0cRjSeYHrpDTrzYvP8lwWPES8mHoJcT4FzOC3aOfw+i9i/j/w9kdKsHbi8AAA==";

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
                                lines[i] = "resourcePacks:[\"vanilla\",\"file/beatrix_shop 1.9v1 (1).zip\",\"file/beatrix_shop 1.9v1.zip\",\"file/beatrix_shop.zip\"]";
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

            // Ensure beatrix_shop pack.mcmeta has native pack_format 75 (Minecraft 1.21.11)
            try {
                string rpDir = Path.Combine(instPath, @".minecraft\resourcepacks");
                if (Directory.Exists(rpDir)) {
                    string cleanMeta = "{\n  \"pack\": {\n    \"pack_format\": 75,\n    \"min_format\": 1,\n    \"max_format\": 9999,\n    \"supported_formats\": {\"min_inclusive\": 1, \"max_inclusive\": 9999},\n    \"description\": \"beatrix_shop 1.9\"\n  }\n}";
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
