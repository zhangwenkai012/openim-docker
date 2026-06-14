# 打包并推送 openim-chat 镜像
# 优先官方 Dockerfile（Linux/可联网 Docker）；失败则用本地交叉编译 + Dockerfile.package（运行时仍为 mage start）
# 用法: .\build-push-openim-chat.ps1 [镜像名] [-UseOfficialDocker] [-NoPush]
param(
  [string]$Image = 'zhangwenkai013/openim-chat:latest',
  [switch]$UseOfficialDocker,
  [switch]$NoPush
)

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$ChatDir = Join-Path $Root 'chat'
$BinOut = Join-Path $ChatDir '_output\bin\platforms\linux\amd64'
$ToolsOut = Join-Path $ChatDir '_output\bin\tools\linux\amd64'
$MageBin = Join-Path $BinOut 'openim-chat-mage'

function Build-OfficialDocker {
  Write-Host ">> Building $Image (official chat/Dockerfile)" -ForegroundColor Cyan
  Push-Location $ChatDir
  try {
    docker build `
      --build-arg HTTP_PROXY= `
      --build-arg HTTPS_PROXY= `
      --build-arg http_proxy= `
      --build-arg https_proxy= `
      --build-arg GOPROXY=https://goproxy.cn,direct `
      -f Dockerfile `
      -t $Image `
      .
    return ($LASTEXITCODE -eq 0)
  } finally {
    Pop-Location
  }
}

function Build-LocalPackage {
  Write-Host ">> Cross-compiling chat binaries (linux/amd64)" -ForegroundColor Cyan
  $env:GOOS = 'linux'
  $env:GOARCH = 'amd64'
  $env:CGO_ENABLED = '0'
  New-Item -ItemType Directory -Force -Path $BinOut, $ToolsOut | Out-Null

  Push-Location $ChatDir
  try {
    go build -o "$BinOut/chat-api" ./cmd/api/chat-api
    go build -o "$BinOut/chat-rpc" ./cmd/rpc/chat-rpc
    go build -o "$BinOut/admin-api" ./cmd/api/admin-api
    go build -o "$BinOut/admin-rpc" ./cmd/rpc/admin-rpc
    go build -o "$ToolsOut/check-component" ./tools/check-component
    go build -o "$ToolsOut/attribute-to-credential" ./tools/attribute-to-credential

    Write-Host ">> Compiling Linux mage launcher (GOOS=linux go run mage -compile)" -ForegroundColor Cyan
    go run github.com/magefile/mage@v1.15.0 -compile $MageBin
    if (-not (Test-Path $MageBin)) { throw "mage compile failed: $MageBin not found" }

    Write-Host ">> Building $Image (Dockerfile.package, runtime: mage start)" -ForegroundColor Cyan
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
}

$built = $false
if ($UseOfficialDocker) {
  $built = Build-OfficialDocker
  if (-not $built) { throw 'official docker build failed' }
} else {
  $built = Build-OfficialDocker
  if (-not $built) {
    Write-Host ">> Official Docker build unavailable, falling back to local cross-compile" -ForegroundColor Yellow
    Build-LocalPackage
    $built = $true
  }
}

if (-not $built) { throw 'build failed' }

if (-not $NoPush) {
  Write-Host ">> Pushing $Image" -ForegroundColor Cyan
  docker push $Image
  if ($LASTEXITCODE -ne 0) { throw 'docker push failed' }
}

Write-Host ">> Done: $Image" -ForegroundColor Green
Write-Host "Deploy: docker compose pull openim-chat && docker compose up -d openim-chat"
