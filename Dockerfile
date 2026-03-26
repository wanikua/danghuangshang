# syntax=docker/dockerfile:1
# Platform: linux/amd64, linux/arm64
# AI 朝廷 · 优化版 Docker 镜像
# 特点：多阶段构建、层缓存优化、体积减小、安全加固

# ============================================
# 阶段 1: GUI 前端构建
# ============================================
FROM node:22-alpine AS gui-builder
WORKDIR /build

# 复制依赖文件（利用 Docker 层缓存）
COPY gui/package.json gui/package-lock.json ./
RUN npm ci --loglevel=error

# 复制源码并构建
COPY gui/ ./
RUN npx tsc -b && npx vite build --emptyOutDir

# ============================================
# 阶段 2: 主镜像
# ============================================
FROM node:22-alpine

# 元数据
LABEL maintainer="wanikua" \
      description="AI 朝廷 - 多 Agent 协作框架" \
      org.opencontainers.image.source="https://github.com/wanikua/danghuangshang" \
      org.opencontainers.image.version="3.6.0" \
      org.opencontainers.image.licenses="MIT"

# 安装系统依赖（合并为单层减小体积）
RUN apk add --no-cache \
        bash \
        curl \
        git \
        ca-certificates \
        gnupg \
        chromium \
        jq \
        python3 \
        py3-pip \
        && rm -rf /var/cache/apk/* \
        && rm -rf /tmp/*

# 环境变量
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium \
    PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true \
    NODE_ENV=production \
    PYTHONUNBUFFERED=1

# 安装 OpenClaw（全局）
RUN npm install -g openclaw@latest --loglevel=error

# 安装 OpenViking（可选，失败不影响构建）
RUN python3 -m venv /opt/openviking && \
    (/opt/openviking/bin/pip install --no-cache-dir openviking 2>/dev/null && \
    ln -sf /opt/openviking/bin/openviking /usr/local/bin/openviking) || \
    echo "⚠ OpenViking 安装跳过（不影响核心功能）"
ENV PATH="/opt/openviking/bin:$PATH"

# 创建非特权用户（安全加固）
RUN addgroup -S court && adduser -S court -G court -h /home/court -s /bin/bash

# 创建工作目录
ARG WORKSPACE=/home/court/clawd
RUN mkdir -p ${WORKSPACE}/memory \
             ${WORKSPACE}/skills \
             /home/court/.openclaw \
             /opt/gui/server \
             /opt/skills-dist && \
    chown -R court:court /home/court /opt/gui /opt/skills-dist

WORKDIR ${WORKSPACE}

# 复制初始化脚本
COPY docker/entrypoint.sh /entrypoint.sh
COPY docker/init-docker.sh /init-docker.sh
RUN chmod +x /entrypoint.sh /init-docker.sh

# 复制 GUI 构建产物
COPY --from=gui-builder /build/dist/ /opt/gui/dist/
COPY gui/server/ /opt/gui/server/
COPY gui/package.json /opt/gui/package.json

# 安装 GUI 后端依赖
RUN cd /opt/gui/server && npm ci --omit=dev --loglevel=error && \
    chown -R court:court /opt/gui

# 复制 Skills（只读模板）
COPY skills/ /opt/skills-dist/

# 设置所有权
RUN chown -R court:court /entrypoint.sh /init-docker.sh

# 暴露端口
EXPOSE 18789 18795

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:18789/health || exit 1

# 以非特权用户运行
USER court

# 默认命令
ENTRYPOINT ["/entrypoint.sh"]
CMD ["openclaw", "gateway", "--verbose"]
