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
- 国子监：教育培训、知识管理、学习规划
- 太医院：健康管理、饮食营养、训练计划
- 内务府：日常起居、日程安排、后勤保障
- 御膳房：膳食安排、美食推荐、食谱研究
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

# ---- [D-29] 同步内置 skills（volume 不会自动获取新镜像的文件）----
if [ -d /opt/skills-dist ]; then
    mkdir -p "$WORKSPACE/skills"
    cp -r /opt/skills-dist/* "$WORKSPACE/skills/" 2>/dev/null || true
fi

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
    echo "  方式一：新开终端进入容器初始化（推荐）"
    echo "    docker exec -it ai-court init-court"
    echo ""
    echo "  方式二：如果方式一失败（容器重启中），用 run 代替"
    echo "    docker compose run -it court bash"
    echo "    init-court"
    echo ""
    echo "  ⚠ Windows Git Bash 用户若遇路径问题："
    echo "    MSYS_NO_PATHCONV=1 docker exec -it ai-court /init-docker.sh"
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
        BACKOFF=2
        while true; do
            START_TS=$(date +%s)
            node server/index.js || true
            ELAPSED=$(( $(date +%s) - START_TS ))
            # 运行超过 30s 说明不是立即崩溃，重置退避
            [ $ELAPSED -gt 30 ] && BACKOFF=2
            sleep $BACKOFF
            # Exponential backoff capped at 30s to avoid crash-loop CPU burn
            BACKOFF=$((BACKOFF < 30 ? BACKOFF * 2 : 30))
        done
    ) &
    GUI_PID=$!
    cd "$WORKSPACE"
    echo "✓ Dashboard 已启动 (PID: $GUI_PID, 端口: 18795)"
fi

# ---- 信号处理：清理后台进程 ----
cleanup() {
    # Kill GUI background process and its children
    if [ -n "$GUI_PID" ]; then
        kill "$GUI_PID" 2>/dev/null
        # Also kill child node processes spawned by the subshell
        pkill -P "$GUI_PID" 2>/dev/null
    fi
    [ -n "$GATEWAY_PID" ] && kill "$GATEWAY_PID" 2>/dev/null
    wait 2>/dev/null
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

# 自动补全 gateway.mode（缺少会导致启动失败）
if command -v openclaw &>/dev/null && [ -f "$CONFIG_DIR/openclaw.json" ]; then
    if ! grep -q '"gateway"' "$CONFIG_DIR/openclaw.json" 2>/dev/null || \
       ! CONFIG_PATH="$CONFIG_DIR/openclaw.json" python3 -c "import json,os; d=json.load(open(os.environ['CONFIG_PATH'])); assert d.get('gateway',{}).get('mode')" 2>/dev/null; then
        echo "⚠ gateway.mode 未设置，自动设为 local..."
        openclaw config set gateway.mode local 2>/dev/null || true
    fi
fi

if [ $# -gt 0 ]; then
    "$@" &
    GATEWAY_PID=$!
    wait $GATEWAY_PID || true
fi
