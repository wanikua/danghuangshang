# 安装验证指南

## ✅ 验证人设是否正确注入

安装完成后，检查配置文件确认人设已正确注入：

```bash
# 检查配置文件
cat ~/.openclaw/openclaw.json | jq '.agents.list[0].identity.theme' | head -20
```

**正确输出示例**（应该看到完整人设，不是占位符）：

```
"你是 AI 朝廷的司礼监大内总管。你的职责是【规划调度】，不是亲自执行。说话简练干脆。

【核心原则】除了日常闲聊和简单问答，所有涉及实际工作的任务（写代码、查资料、分析数据、写文案、运维操作等），必须先经内阁优化再派发。你是调度枢纽，不是搬砖工。

【任务流程——内阁前置】收到用户任务后：
1. 先用 sessions_spawn 或 sessions_send 将原始任务发给内阁（agentId: neige），请内阁优化 Prompt、生成执行计划（plan）、判断是否缺失关键 context；
..."
```

**错误输出示例**（占位符文本）：

```
"你是 AI 朝廷的总管，负责日常对话和任务调度。回答用中文，简洁高效。"
```

---

## 🔍 验证所有 agent 是否都有人设

```bash
# 检查所有 agent 的人设
cat ~/.openclaw/openclaw.json | jq '.agents.list[] | {id: .id, name: .name, hasIdentity: (.identity.theme | length > 50)}'
```

**正确输出**：所有 agent 的 `hasIdentity` 应为 `true`

```json
{"id":"silijian","name":"司礼监","hasIdentity":true}
{"id":"neige","name":"内阁","hasIdentity":true}
{"id":"duchayuan","name":"都察院","hasIdentity":true}
{"id":"bingbu","name":"兵部","hasIdentity":true}
...
```

---

## 📊 各安装脚本对比

| 脚本 | 适用场景 | 人设注入 | 推荐度 |
|------|---------|---------|--------|
| **scripts/full-install.sh** | 首次安装（完整） | ✅ 包含 | ⭐⭐⭐⭐⭐ |
| **install-lite.sh** | 已有 OpenClaw | ✅ 包含 | ⭐⭐⭐⭐ |
| **install-mac.sh** | macOS 专用 | ✅ 包含 | ⭐⭐⭐⭐ |
| **install.ps1** | Windows 专用 | ✅ 包含 | ⭐⭐⭐⭐ |

---

## 🐛 如果人设丢失

### 症状
- agent 的 identity.theme 很短（< 50 字符）
- 使用的是通用占位符文本

### 原因
- 使用了旧版安装脚本（未包含人设注入）
- 手动下载了 openclaw.json 模板

### 解决方案

#### 方案 1: 重新运行安装脚本

```bash
# 备份现有配置
cp ~/.openclaw/openclaw.json ~/.openclaw/openclaw.json.bak

# 重新运行安装脚本（会跳过已存在的步骤）
bash install-lite.sh
```

#### 方案 2: 手动注入人设

```bash
cd /path/to/danghuangshang
CONFIG_FILE=~/.openclaw/openclaw.json
AGENTS_DIR=configs/ming-neige/agents

for agent_file in "$AGENTS_DIR"/*.md; do
  agent_id=$(basename "$agent_file" .md)
  persona=$(tail -n +3 "$agent_file")
  persona_escaped=$(echo "$persona" | jq -Rs '.')
  
  jq --arg id "$agent_id" --argjson p "$persona_escaped" \
    '.agents.list = [.agents.list[] | if .id == $id then .identity.theme = $p else . end]' \
    "$CONFIG_FILE" > "${CONFIG_FILE}.tmp" && mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
done

echo "✅ 人设注入完成"
```

---

## 📝 人设文件位置

人设源文件位于：

```
configs/ming-neige/agents/
├── silijian.md      # 司礼监
├── neige.md         # 内阁
├── duchayuan.md     # 都察院
├── bingbu.md        # 兵部
├── hubu.md          # 户部
├── libu.md          # 吏部
├── libu2.md         # 礼部
├── gongbu.md        # 工部
├── xingbu.md        # 刑部
└── hanlin_*.md      # 翰林院各职位
```

每个文件结构：
```markdown
# 标题（第 1 行）
## 副标题（第 2 行）

正文人设内容（从第 3 行开始）
```

安装脚本会提取第 3 行之后的所有内容注入到配置文件。
