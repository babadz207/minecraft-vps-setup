using System;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Windows.Forms;

public class DangNhapMicrosoftForm : Form {
    public DangNhapMicrosoftForm() {
        this.Text = "Huong Dan Dang Nhap Microsoft - Prism Launcher";
        this.Size = new Size(600, 520);
        this.StartPosition = FormStartPosition.CenterScreen;
        this.FormBorderStyle = FormBorderStyle.FixedDialog;
        this.MaximizeBox = false;
        this.BackColor = Color.FromArgb(15, 23, 42); // Slate Dark

        // Header
        Label title = new Label();
        title.Text = "HƯỚNG DẪN ĐĂNG NHẬP MICROSOFT";
        title.Font = new Font("Segoe UI", 14, FontStyle.Bold);
        title.ForeColor = Color.FromArgb(56, 189, 248); // Sky Blue
        title.Location = new Point(20, 15);
        title.Size = new Size(545, 30);
        title.TextAlign = ContentAlignment.MiddleCenter;
        this.Controls.Add(title);

        Label sub = new Label();
        sub.Text = "Server donutsmp.net yeu cau tai khoan ban quyen (Chi can lam 1 lan duy nhat)";
        sub.Font = new Font("Segoe UI", 9);
        sub.ForeColor = Color.FromArgb(148, 163, 184);
        sub.Location = new Point(20, 48);
        sub.Size = new Size(545, 20);
        sub.TextAlign = ContentAlignment.MiddleCenter;
        this.Controls.Add(sub);

        // Steps Panel
        Panel panel = new Panel();
        panel.Location = new Point(25, 80);
        panel.Size = new Size(535, 290);
        panel.BackColor = Color.FromArgb(30, 41, 59); // Card Dark
        panel.BorderStyle = BorderStyle.FixedSingle;
        this.Controls.Add(panel);

        string[] steps = new string[] {
            "BƯỚC 1: Bấm nút [Mở Prism Launcher] bên dưới để mở giao diện game.",
            "BƯỚC 2: Nhìn góc trên bên phải của Prism Launcher, bấm vào [Accounts] -> [Manage Accounts].",
            "BƯỚC 3: Bấm nút [Add Microsoft] ở thanh công cụ bên phải.",
            "BƯỚC 4: Bấm nút [Open Page and Copy Code] trên hộp thoại của Prism Launcher.\n             -> Mã code sẽ tự động được copy vào bộ nhớ tạm!",
            "BƯỚC 5: Trình duyệt web sẽ mở trang microsoft.com/link (hoặc bấm nút bên dưới).\n             -> Nhấn [Ctrl + V] để dán mã code và đăng nhập tài khoản Microsoft của bạn.",
            "BƯỚC 6: Xong! Nick của bạn xuất hiện trong Accounts. Bây giờ có thể mở Watchdog để AFK!"
        };

        int top = 12;
        foreach (string st in steps) {
            Label lbl = new Label();
            lbl.Text = st;
            lbl.Font = new Font("Segoe UI", 9.5f, st.StartsWith("BƯỚC 4") || st.StartsWith("BƯỚC 5") ? FontStyle.Regular : FontStyle.Regular);
            lbl.ForeColor = st.StartsWith("BƯỚC 6") ? Color.FromArgb(74, 222, 128) : Color.FromArgb(241, 245, 249);
            lbl.Location = new Point(14, top);
            lbl.Size = new Size(505, st.Contains("\n") ? 42 : 32);
            panel.Controls.Add(lbl);
            top += st.Contains("\n") ? 46 : 36;
        }

        // Action Buttons
        Button btnOpenPrism = new Button();
        btnOpenPrism.Text = "🚀 MỞ PRISM LAUNCHER";
        btnOpenPrism.Font = new Font("Segoe UI", 10, FontStyle.Bold);
        btnOpenPrism.BackColor = Color.FromArgb(34, 197, 94); // Emerald Green
        btnOpenPrism.ForeColor = Color.White;
        btnOpenPrism.FlatStyle = FlatStyle.Flat;
        btnOpenPrism.FlatAppearance.BorderSize = 0;
        btnOpenPrism.Location = new Point(25, 385);
        btnOpenPrism.Size = new Size(255, 42);
        btnOpenPrism.Cursor = Cursors.Hand;
        btnOpenPrism.Click += (s, e) => {
            OpenPrism();
        };
        this.Controls.Add(btnOpenPrism);

        Button btnOpenLink = new Button();
        btnOpenLink.Text = "🌐 MỞ MICROSOFT.COM/LINK";
        btnOpenLink.Font = new Font("Segoe UI", 10, FontStyle.Bold);
        btnOpenLink.BackColor = Color.FromArgb(59, 130, 246); // Blue
        btnOpenLink.ForeColor = Color.White;
        btnOpenLink.FlatStyle = FlatStyle.Flat;
        btnOpenLink.FlatAppearance.BorderSize = 0;
        btnOpenLink.Location = new Point(305, 385);
        btnOpenLink.Size = new Size(255, 42);
        btnOpenLink.Cursor = Cursors.Hand;
        btnOpenLink.Click += (s, e) => {
            try { Process.Start("https://microsoft.com/link"); } catch {}
        };
        this.Controls.Add(btnOpenLink);

        Button btnClose = new Button();
        btnClose.Text = "Đóng";
        btnClose.Font = new Font("Segoe UI", 9.5f);
        btnClose.BackColor = Color.FromArgb(51, 65, 85);
        btnClose.ForeColor = Color.White;
        btnClose.FlatStyle = FlatStyle.Flat;
        btnClose.FlatAppearance.BorderSize = 0;
        btnClose.Location = new Point(230, 437);
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
        MessageBox.Show("Khong tim thay Prism Launcher!", "Thong bao", MessageBoxButtons.OK, MessageBoxIcon.Warning);
    }

    [STAThread]
    public static void Main() {
        Application.EnableVisualStyles();
        Application.SetCompatibleTextRenderingDefault(false);
        Application.Run(new DangNhapMicrosoftForm());
    }
}
