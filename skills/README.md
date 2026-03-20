# 📦 预装 Skill

本项目预装了以下 Skill，放在工作区的 `skills/` 目录下即可被 Agent 自动识别和使用。

## Skill 列表

| Skill | 说明 | 需要 API Key | 文档 |
|-------|------|:---:|------|
| [weather](./weather/) | 天气查询（wttr.in / Open-Meteo） | ❌ | [SKILL.md](./weather/SKILL.md) |
| [github](./github/) | GitHub Issue/PR/CI 操作（gh CLI） | ❌* | [SKILL.md](./github/SKILL.md) |
| [notion](./notion/) | Notion 页面/数据库管理 | ✅ | [SKILL.md](./notion/SKILL.md) |
| [hacker-news](./hacker-news/) | Hacker News 浏览和搜索 | ❌ | [SKILL.md](./hacker-news/SKILL.md) |
| [browser-use](./browser-use/) | 浏览器自动化、社媒管理 | ❌ | [SKILL.md](./browser-use/SKILL.md) |
| [quadrants](./quadrants/) | 四象限任务管理（quadrants.ch） | ✅ | [SKILL.md](./quadrants/SKILL.md) |
| [openviking](./openviking/) | 向量知识库（火山引擎开源） | ✅ | [SKILL.md](./openviking/SKILL.md) |
| [self-improving-agent](./self-improving-agent/) | 自我改进：记录错误、学习和纠正 | ❌ | [SKILL.md](./self-improving-agent/SKILL.md) |

> \* GitHub Skill 需要先运行 `gh auth login` 登录 GitHub 账号。

## 安装更多 Skill

通过 OpenClaw Skill 生态安装：

```bash
# 搜索
openclaw skill search "关键词"

# 安装
openclaw skill install skill-name

# 查看已安装
openclaw skill list
```

## 自定义 Skill

每个 Skill 是一个目录，至少包含 `SKILL.md`（指令文件）：

```
skills/
└── my-skill/
    ├── SKILL.md          # 必须：Agent 的使用说明
    ├── scripts/          # 可选：Shell/Python 脚本
    └── references/       # 可选：参考文档
```

`SKILL.md` 的 frontmatter 格式：

```yaml
---
name: my-skill
description: 这个 Skill 做什么的简短描述
---

# My Skill

Agent 看到的使用说明...
```

放到 `skills/` 目录后，Agent 会自动检测并在需要时加载。
