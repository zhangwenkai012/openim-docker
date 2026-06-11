# 打包并推送 openim-chat 镜像（本地交叉编译 Linux 二进制 + Dockerfile.package）
# 用法: .\build-push-openim-chat.ps1 [镜像名，默认 zhangwenkai013/openim-chat:latest]
param(
  [string]$Image = 'zhangwenkai013/openim-chat:latest',
  [switch]$NoPush
)

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$ChatDir = Join-Path $Root 'chat'
$Out = Join-Path $ChatDir '_output\bin\platforms\linux\amd64'

Write-Host ">> Cross-compiling chat binaries (linux/amd64)" -ForegroundColor Cyan
$env:GOOS = 'linux'
$env:GOARCH = 'amd64'
$env:CGO_ENABLED = '0'
New-Item -ItemType Directory -Force -Path $Out | Out-Null

Push-Location $ChatDir
try {
  go build -o "$Out/chat-api" ./cmd/api/chat-api
  go build -o "$Out/chat-rpc" ./cmd/rpc/chat-rpc
  go build -o "$Out/admin-api" ./cmd/api/admin-api
  go build -o "$Out/admin-rpc" ./cmd/rpc/admin-rpc
  go build -o "$Out/check-component" ./tools/check-component
  go install github.com/magefile/mage@v1.15.0
  & "$env:USERPROFILE\go\bin\mage.exe" -compile "$Out/openim-chat-mage"

  Write-Host ">> Building $Image" -ForegroundColor Cyan
  Copy-Item .dockerignore .dockerignore.bak -Force
  (Get-Content .dockerignore) | Where-Object { $_ -ne '_output/' } | Set-Content .dockerignore
  try {
    docker build -f Dockerfile.package -t $Image .
    if ($LASTEXITCODE -ne 0) { throw 'docker build failed' }
  } finally {
    Move-Item .dockerignore.bak .dockerignore -Force
  }
} finally {
  Pop-Location
}

if (-not $NoPush) {
  Write-Host ">> Pushing $Image" -ForegroundColor Cyan
  docker push $Image
  if ($LASTEXITCODE -ne 0) { throw 'docker push failed' }
}

Write-Host ">> Done: $Image" -ForegroundColor Green
Write-Host "Deploy: docker compose pull openim-chat && docker compose up -d openim-chat"
