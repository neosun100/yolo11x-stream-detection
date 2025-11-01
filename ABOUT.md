# 关于本项目

## 项目简介

YOLO11x Stream Detection 是一个基于 Ultralytics YOLO11x 的实时视频流检测系统。它能够接收 RTMP 推流，使用多种 AI 检测算法处理视频，并通过 HLS 协议提供流媒体播放服务。

## 核心特性

- **11 种检测类型**: 从基础的目标检测到复杂的健身动作识别
- **GPU 加速**: 使用 NVIDIA GPU 进行实时推理
- **容器化部署**: 基于 Docker Compose，一键启动
- **多流支持**: 支持多个用户同时推流和观看各自的检测结果
- **易于使用**: 提供完整的脚本和文档

## 技术栈

- **AI 模型**: Ultralytics YOLO11x
- **流媒体**: RTMP (推流) + HLS (播放)
- **容器**: Docker + Docker Compose
- **服务器**: nginx-rtmp
- **GPU**: NVIDIA Container Toolkit

## 适用场景

- 实时监控系统
- 智能安防
- 人流统计
- 动作分析
- 健身指导
- 隐私保护（对象模糊）

## 系统要求

- NVIDIA GPU (推荐 L40S 或更高)
- Docker 20.10+
- Docker Compose 2.0+
- NVIDIA Container Toolkit

## 快速开始

```bash
# 1. 配置环境变量
cp .env.example .env

# 2. 启动系统
bash start.sh

# 3. 推流和播放（参考 SETUP_GUIDE.md）
```

详细文档请查看：
- [README.md](README.md) - 项目概览
- [SETUP_GUIDE.md](SETUP_GUIDE.md) - 快速设置指南
- [docs/README_FULL.md](docs/README_FULL.md) - 完整使用指南

## 许可证

MIT License - 详见 [LICENSE](LICENSE)

## 贡献

欢迎提交 Issue 和 Pull Request！

---

**版本**: 1.0  
**最后更新**: 2025-11-01
