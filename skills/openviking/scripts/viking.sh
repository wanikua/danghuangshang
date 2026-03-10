#!/bin/bash
# OpenViking CLI 封装脚本
# 用法: bash viking.sh <command> [args...]

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 检查 openviking 是否安装
if ! command -v openviking &>/dev/null && ! python3 -c "import openviking" &>/dev/null 2>&1; then
    echo -e "${RED}✗ OpenViking 未安装${NC}"
    echo "运行: pip install openviking"
    exit 1
fi

# 检查配置
OV_CONF="${OPENVIKING_CONFIG_FILE:-$HOME/.openviking/ov.conf}"
if [ ! -f "$OV_CONF" ]; then
    echo -e "${RED}✗ OpenViking 配置文件不存在: $OV_CONF${NC}"
    echo "请参考 skills/openviking/SKILL.md 创建配置"
    exit 1
fi

OV_DATA="${OPENVIKING_DATA_DIR:-$HOME/.openviking/data}"
mkdir -p "$OV_DATA"

CMD="${1:-help}"
shift 2>/dev/null || true

case "$CMD" in
    info)
        echo -e "${GREEN}OpenViking 状态${NC}"
        echo "  配置: $OV_CONF"
        echo "  数据: $OV_DATA"
        python3 -c "import openviking; print(f'  版本: {openviking.__version__}')" 2>/dev/null || echo "  版本: unknown"
        if [ -d "$OV_DATA" ]; then
            FILE_COUNT=$(find "$OV_DATA" -type f 2>/dev/null | wc -l)
            echo "  已索引文件: $FILE_COUNT"
        fi
        ;;
    add)
        if [ -z "$1" ]; then
            echo -e "${RED}用法: viking.sh add <file-path>${NC}"
            exit 1
        fi
        echo -e "${YELLOW}索引文件: $1${NC}"
        python3 -c "
from openviking import Viking
v = Viking.from_config('$OV_CONF')
v.add_resource('$1', data_dir='$OV_DATA')
print('✓ 索引完成')
" 2>&1
        ;;
    add-dir)
        DIR="${1:-.}"
        echo -e "${YELLOW}批量索引目录: $DIR${NC}"
        python3 -c "
import os
from openviking import Viking
v = Viking.from_config('$OV_CONF')
count = 0
for root, dirs, files in os.walk('$DIR'):
    for f in files:
        if f.endswith(('.md', '.txt', '.py', '.js', '.ts', '.json', '.yaml', '.yml', '.sh', '.html', '.css')):
            path = os.path.join(root, f)
            try:
                v.add_resource(path, data_dir='$OV_DATA')
                count += 1
                print(f'  ✓ {path}')
            except Exception as e:
                print(f'  ✗ {path}: {e}')
print(f'\n共索引 {count} 个文件')
" 2>&1
        ;;
    search)
        if [ -z "$1" ]; then
            echo -e "${RED}用法: viking.sh search <query>${NC}"
            exit 1
        fi
        QUERY="$*"
        python3 -c "
from openviking import Viking
v = Viking.from_config('$OV_CONF')
results = v.search('$QUERY', data_dir='$OV_DATA', top_k=5)
if not results:
    print('无匹配结果')
else:
    for i, r in enumerate(results, 1):
        score = getattr(r, 'score', 0)
        path = getattr(r, 'path', getattr(r, 'source', 'unknown'))
        content = getattr(r, 'content', getattr(r, 'text', ''))[:200]
        print(f'{i}. [{score:.3f}] {path}')
        print(f'   {content}')
        print()
" 2>&1
        ;;
    list)
        echo -e "${GREEN}已索引的文件：${NC}"
        python3 -c "
from openviking import Viking
v = Viking.from_config('$OV_CONF')
resources = v.list_resources(data_dir='$OV_DATA')
if not resources:
    print('  （空）')
else:
    for r in resources:
        print(f'  {r}')
" 2>&1
        ;;
    summary)
        if [ -z "$1" ]; then
            echo -e "${RED}用法: viking.sh summary <file-path>${NC}"
            exit 1
        fi
        python3 -c "
from openviking import Viking
v = Viking.from_config('$OV_CONF')
summary = v.get_summary('$1', data_dir='$OV_DATA')
print(summary or '无摘要')
" 2>&1
        ;;
    help|*)
        echo "OpenViking CLI 封装"
        echo ""
        echo "用法: bash viking.sh <command> [args]"
        echo ""
        echo "命令:"
        echo "  info              查看 OpenViking 状态"
        echo "  add <file>        索引单个文件"
        echo "  add-dir [dir]     批量索引目录（默认当前目录）"
        echo "  search <query>    语义搜索"
        echo "  list              列出已索引的文件"
        echo "  summary <file>    查看文件摘要"
        echo "  help              显示帮助"
        ;;
esac
