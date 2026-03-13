# 翰林院 PR 实施计划

## 背景

将 /root/gemini-cli-novel（OmO 架构的 AI 小说创作系统）的领域知识迁移到 boluobobo-ai-court-tutorial（OpenClaw 朝廷架构），新增「翰林院」部门。

**关键区别：** OmO 用 category+skill 动态组装临时执行者，OpenClaw 用固定 Bot 互相 spawn（one-shot）。所以不迁移代码/格式，只迁移领域知识内容。

---

## 一、新增 5 个 Agent

| Agent ID | 名称 | 品级 | 模型层 | 职责 |
|----------|------|------|--------|------|
| `hanlin_zhang` | 掌院学士 | 从二品 | strong | 总编排：接用户需求、拆任务、协调全院、全书终审 |
| `hanlin_xiuzhuan` | 修撰 | 从六品 | strong | 架构设计：大纲、世界观、人物档案、多线叙事规划 |
| `hanlin_bianxiu` | 编修 | 正七品 | strong | 章节执笔：写作、修改、归档（主力 token 消耗者） |
| `hanlin_jiantao` | 检讨 | 从七品 | fast | 校对审核：文笔/逻辑/一致性检查，问题上报 |
| `hanlin_shujishi` | 庶吉士 | 无品 | fast | 资料检索：搜索前文、外部检索、参考库查询 |

**spawn 权限：**
- 掌院学士 → 可 spawn：修撰、编修、检讨、庶吉士
- 修撰 → 可 spawn：庶吉士
- 编修 → 可 spawn：庶吉士
- 检讨、庶吉士 → 不可 spawn

**identity 模板（每个 agent 的 theme 字段）：**

```
掌院学士: "你是翰林院掌院学士，从二品，统管院务。职责：接收用户的小说创作需求，拆解为具体任务，协调修撰（架构）、编修（写作）、检讨（审核）、庶吉士（检索）完成全流程。你拥有最高审核权，全书终审由你负责。遇到检讨上报的问题，由你决定退回编修修改或通过。"

修撰: "你是翰林院修撰，从六品，状元直授。职责：主导小说的架构设计——大纲、世界观、人物档案、多线叙事规划。你是编修团队的负责人，设计的架构需要逻辑严密、因果完整、伏笔自然。可调用庶吉士检索参考素材。"

编修: "你是翰林院编修，正七品。职责：根据修撰设计的大纲，逐章执笔写作。每章不少于10000中文字符，采用分段写作法（5-8个场景）。写完后负责归档（保存正文+生成摘要）。可调用庶吉士查阅前文确保一致性。"

检讨: "你是翰林院检讨，从七品。职责：校对、查阅文稿，发现错误上报。审核维度包括：文笔质量、情节逻辑、角色一致性、情感张力、叙事节奏、对话质量、描写技巧。问题分三级：🔴致命、🟡重要、🟢优化建议。审核完毕向掌院学士上报。"

庶吉士: "你是翰林院庶吉士，新科进士入院见习。职责：纯信息检索——搜索前文内容、查阅参考小说库、检索外部资料。不产出正文、不修改任何文件。检索结果如实上报给调用你的上级。"
```

---

## 二、新增 Skills

### OpenClaw Skill 格式规范

参照 `skills/quadrants/SKILL.md`，每个 skill 文件格式为：
```
---
name: skill-name
description: 触发条件描述...
---
# Skill 标题
正文内容...
```

### 6 个 Skill 目录

从 OmO 迁移领域知识（不迁移格式），源文件位于 `/root/gemini-cli-novel/.opencode/skills/`。

| Skill | 源文件 | 给谁用 |
|-------|--------|--------|
| `skills/novel-worldbuilding/` | `/root/gemini-cli-novel/.opencode/skills/novel-worldbuilding/SKILL.md` | 修撰 |
| `skills/novel-prose/` | `/root/gemini-cli-novel/.opencode/skills/novel-prose/SKILL.md` | 编修 |
| `skills/novel-review/` | `/root/gemini-cli-novel/.opencode/skills/novel-review/SKILL.md` | 检讨、掌院学士 |
| `skills/novel-archiving/` | `/root/gemini-cli-novel/.opencode/skills/novel-archiving/SKILL.md` | 编修 |
| `skills/novel-research/` | `/root/gemini-cli-novel/.opencode/skills/novel-research/SKILL.md` | 庶吉士 |
| `skills/novel-memory/` | 新写（OpenViking 集成指南） | 全员 |

额外参考 prompts（迁移其中的领域知识）：
- `/root/gemini-cli-novel/.opencode/prompts/novel-writing.md` → 编修的 skill
- `/root/gemini-cli-novel/.opencode/prompts/novel-plotting.md` → 修撰的 skill
- `/root/gemini-cli-novel/.opencode/prompts/novel-review.md` → 检讨的 skill
- `/root/gemini-cli-novel/.opencode/prompts/orchestration.md` → 掌院学士的 identity

每个 skill 目录结构：
```
skills/novel-xxx/
├── SKILL.md              # YAML frontmatter + 使用指南
└── references/
    └── xxx.md            # 详细参考资料（模板/标准/指南）
```

---

## 三、修改文件 — 精确插入点

### 3.1 install.sh

三处插入：

**agents.list（约 L251，在 xingbu agent 的 `}` 之后、`]` 之前）：**
添加 5 个 agent 对象，格式同现有 agent（id/name/model/identity/sandbox/runTimeoutSeconds/subagents）

**discord.accounts（约 L293，在 xingbu account 之后、`}` 之前）：**
添加 5 个 bot account（name/token/groupPolicy）

**bindings（约 L305，在 xingbu binding 之后、`]` 之前）：**
添加 5 条 binding

### 3.2 install-lite.sh

同 install.sh，在 Discord 模式的模板中（约 L269/L312/L323）插入同样内容。
注意：WebUI 模式（约 L160）不需要改。

### 3.3 install-mac.sh

同 install.sh，在对应位置（约 L244/L287/L298）插入。

### 3.4 gui/server/index.js

**L21-27 AGENT_DEPT_MAP** — 已有 `'hanlinyuan': '翰林院'`，需补充子 agent：
```javascript
'hanlin_zhang': '翰林院·掌院学士',
'hanlin_xiuzhuan': '翰林院·修撰',
'hanlin_bianxiu': '翰林院·编修',
'hanlin_jiantao': '翰林院·检讨',
'hanlin_shujishi': '翰林院·庶吉士',
```

### 3.5 doctor.sh

doctor.sh 不定义 agent，只做诊断检查（检查 JSON 有效性、agent 数量、binding 数量），无需改动。

### 3.6 README.md / README_EN.md

添加翰林院章节，包含：架构图、5 个角色说明、工作流、skill 列表、OpenViking 集成说明。

---

## 四、工作流

```
用户: "帮我写一部修仙小说"
  │
  └→ 掌院学士（接旨）
       │
       ├─ spawn 修撰 → 设计大纲 + 世界观 + 人物档案
       │    └─ spawn 庶吉士 → 检索参考素材
       │
       ├─ 掌院学士审批大纲 ✅
       │
       ├─ spawn 编修 → 按大纲逐章写作
       │    ├─ spawn 庶吉士 → 查前文确保一致
       │    └─ 写完一章 → 归档到 novel/{书名}/正文/
       │
       ├─ spawn 检讨 → 审核该章
       │    └─ 发现问题 → 上报掌院学士
       │
       ├─ 掌院学士决策：退回编修修改 or 通过
       │
       └─ 循环直到全书完成 → 掌院学士全书终审
```

---

## 五、OpenViking 集成

作为 MCP server 挂载，替代 Milvus + OpenMemory + Knowledge Graph：

| OpenViking | 对应原系统 | 使用场景 |
|-----------|-----------|---------|
| Memories | OpenMemory | 章节摘要、角色状态、伏笔追踪 |
| Resources | Milvus | 参考小说库、风格范本 |
| Skills | Knowledge Graph | 人物关系、世界设定 |

OpenViking 安装/配置不在本 PR 范围，仅在 `skills/novel-memory/` 中提供使用指南。

---

## 六、执行顺序

1. **Phase 1 - Skills**：创建 6 个 skill 目录（读 OmO 源文件 → 适配 OpenClaw 格式写入）
2. **Phase 2 - Agent 配置**：修改 install.sh / install-lite.sh / install-mac.sh
3. **Phase 3 - GUI**：更新 gui/server/index.js
4. **Phase 4 - 文档**：更新 README.md / README_EN.md

---

## 七、不做的事

- 不改现有六部任何配置
- 不引入新依赖
- 不改 GUI 前端组件（仅改 server 端映射）
- 不改 doctor.sh（它只做通用检查）
- OpenViking 安装不在本 PR 范围

---

## 八、验证

1. `bash doctor.sh` — 确认诊断脚本正常运行，不因新 agent 报错
2. 检查 install.sh 生成的 openclaw.json 模板是合法 JSON
3. 6 个 skill 的 SKILL.md 都有正确的 YAML frontmatter
4. README 中翰林院章节的链接和格式正确
