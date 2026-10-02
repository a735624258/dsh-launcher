# DSH Launcher

> 给 Windows 上的 DeepSeek Harness 补上「一键启动、一键停止」：双击图标起服务并打开网页，点一下按钮把服务停掉。
> One-click start and stop for [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness) on Windows.

| 项 | 值 |
|---|---|
| 当前版本 | 跟随 `main`（仓库暂未打 tag；浏览器插件 manifest 为 1.0.0） |
| 许可 | 未声明 LICENSE（个人自用，随意使用） |
| 平台 | Windows 10 / 11 |
| 支持范围 | 本机回环地址上的 DSH Web 服务（`127.0.0.1:3080`）与停止管家（`127.0.0.1:3099`） |

## 1、为什么要做

- DSH 的 Web 服务要开终端、敲 `dsh web`、等端口就绪，换一台电脑还得把这套命令重新记一遍。
- 服务起来之后没有「停」这个动作，只能去任务管理器里翻 node 进程，或者干脆让它一直挂着。
- `dsh.cmd` 和 `node.exe` 的位置因机器而异，写死路径的脚本换台机器就废。
- 启动和停止本来是一下点击的事，却要把人拉回命令行。

## 2、它做什么

- **起服务**：双击桌面图标，3080 没监听就静默执行 `dsh web`，每秒探一次端口、最多等 20 秒，就绪后打开默认浏览器进 `http://127.0.0.1:3080`。
- **停服务**：桌面「停止DSH」、页面红色按钮、`stop-dsh.ps1` 三个入口都走本机 3099 的停止管家，由它强杀占用 3080 的进程。
- **路径自适应**：`dsh.cmd` / `node.exe` 按「环境变量 → PATH → 兜底路径」三级回退查找，不写死某一台机器。
- **一键部署**：`install.ps1` 装文件、建两个桌面快捷方式，可选把停止管家注册进开机自启。
- **查状态**：`status-dsh.ps1` 一眼看出 3080 / 3099 在不在跑、PID 是多少。

## 3、怎么用

1. 双击桌面「DeepSeek Harness」—— 服务没起就静默拉起，20 秒内浏览器自动打开 `http://127.0.0.1:3080`。
2. 用完要停：双击桌面「停止DSH」，或在 DSH 页面点左下角红色「⏻ 停止 DSH」（装了浏览器插件才有）。
3. 想确认状态：`powershell -ExecutionPolicy Bypass -File .\scripts\status-dsh.ps1`。

例子 —— 换到一台 `dsh.cmd` 不在 PATH 上的机器，用环境变量指路：

```powershell
[Environment]::SetEnvironmentVariable('DSH_CMD',  'C:\repos\demo\node\dsh.cmd',  'User')
[Environment]::SetEnvironmentVariable('DSH_NODE', 'C:\repos\demo\node\node.exe', 'User')
# 变量填完整路径、不带参数；设完重新双击图标，仍不生效就注销重登一次
```

| 入口 | 动作 |
|---|---|
| 桌面「DeepSeek Harness」 | 起服务并打开网页 |
| 桌面「停止DSH」 | 停服务（需要 3099 在跑） |
| 页面左下角「⏻ 停止 DSH」 | 停服务，并自动关掉当前标签页 |
| `scripts\start-dsh.ps1` | 等同桌面启动图标 |
| `scripts\stop-dsh.ps1` | 等同桌面停止图标 |
| `scripts\status-dsh.ps1` | 查看 3080 / 3099 状态 |

## 4、安装

### 4.1 三种装法

1. 最新版（仓库暂未发 Release，`main` 即最新）：`git clone https://github.com/a735624258/dsh-launcher.git`
2. 不装 git：下载 [main.zip](https://github.com/a735624258/dsh-launcher/archive/refs/heads/main.zip) 解压。
3. 自己改代码：改 `src/launcher.cs` 后跑 `scripts\build.ps1` 重新编译（需要 .NET Framework 4.x 自带的 `csc.exe`）。

拿到代码后在仓库根目录部署（Windows 默认禁止跑脚本，用 `Bypass` 绕一下）：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\install.ps1
# 想开机自启停止管家，加一个开关：
powershell -ExecutionPolicy Bypass -File .\scripts\install.ps1 -AutoStartStopServer
```

装完得到：`%LOCALAPPDATA%\Programs\dsh-launcher`（exe + 图标）、`%USERPROFILE%\.dsh\dsh-tools\dsh-stop-server.js`、桌面两个快捷方式。浏览器插件只能手动加载：扩展管理页开「开发者模式」→「加载已解压的扩展程序」→ 选 `extension\` 文件夹（`install.ps1` 会把路径放进剪贴板并帮你打开扩展页）。

### 4.2 装完要不要重启

- 启动器和停止管家都不需要重启系统，装完直接双击桌面图标就能用。
- 只有改过 `DSH_CMD` / `DSH_NODE` 这类用户环境变量时，才需要重开一次启动器让新进程读到，必要时注销重登。
- 浏览器插件装好后刷新一次 `127.0.0.1:3080` 页面，按钮才会出现。

### 4.3 卸载与网络

- `.\scripts\uninstall.ps1` 删掉两个桌面快捷方式和开机自启项，并删除安装目录。
- 只想留文件：`.\scripts\uninstall.ps1 -KeepFiles`。
- 浏览器插件在扩展管理页手动移除，脚本删不掉。
- 全程不需要外网：只在本机回环地址上通信（启动器探 3080、停止入口调 3099），拉代码时才需要网络。

### 4.4 兼容与已知坑

| 项 | 要求 |
|---|---|
| 系统 | Windows 10 / 11 |
| 跑停止管家 | Node.js（`node.exe`） |
| 编译启动器 | .NET Framework 4.x（系统自带 `csc.exe`） |
| DSH 侧 | 提供 `dsh web` 命令的版本（未逐版本验证） |
| 浏览器插件 | Chrome / Edge（Manifest V3） |

- 3080 被别的程序占用：启动器等满 20 秒后会弹「服务未能启动」，先跑 `status-dsh.ps1` 看是谁占了。
- 停止是 `taskkill /f` 强杀，不做优雅退出；有正在跑的任务先等它跑完。
- 页面按钮只注入 `127.0.0.1:3080` 这个地址，DSH 换了端口就不出现。
- 停止管家没在跑时，停止入口会报失败 —— 先双击一次启动器把它带起来。
- 停止管家只绑 `127.0.0.1:3099` 且**没有鉴权**：本机任何页面都能调它停服务，别把它改成对外的监听地址。

## 5、它是怎么做到的

```
桌面「DeepSeek Harness」→ dsh-launcher.exe
    ├─ 3099 没监听 → 隐藏窗口起 node dsh-stop-server.js
    ├─ 3080 没监听 → 隐藏执行 dsh.cmd web，每秒探一次，最多 20 秒
    └─ 就绪 → 打开默认浏览器 127.0.0.1:3080；超时则弹窗给出排查提示

停止入口（桌面「停止DSH」/ 页面按钮 / stop-dsh.ps1）
    → GET 127.0.0.1:3099/shutdown
        └─ netstat 找出 :3080 的 LISTENING PID → taskkill /f → 管家自己退出
```

- **用端口探活当「就绪」信号**：不解析 `dsh web` 的输出，只做 TCP 连接探测，20 秒内没通就报错，避免卡在"命令返回了但服务还没起来"。
- **路径三级回退**：环境变量 → PATH → 兜底路径，换机器只需设 `DSH_CMD` / `DSH_NODE` 两个变量。
- **停止做成一个本机 HTTP 端点**：桌面快捷方式、页面按钮、命令行三条路复用同一套逻辑，不必给启动器再加一个界面。
- **安全前提是「只在本机」**：管家只监听 `127.0.0.1:3099`，只认 `/ping` 与 `/shutdown` 两个路由；无鉴权、CORS 放开，所以不能把它暴露到回环地址之外。
- **全程无窗口**：启动用 `CreateNoWindow`，停止快捷方式用 `-WindowStyle Hidden`，不会闪黑框。

## 6、开发

- **依赖**：Windows + .NET Framework 4.x（编译启动器）、Node.js（跑停止管家）；无第三方包，没有 npm 安装步骤。
- **构建**：`powershell -ExecutionPolicy Bypass -File .\scripts\build.ps1` → 产物 `bin\dsh-launcher.exe`（带鲸鱼图标）。
- **测试**：仓库暂无自动化测试；改动后按第 4 节装一遍并实跑（起服务 → 开页面 → 停服务）验证。

```
dsh-launcher/
├─ bin/dsh-launcher.exe         编译产物
├─ src/launcher.cs              启动器源码（C#，路径自适应）
├─ server/dsh-stop-server.js    停止管家（Node，127.0.0.1:3099）
├─ extension/                   浏览器停止按钮（Manifest V3）
├─ scripts/                     build / install / uninstall / start / stop / status
└─ assets/                      图标（ico / png / svg）
```

## 更新日志

- **2026-08-18** 安装脚本：装完自动打开扩展管理页、把扩展路径放进剪贴板、打印手动加载步骤。
- **2026-08-18** 首个版本：自适应路径启动器 + 停止管家 + 浏览器停止按钮 + 鲸鱼图标 + 安装/卸载脚本。

更早与全部记录见 [CHANGELOG.md](CHANGELOG.md)。

---

个人自用工具，随意使用；仓库内暂无 LICENSE 文件。
