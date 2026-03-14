# 🤖 Discord Bot 创建与配置

> ⏱️ 预计耗时：10 分钟 | **必选**（仅使用 Discord 路径时）
>
> ← [返回 README](../README.md) | 前置：[领服务器（可选）](./server-setup.md)

---

## 概述

AI 朝廷的多 Bot 架构：**每个部门 = 一个独立的 Discord Bot**。@兵部就找兵部回复，@户部就找户部回复。

- 起步只需 **1 个 Bot**（司礼监），后续随时加
- 完整版 **4-10 个 Bot**（六部 + 辅助机构）

---

## 第一步：创建 Discord 服务器

1. 打开 https://discord.com → 登录（没有账号先注册）
2. 左侧服务器列表 "+" → "创建我的服务器"
3. 填写服务器名称（如「菠萝王朝」）→ 创建

---

## 第二步：创建 Discord Bot

> 💡 每个部门重复以下步骤。起步只做 1 次（司礼监），后续再加。

### 2.1 创建 Application

1. 打开 [Discord Developer Portal](https://discord.com/developers/applications)
2. 点击 **"New Application"**
3. 名字填部门名（如「司礼监」「兵部」「户部」「礼部」）
4. 点击 "Create"

### 2.2 获取 Bot Token

1. 左侧菜单 → **Bot**
2. 点击 **"Reset Token"** → 复制 Token

> 🔴 **Token 只显示一次！** 先复制到记事本保存。

### 2.3 开启 Intent（⚠️ 必做！）

在同一 Bot 页面往下滚到 **Privileged Gateway Intents**：

| Intent | 必须 | 说明 |
|--------|------|------|
| ✅ **Message Content Intent** | 必须 | 不开 = 收不到消息内容 |
| ✅ **Server Members Intent** | 必须 | @everyone 触发需要 |
| ☑️ Presence Intent | 可选 | 显示在线状态 |

> ⚠️ **每个 Bot 都要开！** 不是只开一个！

### 2.4 邀请 Bot 到服务器

1. 左侧菜单 → **OAuth2**
2. **Scopes** 勾选 `bot` + `applications.commands`（⚠️ 两个都要勾！不勾 `applications.commands` 斜杠命令无法使用）
3. **Bot Permissions** 勾选：
   - ✅ Send Messages
   - ✅ Read Message History
   - ✅ Read Messages/View Channels
   - ✅ Embed Links（可选）
   - ✅ Attach Files（可选）
4. 复制生成的 **URL** → 浏览器打开 → 选择你的服务器 → Authorize

---

## 第三步：填入配置文件

```bash
nano ~/.openclaw/openclaw.json
```

将 Token 填入对应位置：

```json
{
  "channels": {
    "discord": {
      "enabled": true,
      "groupPolicy": "open",
      "allowBots": true,
      "accounts": {
        "silijian": {
          "name": "司礼监",
          "token": "这里粘贴司礼监的Token",
          "groupPolicy": "open"
        },
        "bingbu": {
          "name": "兵部",
          "token": "这里粘贴兵部的Token",
          "groupPolicy": "open"
        }
      }
    }
  },
  "bindings": [
    { "agentId": "silijian", "match": { "channel": "discord", "accountId": "silijian" } },
    { "agentId": "bingbu", "match": { "channel": "discord", "accountId": "bingbu" } }
  ]
}
```

> ⚠️ **关键配置**：
> - `groupPolicy: "open"` — channels 和每个 account 里**都要加**，否则群聊消息被静默丢弃
> - `allowBots: true` — 让 Bot 之间互相看到消息、互相触发回复
> - account key（如 `silijian`、`bingbu`）要和 bindings 里的 `accountId` **一致**

---

## 第四步：启动并测试

```bash
# 启动 Gateway
systemctl --user start openclaw-gateway

# 查看状态
systemctl --user status openclaw-gateway
```

在 Discord 任意频道 @你的 Bot 说句话，收到回复就成功了！🎉

---

## 推荐频道架构

```
🏯 你的朝廷
├── 📜 本纪
│   ├── #起居注（日报）
│   ├── #朔望录（周报）
│   └── #编年纪（月报）
├── 🏢 六部
│   ├── #兵部  #户部  #礼部
│   ├── #工部  #吏部  #刑部
├── 🤖 中枢
│   ├── #命令中心
│   └── #通知提醒
└── 💬 闲聊
    └── #茶水间
```

---

## 排查：斜杠命令（/status /new 等）无效？

- **Scope 没勾全** — OAuth2 里 `bot` 和 `applications.commands` **两个都要勾**。只勾了 `bot` 不行。
- **修复** — 重新生成邀请链接（勾上 `applications.commands`），打开链接对同一服务器重新授权即可，不用踢 Bot。

## 排查：@Bot 不回复？

1. **Intent 没开** — 最常见。每个 Bot 都要开 Message Content Intent + Server Members Intent
2. **groupPolicy 没设** — channels 和每个 account 里都要 `"open"`
3. **Token 过期/错误** — Developer Portal 确认 Token 有效
4. **Bot 没加入服务器** — 检查成员列表
5. **Bot 没有 View Channels 权限** — 检查服务器角色权限
6. **Gateway 没启动** — `systemctl --user status openclaw-gateway`

```bash
# 查看日志定位问题
journalctl --user -u openclaw-gateway --since "5 min ago"
```

> 📖 更多排查见 [配置诊断](./doctor.md) 和 [完整 FAQ](./faq.md)

---

← [返回 README](../README.md) | [进阶配置 →](./tutorial-advanced.md)

## 重要：Bot 互相 @mention 的格式

> ⚠️ 这是多 Bot 协作的**核心机制**，不了解会导致 Bot 之间完全无法互相触发。

Discord 的 @mention 必须使用 `<@用户ID>` 格式，**纯文本 `@兵部` 不会触发任何通知**。

### 为什么需要关注这个？

司礼监的 `identity.theme` 里写着"@对应部门派活"，但 LLM 不知道其他 Bot 的 Discord User ID，只会输出纯文本 `@兵部` — 这在 Discord 里只是普通字符串，不会生成蓝色 mention，其他 Bot 完全收不到。

### 怎么获取 Bot 的 User ID？

1. 在 Discord 中开启「开发者模式」：用户设置 → 高级 → 开发者模式 ✅
2. 右键点击 Bot 头像 → 「复制用户 ID」
3. 得到一串数字（如 `1482327799279652974`）

### 怎么配置？

在司礼监的 `identity.theme` 中写入每个 Bot 的 Discord User ID：

```
【@mention 格式（最重要！）】
在 Discord 中 @其他部门时，必须使用 <@数字ID> 格式：
- 兵部 = <@这里填兵部的User ID>
- 户部 = <@这里填户部的User ID>
- 礼部 = <@这里填礼部的User ID>
- 工部 = <@这里填工部的User ID>
- 吏部 = <@这里填吏部的User ID>
- 刑部 = <@这里填刑部的User ID>

正确示例: <@1482327799279652974> 编写用户登录 REST API
错误示例: @兵部 编写用户登录 REST API（对方收不到！）
```

> 💡 每个 Bot 的 User ID 在创建后就固定了，填一次即可。

