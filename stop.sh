#!/bin/bash
# 停止所有服务

cd "$(dirname "$0")"

if command -v docker-compose &> /dev/null; then
    docker-compose down
elif docker compose version &> /dev/null; then
    docker compose down
else
    echo "错误: 未找到 docker-compose"
    exit 1
fi

echo "所有服务已停止"
