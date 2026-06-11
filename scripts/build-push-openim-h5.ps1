# 打包并推送 openim-h5 镜像
# 用法: .\build-push-openim-h5.ps1 [镜像名，默认 zhangwenkai013/openim-h5:latest]
param(
  [string]$Image = 'zhangwenkai013/openim-h5:latest',
  [switch]$NoPush
)

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$H5Dir = Join-Path $Root 'openim-h5'

Write-Host ">> Building $Image" -ForegroundColor Cyan
Push-Location $H5Dir
try {
  npm run build
  if ($LASTEXITCODE -ne 0) { throw 'npm run build failed' }
  docker build -f Dockerfile.package -t $Image .
  if ($LASTEXITCODE -ne 0) { throw 'docker build failed' }
} finally {
  Pop-Location
}

if (-not $NoPush) {
  Write-Host ">> Pushing $Image" -ForegroundColor Cyan
  docker push $Image
  if ($LASTEXITCODE -ne 0) { throw 'docker push failed' }
}

Write-Host ">> Done: $Image" -ForegroundColor Green
Write-Host "Deploy: docker compose pull openim-h5 && docker compose up -d openim-h5"
