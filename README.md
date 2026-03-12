[English Version](./README_EN.md) | [🏢 企业版 Become CEO (English)](https://github.com/wanikua/become-ceo) | [📚 完整文档](./docs/README.md)

<!-- SEO 关键词 / Keywords：三省六部、明朝、六部制、中书省、门下省、尚书省、司礼监、内阁、都察院、翰林院、兵部、户部、礼部、工部、刑部、吏部、AI朝廷、AI Agent、多Agent协作、人工智能管理、古代治国、现代管理、组织架构、OpenClaw、multi-agent、ancient-china -->

<p align="center">
  <img src="./images/boluobobo-mascot.png" alt="菠萝菠菠 mascot" width="120" />
</p>

# 🏛️ 三省六部 ✖️ OpenClaw

### 一行命令起王朝，三省六部皆AI。千里之外调百官，万事不劳御驾亲。

> **以明朝三省六部制为蓝本，用 [OpenClaw](https://github.com/openclaw/openclaw) 框架构建的多 Agent 协作系统。**
> 一台服务器 + OpenClaw = 一支 7×24 在线的 AI 朝廷。

<p align="center">
  <img src="https://img.shields.io/badge/架构灵感-三省六部制-gold?style=for-the-badge" />
  <img src="https://img.shields.io/badge/框架-OpenClaw-blue?style=for-the-badge" />
  <img src="https://img.shields.io/badge/Agent数-10+-green?style=for-the-badge" />
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

</div>

<p align="center">
  <img src="./images/flow-architecture.png" alt="系统架构流程图" width="80%" />
</p>

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
              │   菠萝皇帝（你）  │
              └────────┬─────────┘
       ┌───────────────┼───────────────┐
       ▼               ▼               ▼
   ┌────────┐    ┌──────────┐    ┌────────┐
   │ 司礼监 │    │   内阁   │    │ 都察院 │
   │ 调度   │    │  战略    │    │  审查  │
   └───┬────┘    └──────────┘    └────────┘
       │
 ┌─────┼─────┬──────┬──────┬──────┐
 ▼     ▼     ▼      ▼      ▼      ▼
兵部  户部  礼部   工部   刑部   吏部
编码  财务  营销   运维   法务   管理
       +
 国子监 · 翰林院 · 太医院 · 内务府 · 御膳房
```

| 自动化任务 | 频率 | 描述 |
|-----------|------|------|
| 每日简报 | 08:00 | 汇总 GitHub、天气、待办，推送到手机 |
| 盘前分析 | 工作日 09:15 | 户部拉取市场数据，生成报告 |
| 起居注 | 22:30 | 自动记录当日大事，写入 Notion |

> 📖 **完整案例** → [菠萝王朝详解](./docs/pineapple-dynasty.md)

---

## 常见问题

**Q: 需要会写代码吗？**
→ 不需要。一键脚本安装，配置填 Key，Discord 里自然语言交互。

**Q: 和直接用 ChatGPT 有什么区别？**
→ ChatGPT 是单通才，关掉就失忆。这里是多专家，各有记忆和工具，能自动提交 GitHub、写 Notion、跑定时任务。

**Q: 每月 API 费用？**
→ 轻度 $10-15，中度 $20-30。重活用强力模型，轻活用快速模型（省 5 倍）。

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
- 💡 不跑代码的部门 sandbox 设 `"off"`，跑代码的设 `"all"`

---

## 免责声明

本项目按"原样"提供，不承担任何直接或间接责任。AI 生成内容仅供参考，使用前请自行审核。涉及财务、安全敏感操作请务必人工复核。详见 [安全须知](./docs/security.md)。

---

v3.5.1 | MIT License

> 📜 Licensed under MIT. Derivative works please credit: [boluobobo-ai-court-tutorial](https://github.com/wanikua/boluobobo-ai-court-tutorial) by [@wanikua](https://github.com/wanikua)
