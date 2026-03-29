# 连接外部 OpenClaw 服务配置指南

## 问题背景

AI Court Docker 镜像默认会启动内部的 OpenClaw Gateway 服务，但如果本地已有其他 OpenClaw 实例，会导致：

- ❌ 端口冲突（18789, 18795）
- ❌ 服务冲突
- ❌ 配置重复

## 解决方案

从 v2.1.0 开始，AI Court 支持**外部 OpenClaw 模式**，只运行 GUI，连接到已有的 OpenClaw 服务。

---

## 快速开始

### 方式 1：Docker CLI

```bash
docker run -d \
  --name ai-court-external \
  -p 127.0.0.1:18796:18795 \
  -e ENABLE_EXTERNAL_CLAW=true \
  -e OPENCLAW_HOST=host.docker.internal \
  -e OPENCLAW_PORT=18789 \
  --add-host=host.docker.internal:host-gateway \
  boluobobo/ai-court:latest
```

### 方式 2：Docker Compose

```bash
docker compose -f docker-compose.external-claw.yml up -d
```

---

## 环境变量配置

### 必需变量

| 变量名 | 说明 | 默认值 | 示例 |
|--------|------|--------|------|
| `ENABLE_EXTERNAL_CLAW` | 启用外部 OpenClaw 模式 | `false` | `true` |
| `OPENCLAW_HOST` | 外部 OpenClaw 服务地址 | `host.docker.internal` | `192.168.1.100` |
| `OPENCLAW_PORT` | 外部 OpenClaw 服务端口 | `18789` | `18789` |

### 可选变量

| 变量名 | 说明 | 默认值 | 示例 |
|--------|------|--------|------|
| `OPENCLAW_API_TOKEN` | API 认证 Token | 无 | `your-token` |
| `GUI_PORT` | GUI 服务端口 | `18795` | `18796` |
| `GUI_HOST` | GUI 绑定地址 | `0.0.0.0` | `0.0.0.0` |

---

## 不同平台的配置

### Linux

```yaml
environment:
  - ENABLE_EXTERNAL_CLAW=true
  - OPENCLAW_HOST=192.168.1.100  # 宿主机 IP
  - OPENCLAW_PORT=18789
extra_hosts:
  - "host.docker.internal:host-gateway"
```

### macOS / Windows (Docker Desktop)

```yaml
environment:
  - ENABLE_EXTERNAL_CLAW=true
  - OPENCLAW_HOST=host.docker.internal
  - OPENCLAW_PORT=18789
```

### 同一 Docker 网络

如果外部 OpenClaw 也在 Docker 中运行：

```yaml
environment:
  - ENABLE_EXTERNAL_CLAW=true
  - OPENCLAW_HOST=openclaw-gateway  # 服务名称
  - OPENCLAW_PORT=18789
networks:
  - claw-network
```

---

## 完整 docker-compose 示例

```yaml
version: '3.8'

services:
  # 外部 OpenClaw Gateway（已存在的服务）
  openclaw:
    image: openclaw/gateway:latest
    container_name: openclaw-gateway
    ports:
      - "127.0.0.1:18789:18789"
    volumes:
      - openclaw-config:/root/.openclaw
    networks:
      - claw-network

  # AI Court（只运行 GUI）
  ai-court:
    image: boluobobo/ai-court:latest
    container_name: ai-court
    ports:
      - "127.0.0.1:18796:18795"  # GUI 端口
    environment:
      - ENABLE_EXTERNAL_CLAW=true
      - OPENCLAW_HOST=openclaw
      - OPENCLAW_PORT=18789
    depends_on:
      - openclaw
    networks:
      - claw-network

volumes:
  openclaw-config:

networks:
  claw-network:
    driver: bridge
```

---

## 验证连接

### 1. 检查日志

```bash
docker logs ai-court-external
```

应该看到：
```
📡 模式：连接外部 OpenClaw 服务
外部 OpenClaw 地址：http://host.docker.internal:18789
✅ 成功连接到外部 OpenClaw 服务
```

### 2. 测试 GUI 访问

```bash
curl http://localhost:18796/health
```

### 3. 测试 OpenClaw 连接

```bash
docker exec ai-court-external curl http://$OPENCLAW_HOST:$OPENCLAW_PORT/health
```

---

## 故障排除

### 问题 1：无法连接外部 OpenClaw

**症状**：
```
❌ 无法连接到外部 OpenClaw 服务
```

**解决**：
1. 检查外部 OpenClaw 是否运行：`docker ps | grep openclaw`
2. 检查端口是否正确：`netstat -tlnp | grep 18789`
3. 检查网络可达性：`docker exec ai-court ping <OPENCLAW_HOST>`
4. Linux 用户确保添加了 `extra_hosts`

### 问题 2：端口冲突

**症状**：
```
Error: Port 18789 is already in use
```

**解决**：
1. 修改 GUI 端口：`-e GUI_PORT=18796`
2. 确保只映射 GUI 端口，不映射 Gateway 端口

### 问题 3：认证失败

**症状**：
```
401 Unauthorized
```

**解决**：
1. 设置 API Token：`-e OPENCLAW_API_TOKEN=your-token`
2. 检查外部 OpenClaw 的认证配置

---

## 架构说明

```
┌─────────────────┐
│  AI Court GUI   │
│  (Docker 容器)   │
│  Port: 18795    │
└────────┬────────┘
         │
         │ HTTP API
         │
         ▼
┌─────────────────┐
│  OpenClaw       │
│  Gateway        │
│  Port: 18789    │
└─────────────────┘
```

**外部 OpenClaw 模式下**：
- ✅ AI Court 只运行 GUI
- ✅ 不启动内部 Gateway
- ✅ 不占用 18789 端口
- ✅ 连接到指定的外部 OpenClaw

---

## 相关文档

- [OpenClaw 文档](https://docs.openclaw.ai)
- [AI Court GitHub](https://github.com/wanikua/ai-court-skill)
- [Docker 网络文档](https://docs.docker.com/network/)
