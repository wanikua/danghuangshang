# 📱 路径 D：Linux + 飞书部署（国内推荐）

> ⏱️ 预计耗时：15-20 分钟 | 飞书无需梯子，WebSocket 长连接不需要公网 IP
>
> ← [返回 README](../README.md) | 前置：[领服务器（可选）](./server-setup.md)

---

## 飞书与 Discord 的差异

飞书 Bot 不能互相 @触发（Discord 可以），所以飞书采用 **单 Bot + sessions_spawn 后台调度** 架构。用户只看到司礼监一个 Bot，司礼监通过 `sessions_spawn` 在后台派活给六部。

## 1. 准备服务器

同路径 A，推荐阿里云/腾讯云/华为云（国内延迟更低）。

## 2. 一键安装

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/wanikua/boluobobo-ai-court-tutorial/main/install.sh)
# 选择模式 2: 飞书单Bot模式
```

## 3. 创建飞书应用（只需 1 个）

1. 打开 [飞书开放平台](https://open.feishu.cn/app)，创建企业自建应用（如「AI朝廷-司礼监」）
2. 复制 **App ID**（`cli_xxx`）和 **App Secret**
3. **权限管理** → 添加 `im:message` 等 **9 个权限**（详见下方权限表）
4. **应用能力** → 开启机器人
5. **事件订阅** → WebSocket 模式 → 添加 `im.message.receive_v1`
6. **版本管理** → 创建版本并发布

### 所需权限列表

| 权限 | 用途 | 必须 |
|------|------|------|
| `im:message` | 获取与发送消息 | ✅ |
| `im:message:send_as_bot` | 以机器人身份发消息 | ✅ |
| `im:message:readonly` | 读取消息 | ✅ |
| `im:message.p2p_msg:readonly` | 获取单聊消息 | ✅ |
| `im:message.group_at_msg:readonly` | 获取群组 @消息 | ✅ |
| `im:resource` | 获取消息中的资源文件 | ✅ |
| `im:chat.members:bot_access` | 获取群成员信息 | 推荐 |
| `im:chat.access_event.bot_p2p_chat:read` | 获取单聊事件 | 推荐 |
| `contact:user.employee_id:readonly` | 获取用户工号 | 推荐 |

> ⚠️ **权限以 [飞书配置指南](../飞书配置指南.md) 为准**，此表为快速参考。如有差异，以飞书配置指南为权威来源。

> 📖 详细步骤见 [飞书配置指南](../飞书配置指南.md)

## 4. 填 Key

```bash
nano ~/.openclaw/openclaw.json
```

```json
{
  "channels": {
    "feishu": {
      "enabled": true,
      "dmPolicy": "open",
      "groupPolicy": "open",
      "accounts": {
        "silijian": {
          "appId": "cli_你的AppID",
          "appSecret": "你的AppSecret",
          "name": "司礼监",
          "groupPolicy": "open"
        }
      }
    }
  }
}
```

> ⚠️ account key 要用 `silijian`（与 install.sh 生成的一致），不要用 `main`。

## 5. 启动

```bash
systemctl --user start openclaw-gateway
systemctl --user status openclaw-gateway
```

在飞书里给机器人发消息，收到回复就成功了！🎉

> 💡 只需 1 个飞书应用，司礼监会通过 `sessions_spawn` 自动调度其他 9 个部门在后台协作。

## 飞书排查指南

Bot @了不回？按这个顺序排查：

1. **事件订阅**（最常见）：确认 WebSocket 模式 + `im.message.receive_v1` + 已启用
2. **权限检查**：确认上方 9 个权限都已开启
3. **配置文件**：account key 和 bindings 的 accountId 要一致
4. **机器人能力**：确认开启了机器人能力，Bot 已加入目标群聊
5. **@方式**：从弹出列表中选择，不能手打 "@xxx"
6. **查看日志**：`journalctl --user -u openclaw-gateway --since "5 min ago" | grep -i "feishu\|lark"`

> 📖 完整排查详见 [飞书配置指南](../飞书配置指南.md)

---

← [返回 README](../README.md)
