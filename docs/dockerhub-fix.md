# 🚨 Docker Hub 推送失败修复

**问题**：Docker 镜像构建失败  
**错误信息**：`##[error]Username required`  
**发生时间**：2026-03-23 10:08 UTC

---

## 🔍 问题原因

**GitHub Actions 日志**：
```
build	Log in to Docker Hub	2026-03-23T10:09:03.2884588Z ##[group]Run docker/login-action@v3
build	Log in to Docker Hub	2026-03-23T10:09:03.5983920Z ##[error]Username required
```

**根本原因**：
- ✅ `DOCKERHUB_TOKEN` Secret 已配置
- ❌ `DOCKERHUB_USERNAME` Secret **缺失**

---

## ✅ 修复步骤

### 步骤 1：添加 DOCKERHUB_USERNAME Secret

**方法一：GitHub Web 界面**

1. 进入仓库：https://github.com/wanikua/danghuangshang
2. 点击 **Settings** → **Secrets and variables** → **Actions**
3. 点击 **New repository secret**
4. 填写：
   - **Name**: `DOCKERHUB_USERNAME`
   - **Value**: `boluobobo`（你的 Docker Hub 用户名）
5. 点击 **Add secret**

**方法二：GitHub CLI**

```bash
# 添加 DOCKERHUB_USERNAME
gh secret set DOCKERHUB_USERNAME --body "boluobobo" --app actions
```

---

### 步骤 2：验证 Secret 配置

```bash
# 列出所有 Secrets
gh secret list --app actions

# 预期输出：
# DOCKERHUB_TOKEN	2026-03-15T15:48:36Z
# DOCKERHUB_USERNAME	2026-03-23T10:15:00Z
```

---

### 步骤 3：重新触发构建

**方法一：推送新 commit**

```bash
cd /home/ubuntu/clawd
git commit --allow-empty -m "ci: 触发 Docker 构建"
git push origin main
```

**方法二：手动触发 Workflow**

```bash
# 使用 GitHub CLI
gh workflow run docker-build.yml

# 或使用 Web 界面
# https://github.com/wanikua/danghuangshang/actions/workflows/docker-build.yml
# 点击 "Run workflow"
```

---

### 步骤 4：验证构建成功

```bash
# 查看最新构建状态
gh run list --workflow=docker-build.yml --limit 1

# 查看构建日志
gh run view --log

# 预期输出：
# ✅ Build and push - Success
# ✅ Docker Multi-Arch Build - Success
```

---

## 📋 完整 Secret 配置

| Secret Name | Value | 必需 | 说明 |
|-------------|-------|------|------|
| `DOCKERHUB_USERNAME` | `boluobobo` | ✅ | Docker Hub 用户名 |
| `DOCKERHUB_TOKEN` | `<your-token>` | ✅ | Docker Hub Access Token |

---

## 🔐 创建 Docker Hub Token

1. 登录 https://hub.docker.com
2. 进入 **Account Settings** → **Security**
3. 点击 **New Access Token**
4. 输入 Token 名称（如：`github-actions-danghuangshang`）
5. 选择权限：**Read & Write**
6. 点击 **Generate**
7. **复制 Token**（只显示一次！）

---

## 🎯 验证 Docker Hub 推送

### 1. 检查 Docker Hub

访问：https://hub.docker.com/r/boluobobo/ai-court/tags

查看最新镜像标签：
- `latest`
- `v3.6.0`（如果有版本标签）

### 2. 本地拉取测试

```bash
# 拉取最新镜像
docker pull boluobobo/ai-court:latest

# 查看镜像信息
docker images boluobobo/ai-court

# 预期输出：
# REPOSITORY              TAG       IMAGE ID       CREATED         SIZE
# boluobobo/ai-court      latest    abc123def456   2 minutes ago   1.2GB
```

---

## 🚀 自动化建议

### 1. 添加构建状态徽章

```markdown
[![Docker Build](https://github.com/wanikua/danghuangshang/actions/workflows/docker-build.yml/badge.svg)](https://github.com/wanikua/danghuangshang/actions/workflows/docker-build.yml)
[![Docker Pulls](https://img.shields.io/docker/pulls/boluobobo/ai-court)](https://hub.docker.com/r/boluobobo/ai-court)
```

### 2. 添加镜像版本信息

```yaml
# .github/workflows/docker-build.yml
- name: Image digest
  run: |
    echo "✅ Docker Image pushed successfully"
    echo "Image: boluobobo/ai-court:latest"
    echo "Digest: ${{ steps.build.outputs.digest }}"
```

---

## 📖 相关文档

- [Docker Hub 配置指南](./dockerhub.md)
- [Docker 部署指南](./docker-deployment.md)
- [GitHub Actions 文档](https://docs.github.com/en/actions)

---

## ⏭️ 后续步骤

1. ✅ 添加 `DOCKERHUB_USERNAME` Secret
2. ⏳ 重新触发 Docker 构建
3. ⏳ 验证镜像推送成功
4. ⏳ 更新文档中的镜像版本

---

**修复时间**：2026-03-23  
**维护者**：工部尚书
