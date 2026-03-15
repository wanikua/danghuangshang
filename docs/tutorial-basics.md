# 🏛️ 保姆级教程：30 分钟搭建你的 AI 朝廷（基础篇）

> ← [返回 README](../README.md) | [📚 文档索引](./README.md)

> 适用人群：完全零基础小白 | 预计耗时：30-45 分钟
>
> 最终效果：拥有一台永久免费的云服务器，运行你的 AI 朝廷团队

---

## 📖 目录

1. [领免费服务器（10 分钟）](#一领免费服务器10-分钟)
2. [连接服务器（5 分钟）](#二连接服务器5-分钟)
3. [一键安装 OpenClaw（5 分钟）](#三一键安装5-分钟)
4. [配置 API Key（5 分钟）](#四配置-api-key5-分钟)
5. [搭建朝廷架构（15 分钟）](#五搭建朝廷架构15-分钟)
6. [启动并测试（5 分钟）](#六启动并测试5-分钟)
7. [常见问题 Q&A](#七常见问题-qa)
8. [15 张配图清单](#八15-张配图清单)

---

## 一、领免费服务器（10 分钟）

### 1.1 打开云服务商官网

推荐（均有免费套餐）：
- **Oracle Cloud**：https://cloud.oracle.com （永久免费 ARM 4核24G，首选）
- **AWS**：https://aws.amazon.com （12个月免费 t2.micro）
- **Google Cloud**：https://cloud.google.com （$300 试用额度）

以下以 Oracle Cloud 为例，其他云服务商流程类似。

### 1.2 填写基本信息

- **Country/Territory**：选择 China
- **Name**：你的真实姓名（拼音）
- **Email**：推荐 Gmail/Outlook（QQ 邮箱可能收不到验证码）
- 点击 "Verify my email"

> ⏱️ 耗时：1 分钟
> ❗ 易错点：邮箱一定要能正常收海外邮件！

### 1.3 验证邮箱

1. 打开邮箱，找到 Oracle Cloud 发的验证邮件
2. 复制 6 位验证码
3. 粘贴回注册页面，点击 "Verify Code"

### 1.4 设置密码

密码要求：至少 8 个字符，含大写 + 小写 + 数字 + 特殊字符

> 💡 建议格式：`MyCloud2026!` 这种

### 1.5 选择主区域（⚠️ 最重要！）

**选定后无法更改！** 推荐：

| 区域 | 推荐指数 | 说明 |
|------|---------|------|
| 🇯🇵 日本东京 | ⭐⭐⭐⭐⭐ | 延迟低，容量足 |
| 🇯🇵 日本大阪 | ⭐⭐⭐⭐ | 备选 |
| 🇺🇸 美西凤凰城 | ⭐⭐⭐⭐ | 容量大 |

> ❗ 易错点：不要选新加坡/首尔！经常缺货抢不到！

### 1.6 填写地址和手机

- **Address**：随便填个英文地址（合理即可）
- **Phone**：+86 你的手机号
- 选择 "Text me a code" 收短信验证

> ❗ +86 有时收不到短信，多试几次或换个时间段

### 1.7 添加信用卡

🔒 **不会扣费！** 只是身份验证，Oracle 会预授权 $1（之后退回）

| 支持的卡 | 说明 |
|----------|------|
| ✅ Visa 信用卡/借记卡 | 推荐 |
| ✅ MasterCard 信用卡/借记卡 | 推荐 |
| ❌ 银联卡 | 不支持 |
| ❌ 预付费卡 | 大概率失败 |

> ❗ 必须是 Visa 或 MasterCard！确保卡上有 $1 余额！

### 1.8 完成注册

1. 勾选同意条款
2. 点击 "Start my free trial"
3. 等待激活（通常几分钟到几小时）

> 📍 成功标志：收到邮件 "Your Oracle Cloud account is activated" ✅

### 1.9 登录控制台

1. 访问：https://cloud.oracle.com
2. 输入 Cloud Account Name
3. 选择 "Oracle Cloud Infrastructure Direct Sign-In"
4. 输入邮箱和密码登录

### 1.10 创建服务器实例

1. 点击左上角 ☰ 汉堡菜单
2. 选择 **Compute → Instances**
3. 点击 **"Create Instance"**

配置实例：

| 配置项 | 推荐值 | 说明 |
|--------|--------|------|
| Name | `openclaw-server` | 随便起 |
| Image | **Ubuntu 24.04** | ⚠️ 一定要改！默认不是 Ubuntu |
| Shape | **VM.Standard.A1.Flex** | ARM 架构 |
| OCPUs | 4 | 免费最大 4 核 |
| Memory | 24 GB | 免费最大 24GB |
| Public IP | Assign | 必须分配公网 IP |
| SSH 密钥 | Generate | ⚠️ 下载私钥保存好！只能下载一次！ |
| Boot Volume | 200GB | 免费最大 |

> ❗ **超级易错点**：
> - 必须选 ARM（Ampere），AMD 的免费实例只有 1GB 内存几乎不能用！
> - SSH 密钥只能下载一次！关掉页面就没了！

### 1.11 等待实例创建

点击 "Create" 后，等待状态变为 **"RUNNING"**（约 2-5 分钟），记下 **Public IP Address**（如 `144.24.xxx.xxx`）。

---

### ⚠️ 中国大陆用户特别说明

可能遇到的问题：
- 🚫 中国大陆 IP 可能被限制注册
- 🚫 免费额度抢手，可能显示 "Out of capacity"
- 🚫 需要国际信用卡（Visa/MasterCard）

**解决方案：**

| 方案 | 说明 |
|------|------|
| 🟢 **方案 1：挂梯子注册（推荐）** | 用香港/日本节点，邮箱用 Gmail/Outlook，成功率 90%+ |
| 🟡 **方案 2：用其他云服务商** | AWS 12 个月免费 / Google Cloud $300 额度 / 腾讯云学生机 ¥9.9/月 |
| 🟡 **方案 3：本地运行** | Mac/Windows 直接装 OpenClaw，不用服务器但需保持开机 |

> ⚠️ **本地安装有安全风险！** Agent 拥有工作区内完整读写权限。新手强烈建议先用云服务器！
> 如果一定要本地装：workspace 设为专用目录（如 `~/clawd`），给所有 Agent 开 sandbox 隔离。

---

## 二、连接服务器（5 分钟）

### Windows 用户

**方法一：PowerShell（推荐）**

```powershell
# 1. 打开 PowerShell（Win+X → 终端）

# 2. 设置密钥权限
icacls "C:\Users\你的用户名\Downloads\ssh-key-2025-xx-xx.key" /inheritance:r /grant:r "%USERNAME%:R"

# 3. 连接服务器
ssh -i "C:\Users\你的用户名\Downloads\ssh-key-2025-xx-xx.key" ubuntu@你的服务器IP
```

**方法二：MobaXterm（图形界面）**

1. 下载：https://mobaxterm.mobatek.net/download.html
2. 打开 → Session → SSH
3. 填写 Remote host / username: `ubuntu` / Use private key
4. 点击 OK 连接

### Mac / Linux 用户

```bash
# 1. 设置密钥权限
chmod 400 ~/Downloads/ssh-key-2025-xx-xx.key

# 2. 连接服务器
ssh -i ~/Downloads/ssh-key-2025-xx-xx.key ubuntu@你的服务器IP
```

### 首次连接确认

首次会提示 `Are you sure you want to continue connecting (yes/no)?`，输入 `yes` 回车。

> 📍 成功标志：看到 `ubuntu@openclaw-server:~$` 提示符就对了！✅
>
> ❗ 用户名是 `ubuntu`，不是 `root`！如果提示 Permission denied，检查密钥路径和权限。

---

## 三、一键安装（5 分钟）

SSH 连上服务器后，复制粘贴这一行：

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/wanikua/boluobobo-ai-court-tutorial/main/install.sh)
```

脚本自动完成：系统更新、防火墙配置、Swap、Node.js 22、GitHub CLI、OpenClaw 安装、工作区初始化。

安装完成后验证：

```bash
openclaw --version
```

> ⏱️ 耗时：3-5 分钟
> 📍 成功标志：能看到版本号就对了！✅
>
> 💡 如果 npm 下载慢：`npm install -g openclaw --registry=https://registry.npmmirror.com`

---

## 四、配置 API Key（5 分钟）

### 4.1 获取 LLM API Key

1. 访问你的 LLM 服务商控制台
2. 注册/登录账号
3. 在 API Keys 页面创建新 Key
4. 复制 Key

> 🔴 **API Key 只显示一次！** 复制后妥善保存！
>
> 💡 费用说明：新账号通常有 $5 免费额度，正常使用每月 $10-30 够了。

### 4.2 保存好你的 API Key

先复制到记事本保存好，下一步会把它填进配置文件 `openclaw.json`。

> 💡 不需要设环境变量，API Key 直接写在配置文件里就行。

---

## 五、搭建朝廷架构（15 分钟）

### 5.1 自定义核心文件

一键脚本已经创建好了 `SOUL.md`、`IDENTITY.md`、`USER.md`，你只需要按需修改：

```bash
cd ~/clawd
ls -la

# 编辑个人信息
nano USER.md

# 按需修改行为准则和架构定义
nano SOUL.md
nano IDENTITY.md
```

### 5.2 配置 OpenClaw

```bash
nano ~/.openclaw/openclaw.json
```

一键脚本已生成包含 7 个部门的完整模板。基础篇只用 4 个（司礼监+兵部+户部+礼部），你可以直接在模板上修改。

**精简配置示例**（记得替换 API Key 和 Bot Token）：

```json
{
  "models": {
    "providers": {
      "your-provider": {
        "baseUrl": "https://your-llm-provider-api-url",
        "apiKey": "你的LLM_API_KEY",
        "api": "openai",
        "models": [
          {
            "id": "fast-model",
            "name": "快速模型",
            "input": ["text", "image"],
            "contextWindow": 200000,
            "maxTokens": 8192
          },
          {
            "id": "strong-model",
            "name": "强力模型",
            "input": ["text", "image"],
            "contextWindow": 200000,
            "maxTokens": 8192
          }
        ]
      }
    }
  },
  "agents": {
    "defaults": {
      "workspace": "/home/ubuntu/clawd",
      "model": { "primary": "your-provider/fast-model" },
      "sandbox": { "mode": "non-main" }
    },
    "list": [
      {
        "id": "silijian",
        "name": "司礼监",
        "model": { "primary": "your-provider/fast-model" },
        "sandbox": { "mode": "off" }
      },
      {
        "id": "bingbu",
        "name": "兵部",
        "model": { "primary": "your-provider/strong-model" },
        "identity": { "theme": "你是兵部尚书，专精软件工程、系统架构、代码审查。" },
        "sandbox": { "mode": "all", "scope": "agent" }
      },
      {
        "id": "hubu",
        "name": "户部",
        "model": { "primary": "your-provider/strong-model" },
        "identity": { "theme": "你是户部尚书，专精财务分析、成本管控、电商运营。" },
        "sandbox": { "mode": "all", "scope": "agent" }
      },
      {
        "id": "libu",
        "name": "礼部",
        "model": { "primary": "your-provider/fast-model" },
        "identity": { "theme": "你是礼部尚书，专精品牌营销、社交媒体、内容创作。" },
        "sandbox": { "mode": "all", "scope": "agent" }
      }
    ]
  },
  "channels": {
    "discord": {
      "enabled": true,
      "groupPolicy": "open",
      "allowBots": true,
      "accounts": {
        "silijian": { "name": "司礼监", "token": "司礼监的Bot Token", "applicationId": "司礼监的Application ID", "groupPolicy": "open" },
        "bingbu": { "name": "兵部", "token": "兵部的Bot Token", "applicationId": "兵部的Application ID", "groupPolicy": "open" },
        "hubu": { "name": "户部", "token": "户部的Bot Token", "applicationId": "户部的Application ID", "groupPolicy": "open" },
        "libu": { "name": "礼部", "token": "礼部的Bot Token", "applicationId": "礼部的Application ID", "groupPolicy": "open" }
      }
    }
  },
  "bindings": [
    { "agentId": "silijian", "match": { "channel": "discord", "accountId": "silijian" } },
    { "agentId": "bingbu", "match": { "channel": "discord", "accountId": "bingbu" } },
    { "agentId": "hubu", "match": { "channel": "discord", "accountId": "hubu" } },
    { "agentId": "libu", "match": { "channel": "discord", "accountId": "libu" } }
  ]
}
```

> ⚠️ **重要配置说明**：
> - `workspace` 是 Agent 的"领地"，设为 `/home/ubuntu/clawd` ✅，不要设成家目录 ❌
> - `groupPolicy: "open"` 在 channels 和每个 account 里都要加，否则群聊消息会被丢弃
> - `allowBots: true` 让 Bot 之间能互相触发回复

### 5.3 创建 Discord Bot（每个部门一个）

> 💡 多 Bot 架构：每个部门 = 一个独立的 Discord Bot！基础篇需要 4 个 Bot。

**第一步：创建 Application（重复 4 次）**

1. 打开 https://discord.com/developers/applications
2. 点击 "New Application"
3. 名字填部门名（司礼监、兵部、户部、礼部）

**第二步：创建 Bot 并获取 Token**

对每个 Application：
1. 左边菜单点 "Bot"
2. 点击 "Reset Token" → 复制 Token（只显示一次！）
3. 把 Token 填到 `openclaw.json` 的 accounts 对应位置

> ⚠️ 同一页面往下滚，**每个 Bot 都要开启**：
> - ✅ **Message Content Intent**（必须！否则收不到消息）
> - ✅ **Server Members Intent**
> - Presence Intent（可选）

**第三步：邀请所有 Bot 到你的服务器**

对每个 Application：
1. 左边菜单点 "OAuth2"
2. 勾选 `bot`
3. Bot Permissions 勾选：Send Messages ✅ / Read Message History ✅ / View Channels ✅
4. 复制生成的邀请链接 → 浏览器打开 → 选择服务器 → Authorize
5. 重复 4 次，直到 4 个 Bot 都加入

保存配置：`nano` 中按 `Ctrl+O` → 回车保存 → `Ctrl+X` 退出

---

## 六、启动并测试（5 分钟）

### 6.1 启动 Gateway

```bash
# 安装 Gateway 服务
openclaw gateway install

# 启动
systemctl --user start openclaw-gateway

# 查看状态
systemctl --user status openclaw-gateway
```

> 📍 成功标志：看到 "active (running)" 就对了！✅

### 6.2 测试对话

在 Discord 的任意频道测试：

```
@司礼监 你好，自我介绍一下
@兵部 用 Python 写个 Hello World
@户部 如何控制 AI API 成本
@礼部 写条小红书文案，主题是 AI 工具推荐
```

> 📍 成功标志：每个 Bot 的回复风格不一样就对了！🎉

### 6.3 常用命令

```bash
systemctl --user status openclaw-gateway    # 查看状态
systemctl --user restart openclaw-gateway   # 重启
journalctl --user -u openclaw-gateway --since today  # 查看日志
systemctl --user stop openclaw-gateway      # 停止
```

---

## 七、常见问题 Q&A

> 💡 更多 FAQ 见 [完整 FAQ](./faq.md) 和 [README](../README.md)

**Q: Oracle Cloud 注册一直失败？**
换梯子节点、确认 Visa/MasterCard、换 Gmail 邮箱。实在不行用 AWS/腾讯云。

**Q: 显示 "Out of capacity"？**
换区域（tokyo/osaka/phoenix）、换时间段（凌晨成功率高）、等几天再试。

**Q: SSH 连接被拒绝？**
确认实例是 RUNNING、用户名是 `ubuntu`、私钥文件正确、安全组开放 22 端口。

**Q: `openclaw` 命令找不到？**
运行 `source ~/.bashrc`，还不行就 `sudo npm install -g openclaw`。

**Q: Gateway 启动失败？**
```bash
journalctl --user -u openclaw-gateway --since today --no-pager
openclaw doctor
```
常见原因：API Key 未填、JSON 格式错误、Bot Token 无效。

---

## 八、15 张配图清单

| 编号 | 内容 | 截图位置 | 标注重点 |
|------|------|----------|----------|
| 1 | Oracle Cloud 注册页 | cloud.oracle.com | 圈出 "Sign Up" |
| 2 | 注册表单 | 邮箱输入区域 | 圈出邮箱框和验证按钮 |
| 3 | 验证邮件 | 邮箱收件箱 | 圈出 6 位验证码 |
| 4 | 密码设置 | 密码输入页面 | 标注密码要求 |
| 5 | 区域选择 | Home Region 下拉框 | 圈出 "ap-tokyo-1" |
| 6 | 信用卡填写 | 卡号输入页面 | 圈出 Visa/MasterCard |
| 7 | Oracle Cloud 控制台 | cloud.oracle.com | 圈出登录入口 |
| 8 | Instances 页面 | Compute → Instances | 圈出 "Create Instance" |
| 9 | 实例配置页 | Shape 和 SSH 密钥 | 圈出 ARM 选择 |
| 10 | 实例详情页 | 实例运行状态 | 圈出公网 IP |
| 11 | MobaXterm 配置 | Session 设置窗口 | 圈出 IP、密钥 |
| 12 | 安装完成截图 | 终端输出 | 圈出 "部署完成！" |
| 13 | LLM API 页 | 服务商控制台 | 圈出 "Create Key" |
| 14 | ~/clawd 目录 | `ls -la` 输出 | 圈出 SOUL.md 等 |
| 15 | 配置文件 | openclaw.json | 圈出 agents.list |

---

🎉 **恭喜完成！** 现在你拥有一台永久免费的云服务器和一个 AI 朝廷团队。

**下一步**：→ [进阶篇](./tutorial-advanced.md) — tmux、GitHub、Notion、Cron、Prompt 技巧
