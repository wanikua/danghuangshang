---
name: ai-court
description: "以明朝内阁制为蓝本的多 Agent 协作系统"
---

# AI Court | 当皇上

一行命令起王朝，三省六部皆 AI。

## 安装

```bash
clawdhub install ai-court
```

## 使用

### 1. 选择制度

**明朝内阁制**（推荐）：
```bash
cd ~/.openclaw && cp -r clawd/skills/ai-court/configs/ming-neige/* .
```

**唐朝三省制**：
```bash
cd ~/.openclaw && cp -r clawd/skills/ai-court/configs/tang-sansheng/* .
```

**现代企业制**：
```bash
cd ~/.openclaw && cp -r clawd/skills/ai-court/configs/modern-ceo/* .
```

### 2. 选择 IM 平台

#### 飞书（国内推荐）⭐
```bash
cd ~/.openclaw && cp -r clawd/skills/ai-court/configs/feishu/* .
```

配置飞书凭证：
- App ID 和 App Secret
- 详见 `references/feishu-setup.md`

#### Discord（国际推荐）
```bash
cd ~/.openclaw && cp -r clawd/skills/ai-court/configs/ming-neige/* .
```

配置 Discord Bot Token：
- 详见 `references/discord-setup.md`

### 3. 配置 API Key

```json
{
  "models": {
    "providers": {
      "dashscope": {
        "apiKey": "sk-your-api-key"
      }
    }
  }
}
```

### 4. 验证安装

```bash
bash clawd/skills/ai-court/scripts/doctor.sh
```

### 5. 启动

```bash
openclaw start
```

## IM 平台对比

| 平台 | 适用场景 | 优势 |
|------|----------|------|
| **飞书** | 国内用户、企业团队 | 无需翻墙、WebSocket 长连接 |
| **Discord** | 国际用户、开源社区 | 功能强大、机器人生态好 |

## 链接

GitHub: https://github.com/wanikua/ai-court-skill
