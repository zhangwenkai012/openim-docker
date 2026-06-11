#!/usr/bin/env sh
# 部署/更新 download.dsvxt.cn 静态下载页（openim-edge 边车 nginx）
set -eu
cd "$(dirname "$0")/.."

echo ">> 重建 openim-edge（挂载 config/nginx/download）"
docker compose up -d openim-edge

echo ">> 校验 nginx 配置"
docker compose exec -T openim-edge nginx -t

echo ">> 热加载 nginx"
docker compose exec -T openim-edge nginx -s reload

echo ">> 完成。请在宝塔为 download.dsvxt.cn 绑定站点并反代到 127.0.0.1:18080（发送域名 \$host）"
