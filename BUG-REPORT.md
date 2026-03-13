# 🐛 Bug Report — AI 朝廷项目全面审查

> 生成时间：2025-07-25  
> 审查范围：install.sh, install-lite.sh, install-mac.sh, doctor.sh, Dockerfile, docker-compose.yml, openclaw.example.json, docs/, gui/, skills/, .github/, README.md, README_EN.md  
> 共发现 **42 个 Bug**（Critical: 4 / High: 11 / Medium: 16 / Low: 11）

---

## Critical（4 个）

### C-01 · `install-lite.sh` 非交互环境下 `read` 阻塞导致脚本挂起
- **文件**：`install-lite.sh` L60, L70
- **描述**：`install-lite.sh` 使用 `read -p` 但未检查 `[ -t 0 ]`（终端检测）。当通过 `bash <(curl ...)` pipe 模式或 CI/CD 非交互方式运行时，`read` 没有输入来源会无限阻塞或立即读到 EOF 返回空值（行为不确定）。`install.sh` 对此有处理（L113: `if [ -t 0 ]`），但 `install-lite.sh` 遗漏了。
- **严重程度**：Critical
- **修复建议**：
  ```bash
  if [ -t 0 ]; then
      read -p "请选择 [1/2/3]（默认1）: " MODE_CHOICE
  else
      MODE_CHOICE=""
  fi
  MODE_CHOICE=${MODE_CHOICE:-1}
  ```

### C-02 · `install-mac.sh` 非交互环境下同样存在 `read` 阻塞
- **文件**：`install-mac.sh` L171
- **描述**：同 C-01。`read -p "请选择 [1/2/3]（默认1）: " DEPLOY_MODE` 在 pipe 运行时会阻塞。
- **严重程度**：Critical
- **修复建议**：同 C-01，添加 `[ -t 0 ]` 检测。

### C-03 · `docker/init-docker.sh` 飞书事件订阅提示使用 Webhook 而非 WebSocket
- **文件**：`docker/init-docker.sh` L99
- **描述**：提示 `"配置事件订阅回调：http://你的IP:18789/webhooks/feishu"`，但 OpenClaw 飞书集成使用的是 **WebSocket 长连接**模式（不需要公网回调地址），这与 `docs/setup-feishu.md` 和 `install.sh` 中的说明自相矛盾。用户按照此提示配置 Webhook URL 无法成功接收消息。
- **严重程度**：Critical
- **修复建议**：修改提示为 `"事件接收方式选择 WebSocket 长连接（无需配置回调 URL）"`。

### C-04 · `docker-compose.yml` volume 挂载使用环境变量展开在 compose 中不可靠
- **文件**：`docker-compose.yml` L10-13
- **描述**：`${OPENCLAW_CONFIG_PATH:-/root/.openclaw/openclaw.json}` 和 `${OPENCLAW_WORKSPACE:-/root/clawd}` 作为 volume 挂载目标路径使用了 shell 默认值语法。Docker Compose 不支持 `:-` 默认值语法（这是 shell 语法，不是 compose 变量语法），实际行为取决于 compose 版本。在未设置环境变量时，某些 compose 版本可能将 `${OPENCLAW_CONFIG_PATH:-/root/.openclaw/openclaw.json}` 当作字面字符串处理，导致挂载失败。
- **严重程度**：Critical
- **修复建议**：使用 `.env` 文件设置默认值，或直接使用硬编码路径（Docker 镜像本身就假定 `/root`）：
  ```yaml
  volumes:
    - ./openclaw.json:/root/.openclaw/openclaw.json
    - court-workspace:/root/clawd
  ```

---

## High（11 个）

### H-01 · ✅ `install.sh` 使用 `$SUDO npm install -g` 在已有 nvm/volta 环境下会破坏用户的 Node 环境
- **文件**：`install.sh` L252-255
- **描述**：`$SUDO npm install -g openclaw` 使用 sudo 安装全局 npm 包。如果用户通过 nvm/volta 管理 Node.js，sudo 调用的是系统 npm（而非 nvm 管理的 npm），安装位置与用户 PATH 不一致，导致 `openclaw` 命令找不到。
- **严重程度**：High
- **修复建议**：检测 nvm 环境时不使用 sudo：
  ```bash
  if [ -n "$NVM_DIR" ] || [ -n "$VOLTA_HOME" ]; then
      npm install -g openclaw --loglevel=error
  else
      $SUDO npm install -g openclaw --loglevel=error
  fi
  ```

### H-02 · `doctor.sh` 使用 `((...))` 算术但缺少 `set -e` 保护下的错误处理
- **文件**：`doctor.sh` L14-16
- **描述**：`((PASS++))` / `((WARN++))` / `((FAIL++))` 在 bash 下当变量值为 0 时，`(( 0 ))` 返回退出码 1。如果脚本后续添加 `set -e`，或用户在 `set -e` 环境中 source 此脚本，第一次 `((PASS++))` 就会导致脚本退出。虽然当前脚本没有 `set -e`，但这是潜在隐患。
- **严重程度**：High
- **修复建议**：改为 `PASS=$((PASS + 1))` 或 `((PASS++)) || true`。

### H-03 · `doctor.sh` 中 `json_get` 函数对含特殊字符的路径不安全
- **文件**：`doctor.sh` L23-50
- **描述**：`json_get` 使用字符串插值 `open('$file')` 和 `'$path'` 传参给 Python/Node。如果配置文件路径或 JSON key 中含单引号（如 `it's`），会导致代码注入或语法错误。
- **严重程度**：High
- **修复建议**：使用环境变量传参（如 viking.sh 的做法）：
  ```bash
  JSON_FILE="$file" JSON_PATH="$path" python3 -c "
  import json, os
  d = json.load(open(os.environ['JSON_FILE']))
  ..."
  ```

### H-04 · `Dockerfile` 以 root 用户运行容器
- **文件**：`Dockerfile` L1-57
- **描述**：整个 Dockerfile 没有 `USER` 指令，容器以 root 运行。若 Agent 代码执行或用户输入导致命令注入，攻击者将获得容器内 root 权限，可以修改 `/entrypoint.sh`、读取挂载的密钥等。
- **严重程度**：High
- **修复建议**：创建非特权用户：
  ```dockerfile
  RUN useradd -m -s /bin/bash court
  USER court
  ```
  同时调整工作区和配置目录的权限。

### H-05 · ✅ `gui/server/index.js` 中 `/api/health` 引用了可能未定义的 `wss` 变量
- **文件**：`gui/server/index.js` L426
- **描述**：`typeof wss !== 'undefined' ? wss.clients.size : 0`。虽然使用了 `typeof` 检测，但 `wss` 是在文件后面通过 `import { WebSocketServer } from 'ws'` 导入但从未实例化为 `wss` 变量（代码中 `import { WebSocketServer } from 'ws'` 存在但 `wss` 从未被赋值），所以 `wss.clients.size` 始终为 0 或报错。这是死代码/不完整功能。
- **严重程度**：High
- **修复建议**：要么完成 WebSocket 服务器初始化，要么移除相关引用，避免误导。

### H-06 · ✅ `openclaw.example.json` 中 `$HOME` 不会被 JSON 解析器展开
- **文件**：`openclaw.example.json` L29
- **描述**：`"workspace": "$HOME/clawd"` 包含 shell 变量 `$HOME`。JSON 文件不会自动展开 shell 变量。如果用户直接复制此文件作为配置，OpenClaw 可能无法识别 `$HOME`（除非框架自身有变量替换逻辑），导致工作区路径错误。
- **严重程度**：High（如果 OpenClaw 不支持变量展开则为 Critical）
- **修复建议**：在 example.json 中使用字面路径或占位符 + 注释：
  ```json
  "workspace": "/home/YOUR_USERNAME/clawd"
  ```
  并添加注释说明用户需要替换。

### H-07 · ✅ `install.sh` 中 heredoc 内的 `$HOME` 变量在 JSON 中不加引号
- **文件**：`install.sh` L297, L352 等处（CONFIG_EOF heredoc 内部）
- **描述**：heredoc 使用 `<< CONFIG_EOF`（不带引号），所以 `$HOME` 会被当前 shell 展开。这通常是期望行为，但如果 `$HOME` 含空格（如 macOS 上 `/Users/John Smith`），生成的 JSON 会格式错误。此外，如果用户在 Docker 中以非 root 身份运行，`$HOME` 可能为空。
- **严重程度**：High
- **修复建议**：对 `$HOME` 做引号保护或验证：
  ```bash
  WORKSPACE_PATH="${HOME:-/root}/clawd"
  ```

### H-08 · `install.sh` Swap 创建没有检查磁盘剩余空间
- **文件**：`install.sh` L139-146
- **描述**：直接 `fallocate -l 4G /swapfile` 而不检查可用空间。在小磁盘的 VPS（如 50GB 几乎用满）上会导致磁盘写满，系统可能变得不稳定。
- **严重程度**：High
- **修复建议**：创建 Swap 前检查可用空间：
  ```bash
  AVAIL_GB=$(df / --output=avail -BG | tail -1 | tr -d 'G ')
  if [ "$AVAIL_GB" -lt 6 ]; then
      echo "磁盘空间不足（剩余 ${AVAIL_GB}GB），跳过 Swap"
  fi
  ```

### H-09 · ✅ `gui/server/index.js` 使用 `readFileSync` 同步读取可能很大的 JSONL 文件
- **文件**：`gui/server/index.js` L354-380（`buildSessionsData` → `countSessionFile`）
- **描述**：`buildSessionsData()` 遍历所有 Agent 的所有 session，对每个 JSONL 文件调用 `countSessionFile()` 同步读取。如果有几百个 session 文件，每个几十 MB，Node.js 事件循环会被长时间阻塞，导致所有 API 请求超时。
- **严重程度**：High
- **修复建议**：改为异步读取 + Worker Thread，或限制扫描的文件数量/大小。

### H-10 · `docker-compose.yml` 使用 bind mount 挂载 `./openclaw.json` 但该文件可能不存在
- **文件**：`docker-compose.yml` L10
- **描述**：`- ./openclaw.json:...` 使用 bind mount。如果用户在 `docker compose up` 之前没有创建 `openclaw.json`，Docker 会自动创建一个**目录**（而非文件），导致容器内配置读取失败。
- **严重程度**：High
- **修复建议**：在 `docker-compose.yml` 添加注释明确说明需要先创建文件，或在 `entrypoint.sh` 中检测文件类型。也可以先 `cp openclaw.example.json openclaw.json` 再启动。

### H-11 · `install.sh` 中 `iptables` 命令不检查当前用户是否有权限执行
- **文件**：`install.sh` L109
- **描述**：`if iptables -L INPUT -n 2>/dev/null | grep -q "REJECT"` — 在非 root 环境（$SUDO 非空）下，此命令未使用 `$SUDO`，所以 `iptables -L` 可能因权限不足返回空结果，导致误判"无 REJECT 规则"。
- **严重程度**：High
- **修复建议**：改为 `$SUDO iptables -L INPUT -n 2>/dev/null`。

---

## Medium（16 个）

### M-01 · `README.md` 与 `README_EN.md` 版本号不一致
- **文件**：`README.md` L315 / `README_EN.md` L271
- **描述**：中文版标注 `v3.0`，英文版标注 `v3.5.1`。应该保持同步。
- **严重程度**：Medium
- **修复建议**：统一版本号。

### M-02 · `Dockerfile` 构建时 `gui/node_modules` 会被复制进镜像
- **文件**：`Dockerfile` L50 / `.dockerignore`
- **描述**：`.dockerignore` 排除了 `gui/node_modules` 和 `gui/dist`，但 `COPY gui/ /opt/gui/` 仍会复制其他开发文件（如 `src/`、`tsconfig.json` 等）。镜像未执行 `npm run build`，也没有 serve 前端 build 产物——server 只启动 `node server/index.js` 后端。前端代码在镜像中是未构建的，占用空间且无用。
- **严重程度**：Medium
- **修复建议**：在 Dockerfile 中添加 `RUN cd /opt/gui && npm run build` 并用 express.static 提供 `dist/` 静态文件。或只复制 `gui/server/`。

### M-03 · `docker/entrypoint.sh` 后台启动 GUI 服务但不处理进程退出
- **文件**：`docker/entrypoint.sh` L68-72
- **描述**：`node server/index.js &` 后台启动 GUI，将 PID 保存到 `$GUI_PID` 但从未使用该变量做健康检查或清理。如果 GUI 崩溃，不会自动重启。
- **严重程度**：Medium
- **修复建议**：使用 `trap` 清理子进程，或使用简单的 watch 循环：
  ```bash
  (while true; do node server/index.js; sleep 2; done) &
  ```

### M-04 · `install.sh` 完成后尝试运行 `doctor.sh` 但路径可能不存在
- **文件**：`install.sh` L841-848
- **描述**：`if [ -f "$WORKSPACE/doctor.sh" ]` 检查 `~/clawd/doctor.sh`，但安装脚本从未将 `doctor.sh` 复制到工作区。`doctor.sh` 存在于 git 仓库中，但一键安装不会 clone 仓库。备选的 curl 下载路径可以工作，但前提是网络可用。
- **严重程度**：Medium
- **修复建议**：直接使用 curl 下载方式，移除对本地文件的检查，或在安装过程中下载 doctor.sh 到工作区。

### M-05 · `gui/server/index.js` Token 统计使用了双重 map 但缺少 `deptMap` 中的新部门
- **文件**：`gui/server/index.js` L530
- **描述**：`getTokenStats()` 中的 `deptMap` 不包含 `neiwufu`（内务府）、`taiyiyuan`（太医院）、`guozijian`（国子监）、`yushanfang`（御膳房），但 `AGENT_DEPT_MAP`（L35）包含这些。导致 Token 统计页面这些部门显示为原始 ID。
- **严重程度**：Medium
- **修复建议**：统一使用顶部定义的 `AGENT_DEPT_MAP`，移除 `getTokenStats` 内部的重复 map。

### M-06 · `gui/server/index.js` 缓存 `buildSessionsData` 但从未失效
- **文件**：`gui/server/index.js` L340
- **描述**：`buildSessionsData()` 使用 5 分钟 TTL 缓存。但会话新增/更新后，用户可能需要等 5 分钟才能看到最新数据。应该提供手动刷新缓存的 API。
- **严重程度**：Medium
- **修复建议**：添加 `/api/cache/clear` endpoint 或在 POST 操作后自动清缓存。

### M-07 · `doctor.sh` Discord API 验证循环中 `sleep 0.3` 在 bash 中可能不精确
- **文件**：`doctor.sh` L324
- **描述**：`sleep 0.3` 在某些最小化 shell（如 Alpine 的 busybox sh）中不支持浮点数，会报错或被忽略。
- **严重程度**：Medium
- **修复建议**：改为 `sleep 1` 或用 `usleep` 兜底。

### M-08 · `install.sh` Chromium snap 检测在 macOS/Docker 环境下会产生错误输出
- **文件**：`install.sh` L192
- **描述**：`snap list chromium &>/dev/null 2>&1` 虽然重定向了输出，但 `snap` 命令在非 Ubuntu 或无 snapd 的系统上仍可能导致延迟。`$IN_DOCKER` 检查已部分覆盖，但 Alpine 等无 snap 的 Linux 发行版仍会执行此检测。
- **严重程度**：Medium
- **修复建议**：先检查 `command -v snap` 再调用。

### M-09 · `openclaw.example.json` 同时启用了 Discord（true）和飞书（false），bindings 包含飞书路由
- **文件**：`openclaw.example.json` L131, L148-155
- **描述**：飞书 `"enabled": false` 但 bindings 数组最后一条是飞书路由 `{"agentId":"silijian","match":{"channel":"feishu","accountId":"silijian"}}`。虽然不会报错（匹配不到会被忽略），但示例文件应该保持一致性，避免用户困惑。
- **严重程度**：Medium
- **修复建议**：要么移除飞书 binding，要么添加注释说明"取消注释以启用飞书"。

### M-10 · `.github/workflows/docker.yml` 仅在 tag push 时触发，PR 无 CI 测试
- **文件**：`.github/workflows/docker.yml` L3-5
- **描述**：workflow 只在 `push: tags: ['v*']` 和 `workflow_dispatch` 时触发。PR 没有任何 CI 检查（lint、test、build 验证），代码质量无保障。
- **严重程度**：Medium
- **修复建议**：添加 PR 触发的 CI workflow（至少包含 shellcheck、JSON 格式验证、npm test）。

### M-11 · `gui/server/index.js` 多处使用 `require('fs')` 同步操作混合了 ESM import
- **文件**：`gui/server/index.js` L273-280
- **描述**：文件顶部使用 `import { readFileSync } from 'fs'`，但在 `countSessionFile` 函数中使用 `require('fs').openSync` / `readSync` / `closeSync`。虽然通过 `createRequire` 兼容了，但混合两种模块系统增加了维护复杂度。
- **严重程度**：Medium
- **修复建议**：统一使用 ESM import 的 fs 方法。

### M-12 · `gui/server/keepalive.sh` 使用 `lsof` 可能未安装
- **文件**：`gui/server/keepalive.sh` L37
- **描述**：`lsof -i :18795 -t` 在 Alpine 和最小化 Docker 镜像中不可用。
- **严重程度**：Medium
- **修复建议**：使用 `fuser 18795/tcp` 或 `ss -tlnp` 替代。

### M-13 · `install.sh` Alpine Node.js 安装使用 edge 仓库可能引入不稳定包
- **文件**：`install.sh` L172-175
- **描述**：`apk add --repository=https://dl-cdn.alpinelinux.org/alpine/edge/main nodejs npm` 从 edge（开发分支）安装，可能获取到不稳定版本或与当前 Alpine release 不兼容。
- **严重程度**：Medium
- **修复建议**：优先尝试当前版本仓库，仅在版本不够时才 fallback 到 edge。

### M-14 · `gui/server/index.js` 的 `/api/weather` 用白名单过滤 location 但仍允许注入 Unicode
- **文件**：`gui/server/index.js` L620
- **描述**：`location.replace(/[^a-zA-Z0-9\s,.\-\u4e00-\u9fff]/g, '')` 允许 CJK 字符范围 `\u4e00-\u9fff`，但这个范围不覆盖所有 Unicode 字符可能造成的问题。不过因为后续用了 `encodeURIComponent()` 和 `fetch()`（不是 exec），实际安全风险已降低。
- **严重程度**：Medium（防御已到位，但正则可以更精确）
- **修复建议**：将最大长度限制为 100 个字符，防止超长输入。

### M-15 · `docker/init-docker.sh` 中 Python heredoc 使用了 shell 变量作为 Python 字符串
- **文件**：`docker/init-docker.sh` L126-180
- **描述**：Python heredoc 中的 `"$API_URL"`、`"$API_KEY"`、`"$MODEL_ID"` 等通过 shell 展开直接嵌入 Python 代码。如果用户输入含 `"""` 三引号或反斜杠的值，会破坏 Python 语法或导致代码注入。
- **严重程度**：Medium
- **修复建议**：使用环境变量传参或 `json.dumps` 转义。

### M-16 · `gui/server/index.js` `/api/dashboard/summary` 读取 session 文件获取 `lastMessagePreview` 效率极低
- **文件**：`gui/server/index.js` L478-500
- **描述**：对每个部门都读取整个 session 文件寻找最后一条 assistant 消息。如果有 10 个部门、每个文件 10MB，此操作在单次 API 调用中读取 100MB 数据。
- **严重程度**：Medium
- **修复建议**：只读取文件尾部（如最后 4KB），或将预览缓存到 session 元数据中。

---

## Low（11 个）

### L-01 · `install.sh` PUPPETEER 路径检测逻辑问题
- **文件**：`install.sh` L228-234
- **描述**：`if ! grep -q PUPPETEER_EXECUTABLE_PATH ~/.bashrc ~/.zshrc 2>/dev/null` 在文件不存在时跳过配置。但如果 `.bashrc` 不存在而 `.zshrc` 存在，grep 可能会误判。且 macOS 用户可能只有 `.zshrc`。
- **严重程度**：Low
- **修复建议**：分别检查两个文件。

### L-02 · `Dockerfile` 安装 `python3-pip` 和 `python3-venv` 但后续 pip 安装 openviking 可能失败
- **文件**：`Dockerfile` L32-34
- **描述**：`python3 -m venv /opt/openviking` 创建 venv 后使用 `pip install openviking`。如果 openviking 包不存在于 PyPI（或已改名），Docker build 不会失败（因为 `|| true`），但用户可能误以为已安装。
- **严重程度**：Low
- **修复建议**：移除 `|| true` 或改为 `2>/dev/null || echo "⚠ OpenViking 安装跳过"`。

### L-03 · `gui/keepalive.sh` 和 `gui/server/keepalive.sh` 功能重复
- **文件**：`gui/keepalive.sh` / `gui/server/keepalive.sh`
- **描述**：两个 keepalive 脚本功能重叠，维护两套代码容易不同步。
- **严重程度**：Low
- **修复建议**：合并为一个脚本，另一个做软链接或删除。

### L-04 · `gui/server/index.js` Notion 人事数据硬编码 `2024` 年份
- **文件**：`gui/server/index.js` L658
- **描述**：`tenure: '${2024 + i}年任职'` 硬编码了年份基数。随着时间推移，数据会越来越不合理。
- **严重程度**：Low
- **修复建议**：使用 `new Date().getFullYear()` 动态计算。

### L-05 · `gui/server/index.js` demo cron 数据的 `nextRun` 使用当前时间
- **文件**：`gui/server/index.js` L725-728
- **描述**：fallback demo 数据中 `nextRun: new Date().toISOString()` 表示"下次运行时间 = 现在"，可能让用户误以为任务即将执行。
- **严重程度**：Low
- **修复建议**：使用未来时间或 null。

### L-06 · `README.md` 维权声明中日期 "2026年2月22日" 可能为笔误
- **文件**：`README.md` L276 / `README_EN.md` L233
- **描述**：`2026年2月22日` — 如果当前年份是 2025 年，这个日期是未来日期，可能是笔误（应为 2025）。
- **严重程度**：Low
- **修复建议**：确认实际首发日期并修正。

### L-07 · `skills/quadrants/scripts/quadrants-cli.sh` 缺少 `jq` 依赖检查
- **文件**：`skills/quadrants/scripts/quadrants-cli.sh`
- **描述**：脚本大量使用 `jq` 构建 JSON，但没有在开头检查 `jq` 是否已安装。在未安装 jq 的系统上会报错 `jq: command not found`。
- **严重程度**：Low
- **修复建议**：在脚本开头添加 `command -v jq &>/dev/null || { echo "Error: jq required"; exit 1; }`。

### L-08 · `install.sh` / `install-lite.sh` / `install-mac.sh` 三个脚本大量代码重复
- **文件**：三个安装脚本
- **描述**：配置文件生成（JSON heredoc）在三个脚本中几乎完全相同，总计约 1500 行重复代码。未来修改需要同步三个文件，容易遗漏。
- **严重程度**：Low
- **修复建议**：提取公共函数到 `lib/config-templates.sh`，三个脚本 source 引用。

### L-09 · `gui/src/hooks/useStatus.ts` 在组件卸载后可能触发状态更新
- **文件**：`gui/src/hooks/useStatus.ts` L15-28
- **描述**：`fetchStatus` 是异步的，如果组件在 fetch 返回前卸载，`setData` / `setError` 会在已卸载组件上调用。React 18+ 不再警告此问题，但可能导致内存泄漏。
- **严重程度**：Low
- **修复建议**：使用 AbortController 在 cleanup 中取消请求。

### L-10 · `docs/setup-feishu.md` 权限表与 `飞书配置指南.md` 可能不同步
- **文件**：`docs/setup-feishu.md` L43-55
- **描述**：权限表列出 9 个权限，但提到"见飞书配置指南"的文档。如果两个文件权限列表不一致，用户可能漏配权限。
- **严重程度**：Low
- **修复建议**：指定一个权威来源，另一个引用之。

### L-11 · `.github/workflows/docker.yml` 缺少 provenance 和 SBOM 安全最佳实践
- **文件**：`.github/workflows/docker.yml`
- **描述**：`docker/build-push-action` 未配置 `provenance: true` 和 `sbom: true`，缺少供应链安全元数据。
- **严重程度**：Low
- **修复建议**：添加 `provenance: true` 和 `sbom: true` 到 build-push-action。

---

## 汇总

| 严重程度 | 数量 | 涉及文件 |
|---------|------|---------|
| 🔴 Critical | 4 | install-lite.sh, install-mac.sh, docker/init-docker.sh, docker-compose.yml |
| 🟠 High | 11 | install.sh, doctor.sh, Dockerfile, gui/server/index.js, openclaw.example.json |
| 🟡 Medium | 16 | README.md, Dockerfile, docker-compose.yml, gui/server/index.js, .github/, install.sh, docker/*.sh |
| 🟢 Low | 11 | gui/, skills/, docs/, .github/, README*.md |

### 优先修复建议

1. **立即修复**（C-01~C-04）：install-lite.sh/install-mac.sh 的 read 阻塞、init-docker.sh 飞书文档矛盾、docker-compose.yml 变量展开问题
2. **尽快修复**（H-01~H-11）：Dockerfile 安全加固、doctor.sh 代码注入风险、JSON 中 $HOME 处理
3. **下一版本**（M-01~M-16）：版本号同步、CI 流程完善、GUI 性能优化
4. **长期改善**（L-01~L-11）：代码去重、依赖检查、文档同步
