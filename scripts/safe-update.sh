#!/bin/bash
# safe-update.sh — 安全更新脚本：备份配置 → 更新 OpenClaw → 验证 → 回滚
#
# 使用方法:
#   bash scripts/safe-update.sh              # 交互式更新
#   bash scripts/safe-update.sh --yes        # 自动确认
#   bash scripts/safe-update.sh --backup     # 仅备份不更新
#   bash scripts/safe-update.sh --rollback   # 回滚到最近备份

set -euo pipefail

# ---- 颜色 ----
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# ---- 配置 ----
CLI_CMD="openclaw"
command -v clawdbot &>/dev/null && CLI_CMD="clawdbot"

CONFIG_DIR="$HOME/.${CLI_CMD}"
CONFIG_FILE="$CONFIG_DIR/${CLI_CMD}.json"
BACKUP_DIR="$HOME/backups/${CLI_CMD}"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_PATH="$BACKUP_DIR/backup-$TIMESTAMP"

AUTO_YES=false
BACKUP_ONLY=false
ROLLBACK=false

for arg in "$@"; do
    case $arg in
        --yes|-y) AUTO_YES=true ;;
        --backup|-b) BACKUP_ONLY=true ;;
        --rollback|-r) ROLLBACK=true ;;
    esac
done

info()  { echo -e "  ${CYAN}ℹ${NC}  $1"; }
pass()  { echo -e "  ${GREEN}✓${NC}  $1"; }
warn()  { echo -e "  ${YELLOW}⚠${NC}  $1"; }
fail()  { echo -e "  ${RED}✗${NC}  $1"; }

confirm() {
    if $AUTO_YES; then return 0; fi
    read -p "  $1 (y/n) " choice
    [[ "$choice" =~ ^[Yy]$ ]]
}

# ============================================================
# 回滚模式
# ============================================================
if $ROLLBACK; then
    echo ""
    echo -e "${CYAN}═══ 回滚模式 ═══${NC}"
    echo ""

    if [ ! -d "$BACKUP_DIR" ]; then
        fail "备份目录不存在: $BACKUP_DIR"
        exit 1
    fi

    LATEST=$(ls -1d "$BACKUP_DIR"/backup-* 2>/dev/null | sort -r | head -1)
    if [ -z "$LATEST" ]; then
        fail "没有找到备份"
        exit 1
    fi

    info "最近备份: $LATEST"
    ls -la "$LATEST/"
    echo ""

    if ! confirm "确认回滚到此备份？"; then
        info "已取消"
        exit 0
    fi

    if [ -f "$LATEST/${CLI_CMD}.json" ]; then
        cp "$LATEST/${CLI_CMD}.json" "$CONFIG_FILE"
        pass "配置文件已恢复"
    fi

    if [ -f "$LATEST/sessions.tar.gz" ]; then
        tar xzf "$LATEST/sessions.tar.gz" -C "$CONFIG_DIR/" 2>/dev/null || true
        pass "会话数据已恢复"
    fi

    info "请手动重启 Gateway: $CLI_CMD gateway restart"
    echo ""
    exit 0
fi

# ============================================================
# 备份
# ============================================================
echo ""
echo -e "${CYAN}═══ 安全更新脚本 ═══${NC}"
echo ""

CURRENT_VERSION=$($CLI_CMD --version 2>/dev/null || echo "unknown")
info "当前版本: $CURRENT_VERSION"
info "CLI: $CLI_CMD"
echo ""

# 创建备份
echo -e "${YELLOW}[1/4] 备份当前配置...${NC}"
mkdir -p "$BACKUP_PATH"

if [ -f "$CONFIG_FILE" ]; then
    cp "$CONFIG_FILE" "$BACKUP_PATH/"
    pass "配置文件已备份"
else
    warn "配置文件不存在: $CONFIG_FILE"
fi

# 备份会话数据
if [ -d "$CONFIG_DIR/sessions" ]; then
    tar czf "$BACKUP_PATH/sessions.tar.gz" -C "$CONFIG_DIR" sessions/ 2>/dev/null || true
    pass "会话数据已备份"
fi

# 备份 memory
if [ -d "$CONFIG_DIR/memory" ]; then
    tar czf "$BACKUP_PATH/memory.tar.gz" -C "$CONFIG_DIR" memory/ 2>/dev/null || true
    pass "Memory 数据已备份"
fi

# 记录版本
echo "$CURRENT_VERSION" > "$BACKUP_PATH/version.txt"
pass "备份完成: $BACKUP_PATH"

# 清理旧备份（保留最近 10 个）
BACKUP_COUNT=$(ls -1d "$BACKUP_DIR"/backup-* 2>/dev/null | wc -l)
if [ "$BACKUP_COUNT" -gt 10 ]; then
    ls -1d "$BACKUP_DIR"/backup-* | sort | head -n -10 | xargs rm -rf
    info "已清理旧备份（保留最近 10 个）"
fi

if $BACKUP_ONLY; then
    echo ""
    pass "仅备份模式完成"
    exit 0
fi

# ============================================================
# 检查更新
# ============================================================
echo ""
echo -e "${YELLOW}[2/4] 检查更新...${NC}"

LATEST_VERSION=$(npm view "$CLI_CMD" version 2>/dev/null || echo "unknown")
info "最新版本: $LATEST_VERSION"

if [ "$CURRENT_VERSION" = "$LATEST_VERSION" ]; then
    pass "已是最新版本，无需更新"
    echo ""
    exit 0
fi

if ! confirm "更新 $CURRENT_VERSION → $LATEST_VERSION？"; then
    info "已取消"
    exit 0
fi

# ============================================================
# 停止 Gateway
# ============================================================
echo ""
echo -e "${YELLOW}[3/4] 更新中...${NC}"

# 停止 gateway
if systemctl --user is-active "${CLI_CMD}-gateway" &>/dev/null; then
    systemctl --user stop "${CLI_CMD}-gateway" 2>/dev/null || true
    info "Gateway 已停止（systemd）"
elif pgrep -f "${CLI_CMD}-gateway\|${CLI_CMD} gateway" &>/dev/null; then
    pkill -f "${CLI_CMD}-gateway\|${CLI_CMD} gateway" 2>/dev/null || true
    sleep 2
    info "Gateway 已停止（进程）"
else
    info "Gateway 未运行"
fi

# 更新
if command -v pnpm &>/dev/null; then
    pnpm add -g "$CLI_CMD@latest" 2>&1 | tail -3
elif command -v npm &>/dev/null; then
    npm install -g "$CLI_CMD@latest" 2>&1 | tail -3
else
    fail "npm/pnpm 未安装"
    exit 1
fi

NEW_VERSION=$($CLI_CMD --version 2>/dev/null || echo "unknown")
pass "更新完成: $NEW_VERSION"

# ============================================================
# 验证 + 重启
# ============================================================
echo ""
echo -e "${YELLOW}[4/4] 验证并重启...${NC}"

# 验证配置
if python3 -c "import json; json.load(open('$CONFIG_FILE'))" 2>/dev/null; then
    pass "配置文件 JSON 有效"
else
    fail "配置文件 JSON 损坏！"
    warn "回滚: bash scripts/safe-update.sh --rollback"
    exit 1
fi

# 重启 gateway
if systemctl --user is-enabled "${CLI_CMD}-gateway" &>/dev/null; then
    systemctl --user start "${CLI_CMD}-gateway"
    sleep 3
    if systemctl --user is-active "${CLI_CMD}-gateway" &>/dev/null; then
        pass "Gateway 已启动（systemd）"
    else
        fail "Gateway 启动失败"
        warn "查看日志: journalctl --user -u ${CLI_CMD}-gateway --since '1 min ago'"
        warn "回滚: bash scripts/safe-update.sh --rollback"
        exit 1
    fi
else
    info "请手动启动 Gateway: $CLI_CMD gateway --verbose"
fi

# 运行 doctor
if [ -f "$(dirname "$0")/doctor.sh" ] || [ -f "doctor.sh" ]; then
    echo ""
    info "运行健康检查..."
    bash "$(dirname "$0")/../doctor.sh" 2>/dev/null || bash doctor.sh 2>/dev/null || true
fi

echo ""
echo -e "${GREEN}═══ 更新完成 ═══${NC}"
echo ""
echo "  版本: $CURRENT_VERSION → $NEW_VERSION"
echo "  备份: $BACKUP_PATH"
echo "  回滚: bash scripts/safe-update.sh --rollback"
echo ""
