# build.ps1 — 编译 dsh-launcher.exe（路径自适应版）
# 需要 Windows 自带的 .NET Framework 4.x（csc.exe）
# 用法：右键用 PowerShell 运行，或在仓库根目录执行  .\scripts\build.ps1
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

$csc = "$env:WINDIR\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
if (-not (Test-Path $csc)) { $csc = "$env:WINDIR\Microsoft.NET\Framework\v4.0.30319\csc.exe" }
if (-not (Test-Path $csc)) { throw '找不到 csc.exe（需要 .NET Framework 4.x）' }

$out = Join-Path $root 'bin'
New-Item -ItemType Directory -Force -Path $out | Out-Null

& $csc /nologo /target:winexe `
  "/win32icon:$root\assets\logo-multi.ico" `
  "/out:$out\dsh-launcher.exe" `
  /reference:System.Windows.Forms.dll `
  "$root\src\launcher.cs"

if ($LASTEXITCODE -ne 0) { throw "编译失败 (exit $LASTEXITCODE)" }
$size = (Get-Item (Join-Path $out 'dsh-launcher.exe')).Length
Write-Host "OK -> $out\dsh-launcher.exe ($size bytes)"