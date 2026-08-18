# DSH Launcher

一键启动 / 停止 [DeepSeek Harness](https://github.com/a735624258/dsh-launcher) 的小工具包。双击桌面图标启动 DSH 并打开网页，点一下停止按钮就叫停服务——给"另一台电脑"用的就是这套。

## 里面有什么

| 组件 | 说明 |
|---|---|
| `bin/dsh-launcher.exe` | 启动器：静默拉起 DSH 服务（`dsh web`）→ 打开 `http://127.0.0.1:3080`。同时保证"停止管家"在运行 |
| `server/dsh-stop-server.js` | 停止管家：监听 `127.0.0.1:3099`，`GET /shutdown` 找到 3080 端口进程并 `taskkill /f`，然后自我退出 |
| `extension/` | 浏览器插件：在 DSH 页面左下角注入红色「⏻ 停止 DSH」按钮，一点就停 |
| `assets/logo-multi.ico` | 多尺寸鲸鱼图标（exe 内嵌图标 + 快捷方式图标） |
| `src/launcher.cs` | 启动器源码（C#），路径**自适应**，不写死某台机器 |
| `scripts/build.ps1` | 重新编译 launcher.cs → exe（需要 Windows 自带 .NET Framework） |
| `scripts/install.ps1` | 新机器一键部署：装文件、建桌面快捷方式、可选注册开机自启 |
| `scripts/uninstall.ps1` | 卸载 |

## 快速开始（新电脑）

```powershell
# 1. 拿到代码（任选其一）
git clone git@github.com:a735624258/dsh-launcher.git
# 或直接下 ZIP：https://github.com/a735624258/dsh-launcher/archive/refs/heads/main.zip

# 2. 部署（仓库根目录；Windows 默认禁止跑脚本，用 Bypass 绕一下）
powershell -ExecutionPolicy Bypass -File .\scripts\install.ps1
# 想开机自启停止管家：powershell -ExecutionPolicy Bypass -File .\scripts\install.ps1 -AutoStartStopServer

# 3.（可选）浏览器装停止按钮插件
#    Chrome/Edge: chrome://extensions -> 开启"开发者模式" -> "加载已解压的扩展程序" -> 选 extension/ 文件夹
```

装完桌面会出现两个图标：

- **DeepSeek Harness** —— 双击 = 启动 DSH（服务没起就起，起了就直接打开网页）
- **停止DSH** —— 双击 = 停止 DSH 服务

## 原理与端口

```
桌面「DeepSeek Harness」 ──► dsh-launcher.exe
                                 ├─ 检查 3099 停止管家，没跑就静默拉起
                                 ├─ 检查 3080 DSH 服务，没跑就执行 dsh web 等最多 20 秒
                                 └─ 打开浏览器 127.0.0.1:3080

停止按钮（页面红按钮 / 桌面「停止DSH」/ scripts\stop-dsh.ps1）
    ──► GET http://127.0.0.1:3099/shutdown
         └─ 停止管家 netstat 找 3080 的 PID -> taskkill /f -> 自己退出
```

| 端口 | 什么 | 谁监听 |
|---|---|---|
| 3080 | DSH Web 服务 | `dsh web`（node） |
| 3099 | 停止管家 | `dsh-stop-server.js`（node） |

## 路径自适应（换了用户名/安装位置也能用）

启动器不再写死路径，按这个顺序找：

| 要什么 | 环境变量 | 其次 | 兜底（旧机器路径） |
|---|---|---|---|
| `dsh.cmd` | `DSH_CMD` | PATH 里搜 `dsh.cmd` | `C:\Users\yeyu\.workbuddy\binaries\node\versions\22.22.2\dsh.cmd` |
| `node.exe` | `DSH_NODE` | PATH 里搜 `node.exe` | `C:\Users\yeyu\.workbuddy\binaries\node\versions\22.22.2\node.exe` |
| 停止管家脚本 | `DSH_STOP_SERVER` | `~/.dsh/dsh-tools/dsh-stop-server.js` | — |

> `DSH_CMD` 填**完整路径**（如 `C:\Users\xx\.workbuddy\binaries\node\versions\22.22.2\dsh.cmd`），不要带参数。没设时默认用 `dsh.cmd web` 启动。

```powershell
# 例如给另一台机器自定义
[Environment]::SetEnvironmentVariable('DSH_CMD', 'C:\Users\xx\.workbuddy\binaries\node\versions\22.22.2\dsh.cmd', 'User')
```

## 重新编译启动器（改完源码后）

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build.ps1
```

产物在 `bin/dsh-launcher.exe`，自带鲸鱼图标。

## 卸载

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\uninstall.ps1            # 删快捷方式 + 自启项
powershell -ExecutionPolicy Bypass -File .\scripts\uninstall.ps1 -KeepFiles # 保留安装文件
```

浏览器插件在扩展管理页手动移除。

## 故障排查

- **双击没反应 / 浏览器没开**：`scripts/status-dsh.ps1` 看两个端口；`DSH_CMD` 是否指向真实的 dsh.cmd；3080 是否被别的程序占了
- **停止按钮提示失败**：停止管家没在跑，先双击一次「DeepSeek Harness」让它带起来
- **dsh 不在 PATH**：装好 DSH 后把 `...\node\versions\<版本>\` 加进 PATH，或直接设 `DSH_CMD` 环境变量

---

个人自用工具，随意使用。