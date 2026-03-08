[中文版](./README.md)

# 🏛️ Build Your AI Court in 30 Minutes

> One free server + [OpenClaw](https://github.com/openclawai/openclaw) = A 24/7 AI team at your command

Writing code, managing finances, running marketing campaigns, generating daily reports, handling DevOps — all you need to do is send a message in Discord.

![System Architecture](./images/flow-architecture.png)

> 📌 **About Originality** — This project was first committed on **2026-02-22** ([commit history](https://github.com/wanikua/boluobobo-ai-court-tutorial/commits/main)) and represents the original implementation of the concept "modeling AI multi-agent collaboration after China's imperial court system." We noticed that [cft0808/edict](https://github.com/cft0808/edict) (first committed 2026-02-23, approximately 21 hours later) shares striking similarities with this project in framework selection, SOUL.md persona files, install.sh deployment approach, and competitor comparison tables — see [Issue #55](https://github.com/cft0808/edict/issues/55) for details.
>
> **Reposts welcome — please credit the source.**
>
> 📕 Original Xiaohongshu series: [Day 3 of Being an AI Emperor — I'm Already Hooked](https://www.xiaohongshu.com/discovery/item/6998638f000000000d0092fe) | [Life of a Cyber Emperor: Give Orders Before Bed, AI Cranks Out Code Overnight](https://www.xiaohongshu.com/discovery/item/69a95dc3000000002801e886)

---

## Why This Setup?

| | ChatGPT & Web UIs | AutoGPT / CrewAI / MetaGPT | **AI Court (This Project)** |
|---|---|---|---|
| Multi-agent collaboration | ❌ Single generalist | ✅ Requires Python orchestration | ✅ Config files only, zero code |
| Persistent memory | ⚠️ Single shared memory | ⚠️ BYO vector database | ✅ Each agent has its own workspace + memory files |
| Tool integrations | ⚠️ Limited plugins | ⚠️ Build your own | ✅ 60+ built-in Skills (GitHub / Notion / Browser / Cron …) |
| Interface | Web | CLI / Self-hosted UI | ✅ Native Discord (works on phone & desktop) |
| Deployment difficulty | No deployment needed | Docker + coding required | ✅ One-line script, up in 5 minutes |
| 24h availability | ❌ Manual conversations only | ✅ | ✅ Cron jobs + heartbeat self-checks |

**The key advantage: it's not a framework — it's a finished product.** Run a script, start chatting in Discord by @mentioning your agents.

---

## Architecture

```
Discord Message
    ↓
OpenClaw Gateway (Node.js daemon)
    ├── Message routing: @mention → match binding → dispatch to agent
    ├── Session isolation: each agent has its own session & workspace
    ├── Auto-threading: large tasks automatically spawn Threads
    └── Cron scheduler: time-triggered agent tasks
         ↓
    ┌──────────────┐  ┌──────────────┐  ┌──────────────┐
    │ 兵部 bingbu  │  │ 户部 hubu    │  │ 礼部 libu    │  ... (extensible)
    │ Power Model  │  │ Power Model  │  │ Fast Model   │
    │ Code Expert  │  │ Finance Pro  │  │ Marketing Pro│
    └──────┬───────┘  └──────┬───────┘  └──────┬───────┘
           │                 │                  │
    ┌──────┴─────────────────┴──────────────────┴──────┐
    │              Skill Layer (60+)                    │
    │  GitHub · Notion · Browser · Cron                │
    │  TTS · Weather · Screenshots · Video …           │
    └──────────────────────────────────────────────────┘
```

Each agent is a standalone Discord Bot bound to its own AI identity:
- **Independent memory**: Every agent has its own `memory/` directory — the more you use it, the better it knows your projects
- **Independent models**: Use power models for heavy lifting, fast models for light work — save money without sacrificing quality
- **Sandboxed execution**: Agent code runs in isolation, no cross-contamination
- **Identity injection**: OpenClaw automatically assembles SOUL.md + IDENTITY.md + workspace files into the system prompt

---

## Quick Start

### Step 1: One-Line Deployment (5 minutes)

Grab a free cloud server (ARM 4-core, 24 GB RAM — free tier), SSH in, and run:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/wanikua/boluobobo-ai-court-tutorial/main/install.sh)
```

The script automatically handles:
- ✅ System updates + cloud provider firewall configuration
- ✅ 4 GB Swap (prevents OOM kills)
- ✅ Node.js 22 + GitHub CLI + Chromium
- ✅ Global OpenClaw installation
- ✅ Workspace initialization (SOUL.md / IDENTITY.md / USER.md / openclaw.json multi-agent template)
- ✅ Gateway systemd service (auto-starts on boot)

The install script features color-coded output with progress indicators and ✓ success markers for each step.

### Step 2: Add Your Keys (10 minutes)

After the script finishes, you just need two things:

1. **LLM API Key** → From your LLM provider's dashboard
2. **Discord Bot Token** (one per department) → [discord.com/developers](https://discord.com/developers/applications)

```bash
# Edit config — fill in API Key and Bot Tokens
nano ~/.openclaw/openclaw.json

# Start the court
systemctl --user start openclaw-gateway

# Verify
systemctl --user status openclaw-gateway
```

@mention your Bot in Discord and say something. If it replies, you're live.

### Step 3: Full Six Ministries + Automation (15 minutes)

```
@bingbu Write me a user login API
→ 兵部 bingbu (Power Model): Complete code + architecture suggestions, large tasks auto-spawn Threads

@hubu How much did we spend on APIs this month?
→ 户部 hubu (Power Model): Cost breakdown + optimization recommendations

@libu Write a Xiaohongshu post about AI tool recommendations
→ 礼部 libu (Fast Model): Copy + hashtag suggestions

@everyone Tomorrow's meeting at 3 PM — all departments prepare weekly reports
→ All agents acknowledge individually
```

Set up automated daily reports:
```bash
# Get the Gateway Token
openclaw gateway token

# Auto-generate daily report at 22:00 Beijing time
openclaw cron add \
  --name "Daily Report" --agent main \
  --cron "0 22 * * *" --tz "Asia/Shanghai" \
  --message "Generate today's daily report, write to Notion and post to Discord" \
  --session isolated --token <your-token>
```

![Court Architecture](./images/discord-architecture.png)

---

## Court Architecture — The Six Ministries

Inspired by the Ming Dynasty's six-ministry system, each "department" is an independent AI Agent + Discord Bot:

| Ministry | Role | Recommended Model | Typical Use Cases |
|----------|------|-------------------|-------------------|
| **司礼监 silijian** — Chief Steward | Central coordination | Fast Model | Daily chat, task delegation, automated reporting |
| **兵部 bingbu** — Engineering | Software engineering | Power Model | Coding, architecture design, code review, debugging |
| **户部 hubu** — Finance | Finance & operations | Power Model | Cost analysis, budgeting, e-commerce operations |
| **礼部 libu** — Marketing | Brand & marketing | Fast Model | Copywriting, social media, content strategy |
| **工部 gongbu** — DevOps | Infrastructure | Fast Model | DevOps, CI/CD, server management |
| **吏部 libu** — Projects | Project management | Fast Model | Startup incubation, task tracking, team coordination |
| **刑部 xingbu** — Legal | Legal & compliance | Fast Model | Contract review, intellectual property, compliance checks |

> 💡 Model tiering strategy: Use power models for heavy tasks (coding/analysis), fast models for light tasks (copywriting/management) — saves roughly 5× on costs. You can also plug in economy models for further savings.

---

## Core Capabilities

### 🤖 Multi-Agent Collaboration
Each department is its own Bot. @mention one and it responds; @everyone triggers all of them. Large tasks automatically spawn Threads to keep channels tidy.
> ⚠️ To enable Bot-to-Bot interactions (e.g., word chain games, multi-Bot discussions), add `"allowBots": true` in the `channels.discord` section of `openclaw.json`. Without this, Bots ignore messages from other Bots by default. Each account also needs `"groupPolicy": "open"`, otherwise group messages will be silently dropped.

### 🧠 Independent Memory System
Each agent has its own workspace and `memory/` directory. Project knowledge accumulated through conversations is persisted to files and retained across sessions. The more you use an agent, the better it understands your project.

### 🛠️ 60+ Built-in Skills
It's not just a chatbot — the built-in toolset covers the entire development lifecycle:

| Category | Skills |
|----------|--------|
| Development | GitHub (Issues/PRs/CI), Coding Agent |
| Documentation | Notion (databases/pages/automated reporting) |
| Information | Browser automation, Web search, Web scraping |
| Automation | Cron scheduled tasks, Heartbeat self-checks |
| Media | TTS voice, Screenshots, Video frame extraction |
| Operations | tmux remote control, Shell command execution |
| Communication | Discord, Slack, Telegram, WhatsApp, Signal… |

### ⏰ Scheduled Tasks (Cron)
Built-in Cron scheduler lets agents run tasks on autopilot:
- Auto-generate daily reports, post to Discord + save to Notion
- Weekly summary roll-ups
- Scheduled health checks and code backups
- Any custom recurring task you can think of

### 👥 Team Collaboration
Invite friends to your Discord server — everyone can @mention department Bots to issue commands. No interference between users, and results are visible to all.

### 🔒 Sandbox Isolation
Agents can run inside Docker sandboxes with isolated code execution. Supports configurable isolation levels for networking, filesystem, and environment variables.

---

## 🖥️ GUI Management Interface

Beyond Discord command-line interaction, the AI Court also offers multiple graphical interface (GUI) management options:

### Web Dashboard (Boluo Dynasty Dashboard)

This project includes a built-in Web management dashboard (in the `gui/` directory), built with React + TypeScript + Vite, providing:

- **📊 Dashboard**: Real-time view of department status, token consumption, system load
- **💬 Court Hall**: Chat directly with department Bots from the web interface
- **📋 Session Management**: Browse all historical sessions, message details, token stats
- **⏰ Cron Jobs**: Visual management of scheduled tasks (enable/disable/manual trigger)
- **📈 Token Analytics**: Token consumption breakdown by department and date
- **🔧 System Health**: CPU/memory/disk monitoring, Gateway status

**How to start:**
```bash
# Enter the GUI directory
cd gui/server

# Install dependencies
npm install

# Start the backend API server (default port 18790)
node index.js

# Build the frontend
cd .. && npm install && npm run build
```

Access at: `http://your-server-ip:18790`

> 💡 For production, use Nginx reverse proxy + HTTPS instead of exposing the port directly.

### Discord as GUI

Discord itself is the best GUI management interface:
- **Phone + Desktop** sync — manage from anywhere
- **Channel categories** naturally map to departments (bingbu, hubu, libu…)
- **Message history** permanently saved with built-in search
- **Permission management** with fine-grained control over who sees and does what
- **@mention** any agent to invoke it — zero learning curve

### Notion as Data Visualization

Through Notion Skill integration, court data auto-syncs to Notion:
- **Daily Reports** and **Weekly Summaries** auto-generated
- **Finance Tracking** automatically records API consumption
- **Project Archives** track progress across all projects
- Notion's kanban, calendar, and table views provide rich data visualization

> 💡 Three-tier GUI: **Web Dashboard** for system status → **Discord** for issuing commands → **Notion** for reports and historical data.

---

## Detailed Tutorials

For the basics (server provisioning → installation → configuration → first run) and advanced topics (tmux, GitHub, Notion, Cron, Discord, prompt engineering tips), check out the Xiaohongshu tutorial series.

---

## FAQ

### Basics

**Q: Do I need to know how to code?**
No. The one-line install script handles setup, and configuration is just filling in a few keys. All interaction happens through natural language in Discord.

**Q: Is the server really free?**
Cloud providers' free tiers (where available).

**Q: How is this different from just using ChatGPT?**
ChatGPT is a single generalist that forgets everything when you close the tab. This system gives you multiple specialists — each agent has its own domain expertise, persistent memory, and tool permissions. They can automatically commit code to GitHub, write docs to Notion, and run tasks on a schedule.

**Q: Can I use other models?**
Yes. OpenClaw supports various LLM providers, OpenAI, Google Gemini, and others (including economy models). Just change the model config in `openclaw.json`. Different departments can use different models.

**Q: How much does the API cost per month?**
Depends on usage intensity. Light usage: $10–15/month, moderate: $20–30/month. Cost-saving tip: use power models for heavy tasks, fast models for light tasks (roughly 5× cheaper), and plug in economy models for simple tasks to save even more.

### Technical

**Q: @everyone doesn't trigger agent responses?**
In the Discord Developer Portal, each Bot needs **Message Content Intent** and **Server Members Intent** enabled. The Bot's role in the server also needs View Channels permission. OpenClaw treats @everyone as an explicit mention for every Bot — once permissions are set correctly, it will trigger responses.

**Q: Agent reports permission errors after enabling sandbox?**
Sandbox mode set to `all` runs the agent inside a Docker container with a read-only filesystem, no network access, and no inherited environment variables by default. Fix:

```json
"sandbox": {
  "mode": "all",
  "workspaceAccess": "rw",
  "docker": {
    "network": "bridge",
    "env": { "LLM_API_KEY": "your-LLM-API-KEY" }
  }
}
```
- `workspaceAccess: "rw"` — Allows the sandbox to read/write the working directory
- `docker.network: "bridge"` — Enables network access
- `docker.env` — Passes in API keys (sandbox doesn't inherit host environment variables)

**Q: Will multiple users @mentioning the same agent cause conflicts?**
No. OpenClaw maintains independent sessions for each user × agent combination. Multiple people can @mention 兵部 bingbu simultaneously — their conversations won't interfere with each other.

**Q: Can agents call each other?**
Yes. Agents can use `sessions_spawn` to delegate sub-tasks to other agents, or `sessions_send` to message another agent's session. For example, 司礼监 (Chief Steward) can assign coding tasks to 兵部 bingbu.

**Q: How do I create custom Skills?**
OpenClaw has a built-in Skill Creator tool for creating custom Skills. Each Skill is a directory containing `SKILL.md` (instructions) + scripts + resources. Place it in the `skills/` directory of your workspace, and agents can use it immediately.

**Q: How do I connect private models (Ollama, etc.)?**
Add an OpenAI API-compatible provider in the `models.providers` section of `openclaw.json`, pointing `baseUrl` to your Ollama address. Local Ollama models have zero API costs.

**Q: How do I troubleshoot Gateway startup failures?**
```bash
# Check detailed logs
journalctl --user -u openclaw-gateway --since today --no-pager

# Run diagnostics
openclaw doctor

# Common causes: missing API Key, malformed JSON, invalid Bot Token
```

---

## 🏛️ Join the Court

| Xiaohongshu (小红书) | WeChat Official: 菠言菠语 | WeChat Group: OpenClaw Emperors |
|:---:|:---:|:---:|
| <a href="https://www.xiaohongshu.com/user/profile/5a169df34eacab2bc9a7a22d"><img src="https://img.shields.io/badge/小红书-Follow-FF2442?style=for-the-badge&logo=xiaohongshu" height="180"/></a> | <img src="./images/qr-wechat-official.jpg" width="180"/> | <img src="./images/qr-wechat-group.png" width="180"/> |
| [Profile](https://www.xiaohongshu.com/user/profile/5a169df34eacab2bc9a7a22d) | Follow for tutorials & updates | If QR expired, follow the official account for latest link |

---

## Related Links

- [AI Court Skill — Chinese](https://github.com/wanikua/ai-court-skill)
- [Become CEO — English](https://github.com/wanikua/become-ceo)

- [OpenClaw Official Documentation](https://docs.openclaw.ai)
- [OpenClaw GitHub](https://github.com/openclawai/openclaw)

## ⚠️ 免责声明 / Disclaimer

本项目按"原样"提供，不承担任何直接或间接责任。/ This project is provided "as is" without any warranties.

**使用前请注意 / Please note:**

1. **AI 生成内容仅供参考 / AI-generated content is for reference only**
   - AI 生成的代码、文案、建议等可能存在错误或不准确之处
   - 使用前请自行审核，确认无风险后再实际应用
   - Code, suggestions, etc. may contain errors. Please review before using in production.

2. **代码安全 / Code Security**
   - 自动生成的代码建议在合并前进行 code review
   - 涉及财务、安全敏感的操作请务必人工复核
   - Review AI-generated code before merging. Human review required for financial/sensitive operations.

3. **API 密钥安全 / API Key Security**
   - 请妥善保管您的 API 密钥 / Keep your API keys safe
   - 不要将包含密钥的配置文件提交到公开仓库 / Don't commit config files with keys to public repos

4. **服务器费用 / Server Costs**
   - 免费服务器（云服务商 等）有一定使用限额 / Free servers have usage limits
   - 超出限额后可能产生费用，请留意账单 / Excess usage may incur charges

5. **数据备份 / Data Backup**
   - 建议定期备份您的工作区和数据 / Regularly backup your workspace
   - 本项目不提供任何数据保证 / This project provides no data guarantees

---

v3.4 | MIT License

> 📜 This project is licensed under MIT. If you create derivative works or projects inspired by this architecture, please credit the original: [boluobobo-ai-court-tutorial](https://github.com/wanikua/boluobobo-ai-court-tutorial) by [@wanikua](https://github.com/wanikua)
