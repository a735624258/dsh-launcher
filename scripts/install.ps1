# install.ps1 — 新机器一键部署
#
# 做什么：
#   1) 拷贝 dsh-launcher.exe + 图标 到 %LOCALAPPDATA%\Programs\dsh-launcher
#   2) 拷贝停止管家到 ~/.dsh/dsh-tools（这是启动器默认探测的位置）
#   3) 桌面创建「DeepSeek Harness」启动快捷方式（带鲸鱼图标）
#   4) 桌面创建「停止DSH」快捷方式（相当于停止按钮，需要停止管家在运行）
#   5) 可选：-AutoStartStopServer 让停止管家开机自启（默认不注册）
#
# 用法：.\\scripts\\install.ps1            （在仓库根目录）
#       .\\scripts\\install.ps1 -AutoStartStopServer
param([switch]$AutoStartStopServer)
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$exeSrc = Join-Path $root 'bin\dsh-launcher.exe'
if (-not (Test-Path $exeSrc)) { throw 'bin\dsh-launcher.exe 不存在，请先运行 scripts\build.ps1' }

# 1) 启动器本体
$installDir = Join-Path $env:LOCALAPPDATA 'Programs\dsh-launcher'
New-Item -ItemType Directory -Force -Path $installDir | Out-Null
Copy-Item $exeSrc $installDir -Force
Copy-Item (Join-Path $root 'assets\logo-multi.ico') $installDir -Force

# 2) 停止管家 -> ~/.dsh/dsh-tools（启动器默认查找路径）
$dshTools = Join-Path $env:USERPROFILE '.dsh\dsh-tools'
New-Item -ItemType Directory -Force -Path $dshTools | Out-Null
Copy-Item (Join-Path $root 'server\dsh-stop-server.js') (Join-Path $dshTools 'dsh-stop-server.js') -Force

# 3) 4) 桌面快捷方式
$desktop = [Environment]::GetFolderPath('Desktop')
$ws = New-Object -ComObject WScript.Shell

$lnk1 = $ws.CreateShortcut((Join-Path $desktop 'DeepSeek Harness.lnk'))
$lnk1.TargetPath = Join-Path $installDir 'dsh-launcher.exe'
$lnk1.WorkingDirectory = $installDir
$lnk1.IconLocation = "$installDir\logo-multi.ico,0"
$lnk1.Save()

$lnk2 = $ws.CreateShortcut((Join-Path $desktop '停止DSH.lnk'))
$lnk2.TargetPath = "$env:WINDIR\System32\WindowsPowerShell\v1.0\powershell.exe"
$lnk2.Arguments = '-NoProfile -WindowStyle Hidden -Command ''try { (Invoke-WebRequest http://127.0.0.1:3099/shutdown -UseBasicParsing).Content } catch { Write-Host ("停止失败: " + $_.Exception.Message) }'''
$lnk2.IconLocation = "$installDir\logo-multi.ico,0"
$lnk2.Description = '停止 DeepSeek Harness 服务（需要停止管家 3099 在运行）'
$lnk2.Save()

# 5) 可选开机自启停止管家
if ($AutoStartStopServer) {
  $run = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
  $nodeExe = (Get-Command node.exe -ErrorAction SilentlyContinue).Source
  if (-not $nodeExe) { $nodeExe = "$env:USERPROFILE\.workbuddy\binaries\node\versions\22.22.2\node.exe" }
  Set-ItemProperty -Path $run -Name 'DSHStopServer' -Value ('"{0}" "{1}"' -f $nodeExe, (Join-Path $dshTools 'dsh-stop-server.js'))
  Write-Host '已注册开机自启 DSHStopServer'
}

Write-Host ''
Write-Host '安装完成 ✅'
Write-Host "  启动器    : $installDir\dsh-launcher.exe"
Write-Host "  停止管家  : $dshTools\dsh-stop-server.js"
Write-Host "  桌面快捷  : DeepSeek Harness.lnk / 停止DSH.lnk"
Write-Host ''

# 6) 浏览器停止按钮插件的辅助安装（插件只能在浏览器里手动加载，脚本帮到你打开页面+复制路径）
$extPath = Join-Path $root 'extension'
if (Test-Path $extPath) {
  try { Set-Clipboard $extPath; Write-Host "扩展路径已复制到剪贴板: $extPath" } catch { }
  $hasEdge = Get-Process msedge -ErrorAction SilentlyContinue | Select-Object -First 1
  $hasChrome = Get-Process chrome -ErrorAction SilentlyContinue | Select-Object -First 1
  if ($hasEdge) { Start-Process 'msedge://extensions' | Out-Null; Write-Host '已打开 Edge 扩展管理页（msedge://extensions）' }
  elseif ($hasChrome) { Start-Process 'chrome://extensions' | Out-Null; Write-Host '已打开 Chrome 扩展管理页（chrome://extensions）' }
  Write-Host ''
  Write-Host '浏览器手动操作（约 30 秒，浏览器安全限制无法脚本代劳）：'
  Write-Host '  1) 打开页面右上角「开发者模式」开关'
  Write-Host '  2) 点「加载已解压的扩展程序」'
  Write-Host "  3) 选文件夹: $extPath  （已在剪贴板，直接 Ctrl+V）"
  Write-Host '装好后打开 DSH 页面(127.0.0.1:3080)，左下角会出现红色「⏻ 停止 DSH」按钮。'
}