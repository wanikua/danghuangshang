# 🐳 Docker Hub 配置指南

> **镜像名称**：`boluobobo/ai-court`  
> **支持架构**：linux/amd64, linux/arm64  
> **自动构建**：GitHub Actions  
> **最新版本**：v3.6.0

---

## 📋 Docker Hub 信息

| 项目 | 值 |
|------|-----|
| **镜像名** | `boluobobo/ai-court` |
| **仓库地址** | https://hub.docker.com/r/boluobobo/ai-court |
| **支持架构** | amd64, arm64 |
| **自动构建** | ✅ GitHub Actions |
| **最新标签** | `latest`, `v3.6.0` |

---

## 🚀 快速使用

### 方式一：Docker Compose（推荐）

```bash
# 1. 创建 docker-compose.yml
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  ai-court:
    image: boluobobo/ai-court:latest
    container_name: ai-court
    restart: unless-stopped
    ports:
      - "18789:18789"  # Gateway WebUI
      - "18795:18795"  # GUI Dashboard
    volumes:
      - ~/.openclaw:/root/.openclaw
      - ~/clawd:/root/clawd
    environment:
      - NODE_ENV=production
      - ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}
      - DASHSCOPE_API_KEY=${DASHSCOPE_API_KEY}
      - DISCORD_BOT_TOKEN=${DISCORD_BOT_TOKEN}
    deploy:
      resources:
        limits:
          memory: 4G
          cpus: '2.0'
EOF

# 2. 配置环境变量
cat > .env << 'EOF'
ANTHROPIC_API_KEY=sk-ant-xxx
DASHSCOPE_API_KEY=sk-xxx
DISCORD_BOT_TOKEN=xxx
EOF

# 3. 启动
docker compose up -d

# 4. 查看日志
docker compose logs -f
```

---

### 方式二：Docker 命令

```bash
# 1. 拉取镜像
docker pull boluobobo/ai-court:latest

# 2. 运行容器
docker run -d \
  --name ai-court \
  -p 18789:18789 \
  -p 18795:18795 \
  -v ~/.openclaw:/root/.openclaw \
  -v ~/clawd:/root/clawd \
  -e ANTHROPIC_API_KEY=sk-ant-xxx \
  -e DASHSCOPE_API_KEY=sk-xxx \
  -e DISCORD_BOT_TOKEN=xxx \
  boluobobo/ai-court:latest

# 3. 查看日志
docker logs -f ai-court
```

---

## 🏷️ 可用镜像标签

| 标签 | 说明 | 适用场景 |
|------|------|----------|
| `latest` | 最新稳定版 | 生产环境 |
| `v3.6.0` | 特定版本 | 版本锁定 |
| `main` | 主分支构建 | 测试新功能 |

---

## 🔧 GitHub Actions 自动构建

### 触发条件

```yaml
on:
  push:
    tags: ['v*']      # 推送版本标签
    branches: [main]  # 推送到 main 分支
  workflow_dispatch:  # 手动触发
```

### 构建流程

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Set up QEMU
        uses: docker/setup-qemu-action@v3
      
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3
      
      - name: Login to Docker Hub
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKERHUB_USERNAME }}
          password: ${{ secrets.DOCKERHUB_TOKEN }}
      
      - name: Build and push
        uses: docker/build-push-action@v5
        with:
          context: .
          platforms: linux/amd64,linux/arm64
          push: true
          tags: |
            boluobobo/ai-court:latest
            boluobobo/ai-court:${{ github.ref_name }}
```

---

## 🔐 Docker Hub 密钥配置

### 1. 创建 Docker Hub Token

1. 登录 https://hub.docker.com
2. 进入 **Account Settings** → **Security**
3. 点击 **New Access Token**
4. 输入 Token 名称（如：`github-actions`）
5. 选择权限：**Read & Write**
6. 复制 Token（只显示一次！）

---

### 2. 配置 GitHub Secrets

进入仓库 **Settings** → **Secrets and variables** → **Actions**

添加以下 Secrets：

| Secret Name | Value |
|-------------|-------|
| `DOCKERHUB_USERNAME` | 你的 Docker Hub 用户名 |
| `DOCKERHUB_TOKEN` | 上一步创建的 Token |

---

## 📊 镜像大小

| 镜像 | 大小 | 说明 |
|------|------|------|
| `boluobobo/ai-court:latest` | ~1.2GB | 完整镜像（含 GUI） |
| `boluobobo/ai-court:slim` | ~500MB | 精简版（无 GUI） |

---

## 🛡️ 安全配置

### 1. 非 root 用户运行

```dockerfile
# Dockerfile
RUN useradd -m -u 1000 clawd
USER clawd
```

### 2. 只读文件系统

```yaml
# docker-compose.yml
services:
  ai-court:
    read_only: true
    tmpfs:
      - /tmp
      - /var/log
```

### 3. 资源限制

```yaml
# docker-compose.yml
services:
  ai-court:
    deploy:
      resources:
        limits:
          memory: 4G
          cpus: '2.0'
```

### 4. 网络隔离

```yaml
# docker-compose.yml
networks:
  ai-court:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16

services:
  ai-court:
    networks:
      - ai-court
```

---

## 🔍 故障排查

### 问题 1：镜像拉取失败

```bash
# 错误：unauthorized: authentication required
# 解决：登录 Docker Hub
docker login

# 或检查 .docker/config.json
cat ~/.docker/config.json
```

---

### 问题 2：容器无法启动

```bash
# 查看错误日志
docker logs ai-court

# 检查配置文件
docker exec -it ai-court cat /root/.openclaw/openclaw.json

# 检查环境变量
docker exec -it ai-court env | grep API_KEY
```

---

### 问题 3：端口冲突

```bash
# 检查端口占用
lsof -i :18789
lsof -i :18795

# 修改端口映射
docker run -p 8080:18789 -p 8085:18795 ...
```

---

### 问题 4：内存不足

```bash
# 查看资源使用
docker stats ai-court

# 调整限制
docker update --memory 2G ai-court
```

---

## 📈 镜像统计

查看 Docker Hub 统计：
https://hub.docker.com/r/boluobobo/ai-court

- **总下载量**：查看 Docker Hub 仪表盘
- **架构分布**：amd64 / arm64
- **更新时间**：每次 push 后自动构建

---

## 🎯 最佳实践

### 1. 使用特定版本标签

```yaml
# ✅ 推荐：使用特定版本
image: boluobobo/ai-court:v3.6.0

# ⚠️ 谨慎：使用 latest（可能意外升级）
image: boluobobo/ai-court:latest
```

---

### 2. 健康检查

```yaml
# docker-compose.yml
services:
  ai-court:
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:18789/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
```

---

### 3. 日志轮转

```yaml
# docker-compose.yml
services:
  ai-court:
    logging:
      driver: json-file
      options:
        max-size: "50m"
        max-file: "3"
```

---

### 4. 自动更新

```bash
# 使用 Watchtower 自动更新
docker run -d \
  --name watchtower \
  -v /var/run/docker.sock:/var/run/docker.sock \
  containrrr/watchtower \
  --interval 86400 \
  ai-court
```

---

## 📖 相关文档

- [Docker 部署指南](./docker-deployment.md)
- [Docker 多架构构建](./docker-multiarch.md)
- [安装脚本修复](./install-script-fix.md)

---

## 🔗 外部链接

- **Docker Hub**: https://hub.docker.com/r/boluobobo/ai-court
- **GitHub**: https://github.com/wanikua/danghuangshang
- **Docker 文档**: https://docs.docker.com/

---

**最后更新**：2026-03-23  
**维护者**：工部尚书
