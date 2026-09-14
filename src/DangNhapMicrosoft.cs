using System;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Windows.Forms;

public class MicrosoftLoginForm : Form {
    public MicrosoftLoginForm() {
        this.Text = "Microsoft Account Setup - Prism Launcher";
        this.Size = new Size(620, 530);
        this.StartPosition = FormStartPosition.CenterScreen;
        this.FormBorderStyle = FormBorderStyle.FixedDialog;
        this.MaximizeBox = false;
        this.BackColor = Color.FromArgb(15, 23, 42); // Slate Dark

        // Header
        Label title = new Label();
        title.Text = "MICROSOFT ACCOUNT SETUP GUIDE";
        title.Font = new Font("Segoe UI", 14, FontStyle.Bold);
        title.ForeColor = Color.FromArgb(56, 189, 248); // Sky Blue
        title.Location = new Point(20, 16);
        title.Size = new Size(565, 30);
        title.TextAlign = ContentAlignment.MiddleCenter;
        this.Controls.Add(title);

        Label sub = new Label();
        sub.Text = "donutsmp.net requires an official Microsoft account (One-time setup only)";
        sub.Font = new Font("Segoe UI", 9.5f);
        sub.ForeColor = Color.FromArgb(148, 163, 184);
        sub.Location = new Point(20, 48);
        sub.Size = new Size(565, 22);
        sub.TextAlign = ContentAlignment.MiddleCenter;
        this.Controls.Add(sub);

        // Steps Panel
        Panel panel = new Panel();
        panel.Location = new Point(25, 80);
        panel.Size = new Size(555, 300);
        panel.BackColor = Color.FromArgb(30, 41, 59); // Card Dark
        panel.BorderStyle = BorderStyle.FixedSingle;
        this.Controls.Add(panel);

        string[] steps = new string[] {
            "STEP 1: Click [Open Prism Launcher] below to launch the game manager.",
            "STEP 2: In Prism Launcher (top right), click [Accounts] -> [Manage Accounts].",
            "STEP 3: Click [Add Microsoft] on the right action toolbar.",
            "STEP 4: Click [Open Page and Copy Code] on Prism's login dialog.\n             -> The one-time code is automatically copied to your clipboard!",
            "STEP 5: Web browser opens microsoft.com/link (or click the button below).\n             -> Press [Ctrl + V] to paste the code and sign in with your account.",
            "STEP 6: Completed! Your profile appears in Accounts. You can now start AFK!"
        };

        int top = 14;
        foreach (string st in steps) {
            Label lbl = new Label();
            lbl.Text = st;
            lbl.Font = new Font("Segoe UI", 9.5f);
            lbl.ForeColor = st.StartsWith("STEP 6") ? Color.FromArgb(74, 222, 128) : Color.FromArgb(241, 245, 249);
            lbl.Location = new Point(14, top);
            lbl.Size = new Size(525, st.Contains("\n") ? 42 : 32);
            panel.Controls.Add(lbl);
            top += st.Contains("\n") ? 46 : 36;
        }

        // Action Buttons
        Button btnOpenPrism = new Button();
        btnOpenPrism.Text = "🚀 OPEN PRISM LAUNCHER";
        btnOpenPrism.Font = new Font("Segoe UI", 10, FontStyle.Bold);
        btnOpenPrism.BackColor = Color.FromArgb(34, 197, 94); // Emerald Green
        btnOpenPrism.ForeColor = Color.White;
        btnOpenPrism.FlatStyle = FlatStyle.Flat;
        btnOpenPrism.FlatAppearance.BorderSize = 0;
        btnOpenPrism.Location = new Point(25, 395);
        btnOpenPrism.Size = new Size(265, 42);
        btnOpenPrism.Cursor = Cursors.Hand;
        btnOpenPrism.Click += (s, e) => {
            OpenPrism();
        };
        this.Controls.Add(btnOpenPrism);

        Button btnOpenLink = new Button();
        btnOpenLink.Text = "🌐 OPEN MICROSOFT.COM/LINK";
        btnOpenLink.Font = new Font("Segoe UI", 10, FontStyle.Bold);
        btnOpenLink.BackColor = Color.FromArgb(59, 130, 246); // Blue
        btnOpenLink.ForeColor = Color.White;
        btnOpenLink.FlatStyle = FlatStyle.Flat;
        btnOpenLink.FlatAppearance.BorderSize = 0;
        btnOpenLink.Location = new Point(315, 395);
        btnOpenLink.Size = new Size(265, 42);
        btnOpenLink.Cursor = Cursors.Hand;
        btnOpenLink.Click += (s, e) => {
            try { Process.Start("https://microsoft.com/link"); } catch {}
        };
        this.Controls.Add(btnOpenLink);

        Button btnClose = new Button();
        btnClose.Text = "Close";
        btnClose.Font = new Font("Segoe UI", 9.5f);
        btnClose.BackColor = Color.FromArgb(51, 65, 85);
        btnClose.ForeColor = Color.White;
        btnClose.FlatStyle = FlatStyle.Flat;
        btnClose.FlatAppearance.BorderSize = 0;
        btnClose.Location = new Point(245, 447);
        btnClose.Size = new Size(130, 32);
        btnClose.Cursor = Cursors.Hand;
        btnClose.Click += (s, e) => { this.Close(); };
        this.Controls.Add(btnClose);
    }

    private static void OpenPrism() {
        string[] paths = new string[] {
            @"C:\MinecraftVPS\PrismLauncher\prismlauncher.exe",
            Path.Combine(AppDomain.CurrentDomain.BaseDirectory, @"PrismLauncher\prismlauncher.exe"),
            Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "prismlauncher.exe")
        };
        foreach (string p in paths) {
            if (File.Exists(p)) {
                try {
                    Process.Start(new ProcessStartInfo {
                        FileName = p,
                        WorkingDirectory = Path.GetDirectoryName(p),
                        UseShellExecute = true
                    });
                    return;
                } catch {}
            }
        }
        MessageBox.Show("Prism Launcher executable not found!", "Notification", MessageBoxButtons.OK, MessageBoxIcon.Warning);
    }

    [STAThread]
    public static void Main() {
        Application.EnableVisualStyles();
        Application.SetCompatibleTextRenderingDefault(false);
        Application.Run(new MicrosoftLoginForm());
    }
}
