# 打包并推送 openim-edge 镜像（nginx 网关 + download 静态页）
# 用法: .\build-push-openim-edge.ps1 [镜像名，默认 zhangwenkai013/openim-edge:latest]
param(
  [string]$Image = 'zhangwenkai013/openim-edge:latest',
  [switch]$NoPush
)

$ErrorActionPreference = 'Stop'
$EdgeDir = Split-Path -Parent $PSScriptRoot

Write-Host ">> Building $Image" -ForegroundColor Cyan
docker build -f (Join-Path $EdgeDir 'Dockerfile.edge') -t $Image $EdgeDir
if ($LASTEXITCODE -ne 0) { throw 'docker build failed' }

if (-not $NoPush) {
  Write-Host ">> Pushing $Image" -ForegroundColor Cyan
  docker push $Image
  if ($LASTEXITCODE -ne 0) { throw 'docker push failed' }
}

Write-Host ">> Done: $Image" -ForegroundColor Green
Write-Host "Deploy: docker compose pull openim-edge && docker compose up -d openim-edge"
