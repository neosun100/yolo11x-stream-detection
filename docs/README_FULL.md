# YOLO11x 视频流实时检测系统 - 完整使用指南

基于 Ultralytics YOLO11x 的实时视频流检测系统，支持多种 AI 检测功能，通过 RTMP/HLS 协议提供流媒体服务。

---

## 📋 目录

1. [系统概述](#系统概述)
2. [功能特性](#功能特性)
3. [系统架构](#系统架构)
4. [环境要求](#环境要求)
5. [安装部署](#安装部署)
6. [配置说明](#配置说明)
7. [启动系统](#启动系统)
8. [使用方法](#使用方法)
9. [所有检测流 URL](#所有检测流-url)
10. [故障排查](#故障排查)
11. [常见问题](#常见问题)

---

## 🎯 系统概述

本系统提供了一个完整的实时视频流检测解决方案，支持：

- **RTMP 推流接收**：从 Mac 或其他设备接收实时视频流
- **多种 AI 检测**：11 种不同的 YOLO11x 检测功能
- **HLS 流媒体输出**：通过 HTTPS 提供安全的 HLS 播放服务
- **GPU 加速**：使用 NVIDIA GPU 进行实时推理
- **多用户支持**：支持多个用户同时推流和观看自己的检测结果

---

## ✨ 功能特性

### 支持的检测类型

1. **目标检测 (Detect)** - 检测对象并绘制边界框
2. **人体姿态识别 (Pose)** - 检测人体关键点和骨架
3. **实例分割 (Segment)** - 像素级对象分割
4. **图像分类 (Classify)** - 图像分类识别
5. **旋转边界框 (OBB)** - 旋转对象检测
6. **对象计数 (Count)** - 对象数量统计
7. **热力图 (Heatmap)** - 对象出现频率可视化
8. **速度估计 (Speed)** - 对象移动速度估算
9. **健身训练 (Workout)** - AI 健身动作识别
10. **区域跟踪 (TrackZone)** - 指定区域对象跟踪
11. **对象模糊 (Blur)** - 隐私保护模糊处理

### 技术特性

- ✅ 使用最新的 YOLO11x 模型系列
- ✅ NVIDIA GPU 加速（支持 L40S 等 GPU）
- ✅ RTMP 推流认证（支持多用户）
- ✅ HTTPS 安全 HLS 播放
- ✅ 嵌套目录支持多用户流隔离
- ✅ Docker 容器化部署
- ✅ 一键启动脚本

---

## 🏗️ 系统架构

```
┌─────────────────┐
│   Mac 客户端    │
│  (FFmpeg 推流)  │
└────────┬────────┘
         │ RTMP (1935)
         ↓
┌─────────────────┐
│  NGEX 服务器    │
│ (Stream 代理)    │
└────────┬────────┘
         │ RTMP 转发
         ↓
┌─────────────────────────────────────────┐
│          GPU 服务器                      │
│  ┌──────────────────────────────────┐   │
│  │  RTMP 服务器 (nginx-rtmp)       │   │
│  │  - 接收推流                      │   │
│  │  - 生成 HLS                      │   │
│  └─────────────┬────────────────────┘   │
│                │                         │
│  ┌─────────────▼────────────────────┐   │
│  │  检测容器 (11 个)                │   │
│  │  - ultralytics-track            │   │
│  │  - ultralytics-pose             │   │
│  │  - ultralytics-segment          │   │
│  │  - ... (其他 8 个)              │   │
│  └─────────────┬────────────────────┘   │
│                │                         │
│  ┌─────────────▼────────────────────┐   │
│  │  RTMP 服务器                    │   │
│  │  (接收检测结果并生成 HLS)       │   │
│  └──────────────────────────────────┘   │
└─────────────────┬───────────────────────┘
                  │ HLS (8080)
                  ↓
┌─────────────────┐
│  NGEX 服务器    │
│ (HTTPS 代理)    │
└────────┬────────┘
         │ HTTPS
         ↓
┌─────────────────┐
│   用户播放      │
│  (FFplay/VLC)   │
└─────────────────┘
```

---

## 🔧 环境要求

### 硬件要求

- **GPU 服务器**：
  - NVIDIA GPU（推荐 L40S 或更高）
  - 至少 32GB 系统内存
  - 足够的存储空间（用于 HLS 文件缓存）

- **NGEX 服务器**：
  - 支持 Nginx stream 模块
  - 已配置 SSL 证书
  - 公网 IP 和域名

- **推流设备**：
  - Mac（使用 FFmpeg）或其他支持 RTMP 推流的设备

### 软件要求

- **GPU 服务器**：
  - Docker 20.10+
  - Docker Compose 2.0+
  - NVIDIA Container Toolkit
  - CUDA 驱动（与 GPU 兼容）

- **NGEX 服务器**：
  - Nginx（支持 stream 模块）
  - SSL 证书

- **推流设备**：
  - FFmpeg（推荐 7.0+）

---

## 📦 安装部署

### 1. 克隆项目

```bash
cd /home/neo/upload
git clone <repository-url> ultralytics
cd ultralytics
```

### 2. 配置文件准备

#### 2.1 创建环境变量文件

```bash
cp .env.example .env
```

编辑 `.env` 文件：

```bash
# RTMP 推流密钥（用于认证）
RTMP_PUSH_KEY=your_secret_key_here

# 默认流名称
STREAM_NAME=cam
```

**重要**：`RTMP_PUSH_KEY` 是推流认证的密钥，请设置为强密码。

#### 2.2 NGEX 服务器配置

在 NGEX 服务器（<your-ngx-server-ip>）上配置：

**添加 Stream 模块配置**（在 `/etc/nginx/nginx.conf` 开头添加）：

```nginx
# RTMP TCP 端口转发（Mac -> NGEX -> GPU）
stream {
    upstream rtmp_backend {
        server <your-gpu-server-ip>:1935;  # GPU 服务器 IP
    }
    
    server {
        listen 1935;
        proxy_pass rtmp_backend;
        proxy_timeout 1h;
        proxy_connect_timeout 10s;
    }
}
```

**配置 HTTPS HLS 代理**（在 `http` 块中添加）：

```nginx
server {
    listen 443 ssl http2;
    server_name <your-server-domain>;
    
    ssl_certificate     /etc/nginx/aws.xin.pem;
    ssl_certificate_key /etc/nginx/aws.xin.pem;
    
    # HLS 播放代理
    location / {
        proxy_pass http://<your-gpu-server-ip>:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        
        # 基本认证
        auth_basic "Restricted";
        auth_basic_user_file /etc/nginx/htpasswd/hls.users;
        
        # HLS 友好设置
        add_header Access-Control-Allow-Origin *;
        types { application/vnd.apple.mpegurl m3u8; video/mp2t ts; }
        expires -1;
    }
}
```

**创建认证文件**（在 NGEX 服务器上）：

```bash
# 安装 htpasswd（如果没有）
apt-get install apache2-utils

# 创建用户文件
mkdir -p /etc/nginx/htpasswd
htpasswd -nbB <your-username> <your-password> > /etc/nginx/htpasswd/hls.users
```

### 3. 检查依赖

```bash
# 检查 Docker
docker --version
docker-compose --version

# 检查 NVIDIA 运行时
nvidia-smi
docker run --rm --gpus all nvidia/cuda:11.8.0-base-ubuntu22.04 nvidia-smi

# 检查 NVIDIA Container Toolkit
docker info | grep -i runtime
```

---

## ⚙️ 配置说明

### 环境变量配置

`.env` 文件中的配置项：

- **RTMP_PUSH_KEY**：RTMP 推流认证密钥（当前版本已临时禁用认证）
- **STREAM_NAME**：默认流名称（默认为 `cam`）

### Docker Compose 配置

系统使用 `docker-compose.yml` 管理 12 个容器：

1. **rtmp**：RTMP 服务器和 HLS 生成
2. **ultralytics-track**：目标检测
3. **ultralytics-pose**：姿态识别
4. **ultralytics-segment**：实例分割
5. **ultralytics-classify**：图像分类
6. **ultralytics-obb**：旋转边界框
7. **ultralytics-count**：对象计数
8. **ultralytics-heatmap**：热力图
9. **ultralytics-speed**：速度估计
10. **ultralytics-workout**：健身训练
11. **ultralytics-trackzone**：区域跟踪
12. **ultralytics-blur**：对象模糊

### 端口配置

- **1935**：RTMP 推流端口
- **8080**：HLS HTTP 播放端口（GPU 服务器）
- **8081**：RTMP 认证回调端口（内部使用）

---

## 🚀 启动系统

### 方法 1：使用一键启动脚本（推荐）

```bash
cd /home/neo/upload/ultralytics

# 启动所有服务
bash start.sh

# 或使用其他选项
bash start.sh --pull    # 拉取最新镜像后启动
bash start.sh --status  # 查看服务状态
bash start.sh --restart # 重启所有服务
```

### 方法 2：使用 Docker Compose

```bash
cd /home/neo/upload/ultralytics

# 启动所有服务
docker-compose up -d

# 查看服务状态
docker-compose ps

# 查看日志
docker-compose logs -f

# 停止所有服务
docker-compose down
```

### 验证启动

```bash
# 检查容器状态
docker ps | grep -E "rtmp|ultralytics"

# 检查 RTMP 服务器
curl http://localhost:8080/stat

# 检查 GPU 使用
nvidia-smi
```

---

## 📱 使用方法

### 1. 推流（从 Mac）

在 Mac 上使用 FFmpeg 推流：

```bash
ffmpeg -f avfoundation -framerate 30 -pixel_format nv12 \
  -video_size 1280x720 -i "0:" \
  -c:v libx264 -preset veryfast -tune zerolatency -pix_fmt yuv420p \
  -g 60 -b:v 3M -maxrate 3M -bufsize 6M \
  -f flv "rtmp://<your-server-domain>:1935/live/cam"
```

**参数说明**：
- `-f avfoundation`：Mac 视频捕获
- `-framerate 30`：帧率
- `-video_size 1280x720`：视频分辨率
- `-i "0:"`：使用默认摄像头（`0` 是摄像头索引）
- `-c:v libx264`：H.264 编码
- `-preset veryfast`：编码速度预设
- `-b:v 3M`：视频比特率
- `rtmp://<your-server-domain>:1935/live/cam`：RTMP 推流地址

**注意**：当前版本认证已临时禁用，无需密钥参数。

### 2. 播放检测流

#### 使用 FFplay

```bash
# 原始流
ffplay "https://<your-username>:<your-password>@<your-server-domain>/live/cam/index.m3u8"

# 目标检测流
ffplay "https://<your-username>:<your-password>@<your-server-domain>/detected/cam/index.m3u8"

# 姿态识别流
ffplay "https://<your-username>:<your-password>@<your-server-domain>/pose/cam/index.m3u8"
```

#### 使用 VLC

1. 打开 VLC
2. 选择「媒体」→「打开网络串流」
3. 输入 URL：`https://<your-username>:<your-password>@<your-server-domain>/detected/cam/index.m3u8`
4. 点击「播放」

#### 使用浏览器（需要支持 HLS 的播放器）

可以使用 HLS.js 或其他 HLS 播放器库。

### 3. 多用户推流

如果要使用不同的流名称（如 `neo`）：

**推流**：
```bash
ffmpeg ... -f flv "rtmp://<your-server-domain>:1935/live/neo"
```

**播放**（需要设置 `STREAM_NAME=neo` 并重启检测容器）：
```bash
STREAM_NAME=neo docker-compose restart ultralytics-track
ffplay "https://<your-username>:<your-password>@<your-server-domain>/detected/neo/index.m3u8"
```

---

## 📺 所有检测流 URL

### 认证信息

- **用户名**：`<your-username>`
- **密码**：`<your-password>`
- **基础域名**：`<your-server-domain>`

### URL 格式

所有流都使用统一格式：
```
https://<your-username>:<your-password>@<your-server-domain>/{流类型}/cam/index.m3u8
```

### 完整 URL 列表

| # | 检测类型 | URL | 说明 |
|---|---------|-----|------|
| 1 | 原始流 | `https://<your-username>:<your-password>@<your-server-domain>/live/cam/index.m3u8` | 无检测的原始视频 |
| 2 | 目标检测 | `https://<your-username>:<your-password>@<your-server-domain>/detected/cam/index.m3u8` | YOLO 对象检测 |
| 3 | 姿态识别 | `https://<your-username>:<your-password>@<your-server-domain>/pose/cam/index.m3u8` | 人体姿态关键点 |
| 4 | 实例分割 | `https://<your-username>:<your-password>@<your-server-domain>/segment/cam/index.m3u8` | 像素级分割 |
| 5 | 图像分类 | `https://<your-username>:<your-password>@<your-server-domain>/classify/cam/index.m3u8` | 图像分类 |
| 6 | 旋转边界框 | `https://<your-username>:<your-password>@<your-server-domain>/obb/cam/index.m3u8` | 旋转对象检测 |
| 7 | 对象计数 | `https://<your-username>:<your-password>@<your-server-domain>/count/cam/index.m3u8` | 对象数量统计 |
| 8 | 热力图 | `https://<your-username>:<your-password>@<your-server-domain>/heatmap/cam/index.m3u8` | 热力图可视化 |
| 9 | 速度估计 | `https://<your-username>:<your-password>@<your-server-domain>/speed/cam/index.m3u8` | 速度估算 |
| 10 | 健身训练 | `https://<your-username>:<your-password>@<your-server-domain>/workout/cam/index.m3u8` | 健身动作识别 |
| 11 | 区域跟踪 | `https://<your-username>:<your-password>@<your-server-domain>/trackzone/cam/index.m3u8` | 区域对象跟踪 |
| 12 | 对象模糊 | `https://<your-username>:<your-password>@<your-server-domain>/blur/cam/index.m3u8` | 隐私保护模糊 |

### 快速测试脚本

创建 `test_streams.sh`：

```bash
#!/bin/bash

BASE_URL="https://<your-username>:<your-password>@<your-server-domain>"
STREAM_NAME="cam"

streams=(
    "live:原始流"
    "detected:目标检测"
    "pose:姿态识别"
    "segment:实例分割"
    "classify:图像分类"
    "obb:旋转边界框"
    "count:对象计数"
    "heatmap:热力图"
    "speed:速度估计"
    "workout:健身训练"
    "trackzone:区域跟踪"
    "blur:对象模糊"
)

for stream_info in "${streams[@]}"; do
    stream=$(echo $stream_info | cut -d: -f1)
    name=$(echo $stream_info | cut -d: -f2)
    url="${BASE_URL}/${stream}/${STREAM_NAME}/index.m3u8"
    
    echo "测试: $name"
    echo "URL: $url"
    curl -s "$url" | head -3
    echo ""
done
```

---

## 🔍 故障排查

### 1. 推流失败

**症状**：FFmpeg 推流时显示 "Input/output error"

**检查步骤**：

```bash
# 检查 RTMP 服务器是否运行
docker ps | grep rtmp

# 检查 RTMP 端口是否监听
netstat -tlnp | grep 1935

# 检查 RTMP 服务器日志
docker logs --tail 50 rtmp

# 检查 NGEX stream 配置
ssh root@<your-ngx-server-ip> "nginx -t"
```

**解决方法**：
- 确认 NGEX 服务器已配置 stream 模块
- 确认 GPU 服务器端口 1935 开放
- 检查网络连接

### 2. HLS 播放 404

**症状**：访问 HLS URL 返回 404

**检查步骤**：

```bash
# 检查 HLS 文件是否存在
docker exec rtmp ls -lh /opt/data/hls/cam/

# 检查 nginx HTTP 配置
docker exec rtmp cat /etc/nginx/nginx.conf | grep "location /live"

# 测试本地访问
curl "http://localhost:8080/live/cam/index.m3u8"
```

**解决方法**：
- 确认推流正在进行
- 等待 HLS 文件生成（需要几秒钟）
- 检查 nginx location 配置是否正确

### 3. 检测容器无法连接

**症状**：检测容器日志显示 "Connection refused" 或 "Stream timeout"

**检查步骤**：

```bash
# 检查检测容器日志
docker logs --tail 30 ultralytics-track

# 检查 RTMP 服务器是否运行
docker ps | grep rtmp

# 检查 RTMP 统计信息
curl "http://localhost:8080/stat" | grep "publishing"

# 检查流名称配置
docker exec ultralytics-track printenv STREAM_NAME
```

**解决方法**：
- 确认推流正在进行
- 确认 `STREAM_NAME` 环境变量与推流名称匹配
- 重启检测容器：`docker-compose restart ultralytics-track`

### 4. GPU 未使用

**症状**：`nvidia-smi` 显示 GPU 使用率为 0%

**检查步骤**：

```bash
# 检查 NVIDIA 运行时
docker info | grep -i runtime

# 检查容器 GPU 访问
docker exec ultralytics-track nvidia-smi

# 检查环境变量
docker exec ultralytics-track printenv NVIDIA_VISIBLE_DEVICES
```

**解决方法**：
- 确认安装了 NVIDIA Container Toolkit
- 确认 `docker-compose.yml` 中配置了 GPU
- 重启容器：`docker-compose restart`

---

## ❓ 常见问题

### Q1: 为什么推流需要密钥？

A: RTMP 推流认证用于防止未授权的推流。当前版本已临时禁用认证以便测试，生产环境建议启用认证。

### Q2: 可以同时推多个流吗？

A: 可以。每个流使用不同的流名称（如 `cam`, `neo`, `alice`），并为每个流启动对应的检测容器。

### Q3: HLS 延迟是多少？

A: 默认配置下，HLS 延迟约为 10-20 秒（取决于 `hls_playlist_length` 和网络延迟）。

### Q4: 如何修改检测参数？

A: 编辑对应的检测脚本（如 `yolo_stream_detector.py`），然后重新构建镜像或重启容器。

### Q5: 支持的推流分辨率是多少？

A: 系统支持各种分辨率，推荐 1280x720 或 1920x1080。更高分辨率需要更强的 GPU 性能。

### Q6: 如何查看检测容器的实时日志？

A: 使用 `docker logs -f ultralytics-track` 查看实时日志。

### Q7: 如何停止所有服务？

A: 使用 `bash stop.sh` 或 `docker-compose down`。

### Q8: 如何更新模型？

A: YOLO 模型会在首次运行时自动下载。要使用自定义模型，修改检测脚本中的模型路径。

---

## 📝 文件说明

### 核心文件

- **`docker-compose.yml`**：Docker Compose 配置文件
- **`start.sh`**：一键启动脚本
- **`stop.sh`**：停止脚本
- **`restart.sh`**：重启脚本
- **`status.sh`**：状态查看脚本
- **`.env`**：环境变量配置

### 配置文件

- **`rtmp-entrypoint.sh`**：RTMP 服务器配置脚本
- **`所有检测流URL访问指南.md`**：详细的 URL 列表和使用说明

### 检测脚本

- **`yolo_stream_detector.py`**：目标检测脚本（示例）
- 其他检测脚本位于各自容器中

---

## 🔄 系统管理

### 查看服务状态

```bash
bash status.sh
# 或
docker-compose ps
```

### 查看日志

```bash
# RTMP 服务器日志
docker logs -f rtmp

# 检测容器日志
docker logs -f ultralytics-track

# 所有容器日志
docker-compose logs -f
```

### 重启服务

```bash
# 重启所有服务
bash restart.sh

# 重启单个容器
docker-compose restart ultralytics-track
```

### 更新镜像

```bash
# 拉取最新镜像
docker-compose pull

# 重启服务
docker-compose up -d
```

---

## 📚 参考文档

- [Ultralytics YOLO 官方文档](https://docs.ultralytics.com/)
- [Nginx RTMP 模块文档](https://github.com/arut/nginx-rtmp-module)
- [FFmpeg 文档](https://ffmpeg.org/documentation.html)
- [Docker Compose 文档](https://docs.docker.com/compose/)

---

## 📄 许可证

本项目基于 Ultralytics YOLO，请遵循相应的许可证要求。

---

## 👥 贡献

欢迎提交 Issue 和 Pull Request。

---

## 📧 联系方式

如有问题或建议，请通过 Issue 联系。

---

**最后更新**：2025-11-01  
**版本**：1.0  
**作者**：Ultralytics YOLO Team

---

## 🎉 快速开始总结

1. **准备环境**：确保 Docker、NVIDIA Container Toolkit 已安装
2. **配置 NGEX**：添加 stream 模块和 HTTPS 代理配置
3. **配置环境变量**：编辑 `.env` 文件
4. **启动系统**：运行 `bash start.sh`
5. **推流**：在 Mac 上使用 FFmpeg 推流到 `rtmp://<your-server-domain>:1935/live/cam`
6. **播放**：使用 `ffplay "https://<your-username>:<your-password>@<your-server-domain>/detected/cam/index.m3u8"` 播放检测流

享受你的实时 AI 检测系统！🚀
