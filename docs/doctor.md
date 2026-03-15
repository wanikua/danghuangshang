# 🏥 配置诊断（doctor.sh）

> ← [返回 README](../README.md)

---

## 一键诊断

遇到问题？跑一行命令自动检查：

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/wanikua/danghuangshang/main/doctor.sh)
```

## 诊断内容

- ✅ OpenClaw / Node.js 安装检查
- ✅ 配置文件格式和 API Key 检查
- ✅ Discord Bot Token、allowBots、groupPolicy 检查
- ✅ Agent 和 Binding 路由匹配检查
- ✅ 工作区文件（SOUL.md / USER.md / memory/）检查
- ✅ Notion 等可选集成检查
- ✅ 飞书 appId / appSecret / 权限 / 事件订阅检查
- ✅ **@everyone 不触发的完整排查清单**

---

## @everyone 不触发 Bot 回复？

这是最常见的问题，通常原因是 **Discord Developer Portal 的 Intent 没开**：

1. 打开 [Discord Developer Portal](https://discord.com/developers/applications)
2. 选择你的 Bot → 左侧 **Bot** 页面
3. 往下翻到 **Privileged Gateway Intents**，开启：
   - ✅ **Message Content Intent**（必须）
   - ✅ **Server Members Intent**（必须）
   - ✅ **Presence Intent**（可选）
4. **每个 Bot 都要开**，不是只开一个！
5. 确认服务器里每个 Bot 的角色有 **View Channels** 权限
6. 确认 `channels.discord.groupPolicy` 和每个 account 的 `groupPolicy` 都是 `"open"`

> ⚠️ 改完 Intent 后需要**重启 Gateway**：`openclaw gateway restart` 或 `systemctl --user restart openclaw-gateway`

---

## 常用排查命令

```bash
# 查看 Gateway 状态
systemctl --user status openclaw-gateway

# 查看详细日志
journalctl --user -u openclaw-gateway --since today --no-pager

# 自动配置检查
openclaw doctor

# 自动修复过期配置字段
openclaw doctor --fix

# 检查飞书消息
journalctl --user -u openclaw-gateway --since "5 min ago" | grep -i "feishu\|lark"
```

---

← [返回 README](../README.md) | [完整 FAQ](./faq.md)
