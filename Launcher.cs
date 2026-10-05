using System;
using System.Diagnostics;
using System.IO;

// GUI-subsystem launcher: no console is created, including at sign-in.
public static class Launcher {
    [STAThread]
    public static void Main() {
        string root = AppDomain.CurrentDomain.BaseDirectory;
        try {
            var start = new ProcessStartInfo {
                FileName = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.System), @"WindowsPowerShell\v1.0\powershell.exe"),
                Arguments = "-NoProfile -NonInteractive -ExecutionPolicy Bypass -File \"" + Path.Combine(root, "Monitor.ps1") + "\"",
                UseShellExecute = false,
                CreateNoWindow = true,
                WindowStyle = ProcessWindowStyle.Hidden
            };
            using (var process = Process.Start(start)) { }
        } catch (Exception e) {
            try { File.AppendAllText(Path.Combine(root, "launcher.log"), DateTime.Now.ToString("s") + " " + e.Message + Environment.NewLine); } catch { }
        }
    }
}
