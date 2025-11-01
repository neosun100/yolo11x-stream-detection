# YOLO11x Stream Detection

基于 Ultralytics YOLO11x 的实时视频流检测系统，支持多种 AI 检测功能，通过 RTMP/HLS 协议提供流媒体服务。

## ✨ 功能特性

### 支持的检测类型

- **目标检测 (Detect)** - 检测对象并绘制边界框
- **人体姿态识别 (Pose)** - 检测人体关键点和骨架
- **实例分割 (Segment)** - 像素级对象分割
- **图像分类 (Classify)** - 图像分类识别
- **旋转边界框 (OBB)** - 旋转对象检测
- **对象计数 (Count)** - 对象数量统计
- **热力图 (Heatmap)** - 对象出现频率可视化
- **速度估计 (Speed)** - 对象移动速度估算
- **健身训练 (Workout)** - AI 健身动作识别
- **区域跟踪 (TrackZone)** - 指定区域对象跟踪
- **对象模糊 (Blur)** - 隐私保护模糊处理

### 技术特点

- ✅ 使用最新的 YOLO11x 模型系列
- ✅ NVIDIA GPU 加速支持
- ✅ RTMP 推流接收
- ✅ HLS 流媒体输出
- ✅ Docker 容器化部署
- ✅ 一键启动脚本
- ✅ 支持多用户多流

## 🚀 快速开始

### 前置要求

- Docker 20.10+ 和 Docker Compose 2.0+
- NVIDIA GPU（推荐）和 NVIDIA Container Toolkit
- 支持 RTMP 推流的设备（Mac/Windows/Linux + FFmpeg）

### 安装步骤

1. **克隆项目**

```bash
git clone <your-repo-url> yolo11x-stream-detection
cd yolo11x-stream-detection
```

2. **配置环境变量**

```bash
cp .env.example .env
# 编辑 .env 文件（可选，有默认值）
```

3. **启动系统**

```bash
bash start.sh
```

4. **推流**

在推流设备上（Mac 示例）：

```bash
ffmpeg -f avfoundation -framerate 30 -pixel_format nv12 \
  -video_size 1280x720 -i "0:" \
  -c:v libx264 -preset veryfast -tune zerolatency -pix_fmt yuv420p \
  -g 60 -b:v 3M -maxrate 3M -bufsize 6M \
  -f flv "rtmp://<your-server-ip>:1935/live/cam"
```

5. **播放检测流**

```bash
# 目标检测流
ffplay "http://<your-server-ip>:8080/detected/cam/index.m3u8"

# 姿态识别流
ffplay "http://<your-server-ip>:8080/pose/cam/index.m3u8"
```

## 📖 详细文档

完整的安装、配置和使用指南请查看 [docs/README_FULL.md](docs/README_FULL.md)。

## 🏗️ 系统架构

```
推流设备 (FFmpeg)
    ↓ RTMP
RTMP 服务器 (nginx-rtmp)
    ↓ 分发
检测容器 (YOLO11x)
    ↓ RTMP
RTMP 服务器 (接收检测结果)
    ↓ HLS
HLS 播放客户端
```

## 📋 项目结构

```
yolo11x-stream-detection/
├── docker-compose.yml       # Docker Compose 配置
├── start.sh                 # 启动脚本
├── stop.sh                  # 停止脚本
├── restart.sh               # 重启脚本
├── status.sh                # 状态查看脚本
├── .env.example             # 环境变量模板
├── .gitignore               # Git 忽略文件
├── config/
│   └── rtmp-entrypoint.sh   # RTMP 服务器配置
├── scripts/
│   ├── yolo_stream_detector.py    # 目标检测
│   ├── yolo_pose_detector.py      # 姿态识别
│   ├── yolo_segment_detector.py   # 实例分割
│   └── ... (其他检测脚本)
├── examples/
│   └── push_stream_example.sh     # 推流示例脚本
└── docs/
    └── README_FULL.md            # 完整文档
```

## 🎯 使用示例

### 基本使用流程

1. **启动服务**

```bash
bash start.sh
```

2. **推流（Mac）**

```bash
# 使用示例脚本
bash examples/push_stream_example.sh mac

# 或手动推流
ffmpeg ... "rtmp://localhost:1935/live/cam"
```

3. **播放检测流**

```bash
# 目标检测
ffplay "http://localhost:8080/detected/cam/index.m3u8"

# 姿态识别
ffplay "http://localhost:8080/pose/cam/index.m3u8"
```

## 🔧 配置说明

### 环境变量

`.env` 文件中的配置：

- `RTMP_PUSH_KEY`: RTMP 推流认证密钥（当前版本已禁用认证）
- `STREAM_NAME`: 默认流名称（默认为 `cam`）

### 端口配置

- **1935**: RTMP 推流端口
- **8080**: HLS HTTP 播放端口
- **8081**: RTMP 认证回调端口（内部使用）

## 📊 服务管理

```bash
# 查看状态
bash status.sh

# 重启服务
bash restart.sh

# 停止服务
bash stop.sh

# 查看日志
docker-compose logs -f

# 查看单个服务日志
docker logs -f yolo-detect
```

## 🌐 访问 URL

所有检测流的访问格式：

```
http://<server-ip>:8080/<detection-type>/<stream-name>/index.m3u8
```

### 完整 URL 列表

| 检测类型 | URL 路径 |
|---------|---------|
| 原始流 | `/live/{stream_name}/index.m3u8` |
| 目标检测 | `/detected/{stream_name}/index.m3u8` |
| 姿态识别 | `/pose/{stream_name}/index.m3u8` |
| 实例分割 | `/segment/{stream_name}/index.m3u8` |
| 图像分类 | `/classify/{stream_name}/index.m3u8` |
| 旋转边界框 | `/obb/{stream_name}/index.m3u8` |
| 对象计数 | `/count/{stream_name}/index.m3u8` |
| 热力图 | `/heatmap/{stream_name}/index.m3u8` |
| 速度估计 | `/speed/{stream_name}/index.m3u8` |
| 健身训练 | `/workout/{stream_name}/index.m3u8` |
| 区域跟踪 | `/trackzone/{stream_name}/index.m3u8` |
| 对象模糊 | `/blur/{stream_name}/index.m3u8` |

## 🔍 故障排查

### 推流失败

- 检查 RTMP 服务器是否运行：`docker ps | grep rtmp`
- 检查端口是否开放：`netstat -tlnp | grep 1935`
- 查看 RTMP 日志：`docker logs rtmp`

### HLS 播放 404

- 确认推流正在进行
- 等待几秒让 HLS 文件生成
- 检查 HLS 文件：`docker exec rtmp ls -lh /opt/data/hls/cam/`

### 检测容器无法连接

- 检查容器日志：`docker logs yolo-detect`
- 确认 RTMP 推流正在进行：`curl http://localhost:8080/stat`
- 检查流名称配置：`docker exec yolo-detect printenv STREAM_NAME`

更多故障排查信息请查看 [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)。

## 📚 相关资源

- [Ultralytics YOLO 文档](https://docs.ultralytics.com/)
- [Nginx RTMP 模块](https://github.com/arut/nginx-rtmp-module)
- [FFmpeg 文档](https://ffmpeg.org/documentation.html)

## 📄 许可证

本项目基于 Ultralytics YOLO，请遵循相应的许可证要求。

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

---

**版本**: 1.0  
**最后更新**: 2025-11-01
