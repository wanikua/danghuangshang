# 版本更新日志

> 记录每个版本的变更、新增功能、Breaking Changes

---

## v3.6.0 (2026-03-21) - 任务状态机与上下文压缩

**新增功能**：
- ✅ `scripts/task-store.js` - 任务状态共享存储
  - 创建/更新/查询任务状态
  - 自动聚合上游输出作为下游输入
  - 支持错误分类（transient/permanent/rejected）
- ✅ `scripts/context-compressor.js` - 智能上下文压缩
  - 识别 10+ 种消息类型
  - 保留关键信息，压缩讨论过程
  - 自动生成摘要
- ✅ `docs/task-state-machine.md` - 使用指南

**配置更新**：
- ✅ `configs/ming-neige/agents/silijian.md` - 集成任务状态机和上下文压缩

**修复问题**：
- 🔧 信息孤岛 - 上游输出自动传递给下游
- 🔧 状态黑盒 - 统一状态机（pending/running/success/failed）
- 🔧 Context 爆炸 - 智能压缩，保留关键信息
- 🔧 错误裸奔 - 分类处理（重试/打回/驳回）

**Breaking Changes**：无（向后兼容）

---

## v3.5.3 (2026-03-21) - 安装脚本修复

**新增功能**：
- ✅ `scripts/full-install.sh` - 远程一键安装脚本
  - 支持 `bash <(curl -fsSL ...)` 执行
  - 自动克隆仓库到临时目录
  - 完整安装流程

**修复问题**：
- 🔧 `install.sh` 通过 curl 管道执行时报 `/dev/fd` 路径错误
- 🔧 README 安装说明不清晰

**配置更新**：
- ✅ `install.sh` - 增加管道执行检测
- ✅ `README.md` - 区分本地安装和远程安装

**Breaking Changes**：无（向后兼容）

---

## v3.5.2 (2026-03-20) - 安全更新体系

**新增功能**：
- ✅ `scripts/safe-update.sh` - 安全更新脚本
  - 更新前自动备份配置
  - 安全检查（allowBots, mentionPatterns）
  - 支持一键回滚
- ✅ `scripts/pre-update-check.sh` - 更新前检查

**修复问题**：
- 🔧 更新时配置被覆盖
- 🔧 缺少备份机制

**Breaking Changes**：无（向后兼容）

---

## v3.5.1 (2026-03-20) - Discord 安全配置

**修复问题**：
- 🔴 `allowBots: true` → `allowBots: "mentions"`
  - 防止 Bot 无限循环互@
  - Issue #107 核心修复

**配置更新**：
- ✅ 所有配置模板更新 `allowBots: "mentions"`
- ✅ `docs/discord-safety.md` - Discord 安全配置指南

**Breaking Changes**：⚠️ 需要用户手动更新配置

---

## v3.5.0 (2026-03-20) - 三种制度完整支持

**新增功能**：
- ✅ 唐朝三省制配置（configs/tang-sansheng/）
- ✅ 现代企业制配置（configs/modern-ceo/）
- ✅ `scripts/switch-regime.sh` - 制度切换脚本

**配置更新**：
- ✅ 所有制度配置包含完整 openclaw.json
- ✅ 所有制度配置包含独立 agents/*.md 人设文件

**Breaking Changes**：无（向后兼容）

---

## v3.4.0 (2026-03-19) - 人设分离架构

**新增功能**：
- ✅ 人设独立文件存储（agents/*.md）
- ✅ `scripts/init-personas.sh` - 人设恢复脚本
- ✅ `scripts/extract-personas.sh` - 人设提取脚本

**修复问题**：
- 🔧 更新时人设被覆盖
- 🔧 配置和人设耦合

**Breaking Changes**：⚠️ 需要运行 `init-personas.sh` 迁移

---

## v3.3.0 (2026-03-18) - 记忆备份系统

**新增功能**：
- ✅ `scripts/memory-backup.sh` - 记忆备份脚本
  - SQLite 数据库备份
  - 工作区记忆文件备份
  - 自动定时备份（cron）

**Breaking Changes**：无（向后兼容）

---

## v3.2.0 (2026-03-17) - 飞书集成

**新增功能**：
- ✅ 飞书通道支持
- ✅ `docs/feishu-integration.md` - 飞书配置指南
- ✅ `docs/setup-feishu.md` - 飞书部署教程

**Breaking Changes**：无（向后兼容）

---

## v3.1.0 (2026-03-16) - GUI 管理界面

**新增功能**：
- ✅ Web Dashboard（gui/ 目录）
- ✅ 朝堂总览、会话管理、Cron 可视化
- ✅ Token 统计、系统健康监控

**Breaking Changes**：无（向后兼容）

---

## v3.0.0 (2026-03-15) - OpenClaw 架构升级

**重大变更**：
- 🎉 基于 OpenClaw 框架重构
- 🎉 多 Agent 协作架构
- 🎉 60+ Skill 生态

**Breaking Changes**：⚠️ 不兼容旧版本，需重新安装

---

## 版本规范

**版本号格式**：`v<主版本>.<次版本>.<修订号>`

- **主版本**：不兼容的 API 变更
- **次版本**：向后兼容的功能新增
- **修订号**：向后兼容的问题修复

**更新日志格式**：
```markdown
## vX.Y.Z (YYYY-MM-DD) - 简短描述

**新增功能**：
- ✅ 功能描述

**修复问题**：
- 🔧 问题描述

**配置更新**：
- ✅ 文件变更

**Breaking Changes**：无 / ⚠️ 需要...
```

---

## 升级指南

### 从 v3.5.x 升级到 v3.6.0

```bash
# 1. 备份配置
bash scripts/safe-update.sh --backup

# 2. 拉取最新代码
cd ~/clawd
git pull

# 3. 新功能无需迁移
# task-store.js 和 context-compressor.js 可选使用

# 4. 验证
openclaw status

# 5. 重启
openclaw gateway restart
```

### 从 v3.4.x 升级到 v3.5.0

```bash
# 1. 备份配置
bash scripts/safe-update.sh --backup

# 2. 拉取最新代码
cd ~/clawd
git pull

# 3. 更新 Discord 安全配置（重要！）
# 将 allowBots: true 改为 allowBots: "mentions"
# 或使用脚本自动修复
node scripts/fix-allowbots.js

# 4. 验证
openclaw doctor

# 5. 重启
openclaw gateway restart
```

---

**查看完整 Git 历史**：
```bash
git log --oneline --all
```
