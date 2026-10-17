# 连接外部 Hermes Agent 配置指南

## 背景

danghuangshang 自 v3.7.0 起把 **Hermes Agent**(by Nous Research)作为 OpenClaw
的 **平行 runtime**:同一套 14 Agent 朝廷设定,你可以二选一跑,也可以两套
并存(各占不同端口)。

| 维度 | OpenClaw 路线 | Hermes 路线 |
|---|---|---|
| 语言 | Node.js | Python |
| 配置文件 | `~/.openclaw/openclaw.json` | `~/.hermes/config.yaml` + `.env` |
| Token 位置 | JSON 内 `channels.*.accounts.*.token` | `~/.hermes/.env` 环境变量 |
| 默认 GUI 端口 | 18795 | (Hermes 自己用 dashboard 端口,默认 8765) |
| Gateway 端口 | 18789 | 不暴露独立端口,统一进程 |
| 多 Bot 多 Agent | 原生 `agents.list[]` × `bindings[]` | 用 `personalities/` + `profiles/` |
| 14 Agent 朝廷 | ✅ 直接用 configs/* | ✅ 用 configs/hermes/personalities/* |
| 跨进程 sandbox | sandbox.mode=non-main | terminal.backend=docker/ssh/modal |

> 二者底层都是"messaging gateway + 多 channel 路由 + 工具调用"的同代架构,
> Hermes 自带 `hermes claw migrate` 把 `openclaw.json` 直接转 Hermes config。

---

## 快速开始

### 方式 1: 全新装 Hermes(推荐新用户)

```bash
# 1. 装 Hermes(自带 uv / Python 3.11 / Node / ripgrep / ffmpeg)
curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh | bash
source ~/.bashrc

# 2. 拷贝 danghuangshang 的 Hermes 模板
mkdir -p ~/.hermes
cp ~/clawd/danghuangshang/hermes.example.yaml ~/.hermes/config.yaml

# 3. 拷贝朝廷角色人设
mkdir -p ~/.hermes/personalities
cp ~/clawd/danghuangshang/configs/hermes/personalities/*.md ~/.hermes/personalities/

# 4. 配 token / API key
cp ~/clawd/danghuangshang/configs/hermes/env.example ~/.hermes/.env
$EDITOR ~/.hermes/.env

# 5. 跑起来
hermes setup           # 交互式补缺失字段
hermes                 # CLI 直接进 REPL
hermes gateway start   # 启动 Discord/Telegram/Feishu/Slack 多通道网关
```

### 方式 2: 从已有 OpenClaw 迁移

```bash
# 一键把 ~/.openclaw/openclaw.json 转成 Hermes config
hermes claw migrate

# 然后把 danghuangshang 的人设覆盖上去
cp ~/clawd/danghuangshang/configs/hermes/personalities/*.md ~/.hermes/personalities/
```

### 方式 3: 两套 runtime 并存

```bash
# OpenClaw 跑在 18789(原 gateway)
openclaw gateway start

# 另开终端,Hermes 跑在自己进程
hermes gateway start --port 8765
```

两者绑定不同 Discord Bot Token / 飞书 App 即可。同一 Bot 不要同时被两边接管。

---

## Token 与凭证(`.env`)

Hermes 不在 YAML 里写敏感字段,所有 token 走环境变量:

```env
# ===== LLM =====
OPENROUTER_API_KEY=
ANTHROPIC_API_KEY=
# 或自托管 OpenAI 兼容网关
OPENAI_BASE_URL=https://your-llm-provider-api-url
OPENAI_API_KEY=

# ===== Discord =====
DISCORD_BOT_TOKEN=
DISCORD_APPLICATION_ID=
DISCORD_ALLOWED_ROLES=  # 可选,限制只有特定 role 能 @

# ===== Telegram =====
TELEGRAM_BOT_TOKEN=

# ===== 飞书 =====
FEISHU_APP_ID=
FEISHU_APP_SECRET=

# ===== Slack =====
SLACK_APP_TOKEN=
SLACK_BOT_TOKEN=

# ===== WhatsApp =====
# 走 baileys,首次扫码登录
```

完整变量表见 [Hermes .env.example](https://github.com/NousResearch/hermes-agent/blob/main/.env.example)。

---

## 朝廷角色 → Hermes Personality 映射

OpenClaw 的 `agents.list[]` 在 Hermes 里对应 `~/.hermes/personalities/*.md`:

| OpenClaw agent.id | Hermes personality 文件 | 说明 |
|---|---|---|
| `silijian` | `silijian.md` | 司礼监(默认人设) |
| `neige` | `neige.md` | 内阁(prompt 优化 + 计划) |
| `duchayuan` | `duchayuan.md` | 都察院(代码审查) |
| `bingbu` | `bingbu.md` | 兵部(开发) |
| `hubu` | `hubu.md` | 户部(财务/分析) |
| `libu` | `libu.md` | 礼部(品牌/营销) |
| `gongbu` | `gongbu.md` | 工部(运维/部署) |
| `libu2` | `libu2.md` | 吏部(项目管理) |
| `xingbu` | `xingbu.md` | 刑部(法务/合规) |
| `hanlin_*` | `hanlin_*.md` | 翰林院 5 子角色 |

切换角色:`hermes` 进入 REPL 后 `/personality silijian` 即可。
默认走哪个见 `~/.hermes/config.yaml` 里 `personality:` 字段。

---

## Discord 接入对照

OpenClaw 一个 Discord Bot 对应一个 `accounts.*.token`,需要 `applicationId`。
Hermes 一个进程默认一个 Bot,跨多个 Bot 要开多个 Hermes profile:

```bash
# 默认 profile = ~/.hermes
hermes gateway start

# 第二个 Bot(都察院专用)用独立 profile
HERMES_HOME=~/.hermes-duchayuan hermes gateway start
```

每个 profile 有自己独立的 `.env` 和 `config.yaml`。
14 Agent 朝廷玩到极致就是 14 个 profile。多数人用单 profile + personality 切换就够。

---

## 验证连接

### 1. 健康检查

```bash
hermes doctor              # 全栈诊断(模型/工具/平台/skill)
hermes status              # 当前模型 / 网关 / channel 状态
hermes channels list       # 当前启用的消息平台
```

### 2. 看 dashboard

```bash
hermes dashboard           # 默认 http://localhost:8765
```

### 3. 看 Gateway 日志

```bash
hermes gateway logs --follow
```

---

## 故障排除

### 问题 1:`hermes` 命令找不到

```bash
# 安装脚本结束后没刷新 shell
source ~/.bashrc   # 或 ~/.zshrc

# 仍找不到 → 手动加 PATH
export PATH="$HOME/.hermes/bin:$PATH"
```

### 问题 2:Discord 网关启动报 `applicationId required`

```bash
# 必填
echo "DISCORD_APPLICATION_ID=YOUR_APP_ID" >> ~/.hermes/.env
hermes gateway restart
```

OpenClaw v2026.5.x(已测到 v2026.5.20)起、Hermes v0.13.x 起,Discord slash
命令注册都要 `applicationId`。danghuangshang `openclaw.example.json` 已对齐补全。

### 问题 3:模型 401 / 空回复

```bash
hermes model           # 列已配置的 provider
hermes model auth      # 看 token 是否有效
```

### 问题 4:OpenClaw 已存在,不想动现有进程

直接走"方式 3 并存",两套绑定不同 Bot Token 就好。
`hermes claw migrate` **只读** OpenClaw 配置生成 Hermes 配置,不会改原文件。

---

## 架构对比

```
                ┌──────── Discord / Telegram / Feishu / Slack ────────┐
                │                                                      │
        ┌───────▼───────┐                                       ┌─────▼──────┐
        │  OpenClaw GW  │                                       │ Hermes GW  │
        │   :18789      │                                       │  内置进程   │
        └───────┬───────┘                                       └─────┬──────┘
                │                                                      │
        ┌───────▼───────┐                                       ┌─────▼──────┐
        │ agents.list[] │                                       │ personality│
        │  × bindings[] │                                       │  × profile │
        └───────┬───────┘                                       └─────┬──────┘
                │                                                      │
                └────────► 同一套 14 Agent 朝廷设定 ◄──────────────────┘
```

**选哪个?**

- 你已经在跑 OpenClaw 多 Bot,且 14 Agent 跑得很满 → 留在 OpenClaw。
- 你要单进程跨 20 个平台(WhatsApp/Signal/Email/Google Chat …)→ Hermes。
- 你想 self-host Sandbox + RL 训练数据采集 → Hermes(自带 Atropos)。
- 你怕折腾,想点一下就跑 → install-lite.sh 选 OpenClaw,默认路线。

两套 runtime 项目都在持续更新,本项目长期同步两边新版本。

---

## 相关文档

- [Parallel 网页搜索（可选 MCP 工具）](./docs/parallel-search.md)
- [Hermes 官方文档](https://hermes-agent.nousresearch.com/docs/)
- [Hermes GitHub](https://github.com/NousResearch/hermes-agent)
- [OpenClaw 文档](https://docs.openclaw.ai)
- [danghuangshang README](./README.md)
- [配置模板说明](./PROJECTS.md)
