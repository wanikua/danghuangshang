# 🛡️ Discord 安全指南

> ← [返回 README](../README.md) | 相关：[Discord Bot 配置](./setup-discord.md) | [FAQ](./faq.md)

---

## 概述

多 Bot 架构意味着多个 Bot Token、多个角色权限、多个潜在攻击面。本指南帮你做好安全防护。

---

## 1. Bot Token 安全

### 基本原则

- **Token = 密码**，泄露 = Bot 被完全控制
- **永远不要**把 Token 提交到 Git（即使是私有仓库）
- **永远不要**在 Discord 频道里发 Token

### 保护措施

```bash
# 配置文件权限：只有自己能读写
chmod 600 ~/.openclaw/openclaw.json

# 检查是否不小心提交了 Token
grep -r "MTQ\|mfa\." .git/ 2>/dev/null && echo "⚠️ Token 可能已提交！"
```

### Token 泄露应急

1. 立即到 [Discord Developer Portal](https://discord.com/developers/applications) → Bot → **Reset Token**
2. 更新配置文件中的新 Token
3. 重启 Gateway
4. 检查 Bot 是否发过异常消息

---

## 2. Bot 权限最小化

### 推荐权限

只授予 Bot 必要的权限，**不要给 Administrator**：

| 权限 | 是否需要 | 说明 |
|------|----------|------|
| ✅ Send Messages | 必须 | 发送消息 |
| ✅ Read Messages / View Channels | 必须 | 读取消息 |
| ✅ Read Message History | 必须 | 读取历史消息 |
| ✅ Embed Links | 推荐 | 富文本消息 |
| ✅ Attach Files | 推荐 | 发送文件 |
| ✅ Add Reactions | 推荐 | 添加表情回应 |
| ✅ Use External Emojis | 可选 | 跨服 Emoji |
| ❌ **Mention Everyone** | **不要** | 防止 Bot 回复 ping 全员 |
| ❌ **Administrator** | **不要** | 权限过大 |
| ❌ Manage Messages | 不需要 | 除非有特殊需求 |
| ❌ Manage Channels | 不需要 | 除非有特殊需求 |
| ❌ Manage Roles | 不需要 | 除非有特殊需求 |

### 禁止 Bot 触发 @everyone

Bot 的 AI 回复可能意外包含 `@everyone`，导致全服务器收到通知。

**修复方法：**

1. **服务器设置** → **角色** → **@everyone** 角色
2. 关闭 **"提及 @everyone、@here 和所有角色"**
3. 对每个 Bot 的托管角色（如「司礼监」「兵部」等）也确认此权限已关闭

> 💡 服务器 Owner 不受角色权限限制，你发 @everyone 仍然正常。

**验证：** 运行 `bash doctor.sh`，会自动检测 Mention Everyone 权限。

---

## 3. 频道隔离

### 推荐架构

```
🏯 你的朝廷
├── 📜 本纪（公开频道）
│   └── 任何人可读，Bot 可写
├── 🏢 六部（工作频道）
│   └── Bot + 管理员可读写
├── 🔒 机密（私密频道）
│   └── 仅管理员可见
└── 💬 闲聊
    └── 任何人可用
```

### 敏感频道保护

对于不希望 Bot 参与的频道，在频道权限中移除 Bot 角色的 **View Channel** 权限。

---

## 4. Bot 间通信安全

### allowBots 配置

```json
"allowBots": "mentions"
```

- `"mentions"` — Bot 只在被 @mention 时响应其他 Bot（**推荐**，防止无限循环）
- `true` — Bot 响应所有 Bot 消息（可能导致消息风暴）
- `false` — Bot 完全忽略其他 Bot 消息

### 防止无限循环

`allowBots: "mentions"` 已经防止了大多数循环。额外保护：

- 确保 Bot 的 identity.theme 中不包含会 @自己的指令
- 监控日志中的异常高频消息

---

## 5. groupPolicy 安全

```json
"groupPolicy": "open"
```

`open` 表示 Bot 响应所有频道的消息（只要被 @mention）。如果需要限制：

```json
"groupPolicy": "allowlist",
"groupAllowList": ["频道ID1", "频道ID2"]
```

> ⚠️ 注意：每个 account 都需要单独设 groupPolicy，全局的不会继承到 account 级别。

---

## 6. 配置文件安全

### 文件权限

```bash
# 设置正确权限
chmod 600 ~/.openclaw/openclaw.json

# 验证
ls -la ~/.openclaw/openclaw.json
# 应该显示 -rw------- （只有 owner 可读写）
```

### 备份加密

```bash
# 备份时加密敏感配置
tar czf - ~/.openclaw/openclaw.json | openssl enc -aes-256-cbc -pbkdf2 -out openclaw-backup.enc

# 恢复
openssl enc -d -aes-256-cbc -pbkdf2 -in openclaw-backup.enc | tar xzf -
```

---

## 7. 安全检查清单

运行 `bash doctor.sh` 自动检查，或手动核对：

- [ ] 配置文件权限 600
- [ ] Token 未提交到 Git
- [ ] Bot 无 Administrator 权限
- [ ] Bot 无 Mention Everyone 权限
- [ ] `allowBots` 设为 `"mentions"`
- [ ] 敏感频道已限制 Bot 访问
- [ ] 每个 account 都设了 `groupPolicy: "open"`
- [ ] 定期检查 Bot 的 audit log

---

## 8. 应急响应

### Bot 异常行为

1. 立即在 Discord 服务器中 **踢出 Bot**（右键 → Kick）
2. 到 Developer Portal **Reset Token**
3. 检查日志找原因
4. 修复后重新邀请

### 配置泄露

1. Reset 所有 Bot Token
2. 更新配置文件
3. 检查 Git 历史（`git log --all -p -- '*.json'`）
4. 如果已推送，用 `git filter-branch` 或 BFG 清理

---

← [返回 README](../README.md) | [Discord Bot 配置](./setup-discord.md) | [FAQ](./faq.md)
