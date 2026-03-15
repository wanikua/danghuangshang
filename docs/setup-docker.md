# 🐳 路径 B：Docker 部署

> ⏱️ 预计耗时：5 分钟 | 有 Docker 经验的用户首选，不污染系统环境
>
> ← [返回 README](../README.md) | 前置：[领服务器（可选）](./server-setup.md)

---

## 快速启动

预构建镜像支持 **amd64 + arm64**。

```bash
# 1. 克隆项目
git clone https://github.com/wanikua/boluobobo-ai-court-tutorial.git
cd boluobobo-ai-court-tutorial

# 2. 启动容器
docker compose up -d

# 3. 交互式初始化（选模式、填 Key、配平台，一步到位）
docker exec -it ai-court init-court

# 4. 重启使配置生效
docker compose restart

# 查看日志
docker compose logs -f

# 升级
docker compose pull && docker compose up -d
```

> 💡 也可以跳过初始化脚本，手动编辑配置：`cp openclaw.example.json openclaw.json && nano openclaw.json`

> ⚠️ **Windows / Git Bash 用户注意**：Git Bash 的 MSYS 会把 `/init-docker.sh` 转换为 Windows 路径导致报错。请用以下方式之一：
> ```bash
> # 推荐：使用不带 / 前缀的别名（不会被 MSYS 转换）
> docker exec -it ai-court init-court
>
> # 或：禁用路径转换
> MSYS_NO_PATHCONV=1 docker exec -it ai-court /init-docker.sh
>
> # 或：用 bash -c 包裹
> docker exec -it ai-court bash -c /init-docker.sh
> ```

## 镜像信息

- Docker Hub：`boluobobo/ai-court:latest`（国内推荐，可配镜像加速）
- GitHub：`ghcr.io/wanikua/boluobobo-ai-court-tutorial:latest`
- 架构：linux/amd64 + linux/arm64
- 内含：Node.js 22 + OpenClaw + Chromium + GitHub CLI + Python + OpenViking
- 工作区和配置通过 volume 持久化，升级不丢数据

### 🔒 镜像安全说明

镜像是干净的运行环境，**不含任何隐私数据**：

| 包含 ✅ | 不包含 ❌ |
|---------|----------|
| Node.js 22 运行时 | API Key / Bot Token |
| OpenClaw 框架 | 个人配置文件 |
| Chromium 浏览器 | Git 历史 / commit 记录 |
| GitHub CLI + Python | memory 文件 / 对话记录 |
| 通用 Skill 模板（天气、GitHub、Notion 等） | 项目图片 / 证据文件 |
| 初始化脚本（创建 SOUL.md 等模板） | 任何用户数据 |

> 💡 你的 API Key、Bot Token、对话记录等全部通过 volume 挂载，不会打包进镜像。

## 端口

| 端口 | 用途 |
|------|------|
| 18789 | Gateway Dashboard |
| 18795 | 菠萝 GUI（可选） |

## 配置说明

配置文件里填 Discord Bot Token 或飞书 App ID/Secret 均可。Docker 模式支持所有平台。

```json
{
  "models": {
    "providers": {
      "your-provider": {
        "baseUrl": "https://api.your-provider.com",
        "apiKey": "你的API_KEY",
        "api": "openai",
        "models": [...]
      }
    }
  },
  "channels": {
    "discord": {
      "enabled": true,
      "groupPolicy": "open",
      "accounts": {
        "silijian": { "name": "司礼监", "token": "你的Bot_Token", "applicationId": "你的Application_ID", "groupPolicy": "open" }
      }
    }
  }
}
```

## 常用命令

```bash
docker compose up -d          # 启动
docker compose down           # 停止
docker compose logs -f        # 查看日志
docker compose pull && docker compose up -d  # 升级
docker compose exec court bash               # 进入容器
```

---

← [返回 README](../README.md)
