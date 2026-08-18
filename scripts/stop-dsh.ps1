# stop-dsh.ps1 — 停止 DSH 服务（需要停止管家在 127.0.0.1:3099 运行）
# 等价于桌面「停止DSH」快捷方式 / 页面上的停止按钮
# 用法：.\\scripts\\stop-dsh.ps1
try {
  $r = Invoke-WebRequest 'http://127.0.0.1:3099/shutdown' -UseBasicParsing -TimeoutSec 5
  Write-Host $r.Content
} catch {
  Write-Host ('停止失败: ' + $_.Exception.Message)
  Write-Host '（先运行启动器一次，让它把停止管家带起来）'
}