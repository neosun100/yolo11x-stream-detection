# 故障排查指南

## 常见问题

### 1. 推流失败

**症状**: FFmpeg 推流时显示 "Input/output error" 或 "Connection refused"

**检查步骤**:

```bash
# 检查 RTMP 服务器是否运行
docker ps | grep rtmp

# 检查 RTMP 端口是否监听
netstat -tlnp | grep 1935
# 或
ss -tlnp | grep 1935

# 检查 RTMP 服务器日志
docker logs --tail 50 rtmp

# 测试 RTMP 端口连通性
telnet localhost 1935
```

**解决方法**:
- 确认 RTMP 容器正在运行
- 检查防火墙是否阻止了 1935 端口
- 确认推流地址正确（格式：`rtmp://server:1935/live/stream_name`）

### 2. HLS 播放 404

**症状**: 访问 HLS URL 返回 404 Not Found

**检查步骤**:

```bash
# 检查 HLS 文件是否存在
docker exec rtmp ls -lh /opt/data/hls/cam/

# 检查推流是否正在进行
curl http://localhost:8080/stat | grep publishing

# 检查 nginx HTTP 配置
docker exec rtmp cat /etc/nginx/nginx.conf | grep "location /live"
```

**解决方法**:
- 确认推流正在进行
- 等待几秒钟让 HLS 文件生成
- 检查流名称是否正确（默认是 `cam`）
- 确认使用正确的 URL 格式：`/live/{stream_name}/index.m3u8`

### 3. 检测容器无法连接 RTMP

**症状**: 检测容器日志显示 "Connection refused" 或 "Stream timeout"

**检查步骤**:

```bash
# 检查检测容器日志
docker logs --tail 30 yolo-detect

# 检查 RTMP 服务器是否运行
docker ps | grep rtmp

# 检查 RTMP 统计信息
curl http://localhost:8080/stat | grep "publishing"

# 检查流名称配置
docker exec yolo-detect printenv STREAM_NAME
```

**解决方法**:
- 确认推流正在进行（RTMP 统计中应该显示 publishing）
- 确认 `STREAM_NAME` 环境变量与推流名称匹配
- 重启检测容器：`docker-compose restart yolo-detect`

### 4. GPU 未使用

**症状**: `nvidia-smi` 显示 GPU 使用率为 0%

**检查步骤**:

```bash
# 检查 NVIDIA 运行时
docker info | grep -i nvidia

# 检查容器 GPU 访问
docker exec yolo-detect nvidia-smi

# 检查环境变量
docker exec yolo-detect printenv NVIDIA_VISIBLE_DEVICES
```

**解决方法**:
- 确认安装了 NVIDIA Container Toolkit
- 确认 `docker-compose.yml` 中配置了 GPU
- 重启容器：`docker-compose restart`

### 5. 检测速度慢

**症状**: 检测 FPS 很低，视频卡顿

**可能原因**:
- GPU 未正确使用
- 模型太大（可以尝试使用更小的模型，如 yolo11n）
- CPU 资源不足

**解决方法**:
- 检查 GPU 使用：`nvidia-smi`
- 尝试使用更小的模型（修改脚本中的 `MODEL_PATH`）
- 降低推流分辨率或帧率

### 6. 容器不断重启

**症状**: 容器状态显示 "Restarting"

**检查步骤**:

```bash
# 查看容器退出代码
docker ps -a | grep yolo-detect

# 查看容器日志
docker logs yolo-detect

# 检查系统资源
free -h
df -h
```

**解决方法**:
- 检查日志中的错误信息
- 确认有足够的系统资源（内存、磁盘）
- 检查 Docker 日志：`journalctl -u docker`

## 调试技巧

### 查看实时日志

```bash
# 所有服务日志
docker-compose logs -f

# 单个服务日志
docker logs -f yolo-detect

# RTMP 服务器日志
docker logs -f rtmp
```

### 进入容器调试

```bash
# 进入检测容器
docker exec -it yolo-detect bash

# 在容器内检查
nvidia-smi
python3 --version
ls -la /workspace/scripts/
```

### 测试 RTMP 连接

```bash
# 查看 RTMP 统计
curl http://localhost:8080/stat

# 测试 RTMP 端口
nc -zv localhost 1935
```

### 检查 HLS 文件

```bash
# 列出 HLS 文件
docker exec rtmp find /opt/data -name "*.m3u8"

# 查看 m3u8 内容
docker exec rtmp cat /opt/data/hls/cam/index.m3u8
```

## 性能优化

### 降低延迟

1. 减少 HLS 片段长度（在 `config/rtmp-entrypoint.sh` 中修改 `hls_fragment`）
2. 使用更快的编码预设（在推流时使用 `ultrafast` 而非 `veryfast`）
3. 降低推流分辨率

### 提高检测速度

1. 使用更小的模型（yolo11n 而非 yolo11x）
2. 降低检测帧率（每隔几帧检测一次）
3. 使用 GPU 加速

### 节省资源

1. 只启动需要的检测服务（注释掉 `docker-compose.yml` 中不需要的服务）
2. 使用更小的模型
3. 降低推流比特率

## 获取帮助

如果以上方法都无法解决问题，请：

1. 收集日志信息
2. 收集系统信息（Docker 版本、GPU 信息等）
3. 在 GitHub 上创建 Issue，附上问题描述和日志
