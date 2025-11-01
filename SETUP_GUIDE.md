# 快速设置指南

本指南帮助你在新环境中快速部署和运行 YOLO11x 流媒体检测系统。

## 前提条件

- Docker 20.10+ 和 Docker Compose 2.0+
- NVIDIA GPU（推荐）和 NVIDIA Container Toolkit
- 推流设备（Mac/Windows/Linux + FFmpeg）

## 快速开始（5 步）

### 步骤 1: 准备环境

```bash
# 检查 Docker
docker --version
docker compose version

# 检查 GPU（如果有）
nvidia-smi

# 检查 NVIDIA Container Toolkit
docker run --rm --gpus all nvidia/cuda:11.8.0-base-ubuntu22.04 nvidia-smi
```

### 步骤 2: 配置环境变量

```bash
cp .env.example .env
# .env 文件已有默认值，可以直接使用
```

### 步骤 3: 启动系统

```bash
bash start.sh
```

等待所有服务启动（约 30-60 秒）。

### 步骤 4: 推流

在推流设备上（Mac 示例）：

```bash
# 使用示例脚本
bash examples/push_stream_example.sh mac

# 或手动推流（替换 <your-server-ip>）
ffmpeg -f avfoundation -framerate 30 -pixel_format nv12 \
  -video_size 1280x720 -i "0:" \
  -c:v libx264 -preset veryfast -tune zerolatency -pix_fmt yuv420p \
  -g 60 -b:v 3M -maxrate 3M -bufsize 6M \
  -f flv "rtmp://<your-server-ip>:1935/live/cam"
```

### 步骤 5: 播放检测流

等待几秒让 HLS 文件生成，然后：

```bash
# 目标检测流
ffplay "http://<your-server-ip>:8080/detected/cam/index.m3u8"

# 姿态识别流
ffplay "http://<your-server-ip>:8080/pose/cam/index.m3u8"
```

## 验证系统运行

```bash
# 查看服务状态
bash status.sh

# 查看 RTMP 统计
curl http://localhost:8080/stat

# 查看 GPU 使用
nvidia-smi
```

## 常见问题

### 问题 1: 推流失败

**原因**: RTMP 服务器未运行或端口未开放

**解决**:
```bash
# 检查 RTMP 容器
docker ps | grep rtmp

# 检查端口
netstat -tlnp | grep 1935
```

### 问题 2: HLS 播放 404

**原因**: 推流未开始或 HLS 文件未生成

**解决**:
```bash
# 确认推流正在进行
curl http://localhost:8080/stat | grep publishing

# 等待几秒钟后重试
```

### 问题 3: 检测容器无法连接

**原因**: 流名称不匹配或推流未开始

**解决**:
```bash
# 检查流名称
docker exec yolo-detect printenv STREAM_NAME

# 确认推流使用的流名称与 STREAM_NAME 一致
```

## 下一步

- 查看 [完整文档](docs/README_FULL.md) 了解详细配置
- 查看 [故障排查指南](docs/TROUBLESHOOTING.md) 解决常见问题
- 查看 [README.md](README.md) 了解项目概览

---

**提示**: 如果遇到问题，请先查看日志：
```bash
docker-compose logs -f
```
