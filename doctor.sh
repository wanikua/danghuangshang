#!/bin/bash
# ============================================
# AI 朝廷配置诊断脚本（doctor.sh）
# 检查常见配置问题，帮助排查故障
# 支持 Discord + 飞书双频道诊断
# ============================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

PASS=0
WARN=0
FAIL=0

pass() { echo -e "  ${GREEN}✓${NC} $1"; PASS=$((PASS + 1)); }
warn() { echo -e "  ${YELLOW}⚠${NC} $1"; WARN=$((WARN + 1)); }
fail() { echo -e "  ${RED}✗${NC} $1"; FAIL=$((FAIL + 1)); }
info() { echo -e "  ${CYAN}ℹ${NC} $1"; }

# JSON 值提取辅助（用 python3 或 node）
# [H-03] 使用环境变量传参，避免路径/key 含特殊字符时的代码注入
json_get() {
    local file="$1" path="$2"
    if command -v python3 &>/dev/null; then
        JSON_FILE="$file" JSON_PATH="$path" python3 -c "
import json, os, sys
try:
    d = json.load(open(os.environ['JSON_FILE']))
    keys = os.environ['JSON_PATH'].split('.')
    for k in keys:
        if isinstance(d, dict):
            d = d.get(k)
        else:
            d = None
            break
    if d is not None:
        if isinstance(d, (dict, list)):
            print(json.dumps(d))
        else:
            print(d)
except: pass
" 2>/dev/null
    elif command -v node &>/dev/null; then
        JSON_FILE="$file" JSON_PATH="$path" node -e "
try {
    const d = require(process.env.JSON_FILE);
    const v = process.env.JSON_PATH.split('.').reduce((o,k) => o && o[k], d);
    if (v !== undefined) console.log(typeof v === 'object' ? JSON.stringify(v) : v);
} catch(e) {}
" 2>/dev/null
    fi
}

# 列出 JSON 对象的 key
json_keys() {
    local file="$1" path="$2"
    if command -v python3 &>/dev/null; then
        JSON_FILE="$file" JSON_PATH="$path" python3 -c "
import json, os
try:
    d = json.load(open(os.environ['JSON_FILE']))
    for k in os.environ['JSON_PATH'].split('.'):
        d = d.get(k, {})
    if isinstance(d, dict):
        for k in d: print(k)
except: pass
" 2>/dev/null
    elif command -v node &>/dev/null; then
        JSON_FILE="$file" JSON_PATH="$path" node -e "
try {
    let d = require(process.env.JSON_FILE);
    for (const k of process.env.JSON_PATH.split('.')) d = d && d[k];
    if (d && typeof d === 'object') Object.keys(d).forEach(k => console.log(k));
} catch(e) {}
" 2>/dev/null
    fi
}

echo ""
echo -e "${BLUE}🏥 AI 朝廷配置诊断${NC}"
echo "================================"
echo ""

# ---- [1/9] 检测 CLI ----
echo -e "${YELLOW}[1/9] 检查安装...${NC}"

if command -v openclaw &>/dev/null; then
    CLI_CMD="openclaw"
    CLI_VER=$(openclaw --version 2>/dev/null || echo "unknown")
    pass "OpenClaw 已安装 ($CLI_VER)"
elif command -v clawdbot &>/dev/null; then
    CLI_CMD="clawdbot"
    CLI_VER=$(clawdbot --version 2>/dev/null || echo "unknown")
    pass "Clawdbot 已安装 ($CLI_VER)"
else
    fail "未检测到 OpenClaw 或 Clawdbot — 请先安装: npm install -g openclaw@latest"
    CLI_CMD=""
fi

NODE_VER=$(node -v 2>/dev/null || echo "none")
if [[ "$NODE_VER" == v22* ]] || [[ "$NODE_VER" == v23* ]] || [[ "$NODE_VER" == v24* ]] || [[ "$NODE_VER" == v25* ]]; then
    pass "Node.js $NODE_VER"
elif [[ "$NODE_VER" == "none" ]]; then
    fail "Node.js 未安装"
else
    warn "Node.js $NODE_VER — 推荐 v22+"
fi

# ---- [2/9] 检测配置文件 ----
echo ""
echo -e "${YELLOW}[2/9] 检查配置文件...${NC}"

CONFIG_FILE=""
if [ -f "$HOME/.openclaw/openclaw.json" ]; then
    CONFIG_FILE="$HOME/.openclaw/openclaw.json"
elif [ -f "$HOME/.clawdbot/clawdbot.json" ]; then
    CONFIG_FILE="$HOME/.clawdbot/clawdbot.json"
fi

if [ -z "$CONFIG_FILE" ]; then
    fail "配置文件不存在 — 请运行 $CLI_CMD onboard 或手动创建"
    echo ""
    echo -e "${RED}配置文件缺失，后续检查无法进行${NC}"
    echo ""
    exit 1
fi

pass "配置文件: $CONFIG_FILE"

# 检查JSON格式（通过环境变量传路径，避免特殊字符注入）
if JSON_FILE="$CONFIG_FILE" python3 -c "import json, os; json.load(open(os.environ['JSON_FILE']))" 2>/dev/null; then
    pass "JSON 格式正确"
elif JSON_FILE="$CONFIG_FILE" node -e "require(process.env.JSON_FILE)" 2>/dev/null; then
    pass "JSON 格式正确"
else
    fail "JSON 格式错误 — 请检查语法（多余逗号、缺少引号等）"
    info "用这个工具检查: https://jsonlint.com"
fi

# ---- [3/9] 检测 API Key ----
echo ""
echo -e "${YELLOW}[3/9] 检查模型配置...${NC}"

if grep -q "YOUR_LLM_API_KEY\|YOUR_API_KEY\|your-api-key\|sk-xxx\|your-provider" "$CONFIG_FILE" 2>/dev/null; then
    fail "API Key 未填写 — 配置文件中仍有占位符"
    info "编辑 $CONFIG_FILE，把 YOUR_LLM_API_KEY 替换成真实的 Key"
else
    pass "API Key 已填写（未检测到占位符）"
fi

if grep -q '"providers"' "$CONFIG_FILE" 2>/dev/null; then
    PROVIDER_COUNT=$(grep -o '"baseUrl"' "$CONFIG_FILE" | wc -l)
    pass "模型 Provider 已配置（$PROVIDER_COUNT 个）"
else
    fail "未找到 models.providers 配置"
fi

# ---- [4/9] 检测 Discord 配置 ----
echo ""
echo -e "${YELLOW}[4/9] 检查 Discord 配置...${NC}"

DISCORD_ENABLED=$(json_get "$CONFIG_FILE" "channels.discord.enabled")

if grep -q '"discord"' "$CONFIG_FILE" 2>/dev/null; then
    if [ "$DISCORD_ENABLED" = "true" ]; then
        pass "Discord 已启用"

        # 检查 Bot Token 占位符
        BOT_PLACEHOLDER=$(grep -cE "YOUR_.*BOT_TOKEN|YOUR_.*_TOKEN" "$CONFIG_FILE" 2>/dev/null || true)
        BOT_PLACEHOLDER=${BOT_PLACEHOLDER:-0}
        [ "$BOT_PLACEHOLDER" -eq "$BOT_PLACEHOLDER" ] 2>/dev/null || BOT_PLACEHOLDER=0
        if [ "$BOT_PLACEHOLDER" -gt 0 ]; then
            fail "有 $BOT_PLACEHOLDER 个 Bot Token 未填写"
            info "去 https://discord.com/developers/applications 创建 Bot 并复制 Token"
        else
            BOT_COUNT=$(grep -c '"token":' "$CONFIG_FILE" 2>/dev/null || true)
            BOT_COUNT=${BOT_COUNT:-0}
            pass "Bot Token 已填写（$BOT_COUNT 个 Bot）"
        fi

        # 检查 allowBots
        DISCORD_ALLOW_BOTS=$(json_get "$CONFIG_FILE" "channels.discord.allowBots")
        if [ "$DISCORD_ALLOW_BOTS" = "true" ]; then
            pass "allowBots: true（Bot 之间可以互相触发）"
        else
            warn "allowBots 未开启 — Bot 之间无法互相对话"
            info "在 channels.discord 中添加 \"allowBots\": true"
        fi

        # 检查 groupPolicy
        DISCORD_GP=$(json_get "$CONFIG_FILE" "channels.discord.groupPolicy")
        if [ "$DISCORD_GP" = "open" ]; then
            pass "groupPolicy: open（群聊消息已放行）"
        else
            warn "groupPolicy 不是 open（当前: ${DISCORD_GP:-未设置}）— @everyone 可能不触发"
            info "确保 channels.discord.groupPolicy 设为 \"open\""
        fi

        # ---- Discord API 在线验证 ----
        if [ "$BOT_PLACEHOLDER" -eq 0 ] && command -v curl &>/dev/null; then
            echo ""
            echo -e "${CYAN}  🔍 Discord API 在线验证...${NC}"
            echo ""

            DISCORD_ACCOUNTS=$(json_keys "$CONFIG_FILE" "channels.discord.accounts")
            while IFS= read -r acct; do
                [ -z "$acct" ] && continue
                TOKEN=$(json_get "$CONFIG_FILE" "channels.discord.accounts.$acct.token")
                ACCT_NAME=$(json_get "$CONFIG_FILE" "channels.discord.accounts.$acct.name")
                DISPLAY_NAME="${ACCT_NAME:-$acct}"

                [ -z "$TOKEN" ] && continue
                [[ "$TOKEN" == YOUR_* ]] && continue

                # --- 验证 Token ---
                # SEC-29: 用 process substitution 传递 header，避免 Token 在 ps/top 命令行中泄露
                USER_RESP=$(curl -sS -w "\n%{http_code}" -H @<(echo "Authorization: Bot $TOKEN") \
                    "https://discord.com/api/v10/users/@me" 2>/dev/null)
                HTTP_CODE=$(echo "$USER_RESP" | tail -1)
                USER_BODY=$(echo "$USER_RESP" | sed '$d')

                if [ "$HTTP_CODE" = "200" ]; then
                    BOT_INFO=$(echo "$USER_BODY" | python3 -c "
import json, sys
d = json.load(sys.stdin)
print(d.get('username','?') + '|' + d.get('id','?'))
" 2>/dev/null)
                    BOT_USERNAME=$(echo "$BOT_INFO" | cut -d'|' -f1)
                    BOT_ID=$(echo "$BOT_INFO" | cut -d'|' -f2)
                    pass "[$DISPLAY_NAME] Token 有效 — @$BOT_USERNAME (ID: $BOT_ID)"
                elif [ "$HTTP_CODE" = "401" ]; then
                    fail "[$DISPLAY_NAME] Token 无效（401）— 请重新复制 Bot Token"
                    continue
                else
                    warn "[$DISPLAY_NAME] API 请求失败（HTTP $HTTP_CODE）— 网络问题或被限流"
                    continue
                fi

                # --- 检查 Privileged Intents ---
                APP_RESP=$(curl -sS -w "\n%{http_code}" -H @<(echo "Authorization: Bot $TOKEN") \
                    "https://discord.com/api/v10/applications/@me" 2>/dev/null)
                APP_CODE=$(echo "$APP_RESP" | tail -1)
                APP_BODY=$(echo "$APP_RESP" | sed '$d')

                if [ "$APP_CODE" = "200" ]; then
                    FLAGS=$(echo "$APP_BODY" | python3 -c "import json,sys; print(json.load(sys.stdin).get('flags',0))" 2>/dev/null)
                    FLAGS=${FLAGS:-0}

                    # Message Content Intent: bit 18 (262144) or limited bit 19 (524288)
                    MSG_CONTENT=$(( (FLAGS >> 18) & 1 ))
                    MSG_CONTENT_LTD=$(( (FLAGS >> 19) & 1 ))
                    if [ "$MSG_CONTENT" -eq 1 ] || [ "$MSG_CONTENT_LTD" -eq 1 ]; then
                        pass "[$DISPLAY_NAME] Message Content Intent ✓"
                    else
                        fail "[$DISPLAY_NAME] Message Content Intent 未开启 — Bot 无法读取消息内容"
                        info "Discord Developer Portal → Bot → Privileged Gateway Intents → 开启 Message Content Intent"
                    fi

                    # Server Members Intent: bit 14 (16384) or limited bit 15 (32768)
                    MEMBERS=$(( (FLAGS >> 14) & 1 ))
                    MEMBERS_LTD=$(( (FLAGS >> 15) & 1 ))
                    if [ "$MEMBERS" -eq 1 ] || [ "$MEMBERS_LTD" -eq 1 ]; then
                        pass "[$DISPLAY_NAME] Server Members Intent ✓"
                    else
                        fail "[$DISPLAY_NAME] Server Members Intent 未开启 — Bot 无法解析 @mention"
                        info "Discord Developer Portal → Bot → Privileged Gateway Intents → 开启 Server Members Intent"
                    fi

                    # Presence Intent: bit 12 (4096) or limited bit 13 (8192) — optional
                    PRESENCE=$(( (FLAGS >> 12) & 1 ))
                    PRESENCE_LTD=$(( (FLAGS >> 13) & 1 ))
                    if [ "$PRESENCE" -eq 1 ] || [ "$PRESENCE_LTD" -eq 1 ]; then
                        pass "[$DISPLAY_NAME] Presence Intent ✓"
                    else
                        info "[$DISPLAY_NAME] Presence Intent 未开启（可选，不影响核心功能）"
                    fi
                else
                    warn "[$DISPLAY_NAME] 无法获取 Application 信息（HTTP $APP_CODE）— Intent 检查跳过"
                fi

                # --- 检查服务器权限 ---
                GUILDS_RESP=$(curl -sS -w "\n%{http_code}" -H @<(echo "Authorization: Bot $TOKEN") \
                    "https://discord.com/api/v10/users/@me/guilds" 2>/dev/null)
                GUILDS_CODE=$(echo "$GUILDS_RESP" | tail -1)
                GUILDS_BODY=$(echo "$GUILDS_RESP" | sed '$d')

                if [ "$GUILDS_CODE" = "200" ]; then
                    GUILD_LINES=$(echo "$GUILDS_BODY" | python3 -c "
import json, sys
guilds = json.load(sys.stdin)
print(len(guilds))
for g in guilds:
    perms = int(g.get('permissions', 0))
    name = g.get('name', '?')
    gid = g.get('id', '?')
    view_ch  = bool(perms & (1 << 10))
    send_msg = bool(perms & (1 << 11))
    read_hist = bool(perms & (1 << 16))
    embed_links = bool(perms & (1 << 14))
    print(f'{gid}|{name}|{view_ch}|{send_msg}|{read_hist}|{embed_links}')
" 2>/dev/null)

                    GUILD_COUNT=$(echo "$GUILD_LINES" | head -1)
                    if [ "${GUILD_COUNT:-0}" -gt 0 ]; then
                        pass "[$DISPLAY_NAME] 已加入 $GUILD_COUNT 个服务器"

                        echo "$GUILD_LINES" | tail -n +2 | while IFS='|' read -r gid gname can_view can_send can_read can_embed; do
                            [ -z "$gid" ] && continue
                            MISSING=""
                            [ "$can_view" = "False" ] && MISSING="${MISSING} View_Channels"
                            [ "$can_send" = "False" ] && MISSING="${MISSING} Send_Messages"
                            [ "$can_read" = "False" ] && MISSING="${MISSING} Read_History"

                            if [ -z "$MISSING" ]; then
                                pass "[$DISPLAY_NAME] 「$gname」权限正常（查看+发送+历史记录）"
                            else
                                fail "[$DISPLAY_NAME] 「$gname」缺少权限:$MISSING"
                                info "服务器设置 → 角色 → 给 $DISPLAY_NAME 的角色添加:$MISSING"
                            fi
                        done
                    else
                        fail "[$DISPLAY_NAME] 未加入任何服务器"
                        info "用 OAuth2 链接邀请: https://discord.com/oauth2/authorize?client_id=$BOT_ID&permissions=274877975552&scope=bot"
                    fi
                else
                    warn "[$DISPLAY_NAME] 无法获取服务器列表（HTTP $GUILDS_CODE）"
                fi

                # [M-07] 小间隔防止 rate limit（用整数秒兼容 busybox/Alpine）
                sleep 1

            done <<< "$DISCORD_ACCOUNTS"

            echo ""
        elif ! command -v curl &>/dev/null; then
            info "curl 未安装 — 跳过 Discord API 在线验证"
        fi

        echo -e "${CYAN}  📋 Discord 手动排查清单：${NC}"
        echo -e "     1. Discord Developer Portal → 每个 Bot 开启 ${YELLOW}Message Content Intent${NC}"
        echo -e "     2. Discord Developer Portal → 每个 Bot 开启 ${YELLOW}Server Members Intent${NC}"
        echo -e "     3. Discord Developer Portal → 每个 Bot 开启 ${YELLOW}Presence Intent${NC}（可选）"
        echo -e "     4. 服务器设置 → 每个 Bot 角色有 ${YELLOW}View Channels${NC} + ${YELLOW}Send Messages${NC} 权限"
        echo -e "     5. 配置文件 → channels.discord.${YELLOW}groupPolicy: \"open\"${NC}"
        echo -e "     6. 配置文件 → 每个 account 的 ${YELLOW}groupPolicy: \"open\"${NC}"
        echo -e "     7. 配置文件 → channels.discord.${YELLOW}\"allowBots\": true${NC}（Bot互触发需要）"
        echo ""
    elif [ "$DISCORD_ENABLED" = "false" ]; then
        info "Discord 已配置但未启用（enabled: false）— 如果使用飞书可忽略"
    else
        warn "Discord 配置存在但 enabled 状态不明确"
    fi
else
    info "Discord 未配置（如果不用 Discord 可忽略）"
fi

# ---- [5/9] 检测飞书配置 ----
echo ""
echo -e "${YELLOW}[5/9] 检查飞书配置...${NC}"

FEISHU_ENABLED=$(json_get "$CONFIG_FILE" "channels.feishu.enabled")

if grep -q '"feishu"' "$CONFIG_FILE" 2>/dev/null; then
    # 5a. 启用状态
    if [ "$FEISHU_ENABLED" = "true" ]; then
        pass "飞书已启用（enabled: true）"
    elif [ "$FEISHU_ENABLED" = "false" ]; then
        fail "飞书已配置但未启用 — 设置 channels.feishu.enabled 为 true"
    else
        warn "飞书 enabled 状态不明确 — 请确认 channels.feishu.enabled: true"
    fi

    # 5b. dmPolicy 检查
    FEISHU_DM_POLICY=$(json_get "$CONFIG_FILE" "channels.feishu.dmPolicy")
    if [ "$FEISHU_DM_POLICY" = "open" ]; then
        pass "飞书 dmPolicy: open（私聊直接对话）"
    elif [ "$FEISHU_DM_POLICY" = "pairing" ]; then
        info "飞书 dmPolicy: pairing — 首次私聊需要运行 openclaw pairing approve"
        info "新手建议改为 \"open\" 简化流程"
    elif [ -z "$FEISHU_DM_POLICY" ]; then
        warn "飞书 dmPolicy 未设置 — 建议设为 \"open\"（直接私聊）或 \"pairing\"（配对审批）"
        info "在 channels.feishu 中添加 \"dmPolicy\": \"open\""
    fi

    # 5b2. groupPolicy（顶层）检查
    FEISHU_GP=$(json_get "$CONFIG_FILE" "channels.feishu.groupPolicy")
    if [ "$FEISHU_GP" = "open" ]; then
        pass "飞书 groupPolicy: open（群聊消息已开放）"
    elif [ -z "$FEISHU_GP" ]; then
        warn "飞书顶层 groupPolicy 未设置 — 群聊可能不响应"
        info "在 channels.feishu 中添加 \"groupPolicy\": \"open\""
    fi

    # 5b3. allowBots（仅多 Bot 模式才需要）
    FEISHU_ALLOW_BOTS=$(json_get "$CONFIG_FILE" "channels.feishu.allowBots")

    # 5c. 检查 accounts
    FEISHU_ACCOUNTS=$(json_keys "$CONFIG_FILE" "channels.feishu.accounts")
    FEISHU_ACCOUNT_COUNT=$(echo "$FEISHU_ACCOUNTS" | grep -c . 2>/dev/null || true)
    FEISHU_ACCOUNT_COUNT=${FEISHU_ACCOUNT_COUNT:-0}
    [ "$FEISHU_ACCOUNT_COUNT" -eq "$FEISHU_ACCOUNT_COUNT" ] 2>/dev/null || FEISHU_ACCOUNT_COUNT=0

    if [ "$FEISHU_ACCOUNT_COUNT" -gt 0 ]; then
        pass "飞书已配置 $FEISHU_ACCOUNT_COUNT 个 Bot 账户"

        if [ "$FEISHU_ACCOUNT_COUNT" -gt 1 ]; then
            info "多 Bot 模式（六部架构）— 确保每个 Bot 在飞书开放平台都是独立应用"
            # 多 Bot 模式才需要 allowBots
            if [ "$FEISHU_ALLOW_BOTS" = "true" ]; then
                pass "飞书 allowBots: true（Bot 之间可以互相触发）"
            else
                warn "飞书 allowBots 未开启 — 多 Bot 模式下 Bot 之间无法互相对话"
                info "在 channels.feishu 中添加 \"allowBots\": true"
            fi
        else
            info "单 Bot 模式（推荐）— 司礼监 + sessions_spawn 后台调度"
        fi

        # 逐个检查 account
        FEISHU_ISSUES=0
        while IFS= read -r acct; do
            [ -z "$acct" ] && continue

            ACCT_APPID=$(json_get "$CONFIG_FILE" "channels.feishu.accounts.$acct.appId")
            ACCT_SECRET=$(json_get "$CONFIG_FILE" "channels.feishu.accounts.$acct.appSecret")
            ACCT_GP=$(json_get "$CONFIG_FILE" "channels.feishu.accounts.$acct.groupPolicy")
            ACCT_NAME=$(json_get "$CONFIG_FILE" "channels.feishu.accounts.$acct.name")

            DISPLAY_NAME="${ACCT_NAME:-$acct}"

            # 检查 appId
            if [ -z "$ACCT_APPID" ] || [ "$ACCT_APPID" = "cli_xxx" ] || [ "$ACCT_APPID" = "YOUR_APP_ID" ]; then
                fail "[$DISPLAY_NAME] appId 未填写或仍是占位符"
                ((FEISHU_ISSUES++))
            elif [[ "$ACCT_APPID" == cli_* ]]; then
                pass "[$DISPLAY_NAME] appId 格式正确 (${ACCT_APPID:0:12}...)"
            else
                warn "[$DISPLAY_NAME] appId 格式异常（应以 cli_ 开头，当前: ${ACCT_APPID:0:12}...）"
                ((FEISHU_ISSUES++))
            fi

            # 检查 appSecret
            if [ -z "$ACCT_SECRET" ] || [ "$ACCT_SECRET" = "YOUR_APP_SECRET" ] || [ "$ACCT_SECRET" = "xxx" ]; then
                fail "[$DISPLAY_NAME] appSecret 未填写或仍是占位符"
                ((FEISHU_ISSUES++))
            else
                pass "[$DISPLAY_NAME] appSecret 已填写"
            fi

            # 检查 groupPolicy
            if [ "$ACCT_GP" = "open" ]; then
                pass "[$DISPLAY_NAME] groupPolicy: open ✓"
            elif [ -n "$ACCT_GP" ]; then
                warn "[$DISPLAY_NAME] groupPolicy: $ACCT_GP — 如需群聊消息请设为 \"open\""
            else
                warn "[$DISPLAY_NAME] groupPolicy 未设置 — 群消息可能不响应"
                info "在该 account 中添加 \"groupPolicy\": \"open\""
            fi

        done <<< "$FEISHU_ACCOUNTS"

        # 5d. 检查 bindings 中飞书路由
        FEISHU_BINDING_COUNT=$(grep -cE '"channel":\s*"feishu"' "$CONFIG_FILE" 2>/dev/null || true)
        FEISHU_BINDING_COUNT=${FEISHU_BINDING_COUNT:-0}
        [ "$FEISHU_BINDING_COUNT" -eq "$FEISHU_BINDING_COUNT" ] 2>/dev/null || FEISHU_BINDING_COUNT=0
        if [ "$FEISHU_BINDING_COUNT" -gt 0 ]; then
            pass "Bindings 中有 $FEISHU_BINDING_COUNT 条飞书路由"
            if [ "$FEISHU_ACCOUNT_COUNT" -gt 1 ] && [ "$FEISHU_BINDING_COUNT" -lt "$FEISHU_ACCOUNT_COUNT" ]; then
                warn "飞书 account ($FEISHU_ACCOUNT_COUNT) 多于飞书 binding ($FEISHU_BINDING_COUNT) — 部分 Bot 可能没有绑定到 Agent"
            fi
        else
            if [ "$FEISHU_ACCOUNT_COUNT" -gt 1 ]; then
                fail "多 Bot 模式但没有飞书 binding — Bot 无法路由到对应 Agent"
                info "在 bindings 数组中为每个飞书 account 添加路由规则"
            else
                if [ "$FEISHU_BINDING_COUNT" -gt 0 ]; then
                    pass "单 Bot 模式 — 1 条飞书 binding ✓"
                else
                    warn "单 Bot 模式但没有飞书 binding — 建议添加 binding 确保消息路由正确"
                    info "在 bindings 数组中添加: {\"agentId\": \"silijian\", \"match\": {\"channel\": \"feishu\", \"accountId\": \"silijian\"}}"
                fi
            fi
        fi

        if [ "$FEISHU_ISSUES" -eq 0 ]; then
            echo ""
            pass "飞书配置基本完整 ✓"
        fi

    else
        fail "飞书 accounts 为空 — 至少需要配置一个 Bot 账户"
        info "在 channels.feishu.accounts 中添加飞书应用的 appId 和 appSecret"
    fi

    # 5e. 飞书排查清单
    echo ""
    echo -e "${CYAN}  📋 飞书机器人不响应？逐项检查：${NC}"
    echo -e "     1. 飞书开放平台 → 应用已${YELLOW}发布${NC}（版本管理中创建并发布）"
    echo -e "     2. 飞书开放平台 → 事件订阅中添加了 ${YELLOW}im.message.receive_v1${NC}"
    echo -e "     3. 飞书开放平台 → 事件接收方式选择 ${YELLOW}WebSocket 长连接${NC}"
    echo -e "     4. 飞书开放平台 → 权限管理中 ${YELLOW}im:message${NC} 等权限全部已审批通过"
    echo -e "     5. 飞书开放平台 → 应用能力中已开启${YELLOW}机器人${NC}能力"
    echo -e "     6. 飞书群聊 → 机器人已${YELLOW}添加到群聊${NC}中"
    echo -e "     7. 配置文件 → channels.feishu.${YELLOW}enabled: true${NC}"
    echo -e "     8. 配置文件 → 每个 account 的 ${YELLOW}appId${NC} 以 cli_ 开头"
    echo -e "     9. 配置文件 → 每个 account 的 ${YELLOW}appSecret${NC} 已正确填写"
    echo -e "    10. 配置文件 → 每个 account 的 ${YELLOW}groupPolicy: \"open\"${NC}（群消息需要）"
    echo -e "    11. 配置文件 → ${YELLOW}allowBots: true${NC}（仅多 Bot 模式需要）"
    echo -e "    12. 多 Bot → 每个 Bot 的 ${YELLOW}bindings${NC} 路由到正确的 Agent"
    echo ""
    echo -e "${CYAN}  🔍 进一步诊断：${NC}"
    echo -e "     • 查看 Gateway 日志: ${YELLOW}$CLI_CMD gateway logs${NC} 或 ${YELLOW}$CLI_CMD logs --follow${NC}"
    echo -e "     • 飞书开放平台 → 事件订阅 → ${YELLOW}近期事件${NC}（查看是否有事件推送记录）"
    echo -e "     • 飞书开放平台 → 开发者后台 → ${YELLOW}日志查询${NC}（查看 API 调用日志）"
    echo ""
else
    info "飞书未配置（如果不用飞书可忽略）"
    info "飞书配置指南: https://github.com/wanikua/boluobobo-ai-court-tutorial/blob/main/飞书配置指南.md"
fi

# ---- [6/9] 检测 Docker / Sandbox 权限 ----
echo ""
echo -e "${YELLOW}[6/9] 检查 Docker / Sandbox 权限...${NC}"

if command -v docker &>/dev/null; then
    pass "Docker 已安装"
    if docker info &>/dev/null 2>&1; then
        pass "Docker 权限正常（可以连接 docker.sock）"
    else
        if [ "$(id -u)" -eq 0 ]; then
            fail "Docker 已安装但无法连接 — 检查 Docker daemon 是否启动: systemctl start docker"
        else
            fail "Docker 权限不足 — 非 root 用户无法连接 docker.sock"
            info "修复方法: sudo usermod -aG docker \$USER && newgrp docker"
            info "或重新登录后生效"
            info "这会导致 sandbox 模式（子代理沙箱）无法工作"
        fi
    fi
else
    if grep -q '"sandbox"' "$CONFIG_FILE" 2>/dev/null; then
        SANDBOX_MODE=$(json_get "$CONFIG_FILE" "agents.defaults.sandbox.mode")
        if [ "$SANDBOX_MODE" = "off" ]; then
            info "Docker 未安装，sandbox 已关闭，无影响"
        else
            warn "Docker 未安装但配置了 sandbox — 子代理沙箱将无法工作"
            info "安装 Docker: curl -fsSL https://get.docker.com | sh"
            info "或关闭 sandbox: 把 agents.defaults.sandbox.mode 设为 \"off\""
        fi
    else
        info "Docker 未安装（sandbox 未配置，可忽略）"
    fi
fi

# ---- [7/9] 检测 Agents 配置 ----
echo ""
echo -e "${YELLOW}[7/9] 检查 Agent 配置...${NC}"

# 使用 JSON 解析准确统计 agents.list 数组长度（避免 grep 误匹配 model id 等字段）
if command -v python3 &>/dev/null; then
    AGENT_COUNT=$(JSON_FILE="$CONFIG_FILE" python3 -c "
import json, os
try:
    d = json.load(open(os.environ['JSON_FILE']))
    print(len(d.get('agents', {}).get('list', [])))
except: print(0)
" 2>/dev/null)
elif command -v node &>/dev/null; then
    AGENT_COUNT=$(JSON_FILE="$CONFIG_FILE" node -e "
try {
    const d = require(process.env.JSON_FILE);
    console.log(((d.agents || {}).list || []).length);
} catch(e) { console.log(0); }
" 2>/dev/null)
else
    AGENT_COUNT=$(grep -c '"id":' "$CONFIG_FILE" 2>/dev/null || true)
fi
AGENT_COUNT=${AGENT_COUNT:-0}
[ "$AGENT_COUNT" -eq "$AGENT_COUNT" ] 2>/dev/null || AGENT_COUNT=0
if [ "$AGENT_COUNT" -gt 0 ]; then
    pass "已配置 $AGENT_COUNT 个 Agent"
else
    warn "未检测到 Agent 配置"
fi

# 检查 bindings 总数
BINDING_COUNT=$(grep -c '"agentId":' "$CONFIG_FILE" 2>/dev/null || true)
BINDING_COUNT=${BINDING_COUNT:-0}
[ "$BINDING_COUNT" -eq "$BINDING_COUNT" ] 2>/dev/null || BINDING_COUNT=0
if [ "$BINDING_COUNT" -gt 0 ]; then
    pass "已配置 $BINDING_COUNT 条 Binding 路由"
else
    warn "未检测到 Binding 路由 — Agent 可能收不到消息"
fi

if [ "$AGENT_COUNT" -gt 0 ] && [ "$BINDING_COUNT" -gt 0 ]; then
    if [ "$AGENT_COUNT" -ne "$BINDING_COUNT" ]; then
        # 飞书单 Bot 模式下 10 agent + 1 binding 是正常的（司礼监 sessions_spawn 后台调度）
        if [ "$FEISHU_ENABLED" = "true" ] && [ "$BINDING_COUNT" -eq 1 ] && [ "$FEISHU_ACCOUNT_COUNT" -le 1 ] 2>/dev/null; then
            pass "飞书单 Bot 模式 — $AGENT_COUNT 个 Agent + 1 条 Binding（司礼监入口，其余后台调度）"
        else
            warn "Agent 数量（$AGENT_COUNT）和 Binding 数量（$BINDING_COUNT）不一致 — 部分 Agent 可能没有绑定"
        fi
    fi
fi

# 检查 identity 配置
if [ "$AGENT_COUNT" -gt 0 ]; then
    AGENT_IDS=$(json_keys "$CONFIG_FILE" "agents.list" 2>/dev/null)
    # 用 python/node 获取缺 identity 的 agent 列表
    MISSING_IDENTITY=""
    if command -v python3 &>/dev/null; then
        MISSING_IDENTITY=$(JSON_FILE="$CONFIG_FILE" python3 -c "
import json, os
try:
    d = json.load(open(os.environ['JSON_FILE']))
    agents = d.get('agents', {}).get('list', [])
    missing = []
    for a in agents:
        aid = a.get('id', '?')
        name = a.get('name', aid)
        identity = a.get('identity')
        if not identity or not identity.get('theme'):
            missing.append(name)
    if missing:
        print(','.join(missing))
except: pass
" 2>/dev/null)
    elif command -v node &>/dev/null; then
        MISSING_IDENTITY=$(JSON_FILE="$CONFIG_FILE" node -e "
try {
    const d = require(process.env.JSON_FILE);
    const agents = (d.agents || {}).list || [];
    const missing = agents.filter(a => !a.identity || !a.identity.theme).map(a => a.name || a.id);
    if (missing.length) console.log(missing.join(','));
} catch(e) {}
" 2>/dev/null)
    fi

    if [ -n "$MISSING_IDENTITY" ]; then
        MISSING_COUNT=$(echo "$MISSING_IDENTITY" | tr ',' '\n' | wc -l)
        fail "有 $MISSING_COUNT 个 Agent 缺少 identity.theme（角色描述）"
        info "缺少 identity 的 Agent: $MISSING_IDENTITY"
        info "Agent 没有 identity.theme 会不知道自己的角色定位，影响回答质量"
        info "参考模板补全: https://github.com/wanikua/boluobobo-ai-court-tutorial/blob/main/openclaw.example.json"
        echo ""
        echo -e "${CYAN}  📋 修复方法：${NC}"
        echo -e "     1. 编辑 ${YELLOW}$CONFIG_FILE${NC}"
        echo -e "     2. 在每个 agent 对象里加上 ${YELLOW}\"identity\": { \"theme\": \"你是...\" }${NC}"
        echo -e "     3. 重启: ${YELLOW}$CLI_CMD gateway restart${NC}"
        echo ""
    else
        pass "所有 Agent 都有 identity.theme（角色描述）✓"
    fi
fi

# ---- [8/9] 检测工作区 ----
echo ""
echo -e "${YELLOW}[8/9] 检查工作区...${NC}"

WORKSPACE=$(json_get "$CONFIG_FILE" "agents.defaults.workspace" | sed "s|\$HOME|$HOME|;s|~|$HOME|")
if [ -z "$WORKSPACE" ]; then
    WORKSPACE="$HOME/clawd"
fi

if [ -d "$WORKSPACE" ]; then
    pass "工作区目录存在: $WORKSPACE"
else
    fail "工作区目录不存在: $WORKSPACE"
    info "运行: mkdir -p $WORKSPACE"
fi

[ -f "$WORKSPACE/SOUL.md" ] && pass "SOUL.md ✓" || warn "SOUL.md 不存在 — Agent 缺少行为准则"
[ -f "$WORKSPACE/USER.md" ] && pass "USER.md ✓" || warn "USER.md 不存在 — Agent 不了解用户信息"
[ -d "$WORKSPACE/memory" ] && pass "memory/ ✓" || warn "memory/ 目录不存在 — 运行: mkdir -p $WORKSPACE/memory"

# ---- [9/9] 检测可选集成 ----
echo ""
echo -e "${YELLOW}[9/9] 检查可选集成与服务...${NC}"

# Notion
if [ -f "$HOME/.config/notion/api_key" ]; then
    NOTION_KEY=$(cat "$HOME/.config/notion/api_key" 2>/dev/null)
    if [[ "$NOTION_KEY" == ntn_* ]] || [[ "$NOTION_KEY" == secret_* ]]; then
        pass "Notion API Key 已配置"
    else
        warn "Notion API Key 格式异常（应以 ntn_ 或 secret_ 开头）"
    fi
else
    info "Notion 未配置（可选，跳过）"
fi

# Gateway 服务状态
if systemctl --user is-active openclaw-gateway &>/dev/null; then
    pass "Gateway 服务运行中（openclaw-gateway）"
elif systemctl --user is-active clawdbot-gateway &>/dev/null; then
    pass "Gateway 服务运行中（clawdbot-gateway）"
elif systemctl is-active openclaw-gateway &>/dev/null 2>&1; then
    pass "Gateway 服务运行中（openclaw-gateway, system）"
elif systemctl is-active clawdbot-gateway &>/dev/null 2>&1; then
    pass "Gateway 服务运行中（clawdbot-gateway, system）"
else
    warn "Gateway 服务未运行 — 可手动启动: $CLI_CMD gateway start"
    info "或前台调试: $CLI_CMD gateway --verbose"
fi

# ---- 运行 OpenClaw 自带的 doctor ----
echo ""
if [ -n "$CLI_CMD" ]; then
    echo -e "${YELLOW}运行 $CLI_CMD doctor...${NC}"
    $CLI_CMD doctor --non-interactive 2>/dev/null || info "$CLI_CMD doctor 执行失败（可忽略）"
fi

# ---- 汇总 ----
echo ""
echo "================================"
echo -e "诊断完成：${GREEN}$PASS 通过${NC}  ${YELLOW}$WARN 警告${NC}  ${RED}$FAIL 错误${NC}"
echo "================================"
echo ""

if [ "$FAIL" -gt 0 ]; then
    echo -e "${RED}有 $FAIL 个错误需要修复，请按提示操作。${NC}"
elif [ "$WARN" -gt 0 ]; then
    echo -e "${YELLOW}配置基本正确，有 $WARN 个警告建议检查。${NC}"
else
    echo -e "${GREEN}🎉 配置完美！所有检查通过。${NC}"
fi

echo ""

# 根据配置的频道给出针对性提示
if [ "$DISCORD_ENABLED" = "true" ]; then
    echo -e "Discord 提示：确认 Discord Developer Portal 中"
    echo -e "每个 Bot 都开启了 ${YELLOW}Message Content Intent${NC} 和 ${YELLOW}Server Members Intent${NC}"
    echo ""
fi

if [ "$FEISHU_ENABLED" = "true" ]; then
    echo -e "飞书提示：确认飞书开放平台中每个应用都已${YELLOW}发布${NC}，"
    echo -e "事件订阅使用 ${YELLOW}WebSocket 长连接${NC}，且添加了 ${YELLOW}im.message.receive_v1${NC} 事件"
    echo ""
fi

echo -e "需要帮助？${BLUE}https://discord.gg/clawd${NC}"
echo ""
