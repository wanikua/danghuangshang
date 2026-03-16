#!/usr/bin/env bash
# ============================================================
# 🦞 龙虾记忆备份 / Memory Backup
# 自动备份 记忆数据库、工作区记忆和核心配置
# 支持 cron 定时运行，自动清理过期备份
# ============================================================

set -euo pipefail

# ---------- CLI 配置 ----------
CLI_CMD="openclaw"
CLI_HOME_DEFAULT="$HOME/.openclaw"
CLI_CONFIG_NAME="openclaw.json"

# ---------- 配置 ----------
OPENCLAW_HOME="${OPENCLAW_HOME:-$CLI_HOME_DEFAULT}"
WORKSPACE="${OPENCLAW_WORKSPACE:-$HOME/clawd}"
BACKUP_ROOT="${BACKUP_ROOT:-$HOME/backups/${CLI_CMD}}"
RETAIN_DAYS="${RETAIN_DAYS:-7}"
RETAIN_WEEKLY="${RETAIN_WEEKLY:-4}"
RETAIN_MONTHLY="${RETAIN_MONTHLY:-6}"
LOG_FILE="${BACKUP_ROOT}/backup.log"

# ---------- 颜色 ----------
RED="\033[0;31m"; GREEN="\033[0;32m"; YELLOW="\033[0;33m"; CYAN="\033[0;36m"; NC="\033[0m"

log()  { echo -e "${CYAN}[$(date +%H:%M:%S)]${NC} $*"; }
ok()   { echo -e "${GREEN}[✓]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
err()  { echo -e "${RED}[✗]${NC} $*" >&2; }

# ---------- 帮助 ----------
usage() {
    cat <<EOF
🦞 龙虾记忆备份工具

用法: $(basename "$0") [选项]

选项:
  -d, --dest <路径>      备份目录 (默认: ~/backups/openclaw)
  -r, --retain <天数>    每日备份保留天数 (默认: 7)
  -l, --list             列出现有备份
  -s, --restore <文件>   从备份恢复
  --dry-run              只显示会做什么，不实际执行
  --no-compress          不压缩备份
  -q, --quiet            静默模式（适合 cron）
  -h, --help             显示帮助

示例:
  $(basename "$0")                        # 立即备份
  $(basename "$0") -d /mnt/nas/backup     # 备份到 NAS
  $(basename "$0") -l                      # 列出备份
  $(basename "$0") -s daily/2026-03-15.tar.gz  # 从备份恢复

Cron 示例:
  # 每天凌晨 3 点备份
  0 3 * * * \$HOME/danghuangshang/scripts/memory-backup.sh -q
  # 每周日额外做一次完整备份
  0 4 * * 0 \$HOME/danghuangshang/scripts/memory-backup.sh -q
EOF
    exit 0
}

# ---------- 参数解析 ----------
DRY_RUN=false
COMPRESS=true
QUIET=false
LIST_MODE=false
RESTORE_FILE=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        -d|--dest)     BACKUP_ROOT="$2"; shift 2 ;;
        -r|--retain)   RETAIN_DAYS="$2"; shift 2 ;;
        -l|--list)     LIST_MODE=true; shift ;;
        -s|--restore)  RESTORE_FILE="$2"; shift 2 ;;
        --dry-run)     DRY_RUN=true; shift ;;
        --no-compress) COMPRESS=false; shift ;;
        -q|--quiet)    QUIET=true; shift ;;
        -h|--help)     usage ;;
        *) err "未知选项: $1"; usage ;;
    esac
done

qlog() { [[ "$QUIET" == "true" ]] || log "$@"; }
qok()  { [[ "$QUIET" == "true" ]] || ok "$@"; }

# ---------- 列出备份 ----------
if [[ "$LIST_MODE" == "true" ]]; then
    echo "📦 现有备份 ($BACKUP_ROOT):"
    echo ""
    for tier in daily weekly monthly; do
        dir="$BACKUP_ROOT/$tier"
        [[ -d "$dir" ]] || continue
        count=$(find "$dir" -maxdepth 1 -name "*.tar.gz" -o -name "*.tar" 2>/dev/null | wc -l)
        size=$(du -sh "$dir" 2>/dev/null | cut -f1)
        echo "  $tier/  ($count 个备份, $size)"
        find "$dir" -maxdepth 1 \( -name "*.tar.gz" -o -name "*.tar" \) -printf "    %f  %s bytes  %Tc\n" 2>/dev/null | sort -r | head -5
        [[ $count -gt 5 ]] && echo "    ... 还有 $((count - 5)) 个"
        echo ""
    done
    exit 0
fi

# ---------- 恢复 ----------
if [[ -n "$RESTORE_FILE" ]]; then
    archive="$BACKUP_ROOT/$RESTORE_FILE"
    [[ -f "$archive" ]] || { err "备份文件不存在: $archive"; exit 1; }

    echo "⚠️  即将从备份恢复，这会覆盖当前数据："
    echo "  📁 $archive"
    echo ""
    echo "  将恢复:"
    echo "    - $OPENCLAW_HOME/memory/*.sqlite  (记忆数据库)"
    echo "    - $WORKSPACE/memory/              (工作区记忆)"
    echo "    - $OPENCLAW_HOME/$CLI_CONFIG_NAME    (配置文件)"
    echo ""
    read -rp "确认恢复? (输入 yes): " confirm
    [[ "$confirm" == "yes" ]] || { echo "已取消"; exit 0; }

    echo "⏸  停止 gateway..."
    $CLI_CMD gateway stop 2>/dev/null || true

    tmpdir=$(mktemp -d)
    tar -xzf "$archive" -C "$tmpdir" 2>/dev/null || tar -xf "$archive" -C "$tmpdir"

    if [[ -d "$tmpdir/memory-sqlite" ]]; then
        cp -v "$tmpdir/memory-sqlite/"*.sqlite "$OPENCLAW_HOME/memory/"
        ok "记忆数据库已恢复"
    fi

    if [[ -d "$tmpdir/memory-workspace" ]]; then
        rsync -a "$tmpdir/memory-workspace/" "$WORKSPACE/memory/"
        ok "工作区记忆已恢复"
    fi

    if [[ -f "$tmpdir/config/$CLI_CONFIG_NAME" ]]; then
        read -rp "是否恢复配置文件? (y/N): " restore_config
        if [[ "$restore_config" == "y" ]]; then
            cp "$OPENCLAW_HOME/$CLI_CONFIG_NAME" "$OPENCLAW_HOME/$CLI_CONFIG_NAME.pre-restore"
            cp "$tmpdir/config/$CLI_CONFIG_NAME" "$OPENCLAW_HOME/$CLI_CONFIG_NAME"
            ok "配置已恢复 (旧配置保存为 $CLI_CONFIG_NAME.pre-restore)"
        fi
    fi

    rm -rf "$tmpdir"

    echo "▶️  重启 gateway..."
    $CLI_CMD gateway start 2>/dev/null || true
    ok "恢复完成！"
    exit 0
fi

# ---------- 备份主流程 ----------
TODAY=$(date +%Y-%m-%d)
NOW=$(date +%Y-%m-%dT%H%M%S)
DAY_OF_WEEK=$(date +%u)
DAY_OF_MONTH=$(date +%d)

mkdir -p "$BACKUP_ROOT"/{daily,weekly,monthly}
mkdir -p "$(dirname "$LOG_FILE")"

exec > >(tee -a "$LOG_FILE") 2>&1

qlog "🦞 龙虾记忆备份开始 — $NOW"

STAGING=$(mktemp -d)
cleanup_staging() { rm -rf "$STAGING"; }
trap cleanup_staging EXIT

# 1) 备份记忆数据库 (SQLite)
qlog "备份记忆数据库..."
mkdir -p "$STAGING/memory-sqlite"
if [[ -d "$OPENCLAW_HOME/memory" ]]; then
    for db in "$OPENCLAW_HOME/memory/"*.sqlite; do
        [[ -f "$db" ]] || continue
        name=$(basename "$db")
        if [[ "$DRY_RUN" == "true" ]]; then
            qlog "  [dry-run] 会备份 $name"
        else
            if command -v sqlite3 &>/dev/null; then
                sqlite3 "$db" ".backup '$STAGING/memory-sqlite/$name'" 2>/dev/null || cp "$db" "$STAGING/memory-sqlite/$name"
            else
                cp "$db" "$STAGING/memory-sqlite/$name"
            fi
        fi
    done
    qok "记忆数据库: $(ls "$STAGING/memory-sqlite/" 2>/dev/null | wc -l) 个文件"
else
    warn "记忆目录不存在: $OPENCLAW_HOME/memory"
fi

# 2) 备份工作区记忆
qlog "备份工作区记忆..."
mkdir -p "$STAGING/memory-workspace"
if [[ -d "$WORKSPACE/memory" ]]; then
    if [[ "$DRY_RUN" == "true" ]]; then
        qlog "  [dry-run] 会备份 $WORKSPACE/memory/"
    else
        rsync -a "$WORKSPACE/memory/" "$STAGING/memory-workspace/"
    fi
    qok "工作区记忆: $(find "$STAGING/memory-workspace" -type f 2>/dev/null | wc -l) 个文件"
else
    warn "工作区记忆不存在: $WORKSPACE/memory"
fi

# 3) 备份配置
qlog "备份配置文件..."
mkdir -p "$STAGING/config"
for cfg in "$OPENCLAW_HOME/$CLI_CONFIG_NAME" "$OPENCLAW_HOME/agents/silijian/agent/auth-profiles.json"; do
    if [[ -f "$cfg" ]]; then
        if [[ "$DRY_RUN" == "true" ]]; then
            qlog "  [dry-run] 会备份 $(basename "$cfg")"
        else
            cp "$cfg" "$STAGING/config/"
        fi
    fi
done
qok "配置文件已备份"

# 4) 写入元数据
sqlite_count=$(ls "$STAGING/memory-sqlite/"*.sqlite 2>/dev/null | wc -l || echo 0)
workspace_count=$(find "$STAGING/memory-workspace" -type f 2>/dev/null | wc -l || echo 0)
total_bytes=$(du -sb "$STAGING" 2>/dev/null | cut -f1 || echo 0)
openclaw_ver=$($CLI_CMD --version 2>/dev/null || echo "unknown")

cat > "$STAGING/backup-meta.json" <<METAEOF
{
  "timestamp": "$NOW",
  "hostname": "$(hostname)",
  "cli_version": "$openclaw_ver",
  "sqlite_count": $sqlite_count,
  "workspace_files": $workspace_count,
  "total_size_bytes": $total_bytes
}
METAEOF

# 5) 打包
if [[ "$DRY_RUN" == "true" ]]; then
    qlog "[dry-run] 会打包到 $BACKUP_ROOT/daily/$TODAY.tar.gz"
else
    ARCHIVE="$BACKUP_ROOT/daily/$TODAY.tar.gz"
    if [[ "$COMPRESS" == "true" ]]; then
        tar -czf "$ARCHIVE" -C "$STAGING" .
    else
        ARCHIVE="$BACKUP_ROOT/daily/$TODAY.tar"
        tar -cf "$ARCHIVE" -C "$STAGING" .
    fi
    qok "每日备份: $ARCHIVE ($(du -sh "$ARCHIVE" | cut -f1))"

    # 每周日做一份周备份
    if [[ "$DAY_OF_WEEK" == "7" ]]; then
        WEEK_NUM=$(date +%Y-W%V)
        cp "$ARCHIVE" "$BACKUP_ROOT/weekly/$WEEK_NUM.tar.gz"
        qok "每周备份: $BACKUP_ROOT/weekly/$WEEK_NUM.tar.gz"
    fi

    # 每月1号做一份月备份
    if [[ "$DAY_OF_MONTH" == "01" ]]; then
        MONTH=$(date +%Y-%m)
        cp "$ARCHIVE" "$BACKUP_ROOT/monthly/$MONTH.tar.gz"
        qok "每月备份: $BACKUP_ROOT/monthly/$MONTH.tar.gz"
    fi
fi

# ---------- 清理过期备份 ----------
if [[ "$DRY_RUN" == "false" ]]; then
    qlog "清理过期备份..."

    deleted=$(find "$BACKUP_ROOT/daily" -name "*.tar*" -mtime "+$RETAIN_DAYS" -delete -print 2>/dev/null | wc -l)
    [[ $deleted -gt 0 ]] && qlog "  删除 $deleted 个过期每日备份"

    deleted=$(find "$BACKUP_ROOT/weekly" -name "*.tar*" -mtime "+$((RETAIN_WEEKLY * 7))" -delete -print 2>/dev/null | wc -l)
    [[ $deleted -gt 0 ]] && qlog "  删除 $deleted 个过期每周备份"

    deleted=$(find "$BACKUP_ROOT/monthly" -name "*.tar*" -mtime "+$((RETAIN_MONTHLY * 30))" -delete -print 2>/dev/null | wc -l)
    [[ $deleted -gt 0 ]] && qlog "  删除 $deleted 个过期每月备份"
fi

# ---------- 汇总 ----------
if [[ "$DRY_RUN" == "false" ]]; then
    total_size=$(du -sh "$BACKUP_ROOT" 2>/dev/null | cut -f1)
    daily_count=$(find "$BACKUP_ROOT/daily" -name "*.tar*" 2>/dev/null | wc -l)
    weekly_count=$(find "$BACKUP_ROOT/weekly" -name "*.tar*" 2>/dev/null | wc -l)
    monthly_count=$(find "$BACKUP_ROOT/monthly" -name "*.tar*" 2>/dev/null | wc -l)
    qok "备份完成！ 总计: ${total_size} (日:${daily_count} 周:${weekly_count} 月:${monthly_count})"
fi

qlog "🦞 龙虾记忆备份结束"
