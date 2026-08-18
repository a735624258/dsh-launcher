using System;
using System.IO;
using System.Diagnostics;
using System.Threading;
using System.Net.Sockets;

// DSH Launcher — 一键启动 DeepSeek Harness（自省路径版）
//
// 行为：
//   1) 确保"停止管家"在跑（127.0.0.1:3099），供页面上的停止按钮/浏览器插件调用
//   2) 确保 DSH 服务在跑（127.0.0.1:3080），没跑就静默执行 dsh web，最多等 20 秒
//   3) 就绪就打开浏览器进 127.0.0.1:3080，失败弹窗提示
//
// 路径自适应（不写死某台机器）：
//   DSH_CMD   -> dsh.cmd 完整路径（不是命令行参数）。优先环境变量，其次 PATH，最后回退默认路径
//   DSH_NODE  -> node.exe 完整路径。优先环境变量，其次 PATH，最后回退默认路径
//   DSH_STOP_SERVER -> 停止管家脚本路径。优先环境变量，其次 ~/.dsh/dsh-tools/dsh-stop-server.js
//   工作目录  -> 当前用户主目录
//
// 编译：见 scripts/build.ps1（csc + logo-multi.ico 作 win32 图标）

class DshLauncher
{
    static string ResolveExe(string envVar, string exeName, string fallback)
    {
        string fromEnv = Environment.GetEnvironmentVariable(envVar);
        if (!string.IsNullOrEmpty(fromEnv)) return fromEnv; // 用户显式指定，照用
        string path = Environment.GetEnvironmentVariable("Path") ?? "";
        foreach (string dir in path.Split(';'))
        {
            if (string.IsNullOrEmpty(dir)) continue;
            string candidate = Path.Combine(dir.Trim(), exeName);
            if (File.Exists(candidate)) return candidate;
        }
        return fallback;
    }

    static string FindStopServer()
    {
        string fromEnv = Environment.GetEnvironmentVariable("DSH_STOP_SERVER");
        if (!string.IsNullOrEmpty(fromEnv)) return fromEnv;
        string home = Environment.GetFolderPath(Environment.SpecialFolder.UserProfile);
        return Path.Combine(home, ".dsh", "dsh-tools", "dsh-stop-server.js");
    }

    [STAThread]
    static void Main()
    {
        try
        {
            string node = ResolveExe("DSH_NODE", "node.exe",
                @"C:\Users\yeyu\.workbuddy\binaries\node\versions\22.22.2\node.exe");
            string dshCmd = ResolveExe("DSH_CMD", "dsh.cmd",
                @"C:\Users\yeyu\.workbuddy\binaries\node\versions\22.22.2\dsh.cmd");
            string stopServer = FindStopServer();
            string workDir = Environment.GetFolderPath(Environment.SpecialFolder.UserProfile);

            // 1) 确保停止管家在跑（3099），供页面按钮/浏览器插件调用
            if (!IsPortOpen(3099) && File.Exists(stopServer))
            {
                StartHidden(node, "\"" + stopServer + "\"", workDir);
            }

            // 2) 确保 DSH 服务在跑（3080）
            bool ready = IsPortOpen(3080);
            if (!ready)
            {
                StartHidden("cmd.exe", "/c " + dshCmd + " web", workDir);
                for (int i = 0; i < 20; i++)
                {
                    Thread.Sleep(1000);
                    if (IsPortOpen(3080)) { ready = true; break; }
                }
            }

            // 3) 打开 Web 界面
            if (ready)
            {
                Process.Start("http://127.0.0.1:3080");
            }
            else
            {
                System.Windows.Forms.MessageBox.Show(
                    "服务未能启动。请检查：\n" +
                    "· DSH_CMD 是否指向 dsh.cmd（或 dsh.cmd 是否在 PATH 中）\n" +
                    "· 端口 3080 是否被其他程序占用",
                    "DeepSeek Harness",
                    System.Windows.Forms.MessageBoxButtons.OK,
                    System.Windows.Forms.MessageBoxIcon.Warning);
            }
        }
        catch (Exception ex)
        {
            System.Windows.Forms.MessageBox.Show("启动失败: " + ex.Message, "DeepSeek Harness");
        }
    }

    static void StartHidden(string file, string args, string workDir)
    {
        ProcessStartInfo psi = new ProcessStartInfo(file, args)
        {
            UseShellExecute = false,
            CreateNoWindow = true,
            WindowStyle = ProcessWindowStyle.Hidden,
            WorkingDirectory = workDir
        };
        Process.Start(psi);
    }

    static bool IsPortOpen(int port)
    {
        try
        {
            TcpClient c = new TcpClient();
            var ar = c.BeginConnect("127.0.0.1", port, null, null);
            bool ok = ar.AsyncWaitHandle.WaitOne(500);
            if (ok) { c.EndConnect(ar); c.Close(); return true; }
            c.Close();
        }
        catch { }
        return false;
    }
}