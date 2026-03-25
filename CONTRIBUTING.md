# 🤝 贡献指南 (Contributing Guide)

感谢你为 **菠萝王朝 (AI 朝廷)** 项目做出贡献！

---

## 📋 目录

1. [行为准则](#行为准则)
2. [贡献方式](#贡献方式)
3. [开发环境设置](#开发环境设置)
4. [提交规范](#提交规范)
5. [Pull Request 流程](#pull-request-流程)
6. [代码风格](#代码风格)
7. [测试](#测试)
8. [文档](#文档)
9. [问题报告](#问题报告)
10. [社区](#社区)

---

## 行为准则

本项目采用 **贡献者公约 (Contributor Covenant)** 作为行为准则。

### 核心原则

- ✅ **开放包容** - 欢迎各种背景的贡献者
- ✅ **相互尊重** - 尊重不同观点和经验
- ✅ **建设性反馈** - 提供有帮助的批评和建议
- ✅ **社区优先** - 以社区利益为重

### 不可接受的行为

- ❌ 使用性别化语言或图像
- ❌ 人身攻击或侮辱性评论
- ❌ 公开或私下骚扰
- ❌ 未经许可发布他人隐私信息
- ❌ 其他不道德或不专业的行为

---

## 贡献方式

### 1. 报告 Bug 🐛

在 GitHub Issues 中创建 Bug 报告：

**标题格式**: `[Bug] 简短描述`

**内容模板**:
```markdown
### 问题描述
[清晰简洁的问题描述]

### 复现步骤
1. 执行 '...'
2. 点击 '...'
3. 看到错误 '...'

### 期望行为
[描述期望发生什么]

### 实际行为
[描述实际发生了什么]

### 环境信息
- OS: [如 Ubuntu 22.04]
- OpenClaw 版本: [如 2026.3.13]
- 安装方式: [如 install-lite.sh]

### 截图
[如有，添加截图]

### 日志
[如有，添加相关日志]
```

### 2. 功能建议 💡

在 GitHub Issues 中创建功能建议：

**标题格式**: `[Feature] 简短描述`

**内容模板**:
```markdown
### 功能描述
[清晰简洁的功能描述]

### 使用场景
[描述这个功能解决什么问题]

### 实现建议
[如有，描述如何实现]

### 替代方案
[如有，描述其他可能的解决方案]
```

### 3. 提交代码 👨‍💻

1. Fork 项目
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 创建 Pull Request

### 4. 改进文档 📚

- 修复拼写错误
- 补充缺失说明
- 添加示例代码
- 翻译文档

### 5. 分享经验 📢

- 撰写教程
- 分享使用案例
- 在社区回答问题

---

## 开发环境设置

### 1. 克隆项目

```bash
git clone https://github.com/wanikua/danghuangshang.git
cd danghuangshang
```

### 2. 安装依赖

```bash
# 安装 OpenClaw
npm install -g openclaw@latest

# 安装项目依赖（如有）
npm install
```

### 3. 配置环境

```bash
# 复制配置示例
cp openclaw.example.json ~/.openclaw/openclaw.json

# 编辑配置，添加 API Key 和 Bot Token
nano ~/.openclaw/openclaw.json
```

### 4. 运行测试

```bash
# 运行测试套件
npm test

# 运行代码检查
npm run lint

# 运行健康检查
npm run health
```

---

## 提交规范

### Commit Message 格式

遵循 [Conventional Commits](https://www.conventionalcommits.org/) 规范：

```
<type>(<scope>): <description>

[optional body]

[optional footer(s)]
```

### Type 类型

| Type | 说明 | 示例 |
|------|------|------|
| `feat` | 新功能 | `feat(quadrants): 添加任务优先级排序` |
| `fix` | Bug 修复 | `fix(install): 修复模板路径错误` |
| `docs` | 文档更新 | `docs(README): 添加安装视频链接` |
| `style` | 代码格式 | `style(eslint): 修复缩进问题` |
| `refactor` | 重构 | `refactor(config): 简化配置结构` |
| `perf` | 性能优化 | `perf(docker): 减小镜像体积` |
| `test` | 测试相关 | `test(install): 添加安装脚本测试` |
| `chore` | 构建/工具 | `chore(deps): 更新依赖版本` |

### Scope 范围

| Scope | 说明 |
|-------|------|
| `install` | 安装脚本 |
| `config` | 配置文件 |
| `docker` | Docker 相关 |
| `gui` | GUI 界面 |
| `skills` | 技能包 |
| `docs` | 文档 |
| `ci` | CI/CD |

### 示例

```bash
# 新功能
git commit -m "feat(quadrants): 添加任务批量导入功能"

# Bug 修复
git commit -m "fix(install): 修复 macOS 安装脚本权限问题"

# 文档更新
git commit -m "docs(README): 添加故障排除章节"

# 重构
git commit -m "refactor(config): 统一配置模板结构"
```

---

## Pull Request 流程

### 1. 创建 PR

- 使用清晰的标题
- 填写 PR 模板
- 关联相关 Issue

### 2. PR 模板

```markdown
## 📋 变更类型
- [ ] 🐛 Bug 修复
- [ ] ✨ 新功能
- [ ] 📚 文档更新
- [ ] ♻️ 代码重构
- [ ] ⚡ 性能优化
- [ ] 🧪 测试
- [ ] 🔧 配置

## 🎯 关联 Issue
Fixes #123

## 📝 变更描述
[详细描述你的变更]

## 🧪 测试
- [ ] 已添加单元测试
- [ ] 已手动测试
- [ ] 已在生产环境测试

## 📸 截图
[如有，添加截图]

## ✅ 检查清单
- [ ] 代码遵循项目风格
- [ ] 已更新相关文档
- [ ] 已通过 CI 检查
- [ ] 无新的警告或错误
```

### 3. 代码审查

- 至少需要 1 个维护者批准
- 解决所有审查意见
- 通过所有 CI 检查

### 4. 合并

- 使用 Squash and Merge（推荐）
- 或 Rebase and Merge
- 不要使用 Merge Commit

---

## 代码风格

### Shell 脚本

```bash
#!/bin/bash
# 使用 shellcheck 检查
# shellcheck disable=SC1091

# 变量使用大写字母
readonly SCRIPT_NAME="install-lite.sh"
readonly VERSION="3.6.0"

# 函数使用小写字母和下划线
check_environment() {
  local required_commands=("git" "curl" "jq")
  
  for cmd in "${required_commands[@]}"; do
    if ! command -v "$cmd" &>/dev/null; then
      echo "❌ 缺少依赖：$cmd"
      return 1
    fi
  done
  
  return 0
}

# 错误处理
set -euo pipefail
```

### JavaScript/Node.js

```javascript
// 使用 ESLint 检查
// .eslintrc.js 已配置

// 使用 async/await
async function fetchConfig() {
  const response = await fetch('/api/config');
  return await response.json();
}

// 错误处理
try {
  await fetchConfig();
} catch (error) {
  console.error('Failed to fetch config:', error);
}
```

### Docker

```dockerfile
# 多阶段构建
FROM node:22-alpine AS builder
WORKDIR /build
COPY package*.json ./
RUN npm ci

FROM node:22-alpine
LABEL maintainer="wanikua"
USER court
CMD ["openclaw", "gateway"]
```

### YAML

```yaml
# 使用 2 个空格缩进
services:
  gateway:
    image: boluobobo/ai-court:latest
    ports:
      - "127.0.0.1:18789:18789"
    restart: unless-stopped
```

---

## 测试

### 单元测试

```bash
# 运行所有测试
npm test

# 运行特定测试
npm test -- --testPathPattern=install

# 生成覆盖率报告
npm run test:coverage
```

### 集成测试

```bash
# 测试安装脚本
bash scripts/test-install.sh

# 测试 Docker 部署
bash scripts/test-docker.sh

# 测试 GUI
bash scripts/test-gui.sh
```

### 手动测试

```bash
# 1. 清理环境
rm -rf ~/.openclaw

# 2. 全新安装
bash install-lite.sh

# 3. 验证功能
openclaw --version
curl http://127.0.0.1:18789/health
```

---

## 文档

### 文档结构

```
docs/
├── README.md              # 文档索引
├── install-*.md           # 安装指南
├── docker-*.md            # Docker 部署
├── config-*.md            # 配置指南
├── skill-*.md             # Skills 文档
└── troubleshooting.md     # 故障排除
```

### 文档规范

- 使用 Markdown 格式
- 添加目录（长文档）
- 提供示例代码
- 包含截图（如有必要）
- 标注适用版本

### 文档更新

```bash
# 更新文档后运行检查
bash scripts/check-docs.sh

# 生成文档索引
bash scripts/generate-docs-index.sh
```

---

## 问题报告

### Bug 报告

在创建 Bug 报告前，请：

1. **搜索现有 Issues** - 避免重复
2. **检查最新版本** - 确认问题仍存在
3. **收集信息** - 日志、截图、环境信息

### 响应时间

- **确认收到**: 48 小时内
- **初步评估**: 5 个工作日内
- **修复计划**: 视严重性而定

---

## 社区

### 联系方式

- 💬 **Discord**: [加入服务器](https://discord.gg/clawd)
- 📧 **邮箱**: [联系邮箱]
- 🐦 **Twitter**: [@菠萝菠菠](https://twitter.com/)
- 📺 **Bilibili**: [菠萝菠菠](https://space.bilibili.com/)

### 社区资源

- 📚 **文档**: https://github.com/wanikua/danghuangshang/docs
- 🎥 **教程视频**: [Bilibili 频道]
- 💡 **使用案例**: [GitHub Discussions]

---

## 贡献者名单

感谢所有贡献者：

[![Contributors](https://contrib.rocks/image?repo=wanikua/danghuangshang)](https://github.com/wanikua/danghuangshang/graphs/contributors)

---

## 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

---

**最后更新**: 2026-03-25  
**维护者**: 工部
