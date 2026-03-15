# 🤝 贡献指南

感谢你对 AI 朝廷项目的兴趣！欢迎提交 Issue、PR 或建议。

## 项目结构

```
├── README.md / README_EN.md    # 主文档
├── 飞书配置指南.md               # 飞书详细指南
├── 基础篇.txt / 进阶篇.txt      # 小红书视频配套文字稿
├── openclaw.example.json        # 配置模板
├── install.sh                   # Linux 一键安装脚本
├── install-lite.sh              # 精简安装（已有 OpenClaw）
├── install-mac.sh               # macOS 安装脚本
├── doctor.sh                    # 配置诊断脚本
├── Dockerfile                   # Docker 镜像
├── docker-compose.yml           # Docker Compose 编排
├── docker/entrypoint.sh         # Docker 入口脚本
├── docs/                        # 补充文档
│   └── windows-wsl.md           # Windows WSL2 指南
├── gui/                         # Web 管理后台
│   ├── src/                     # React + TypeScript 前端
│   ├── server/                  # Express + WebSocket 后端
│   └── README.md                # GUI 开发文档
├── skills/                      # 预装 Skill
│   ├── README.md                # Skill 总索引
│   ├── weather/                 # 天气查询
│   ├── github/                  # GitHub 操作
│   ├── notion/                  # Notion 管理
│   ├── hacker-news/             # HN 浏览
│   ├── browser-use/             # 浏览器自动化
│   ├── quadrants/               # 四象限任务
│   └── openviking/              # 向量知识库
├── images/                      # README 配图
└── evidence/                    # 原创性证据
```

## 开发环境

### GUI 前端开发

```bash
cd gui

# 安装依赖
npm install

# 启动开发服务器（热更新）
npm run dev
# 访问 http://localhost:5173

# 构建生产版本
npm run build
# 产物在 gui/dist/
```

### GUI 后端开发

```bash
cd gui/server

# 安装依赖
npm install

# 启动（需要 OpenClaw Gateway 运行中）
BOLUO_AUTH_TOKEN=test node index.js
# 访问 http://localhost:18795
```

### 诊断脚本测试

```bash
# 本地运行
bash doctor.sh

# 测试特定场景（创建临时配置文件）
cp openclaw.example.json /tmp/test-config.json
# 编辑后运行 doctor.sh 验证
```

## 提交规范

Commit message 格式：

```
<type>: <description>

feat:     新功能
fix:      Bug 修复
docs:     文档更新
chore:    构建/工具变更
refactor: 重构
style:    格式调整
```

示例：
```
feat: 预装 weather Skill
fix: README 飞书配置示例缺 groupPolicy
docs: 补充 GUI 使用说明
```

## PR 检查清单

- [ ] README.md 和 README_EN.md 保持同步
- [ ] 飞书配置示例包含 `dmPolicy` + `groupPolicy` + `name`
- [ ] openclaw.example.json 的 agents/bindings/accounts 三者匹配
- [ ] install.sh 的配置模板与 openclaw.example.json 一致
- [ ] doctor.sh 能检测到新增的配置项
- [ ] 新增 Skill 已加入 skills/README.md 索引

## 问题反馈

- **Bug 报告**：[GitHub Issues](https://github.com/wanikua/boluobobo-ai-court-tutorial/issues)
- **功能建议**：[GitHub Discussions](https://github.com/wanikua/boluobobo-ai-court-tutorial/discussions)
- **社区交流**：微信群（关注公众号「菠言菠语」获取入群码）
