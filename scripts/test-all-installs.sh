#!/bin/bash
# ============================================
# 安装脚本自动化测试
# 验证所有安装脚本的关键功能
# ============================================

set -uo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

TEST_PASSED=0
TEST_FAILED=0

# 测试函数
test_soul_creation() {
  local script="$1"
  echo -e "${YELLOW}测试：$script - SOUL.md 创建逻辑${NC}"
  
  # 检测 SOUL.md 创建逻辑（支持多种格式）
  if grep -q 'SOUL.md.*<<\|cat >.*SOUL.md' "$script" && grep -q 'if \[ ! -f.*SOUL.md' "$script"; then
    echo -e "  ${GREEN}✓ SOUL.md 创建逻辑正确${NC}"
    ((TEST_PASSED++))
  else
    echo -e "  ${RED}✗ SOUL.md 创建逻辑缺失或错误${NC}"
    ((TEST_FAILED++))
  fi
}

test_home_fallback() {
  local script="$1"
  echo -e "${YELLOW}测试：$script - \$HOME fallback${NC}"
  
  if grep -q 'if \[ -z "\$HOME" \]' "$script" || grep -q 'HOME=.*getent' "$script"; then
    echo -e "  ${GREEN}✓ \$HOME fallback 存在${NC}"
    ((TEST_PASSED++))
  else
    echo -e "  ${RED}✗ \$HOME fallback 缺失${NC}"
    ((TEST_FAILED++))
  fi
}

test_error_handling() {
  local script="$1"
  echo -e "${YELLOW}测试：$script - 错误处理${NC}"
  
  if grep -q 'set -euo pipefail\|set -e' "$script" && grep -q '|| {' "$script"; then
    echo -e "  ${GREEN}✓ 错误处理完善${NC}"
    ((TEST_PASSED++))
  else
    echo -e "  ${RED}✗ 错误处理不足${NC}"
    ((TEST_FAILED++))
  fi
}

test_workspace_check() {
  local script="$1"
  echo -e "${YELLOW}测试：$script - 工作区检查${NC}"
  
  if grep -q 'if \[ -d "\$WORKSPACE" \]' "$script" || grep -q 'mkdir -p.*||' "$script"; then
    echo -e "  ${GREEN}✓ 工作区检查存在${NC}"
    ((TEST_PASSED++))
  else
    echo -e "  ${RED}✗ 工作区检查缺失${NC}"
    ((TEST_FAILED++))
  fi
}

test_syntax() {
  local script="$1"
  echo -e "${YELLOW}测试：$script - 语法检查${NC}"
  
  if bash -n "$script" 2>/dev/null; then
    echo -e "  ${GREEN}✓ 语法正确${NC}"
    ((TEST_PASSED++))
  else
    echo -e "  ${RED}✗ 语法错误${NC}"
    ((TEST_FAILED++))
  fi
}

# 主测试流程
echo ""
echo -e "${GREEN}╔══════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  🧪 安装脚本自动化测试              ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════╝${NC}"
echo ""

# 测试所有安装脚本
for script in scripts/full-install.sh scripts/simple-install.sh; do
  if [ -f "$script" ]; then
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}测试脚本：$script${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    test_syntax "$script"
    test_soul_creation "$script"
    test_home_fallback "$script"
    test_error_handling "$script"
    test_workspace_check "$script"
    
    echo ""
  fi
done

# 汇总结果
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}测试结果汇总${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}通过：$TEST_PASSED${NC}"
echo -e "${RED}失败：$TEST_FAILED${NC}"
echo ""

if [ $TEST_FAILED -eq 0 ]; then
  echo -e "${GREEN}✅ 所有测试通过！${NC}"
  exit 0
else
  echo -e "${RED}❌ 有 $TEST_FAILED 个测试失败${NC}"
  exit 1
fi
