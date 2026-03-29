# 飞书配置完整教程

## 快速开始（5 分钟）

### 步骤 1：创建飞书应用

1. 访问 [飞书开放平台](https://open.feishu.cn/app)
2. 点击 **创建企业应用**
3. 填写应用名称（如：AI 朝廷）和描述
4. 选择应用图标

### 步骤 2：获取凭证

从 **凭证与基础信息** 复制：
- **App ID**（格式：`cli_xxx`）
- **App Secret**（保密！）

### 步骤 3：配置权限

在 **权限管理** → **批量导入**，粘贴：

```json
{
  "scopes": {
    "tenant": [
      "im:message",
      "im:message:send_as_bot",
      "im:message.p2p_msg:readonly",
      "im:message.group_at_msg:readonly",
      "im:chat.access_event.bot_p2p_chat:read",
      "im:chat.members:bot_access"
    ],
    "user": ["im:chat.access_event.bot_p2p_chat:read"]
  }
}
```

### 步骤 4：启用机器人

1. 进入 **应用功能** → **机器人**
2. 启用机器人能力
3. 设置机器人名称（如：工部、司礼监）

### 步骤 5：配置事件订阅

⚠️ **重要**：先启动网关再配置！

```bash
# 先启动网关
openclaw gateway start
```

1. 进入 **事件订阅**
2. 选择 **使用长连接接收事件**（WebSocket）
3. 添加事件：`im.message.receive_v1`

### 步骤 6：发布应用

1. 进入 **版本管理与发布**
2. 创建版本并提交审核
3. 等待批准（企业应用通常自动批准）

---

## 配置 OpenClaw

### 方式 1：配置文件

编辑 `~/.openclaw/openclaw.json`：

```json5
{
  channels: {
    feishu: {
      enabled: true,
      dmPolicy: "pairing",
      groupPolicy: "open",
      accounts: {
        main: {
          appId: "cli_xxx",
          appSecret: "xxx",
          botName: "AI 朝廷",
        },
      },
    },
  },
}
```

### 方式 2：环境变量

```bash
export FEISHU_APP_ID="cli_xxx"
export FEISHU_APP_SECRET="xxx"
```

---

## 访问控制

### 私聊控制（dmPolicy）

| 模式 | 说明 |
|------|------|
| `"pairing"` | 默认，陌生用户获取配对码 |
| `"allowlist"` | 仅允许列表用户 |
| `"open"` | 允许所有用户 |
| `"disabled"` | 禁用私聊 |

### 群聊控制（groupPolicy）

| 模式 | 说明 |
|------|------|
| `"open"` | 默认，允许所有群 |
| `"allowlist"` | 仅允许特定群 |
| `"disabled"` | 禁用群聊 |

---

## 获取群 ID 和用户 ID

### 群 ID（chat_id）
格式：`oc_xxx`

**方法**：
1. 在群里 @机器人
2. 查看日志：`openclaw logs --follow`
3. 找到 `chat_id`

### 用户 ID（open_id）
格式：`ou_xxx`

**方法**：
1. 给机器人发私聊
2. 查看日志：`openclaw logs --follow`
3. 找到 `open_id`

---

## 常用命令

| 命令 | 说明 |
|------|------|
| `/status` | 显示机器人状态 |
| `/reset` | 重置会话 |
| `/model` | 查看/切换模型 |

**网关管理**：
```bash
openclaw gateway status              # 查看状态
openclaw gateway restart             # 重启
openclaw logs --follow               # 查看日志
openclaw pairing list feishu         # 查看配对请求
openclaw pairing approve feishu CODE # 批准配对
```

---

## 故障排除

### 机器人不回复

1. ✅ 检查事件订阅是否包含 `im.message.receive_v1`
2. ✅ 检查权限是否完整
3. ✅ 检查网关状态：`openclaw gateway status`
4. ✅ 检查日志：`openclaw logs --follow`

### 群聊无响应

1. ✅ 确认已 @机器人
2. ✅ 检查 `groupPolicy` 配置
3. ✅ 检查机器人是否在群里

### 配对失败

1. ✅ 检查 `dmPolicy` 配置
2. ✅ 使用 `openclaw pairing approve` 批准

---

## 相关链接

- [飞书开放平台](https://open.feishu.cn/app)
- [飞书 API 文档](https://open.feishu.cn/document)
- [OpenClaw 飞书通道文档](https://docs.openclaw.ai/channels/feishu)
