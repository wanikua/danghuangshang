# 飞书配置说明

## 快速开始

### 1. 创建飞书应用

1. 访问 https://open.feishu.cn/app
2. 创建企业应用
3. 复制 App ID 和 App Secret

### 2. 配置权限

```json
{
  "scopes": {
    "tenant": [
      "im:message",
      "im:message:send_as_bot",
      "im:message.p2p_msg:readonly",
      "im:message.group_at_msg:readonly"
    ]
  }
}
```

### 3. 启用机器人并配置事件订阅

- 启用机器人能力
- 使用长连接接收事件（WebSocket）
- 添加事件：`im.message.receive_v1`

### 4. 配置 OpenClaw

```bash
cd ~/.openclaw
cp -r clawd/skills/ai-court/configs/feishu/* .
nano openclaw.json  # 填入 App ID 和 App Secret
openclaw start
```

## 详细教程

参见 `references/feishu-setup.md`
