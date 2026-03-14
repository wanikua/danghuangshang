---
name: novel-openviking
description: 翰林院 OpenViking 记忆增强 — 将小说写作 pipeline 的设定、摘要、伏笔接入 OpenViking 语义记忆。关键词：OpenViking、语义搜索、记忆增强、小说设定。
---

# 翰林院 OpenViking 记忆增强

本技能在 `novel-memory` 的文件系统记忆之上，将写作 pipeline 接入 OpenViking 语义记忆。

> 前置：`memory-openviking` 插件已启用（提供 `memory_recall` / `memory_store` / `memory_forget` 工具）。

---

## 核心原则

**文件是 source of truth，OpenViking 是语义索引层。**

- 所有设定、摘要、伏笔先写入文件（按 `novel-memory` 技能规范）
- 再通过 `memory_store` 同步关键信息到 OpenViking
- 查询时优先用 `memory_recall` 语义搜索，比 grep 更精准
- OpenViking 数据丢失时，可从文件重建

---

## 写入同步：什么信息要 memory_store

### 新书初始化后

```
memory_store: "{角色名}的人物档案：{性格}、{背景}、{动机}、{能力}"
memory_store: "世界观核心规则：{力量体系}、{社会结构}、{地理环境}"
memory_store: "故事主线：{核心冲突}、{主角目标}、{主要矛盾}"
```

### 每章归档后（配合 novel-archiving）

文件归档完成后，追加同步：

```
memory_store: "第X章摘要：{核心事件}；{角色状态变化}"
memory_store: "伏笔F{XXX}：{描述}，第X章埋设，预计第Y章回收"
memory_store: "{角色名}当前状态：位于{地点}，情绪{状态}，与{角色}关系变为{关系}"
```

### 设定变更时

```
memory_store: "{角色名}获得新能力：{能力描述}，来源：第X章{事件}"
memory_store: "新势力出现：{势力名}，{立场}，与{现有势力}的关系"
```

---

## 语义查询：什么时候用 memory_recall

### 写作前（novel-prose）

```
memory_recall: "{角色名}的性格特征和当前状态"     → 确保人设一致
memory_recall: "第X章到第Y章的情节发展"           → 回顾上下文
memory_recall: "与{场景关键词}相关的世界设定"      → 确认设定细节
```

### 审核时（novel-review）

```
memory_recall: "{角色名}在前文中的行为模式"       → 验证角色一致性
memory_recall: "未回收的伏笔"                    → 检查伏笔遗漏
memory_recall: "{设定关键词}"                    → 交叉验证设定冲突
```

### 架构设计时（novel-worldbuilding）

```
memory_recall: "已有的世界观规则"                 → 避免设定矛盾
memory_recall: "现有角色的关系网络"               → 设计新角色时考虑已有关系
```

---

## 与纯文件模式的区别

| 操作 | 纯文件模式 | + OpenViking |
|------|-----------|-------------|
| 查设定 | grep 关键词 → 精确匹配 | memory_recall → 语义模糊匹配 |
| 回顾前文 | 逐个读 summary 文件 | memory_recall → 一步定位相关章节 |
| 查伏笔 | 读 foreshadowing.md | memory_recall "未回收伏笔" → 语义聚合 |
| 存设定 | 写文件 | 写文件 + memory_store 同步 |

---

## 注意事项

1. **不要跳过文件写入**：即使有 OpenViking，设定文件仍然是权威数据源
2. **store 内容要精炼**：存入的是摘要级信息，不是全文
3. **recall 结果要验证**：语义搜索可能返回不精确的结果，关键设定以文件为准
