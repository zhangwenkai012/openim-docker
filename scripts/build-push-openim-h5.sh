#!/usr/bin/env sh
# 打包并推送 openim-h5 镜像
# 用法: ./build-push-openim-h5.sh [镜像名] [--no-push]
set -eu
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
IMAGE="${1:-zhangwenkai013/openim-h5:latest}"
NO_PUSH="${2:-}"

echo ">> Building $IMAGE"
cd "$ROOT/openim-h5"
npm run build
docker build -f Dockerfile.package -t "$IMAGE" .

if [ "$NO_PUSH" != "--no-push" ]; then
  echo ">> Pushing $IMAGE"
  docker push "$IMAGE"
fi

echo ">> Done: $IMAGE"
echo "Deploy: docker compose pull openim-h5 && docker compose up -d openim-h5"
