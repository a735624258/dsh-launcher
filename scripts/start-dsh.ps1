# start-dsh.ps1 — 启动 DSH（等价于双击桌面「DeepSeek Harness」快捷方式）
# 用法：.\\scripts\\start-dsh.ps1
$exe = Join-Path $env:LOCALAPPDATA 'Programs\dsh-launcher\dsh-launcher.exe'
if (-not (Test-Path $exe)) { $exe = Join-Path (Split-Path -Parent $PSScriptRoot) 'bin\dsh-launcher.exe' }
if (-not (Test-Path $exe)) { throw '找不到 dsh-launcher.exe，请先运行 scripts\install.ps1' }
Start-Process $exe
Write-Host '已启动 DSH Launcher，浏览器会自动打开 127.0.0.1:3080'