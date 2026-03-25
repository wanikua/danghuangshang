# 🔒 安全策略 (Security Policy)

## 报告安全问题

如果你发现安全漏洞，请**不要**在公开 Issues 中报告。

### 联系方式

- 📧 **邮箱**: [填写联系邮箱]
- 💬 **Discord**: [填写 Discord 联系方式]
- 🔐 **PGP Key**: [可选，填写 PGP 公钥]

### 报告格式

请提供以下信息：

1. **漏洞类型** (如：XSS, SQL 注入，权限绕过等)
2. **影响范围** (哪些版本受影响)
3. **复现步骤** (详细说明如何复现)
4. **潜在影响** (可能造成什么后果)
5. **修复建议** (如有)

### 响应时间

- **确认收到**: 48 小时内
- **初步评估**: 5 个工作日内
- **修复计划**: 10 个工作日内

---

## 安全最佳实践

### 安装安全

1. **验证安装脚本**
   ```bash
   # 下载后先检查脚本内容
   curl -fsSL https://raw.githubusercontent.com/wanikua/danghuangshang/main/install-lite.sh -o install-lite.sh
   cat install-lite.sh  # 检查后再运行
   bash install-lite.sh
   ```

2. **使用官方源**
   - 仅从官方 GitHub 仓库下载安装脚本
   - 验证 Git 提交签名

### 配置安全

1. **API Key 保护**
   ```bash
   # 配置文件权限设置为仅自己可读
   chmod 600 ~/.openclaw/openclaw.json
   ```

2. **不要提交敏感信息**
   - `.gitignore` 已排除 `openclaw.json`
   - 不要将 API Key 上传到 GitHub

### Docker 安全

1. **非特权运行**
   - Docker 容器以非 root 用户运行
   - 默认禁用特权模式

2. **网络隔离**
   ```yaml
   # docker-compose.yml 默认绑定 localhost
   ports:
     - "127.0.0.1:18789:18789"
   ```

3. **外网访问配置**
   - 如需外网访问，手动修改 docker-compose.yml
   - 建议配合防火墙规则

### Discord Bot 安全

1. **权限最小化**
   - 仅授予必要的 Bot 权限
   - 禁用管理员权限

2. **消息安全**
   - 启用 `discord-message-guard` skill
   - 配置 `allowBots: "mentions"` 避免消息循环

3. **Webhook 保护**
   - 不要公开 Webhook URL
   - 定期轮换 Webhook

---

## 已知安全问题

### 已修复

| CVE/ID | 描述 | 修复版本 | 日期 |
|--------|------|---------|------|
| - | 配置文件 JSON 注入 | 3.6.0 | 2026-03-24 |
| - | 安装脚本路径遍历 | 3.6.0 | 2026-03-24 |

### 待修复

| ID | 描述 | 严重性 | 计划修复 |
|----|------|--------|---------|
| - | 暂无 | - | - |

---

## 安全更新

### 自动更新

```bash
# 启用自动更新（推荐）
openclaw gateway auto-update --enable
```

### 手动更新

```bash
# 检查更新
openclaw --version

# 更新 OpenClaw
npm install -g openclaw@latest

# 更新项目
cd danghuangshang
git pull origin main
```

---

## 安全审计

### 定期审计项目

```bash
# 检查依赖漏洞
npm audit

# 检查 Docker 镜像
docker scout cve boluobobo/ai-court:latest

# 检查配置文件
jq empty ~/.openclaw/openclaw.json
```

### 日志监控

```bash
# 查看 Gateway 日志
journalctl --user -u openclaw-gateway -f

# 查看 Docker 日志
docker logs ai-court -f
```

---

## 贡献安全代码

1. **Fork 项目**
2. **创建安全分支** (`security/xxx`)
3. **提交修复**
4. **创建 Pull Request**
   - 标题添加 `[Security]` 前缀
   - 详细描述漏洞和修复方案

---

## 致谢

感谢以下安全研究者：

- [待添加]

---

**最后更新**: 2026-03-25  
**维护者**: 工部
