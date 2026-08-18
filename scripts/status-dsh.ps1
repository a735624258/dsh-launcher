# status-dsh.ps1 — 查看 DSH 服务与停止管家状态
# 用法：.\\scripts\\status-dsh.ps1
$svc = Get-NetTCPConnection -State Listen -LocalPort 3080 -ErrorAction SilentlyContinue
$stp = Get-NetTCPConnection -State Listen -LocalPort 3099 -ErrorAction SilentlyContinue
if ($svc) { Write-Host ("DSH 服务  3080: RUNNING (PID " + (($svc.OwningProcess | Select-Object -First 1)) + ")") }
else      { Write-Host 'DSH 服务  3080: STOPPED' }
if ($stp) { Write-Host ("停止管家  3099: RUNNING (PID " + (($stp.OwningProcess | Select-Object -First 1)) + ")") }
else      { Write-Host '停止管家  3099: STOPPED' }