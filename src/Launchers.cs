using System;
using System.Diagnostics;
using System.IO;

public class DonRAMLauncher {
    [STAThread]
    public static void Main() {
        string[] paths = new string[] {
            @"C:\MinecraftVPS\MemReduct\memreduct.exe",
            Path.Combine(AppDomain.CurrentDomain.BaseDirectory, @"MemReduct\memreduct.exe"),
            Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "memreduct.exe")
        };
        foreach (string p in paths) {
            if (File.Exists(p)) {
                try {
                    Process.Start(new ProcessStartInfo {
                        FileName = p,
                        Arguments = "-minimized",
                        WorkingDirectory = Path.GetDirectoryName(p),
                        UseShellExecute = true
                    });
                    return;
                } catch {}
            }
        }
    }
}

public class MoPrismLauncher {
    [STAThread]
    public static void Main() {
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
    }
}
