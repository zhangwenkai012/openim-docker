#!/usr/bin/env sh
# 打包并推送 openim-edge 镜像
# 用法: ./build-push-openim-edge.sh [镜像名] [--no-push]
set -eu
EDGE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
IMAGE="${1:-zhangwenkai013/openim-edge:latest}"
NO_PUSH="${2:-}"

echo ">> Building $IMAGE"
docker build -f "$EDGE_DIR/Dockerfile.edge" -t "$IMAGE" "$EDGE_DIR"

if [ "$NO_PUSH" != "--no-push" ]; then
  echo ">> Pushing $IMAGE"
  docker push "$IMAGE"
fi

echo ">> Done: $IMAGE"
echo "Deploy: docker compose pull openim-edge && docker compose up -d openim-edge"
