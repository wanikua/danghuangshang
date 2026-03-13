# 📜 Changelog

## v3.5.2 (2026-03-13)

### Bug 修复
- **H-01** `install.sh` — nvm/volta/fnm 环境下不再使用 sudo 安装全局 npm 包，避免系统 npm 与用户 npm 路径冲突
- **H-05** `gui/server/index.js` — `/api/health` 中 wss/sseClients/metricsBuffer 引用改为 optional chaining，消除死代码风险
- **H-06** `openclaw.example.json` — `$HOME/clawd` 替换为 `/home/YOUR_USERNAME/clawd` 占位符，JSON 不再依赖 shell 变量展开
- **H-07** `install.sh` — heredoc 中 `$HOME` 增加空值保护（`${HOME:-/root}`）及空格路径警告
- **H-09** `gui/server/index.js` — `countSessionFile` 从同步 readSync 改为异步 readline stream，不再阻塞 Node 事件循环；新增 50MB 文件大小上限跳过

---

## v3.5.1 (2026-03-12)

### 优化
- **README 重构** — 精简为 ~400 行引导页，详细教程拆分到 `docs/` 目录
- 修复飞书权限数量描述（8→9 个）
- 飞书排查权限表补全 `contact:user.employee_id:readonly`
- 修复 Sandbox 锚点链接
- 插入 mascot 图片
- OpenClaw Hub 链接统一为 OpenClaw Skill 生态
- `clawdhub install` 命令更新为 `openclaw skill install`
- 基础篇/进阶篇 txt 转 markdown 格式（`docs/tutorial-basics.md`、`docs/tutorial-advanced.md`）
- 新增 `docs/` 文档索引和多个拆分文档

---

## v3.5 (2026-03-12)

### 新功能
- **预装 7 个 Skill** — weather / github / notion / hacker-news / browser-use / quadrants / openviking
- **飞书配置全面优化** — 所有示例统一 dmPolicy/groupPolicy/botName，权限表补全到 8 项
- **GUI 品牌可配置** — 通过 `VITE_BRAND_NAME` 环境变量自定义品牌名
- **install.sh 安装后自动运行 doctor.sh** 健康检查
- **新增 CONTRIBUTING.md** 贡献指南和 skills/README.md 索引

### Bug 修复
- README 飞书配置示例缺 groupPolicy、结构过时（appId 不在 accounts 里）
- README/README_EN 排查指南权限表从 3 个补全到 8 个
- README 架构图司礼监标注 (main) → (silijian)
- Court.tsx core agent filter 未包含 silijian
- openclaw.example.json 缺少翰林院的 Discord account 和 binding
- Dockerfile `COPY skills/` 路径硬编码
- docker-compose.yml 移除废弃的 `version: '3.8'`
- 基础篇.txt 云服务商占位符替换为 Oracle Cloud 实际链接

### 优化
- doctor.sh 新增 dmPolicy 和顶层 groupPolicy 检查项
- install.sh 飞书安装指引补权限步骤和文档链接
- README_EN 同步预装 Skill 章节和 60+ Skill 措辞

---

## v3.4 (2026-03-11)

### 新功能
- **飞书配置指南** — 完整的飞书接入文档（500+ 行）
- **doctor.sh 飞书诊断** — 自动检测飞书 appId/appSecret/权限/事件订阅
- **GUI 多框架支持** — 自动检测 OpenClaw/Clawdbot CLI 和配置目录
- **Docker 部署** — Dockerfile + docker-compose + entrypoint 初始化

### Bug 修复
- GUI 部门映射修正（libu=礼部, libu2=吏部）
- GUI 兼容 `.openclaw` 和 `.clawdbot` 配置目录
- GUI 支持 silijian 和 main 两种 agent id
- Dockerfile/docker-compose 路径参数化

---

## v3.0 (2026-03-10)

### 新功能
- **一键安装脚本三合一** — install.sh (Linux) / install-lite.sh / install-mac.sh
- **多部署模式** — Discord 多Bot / 飞书多Bot / 纯 WebUI
- **Web GUI** — React + TypeScript Dashboard（朝堂、会话、Token、Cron 等）
- **OpenViking Skill** — 向量知识库集成
- **Quadrants Skill** — 四象限任务管理

---

## v2.0 (2026-02-22)

### 首次发布
- 三省六部制 × OpenClaw 多 Agent 架构
- 10 Agent 模板（司礼监 + 内阁 + 都察院 + 六部 + 翰林院）
- 内置审批流程（代码→都察院审查，重大决策→内阁审议）
- Discord 多 Bot 模式
- 小红书系列教程配套文字稿
