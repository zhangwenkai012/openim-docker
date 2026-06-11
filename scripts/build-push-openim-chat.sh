#!/usr/bin/env sh
# 打包并推送 openim-chat 镜像
# 用法: ./build-push-openim-chat.sh [镜像名] [--no-push]
set -eu
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
IMAGE="${1:-zhangwenkai013/openim-chat:latest}"
NO_PUSH="${2:-}"
CHAT_DIR="$ROOT/chat"
OUT="$CHAT_DIR/_output/bin/platforms/linux/amd64"

export GOOS=linux GOARCH=amd64 CGO_ENABLED=0
mkdir -p "$OUT"

echo ">> Cross-compiling chat binaries (linux/amd64)"
cd "$CHAT_DIR"
go build -o "$OUT/chat-api" ./cmd/api/chat-api
go build -o "$OUT/chat-rpc" ./cmd/rpc/chat-rpc
go build -o "$OUT/admin-api" ./cmd/api/admin-api
go build -o "$OUT/admin-rpc" ./cmd/rpc/admin-rpc
go build -o "$OUT/check-component" ./tools/check-component
go install github.com/magefile/mage@v1.15.0
mage -compile "$OUT/openim-chat-mage"

echo ">> Building $IMAGE"
cp .dockerignore .dockerignore.bak
grep -v '^_output/$' .dockerignore.bak > .dockerignore || true
docker build -f Dockerfile.package -t "$IMAGE" .
mv .dockerignore.bak .dockerignore

if [ "$NO_PUSH" != "--no-push" ]; then
  echo ">> Pushing $IMAGE"
  docker push "$IMAGE"
fi

echo ">> Done: $IMAGE"
echo "Deploy: docker compose pull openim-chat && docker compose up -d openim-chat"
