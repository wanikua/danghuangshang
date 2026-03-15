# 🐧 路径 A：Linux + Discord 部署（新手推荐）

> ⏱️ 预计耗时：15-20 分钟 | 海外用户首选
>
> ← [返回 README](../README.md) | 前置：[领服务器（可选）](./server-setup.md)

---

## 1. 准备服务器

> 已有 Linux 服务器？直接跳到第 2 步。没有？→ [领一台免费服务器](./server-setup.md)

推荐 ARM 架构 + 4GB 以上内存。只跑司礼监（单 Agent）2GB 也够。

## 2. 一键安装

SSH 连上服务器，运行：

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/wanikua/danghuangshang/main/install.sh)
# 选择模式 1: Discord 多Bot模式
```

脚本自动完成：系统更新 → 防火墙 → Swap → Node.js 22 → OpenClaw → 工作区初始化 → Gateway 系统服务

## 3. 创建 Discord Bot

> 📖 **详细步骤见 [Discord Bot 创建与配置](./setup-discord.md)**

简要流程：
1. [Discord Developer Portal](https://discord.com/developers/applications) 创建 Application
2. 获取 Bot Token（每个部门一个）
3. 开启 Message Content Intent + Server Members Intent
4. 邀请 Bot 到你的服务器

## 4. 填 Key

```bash
nano ~/.openclaw/openclaw.json
```

填两样东西：
1. **LLM API Key** — 你的 LLM 服务商（Anthropic / OpenAI / DeepSeek 等）
2. **Discord Bot Token** — 上一步获取的 Token

> 💡 起步可以只创建司礼监一个 Bot，后续再加其他部门。

## 5. 启动

```bash
systemctl --user start openclaw-gateway
systemctl --user status openclaw-gateway
```

在 Discord @你的 Bot 说句话，收到回复就成功了！🎉

## 6. 下一步（可选）

| 增强项 | 说明 | 文档 |
|--------|------|------|
| 📝 接入 Notion | 自动日报/周报归档 | [Notion 指南](./notion-setup.md) |
| 🖥️ Web GUI | 可视化管理后台 | [GUI 文档](./gui.md) |
| ⏰ 定时任务 | 自动执行 Cron | [进阶篇](./tutorial-advanced.md) |
| 🛡️ 安全加固 | Sandbox 沙箱配置 | [安全须知](./security.md) |

---

← [返回 README](../README.md) | [Discord Bot 配置 →](./setup-discord.md) | [进阶篇 →](./tutorial-advanced.md)
