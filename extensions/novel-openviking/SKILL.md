---
name: novel-openviking
description: "[扩展] 翰林院 OpenViking 增强 - 为小说记忆系统接入语义搜索、自动摘要和知识图谱。需要先安装 OpenViking。关键词：OpenViking、语义搜索、知识图谱、记忆增强。"
---

# 翰林院 OpenViking 增强（可选扩展）

你已被注入 `novel-openviking` 技能。本技能在 `novel-memory` 的文件系统记忆之上，叠加 OpenViking 的语义搜索和知识图谱能力。

> 本技能是**可选增强**，不是必需品。没有本技能时，翰林院使用文件系统正常工作。

---

## 启用条件

本技能仅在 OpenViking MCP server 已配置并可用时生效。检测方法：

```bash
bash skills/openviking/scripts/viking.sh info
```

如果命令报错，说明 OpenViking 未安装，忽略本技能的全部指令，回退到 `novel-memory` 的纯文件模式。

---

## 增强能力

| 能力 | 纯文件模式 | + OpenViking |
|------|-----------|-------------|
| 设定查询 | grep 关键词搜索 | 语义搜索，模糊匹配 |
| 章节回顾 | 读 summary 文件 | L0/L1/L2 分层摘要，按需加载 |
| 关系检查 | 读 relations.md | 知识图谱遍历，自动发现隐含关系 |
| 跨章追踪 | 手动翻阅前文 | 语义检索，一步定位相关段落 |

---

## OpenViking 三维映射

在文件系统记忆的基础上，同步数据到 OpenViking 三个模块：

| OpenViking 模块 | 同步来源 | 增强能力 |
|----------------|---------|---------|
| **Memories** | `设定/` + `summary/` 全部文件 | 语义搜索 + 自动摘要分层 |
| **Resources** | 外部参考素材 | 风格参考检索 |
| **Skills** | `设定/relations.md` + `world.md` | 结构化知识图谱浏览 |

---

## 使用方式

### 索引设定文件（新书启动或设定大改后）

```bash
bash skills/openviking/scripts/viking.sh add-dir novel/{书名}/设定/
```

### 索引章节摘要（每章归档后）

```bash
bash skills/openviking/scripts/viking.sh add novel/{书名}/summary/chapter_XX.md
```

### 语义查询（替代 grep）

```bash
# 查询角色相关设定
bash skills/openviking/scripts/viking.sh search "林晓的性格特征和成长经历"

# 查询跨章伏笔
bash skills/openviking/scripts/viking.sh search "青铜匕首的来历和出现场景"

# 查询世界设定
bash skills/openviking/scripts/viking.sh search "魔法体系的等级限制"
```

### 风格参考检索

```bash
# 先索引参考素材
bash skills/openviking/scripts/viking.sh add-dir ./参考素材/

# 检索特定风格
bash skills/openviking/scripts/viking.sh search "悬疑氛围的开场描写手法"
```

---

## 工作流变化

启用本扩展后，`novel-memory` 的操作流程变为：

```
原：写入设定文件 → 完成
增强：写入设定文件 → 同步索引到 OpenViking → 完成

原：grep 搜索设定 → 获取结果
增强：OpenViking 语义搜索 → 获取结果（更准确，支持模糊匹配）
```

**原则：文件系统是 source of truth，OpenViking 是索引层。** 数据始终先写入文件，再同步到 OpenViking。丢失 OpenViking 数据时，可从文件重建索引。

---

## 安装方式

### 1. 先安装 OpenViking

见 `skills/openviking/SKILL.md`。

### 2. 安装本插件

```bash
# 从本地安装
openclaw plugins install ./extensions/novel-openviking

# 启用
openclaw plugins enable novel-openviking
```

### 3. 管理

```bash
# 查看状态
openclaw plugins list

# 关闭（不删除，可随时重新启用）
openclaw plugins disable novel-openviking
```

安装后插件会注册两个工具供翰林院 agent 调用：
- `novel_viking_search` — 语义搜索设定和前文
- `novel_viking_index` — 将文件索引到 OpenViking
