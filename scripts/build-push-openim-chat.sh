#!/usr/bin/env sh
# 打包并推送 openim-chat 镜像（优先官方 Dockerfile，失败则本地交叉编译 + Dockerfile.package）
# 用法: ./build-push-openim-chat.sh [镜像名] [--no-push] [--official-only]
set -eu
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
IMAGE="${1:-zhangwenkai013/openim-chat:latest}"
NO_PUSH="${2:-}"
OFFICIAL_ONLY="${3:-}"
CHAT_DIR="$ROOT/chat"
BIN_OUT="$CHAT_DIR/_output/bin/platforms/linux/amd64"
TOOLS_OUT="$CHAT_DIR/_output/bin/tools/linux/amd64"
MAGE_BIN="$BIN_OUT/openim-chat-mage"

build_official() {
  echo ">> Building $IMAGE (official chat/Dockerfile)"
  cd "$CHAT_DIR"
  docker build \
    --build-arg HTTP_PROXY= \
    --build-arg HTTPS_PROXY= \
    --build-arg http_proxy= \
    --build-arg https_proxy= \
    --build-arg GOPROXY=https://goproxy.cn,direct \
    -f Dockerfile \
    -t "$IMAGE" \
    .
}

build_local_package() {
  echo ">> Cross-compiling chat binaries (linux/amd64)"
  export GOOS=linux GOARCH=amd64 CGO_ENABLED=0
  mkdir -p "$BIN_OUT" "$TOOLS_OUT"
  cd "$CHAT_DIR"
  go build -o "$BIN_OUT/chat-api" ./cmd/api/chat-api
  go build -o "$BIN_OUT/chat-rpc" ./cmd/rpc/chat-rpc
  go build -o "$BIN_OUT/admin-api" ./cmd/api/admin-api
  go build -o "$BIN_OUT/admin-rpc" ./cmd/rpc/admin-rpc
  go build -o "$TOOLS_OUT/check-component" ./tools/check-component
  go build -o "$TOOLS_OUT/attribute-to-credential" ./tools/attribute-to-credential
  echo ">> Compiling Linux mage launcher"
  go run github.com/magefile/mage@v1.15.0 -compile "$MAGE_BIN"
  echo ">> Building $IMAGE (Dockerfile.package)"
  cp .dockerignore .dockerignore.bak
  grep -v '^_output/$' .dockerignore.bak > .dockerignore || true
  docker build -f Dockerfile.package -t "$IMAGE" .
  mv .dockerignore.bak .dockerignore
}

if build_official; then
  :
elif [ "$OFFICIAL_ONLY" = "--official-only" ]; then
  echo "official docker build failed" >&2
  exit 1
else
  echo ">> Official Docker build unavailable, falling back to local cross-compile"
  build_local_package
fi

if [ "$NO_PUSH" != "--no-push" ]; then
  echo ">> Pushing $IMAGE"
  docker push "$IMAGE"
fi

echo ">> Done: $IMAGE"
echo "Deploy: docker compose pull openim-chat && docker compose up -d openim-chat"
