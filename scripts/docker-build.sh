#!/bin/bash
# AI 朝廷 · Docker 镜像构建脚本
# 用法：bash scripts/docker-build.sh [tag]

set -e

TAG=${1:-latest}
IMAGE_NAME="boluobobo/ai-court"
PLATFORMS="linux/amd64,linux/arm64"

echo "======================================"
echo "  AI 朝廷 · Docker 镜像构建"
echo "======================================"
echo ""
echo "镜像名称：${IMAGE_NAME}:${TAG}"
echo "目标平台：${PLATFORMS}"
echo ""

# 检查 Docker
if ! command -v docker &>/dev/null; then
    echo "❌ Docker 未安装"
    exit 1
fi

# 检查 Buildx
if ! docker buildx version &>/dev/null; then
    echo "❌ Docker Buildx 未安装"
    exit 1
fi

# 创建或选择 builder
docker buildx inspect ai-court-builder &>/dev/null || \
    docker buildx create --name ai-court-builder --driver docker-container --use

# 构建镜像
echo "开始构建..."
docker buildx build \
    --platform ${PLATFORMS} \
    --tag ${IMAGE_NAME}:${TAG} \
    --tag ${IMAGE_NAME}:latest \
    --build-arg BUILDKIT_INLINE_CACHE=1 \
    --cache-from type=local,src=.cache/docker \
    --cache-to type=local,dest=.cache/docker,mode=max \
    --progress=plain \
    --push \
    .

echo ""
echo "✅ 构建完成！"
echo ""
echo "镜像信息:"
docker images ${IMAGE_NAME} --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"

echo ""
echo "使用示例:"
echo "  docker run -d --name ai-court ${IMAGE_NAME}:${TAG}"
echo "  或"
echo "  docker compose up -d"
