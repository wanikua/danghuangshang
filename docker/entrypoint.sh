#!/bin/bash
set -e

WORKSPACE="${OPENCLAW_WORKSPACE:-$HOME/clawd}"
CONFIG_DIR="${OPENCLAW_CONFIG_DIR:-$HOME/.openclaw}"

# ---- [H-10] 检测 bind mount 目录误创建 ----
if [ -d "$CONFIG_DIR/openclaw.json" ]; then
    echo ""
    echo "================================"
    echo "⚠ 错误：$CONFIG_DIR/openclaw.json 是一个目录！"
    echo "================================"
    echo ""
    echo "Docker 在文件不存在时会自动创建同名目录。"
    echo "请先在宿主机创建配置文件再启动："
    echo ""
    echo "  cp openclaw.example.json openclaw.json"
    echo "  docker compose up -d"
    echo ""
    echo "或使用交互式初始化（不需要预创建文件）："
    echo "  先移除错误目录：rm -rf openclaw.json"
    echo "  注释掉 docker-compose.yml 中的 openclaw.json 挂载行"
    echo "  docker compose up -d"
    echo "  docker exec -it ai-court /init-docker.sh"
    echo ""
    rmdir "$CONFIG_DIR/openclaw.json" 2>/dev/null || true
    echo "容器将保持运行，请修复后执行 init-court 初始化..."
    echo ""
    # 等待用户修复后创建配置文件，避免 exit 1 触发 restart 循环
    while [ ! -f "$CONFIG_DIR/openclaw.json" ]; do
        sleep 5
    done
    echo "✓ 检测到配置文件，继续启动..."
fi

# ---- 初始化工作区模板（仅首次）----
if [ ! -f "$WORKSPACE/SOUL.md" ]; then
cat > "$WORKSPACE/SOUL.md" << 'EOF'
# SOUL.md - 朝廷行为准则

## 铁律
1. 废话不要多 — 说重点
2. 汇报要及时 — 做完就说
3. 做事要靠谱 — 先想后做

## 沟通风格
- 中文为主
- 直接说结论，需要细节再展开

## 朝廷架构
- 司礼监：日常调度、任务分配
- 内阁：战略决策、方案审议、全局规划
- 都察院：监察审计、代码审查、质量把控
- 兵部：软件工程、系统架构
- 户部：财务预算、电商运营
- 礼部：品牌营销、内容创作
- 工部：DevOps、服务器运维
- 吏部：项目管理、创业孵化
- 刑部：法务合规、知识产权
- 翰林院：学术研究、知识整理、文档撰写
EOF
echo "✓ SOUL.md 已创建"
fi

if [ ! -f "$WORKSPACE/IDENTITY.md" ]; then
cat > "$WORKSPACE/IDENTITY.md" << 'EOF'
# IDENTITY.md - 身份信息

- **Name:** AI朝廷
- **Creature:** 大明朝廷 AI 集群
- **Vibe:** 忠诚干练、各司其职
- **Emoji:** 🏛️
EOF
echo "✓ IDENTITY.md 已创建"
fi

if [ ! -f "$WORKSPACE/USER.md" ]; then
cat > "$WORKSPACE/USER.md" << 'EOF'
# USER.md - 关于你

- **称呼:** （填你的称呼）
- **语言:** 中文
- **风格:** 简洁高效
EOF
echo "✓ USER.md 已创建"
fi

mkdir -p "$WORKSPACE/memory"

# ---- OpenViking 初始化（如果配置了）----
if [ -f "$HOME/.openviking/ov.conf" ] || [ -n "$OPENVIKING_CONFIG_FILE" ]; then
    echo "✓ OpenViking 配置已检测到"
    mkdir -p "$HOME/.openviking/data"
fi

# ---- 提示信息 & 无配置等待模式 ----
if [ ! -f "$CONFIG_DIR/openclaw.json" ]; then
    echo ""
    echo "================================"
    echo "⚠ 配置文件不存在"
    echo "================================"
    echo ""
    echo "请选择一种方式初始化："
    echo ""
    echo "  方式一：交互式初始化（推荐）"
    echo "    docker exec -it ai-court init-court"
    echo ""
    echo "  ⚠ Windows Git Bash 用户若遇路径问题，请用上述命令或："
    echo "    MSYS_NO_PATHCONV=1 docker exec -it ai-court /init-docker.sh"
    echo ""
    echo "  方式二：OpenClaw 配置向导"
    echo "    docker exec -it ai-court openclaw onboard"
    echo ""
    echo "  方式三：挂载已有配置文件"
    echo "    docker run -v ./openclaw.json:$CONFIG_DIR/openclaw.json ..."
    echo ""
    echo "容器将保持运行，等待配置完成后自动启动 Gateway..."
    echo ""

    # 等待配置文件出现（每 5 秒检查一次），避免无配置时 gateway 崩溃导致容器反复重启
    while [ ! -f "$CONFIG_DIR/openclaw.json" ]; do
        sleep 5
    done

    echo "✓ 检测到配置文件，启动 Gateway..."
fi

# ---- [M-03] GUI Dashboard 自动启动（配置就绪后）----
GUI_PID=""
if [ -f "/opt/gui/server/index.js" ]; then
    echo "✓ 朝堂 Dashboard 启动中..."
    export BOLUO_BIND_HOST="${BOLUO_BIND_HOST:-0.0.0.0}"
    (
        cd /opt/gui
        while true; do
            node server/index.js || true
            sleep 2
        done
    ) &
    GUI_PID=$!
    cd "$WORKSPACE"
    echo "✓ Dashboard 已启动 (PID: $GUI_PID, 端口: 18795)"
fi

# ---- 信号处理：清理后台进程 ----
cleanup() {
    [ -n "$GUI_PID" ] && kill "$GUI_PID" 2>/dev/null
    exit 0
}
trap cleanup SIGTERM SIGINT

echo ""
echo "🏛️ AI 朝廷 Docker 启动中..."
echo "  工作区:    $WORKSPACE"
echo "  配置:      $CONFIG_DIR/openclaw.json"
echo "  Gateway:   http://localhost:18789"
echo "  Dashboard: http://localhost:18795"
echo "  初始化:    docker exec -it ai-court init-court"
echo ""

exec "$@"
