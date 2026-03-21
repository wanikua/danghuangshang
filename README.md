[English Version](./README_EN.md) | [🏢 企业版 Become CEO (English)](https://github.com/wanikua/become-ceo) | [📚 完整文档](./docs/README.md)

> **⚠️ 维权声明 / Originality Notice**
>
> 本项目是「三省六部 × OpenClaw」架构的 **首发作品**，架构设计、角色功能映射、目录结构均为本项目原创。时间线：
> - **2025-02-20**：小红书首发教程
> - **2025-02-22**：GitHub 完整教程发布
>
> **📋 已知侵权**：[Edict](https://github.com/cft0808/edict) 项目结构与本项目高度相似，未注明引用任何出处。经多次沟通，作者拒绝标注原创出处。
>
> 🔗 [原创证据链 & 维权文章](./docs/originality.md)

>
> **🤝 欢迎共创**：本项目是MIT License，欢迎 PR 贡献、Fork 二次开发。但请**注明出处**并保留License。
> 这是开源社区的基本礼仪，也是对每一位贡献者的尊重。


<!-- SEO 关键词 / Keywords：三省六部、明朝、六部制、司礼监、内阁、都察院、翰林院、兵部、户部、礼部、工部、刑部、吏部、AI朝廷、AI Agent、多Agent协作、人工智能管理、古代治国、现代管理、组织架构、OpenClaw、multi-agent、ancient-china -->

<p align="center">
  <img src="./images/boluobobo-mascot.png" alt="菠萝菠菠 mascot" width="120" />
</p>

# 🏛️ 当皇上 ✖️ OpenClaw

### 一行命令起王朝，三省六部皆AI。千里之外调百官，万事不劳御驾亲。

> **以明朝内阁制为蓝本，用 [OpenClaw](https://github.com/openclaw/openclaw) 框架构建的多 Agent 协作系统。**
> 一台服务器 + OpenClaw = 一支 7×24 在线的 AI 朝廷。

<p align="center">
  <img src="https://img.shields.io/badge/架构-明朝内阁制-gold?style=for-the-badge" />
  <img src="https://img.shields.io/badge/框架-OpenClaw-blue?style=for-the-badge" />
  <img src="https://img.shields.io/badge/Agent-18+-green?style=for-the-badge" />
  <img src="https://img.shields.io/badge/Skill-60+-orange?style=for-the-badge" />
  <img src="https://img.shields.io/badge/部署-5分钟-red?style=for-the-badge" />
</p>

<div align="center">

### 👑 一键登基

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/wanikua/danghuangshang/main/scripts/full-install.sh)
```

**一行命令，5 分钟，你就是皇上。** [→ 快速开始](#快速开始)

</div>

> ### ⚠️ **Discord 多 Bot 安全配置**（必读）
> 
> **默认配置已安全**：新版安装脚本已设置 `"allowBots": "mentions"`，Bot 只在被 @ 时响应其他 Bot，避免消息循环。
> 
> **如果你使用旧版配置**：请确保 Discord 配置中有：
> ```json
> "discord": {
>   "allowBots": "mentions"  // ✅ 只响应被 @ 的 Bot
> }
> ```
> 
> **⚠️ 禁止使用 `"allowBots": true`** — 会导致 Bot 互相触发，引发消息风暴！
> 
> 📖 详细说明：[Discord 安全配置指南](./docs/discord-safety.md) | 相关 Issue：[#107](https://github.com/wanikua/danghuangshang/issues/107)

<p align="center">
  <img src="./images/flow-architecture.png" alt="系统架构流程图" width="80%" />
</p>

<p align="center">
  <img src="./images/discord-architecture.png" alt="Discord 朝廷架构图" width="80%" />
</p>

---

**AI 朝廷**是一个开箱即用的多 Agent 协作系统。你是皇帝，AI 是你的大臣。在 Discord 或飞书 @某个 Agent，大臣们就会立刻执行。司礼监接旨、内阁优化 Prompt、六部各司其职、都察院自动审查代码。**管理 AI 团队的高效模版。**

## 目录

- 🚀 [**快速开始**](#快速开始) — 3 步安装
- 🏛️ [朝廷架构](#朝廷架构) — 明朝内阁制：皇帝→司礼监→内阁→六部→都察院
- 🎬 [效果展示](#效果展示) — Discord / 飞书 对话示例
- 📝 [翰林院](#翰林院) — 5 Agent 协作写小说（可选）
- ⚙️ [核心能力](#核心能力) — 协作、记忆、60+ Skill、Cron、沙箱
- 🆚 [为什么选这套方案？](#为什么选这套方案) — 与 ChatGPT / AutoGPT / CrewAI 对比
- 📦 [更多](#更多) — GUI · 飞书 · Notion · 诊断 · FAQ · 企业版 · 菠萝王朝

---

<a id="快速开始"></a>

## 🚀 快速开始

> 🔴 **新手请用云服务器**，不要在个人电脑上安装。[→ 领一台免费服务器](./docs/server-setup.md)

### 1️⃣ 选择制度

安装时可选择三种制度：

| 制度 | 特点 | 适用场景 | Agent |
|------|------|---------|-------|
| **明朝内阁制** | 司礼监 + 内阁 + 六部，快速迭代 | 个人项目 | 18 个 |
| **唐朝三省制** | 中书→门下→尚书，制衡审核 | 偏好严谨流程的项目 | 14 个 |
| **现代企业制** | CEO/CTO/CFO，国际化 | 创业团队 | 14 个 |

### 2️⃣ 一键安装

**Linux / macOS**:
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/wanikua/danghuangshang/main/install.sh)
```

**Windows (PowerShell)**:
```powershell
powershell -ExecutionPolicy Bypass -File (New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/wanikua/danghuangshang/main/install.ps1')
```

**已有 OpenClaw？精简版**:
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/wanikua/danghuangshang/main/install-lite.sh)
```

### 3️⃣ 配置 + 启动

**2. 按提示填入** LLM API Key + Discord Bot Token

**3. 在 Discord @你的 Bot 说话** — 完成！

### 🔄 切换制度

安装后想切换制度？运行：

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/wanikua/danghuangshang/main/scripts/switch-regime.sh)
```

或手动选择：
```bash
bash scripts/switch-regime.sh tang-sansheng  # 唐朝三省制
bash scripts/switch-regime.sh modern-ceo     # 现代企业制
bash scripts/switch-regime.sh ming-neige     # 明朝内阁制
```

> **⚠️ 更新安全提示**
> 
> 更新代码前，请先备份重要文件：
> ```bash
> cd ~/clawd
> tar -czf ../clawd_backup_$(date +%Y%m%d).tar.gz \
>   SOUL.md IDENTITY.md USER.md MEMORY.md memory/
> ```
> 
> 更新命令：
> ```bash
> cd ~/clawd
> git stash          # 暂存本地修改
> git pull           # 拉取最新代码
> git stash pop      # 恢复本地修改（可能有冲突需手动解决）
> ```
> 
> **系统会自动备份配置文件（`~/.openclaw/openclaw.json`），但工作区文件（如 MEMORY.md）需手动备份。**

> 🏥 遇到问题？
> - Linux/macOS: `bash <(curl -fsSL https://raw.githubusercontent.com/wanikua/danghuangshang/main/doctor.sh)`
> - Windows: `openclaw doctor`
>
> 🤖 不想看文档？把 [这段 Prompt](./docs/install-prompt.md) 丢给 AI 助手，让它带你装

---

<a id="朝廷架构"></a>

## 🏛️ 朝廷架构

本项目提供 **三种制度** 供选择，各有侧重：

| 制度 | 特点 | 流程 |
|------|------|------|
| **明朝内阁制**（默认） | 司礼监 + 内阁二元调度 | 司礼监接旨 → 内阁优化 → 六部执行 |
| **唐朝三省制** | 三权分立、互相制衡 | 中书起草 → 门下审核 → 尚书执行 |
| **现代企业制** | 扁平管理、英文沟通 | CEO 决策 → Board 审议 → CxO 执行 |

> 💡 下方先展示明朝内阁制（默认），唐朝三省制和现代企业制请展开下方折叠查看。

**方式一：经司礼监调度（默认）**

```
皇帝（你）下旨
  ▼
司礼监（大内总管）── 接旨
  │
  ├─→ 内阁（首辅）── Prompt 增强：理解意图、引导追问、生成执行计划
  │ ←─┘ 返回优化后的 Prompt + Plan
  │
  ├─→ @兵部 @户部 @礼部 …（按 Plan 派发）
  │
  └─→ 都察院 ── 代码 push 到 GitHub 时自动审查
       └─→ ✅ 通过 / ❌ 打回修改
```

**方式二：皇帝直接下旨给任意部门**（Discord 多 Bot 模式）

```
皇帝（你）
  ├─→ @兵部 写个登录 API        ← 直接指挥，跳过司礼监
  ├─→ @户部 查本月开销
  └─→ @都察院 审查这个 PR
```

> 💡 Discord 多 Bot 模式下，每个部门都是独立 Bot，你可以直接 @任意部门下达指令，无需经过司礼监。复杂任务推荐走司礼监（自动内阁优化），简单任务直接 @对应部门更快。

<details>
<summary><b>查看完整机构表</b></summary>

| 机构 | 角色 | 在本项目中 |
|------|------|-----------|
| **司礼监** | 大内总管 | 接旨 → 送内阁优化 → 派发六部 |
| **内阁** | 首辅大学士 | Prompt 增强、追问、生成计划、重大决策审议 |
| **都察院** | 左都御史 | GitHub push 自动代码审查 |
| **兵部** | 尚书 | 软件工程：编码、架构、Bug 调试 |
| **户部** | 尚书 | 财务运营：成本分析、预算管控 |
| **礼部** | 尚书 | 品牌营销：文案、社媒运营 |
| **工部** | 尚书 | 运维：DevOps、CI/CD |
| **吏部** | 尚书 | 项目管理、团队协调 |
| **刑部** | 尚书 | 法务合规、知识产权 |

**与明朝制度的映射：**

| 明朝 | 本项目 |
|------|--------|
| 皇帝下旨 → 司礼监批红 | 用户 @司礼监 → 接旨调度 |
| 内阁票拟（起草方案） | 内阁 Prompt 增强 + Plan |
| 司礼监代批（下发执行） | 用优化后 Prompt 派发六部 |
| 都察院纠劾百官 | GitHub push 自动审查 |
| 内阁封驳权 | 内阁可否决不合理方案 |

</details>
---

<details>
<summary><b>唐朝三省制（tang-sansheng）</b></summary>

**中书起草 → 门下审核 → 尚书执行**，三权分立、互相制衡。适合需要严谨审批流程的企业级场景。

**方式一：三省流转（默认）**

```
皇帝（你）下旨
  ▼
中书省 ── 起草诏令（理解意图、生成执行方案）
  ▼
门下省 ── 审核驳回（审查方案可行性、合规性）
  │
  ├─ ❌ 封驳 → 退回中书省修改
  └─ ✅ 通过 ▼
         尚书省 ── 执行派发
           ├─→ @兵部 编码开发
           ├─→ @户部 财务分析
           ├─→ @工部 运维部署
           ├─→ @礼部 品牌营销
           ├─→ @吏部 项目管理
           └─→ @刑部 法务合规
                  ▼
               御史台 ── 监察审计（全程监督、代码审查）
```

**方式二：皇帝直接下旨给任意部门**

```
皇帝（你）
  ├─→ @中书省 拟一份新产品方案
  ├─→ @兵部 修复这个 Bug
  └─→ @御史台 审查这个 PR
```

> 💡 三省制的核心是制衡：中书省负责"想"，门下省负责"审"，尚书省负责"做"。任何重大决策都要经过三省流转，避免一家独大。

| 唐朝三省 | Agent ID | 职责 |
|----------|----------|------|
| **中书省** | `zhongshu` | 起草方案、Prompt 增强、生成执行计划 |
| **门下省** | `menxia` | 审核方案、封驳不合理决策 |
| **尚书省** | `shangshu` | 接收通过的方案、派发六部执行 |
| **御史台** | `yushitai` | 全程监察、代码审查、质量把控 |
| **兵部** | `bingbu` | 软件工程、系统架构 |
| **户部** | `hubu` | 财务分析、成本管控 |
| **工部** | `gongbu` | DevOps、服务器运维 |
| **礼部** | `libu` | 品牌营销、内容创作 |
| **吏部** | `libu2` | 项目管理、团队协调 |
| **刑部** | `xingbu` | 法务合规、知识产权 |
| **史官** | `shiguan` | 自动记录每日朝政摘要 |

</details>

<details>
<summary><b>现代企业制（modern-ceo）</b></summary>

**CEO 决策 → Board 审议 → CxO 执行**，扁平化管理、英文沟通。适合国际化团队或偏好现代企业架构的用户。

**方式一：经 CEO 调度（默认）**

```
Owner (You)
  ▼
CEO ── Receive task, delegate to C-suite
  │
  ├─→ Board of Directors ── Strategic review & approval
  │ ←─┘ Approve / Reject / Request changes
  │
  ├─→ @CTO  Technical execution (code, architecture)
  ├─→ @CFO  Financial analysis (budget, cost)
  ├─→ @CMO  Marketing (brand, content, social)
  ├─→ @COO  Operations (DevOps, infrastructure)
  ├─→ @CLO  Legal & compliance
  └─→ @CoS  Project coordination
         ▼
      QA Director ── Quality assurance & code review
```

**方式二：直接指挥（Direct command）**

```
Owner (You)
  ├─→ @CTO Build a login API
  ├─→ @CFO Review this month's spending
  └─→ @QA  Review this PR
```

> 💡 Modern CEO mode uses English for all communication. The CEO acts as dispatcher (like 司礼监), the Board provides strategic oversight (like 内阁), and QA handles quality control (like 都察院).

| Role | Agent ID | Responsibility |
|------|----------|---------------|
| **CEO** | `ceo` | Task intake, delegation, progress tracking |
| **Board** | `board` | Strategic review, budget approval, veto power |
| **QA Director** | `qa` | Code review, quality assurance |
| **CTO** | `cto` | Engineering, architecture, technical decisions |
| **CFO** | `cfo` | Financial analysis, cost optimization |
| **CMO** | `cmo` | Marketing, brand, content creation |
| **COO** | `coo` | Operations, DevOps, infrastructure |
| **CLO** | `clo` | Legal compliance, IP protection |
| **Chief of Staff** | `cos` | Project management, team coordination |

</details>



---

<a id="效果展示"></a>

<details>
<summary><h2>🎬 效果展示</h2></summary>

### Discord 模式

```
👑 皇帝：@司礼监 帮朕写个用户登录 API，再查一下这个月花了多少钱

🏛️ 司礼监：遵旨！臣先请内阁优化任务……
  → @内阁 请首辅审阅此旨，拟定执行计划。

📜 内阁：臣已拟票。
  【任务一】@兵部 — 编写用户登录 REST API（Node.js + Express + JWT）
  【任务二】@户部 — 本月 API 支出分析（分部门明细 + 优化建议）

🏛️ 司礼监：内阁拟票已收，开始派发！
  → @兵部 …（优化后的完整 Prompt）
  → @户部 …

🏛️ 兵部：✅ 已提交 GitHub：wanikua/auth-api#1

🔍 都察院：代码审查 ✅ 通过 | ⚠️ 建议添加 rate limiting

🏛️ 户部：本月 $23.47，环比 -12%，建议优化兵部 Prompt 省 15%。
```

> 皇帝下旨 → 司礼监接旨 → **内阁优化** → 司礼监派发 → **都察院审查**。全流程公开可见。

### 飞书模式

```
👤 你：帮我写个用户登录 API，再查一下这个月花了多少钱

🏛️ 司礼监：遵旨，臣先请内阁拟票……

  ……（内阁优化 → 派发 → 执行 → 审查，用户无感）

🏛️ 司礼监：陛下，已办妥：
  📌 兵部：auth-api 已创建，都察院审查通过 ✅
  📌 户部：本月 $23.47，环比 -12%
```

> 飞书模式：用户只和司礼监对话，后台自动走完整流程。

</details>

---

<a id="翰林院"></a>

<details>
<summary><h2>📝 翰林院 — AI 小说创作（可选）</h2></summary>

5 个 Agent 协作写小说：掌院学士（总编排）→ 修撰（架构）→ 编修（写作）→ 检讨（审核）→ 庶吉士（检索）。

```
用户: "帮我写一部修仙小说"
  └→ 掌院学士（总编排）
       ├─ spawn 修撰 → 大纲 + 世界观 + 人物档案
       ├─ 掌院审批 ✅
       ├─ spawn 编修 → 逐章写作（每章 ≥ 10,000 字）
       ├─ spawn 检讨 → 7 维度审核
       └─ 循环至全书完成 → 终审
```

| Agent | 角色 | 职责 |
|-------|------|------|
| `hanlin_zhang` | 掌院学士 | 接需求、拆任务、协调、终审 |
| `hanlin_xiuzhuan` | 修撰 | 大纲、世界观、人物档案 |
| `hanlin_bianxiu` | 编修 | 逐章写作、归档 |
| `hanlin_jiantao` | 检讨 | 文笔/逻辑/一致性审核 |
| `hanlin_shujishi` | 庶吉士 | 搜索前文、检索资料 |

</details>

---

<a id="核心能力"></a>

<details>
<summary><h2>⚙️ 核心能力</h2></summary>

| 能力 | 说明 |
|------|------|
| **多 Agent 协作** | 18+ 独立 Bot，@谁谁回复，@everyone 全员响应 |
| **内阁前置优化** | 用户指令自动经内阁 Prompt 增强后再派发 |
| **都察院自动审查** | 代码 push 到 GitHub 自动触发代码审查 |
| **独立记忆** | 每个 Agent 独立工作区 + memory，越用越懂你 |
| **60+ Skill** | GitHub、Notion、浏览器、Cron、TTS…… |
| **定时任务** | 自动写日报/周报、健康检查、代码备份 |
| **沙箱隔离** | Docker 容器隔离，Agent 代码执行互不干扰 |
| **多平台** | Discord / 飞书 / Slack / Telegram / WebUI |

### 60+ 内置 Skill

| 类别 | Skill |
|------|-------|
| 开发 | GitHub（Issue/PR/CI）、Coding Agent |
| 文档 | Notion（数据库/页面/自动汇报） |
| 信息 | 浏览器自动化、Web 搜索、Web 抓取 |
| 自动化 | Cron 定时任务、心跳自检 |
| 媒体 | TTS 语音、截图、视频帧提取 |
| 运维 | tmux 远程控制、Shell 命令执行 |
| 通信 | Discord、Slack、飞书、Telegram… |
| 扩展 | [OpenClaw Hub](https://github.com/openclaw/openclaw) 社区 Skill |

</details>

---

<a id="更多"></a>

<details>
<summary><h2>🖥️ GUI 管理界面</h2></summary>

内置 Web Dashboard（`gui/` 目录），React + TypeScript + Vite：

<p align="center">
  <img src="./images/gui-court.png" alt="朝堂总览" width="90%" />
  <br/><em>朝堂总览 — 御座、六部、诸院，在线状态一目了然</em>
</p>

<p align="center">
  <img src="./images/gui-sessions.png" alt="会话管理" width="90%" />
  <br/><em>会话管理 — Token 消耗、消息统计实时追踪</em>
</p>

功能：仪表盘 · 朝堂对话 · 会话管理 · Cron 可视化 · Token 统计 · 系统健康监控

```bash
cd danghuangshang/gui && npm install && npm run build
cd server && npm install
BOLUO_AUTH_TOKEN=你的密码 node index.js
# 访问 http://你的服务器IP:18795
```

> 三层 GUI：**Web Dashboard** 看状态 → **Discord** 下指令 → **Notion** 查报表

</details>

<details>
<summary><h2>📱 接入飞书</h2></summary>

飞书插件已内置，无需额外安装。

1. [飞书开放平台](https://open.feishu.cn/app) 创建应用，复制 App ID + Secret
2. 开启机器人能力，添加事件 `im.message.receive_v1`（WebSocket 长连接）
3. `openclaw channels add` 选 Feishu，填入凭证
4. `openclaw gateway restart`，在飞书 @机器人 测试

> 飞书用 WebSocket，**不需要公网 IP**。详见 [docs.openclaw.ai/channels/feishu](https://docs.openclaw.ai/channels/feishu)

</details>

<details>
<summary><h2>📝 接入 Notion</h2></summary>

1. [Notion Integrations](https://www.notion.so/profile/integrations) 创建集成，复制 Secret
2. `mkdir -p ~/.config/notion && echo "ntn_xxx" > ~/.config/notion/api_key`
3. 在 Notion 页面点 **··· → Connect to** 授权
4. 在 Discord：`@司礼监 把今天的工作总结写到 Notion 日报里`

</details>

<details>
<summary><h2>🧠 记忆备份</h2></summary>

Agent 的记忆是长期积累的资产，丢失不可逆。内置备份脚本，一行命令守护所有 Agent 记忆。

**备份内容：** 18 个 Agent 的 SQLite 记忆数据库 + 工作区记忆文件 + 核心配置

```bash
# 立即备份
bash scripts/memory-backup.sh

# 查看现有备份
bash scripts/memory-backup.sh -l

# 从备份恢复
bash scripts/memory-backup.sh -s daily/2026-03-15.tar.gz

# 预览（不实际执行）
bash scripts/memory-backup.sh --dry-run
```

**自动定时备份（推荐）：**

```bash
# 每天凌晨 3 点自动备份
(crontab -l 2>/dev/null; echo "0 3 * * * $HOME/danghuangshang/scripts/memory-backup.sh -q") | crontab -
```

| 策略 | 保留周期 | 说明 |
|------|----------|------|
| 每日备份 | 7 天 | 自动清理过期 |
| 每周备份 | 4 周 | 每周日自动归档 |
| 每月备份 | 6 个月 | 每月 1 号自动归档 |

> 使用 `sqlite3 .backup` 保证数据库一致性，备份期间不影响 Agent 正常运行。

</details>

<details>
<summary><h2>🏥 配置诊断</h2></summary>

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/wanikua/danghuangshang/main/doctor.sh)
```

**@everyone 不触发？** → 每个 Bot 都要开 Message Content Intent + Server Members Intent（[Discord Developer Portal](https://discord.com/developers/applications) → Bot 页面 → Privileged Gateway Intents）

**Bot 回复触发 @everyone 通知？** → 服务器设置 → 角色 → @everyone → 关闭「提及 @everyone」权限（Owner 不受影响）

</details>

<details>
<summary><h2>❓ 常见问题</h2></summary>

**Q: 能用其他模型吗？** → 能。支持 Anthropic、OpenAI、Gemini、DeepSeek 等，不同部门可用不同模型。

**Q: 每月费用？** → 轻度 $10-15，中度 $20-30。重活用强模型、轻活用快模型可省 5 倍。

**Q: 和 Become CEO 的关系？** → [Become CEO](https://github.com/wanikua/become-ceo) 是英文企业版，同架构，CTO/CFO 代替六部。

> 📖 [完整 FAQ](./docs/faq.md)

</details>

<details>
<summary><h2>🆚 为什么选这套方案？</h2></summary>

| | ChatGPT 等 | AutoGPT / CrewAI | **AI 朝廷** |
|---|---|---|---|
| 多 Agent | ❌ 单通才 | ✅ 需写 Python | ✅ 配置文件，零代码 |
| 记忆 | ⚠️ 单一 | ⚠️ 需接向量库 | ✅ 每 Agent 独立 memory |
| 工具 | ⚠️ 有限 | ⚠️ 需开发 | ✅ 60+ Skill |
| 界面 | 网页 | CLI | ✅ Discord 原生 |
| 部署 | 无需 | Docker + 编码 | ✅ 一键脚本 |
| 24h 在线 | ❌ | ✅ | ✅ Cron + 心跳 |

**核心优势：不是框架，是成品。** 跑个脚本就能用，在 Discord 里 @谁谁回复。

> 📖 [架构详解](./docs/architecture.md) | [与 ChatGPT/AutoGPT/CrewAI 对比](./docs/architecture.md)

</details>

<details>
<summary><h2>🏢 企业版 Become CEO</h2></summary>

同架构，CEO/CTO/CFO 代替朝廷六部：

👉 **[Become CEO](https://github.com/wanikua/become-ceo)**

| 朝廷 | 企业 |
|:---:|:---:|
| 司礼监 | COO |
| 内阁 | CSO |
| 都察院 | QA VP |
| 兵部 | CTO |
| 户部 | CFO |
| 礼部 | CMO |

</details>

<details>
<summary><h2>🍍 实战案例：菠萝王朝</h2></summary>

18 个 Agent，24/7 运行的真实生产系统。

```
🏯 菠萝王朝
├── 本纪（时间线）：起居注·朔望录·编年纪·大事记
├── 表（看板）：食货表·舆情表·臣工表·器用表
├── 志（知识库）：天工志·宣化志·经籍志·典章志
└── 列传（项目档案）：11 个项目全生命周期
```

> 📖 [菠萝王朝详解](./docs/pineapple-dynasty.md)

</details>

---

## 加入朝会

| 小红书「菠萝菠菠🍍」 | 公众号「菠言菠语」 | 微信群 |
|:---:|:---:|:---:|
| <a href="https://www.xiaohongshu.com/user/profile/5a169df34eacab2bc9a7a22d"><img src="./images/avatar-xiaohongshu.png" width="150" style="border-radius:50%"/></a> | <img src="./images/qr-wechat-official.jpg" width="150"/> | ![8e02d54f8ec2145c9592ffd1fadb2068](https://github.com/user-attachments/assets/eb4daaba-d531-46cd-a3f4-789223752a34)
 |

<details>
<summary>相关链接 · 安全须知 · 免责声明</summary>

**相关链接**
- 🏢 [Become CEO — 企业版](https://github.com/wanikua/become-ceo) · 🔧 [OpenClaw 框架](https://github.com/openclaw/openclaw) · 📖 [OpenClaw 文档](https://docs.openclaw.ai) · 📚 [完整文档](./docs/README.md)
- 🎁 [MiniMax Coding Plan](https://platform.minimaxi.com/subscribe/coding-plan?code=CIeSxc2iq2&source=link) — 88折优惠

**安全须知** — 🔴 用云服务器，不要个人电脑 · workspace 设专用目录 · API Key 不提交公开仓库 · [详见](./docs/security.md)

**免责声明** — 按"原样"提供，AI 生成内容仅供参考，敏感操作请人工复核。[详见](./docs/security.md)

</details>

---

**🔄 已安装？一键更新：** `bash <(curl -fsSL https://raw.githubusercontent.com/wanikua/danghuangshang/main/install.sh)` · Docker：`docker pull boluobobo/ai-court:latest && docker compose up -d`

v3.5.3 | MIT License | [User Agreement](./docs/user-agreement.md) | [Privacy Policy](./docs/privacy-policy.md)

> 📜 Licensed under MIT. Credit: [danghuangshang](https://github.com/wanikua/danghuangshang) by [@wanikua](https://github.com/wanikua)
