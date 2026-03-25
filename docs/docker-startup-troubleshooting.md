# 🐳 Docker 启动问题诊断指南

**最后更新**: 2026-03-25  
**适用版本**: 3.6.0+

---

## 常见问题

### 1. 容器反复重启

**症状**:
```bash
$ docker ps
CONTAINER ID   IMAGE                    STATUS
ai-court       boluobobo/ai-court       Restarting (1) 5 seconds ago
```

**原因**:
- 配置文件不存在或格式错误
- API Key 无效
- 端口冲突

**解决方案**:

```bash
# 1. 查看日志
docker logs ai-court --tail 50

# 2. 检查配置文件
docker exec ai-court cat ~/.openclaw/openclaw.json | jq empty

# 3. 检查配置文件是否存在
docker exec ai-court ls -la ~/.openclaw/openclaw.json

# 4. 重新初始化
docker exec -it ai-court init-court
```

---

### 2. 配置文件目录错误

**症状**:
```
⚠ 错误：/root/.openclaw/openclaw.json 是一个目录！
```

**原因**: Docker 在文件不存在时会自动创建同名目录

**解决方案**:

```bash
# 1. 停止容器
docker compose down

# 2. 移除错误目录
docker compose run --rm court rm -rf /root/.openclaw/openclaw.json

# 3. 在宿主机创建正确文件
cd ~/danghuangshang
cp openclaw.example.json openclaw.json

# 4. 编辑配置
nano openclaw.json

# 5. 重新启动
docker compose up -d
```

---

### 3. 配置文件不存在

**症状**:
```
⚠ 配置文件不存在
请选择一种方式初始化...
```

**解决方案**:

```bash
# 方式一：进入容器初始化（推荐）
docker exec -it ai-court init-court

# 方式二：使用 run 模式
docker compose run -it court bash
init-court

# 方式三：Windows Git Bash 用户
MSYS_NO_PATHCONV=1 docker exec -it ai-court /init-docker.sh
```

---

### 4. Gateway 启动失败

**症状**:
```bash
$ curl http://localhost:18789/health
curl: (7) Failed to connect to localhost port 18789
```

**原因**:
- gateway.mode 未设置
- 配置参数错误

**解决方案**:

```bash
# 1. 进入容器
docker exec -it ai-court bash

# 2. 检查配置
openclaw config list

# 3. 设置 gateway.mode
openclaw config set gateway.mode local

# 4. 重启 Gateway
openclaw gateway restart

# 5. 验证
curl http://localhost:18789/health
```

---

### 5. Dashboard 无法访问

**症状**:
```bash
$ curl http://localhost:18795
curl: (7) Failed to connect
```

**原因**:
- GUI 未正确构建
- 端口绑定问题

**解决方案**:

```bash
# 1. 检查 GUI 是否运行
docker exec ai-court ps aux | grep node

# 2. 查看 GUI 日志
docker exec ai-court tail -f /opt/gui/server/logs/*.log

# 3. 检查端口绑定
docker exec ai-court netstat -tlnp | grep 18795

# 4. 修改绑定地址（如需外网访问）
export BOLUO_BIND_HOST=0.0.0.0
docker compose restart
```

---

### 6. 端口冲突

**症状**:
```
Error starting userland proxy: listen tcp4 0.0.0.0:18789: bind: address already in use
```

**解决方案**:

```bash
# 1. 查找占用端口的进程
sudo lsof -i :18789
sudo lsof -i :18795

# 2. 停止占用进程
sudo kill -9 <PID>

# 3. 或修改 docker-compose.yml 端口
ports:
  - "127.0.0.1:18790:18789"  # 改用其他端口
```

---

### 7. 权限问题

**症状**:
```
Permission denied
```

**解决方案**:

```bash
# 1. 检查文件权限
ls -la ~/.openclaw/openclaw.json

# 2. 修复权限
chmod 600 ~/.openclaw/openclaw.json
chown $(id -u):$(id -g) ~/.openclaw/openclaw.json

# 3. 重新启动
docker compose down
docker compose up -d
```

---

## 诊断脚本

```bash
#!/bin/bash
# docker-diagnose.sh

echo "=== Docker 容器状态 ==="
docker ps -a | grep ai-court

echo ""
echo "=== 最近日志 ==="
docker logs ai-court --tail 20

echo ""
echo "=== 配置文件检查 ==="
docker exec ai-court cat ~/.openclaw/openclaw.json | jq '.gateway.mode' 2>/dev/null || echo "❌ 配置文件错误"

echo ""
echo "=== 端口检查 ==="
docker exec ai-court netstat -tlnp 2>/dev/null | grep -E "18789|18795" || echo "❌ 端口未监听"

echo ""
echo "=== 健康检查 ==="
curl -s http://localhost:18789/health | jq . || echo "❌ Gateway 未响应"
```

---

## 获取帮助

### 相关 Issues

- #100 - docker 启动失败
- #93 - docker 部署后反复重启
- #67 - docker 启动失败

### 联系方式

- 💬 Discord: https://discord.gg/clawd
- 📧 邮箱: [联系邮箱]
- 📚 文档: https://github.com/wanikua/danghuangshang/docs

---

## 快速参考

| 命令 | 用途 |
|------|------|
| `docker logs ai-court` | 查看容器日志 |
| `docker exec -it ai-court init-court` | 初始化配置 |
| `docker compose restart` | 重启容器 |
| `docker compose down` | 停止并移除容器 |
| `curl http://localhost:18789/health` | 健康检查 |

---

**维护者**: 工部
