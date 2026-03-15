# ❓ 常见问题 FAQ

---

## 基础问题

### Q: 需要会写代码吗？
不需要。一键脚本搞定安装，配置文件填几个 Key 就行。所有交互都是在 Discord 里用自然语言。

### Q: 和直接用 ChatGPT 有什么区别？
ChatGPT 是一个通才，对话结束就失忆。这套系统是多个专家——每个 Agent 有自己的专业领域、持久记忆和工具权限。能自动写代码提交 GitHub、自动写文档到 Notion、定时执行任务。

### Q: 能用其他模型吗？
能。OpenClaw 支持 Anthropic、OpenAI、Google Gemini 等主流服务商，也可接入兼容 OpenAI API 格式的服务商。在 `openclaw.json` 里改 model 配置就行。不同部门可以用不同模型。

### Q: 每月 API 费用大概多少？
看使用强度。轻度使用 $10-15/月，中度 $20-30/月。省钱技巧：重活用强力模型，轻活用快速模型（便宜约 5 倍），简单任务可接入经济模型进一步降本。

### Q: 和 Become CEO 项目有什么关系？
[Become CEO](https://github.com/wanikua/become-ceo) 是本项目的英文企业版，使用相同的 OpenClaw 框架和架构，只是将朝廷角色换成了现代企业角色（CTO、CFO 等）。

---

## 技术问题

### Q: @everyone 不触发 Agent 回复？
Discord Developer Portal 里每个 Bot 要开启 **Message Content Intent** 和 **Server Members Intent**，服务器里 Bot 角色要有 View Channels 权限。

### Q: Agent 报「只读文件系统」「apt 失败」？
sandbox mode 设成了 `all` 导致 Agent 跑在 Docker 容器里，文件系统只读。

**最简单的解法：** 不写代码的部门直接关掉沙箱：
```json
"sandbox": { "mode": "off" }
```

**如果必须开沙箱但需要更多权限：**
```json
"sandbox": {
  "mode": "all",
  "workspaceAccess": "rw",
  "docker": {
    "network": "bridge",
    "env": { "LLM_API_KEY": "你的LLM_API_KEY" }
  }
}
```

> 详细说明见 [安全须知](./security.md)

### Q: 多人同时 @ 同一个 Agent 会冲突吗？
不会。OpenClaw 为每个用户 × Agent 组合维护独立会话。多人同时 @兵部，各自的对话互不干扰。

### Q: Agent 之间能互相调用吗？
能。通过 `sessions_spawn` 产生子任务给其他 Agent，通过 `sessions_send` 发消息给其他 Agent 的会话。

### Q: 怎么自定义 Skill？
每个 Skill 是一个包含 `SKILL.md` + 脚本 + 资源的目录。放到 `skills/` 目录下即可。也可以从 [OpenClaw Skill 生态](https://github.com/openclaw/openclaw) 获取社区 Skill。

### Q: 怎么接入私有模型（Ollama 等）？
在 `openclaw.json` 的 `models.providers` 中添加 OpenAI API 格式的 provider，指定 `baseUrl` 到 Ollama 地址。零 API 费用。

### Q: 启动时报 "workspace does not exist"？
这通常是因为 `defaults.workspace` 配置了但目录未创建，或者个别 Agent 覆盖了自己的 workspace 路径。

**推荐做法**：所有 Agent 共用一个工作区（在 `defaults` 里配，不要在每个 agent 里单独配）：
```json
"agents": {
  "defaults": { "workspace": "/home/你的用户名/clawd" },
  "list": [
    { "id": "silijian", "name": "司礼监" },
    { "id": "bingbu", "name": "兵部" }
  ]
}
```

然后确保目录存在：
```bash
mkdir -p ~/clawd
```

> ⚠️ **不要在每个 agent 里写不同的 workspace**（如 `workspace-silijian`、`workspace-bingbu`），这会导致 SOUL.md / IDENTITY.md 等文件需要在每个目录里单独维护。共享工作区 + `defaults.workspace` 是最佳实践。

### Q: Agent 不知道自己是谁 / SOUL.md 和 IDENTITY.md 是空的？
安装脚本会自动生成包含有意义内容的 SOUL.md 和 IDENTITY.md。如果你的文件是空的，说明可能是早期版本安装的，手动补充即可：

- **SOUL.md** — 朝廷行为准则（铁律、沟通风格、部门架构等）
- **IDENTITY.md** — 身份信息（名字、定位、Emoji 等）

参考最新安装脚本生成的模板内容，或直接重新运行安装脚本。

### Q: subagent 用的 workspace 不是自己的而是继承了父 agent 的？
这是正常行为。OpenClaw 的 subagent 默认继承父 agent 的 workspace。如果你希望所有 agent 共享同一个工作区，在 `defaults.workspace` 配置统一路径即可。

### Q: Gateway 启动失败？
```bash
journalctl --user -u openclaw-gateway --since today --no-pager
openclaw doctor
```
常见原因：API Key 未填、JSON 格式错误、Bot Token 无效。

### Q: 报 "Failed to resolve Discord application id"？
每个 Discord Bot 需要在配置中添加 `applicationId` 字段。在 Discord Developer Portal → 你的 Application → General Information 页面复制 Application ID（一串数字），填入对应 account 配置中：
```json
"silijian": {
  "name": "司礼监",
  "token": "你的Bot Token",
  "applicationId": "你的Application ID",
  "groupPolicy": "open"
}
```

### Q: 报 "Unrecognized key: botName"？
新版 OpenClaw 已将 `botName` 字段改为 `name`。把配置中所有 `"botName"` 替换为 `"name"` 即可，或运行 `openclaw doctor --fix` 自动修复。

### Q: 报 config invalid 错误？
新版 OpenClaw 移除了过期字段（如 `runTimeoutSeconds`），运行 `openclaw doctor --fix` 自动修复。

### Q: Windows 能用吗？
可以！通过 WSL2 运行。详见 [Windows WSL2 安装指南](./windows-wsl.md)。

---

← [返回 README](../README.md)

### Q: Bot 之间互相 @ 不触发回复？

这是多 Bot 模式最常见的坑。Discord 的 @mention 必须用 `<@用户ID>` 格式（如 `<@1482327799279652974>`），纯文本 `@兵部` 只是普通字符串，不会触发任何通知。

**解决方法**：在司礼监的 `identity.theme` 中写入每个 Bot 的 Discord User ID 和正确格式。详见 [Discord Bot 配置 - @mention 格式](./setup-discord.md#重要bot-互相-mention-的格式)。

### Q: 日志显示 `no-mention` 但我确实 @ 了 Bot？

`no-mention` 是正常行为 — 当一条消息 @司礼监 时，其他 6 个 Bot 都会报 `no-mention`（因为确实没 @ 它们）。只要被 @ 的那个 Bot 显示 `explicitlyMentioned=true` 就说明 mention 检测正常。

如果被 @ 的 Bot 也报 `no-mention`，检查：
1. 是否用了 `<@用户ID>` 格式（不是纯文本 `@名字`）
2. `allowBots: true` 是否已配置（Bot 间互相触发需要）
3. Bot 的 Message Content Intent 是否已开启
