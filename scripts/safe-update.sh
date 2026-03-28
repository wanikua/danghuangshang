#!/bin/bash
#
# safe-update.sh - 菠萝王朝安全更新脚本
# 
# 功能：
# 1. 更新前自动备份配置和记忆
# 2. 检查关键安全配置
# 3. 支持一键回滚
#
# 用法：
#   ./safe-update.sh          # 完整流程（备份 + 检查 + 更新）
#   ./safe-update.sh --backup # 仅备份
#   ./safe-update.sh --check  # 仅安全检查
#   ./safe-update.sh --rollback  # 回滚到上次备份
#

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 路径配置
CLAWD_DIR="${CLAWD_DIR:-$HOME/.openclaw}"
BACKUP_DIR="${BACKUP_DIR:-$CLAWD_DIR/backups}"
OPENCLAW_CONFIG="${OPENCLAW_CONFIG:-$HOME/.openclaw/openclaw.json}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# 打印函数
info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# 创建备份目录
init_backup_dir() {
    mkdir -p "$BACKUP_DIR"
    info "备份目录：$BACKUP_DIR"
}

# 备份配置
backup_configs() {
    local backup_path="$BACKUP_DIR/config_$TIMESTAMP"
    mkdir -p "$backup_path"
    
    info "正在备份配置..."
    
    # 备份 openclaw.json
    if [ -f "$OPENCLAW_CONFIG" ]; then
        cp "$OPENCLAW_CONFIG" "$backup_path/"
        success "已备份 openclaw.json"
    else
        warn "未找到 $OPENCLAW_CONFIG"
    fi
    
    # 备份 configs 目录（各制度配置）
    if [ -d "$CLAWD_DIR/configs" ]; then
        cp -r "$CLAWD_DIR/configs" "$backup_path/"
        success "已备份 configs/"
    fi
    
    # 备份 agents 目录
    if [ -d "$CLAWD_DIR/agents" ]; then
        cp -r "$CLAWD_DIR/agents" "$backup_path/"
        success "已备份 agents/"
    fi
    
    # 记录备份元数据
    echo "$TIMESTAMP" > "$backup_path/.timestamp"
    echo "$backup_path" > "$BACKUP_DIR/latest"
    
    success "备份完成：$backup_path"
}

# 安全检查
safety_check() {
    info "正在执行安全检查..."
    local errors=0
    
    # 检查 1: allowBots 设置
    if [ -f "$OPENCLAW_CONFIG" ]; then
        local allow_bots
        allow_bots=$(grep -o '"allowBots"[[:space:]]*:[[:space:]]*"[^"]*"' "$OPENCLAW_CONFIG" | head -1)
        if echo "$allow_bots" | grep -q '"mentions"'; then
            success "allowBots 配置正确：mentions"
        elif echo "$allow_bots" | grep -q 'true'; then
            error "❌ allowBots=true 危险！会导致机器人循环。请改为 \"mentions\""
            ((errors++))
        else
            warn "allowBots 配置：$allow_bots"
        fi
        
        # 检查 2: mentionPatterns 是否包含 @everyone
        if grep -q '@everyone' "$OPENCLAW_CONFIG"; then
            error "❌ 发现 @everyone 配置！这是核弹开关，必须移除"
            ((errors++))
        else
            success "未发现 @everyone 配置"
        fi
        
        # 检查 3: mentionPatterns 是否包含 @here
        if grep -q '@here' "$OPENCLAW_CONFIG"; then
            error "❌ 发现 @here 配置！必须移除"
            ((errors++))
        else
            success "未发现 @here 配置"
        fi
    else
        warn "未找到配置文件，跳过检查"
    fi
    
    if [ $errors -gt 0 ]; then
        echo ""
        error "安全检查失败！发现 $errors 个严重问题，请修复后再更新"
    else
        success "安全检查通过 ✓"
    fi
}

# 执行更新
do_update() {
    info "正在更新..."
    
    # 如果使用 clawdhub
    if command -v clawdhub &> /dev/null; then
        clawdhub sync
        success "clawdhub sync 完成"
    fi
    
    # 如果使用 openclaw
    if command -v openclaw &> /dev/null; then
        openclaw update
        success "openclaw update 完成"
    fi
    
    success "更新完成！"
}

# 回滚
rollback() {
    local latest_backup
    latest_backup=$(cat "$BACKUP_DIR/latest" 2>/dev/null)
    
    if [ -z "$latest_backup" ] || [ ! -d "$latest_backup" ]; then
        error "未找到备份，无法回滚"
    fi
    
    info "正在回滚到：$latest_backup"
    
    # 恢复 openclaw.json（先备份当前配置）
    if [ -f "$OPENCLAW_CONFIG" ]; then
        cp "$OPENCLAW_CONFIG" "$BACKUP_DIR/pre_rollback_$TIMESTAMP.json"
        warn "已备份当前配置到：$BACKUP_DIR/pre_rollback_$TIMESTAMP.json"
    fi
    if [ -f "$latest_backup/openclaw.json" ]; then
        cp "$latest_backup/openclaw.json" "$OPENCLAW_CONFIG"
        success "已恢复 openclaw.json"
    fi
    
    # 恢复 configs
    if [ -d "$latest_backup/configs" ]; then
        cp -r "$latest_backup/configs" "$CLAWD_DIR/"
        success "已恢复 configs/"
    fi
    
    # 恢复 agents
    if [ -d "$latest_backup/agents" ]; then
        cp -r "$latest_backup/agents" "$CLAWD_DIR/"
        success "已恢复 agents/"
    fi
    
    success "回滚完成！请重启 gateway: openclaw gateway restart"
}

# 显示帮助
show_help() {
    cat << EOF
菠萝王朝安全更新脚本

用法：$0 [选项]

选项：
  (无)        完整流程：备份 → 安全检查 → 更新
  --backup    仅备份配置
  --check     仅安全检查
  --rollback  回滚到上次备份
  --help      显示帮助

示例：
  $0                    # 完整更新流程
  $0 --backup           # 手动备份
  $0 --check            # 检查配置安全性
  $0 --rollback         # 出问题时回滚

EOF
}

# 主流程
main() {
    init_backup_dir
    
    case "${1:-}" in
        --backup)
            backup_configs
            ;;
        --check)
            safety_check
            ;;
        --rollback)
            rollback
            ;;
        --help|-h)
            show_help
            ;;
        "")
            # 完整流程
            backup_configs
            echo ""
            safety_check
            echo ""
            read -p "是否继续更新？[y/N] " confirm
            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                do_update
            else
                info "已取消更新"
            fi
            ;;
        *)
            error "未知选项：$1，使用 --help 查看帮助"
            ;;
    esac
}

main "$@"
