# 依次打包并推送三个镜像（也可单独运行 build-push-openim-*.ps1）
param(
  [switch]$NoPush
)

$ErrorActionPreference = 'Stop'
$ScriptDir = $PSScriptRoot
$pushArg = @{}
if ($NoPush) { $pushArg['NoPush'] = $true }

& (Join-Path $ScriptDir 'build-push-openim-h5.ps1') @pushArg
& (Join-Path $ScriptDir 'build-push-openim-chat.ps1') @pushArg
& (Join-Path $ScriptDir 'build-push-openim-edge.ps1') @pushArg

Write-Host "`n>> All three images done." -ForegroundColor Green
Write-Host "Server:"
Write-Host "  cd openim-docker"
Write-Host "  docker compose pull openim-h5 openim-chat openim-edge"
Write-Host "  docker compose up -d openim-h5 openim-chat openim-edge"
