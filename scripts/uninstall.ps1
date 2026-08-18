# uninstall.ps1 — 卸载：删除桌面快捷方式、可选删除安装文件、删除开机自启项
# 用法：.\\scripts\\uninstall.ps1            只删快捷方式和自启项
#       .\\scripts\\uninstall.ps1 -KeepFiles 保留安装文件
param([switch]$KeepFiles)
$ErrorActionPreference = 'Continue'

$desktop = [Environment]::GetFolderPath('Desktop')
foreach ($n in @('DeepSeek Harness.lnk', '停止DSH.lnk')) {
  $p = Join-Path $desktop $n
  if (Test-Path $p) { Remove-Item $p -Force; Write-Host "已删除 $p" }
}

Remove-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name 'DSHStopServer' -ErrorAction SilentlyContinue
Write-Host '已移除开机自启项 DSHStopServer'

if (-not $KeepFiles) {
  $installDir = Join-Path $env:LOCALAPPDATA 'Programs\dsh-launcher'
  if (Test-Path $installDir) {
    Remove-Item $installDir -Recurse -Force
    Write-Host "已删除 $installDir"
  }
}
Write-Host '卸载完成。浏览器插件请在浏览器扩展管理页手动移除。'