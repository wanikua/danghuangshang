FROM node:22-slim

LABEL maintainer="wanikua" \
      description="AI 朝廷一键部署 Docker 镜像" \
      org.opencontainers.image.source="https://github.com/wanikua/boluobobo-ai-court-tutorial"

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

# OpenViking（Python 依赖）
RUN python3 -m venv /opt/openviking && \
    /opt/openviking/bin/pip install --no-cache-dir openviking && \
    ln -s /opt/openviking/bin/openviking /usr/local/bin/openviking 2>/dev/null || true
ENV PATH="/opt/openviking/bin:$PATH"

# 工作区
RUN mkdir -p /root/clawd/memory /root/clawd/skills /root/.openclaw
WORKDIR /root/clawd

# 复制朝廷模板文件
COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# 复制 skill 和模板
COPY skills/ /root/clawd/skills/

# 端口：Gateway WebUI
EXPOSE 18789

ENTRYPOINT ["/entrypoint.sh"]
CMD ["openclaw", "gateway", "--verbose"]
