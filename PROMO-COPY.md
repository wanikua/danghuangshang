# Promotional Copy — Ready to Post

## Reddit: r/ClaudeAI

**Title:** I built a 7-bot Discord workspace where Claude Opus handles Engineering and Finance, Sonnet handles the rest

**Body:**

Been running this for a few months. The idea: instead of one chatbot, you get a full "executive team" of Discord bots. Each one is a separate bot with a distinct role:

- **Engineering** — Claude Opus (code, architecture)
- **Finance** — Claude Opus (budgets, cost tracking)
- **Marketing** — Claude Sonnet (content, branding)
- **DevOps** — Claude Sonnet (servers, CI/CD)
- **Legal** — Claude Sonnet (contracts, compliance)
- **Management** — Claude Sonnet (project coordination)
- **Chief of Staff** — Claude Sonnet (dispatcher)

Tag `@Engineering` and Claude Opus picks it up. `@everyone` triggers a standup where every agent reports.

Setup is one bash command on an Oracle Cloud free tier server (4 cores, 24GB RAM — genuinely free).

GitHub: https://github.com/wanikua/become-ceo
Chinese version (Ming Dynasty theme): https://github.com/wanikua/ai-court-skill

---

## Reddit: r/selfhosted

**Title:** Self-hosted 7-agent AI team on Discord, free Oracle Cloud server, one setup command

**Body:**

7 independent Discord bots (Engineering, Finance, Marketing, DevOps, Legal, Management, Chief of Staff), each a separate Claude-powered agent running on your own server.

- Host: Oracle Cloud Free Tier — ARM, 4 OCPU, 24GB RAM. Always-free.
- Runtime: Clawdbot (Node.js, open source)
- Models: Anthropic API (pay-per-token)

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/wanikua/become-ceo/main/setup.sh)
```

All data stays on your server. Config is plain JSON. Workspace is just markdown files.

**Gotcha:** Each Discord bot needs `"groupPolicy": "open"` set individually in config. Global setting does NOT cascade.

GitHub: https://github.com/wanikua/become-ceo

---

## Reddit: r/Discord_Bots

**Title:** Built a 7-bot "executive team" system for Discord — each bot is a separate AI specialist

**Body:**

7 Discord bots in the same server, each representing a role. They're powered by Claude via Clawdbot. Each bot is a separate Discord application with its own token. All need Message Content Intent and Server Members Intent.

The main bot (Chief of Staff) dispatches. Big tasks auto-open threads. `@everyone` triggers all bots.

Gotcha: each bot account needs `"groupPolicy": "open"` explicitly — global setting doesn't cascade.

One-click setup: https://github.com/wanikua/become-ceo

---

## Reddit: r/SideProject

**Title:** I built an AI executive team out of 7 Discord bots — free server, open source

**Body:**

I work alone. Kept noticing friction context-switching between "write code" and "review contract" and "check burn rate" in the same AI window.

Built Become CEO: 7 Discord bots as an executive team. Each one has its own Claude model, personality, context. Chief of Staff routes requests.

Runs on a free Oracle Cloud server. Cost = Anthropic API tokens only.

What I learned:
1. Dispatcher pattern is more useful than expected
2. Context isolation between agents is underrated
3. File-based memory (markdown) survives restarts, LLM "memory" doesn't
4. The hardest bug was `groupPolicy` not inheriting — silent message drops, no error

GitHub: https://github.com/wanikua/become-ceo

---

## Hacker News — Show HN

**Title:** Show HN: Become CEO – Run a 7-agent AI executive team on Discord for free

**Comment:**

7 independent Discord bots — Engineering, Finance, Marketing, DevOps, Legal, Management, Chief of Staff — powered by Claude via Clawdbot.

Each agent is a separate Discord application. Clawdbot multiplexes WebSocket connections and routes messages by @mention. Agents read shared markdown files (SOUL.md, IDENTITY.md, USER.md) for context. Engineering/Finance get Opus, rest get Sonnet.

Designed for Oracle Cloud's always-free ARM tier (4 OCPU, 24GB RAM). One setup command.

Config gotcha worth documenting: each Discord account needs `"groupPolicy": "open"` individually — global doesn't cascade, messages silently drop.

English: https://github.com/wanikua/become-ceo
Chinese (Ming Dynasty theme): https://github.com/wanikua/ai-court-skill

---

## Twitter/X Thread

**Tweet 1:**
I gave myself a 7-person executive team for $0/month in server costs.

Engineering, Finance, Marketing, DevOps, Legal, Management, Chief of Staff.

All Discord bots. All Claude. All running on a free Oracle server. 🧵

**Tweet 2:**
Each specialist is a separate Discord bot with their own model:
- Engineering & Finance → Claude Opus
- Everyone else → Claude Sonnet

Tag @Engineering to ship code. @Finance to check burn rate. @everyone to run a standup.

**Tweet 3:**
Setup is one command on Oracle Cloud free tier:
bash <(curl -fsSL .../setup.sh)

Add your @AnthropicAI API key and @discord bot tokens. Done.

Zero monthly server bill.

**Tweet 4:**
English: github.com/wanikua/become-ceo
Chinese (Ming Dynasty cabinet): github.com/wanikua/ai-court-skill

MIT licensed. Built on Clawdbot.

---

## V2EX

**标题:** 用 Clawdbot 搭了个 7 机器人的 Discord AI 团队，免费 Oracle 服务器，一键部署

**节点:** AI / 分享创造

在 Discord 里跑 7 个独立 AI 机器人，每个对应一个部门。每个机器人用自己的 Token，绑定自己的 Claude 模型。

Engineering/Finance 用 Opus，其余用 Sonnet。跑在 Oracle Cloud 永久免费套餐，4 OCPU + 24GB RAM。

踩的坑：`groupPolicy` 全局配置不会下发给单个 account，必须单独设 `"groupPolicy": "open"`。

- 英文版：https://github.com/wanikua/become-ceo
- 中文版：https://github.com/wanikua/ai-court-skill
- 教程：https://github.com/wanikua/boluobobo-ai-court-tutorial

---

## Dev.to

**Title:** How I Built a 7-Agent AI Team on Discord for $0 in Server Costs
**Tags:** ai, discord, selfhosted, claude

(See full article in conversation history)

---

## Product Hunt

**Tagline:** Your 7-agent AI team on Discord — free to host

(See full description in conversation history)
