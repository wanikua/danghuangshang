# 🚀 朝廷进阶玩法：效率翻倍的神器（进阶篇）

> ← [返回 README](../README.md) | [📚 文档索引](./README.md)
>
> 适用人群：已搭建好朝廷，想进一步提升效率 | 预计耗时：30-40 分钟
>
> 最终效果：远程编程不断线 + 代码自动备份 + 奏折自动写 + 定时任务 + Discord 协作 + Prompt 技巧

---

## 📖 目录

1. [tmux — 远程编程神器](#一tmux--远程编程神器)
2. [GitHub 自动化 — 代码自动备份](#二github-自动化--代码自动备份)
3. [Notion 数据库 — 朝廷自动写奏折](#三notion-数据库--朝廷自动写奏折)
4. [Cron — 定时任务自动执行](#四cron--定时任务自动执行)
5. [Discord — 朝廷总部设置](#五discord--朝廷总部设置)
6. [Prompt 技巧 — 让朝廷更懂你](#六prompt-技巧--让朝廷更懂你)
7. [飞书接入](#七飞书接入--不用-discord-也能玩)
8. [Web GUI — 浏览器管理朝廷](#八web-gui--浏览器管理朝廷)
9. [预装 Skill](#九预装-skill--开箱即用的能力)
10. [Docker 部署](#十docker-部署--容器化一键启动)
11. [语义记忆搜索](#十一语义记忆搜索--让-ai-真正记住过去)

---

## 一、tmux — 远程编程神器

### 为什么需要 tmux？

- 😭 SSH 写代码写到一半，网络断了，所有进度没了
- 😭 跑个长任务，关掉终端就没了
- 😭 同时开好几个 SSH 窗口，切来切去眼花

**tmux 让你：** SSH 断线后重新连上去，所有程序还在运行；一个窗口 split 成多个面板；后台跑任务不受影响。

### 安装

```bash
sudo apt update && sudo apt install tmux -y
tmux -V   # 应显示 tmux 3.x
```

### 5 个核心命令

| 命令 | 作用 |
|------|------|
| `tmux new -s coding` | 创建名为 coding 的会话 |
| `Ctrl+B` 然后 `D` | 退出会话（保持后台运行） |
| `tmux attach -t coding` | 重新连接会话 |
| `Ctrl+B` 然后 `%` | 左右分屏 |
| `Ctrl+B` 然后 `"` | 上下分屏 |

### 分屏快捷键

| 快捷键 | 功能 |
|--------|------|
| `Ctrl+B %` | 左右分屏 |
| `Ctrl+B "` | 上下分屏 |
| `Ctrl+B 方向键` | 切换面板 |
| `Ctrl+B X` | 关闭当前面板 |
| `Ctrl+B Z` | 最大化/还原面板 |

### 实战场景

**场景 1：跑长任务**
```bash
tmux new -s training
python train.py --epochs 100
# Ctrl+B D 退出，任务继续跑
# 第二天 tmux attach -t training 回来看
```

**场景 2：远程开发 + 实时测试**
```bash
tmux new -s dev
# Ctrl+B %  左右分屏
# 左边 nano app.py 编辑代码
# 右边 python test.py 运行测试
```

### 推荐配置（可选）

```bash
cat > ~/.tmux.conf << 'EOF'
set -g mouse on
set -g history-limit 10000
set -g status-bg blue
set -g status-fg white
EOF
tmux source-file ~/.tmux.conf
```

---

## 二、GitHub 自动化 — 代码自动备份

### 配置 GitHub Skill

**1. 生成 GitHub Personal Access Token**

访问 https://github.com/settings/tokens → Generate new token (classic) → 勾选 `repo`, `workflow` → 复制 Token

> 🔴 Token 只显示一次！

**2. 配置环境变量**

```bash
echo 'export GITHUB_TOKEN="ghp_你的Token"' >> ~/.bashrc
git config --global user.name "OpenClaw 朝廷"
git config --global user.email "openclaw@your-email.com"
source ~/.bashrc
```

**3. 创建备份仓库**

```bash
cd ~/clawd
git init
git remote add origin https://github.com/你的用户名/openclaw-backup.git
```

### 使用示例

```
@兵部 把当前目录的改动提交到 GitHub，commit message 写"自动备份配置"
@兵部 在 GitHub 仓库创建一个 Issue，标题是"优化日志系统"
@兵部 为 dev 分支创建 PR 到 main 分支
```

### 自动备份脚本

```bash
cat > ~/clawd/auto-backup.sh << 'EOF'
#!/bin/bash
cd ~/clawd
git add .
git commit -m "自动备份 $(date '+%Y-%m-%d %H:%M:%S')"
git push origin main
echo "✅ 备份完成！$(date)"
EOF
chmod +x ~/clawd/auto-backup.sh
```

配合 crontab 每天凌晨自动备份：

```bash
crontab -e
# 添加：0 3 * * * cd ~/clawd && ./auto-backup.sh >> ~/clawd/backup.log 2>&1
```

---

## 三、Notion 数据库 — 朝廷自动写奏折

> 📖 完整 Notion 配置见 [Notion 接入指南](./notion-setup.md)

### 快速配置

1. 访问 https://www.notion.so/my-integrations → 创建 Integration → 复制 Token
2. 在 Notion 页面 → `···` → Connect to → 选择你的 Integration
3. 配置环境变量：

```bash
echo 'export NOTION_TOKEN="secret_你的NotionToken"' >> ~/.bashrc
source ~/.bashrc
```

### 使用场景

```
@司礼监 生成今天的日报，写入 Notion 日报数据库
@司礼监 在 Notion 周报数据库创建本周周报
@司礼监 更新 Notion 项目数据库，pindoudou 项目进度 65%
@户部 在 Notion 财务数据库添加记录：API 费用 $2.5
```

---

## 四、Cron — 定时任务自动执行

### 两种定时任务

| 类型 | 用途 | 配置方式 |
|------|------|----------|
| **Linux crontab** | 跑 bash 脚本（备份、清理等） | `crontab -e` |
| **OpenClaw cron** | 让 AI 执行任务（写日报、查数据等） | `openclaw cron add` |

> 简单规则：不需要 AI 思考的 → Linux crontab；需要 AI 动脑的 → OpenClaw cron

### crontab 语法

```
# 分 时 日 月 周  命令
  *  *  *  *  *  command
```

| 表达式 | 含义 |
|--------|------|
| `0 9 * * *` | 每天早上 9 点 |
| `0 9 * * 1` | 每周一早上 9 点 |
| `0 0 1 * *` | 每月 1 号凌晨 |
| `*/5 * * * *` | 每 5 分钟 |

### OpenClaw Cron 实战

```bash
# 先获取 Gateway Token
openclaw gateway token

# 每日自动日报
openclaw cron add \
  --name "每日日报" --agent silijian \
  --cron "0 22 * * *" --tz "Asia/Shanghai" \
  --message "生成今日日报，写入 Notion 日报数据库" \
  --session isolated --token 你的token

# 服务器健康检查（每 6 小时）
openclaw cron add \
  --name "健康检查" --agent silijian \
  --cron "0 */6 * * *" --tz "Asia/Shanghai" \
  --message "检查服务器 CPU、内存、磁盘使用率" \
  --session isolated --token 你的token

# 每月财务汇总
openclaw cron add \
  --name "月度财务" --agent hubu \
  --cron "0 20 1 * *" --tz "Asia/Shanghai" \
  --message "汇总本月所有 API 花费，写入 Notion 财务数据库" \
  --session isolated --token 你的token
```

> ⚠️ OpenClaw cron 必须用命令行添加，不能写在 `openclaw.json` 里！

---

## 五、Discord — 朝廷总部设置

### 推荐频道架构

```
🏯 菠萝王朝
├── 📜 本纪（奏报频道）
│   ├── 📅 起居注（日报）
│   ├── 📊 朔望录（周报）
│   └── 🌙 编年纪（月报）
├── 🏢 六部（部门频道）
│   ├── ⚔️ 兵部 / 💰 户部 / 🎋 礼部
│   ├── 🔧 工部 / 👥 吏部 / ⚖️ 刑部
├── 🤖 中枢（命令中心 / 日志 / 通知）
└── 💬 闲聊（茶水间 / 灵感交流）
```

### 权限设置建议

| 角色 | 权限 | 适用人群 |
|------|------|----------|
| @尚书 | 管理员权限 | 老板/创始人 |
| @侍郎 | 高级成员 | 核心团队 |
| @主事 | 普通成员 | 一般成员 |
| @观察员 | 只读 | 投资人/顾问 |

### Bot 配置要点

- 每个 Bot 在 Developer Portal 都要开启 **Message Content Intent** + **Server Members Intent**
- `groupPolicy: "open"` 在 channels 和每个 account 里都要加
- `allowBots: true` 让 Bot 之间能互相触发

---

## 六、Prompt 技巧 — 让朝廷更懂你

### 万能公式

**【角色】+【任务】+【背景】+【要求】+【格式】**

### 各部门 Prompt 模板

| 部门 | Prompt 模板 |
|------|-------------|
| 兵部 | "请用【语言/框架】实现【功能】，要求：【性能/安全/规范】" |
| 户部 | "请分析【数据】，重点关注：【指标1/指标2/异常检测】" |
| 礼部 | "请为【产品】撰写【内容类型】，目标受众【人群】，发布在【平台】" |
| 吏部 | "请为【项目】制定【计划类型】，包括：时间节点/里程碑/风险" |
| 刑部 | "请审查【文档/合同】，重点关注：合规/风险条款/缺失内容" |
| 工部 | "请为【服务】设计【部署方案】，要求：可用性/扩展性/监控" |

### 高级技巧

1. **分步拆解**：复杂任务拆成 3-5 步，每步单独下令
2. **提供示例**："参考这个风格写……"
3. **指定格式**："用表格/Markdown/分点列出"
4. **设定约束**："不超过 500 字"、"只用标准库"
5. **追问迭代**：第 1 轮生成 → 第 2 轮对比 → 第 3 轮优化

---

## 七、飞书接入 — 不用 Discord 也能玩

> 📖 完整指南见 [飞书配置指南](../飞书配置指南.md) 和 [飞书部署文档](./setup-feishu.md)

**快速 4 步**：

1. [飞书开放平台](https://open.feishu.cn/app) 创建自建应用 → 复制 App ID + App Secret
2. 权限管理 → 添加 9 个权限 → 应用能力 → 开启机器人 → 事件订阅 WebSocket
3. `openclaw channels add` 或手动编辑 `openclaw.json`
4. 发布应用 + `openclaw gateway restart`

---

## 八、Web GUI — 浏览器管理朝廷

> 📖 完整 GUI 说明见 [GUI 文档](./gui.md)

```bash
cd gui && npm install && npm run build
cd server && npm install
BOLUO_AUTH_TOKEN=你的密码 node index.js
# 访问 http://你的服务器IP:18795
```

功能：仪表盘 / 朝堂对话 / 会话管理 / Cron 管理 / Token 统计 / 系统健康。

---

## 九、预装 Skill — 开箱即用的能力

| Skill | 说明 | 需要 API Key |
|-------|------|:---:|
| `weather` | 天气查询 | ❌ |
| `github` | GitHub Issue/PR/CI | ❌（需 `gh auth login`） |
| `notion` | Notion 页面/数据库 | ✅ |
| `hacker-news` | HN 浏览和搜索 | ❌ |
| `browser-use` | 浏览器自动化 | ❌ |
| `quadrants` | 四象限任务管理 | ✅ |
| `openviking` | 向量知识库 | ✅ |

安装更多 Skill：`openclaw skill install <skill名>`

---

## 十、Docker 部署 — 容器化一键启动

```bash
git clone https://github.com/wanikua/danghuangshang.git
cd danghuangshang
cp openclaw.example.json openclaw.json
nano openclaw.json   # 填入 API Key 和 Bot Token
docker compose up -d
docker compose logs -f
```

> 📖 完整 Docker 部署见 [Docker 部署指南](./setup-docker.md)

---

## 十一、语义记忆搜索 — 让 AI 真正记住过去

Clawdbot 的 `memory-core` 插件支持用**向量索引**对记忆文件做语义搜索。但这需要一个 **Embedding API** — 没有配置的话，AI 只能靠关键词精确匹配来找历史笔记。

### 为什么重要？

- ❌ 没有 Embedding：问"上周聊的部署方案"→ 找不到
- ✅ 有 Embedding：问"上周聊的部署方案"→ 能匹配到"Docker 容器化迁移"的记录

### 三种方案（任选其一）

| 方案 | 提供商 | 国内直连 | 推荐 |
|------|--------|:--------:|:----:|
| OpenAI | `text-embedding-3-small` | ❌ | 海外服务器 |
| Google Gemini | `gemini-embedding-001` | ❌ | 免费额度大 |
| 阿里 DashScope | `text-embedding-v3` | ✅ | 🌟 国内首选 |

### DashScope 快速配置（国内推荐）

```json5
// openclaw.json → agents.defaults 中添加
"memorySearch": {
  "provider": "openai",
  "model": "text-embedding-v3",
  "remote": {
    "baseUrl": "https://dashscope.aliyuncs.com/compatible-mode/v1/",
    "apiKey": "sk-你的DashScope-Key",
    "batch": { "enabled": false }  // ⚠️ 必须关闭
  }
}
```

验证：

```bash
clawdbot memory status --deep   # Embeddings: ready = 成功
clawdbot memory index           # 建立索引
clawdbot memory search "测试搜索"  # 测试语义搜索
```

> 📖 完整配置指南（含 OpenAI / Gemini / 本地模型 / 混合搜索 / 会话索引）见 [语义记忆搜索配置指南](./memory-search.md)

---

🎉 **恭喜完成进阶篇！** 有问题欢迎在小红书「菠萝菠菠🍍」交流，关注公众号「菠言菠语」获取最新教程。
