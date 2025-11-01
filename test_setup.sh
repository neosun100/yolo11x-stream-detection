#!/bin/bash
# 项目设置验证脚本

echo "============================================"
echo "YOLO11x Stream Detection - 设置验证"
echo "============================================"
echo ""

ERRORS=0

# 检查必要文件
echo "1. 检查必要文件..."
FILES=("docker-compose.yml" "start.sh" "config/rtmp-entrypoint.sh" ".env.example")
for file in "${FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "  ✅ $file"
    else
        echo "  ❌ $file 缺失"
        ERRORS=$((ERRORS+1))
    fi
done

# 检查检测脚本
echo ""
echo "2. 检查检测脚本..."
SCRIPT_COUNT=$(find scripts -name "yolo_*_detector.py" | wc -l)
if [ "$SCRIPT_COUNT" -eq 11 ]; then
    echo "  ✅ 检测脚本完整 ($SCRIPT_COUNT 个)"
else
    echo "  ⚠️  检测脚本可能不完整 ($SCRIPT_COUNT/11)"
fi

# 检查 Docker Compose 语法
echo ""
echo "3. 检查 Docker Compose 配置..."
if docker-compose config > /dev/null 2>&1 || docker compose config > /dev/null 2>&1; then
    echo "  ✅ docker-compose.yml 语法正确"
else
    echo "  ❌ docker-compose.yml 语法错误"
    ERRORS=$((ERRORS+1))
fi

# 检查敏感信息
echo ""
echo "4. 检查敏感信息..."
SENSITIVE=$(grep -r "107\.172\|44\.193\|stream\.aws\|hls\.aws\|FdswWE5m\|3d8e70935" . 2>/dev/null | grep -v ".git" | wc -l)
if [ "$SENSITIVE" -eq 0 ]; then
    echo "  ✅ 未发现敏感信息"
else
    echo "  ⚠️  发现 $SENSITIVE 处可能的敏感信息"
fi

echo ""
echo "============================================"
if [ "$ERRORS" -eq 0 ]; then
    echo "✅ 验证通过！项目可以准备推送。"
else
    echo "⚠️  发现 $ERRORS 个问题，请检查。"
fi
echo "============================================"
