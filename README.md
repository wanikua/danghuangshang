[English Version](./README_EN.md) | [🏢 企业版 Become CEO (English)](https://github.com/wanikua/become-ceo) | [📚 完整文档](./docs/README.md)

<!-- SEO 关键词 / Keywords：三省六部、明朝、六部制、中书省、门下省、尚书省、司礼监、内阁、都察院、翰林院、兵部、户部、礼部、工部、刑部、吏部、AI朝廷、AI Agent、多Agent协作、人工智能管理、古代治国、现代管理、组织架构、OpenClaw、multi-agent、ancient-china -->

<p align="center">
  <img src="./images/boluobobo-mascot.png" alt="菠萝菠菠 mascot" width="120" />
</p>

# 🏛️ 三省六部 ✖️ OpenClaw

### 一行命令起王朝，三省六部皆AI。千里之外调百官，万事不劳御驾亲。

> **以明朝六部制为蓝本，用 [OpenClaw](https://github.com/openclaw/openclaw) 框架构建的多 Agent 协作系统。**
> 一台服务器 + OpenClaw = 一支 7×24 在线的 AI 朝廷。

<p align="center">
  <img src="https://img.shields.io/badge/架构灵感-三省六部制-gold?style=for-the-badge" />
  <img src="https://img.shields.io/badge/框架-OpenClaw-blue?style=for-the-badge" />
  <img src="https://img.shields.io/badge/Agent数-12+-green?style=for-the-badge" />
  <img src="https://img.shields.io/badge/OpenClaw_Skill生态-60+-orange?style=for-the-badge" />
  <img src="https://img.shields.io/badge/部署-5分钟-red?style=for-the-badge" />
</p>

<div align="center">

### 👑 一键当皇帝

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/wanikua/boluobobo-ai-court-tutorial/main/install.sh)
```

**一行命令，5 分钟，你就是皇上。** [→ 快速开始](#快速开始三步登基)

🏥 **安装遇到问题？** `bash <(curl -fsSL https://raw.githubusercontent.com/wanikua/boluobobo-ai-court-tutorial/main/doctor.sh)` — [诊断工具文档](./docs/doctor.md)

🤖 **不想看文档？** 把 [这段 Prompt](./docs/install-prompt.md) 丢给你的 AI 助手（Claude / ChatGPT / DeepSeek），让它一步步带你装。

</div>

<p align="center">
  <img src="./images/flow-architecture.png" alt="系统架构流程图" width="80%" />
</p>

<p align="center">
  <img src="./images/discord-architecture.png" alt="Discord 朝廷架构图" width="80%" />
</p>

---

## 目录

| | 章节 | 说明 |
|:---:|------|------|
| 📜 | [这个项目是什么？](#这个项目是什么) | 项目介绍、设计理念、核心能力 |
| 🆚 | [为什么选这套方案？](#为什么选这套方案) | 与 ChatGPT / AutoGPT / CrewAI 对比 |
| 🏗️ | [技术架构](#技术架构) | 三省六部映射、架构图 |
| 🎬 | [效果展示](#效果展示) | Discord 真实对话示例 |
| 🚀 | [**快速开始**](#快速开始) | **← 从这里开始安装** |
| | ├─ [Linux 服务器安装](#第一步一键部署5-分钟) | 一键脚本，5分钟搞定 |
| | ├─ [macOS 本地安装](#第一步一键部署5-分钟) | Homebrew 自动安装 |
| | ├─ [精简安装（已有 OpenClaw）](#第一步一键部署5-分钟) | 只初始化配置 |
| | ├─ [填 Key 上线](#第二步填-key-上线10-分钟) | API Key + Discord Bot Token |
| | └─ [全六部上线](#第三步全六部上线-自动化15-分钟) | 测试 + 配置自动化 |
| 🍍 | [实战案例：菠萝王朝](#实战案例菠萝王朝) | 14 Agent 真实运行架构 |
| 🏛️ | [朝廷架构详解](#朝廷架构三省六部制) | 历史背景、角色对照、多模型混搭 |
| 📝 | [翰林院 — AI 小说创作](#翰林院--ai-小说创作) | 5 Agent 协作写小说，自动写作+审核+归档 |
| ⚙️ | [核心能力详解](#核心能力) | 协作、记忆、Skill、Cron、沙箱 |
| 🖥️ | [GUI 管理界面](#gui-管理界面) | Web Dashboard + Discord + Notion |
| ❓ | [常见问题](#常见问题) | 基础 + 技术 FAQ |
| 🏢 | [企业版 Become CEO](#想要企业版) | 同架构的英文企业版 |
| 🔗 | [相关链接 & 社区](#加入朝会) | 小红书、公众号、微信群 |

---

## 这个项目是什么？

**AI 朝廷**是一个开箱即用的多 AI Agent 协作系统。你是皇帝，AI 是你的大臣——每位大臣各司其职：写代码的、管财务的、搞营销的、做运维的——你只需要在 Discord 或飞书里下一道「圣旨」（@某个 Agent），大臣们就会立刻执行。

古代三省六部制运行超过 1300 年，是人类历史上最久经考验的组织架构之一。它的核心设计——**职责分明、流程标准化、权力制衡、档案留存**——完美映射到现代多 Agent 系统。**古代治国的智慧，就是管理 AI 团队的最佳实践。**

### 核心能力

| 能力 | 描述 |
|------|------|
| **多 Agent 协作** | 10+ 独立 AI Agent，各有专长，@谁谁回复 |
| **独立记忆** | 每个 Agent 有独立工作区和 memory 文件，越用越懂你 |
| **60+ Skill 生态** | GitHub、Notion、浏览器、Cron、TTS 等开箱即用 |
| **自动化任务** | Cron 定时 + 心跳自检，7×24 无人值守 |
| **多平台支持** | Discord / 飞书 / Slack / Telegram / 纯 WebUI |
| **沙箱隔离** | Docker 容器隔离，Agent 代码执行互不干扰 |
| **Web 管理后台** | React Dashboard，可视化管理一切 |

> 📖 **深入了解** → [架构详解](./docs/architecture.md) | [与 ChatGPT/AutoGPT/CrewAI 对比](./docs/architecture.md)

---

## 效果展示

### Discord 模式 — 频道内公开派活

```
👑 皇帝：@司礼监 帮朕写个用户登录 API，再查一下这个月花了多少钱

🏛️ 司礼监：遵旨！臣安排各部：
  → @兵部 编写用户登录 REST API（Node.js + Express），完成后提交 GitHub
  → @户部 统计本月 API 支出明细，给出优化建议

🏛️ 兵部：臣领旨。
  📁 已创建 auth-api/ 项目结构
  ✅ POST /api/login — JWT 认证
  ✅ POST /api/register — 用户注册
  ✅ 已提交至 GitHub：wanikua/auth-api#1
  臣已完工，请陛下御览。

🏛️ 户部：臣领旨。本月 API 总计 $23.47
  ├── 兵部（强力模型）：$15.20
  ├── 礼部（快速模型）：$3.80
  └── 其他：$4.47  📊 环比 -12%
  建议：兵部可优化 Prompt 长度，预计再省 15%。
```

> 💡 Discord 模式下，司礼监在频道里 @各部门派活，各部门独立回复，全过程公开可见。

### 飞书模式 — 司礼监后台调度

```
👤 你：帮我写个用户登录 API，再查一下这个月花了多少钱

🏛️ 司礼监：遵旨，臣已在后台安排兵部和户部处理。

  ……（兵部、户部在后台执行，用户无感）

🏛️ 司礼监：陛下，两项任务均已办妥：

  📌 兵部完成编码：
  ✅ auth-api/ 已创建，含登录 + 注册接口
  ✅ 已提交 GitHub：wanikua/auth-api#1

  📌 户部财务报告：
  💰 本月 API 总计 $23.47，环比 -12%
  建议优化兵部 Prompt 长度，预计再省 15%。
```

> 💡 飞书模式下，用户只和司礼监对话，司礼监通过 `sessions_spawn` 后台派活，汇总结果后统一回复。

---

## 快速开始（三步登基）

> 🔴 **新手请用云服务器**，不要在个人电脑上安装。详见 [安全须知](./docs/security.md)。

### 📍 第零步：已安装 OpenClaw？

> 已经在跑 OpenClaw 的老用户，不需要重新安装，用精简版脚本直接初始化朝廷工作区和配置模板：
> ```bash
> bash <(curl -fsSL https://raw.githubusercontent.com/wanikua/boluobobo-ai-court-tutorial/main/install-lite.sh)
> ```
> 跑完后跳到第三步填 Key 即可。**新用户请忽略，从第一步开始。**

### 📍 第一步：有服务器吗？

| 情况 | 操作 |
|------|------|
| ✅ 已有 Linux 服务器 | 直接进入第二步 |
| ✅ 已有 Mac | 直接进入第二步 |
| ❌ 没有服务器 | → [**领一台云服务器**](./docs/server-setup.md)（Oracle Cloud / 阿里云 / 腾讯云 / AWS 均可） |

### 📍 第二步：选平台

```
            你想用什么平台交互？
           ┌──────┼──────┐
           ▼      ▼      ▼
       Discord   飞书   纯浏览器
       海外首选  国内首选  极简体验
```

| 路径 | 平台 | 适合谁 | 部署方式 | 文档 |
|:---:|------|--------|----------|------|
| **A** | Discord | 海外用户 / 新手 | Linux 一键脚本 | [→ 路径 A](./docs/setup-linux-discord.md) |
| **B** | 通用 | 有 Docker 经验 | Docker 容器化 | [→ 路径 B](./docs/setup-docker.md) |
| **C** | 通用 | Mac 用户 | macOS Homebrew | [→ 路径 C](./docs/setup-macos.md) |
| **D** | 飞书 | 国内用户 | Linux 一键脚本 | [→ 路径 D](./docs/setup-feishu.md) |
| **E** | 纯 WebUI | 不需要 Bot | 只要 API Key | [→ 路径 E](./docs/setup-webui.md) |
| **W** | Discord/飞书 | Windows 用户 | WSL2 | [→ WSL2 指南](./docs/windows-wsl.md) |

> 💡 **不确定选哪个？** 国内用户选 **D**（飞书），海外用户选 **A**（Discord）。

### 📍 第三步：安装 → 填 Key → 启动

无论哪条路径，核心步骤都一样：

```bash
# 1️⃣ 一键安装（Linux 示例，其他路径见对应文档）
bash <(curl -fsSL https://raw.githubusercontent.com/wanikua/boluobobo-ai-court-tutorial/main/install.sh)

# 2️⃣ 填入 API Key 和 Bot Token
nano ~/.openclaw/openclaw.json

# 3️⃣ 启动
systemctl --user start openclaw-gateway
```

@你的 Bot 说句话，收到回复 = 登基成功！🎉

> 📖 **完整保姆级步骤** → [基础篇教程](./docs/tutorial-basics.md)（含服务器申请、SSH 连接、Discord Bot 创建）

---

### 📍 可选增强（安装完成后随时加）

| 增强项 | 说明 | 必选？ | 文档 |
|--------|------|--------|------|
| 📝 Notion 接入 | 自动日报/周报/知识库归档 | 可选 | [→ Notion 指南](./docs/notion-setup.md) |
| 🖥️ Web GUI | 可视化管理后台 | 可选 | [→ GUI 文档](./docs/gui.md) |
| ⏰ 定时任务 | Cron 自动执行 | 可选 | [→ 进阶篇](./docs/tutorial-advanced.md) |
| 🛡️ 安全加固 | Sandbox 沙箱配置 | 推荐 | [→ 安全须知](./docs/security.md) |
| 🏥 配置诊断 | 一键排查问题 | 遇到问题时 | [→ 诊断工具](./docs/doctor.md) |

---

## 实战案例：菠萝王朝

> 14 个 Agent，24/7 在线运转的真实生产系统。

```
                  ┌──────────────────┐
                  │  菠萝皇帝（你）  │
                  └─────────┬────────┘
              ┌─────────────┼─────────────┐
              ▼             ▼             ▼
         ┌────────┐    ┌────────┐    ┌────────┐
         │ 司礼监 │    │  内阁  │    │ 都察院 │
         │  调度  │    │  战略  │    │  审查  │
         └────┬───┘    └────┬───┘    └────┬───┘
              └─────────────┼─────────────┘
             ┌─────┬─────┬──┼──┬─────┬─────┐
             ▼     ▼     ▼     ▼     ▼     ▼
           兵部  户部  礼部  工部  刑部  吏部
           编码  财务  营销  运维  法务  管理
                            +
       国子监 · 翰林院 · 太医院 · 内务府 · 御膳房
```

| 自动化任务 | 频率 | 描述 |
|-----------|------|------|
| 每日简报 | 08:00 | 汇总 GitHub、天气、待办，推送到手机 |
| 盘前分析 | 工作日 09:15 | 户部拉取市场数据，生成报告 |
| 起居注 | 22:30 | 自动记录当日大事，写入 Notion |

**14 个 Agent，各有专属 Discord Bot，24/7 在线运转：**

| 机构 | Agent | 日常工作示例 |
|------|-------|-------------|
| 司礼监 | 大内总管 | 接收圣旨、分派任务、协调各部、Cron 调度 |
| 内阁 | 首辅大学士 | 商业战略分析、竞品研究、全局决策建议 |
| 都察院 | 左都御史 | 代码审查、质量把关、纠正各部错误 |
| 兵部 | 尚书 | 全栈开发、GitHub PR、系统架构、Bug 修复 |
| 户部 | 尚书 | 市场数据分析、API 成本追踪、财务报表 |
| 礼部 | 尚书 | 社媒运营、文案创作、品牌推广 |
| 工部 | 尚书 | 服务器运维、CI/CD、基础设施巡检 |
| 刑部 | 尚书 | 开源合规、知识产权维权、合同审查 |
| 吏部 | 尚书 | 项目管理、创业孵化、人事考核 |
| 国子监 | 祭酒 | 课程学习辅导、学习规划、知识整理 |
| 翰林院 | 学士 | 论文写作、读书笔记、技术文档 |
| 太医院 | 院使 | 健康提醒、饮食建议、运动计划 |
| 内务府 | 总管 | 日程管理、天气查询、出行提醒 |
| 御膳房 | 总管 | 美食推荐、食谱研究、外卖选择 |

### 自动化 Cron 任务（实际运行中）

| 任务 | 频率 | 描述 |
|------|------|------|
| 每日简报 | 每天 08:00 | 自动汇总 GitHub、天气、待办，推送到手机 |
| 市场盘前分析 | 工作日 09:15 | 户部自动拉取市场数据，生成分析报告，多渠道推送 |
| 起居注 | 每天 22:30 | 史官自动记录当日大事，写入 Notion 起居注数据库 |
| 礼部日报 | 每天 14:00 | 礼部汇报社媒运营数据 |

### Notion 史记式知识库

菠萝王朝使用 Notion 作为「国史馆」，完整存档所有决策和数据：

```
🏯 菠萝王朝
├── 本纪（时间线）
│   ├── 起居注（日报）    ← 每日自动写入
│   ├── 朔望录（周报）    ← 每周自动汇总
│   ├── 编年纪（月报）    ← 每月自动总结
│   └── 大事记            ← 里程碑事件
├── 表（数据看板）
│   ├── 食货表（财务）    ← 户部管理
│   ├── 舆情表（社媒）    ← 礼部管理
│   ├── 臣工表（人脉）    ← 吏部管理
│   └── 器用表（工具）    ← 工部管理
├── 志（知识库）
│   ├── 天工志（技术）    ← 兵部/工部
│   ├── 宣化志（运营）    ← 礼部
│   ├── 经籍志（学业）    ← 国子监
│   └── 典章志（SOP）     ← 各部流程
└── 列传（项目档案）
    └── 11个项目独立档案  ← 全生命周期管理
```

> 💡 **这不是 demo，是每天在用的生产系统。** 菠萝王朝已稳定运行数周，处理过数百个实际任务——从代码开发到内容运营，从数据分析到项目管理。

> 📖 **完整案例** → [菠萝王朝详解](./docs/pineapple-dynasty.md)

---

## 朝廷架构——三省六部制

### 历史背景

三省六部制是中国古代的中央官制体系：
- **中书省**：起草诏令（= 接收用户指令、生成计划）
- **门下省**：审核驳回（= 消息路由、权限校验）
- **尚书省**：执行落实（= Skill 工具层、实际执行）

尚书省下设**六部**，各管一摊。在本项目中，OpenClaw Gateway 扮演三省的角色，六个 AI Agent 对应六部：

| 部门 | 古代职责 | AI 职责 | 推荐模型 | 典型场景 |
|------|----------|---------|----------|----------|
| **司礼监** | 皇帝近侍、批红 | 总管调度 | 快速模型 | 日常对话、任务分配、自动汇报 |
| **兵部** | 军事武备 | 软件工程 | 强力模型 | 写代码、架构设计、代码审查、Bug 调试 |
| **户部** | 户籍财税 | 财务运营 | 强力模型 | 成本分析、预算管控、电商运营 |
| **礼部** | 礼仪外交 | 品牌营销 | 快速模型 | 文案创作、社媒运营、内容策划 |
| **工部** | 工程营造 | 运维部署 | 快速模型 | DevOps、CI/CD、服务器管理 |
| **吏部** | 官员选拔 | 项目管理 | 快速模型 | 创业孵化、任务追踪、团队协调 |
| **刑部** | 司法刑狱 | 法务合规 | 快速模型 | 合同审查、知识产权、合规检查 |

> 💡 模型分层策略：重活（编码/分析）用 强力模型，轻活（文案/管理）用 快速模型，能省 5 倍成本。也可以接入 经济模型 等国产模型进一步降本。

### 多 Provider 混搭（可选）

默认模板用单一 Provider，但你可以同时接入多家，给不同部门分配不同模型：

```json5
// openclaw.json 中的 models.providers 支持多个
{
  "models": {
    "providers": {
      "anthropic": {
        "baseUrl": "https://api.anthropic.com",
        "apiKey": "sk-ant-xxx",
        "api": "anthropic-messages",
        "models": [
          { "id": "claude-sonnet-4-5", "name": "Claude Sonnet 4.5", "input": ["text", "image"], "contextWindow": 200000, "maxTokens": 8192 }
        ]
      },
      "deepseek": {
        "baseUrl": "https://api.deepseek.com/v1",
        "apiKey": "sk-xxx",
        "api": "openai-completions",
        "models": [
          { "id": "deepseek-chat", "name": "DeepSeek V3", "input": ["text"], "contextWindow": 128000, "maxTokens": 8192 }
        ]
      }
    }
  }
}
```

然后在 `agents.list` 里按需分配：

```json5
{ "id": "bingbu", "model": { "primary": "anthropic/claude-sonnet-4-5" } },  // 重活用 Claude
{ "id": "libu",   "model": { "primary": "deepseek/deepseek-chat" } }        // 轻活用 DeepSeek 省钱
```

> 格式：`provider名/模型id`。支持任何兼容 OpenAI API 格式的服务商（Ollama、通义千问、Gemini 等），详见 [OpenClaw 模型配置文档](https://docs.openclaw.ai/concepts/models)。

---

## 翰林院 — AI 小说创作

翰林院是朝廷新增的**文学创作部门**，由 5 个 Agent 组成，专门负责 AI 小说创作的全流程：从需求拆解、架构设计、逐章写作、审核校对到归档管理。

### 翰林院架构

```
用户: "帮我写一部修仙小说"
  │
  └→ 掌院学士（接旨·总编排）
       │
       ├─ spawn 修撰 → 设计大纲 + 世界观 + 人物档案
       │    └─ spawn 庶吉士 → 检索参考素材
       │
       ├─ 掌院学士审批大纲 ✅
       │
       ├─ spawn 编修 → 按大纲逐章写作（每章 ≥ 10,000 字）
       │    ├─ spawn 庶吉士 → 查前文确保一致
       │    └─ 写完一章 → 归档到 novel/{书名}/
       │
       ├─ spawn 检讨 → 审核该章（7 维度 + 三级问题分级）
       │    └─ 发现问题 → 上报掌院学士
       │
       ├─ 掌院学士决策：退回编修修改 or 通过
       │
       └─ 循环直到全书完成 → 掌院学士全书终审
```

### 翰林院角色表

| Agent ID | 角色 | 品级 | 模型 | 职责 |
|----------|------|------|------|------|
| `hanlin_zhang` | 掌院学士 | 从二品 | strong | 总编排：接需求、拆任务、协调全院、全书终审 |
| `hanlin_xiuzhuan` | 修撰 | 从六品 | strong | 架构师：大纲、世界观、人物档案、多线叙事规划 |
| `hanlin_bianxiu` | 编修 | 正七品 | strong | 执笔者：逐章写作、分段创作法、归档 |
| `hanlin_jiantao` | 检讨 | 从七品 | fast | 审核官：文笔/逻辑/一致性审核，三级问题上报 |
| `hanlin_shujishi` | 庶吉士 | 无品 | fast | 检索员：搜索前文、查阅参考库、外部资料检索 |

### Spawn 权限链

- **司礼监** → 掌院学士
- **掌院学士** → 修撰、编修、检讨、庶吉士
- **修撰** → 庶吉士
- **编修** → 庶吉士
- **检讨、庶吉士** → 不可 spawn

### 翰林院专属 Skill

| Skill | 说明 | 使用者 |
|-------|------|--------|
| `novel-worldbuilding` | 小说架构设计：大纲、人物档案、世界观模板 | 修撰 |
| `novel-prose` | 小说写作技法：分段写作法、叙事规范、字数纪律 | 编修 |
| `novel-review` | 小说审核标准：7 维度评估、三级问题分级、报告模板 | 检讨、掌院学士 |
| `novel-archiving` | 章节归档：摘要生成、记忆更新、状态报告 | 编修 |
| `novel-research` | 深度调研：真实细节检索、逻辑推演、风格参考 | 庶吉士 |
| `novel-memory` | OpenViking 集成指南：三维记忆系统操作 | 全员 |

### OpenViking 集成（可选）

翰林院可选挂载 [OpenViking](https://github.com/openviking) 作为 MCP server，提供持久化记忆：

| OpenViking 模块 | 功能 | 使用场景 |
|----------------|------|---------|
| Memories | 静态知识 + 动态日志 | 章节摘要、角色状态、伏笔追踪 |
| Resources | 参考素材库 | 参考小说库、风格范本 |
| Skills | 结构化知识图谱 | 人物关系、世界设定 |

> OpenViking 的安装和配置不在本项目范围内，`skills/novel-memory/` 中提供使用指南。

---

## 核心能力

### 多 Agent 协作
每个部门是独立 Bot，@谁谁回复，@everyone 全员响应。大任务自动新建 Thread 保持频道整洁。
> ⚠️ 想让 Bot 之间互相触发（如成语接龙、多 Bot 讨论），需在 `openclaw.json` 的 `channels.discord` 中加上 `"allowBots": true`。不加的话 Bot 默认忽略其他 Bot 的消息。同时每个 account 都要设置 `"groupPolicy": "open"`，否则群聊消息会被静默丢弃。

### 独立记忆系统
每个 Agent 有独立的工作区和 `memory/` 目录。对话积累的项目知识会持久化到文件，跨会话保留。Agent 越用越懂你的项目。

### 60+ 内置 Skill（基于 OpenClaw 生态）
不只是聊天——内置的工具覆盖开发全流程，且可通过 [OpenClaw Hub](https://github.com/openclaw/openclaw) 扩展更多 Skill：

| 类别 | Skill |
|------|-------|
| 开发 | GitHub（Issue/PR/CI）、Coding Agent（代码生成与重构） |
| 文档 | Notion（数据库/页面/自动汇报） |
| 信息 | 浏览器自动化、Web 搜索、Web 抓取 |
| 自动化 | Cron 定时任务、心跳自检 |
| 媒体 | TTS 语音、截图、视频帧提取 |
| 运维 | tmux 远程控制、Shell 命令执行 |
| 通信 | Discord、Slack、飞书（Lark）、Telegram、WhatsApp、Signal… |
| 扩展 | OpenClaw Hub 社区 Skill、自定义 Skill |

### 定时任务（Cron）
内置 Cron 调度器，让 Agent 定时自动执行：
- 每天自动写日报，发到 Discord + 存到 Notion
- 每周汇总周报
- 定时健康检查、代码备份
- 自定义任意定时任务

### 好友协作
邀请朋友进 Discord 服务器，所有人都能 @各部门 Bot 下达指令。互不干扰，结果大家都能看到。

### 沙箱隔离
Agent 可以运行在 Docker 沙箱中，代码执行互不干扰。支持配置网络、文件系统、环境变量的隔离级别。

---

## GUI 管理界面

除了 Discord 命令行交互，AI 朝廷还提供多种图形界面（GUI）管理方式：

### Web 管理后台（菠萝王朝 Dashboard）

本项目内置了一套 Web 管理后台（`gui/` 目录），基于 React + TypeScript + Vite 构建：

<p align="center">
  <img src="./images/gui-court.png" alt="朝堂总览 — 各部门状态一目了然" width="90%" />
  <br/>
  <em>朝堂总览 — 御座、六部、诸院，在线状态一目了然</em>
</p>

<p align="center">
  <img src="./images/gui-sessions.png" alt="会话管理 — Token 消耗、消息统计" width="90%" />
  <br/>
  <em>会话管理 — 88 个会话、9008 条消息、87.34M Token 消耗实时追踪</em>
</p>

功能包括：
- **仪表盘**：实时查看各部门状态、Token 消耗、系统负载
- **朝堂**：直接在 Web 端与各部门 Bot 对话
- **会话管理**：查看所有历史会话、消息详情、Token 统计
- **定时任务**：可视化管理 Cron 任务（启用/禁用/手动触发）
- **Token 统计**：按部门、按日期的 Token 消耗分析
- **系统健康**：CPU/内存/磁盘监控、Gateway 状态

**启动方式：**
```bash
# 1. 先 clone 教程仓库（如果还没有）
git clone https://github.com/wanikua/boluobobo-ai-court-tutorial.git
cd boluobobo-ai-court-tutorial

# 2. 构建前端
cd gui && npm install && npm run build

# 3. 安装后端依赖并启动（设置登录密码）
cd server && npm install
BOLUO_AUTH_TOKEN=你的密码 node index.js
```

> ⚠️ **登录密码说明**：启动后端时通过环境变量 `BOLUO_AUTH_TOKEN` 设置登录密码。打开页面后用这个密码登录。如果不想要密码验证，需要修改 `server/index.js` 中的 `authMiddleware`。

访问地址：`http://你的服务器IP:18790`

> 💡 生产环境建议通过 Nginx 反向代理 + HTTPS 访问，不要直接暴露端口。长期运行建议用 `pm2` 或 `screen`：`BOLUO_AUTH_TOKEN=你的密码 pm2 start server/index.js --name boluo-gui`

### Discord 作为 GUI

Discord 本身就是最佳的 GUI 管理界面：
- **手机 + 电脑**同步，随时随地管理
- **频道分类**天然对应各部门（兵部、户部、礼部…）
- **消息历史**永久保存，自带搜索
- **权限管理**精细控制谁能看什么、谁能操作什么
- **@mention** 即可调用任意 Agent，零学习成本

### Notion 作为数据可视化补充

通过 OpenClaw 的 Notion Skill 集成，朝廷的数据可以自动同步到 Notion：
- **起居注（日报）**、**朔望录（周报）**自动生成
- **食货表（财务）**自动记录 API 消耗
- **列传（项目）**追踪各项目进展
- Notion 的看板、日历、表格视图提供丰富的数据可视化

> 💡 三层 GUI 配合使用：**Web Dashboard** 看系统状态 → **Discord** 下达指令 → **Notion** 查看报表和历史数据。

---

## 详细教程

基础篇（服务器申请→安装→配置→跑起来）和进阶篇（tmux、GitHub、Notion、Cron、Discord、Prompt 技巧）见小红书系列笔记。

---

## 📱 接入飞书（Feishu/Lark）

除了 Discord，AI 朝廷也支持飞书作为交互界面。飞书插件已内置在新版 OpenClaw 中，无需额外安装。

### 第一步：创建飞书应用

1. 访问 [飞书开放平台](https://open.feishu.cn/app)，登录后点击 **创建企业自建应用**
2. 填写应用名称和描述，选择图标
3. 在 **凭证与基础信息** 页面，复制 **App ID**（格式 `cli_xxx`）和 **App Secret**

### 第二步：配置权限和能力

1. **添加权限**：进入 **权限管理**，点击 **批量导入**，粘贴以下内容：
```json
{
  "scopes": {
    "tenant": [
      "im:message", "im:message:send_as_bot", "im:message:readonly",
      "im:message.p2p_msg:readonly", "im:message.group_at_msg:readonly",
      "im:resource", "im:chat.members:bot_access",
      "im:chat.access_event.bot_p2p_chat:read"
    ]
  }
}
```

2. **开启机器人能力**：进入 **应用能力 > 机器人**，启用并设置机器人名称

3. **配置事件订阅**：进入 **事件订阅**，选择 **使用长连接接收事件（WebSocket）**，添加事件 `im.message.receive_v1`

> ⚠️ 配置事件订阅前，需要先完成下面第三步并启动 Gateway，否则长连接可能保存失败。

4. **发布应用**：在 **版本管理与发布** 中创建版本，提交审核发布

### 第三步：配置 OpenClaw

**方式一：命令行向导（推荐）**
```bash
openclaw channels add
# 选择 Feishu，输入 App ID 和 App Secret
```

**方式二：手动编辑配置文件**
```json5
{
  "channels": {
    "feishu": {
      "enabled": true,
      "dmPolicy": "pairing",
      "accounts": {
        "main": {
          "appId": "cli_xxx",
          "appSecret": "你的App Secret"
        }
      }
    }
  }
}
```

### 第四步：启动并测试

```bash
# 启动/重启 Gateway
openclaw gateway restart

# 在飞书里找到你的机器人，发一条消息
# 首次会收到配对码，执行以下命令批准：
openclaw pairing approve feishu <配对码>
```

批准后即可正常聊天。群聊中需要 @机器人 才会触发回复。

> 💡 飞书使用 WebSocket 长连接，**不需要公网IP或域名**，本地部署也能用。
>
> 📖 完整飞书文档：[docs.openclaw.ai/channels/feishu](https://docs.openclaw.ai/channels/feishu)

---

## 📝 接入 Notion（自动归档）

AI 朝廷可以通过 Notion Skill 自动写日报、归档数据、管理知识库。配置只需 3 步。

### 第一步：创建 Notion Integration

1. 访问 [Notion Integrations](https://www.notion.so/profile/integrations)
2. 点击 **New integration**（新建集成）
3. 填写名称（如「AI 朝廷」），选择关联的 Workspace
4. 创建后复制 **Internal Integration Secret**（格式 `ntn_xxx` 或 `secret_xxx`）

### 第二步：存储 API Key

```bash
# 创建配置目录并保存 Key
mkdir -p ~/.config/notion
echo "ntn_你的token" > ~/.config/notion/api_key
```

### 第三步：授权页面/数据库

这一步**很关键**，不做的话 API 会返回 404：

1. 打开你想让 AI 访问的 Notion 页面或数据库
2. 点击右上角 **`···`** → **Connect to**（连接到）
3. 选择你刚创建的 Integration 名称
4. 子页面会自动继承权限

> ⚠️ **每个要访问的顶级页面/数据库都需要手动授权一次**，Integration 不会自动获得整个 Workspace 的权限。

### 验证

```bash
# 测试 API 是否通了
NOTION_KEY=$(cat ~/.config/notion/api_key)
curl -s "https://api.notion.com/v1/users/me" \
  -H "Authorization: Bearer $NOTION_KEY" \
  -H "Notion-Version: 2025-09-03" | head -c 200
```

看到返回的 JSON 包含你的 Integration 名称就说明配置成功了。

### 使用示例

配好后就可以在 Discord 里让 Agent 操作 Notion：

```
@司礼监 把今天的工作总结写到 Notion 日报里
@户部 创建一个新的财务数据库，字段包含日期、收入、支出、备注
@礼部 把这周的社媒数据更新到 Notion 舆情表
```

> 💡 Notion 适合做**持久化存档**（日报/周报/知识库），Discord 适合做**实时交互**，两者配合效果最佳。
>
> 📖 Notion API 文档：[developers.notion.com](https://developers.notion.com)

---

## 🏥 配置诊断（doctor.sh）

遇到问题？跑一行命令自动检查配置：

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/wanikua/boluobobo-ai-court-tutorial/main/doctor.sh)
```

诊断内容包括：
- ✅ OpenClaw/Node.js 安装检查
- ✅ 配置文件格式和 API Key 检查
- ✅ Discord Bot Token、allowBots、groupPolicy 检查
- ✅ Agent 和 Binding 路由匹配检查
- ✅ 工作区文件（SOUL.md / USER.md / memory/）检查
- ✅ Notion 等可选集成检查
- ✅ **@everyone 不触发的完整排查清单**

### @everyone 不触发 Bot 回复？

这是最常见的问题，通常原因是 **Discord Developer Portal 的 Intent 没开**：

1. 打开 [Discord Developer Portal](https://discord.com/developers/applications)
2. 选择你的 Bot → 左侧 **Bot** 页面
3. 往下翻到 **Privileged Gateway Intents**，开启以下三项：
   - ✅ **Message Content Intent**（必须）
   - ✅ **Server Members Intent**（必须）
   - ✅ **Presence Intent**（可选）
4. **每个 Bot 都要开**，不是只开一个！
5. 确认服务器里每个 Bot 的角色有 **View Channels** 权限
6. 确认配置文件里 `channels.discord.groupPolicy` 和每个 account 的 `groupPolicy` 都是 `"open"`

> ⚠️ 改完 Intent 后需要**重启 Gateway**：`openclaw gateway restart` 或 `systemctl --user restart openclaw-gateway`

---

## 常见问题

**Q: 需要会写代码吗？**
→ 不需要。一键脚本安装，配置填 Key，Discord 里自然语言交互。

**Q: 和直接用 ChatGPT 有什么区别？**
→ ChatGPT 是单通才，关掉就失忆。这里是多专家，各有记忆和工具，能自动提交 GitHub、写 Notion、跑定时任务。


**Q: @everyone 不触发回复？**
→ 每个 Bot 要开 Message Content Intent + Server Members Intent。详见 [诊断工具](./docs/doctor.md)。

**Q: Agent 报「只读文件系统」？**
→ sandbox mode 导致的。不跑代码的部门设 `"sandbox": { "mode": "off" }`。详见 [安全须知](./docs/security.md)。

> 📖 **完整 FAQ** → [常见问题](./docs/faq.md)

---

## 企业版：Become CEO

喜欢现代企业风格？同一架构，用 CEO/CTO/CFO 代替朝廷六部：

👉 **[Become CEO](https://github.com/wanikua/become-ceo)** — 同框架，企业角色，英文版

---

## 加入朝会

| 小红书「菠萝菠菠🍍」 | 公众号「菠言菠语」 | 微信群 |
|:---:|:---:|:---:|
| <a href="https://www.xiaohongshu.com/user/profile/5a169df34eacab2bc9a7a22d"><img src="./images/avatar-xiaohongshu.png" width="150" style="border-radius:50%"/></a> | <img src="./images/qr-wechat-official.jpg" width="150"/> | <img src="./images/qr-wechat-group.png" width="150"/> |
| [@菠萝菠菠🍍](https://www.xiaohongshu.com/user/profile/5a169df34eacab2bc9a7a22d) | 关注获取最新教程 | 群二维码过期请关注公众号 |

## 🤝 推荐

- 🎁 [MiniMax Coding Plan](https://platform.minimaxi.com/subscribe/coding-plan?code=CIeSxc2iq2&source=link) — 88折专属优惠 + Builder 权益

## 相关链接

- 🏢 [Become CEO — 企业版（English）](https://github.com/wanikua/become-ceo)
- 🎭 [AI 朝廷 Skill — 中文版](https://github.com/wanikua/ai-court-skill)
- 🔧 [OpenClaw 框架](https://github.com/openclaw/openclaw)
- 📖 [OpenClaw 官方文档](https://docs.openclaw.ai)
- 📚 [完整文档目录](./docs/README.md)

---

## ⚠️ 维权声明

本项目于 **2026年2月22日** 首发（[小红书推广帖更早于2月20日](https://www.xiaohongshu.com/discovery/item/6998638f000000000d0092fe?source=webshare)），是「三省六部制 × AI 多智能体」概念的原创项目。完整证据链见 [GitHub Issue](https://github.com/cft0808/edict/issues/55) | [维权文章](https://mp.weixin.qq.com/s/erVkoANrpZQFawMCNn6p9g)。欢迎 fork 和二次开发，请尊重开源精神，注明出处。

> 📕 小红书原创系列：[用AI当上皇帝的第3天](https://www.xiaohongshu.com/discovery/item/6998638f000000000d0092fe) | [赛博皇帝的日常](https://www.xiaohongshu.com/discovery/item/69a95dc3000000002801e886)

---

## 🛡️ 安全须知

> 详细配置见 [安全须知文档](./docs/security.md)

- 🔴 **不要在个人电脑上安装**——用云服务器，出问题随时重建
- 🔴 **workspace 设专用目录**（如 `/home/ubuntu/clawd`），不要设成家目录
- 🔴 **API Key 不要提交到公开仓库**

---

## 免责声明

本项目按"原样"提供，不承担任何直接或间接责任。AI 生成内容仅供参考，使用前请自行审核。涉及财务、安全敏感操作请务必人工复核。详见 [安全须知](./docs/security.md)。

---

## 🔄 已安装？一键更新

> 💡 放心跑，不会覆盖你的 SOUL.md、USER.md、IDENTITY.md 和 openclaw.json 等已有配置。

```bash
# 重跑安装脚本（自动保留你的配置）
bash <(curl -fsSL https://raw.githubusercontent.com/wanikua/boluobobo-ai-court-tutorial/main/install.sh)

# Docker 用户
docker pull boluobobo/ai-court:latest && docker compose up -d

# 手动更新
npm update -g openclaw && systemctl --user restart openclaw-gateway
```

---

v3.5.1 | MIT License | [User Agreement](./docs/user-agreement.md) | [Privacy Policy](./docs/privacy-policy.md)

> 📜 Licensed under MIT. Derivative works please credit: [boluobobo-ai-court-tutorial](https://github.com/wanikua/boluobobo-ai-court-tutorial) by [@wanikua](https://github.com/wanikua)
