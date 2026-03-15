FROM node:22-slim

LABEL maintainer="wanikua" \
      description="AI 朝廷一键部署 Docker 镜像" \
      org.opencontainers.image.source="https://github.com/wanikua/danghuangshang"

# 系统依赖
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
        curl git ca-certificates gnupg \
        chromium python3 python3-pip python3-venv && \
    # gh CLI
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg 2>/dev/null && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] \
        https://cli.github.com/packages stable main" \
        > /etc/apt/sources.list.d/github-cli.list && \
    apt-get update -qq && apt-get install -y --no-install-recommends gh && \
    # 清理
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Chromium 路径
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true

# OpenClaw
RUN npm install -g openclaw --loglevel=error

# [L-02] OpenViking（Python 依赖）— 安装失败时给出明确提示而非静默跳过
RUN python3 -m venv /opt/openviking && \
    (/opt/openviking/bin/pip install --no-cache-dir openviking && \
    ln -s /opt/openviking/bin/openviking /usr/local/bin/openviking 2>/dev/null || \
    echo "⚠ OpenViking 安装跳过（包可能不可用），不影响核心功能")
ENV PATH="/opt/openviking/bin:$PATH"

# [H-04] 创建非特权用户（安全加固）
RUN groupadd -r court && useradd -r -g court -m -s /bin/bash court

# 工作区
ARG WORKSPACE=/home/court/clawd
RUN mkdir -p ${WORKSPACE}/memory ${WORKSPACE}/skills /home/court/.openclaw
WORKDIR ${WORKSPACE}

# 复制朝廷模板文件和初始化脚本
COPY docker/entrypoint.sh /entrypoint.sh
COPY docker/init-docker.sh /init-docker.sh
RUN chmod +x /entrypoint.sh /init-docker.sh && \
    printf '#!/bin/bash\nexec /init-docker.sh "$@"\n' > /usr/local/bin/init-court && \
    chmod +x /usr/local/bin/init-court

# 复制 skill 和模板
COPY skills/ ${WORKSPACE}/skills/

# [M-02] 只复制 GUI server（前端源码不需要进镜像）
COPY gui/server/ /opt/gui/server/
COPY gui/package.json /opt/gui/package.json
RUN cd /opt/gui && npm install --production --loglevel=error 2>/dev/null || true && \
    cd /opt/gui/server && npm install --production --loglevel=error 2>/dev/null || true

# 设置文件所有权
RUN chown -R court:court /home/court ${WORKSPACE} /opt/gui /entrypoint.sh /init-docker.sh

# 端口：Gateway WebUI + 菠萝 GUI（可选）
EXPOSE 18789 18795

# [H-04] 以非 root 用户运行
USER court

ENTRYPOINT ["/entrypoint.sh"]
CMD ["openclaw", "gateway", "--verbose"]
