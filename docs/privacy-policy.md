# 🔒 Privacy Policy

> Last updated: 2026-03-13

← [返回 README](../README.md) | [📚 文档索引](./README.md)

---

## 1. Overview

This Privacy Policy describes how the AI Court System ("danghuangshang", hereinafter "the Project") handles data. The Project is a self-hosted, open-source system — **you control all your data**.

## 2. Data Collection

### What the Project Does NOT Collect

- ❌ We do **not** collect any personal information
- ❌ We do **not** have access to your server, conversations, or API keys
- ❌ We do **not** use analytics, tracking, or telemetry
- ❌ We do **not** operate any central server that receives your data
- ❌ The Docker image contains **no** user data, credentials, or tracking code

### What Stays on Your Server

When you deploy the Project, the following data is stored **exclusively on your own server**:

| Data | Location | Description |
|------|----------|-------------|
| Configuration | `~/.openclaw/openclaw.json` | API keys, bot tokens, agent settings |
| Conversations | `~/.clawdbot/agents/*/sessions/` | Chat history per agent |
| Memory files | `~/clawd/memory/` | Agent memory and notes |
| Workspace files | `~/clawd/` | SOUL.md, USER.md, IDENTITY.md, etc. |

**You have full control** over all data. Delete it anytime by removing the relevant directories.

## 3. Third-Party Data Sharing

When you use the Project, your data is sent to third-party services **that you configure**:

### AI Model Providers

Your conversation content is sent to your chosen AI provider for processing:

| Provider | Their Privacy Policy |
|----------|---------------------|
| Anthropic | https://www.anthropic.com/privacy |
| OpenAI | https://openai.com/privacy |
| DeepSeek | https://www.deepseek.com/privacy |
| OpenRouter | https://openrouter.ai/privacy |

**What is sent**: Message content, system prompts, file contents (if attached)
**What is NOT sent**: Your API key is sent only to the provider you configured, not to us

### Communication Platforms

If you connect Discord or Feishu, messages flow through their servers:

| Platform | Their Privacy Policy |
|----------|---------------------|
| Discord | https://discord.com/privacy |
| Feishu/Lark | https://www.feishu.cn/privacy |

### Docker Hub / GitHub

If you use the pre-built Docker image:
- Docker Hub may log pull requests (IP address, image name)
- GitHub may log repository access

## 4. Data Security

Since the Project is self-hosted, data security is your responsibility:

- 🔴 **Use a dedicated server** — not your personal computer
- 🔴 **Keep API keys private** — never commit to public repositories
- 🔴 **Set a dedicated workspace** — e.g., `/home/ubuntu/clawd`, not your home directory
- 🔴 **Configure sandbox mode** for code-executing agents
- 💡 Use firewall rules to restrict access to Gateway ports (18789, 18795)

See [Security Guide](./security.md) for detailed recommendations.

## 5. Data Retention

- **Your server, your rules**: Data persists until you delete it
- **No remote retention**: We do not retain any copy of your data
- **AI providers**: Retention depends on your provider's policy (some providers retain data for training unless you opt out)

## 6. Children's Privacy

The Project is not intended for use by children under 13. We do not knowingly collect data from children.

## 7. Open Source Transparency

The entire Project is open source. You can audit exactly what the code does:

- **Repository**: https://github.com/wanikua/danghuangshang
- **Docker image contents**: See [Docker Security](./setup-docker.md#-镜像安全说明) for a full breakdown
- **Installation scripts**: All `.sh` files are readable before execution

## 8. Changes to This Policy

We may update this Privacy Policy from time to time. Changes will be reflected in the "Last updated" date at the top of this page.

## 9. Contact

For privacy-related questions, please open a [GitHub Issue](https://github.com/wanikua/danghuangshang/issues).

---

← [返回 README](../README.md)
