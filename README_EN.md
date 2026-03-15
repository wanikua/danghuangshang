[中文版](./README.md) | [🏢 Corporate Edition: Become CEO](https://github.com/wanikua/become-ceo) | [📚 Full Docs](./docs/README.md)

<!-- SEO Keywords: Three Departments and Six Ministries, Ming Dynasty, Six Ministries System, AI Court, AI Agent, Multi-Agent Collaboration, OpenClaw, multi-agent, ancient-china -->

<p align="center">
  <img src="./images/boluobobo-mascot.png" alt="Boluobobo mascot" width="120" />
</p>

# 🏛️ Three Departments & Six Ministries ✖️ OpenClaw

### One Command to Build a Dynasty. Six Ministries, All AI. Rule from Afar, Never Lift a Finger.

> **Modeled after the Ming Dynasty's Three Departments and Six Ministries (三省六部制), built on the [OpenClaw](https://github.com/openclaw/openclaw) framework.**
> One server + OpenClaw = A 24/7 AI imperial court at your command.

<p align="center">
  <img src="https://img.shields.io/badge/Inspired_By-Six_Ministries_System-gold?style=for-the-badge" />
  <img src="https://img.shields.io/badge/Framework-OpenClaw-blue?style=for-the-badge" />
  <img src="https://img.shields.io/badge/Agents-10+-green?style=for-the-badge" />
  <img src="https://img.shields.io/badge/OpenClaw_Skill_Ecosystem-60+-orange?style=for-the-badge" />
  <img src="https://img.shields.io/badge/Deploy-5_min-red?style=for-the-badge" />
</p>

<div align="center">

### 👑 Become Emperor in One Click

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/wanikua/danghuangshang/main/install.sh)
```

**One command. 5 minutes. You are the Emperor.** [→ Quick Start](#quick-start-three-steps-to-the-throne)

🏥 **Having issues?** `bash <(curl -fsSL https://raw.githubusercontent.com/wanikua/danghuangshang/main/doctor.sh)` — [Doctor Tool Docs](./docs/doctor.md)

🤖 **Don't want to read docs?** Give [this Prompt](./docs/install-prompt.md) to your AI assistant (Claude / ChatGPT / DeepSeek) and let it guide you step by step.

</div>

<p align="center">
  <img src="./images/flow-architecture.png" alt="System Architecture Flow" width="80%" />
</p>

---

## What Is This?

**AI Court** is a ready-to-use multi-AI-agent collaboration system. You are the Emperor 👑, AI agents are your ministers — each with a clear role: one writes code, one manages finances, one handles marketing, one runs DevOps — all you do is issue an "imperial decree" (@mention an agent in Discord or Feishu), and they execute immediately.

The Three Departments and Six Ministries system ran for over 1,300 years — one of the longest-running organizational frameworks in human history. Its core design principles — **clear separation of duties, standardized processes, checks and balances, record keeping** — map perfectly to modern multi-agent systems. **Ancient governance wisdom is the best practice for managing AI teams.**

### Core Capabilities

| Capability | Description |
|-----------|-------------|
| **Multi-Agent Collaboration** | 10+ independent AI Agents, each specialized, @mention to invoke |
| **Independent Memory** | Each agent has its own workspace and memory files |
| **60+ Skill Ecosystem** | GitHub, Notion, Browser, Cron, TTS and more, out of the box |
| **Automated Tasks** | Cron scheduling + heartbeat self-checks, 24/7 unattended |
| **Multi-Platform** | Discord / Feishu (Lark) / Slack / Telegram / Pure WebUI |
| **Sandbox Isolation** | Docker container isolation for agent code execution |
| **Web Dashboard** | React dashboard for visual management |

> 📖 **Deep dive** → [Architecture](./docs/architecture.md)

---

## Demo: Discord Conversations

```
👑 Emperor: @bingbu Write me a user login REST API with Node.js + Express

🏛️ War Ministry: As Your Majesty commands.
  📁 Created auth-api/ project structure
  ✅ POST /api/login — JWT authentication
  ✅ POST /api/register — User registration
  ✅ Pushed to GitHub: wanikua/auth-api#1

👑 Emperor: @hubu How much did we spend on APIs this month?

🏛️ Revenue Ministry: Your Majesty, total: $23.47
  ├── War Ministry (Power Model): $15.20
  ├── Rites Ministry (Fast Model): $3.80
  └── Others: $4.47  📊 Down 12% MoM

👑 Emperor: @libu Write a Xiaohongshu post recommending AI tool setups

🏛️ Rites Ministry: As you wish!
  📝 "Regular People Can Be AI Emperors? I Manage My Whole Team with 6 AIs"
  🏷️ #AITools #Productivity #MultiAgent #AICourt
```

---

## Quick Start (Three Steps to the Throne)

> 🔴 **Beginners: use a cloud server, not your personal computer.** See [Security Guide](./docs/security.md).

### 📍 Step 0: Already Have OpenClaw?

> Already running OpenClaw? No need to reinstall. Use the lite script to initialize the court workspace and config template:
> ```bash
> bash <(curl -fsSL https://raw.githubusercontent.com/wanikua/danghuangshang/main/install-lite.sh)
> ```
> Then skip to Step 3 to fill in your keys. **New users: ignore this, start from Step 1.**

### 📍 Step 1: Got a Server?

| Situation | Action |
|-----------|--------|
| ✅ Have a Linux server | Go to Step 2 |
| ✅ Have a Mac | Go to Step 2 |
| ❌ No server | → [**Get a free server**](./docs/server-setup.md) (Oracle Cloud: free 4-core 24GB) |

### 📍 Step 2: Choose Your Platform

| Path | Platform | Best For | Deploy Method | Docs |
|:---:|----------|----------|---------------|------|
| **A** | Discord | Global users / Beginners | Linux one-line script | [→ Path A](./docs/setup-linux-discord.md) |
| **B** | Any | Docker experienced | Docker container | [→ Path B](./docs/setup-docker.md) |
| **C** | Any | Mac users | macOS Homebrew | [→ Path C](./docs/setup-macos.md) |
| **D** | Feishu (Lark) | China users | Linux one-line script | [→ Path D](./docs/setup-feishu.md) |
| **E** | Pure WebUI | No Bot needed | Just API Key | [→ Path E](./docs/setup-webui.md) |
| **W** | Any | Windows users | WSL2 | [→ WSL2 Guide](./docs/windows-wsl.md) |

> 💡 **Not sure?** China users → **D** (Feishu). Global users → **A** (Discord).

### 📍 Step 3: Install → Add Keys → Start

```bash
# 1️⃣ One-line install (Linux example)
bash <(curl -fsSL https://raw.githubusercontent.com/wanikua/danghuangshang/main/install.sh)

# 2️⃣ Add API Key and Bot Token
nano ~/.openclaw/openclaw.json

# 3️⃣ Start
systemctl --user start openclaw-gateway
```

@mention your Bot, get a reply = you're on the throne! 🎉

> 📖 **Full step-by-step tutorial** → [Basics Tutorial](./docs/tutorial-basics.md) (Chinese)

---

### 📍 Optional Enhancements (Add anytime after install)

| Enhancement | Description | Required? | Docs |
|-------------|-------------|-----------|------|
| 📝 Notion | Auto daily/weekly reports | Optional | [→ Notion Guide](./docs/notion-setup.md) |
| 🖥️ Web GUI | Visual management dashboard | Optional | [→ GUI Docs](./docs/gui.md) |
| ⏰ Cron Tasks | Automated scheduling | Optional | [→ Advanced Tutorial](./docs/tutorial-advanced.md) |
| 🛡️ Security | Sandbox configuration | Recommended | [→ Security Guide](./docs/security.md) |
| 🏥 Diagnostics | One-click troubleshooting | When needed | [→ Doctor Tool](./docs/doctor.md) |

---

## Real-World Case: Boluo Dynasty

> 14 Agents, running 24/7, a real production system.

```
              ┌──────────────────┐
              │ Pineapple Emperor │
              └────────┬─────────┘
       ┌───────────────┼───────────────┐
       ▼               ▼               ▼
  Directorate    Grand Secretary    Censorate
  (Scheduler)    (Strategy)         (QA Review)
       │
 ┌─────┼─────┬──────┬──────┬──────┐
 ▼     ▼     ▼      ▼      ▼      ▼
War  Revenue Rites  Works  Justice Personnel
Code Finance  Mktg   Ops   Legal   Mgmt
       +
 Academy · Hanlin · Medical · Household · Kitchen
```

> 📖 **Full case study** → [Pineapple Dynasty](./docs/pineapple-dynasty.md)

---

## FAQ

**Q: Do I need to know how to code?**
→ No. One-line script installs everything. Natural language interaction in Discord.

**Q: How is this different from ChatGPT?**
→ ChatGPT = one generalist, forgets everything. This = multiple specialists with persistent memory, tools, and automation.

**Q: Monthly API cost?**
→ Light: $10-15. Moderate: $20-30. Use power models for heavy tasks, fast models for light tasks (5× savings).

**Q: @everyone doesn't trigger responses?**
→ Enable Message Content Intent + Server Members Intent for each Bot. See [Diagnostics](./docs/doctor.md).

> 📖 **Full FAQ** → [FAQ](./docs/faq.md)

---

## Corporate Edition: Become CEO

Prefer modern corporate style? Same architecture with CEO / CTO / CFO roles:

👉 **[Become CEO](https://github.com/wanikua/become-ceo)** — Same framework, corporate roles, English

---

## 🏛️ Join the Court

| Xiaohongshu (小红书) | WeChat Official: 菠言菠语 | WeChat Group |
|:---:|:---:|:---:|
| <a href="https://www.xiaohongshu.com/user/profile/5a169df34eacab2bc9a7a22d"><img src="./images/avatar-xiaohongshu.png" width="150" style="border-radius:50%"/></a> | <img src="./images/qr-wechat-official.jpg" width="150"/> | <img src="./images/qr-wechat-group.png" width="150"/> |
| [@菠萝菠菠🍍](https://www.xiaohongshu.com/user/profile/5a169df34eacab2bc9a7a22d) | Follow for tutorials | QR expired? Follow official account |

## 🤝 Recommendations

- 🎁 [MiniMax Coding Plan](https://platform.minimaxi.com/subscribe/coding-plan?code=CIeSxc2iq2&source=link) — Exclusive 12% discount + Builder benefits

## Related Links

- 🏢 [Become CEO — Corporate Edition](https://github.com/wanikua/become-ceo)
- 🎭 [AI Court Skill — Chinese](https://github.com/wanikua/ai-court-skill)
- 🔧 [OpenClaw Framework](https://github.com/openclaw/openclaw)
- 📖 [OpenClaw Official Documentation](https://docs.openclaw.ai)
- 📚 [Full Documentation Index](./docs/README.md)

---

## ⚠️ Originality & Rights Notice

This project was first published on **February 22, 2026**. Full evidence: [GitHub Issue](https://github.com/cft0808/edict/issues/55) | [Rights Article](https://mp.weixin.qq.com/s/erVkoANrpZQFawMCNn6p9g). Forks welcome — please credit the source.

---

## 🛡️ Security Guide

> Full details → [Security Guide](./docs/security.md)

- 🔴 **Don't install on personal computers** — use a cloud server
- 🔴 **Set workspace to a dedicated directory** (e.g., `/home/ubuntu/clawd`)
- 🔴 **Never commit API keys to public repos**
- 💡 Non-coding departments: sandbox `"off"`. Coding departments: sandbox `"all"`

---

## 🔄 Already Installed? One-Click Update

> 💡 Safe to run — won't overwrite your SOUL.md, USER.md, IDENTITY.md, or openclaw.json.

```bash
# Re-run install script (auto-preserves your config)
bash <(curl -fsSL https://raw.githubusercontent.com/wanikua/danghuangshang/main/install.sh)

# Docker users
docker pull boluobobo/ai-court:latest && docker compose up -d

# Manual update
npm update -g openclaw && systemctl --user restart openclaw-gateway
```

---

## Disclaimer

This project is provided "as is" without any warranties. AI-generated content is for reference only — review before production use. Human review required for financial/security-sensitive operations.

---

v3.5.1 | MIT License

> 📜 Licensed under MIT. Derivative works please credit: [danghuangshang](https://github.com/wanikua/danghuangshang) by [@wanikua](https://github.com/wanikua)
