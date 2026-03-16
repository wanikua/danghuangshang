import express from 'express';
import cors from 'cors';
import { readFileSync, readdirSync, existsSync, statSync, createReadStream, openSync, readSync, closeSync } from 'fs';
import { readFile } from 'fs/promises';
import { join, resolve } from 'path';
import { fileURLToPath } from 'url';
import { dirname } from 'path';
import readline from 'readline';
import os from 'os';
import http from 'http';
import { createRequire } from 'module';
const require = createRequire(import.meta.url);
import { WebSocketServer } from 'ws';
import { exec as _exec, execFile as _execFile } from 'child_process';
import { promisify } from 'util';
const execAsync = promisify(_exec);
const execFileAsync = promisify(_execFile);

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// CLI 命令
let CLI_CMD = 'clawdbot';
try {
  await execAsync('which clawdbot', { encoding: 'utf-8', timeout: 3000 });
  CLI_CMD = 'clawdbot';
} catch {
  try {
    await execAsync('which openclaw', { encoding: 'utf-8', timeout: 3000 });
    CLI_CMD = 'openclaw';
  } catch { CLI_CMD = 'clawdbot'; }
}

const app = express();
const PORT = process.env.BOLUO_GUI_PORT || 18795;

// SEC-03: 不再使用硬编码默认 Token
import crypto from 'crypto';
let AUTH_TOKEN = process.env.BOLUO_AUTH_TOKEN;
if (!AUTH_TOKEN || AUTH_TOKEN === 'changeme') {
  AUTH_TOKEN = crypto.randomBytes(16).toString('hex');
  console.warn('');
  console.warn('╔══════════════════════════════════════════════════════════════╗');
  console.warn('║  ⚠️  安全警告: BOLUO_AUTH_TOKEN 未设置或使用了默认值!       ║');
  console.warn('║  已自动生成随机 Token（仅本次运行有效）                     ║');
  console.warn('║  请设置环境变量: export BOLUO_AUTH_TOKEN=$(openssl rand -hex 16) ║');
  console.warn('╚══════════════════════════════════════════════════════════════╝');
  console.warn(`  本次 Token: ${AUTH_TOKEN}`);
  console.warn('');
}

const AGENT_DEPT_MAP = {
  'silijian': '司礼监', 'main': '司礼监', 'gongbu': '工部', 'hubu': '户部',
  'libu': '礼部', 'libu2': '吏部',
  'xingbu': '刑部', 'bingbu': '兵部',
  'neige': '内阁', 'duchayuan': '都察院', 'neiwufu': '内务府',
  'hanlinyuan': '翰林院',
  'hanlin_zhang': '翰林院·掌院学士',
  'hanlin_xiuzhuan': '翰林院·修撰',
  'hanlin_bianxiu': '翰林院·编修',
  'hanlin_jiantao': '翰林院·检讨',
  'hanlin_shujishi': '翰林院·庶吉士',
  'taiyiyuan': '太医院', 'guozijian': '国子监',
  'yushanfang': '御膳房'
};

// GUI botId → clawdbot agent id 映射（silijian 在 GUI 里是司礼监，但实际 agent id 是 main）
const BOT_TO_AGENT = { 'silijian': 'main' };
function resolveAgentId(botId) {
  return BOT_TO_AGENT[botId] || botId;
}

const HOME = process.env.HOME || '/home/ubuntu';
// 兼容 OpenClaw (.openclaw) 和 Clawdbot (.clawdbot) 两种目录结构
const OPENCLAW_DIR = existsSync(join(HOME, '.openclaw'))
  ? join(HOME, '.openclaw')
  : existsSync(join(HOME, '.clawdbot'))
    ? join(HOME, '.clawdbot')
    : join(HOME, '.openclaw'); // fallback

const STATE_DIR = OPENCLAW_DIR;
const AGENTS_DIR = join(STATE_DIR, 'agents');

// SEC: 验证 session 文件路径在合法目录内
function isValidSessionPath(filePath) {
  if (!filePath) return false;
  const resolved = resolve(filePath);
  return resolved.startsWith(AGENTS_DIR) || resolved.startsWith(STATE_DIR);
}
// 兼容配置文件名
const CONFIG_PATH = existsSync(join(OPENCLAW_DIR, 'openclaw.json'))
  ? join(OPENCLAW_DIR, 'openclaw.json')
  : join(OPENCLAW_DIR, 'clawdbot.json');

app.use(cors());
app.use(express.json());

function authMiddleware(req, res, next) {
  const token = req.headers.authorization?.replace('Bearer ', '');
  if (token !== AUTH_TOKEN) {
    return res.status(401).json({ error: 'Unauthorized' });
  }
  next();
}

function formatUptime(seconds) {
  const d = Math.floor(seconds / 86400);
  const h = Math.floor((seconds % 86400) / 3600);
  const m = Math.floor((seconds % 3600) / 60);
  const parts = [];
  if (d > 0) parts.push(`${d}d`);
  if (h > 0) parts.push(`${h}h`);
  parts.push(`${m}m`);
  return parts.join(' ');
}

function getOpenclawConfig() {
  try {
    if (existsSync(CONFIG_PATH)) {
      return JSON.parse(readFileSync(CONFIG_PATH, 'utf-8'));
    }
  } catch (e) { }
  return null;
}

// SEC-15: 验证 agentId 防止路径遍历
function sanitizeAgentId(id) {
  if (!id || typeof id !== 'string') return null;
  if (/[\/\\.\s]/.test(id) || id.includes('..')) return null;
  if (!/^[a-zA-Z0-9_-]{1,64}$/.test(id)) return null;
  return id;
}

function getAgentSessionData(agentId) {
  const sessionsPath = join(AGENTS_DIR, agentId, 'sessions', 'sessions.json');
  if (!existsSync(sessionsPath)) return { sessions: 0, inputTokens: 0, outputTokens: 0, totalTokens: 0, model: '' };

  try {
    const data = JSON.parse(readFileSync(sessionsPath, 'utf-8'));
    const entries = Object.values(data);
    let inputTokens = 0, outputTokens = 0, totalTokens = 0;
    let model = '';

    for (const sess of entries) {
      inputTokens += sess.inputTokens || 0;
      outputTokens += sess.outputTokens || 0;
      totalTokens += sess.totalTokens || 0;
      if (sess.model && !model) model = sess.model;
    }

    return { sessions: entries.length, inputTokens, outputTokens, totalTokens, model };
  } catch (e) {
    return { sessions: 0, inputTokens: 0, outputTokens: 0, totalTokens: 0, model: '' };
  }
}

function getRecentLogs(limit = 100) {
  const logs = [];
  if (!existsSync(AGENTS_DIR)) return logs;

  try {
    const agentDirs = readdirSync(AGENTS_DIR, { withFileTypes: true })
      .filter(d => d.isDirectory())
      .map(d => d.name);

    for (const agentId of agentDirs) {
      const sessDir = join(AGENTS_DIR, agentId, 'sessions');
      if (!existsSync(sessDir)) continue;

      const jsonlFiles = readdirSync(sessDir)
        .filter(f => f.endsWith('.jsonl'))
        .map(f => ({ name: f, mtime: statSync(join(sessDir, f)).mtimeMs }))
        .sort((a, b) => b.mtime - a.mtime)
        .slice(0, 1);

      for (const file of jsonlFiles) {
        try {
          const content = readFileSync(join(sessDir, file.name), 'utf-8');
          const lines = content.split('\n').filter(l => l.trim()).slice(-5);
          for (const line of lines) {
            try {
              const entry = JSON.parse(line);
              if (entry.role === 'assistant' && entry.content) {
                const text = typeof entry.content === 'string'
                  ? entry.content.substring(0, 200)
                  : JSON.stringify(entry.content).substring(0, 200);
                logs.push({
                  timestamp: new Date(file.mtime).toISOString(),
                  level: 'info',
                  message: text,
                  source: AGENT_DEPT_MAP[agentId] || agentId
                });
              }
            } catch (e) { }
          }
        } catch (e) { }
      }
    }
  } catch (e) { }

  return logs.sort((a, b) => b.timestamp.localeCompare(a.timestamp)).slice(0, limit);
}

// Detect which platforms an agent is bound to, from session keys
function detectAgentPlatforms(agentId) {
  const sessionsPath = join(AGENTS_DIR, agentId, 'sessions', 'sessions.json');
  const platformSet = new Set();

  if (existsSync(sessionsPath)) {
    try {
      const data = JSON.parse(readFileSync(sessionsPath, 'utf-8'));
      for (const sessionKey of Object.keys(data)) {
        // Session key format: "discord:channel:xxx", "feishu:xxx", "telegram:xxx", "cron:xxx", etc.
        const parts = sessionKey.split(':');
        const plat = parts[0]?.toLowerCase();
        if (['discord', 'telegram', 'signal', 'whatsapp', 'slack', 'feishu', 'lark'].includes(plat)) {
          // Normalize lark -> feishu
          platformSet.add(plat === 'lark' ? 'feishu' : plat);
        }
      }
    } catch (e) { }
  }

  // Also check gateway config channels
  const config = getOpenclawConfig();
  const channels = config?.channels || {};
  for (const key of Object.keys(channels)) {
    const plat = key.toLowerCase();
    if (['discord', 'telegram', 'signal', 'whatsapp', 'slack', 'feishu', 'lark'].includes(plat)) {
      // Check if this agent has accounts in that channel
      const accounts = channels[key]?.accounts || {};
      if (accounts[agentId]) {
        platformSet.add(plat === 'lark' ? 'feishu' : plat);
      }
    }
  }

  const platforms = [...platformSet];
  return platforms.length > 0 ? platforms : ['discord']; // default fallback
}

app.get('/api/status', authMiddleware, async (req, res) => {
  const config = getOpenclawConfig();
  const defaultModel = config?.agents?.defaults?.model?.primary || config?.defaultModel || 'unknown';

  let agentIds = [];
  if (existsSync(AGENTS_DIR)) {
    agentIds = readdirSync(AGENTS_DIR, { withFileTypes: true })
      .filter(d => d.isDirectory())
      .map(d => d.name);
  }

  const botAccounts = agentIds.map(id => {
    const sessData = getAgentSessionData(id);
    // Support both array and object agent list formats
    let agentConfig = {};
    if (Array.isArray(config?.agents?.list)) {
      agentConfig = config.agents.list.find(a => a.id === id) || {};
    } else {
      agentConfig = config?.agents?.list?.[id] || {};
    }
    const model = agentConfig?.model?.primary || sessData.model || defaultModel;

    // Detect platform from session keys
    const platforms = detectAgentPlatforms(id);

    return {
      name: id,
      displayName: AGENT_DEPT_MAP[id] || id,
      status: 'online',
      model: model,
      sessions: sessData.sessions,
      inputTokens: sessData.inputTokens,
      outputTokens: sessData.outputTokens,
      totalTokens: sessData.totalTokens,
      platforms: platforms,
      platform: platforms[0] || 'unknown',
    };
  });

  const totalSessions = botAccounts.reduce((s, b) => s + b.sessions, 0);
  const todayTokens = botAccounts.reduce((s, b) => s + b.totalTokens, 0);

  const mem = process.memoryUsage();
  const sysUptime = os.uptime();
  const cpuLoad = os.loadavg();

  const logs = getRecentLogs(100);

  // Measure real gateway ping — auto-detect gateway host:port from config
  let gatewayPing = -1;
  let gatewayStatus = 'unknown';
  try {
    const gwConfig = loadConfig()?.gateway || {};
    const gwHost = gwConfig.host || 'localhost';
    const gwPort = gwConfig.port || 18789;
    const pingStart = Date.now();
    const pingRes = await fetch(`http://${gwHost}:${gwPort}/health`, { signal: AbortSignal.timeout(3000) });
    if (pingRes.ok) {
      gatewayPing = Date.now() - pingStart;
      gatewayStatus = 'ready';
    } else {
      gatewayStatus = 'error';
    }
  } catch {
    gatewayStatus = 'unreachable';
  }

  const status = {
    platform: `${os.platform()} ${os.arch()}`,
    uptime: formatUptime(sysUptime),
    uptimeSeconds: Math.floor(sysUptime),
    memoryUsage: {
      rss: mem.rss,
      heapTotal: mem.heapTotal,
      heapUsed: mem.heapUsed,
      external: mem.external
    },
    cpuLoad: cpuLoad,
    cpuCores: os.cpus().length,
    gateway: {
      status: gatewayStatus,
      ping: gatewayPing,
      guilds: Object.keys(config?.channels || {}).length || 1
    },
    botAccounts: botAccounts,
    totalSessions: totalSessions,
    todayTokens: todayTokens,
    logs: logs
  };

  res.json(status);
});

app.get('/api/logs', authMiddleware, (req, res) => {
  const limit = Math.min(parseInt(req.query.limit) || 100, 500);
  const logs = getRecentLogs(limit);
  res.json({ logs });
});

app.get('/api/messages', authMiddleware, (req, res) => {
  const logs = getRecentLogs(200);
  const messages = logs
    .filter(entry => {
      const msg = entry.message || '';
      return msg.includes('channel') || msg.includes('message');
    })
    .slice(-50)
    .map((entry, i) => ({
      id: i,
      content: (entry.message || '').substring(0, 200),
      timestamp: entry.timestamp || new Date().toISOString(),
      channel: entry.source || 'general'
    }));
  res.json({ messages });
});

function getTokenStats() {
  // [M-05] 统一使用顶部 AGENT_DEPT_MAP，不再维护重复的 deptMap
  const deptMap = AGENT_DEPT_MAP;

  const byDepartment = [];
  let totalTokens = 0;

  if (existsSync(AGENTS_DIR)) {
    const agentDirs = readdirSync(AGENTS_DIR);
    for (const agentDir of agentDirs) {
      const sessionsPath = join(AGENTS_DIR, agentDir, 'sessions', 'sessions.json');
      if (existsSync(sessionsPath)) {
        try {
          const sessions = JSON.parse(readFileSync(sessionsPath, 'utf-8'));
          let deptTokens = 0;
          for (const session of Object.values(sessions)) {
            deptTokens += (session.inputTokens || 0) + (session.outputTokens || 0);
          }
          const deptName = deptMap[agentDir] || agentDir;
          byDepartment.push({ department: deptName, tokens: deptTokens });
          totalTokens += deptTokens;
        } catch (e) { }
      }
    }
  }

  const rawConfig = getOpenclawConfig();
  const tokenPrice = rawConfig?.tokenPricePerM || 0.3;
  for (const d of byDepartment) {
    d.cost = (d.tokens / 1000000 * tokenPrice).toFixed(3);
  }

  const trend = [];
  for (let i = 6; i >= 0; i--) {
    const date = new Date();
    date.setDate(date.getDate() - i);
    trend.push({
      date: date.toISOString().split('T')[0],
      tokens: 0
    });
  }

  return { byDepartment, trend, tokenPrice, totalTokens };
}

app.get('/api/tokens', authMiddleware, (req, res) => {
  const result = getTokenStats();
  res.json(result);
});

// Track cache stats
let cacheHits = 0, cacheMisses = 0;

app.get('/api/health', authMiddleware, async (req, res) => {
  try {
    const uptime = process.uptime();
    const memUsage = process.memoryUsage();
    const cpuLoad = os.loadavg();
    const sysUptime = os.uptime();

    // Count endpoints
    let endpointCount = 0;
    app._router.stack.forEach(r => { if (r.route) endpointCount++; });

    // Disk usage (async)
    let diskUsagePct = 'N/A', diskTotal = 'N/A', diskUsed = 'N/A';
    try {
      const { stdout: dfLine } = await execAsync("df -h / | tail -1", { encoding: 'utf-8', timeout: 2000 });
      const parts = dfLine.trim().split(/\s+/);
      diskTotal = parts[1] || 'N/A'; diskUsed = parts[2] || 'N/A'; diskUsagePct = parts[4] || 'N/A';
    } catch { }

    const freeMem = os.freemem();
    const totalMem = os.totalmem();

    res.json({
      status: 'healthy',
      uptime: Math.floor(uptime),
      uptimeSeconds: Math.floor(uptime),
      uptimeFormatted: formatUptime(Math.floor(uptime)),
      systemUptime: formatUptime(Math.floor(sysUptime)),
      systemUptimeSeconds: Math.floor(sysUptime),
      version: '2.0.0',
      nodeVersion: process.version,
      platform: `${os.platform()} ${os.arch()}`,
      hostname: os.hostname(),
      memory: {
        processUsedMB: Math.floor(memUsage.heapUsed / 1024 / 1024),
        processHeapMB: Math.floor(memUsage.heapTotal / 1024 / 1024),
        processRssMB: Math.floor(memUsage.rss / 1024 / 1024),
        systemTotalGB: (totalMem / 1024 / 1024 / 1024).toFixed(1),
        systemFreeGB: (freeMem / 1024 / 1024 / 1024).toFixed(1),
        systemUsedPct: ((1 - freeMem / totalMem) * 100).toFixed(1),
      },
      disk: { total: diskTotal, used: diskUsed, usagePct: diskUsagePct },
      cpu: cpuLoad.map(l => l.toFixed(2)),
      gateway: 'connected',
      endpoints: endpointCount,
      cache: { hits: cacheHits, misses: cacheMisses, keys: Object.keys(cache).length },
      wsClients: wss?.clients?.size ?? 0,
      sseClients: sseClients?.size ?? 0,
      metricsBufferSize: metricsBuffer?.length ?? 0,
      timestamp: new Date().toISOString()
    });
  } catch (err) {
    res.status(500).json({ status: 'error', error: err.message });
  }
});

// ========== CACHING ==========
const cache = {};
const CACHE_TTL = 5 * 60 * 1000; // 5 minutes

function getCached(key) {
  const entry = cache[key];
  if (entry && Date.now() - entry.ts < CACHE_TTL) { cacheHits++; return entry.data; }
  cacheMisses++;
  return null;
}

function setCache(key, data) {
  cache[key] = { data, ts: Date.now() };
}

// [M-06] 手动清除缓存的 API
function clearCache() {
  const keys = Object.keys(cache);
  for (const key of keys) delete cache[key];
  return keys.length;
}

// Periodic cache cleanup — evict expired entries every 10 minutes
setInterval(() => {
  const now = Date.now();
  for (const key of Object.keys(cache)) {
    if (now - cache[key].ts > CACHE_TTL) {
      delete cache[key];
    }
  }
}, 10 * 60 * 1000);

// [H-09] Count messages and usage from a JSONL session file (async streaming to avoid blocking event loop)
async function countSessionFile(filePath) {
  const result = { messages: 0, userMessages: 0, assistantMessages: 0, inputTokens: 0, outputTokens: 0 };
  try {
    if (!filePath || !existsSync(filePath)) return result;
    const fileSize = statSync(filePath).size;
    // Skip files larger than 50MB to avoid excessive processing
    if (fileSize > 50 * 1024 * 1024) {
      console.warn(`[Sessions] Skipping oversized session file (${(fileSize / 1024 / 1024).toFixed(1)}MB): ${filePath}`);
      return result;
    }
    const rl = readline.createInterface({
      input: createReadStream(filePath, { encoding: 'utf-8' }),
      crlfDelay: Infinity,
    });
    for await (const line of rl) {
      const trimmed = line.trim();
      if (!trimmed) continue;
      try {
        const entry = JSON.parse(trimmed);
        if (entry.type === 'message' && entry.message) {
          result.messages++;
          if (entry.message.role === 'user') result.userMessages++;
          else if (entry.message.role === 'assistant') result.assistantMessages++;
          const usage = entry.message?.usage;
          if (usage) {
            result.inputTokens += usage.input || usage.input_tokens || usage.inputTokens || 0;
            result.outputTokens += usage.output || usage.output_tokens || usage.outputTokens || 0;
          }
        }
      } catch { }
    }
  } catch { }
  return result;
}

// [H-09] Build all sessions data (cached, async to avoid blocking event loop)
async function buildSessionsData() {
  const cached = getCached('sessions');
  if (cached) return cached;
  
  const sessions = [];
  
  if (existsSync(AGENTS_DIR)) {
    const agentDirs = readdirSync(AGENTS_DIR, { withFileTypes: true })
      .filter(d => d.isDirectory()).map(d => d.name);
    for (const agentId of agentDirs) {
      const sessionsPath = join(AGENTS_DIR, agentId, 'sessions', 'sessions.json');
      if (existsSync(sessionsPath)) {
        try {
          const data = JSON.parse(readFileSync(sessionsPath, 'utf-8'));
          // Collect count promises for parallel async processing
          const entries = Object.entries(data);
          const countPromises = entries.map(([, session]) =>
            isValidSessionPath(session.sessionFile) ? countSessionFile(session.sessionFile) : Promise.resolve({ messages: 0, userMessages: 0, assistantMessages: 0, inputTokens: 0, outputTokens: 0 })
          );
          const allCounts = await Promise.all(countPromises);
          
          entries.forEach(([sessionKey, session], i) => {
            const updatedAt = session.updatedAt || 0;
            const counts = allCounts[i];
            
            // 判定渠道
            let channel = session.channel || session.lastChannel || 'unknown';
            if (channel === 'unknown') {
              if (sessionKey.includes('discord:')) channel = 'discord';
              else if (sessionKey.includes('cron:')) channel = 'cron';
              else if (sessionKey.includes('signal:')) channel = 'signal';
              else if (sessionKey.includes('telegram:')) channel = 'telegram';
            }
            
            sessions.push({
              id: `agent:${agentId}:${sessionKey}`,
              agentId,
              agentName: AGENT_DEPT_MAP[agentId] || agentId,
              channel,
              updatedAt,
              createdAt: session.createdAt || 0,
              messageCount: counts.messages,
              inputTokens: counts.inputTokens,
              outputTokens: counts.outputTokens,
              totalTokens: counts.inputTokens + counts.outputTokens,
              model: session.model || '',
              displayName: session.displayName || '',
            });
          });
        } catch (e) { }
      }
    }
  }

  sessions.sort((a, b) => b.updatedAt - a.updatedAt);
  
  const now = Date.now();
  const activeCount = sessions.filter(s => now - s.updatedAt < 3600000).length;
  
  const result = { sessions, total: sessions.length, active: activeCount };
  setCache('sessions', result);
  return result;
}

app.get('/api/sessions', authMiddleware, async (req, res) => {
  try {
    const limit = parseInt(req.query.limit) || 100;
    const data = await buildSessionsData();
    res.json({ 
      sessions: data.sessions.slice(0, limit), 
      total: data.total,
      active: data.active
    });
  } catch (err) {
    res.status(500).json({ error: err.message, sessions: [], total: 0, active: 0 });
  }
});

// [M-06] 手动刷新缓存的 API
app.post('/api/cache/clear', authMiddleware, (req, res) => {
  const cleared = clearCache();
  res.json({ success: true, clearedKeys: cleared });
});

// ========== DASHBOARD SUMMARY ==========
app.get('/api/dashboard/summary', authMiddleware, async (req, res) => {
  try {
    const cached = getCached('dashboard_summary');
    if (cached) return res.json(cached);

    const sessData = await buildSessionsData();
    const sessions = sessData.sessions;
    
    // Total tokens
    let totalInput = 0, totalOutput = 0;
    const deptActivity = {};
    for (const s of sessions) {
      totalInput += s.inputTokens || 0;
      totalOutput += s.outputTokens || 0;
      if (!deptActivity[s.agentName] || s.updatedAt > deptActivity[s.agentName].updatedAt) {
        deptActivity[s.agentName] = { name: s.agentName, updatedAt: s.updatedAt, messages: s.messageCount, tokens: s.totalTokens };
      }
    }
    
    // Department ranking by activity — with lastMessagePreview
    const deptRanking = Object.values(deptActivity)
      .sort((a, b) => b.updatedAt - a.updatedAt)
      .slice(0, 10);
    
    // Add lastMessagePreview to each department
    for (const dept of deptRanking) {
      try {
        const agentId = Object.entries(AGENT_DEPT_MAP).find(([, v]) => v === dept.name)?.[0];
        if (agentId) {
          const sessPath = join(AGENTS_DIR, agentId, 'sessions', 'sessions.json');
          if (existsSync(sessPath)) {
            const sd = JSON.parse(readFileSync(sessPath, 'utf-8'));
            let bestFile = null, bestTime = 0;
            for (const sess of Object.values(sd)) {
              if ((sess.updatedAt || 0) > bestTime && sess.sessionFile && existsSync(sess.sessionFile)) {
                bestTime = sess.updatedAt; bestFile = sess.sessionFile;
              }
            }
            if (bestFile && isValidSessionPath(bestFile)) {
              // [M-16] 只读文件尾部 4KB，避免对大文件全量读取
              const PREVIEW_TAIL = 4096;
              let tailContent;
              try {
                const fStat = statSync(bestFile);
                if (fStat.size > PREVIEW_TAIL) {
                  const fd2 = openSync(bestFile, 'r');
                  const buf2 = Buffer.alloc(PREVIEW_TAIL);
                  readSync(fd2, buf2, 0, PREVIEW_TAIL, fStat.size - PREVIEW_TAIL);
                  closeSync(fd2);
                  const raw2 = buf2.toString('utf-8');
                  tailContent = raw2.substring(raw2.indexOf('\n') + 1);
                } else {
                  tailContent = readFileSync(bestFile, 'utf-8');
                }
              } catch { tailContent = ''; }
              const lines = tailContent.split('\n').filter(l => l.trim());
              for (let i = lines.length - 1; i >= Math.max(0, lines.length - 20); i--) {
                try {
                  const e = JSON.parse(lines[i]);
                  if (e.type === 'message' && e.message?.role === 'assistant') {
                    const c = e.message.content;
                    const text = typeof c === 'string' ? c : Array.isArray(c) ? c.map(x => x.text || '').join('') : '';
                    if (text.trim()) { dept.lastMessagePreview = text.substring(0, 100); break; }
                  }
                } catch { }
              }
            }
          }
        }
      } catch { }
    }
    
    // System stats
    const mem = process.memoryUsage();
    const cpuLoad = os.loadavg();
    const sysUptime = os.uptime();
    const freeMem = os.freemem();
    const totalMem = os.totalmem();
    
    // Per-day token stats (from JSONL file dates)
    const dailyTokens = {};
    const now = new Date();
    for (let i = 6; i >= 0; i--) {
      const d = new Date(now);
      d.setDate(d.getDate() - i);
      const key = d.toISOString().split('T')[0];
      dailyTokens[key] = 0;
    }
    
    // Try to estimate daily distribution from session file modification times
    if (existsSync(AGENTS_DIR)) {
      const agentDirs = readdirSync(AGENTS_DIR, { withFileTypes: true }).filter(d => d.isDirectory()).map(d => d.name);
      for (const agentId of agentDirs) {
        const sessDir = join(AGENTS_DIR, agentId, 'sessions');
        if (!existsSync(sessDir)) continue;
        try {
          const files = readdirSync(sessDir).filter(f => f.endsWith('.jsonl'));
          for (const f of files) {
            try {
              const stat = statSync(join(sessDir, f));
              const dateKey = stat.mtime.toISOString().split('T')[0];
              if (dailyTokens[dateKey] !== undefined) {
                dailyTokens[dateKey] += Math.floor(stat.size / 100); // rough estimate
              }
            } catch { }
          }
        } catch { }
      }
    }
    
    const dailyTrend = Object.entries(dailyTokens).map(([date, tokens]) => ({ date, tokens }));
    
    // Disk usage (async)
    let diskUsage = 'N/A';
    try {
      const { stdout: du } = await execAsync("df -h / | tail -1 | awk '{print $5}'", { encoding: 'utf-8', timeout: 3000 });
      diskUsage = du.trim();
    } catch { }

    const summary = {
      totalInput,
      totalOutput,
      totalTokens: totalInput + totalOutput,
      totalSessions: sessData.total,
      activeSessions: sessData.active,
      deptRanking,
      dailyTrend,
      system: {
        memUsedMB: Math.round(mem.heapUsed / 1024 / 1024),
        memTotalMB: Math.round(mem.heapTotal / 1024 / 1024),
        sysMemUsedGB: ((totalMem - freeMem) / 1024 / 1024 / 1024).toFixed(1),
        sysMemTotalGB: (totalMem / 1024 / 1024 / 1024).toFixed(1),
        cpuLoad: cpuLoad.map(l => l.toFixed(2)),
        uptime: formatUptime(sysUptime),
        uptimeSeconds: Math.floor(sysUptime),
      },
      systemLoad: {
        cpu1m: cpuLoad[0].toFixed(2),
        cpu5m: cpuLoad[1].toFixed(2),
        cpu15m: cpuLoad[2].toFixed(2),
        memTotalGB: (totalMem / 1024 / 1024 / 1024).toFixed(1),
        memFreeGB: (freeMem / 1024 / 1024 / 1024).toFixed(1),
        memUsedPct: ((1 - freeMem / totalMem) * 100).toFixed(1),
        diskUsage,
      },
      lastUpdated: new Date().toISOString(),
      timestamp: new Date().toISOString(),
    };
    
    setCache('dashboard_summary', summary);
    res.json(summary);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ========== SESSION TIMELINE ==========
app.get('/api/sessions/:sessionId/timeline', authMiddleware, (req, res) => {
  try {
    const { sessionId } = req.params;
    const cacheKey = `timeline:${sessionId}`;
    const cached = getCached(cacheKey);
    if (cached) return res.json(cached);
    
    const parts = sessionId.split(':');
    // Only fallback to 'main' if no agent part is provided; if provided but invalid, reject
    const rawAgentId = parts[1];
    const agentId = rawAgentId ? sanitizeAgentId(rawAgentId) : 'main';
    if (!agentId) return res.status(400).json({ error: 'Invalid agent ID', timeline: [] });
    const sessionKey = parts.slice(2).join(':');
    
    const sessionsPath = join(AGENTS_DIR, agentId, 'sessions', 'sessions.json');
    if (!existsSync(sessionsPath)) return res.json({ timeline: [] });
    
    const sessionsData = JSON.parse(readFileSync(sessionsPath, 'utf-8'));
    const session = sessionsData[sessionKey];
    if (!session?.sessionFile || !existsSync(session.sessionFile)) return res.json({ timeline: [] });

    if (!isValidSessionPath(session.sessionFile)) {
      return res.status(403).json({ error: 'Invalid session file path' });
    }

    // Guard against oversized files to prevent OOM
    const fileSize = statSync(session.sessionFile).size;
    if (fileSize > 50 * 1024 * 1024) {
      return res.status(413).json({ error: `Session file too large (${(fileSize / 1024 / 1024).toFixed(1)}MB)`, timeline: [] });
    }
    
    const content = readFileSync(session.sessionFile, 'utf-8');
    const lines = content.split('\n').filter(l => l.trim());
    
    // Aggregate by hour
    const hourly = {};
    for (const line of lines) {
      try {
        const entry = JSON.parse(line);
        if (entry.type === 'message' && entry.timestamp) {
          const ts = new Date(entry.timestamp);
          const hourKey = ts.toISOString().substring(0, 13) + ':00'; // YYYY-MM-DDTHH:00
          if (!hourly[hourKey]) hourly[hourKey] = { hour: hourKey, user: 0, assistant: 0, total: 0 };
          hourly[hourKey].total++;
          if (entry.message?.role === 'user') hourly[hourKey].user++;
          else if (entry.message?.role === 'assistant') hourly[hourKey].assistant++;
        }
      } catch { }
    }
    
    const timeline = Object.values(hourly).sort((a, b) => a.hour.localeCompare(b.hour));
    const result = { timeline, sessionKey, agentId };
    setCache(cacheKey, result);
    res.json(result);
  } catch (err) {
    res.status(500).json({ error: err.message, timeline: [] });
  }
});

// 获取会话消息详情（分页 + 搜索）
app.get('/api/sessions/:sessionId/messages', authMiddleware, (req, res) => {
  try {
    const { sessionId } = req.params;
    const limit = Math.min(parseInt(req.query.limit) || 20, 100);
    const page = Math.max(parseInt(req.query.page) || 1, 1);
    const search = (req.query.search || '').toLowerCase().trim();
    const allMessages = [];
    
    const parts = sessionId.split(':');
    const rawAgentId = parts[1];
    const agentId = rawAgentId ? sanitizeAgentId(rawAgentId) : 'main';
    if (!agentId) return res.status(400).json({ error: 'Invalid agent ID', messages: [], total: 0, page: 1, totalPages: 0 });
    const sessionKey = parts.slice(2).join(':');
    
    const sessionsPath = join(AGENTS_DIR, agentId, 'sessions', 'sessions.json');
    if (existsSync(sessionsPath)) {
      const sessionsData = JSON.parse(readFileSync(sessionsPath, 'utf-8'));
      const session = sessionsData[sessionKey];
      if (session?.sessionFile && existsSync(session.sessionFile)) {
        if (!isValidSessionPath(session.sessionFile)) {
          return res.status(403).json({ error: 'Invalid session file path', messages: [], total: 0, page: 1, totalPages: 0 });
        }
        // Q2: 大文件保护 — 超过 10MB 的 JSONL 只读最后 2MB（避免 OOM）
        const fileStat = statSync(session.sessionFile);
        const MAX_FULL_READ = 10 * 1024 * 1024; // 10MB
        const TAIL_READ = 2 * 1024 * 1024; // 2MB
        let content;
        if (fileStat.size > MAX_FULL_READ && !search) {
          // 只读尾部，避免内存爆炸
          // [M-11] 统一使用 ESM import，不再混用 require('fs')
          const fd = openSync(session.sessionFile, 'r');
          const buf = Buffer.alloc(TAIL_READ);
          readSync(fd, buf, 0, TAIL_READ, fileStat.size - TAIL_READ);
          closeSync(fd);
          // 丢弃第一行（可能不完整）
          const raw = buf.toString('utf-8');
          content = raw.substring(raw.indexOf('\n') + 1);
        } else {
          content = readFileSync(session.sessionFile, 'utf-8');
        }
        const lines = content.split('\n').filter(Boolean);
        for (const line of lines) {
          try {
            const entry = JSON.parse(line);
            if (entry.type === 'message' && entry.message) {
              const msgContent = entry.message.content;
              let text = '';
              if (Array.isArray(msgContent)) {
                text = msgContent.map(c => c.text || c.type).join('');
              } else if (typeof msgContent === 'string') {
                text = msgContent;
              }
              if (text) {
                // Search filter
                if (search && !text.toLowerCase().includes(search)) continue;
                allMessages.push({
                  id: entry.id,
                  role: entry.message.role,
                  content: text.substring(0, 500),
                  timestamp: entry.timestamp || entry.message.timestamp
                });
              }
            }
          } catch { }
        }
      }
    }
    
    const total = allMessages.length;
    const totalPages = Math.max(1, Math.ceil(total / limit));
    const safePage = Math.min(page, totalPages);
    const start = (safePage - 1) * limit;
    const paginated = allMessages.slice(start, start + limit);
    
    res.json({ messages: paginated, total, page: safePage, totalPages, limit });
  } catch (err) {
    res.status(500).json({ error: err.message, messages: [], total: 0, page: 1, totalPages: 0 });
  }
});

// ========== SESSION SUMMARY ==========
app.get('/api/sessions/:sessionId/summary', authMiddleware, (req, res) => {
  try {
    const { sessionId } = req.params;
    const parts = sessionId.split(':');
    const rawAgentId = parts[1];
    const agentId = rawAgentId ? sanitizeAgentId(rawAgentId) : 'main';
    if (!agentId) return res.status(400).json({ error: 'Invalid agent ID' });
    const sessionKey = parts.slice(2).join(':');
    
    const sessionsPath = join(AGENTS_DIR, agentId, 'sessions', 'sessions.json');
    if (!existsSync(sessionsPath)) return res.json({ error: 'Session not found' });
    
    const sessionsData = JSON.parse(readFileSync(sessionsPath, 'utf-8'));
    const session = sessionsData[sessionKey];
    if (!session?.sessionFile || !existsSync(session.sessionFile)) return res.json({ error: 'Session file not found' });

    if (!isValidSessionPath(session.sessionFile)) {
      return res.status(403).json({ error: 'Invalid session file path' });
    }

    // Guard against oversized files to prevent OOM
    const fileSize = statSync(session.sessionFile).size;
    if (fileSize > 50 * 1024 * 1024) {
      return res.status(413).json({ error: `Session file too large (${(fileSize / 1024 / 1024).toFixed(1)}MB), max 50MB` });
    }

    const content = readFileSync(session.sessionFile, 'utf-8');
    const lines = content.split('\n').filter(l => l.trim());

    let totalTokens = 0, messageCount = 0, firstTs = null, lastTs = null;
    let firstMessage = '', lastMessage = '';
    const responseTimes = [];
    let lastUserTs = null;
    
    for (const line of lines) {
      try {
        const entry = JSON.parse(line);
        if (entry.type !== 'message' || !entry.message) continue;
        messageCount++;
        const ts = entry.timestamp ? new Date(entry.timestamp).getTime() : null;
        const usage = entry.message?.usage;
        if (usage) totalTokens += (usage.input || 0) + (usage.output || 0);
        
        const text = typeof entry.message.content === 'string' 
          ? entry.message.content 
          : Array.isArray(entry.message.content) 
            ? entry.message.content.map(c => c.text || '').join('')
            : '';
        
        if (!firstTs && ts) { firstTs = ts; firstMessage = text.substring(0, 200); }
        if (ts) { lastTs = ts; lastMessage = text.substring(0, 200); }
        
        if (entry.message.role === 'user' && ts) lastUserTs = ts;
        if (entry.message.role === 'assistant' && lastUserTs && ts) {
          responseTimes.push(ts - lastUserTs);
          lastUserTs = null;
        }
      } catch { }
    }
    
    const avgResponseTime = responseTimes.length > 0 
      ? Math.round(responseTimes.reduce((a, b) => a + b, 0) / responseTimes.length)
      : 0;
    
    res.json({
      totalTokens, messageCount,
      firstMessage: firstTs ? { timestamp: new Date(firstTs).toISOString(), preview: firstMessage } : null,
      lastMessage: lastTs ? { timestamp: new Date(lastTs).toISOString(), preview: lastMessage } : null,
      avgResponseTimeMs: avgResponseTime,
      avgResponseTimeSec: (avgResponseTime / 1000).toFixed(1),
      agentId, sessionKey,
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ========== DEPARTMENT RECENT MESSAGES ==========
app.get('/api/departments/:name/recent', authMiddleware, (req, res) => {
  try {
    const deptName = decodeURIComponent(req.params.name);
    const limit = Math.min(parseInt(req.query.limit) || 5, 20);
    
    // Find agent ID from department name
    let agentId = null;
    for (const [id, name] of Object.entries(AGENT_DEPT_MAP)) {
      if (name === deptName || id === deptName) { agentId = id; break; }
    }
    if (!agentId) return res.json({ messages: [], error: 'Department not found' });
    
    const sessionsPath = join(AGENTS_DIR, agentId, 'sessions', 'sessions.json');
    if (!existsSync(sessionsPath)) return res.json({ messages: [] });
    
    const sessionsData = JSON.parse(readFileSync(sessionsPath, 'utf-8'));
    
    // Find the most recently updated session
    let bestSession = null, bestTime = 0;
    for (const [, sess] of Object.entries(sessionsData)) {
      if ((sess.updatedAt || 0) > bestTime && sess.sessionFile) {
        bestTime = sess.updatedAt;
        bestSession = sess;
      }
    }
    
    if (!bestSession?.sessionFile || !existsSync(bestSession.sessionFile)) return res.json({ messages: [] });

    if (!isValidSessionPath(bestSession.sessionFile)) {
      return res.status(403).json({ error: 'Invalid session file path' });
    }

    // Guard against oversized files to prevent OOM (consistent with other endpoints)
    const fileSize = statSync(bestSession.sessionFile).size;
    if (fileSize > 50 * 1024 * 1024) {
      return res.status(413).json({ error: 'Session file too large', messages: [] });
    }
    
    // For files > 10MB, only read the tail (last 2MB) for recent messages
    let content;
    if (fileSize > 10 * 1024 * 1024) {
      const TAIL_READ = 2 * 1024 * 1024;
      const fd = openSync(bestSession.sessionFile, 'r');
      const buf = Buffer.alloc(TAIL_READ);
      readSync(fd, buf, 0, TAIL_READ, fileSize - TAIL_READ);
      closeSync(fd);
      const raw = buf.toString('utf-8');
      content = raw.substring(raw.indexOf('\n') + 1);
    } else {
      content = readFileSync(bestSession.sessionFile, 'utf-8');
    }
    const lines = content.split('\n').filter(l => l.trim());
    const messages = [];
    
    // Read from the end for recent messages
    for (let i = lines.length - 1; i >= 0 && messages.length < limit * 2; i--) {
      try {
        const entry = JSON.parse(lines[i]);
        if (entry.type === 'message' && entry.message) {
          const c = entry.message.content;
          let text = typeof c === 'string' ? c : Array.isArray(c) ? c.map(x => x.text || '').join('') : '';
          if (text.trim()) {
            messages.unshift({
              id: entry.id,
              role: entry.message.role,
              content: text.substring(0, 300),
              timestamp: entry.timestamp || entry.message.timestamp,
            });
          }
        }
      } catch { }
    }
    
    res.json({ messages: messages.slice(-limit), department: deptName, agentId });
  } catch (err) {
    res.status(500).json({ error: err.message, messages: [] });
  }
});

// Gateway config (read-only, masks secrets)
app.get('/api/config', authMiddleware, (req, res) => {
  try {
    const config = getOpenclawConfig();
    if (!config) return res.json({ config: null, error: 'Config not found' });
    
    // Deep clone and mask sensitive fields
    const masked = JSON.parse(JSON.stringify(config));
    const maskSecrets = (obj, depth = 0) => {
      if (!obj || typeof obj !== 'object' || depth > 10) return;
      for (const key of Object.keys(obj)) {
        if (/token|secret|key|password|apiKey/i.test(key) && typeof obj[key] === 'string') {
          // SEC-18: 完全脱敏，不保留任何前缀（Discord Token 前缀含 Bot ID）
          obj[key] = `[REDACTED ${obj[key].length} chars]`;
        } else if (typeof obj[key] === 'object') {
          maskSecrets(obj[key], depth + 1);
        }
      }
    };
    maskSecrets(masked);
    
    res.json({ config: masked });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// 重启 Gateway（杀掉主进程，Docker restart policy 会自动重启容器）
app.post('/api/gateway/restart', authMiddleware, async (req, res) => {
  console.log('[AUDIT] Gateway restart requested');
  // 检测是否在容器内运行
  const isContainer = existsSync('/.dockerenv') || existsSync('/run/.containerenv');
  res.json({ success: true, message: 'Gateway 正在重启...' });
  setTimeout(() => {
    try {
      if (isContainer) {
        // 容器内：杀 PID 1，Docker restart policy 自动重启
        process.kill(1, 'SIGTERM');
      } else {
        // 非容器：杀 gateway 进程
        const { execSync } = require('child_process');
        execSync('pkill -f "openclaw gateway" || pkill -f "clawdbot gateway" || true');
      }
    } catch (e) {
      console.error('[RESTART] Failed:', e.message);
    }
  }, 500);
});

app.get('/api/notion', authMiddleware, (req, res) => {
  const NOTION_TOKEN = process.env.NOTION_TOKEN;
  res.json({
    status: NOTION_TOKEN ? 'configured' : 'not_configured',
    configured: !!NOTION_TOKEN,
    lastSync: null,
    pagesLinked: 0,
    lastError: NOTION_TOKEN ? null : '未配置 NOTION_TOKEN 环境变量',
    _note: 'placeholder — 尚未对接真实 Notion 同步'
  });
});

app.post('/api/notion/sync', authMiddleware, (req, res) => {
  res.status(501).json({ success: false, message: 'Notion 同步功能尚未实现（placeholder）' });
});

app.get('/api/notion/data', authMiddleware, (req, res) => {
  const { type = 'daily' } = req.query;
  const config = getOpenclawConfig();
  
  if (type === 'daily') {
    const data = [];
    if (existsSync(AGENTS_DIR)) {
      const agentDirs = readdirSync(AGENTS_DIR);
      let id = 1;
      for (const agentId of agentDirs.slice(0, 7)) {
        const sessData = getAgentSessionData(agentId);
        const today = new Date().toISOString().split('T')[0];
        data.push({
          id: String(id++),
          title: `${today} ${AGENT_DEPT_MAP[agentId] || agentId}日报`,
          date: today,
          summary: `今日会话${sessData.sessions}次，消耗Token ${sessData.totalTokens.toLocaleString()}`,
          author: AGENT_DEPT_MAP[agentId] || agentId,
          status: 'published'
        });
      }
    }
    res.json({ type: 'daily', data, lastSync: new Date().toISOString() });
  } else if (type === 'finance') {
    const tokenStats = getTokenStats();
    const tokenPrice = tokenStats.tokenPrice || 0.3;
    const data = tokenStats.byDepartment.slice(0, 6).map((d, i) => {
      const expense = Math.floor(d.tokens * 0.001);
      return {
        id: String(i + 1),
        category: d.department,
        income: 0,
        expense: expense,
        period: new Date().toISOString().substring(0, 7),
        balance: -expense,
        tokenCost: (d.tokens / 1000000 * tokenPrice).toFixed(3),
      };
    });
    res.json({ type: 'finance', data, lastSync: new Date().toISOString() });
  } else if (type === 'personnel') {
    const depts = ['工部', '户部', '吏部', '刑部', '兵部', '礼部'];
    const data = depts.map((name, i) => ({
      id: String(i + 1),
      name: `${name}尚书`,
      title: name,
      department: name,
      status: 'active',
      tenure: `${new Date().getFullYear() - (depts.length - i - 1)}年任职`
    }));
    res.json({ type: 'personnel', data, lastSync: new Date().toISOString() });
  } else {
    res.json({ type, data: [], lastSync: new Date().toISOString() });
  }
});

const WEATHER_DEFAULT_LOCATION = process.env.WEATHER_LOCATION || 'Beijing';

app.get('/api/weather', authMiddleware, async (req, res) => {
  // SEC-01: 白名单过滤 location，用 fetch 替代 execAsync(curl) 防止命令注入
  // [M-14] 增加最大长度限制，防止超长输入
  const location = (req.query.location || WEATHER_DEFAULT_LOCATION)
    .replace(/[^a-zA-Z0-9\s,.\-\u4e00-\u9fff]/g, '')
    .substring(0, 100);
  
  try {
    const weatherResp = await fetch(`https://wttr.in/${encodeURIComponent(location)}?format=j1`, {
      signal: AbortSignal.timeout(5000),
      headers: { 'User-Agent': 'boluo-gui/1.0' }
    });
    if (!weatherResp.ok) throw new Error(`wttr.in returned ${weatherResp.status}`);
    
    const data = await weatherResp.json();
    const current = data.current_condition?.[0];
    
    if (current) {
      const temp = current.temp_C || 'N/A';
      const condition = current.weatherDesc?.[0]?.value || 'Unknown';
      const humidity = current.humidity || 'N/A';
      const wind = current.windspeedKmph || 'N/A';
      
      res.json({
        location,
        weather: `${condition} ${temp}°C`,
        details: {
          temp,
          condition,
          humidity: humidity + '%',
          wind: wind + 'km/h'
        },
        timestamp: new Date().toISOString()
      });
    } else {
      res.json({ location, weather: '数据解析失败', timestamp: new Date().toISOString() });
    }
  } catch (e) {
    res.json({ location, weather: '天气服务暂不可用', timestamp: new Date().toISOString() });
  }
});

// 获取平台连接状态
app.get('/api/platforms', authMiddleware, (req, res) => {
  try {
    // 直接读取 gateway 配置和 agent 数据（不再 curl 自己）
    const config = getOpenclawConfig();
    const channels = config?.channels || {};
    
    // 读取 agent 数据获取在线账号数和会话数
    let agentIds = [];
    if (existsSync(AGENTS_DIR)) {
      agentIds = readdirSync(AGENTS_DIR, { withFileTypes: true })
        .filter(d => d.isDirectory())
        .map(d => d.name);
    }
    
    let totalSessions = 0;
    for (const id of agentIds) {
      const sessData = getAgentSessionData(id);
      totalSessions += sessData.sessions;
    }

    // 从 gateway 配置读取真实平台状态
    const platformDefs = [
      { key: 'discord', name: 'Discord', icon: '💬' },
      { key: 'telegram', name: 'Telegram', icon: '✈️' },
      { key: 'signal', name: 'Signal', icon: '🔒' },
      { key: 'whatsapp', name: 'WhatsApp', icon: '📱' },
      { key: 'slack', name: 'Slack', icon: '💼' },
      { key: 'feishu', name: '飞书', icon: '🐦' },
      { key: 'lark', name: 'Lark/飞书', icon: '🐦' },
    ];
    
    // Check for feishu under both 'feishu' and 'lark' keys
    const feishuConf = channels['feishu'] || channels['lark'];
    
    const platforms = platformDefs
      .map(def => {
        // For feishu/lark, use the merged config
        let chConf;
        if (def.key === 'feishu' || def.key === 'lark') {
          chConf = feishuConf;
        } else {
          chConf = channels[def.key];
        }
        const isConfigured = !!chConf;
        // Count accounts: check if there's a token/credentials configured
        const accounts = isConfigured ? (Array.isArray(chConf.accounts) ? chConf.accounts.length : (typeof chConf.accounts === 'object' ? Object.keys(chConf.accounts).length : 1)) : 0;
        return {
          key: def.key,
          name: def.name,
          icon: def.icon,
          status: isConfigured ? 'connected' : 'disconnected',
          channels: 0,
          accounts: accounts,
        };
      })
      // Deduplicate feishu/lark: if both exist, keep the one that's configured, or just feishu
      .filter((p, i, arr) => {
        if (p.key === 'lark') {
          const feishu = arr.find(x => x.key === 'feishu');
          // If feishu is already connected, skip lark
          if (feishu && feishu.status === 'connected') return false;
        }
        return true;
      })
      .filter(p => p.status === 'connected' || ['Discord', 'Telegram', 'Signal', 'WhatsApp', '飞书'].includes(p.name));
    
    // Discord 特殊处理：从 guilds 和 agents 统计
    const discordPlatform = platforms.find(p => p.name === 'Discord');
    if (discordPlatform) {
      discordPlatform.accounts = agentIds.length;
      discordPlatform.channels = totalSessions;
    }
    
    res.json({ platforms, source: 'gateway' });
  } catch (e) {
    res.json({ 
      platforms: [
        { name: 'Discord', status: 'connected', channels: 0, accounts: 0 },
      ],
      source: 'error'
    });
  }
});

// SEC-02: Cron Job ID 白名单验证（防止命令注入）
function validateCronId(id) {
  return /^[a-zA-Z0-9_-]{1,64}$/.test(id);
}

// Helper: parse cron job list output
function parseCronJobs(data) {
  return (data.jobs || []).map((j) => {
    let scheduleStr = '';
    if (j.schedule) {
      const s = j.schedule;
      if (s.kind === 'cron') {
        scheduleStr = (s.expr) || '';
      } else if (s.kind === 'every') {
        const ms = s.everyMs;
        if (ms < 60000) scheduleStr = `every ${ms/1000}s`;
        else if (ms < 3600000) scheduleStr = `every ${ms/60000}m`;
        else scheduleStr = `every ${ms/3600000}h`;
      }
    }
    const state = j.state || {};
    return {
      id: j.id, name: j.name, schedule: scheduleStr, enabled: j.enabled,
      nextRun: state.nextRunAtMs ? new Date(state.nextRunAtMs).toISOString() : null,
      lastRun: state.lastRunAtMs ? new Date(state.lastRunAtMs).toISOString() : null,
      status: state.lastStatus || 'unknown', agent: j.agentId
    };
  });
}

app.get('/api/cron', authMiddleware, async (req, res) => {
  try {
    const { stdout } = await execAsync(`${CLI_CMD} cron list --json 2>/dev/null`, { encoding: 'utf-8', timeout: 5000 });
    const data = JSON.parse(stdout);
    res.json({ jobs: parseCronJobs(data), source: 'gateway' });
  } catch (e) {
    // Fallback to demo data
    const jobs = [
      { id: 'heartbeat-check', name: '心跳检查', schedule: '*/30 * * * *', enabled: true, nextRun: new Date(Date.now() + 30 * 60000).toISOString() },
      { id: 'notion-sync', name: 'Notion同步', schedule: '0 2 * * *', enabled: true, nextRun: new Date(Date.now() + 24 * 3600000).toISOString() },
      { id: 'data-backup', name: '数据备份', schedule: '0 3 * * *', enabled: false, nextRun: null }
    ];
    res.json({ jobs, source: 'demo' });
  }
});

app.post('/api/cron/run/:id', authMiddleware, async (req, res) => {
  const { id } = req.params;
  if (!validateCronId(id)) {
    return res.status(400).json({ success: false, message: 'Invalid cron job ID' });
  }
  try {
    await execAsync(`${CLI_CMD} cron run ${id}`, { encoding: 'utf-8', timeout: 10000 });
    res.json({ success: true, message: `任务 ${id} 已触发执行` });
  } catch (e) {
    res.json({ success: false, message: `任务 ${id} 执行失败: ${e.message}` });
  }
});

// Cron enable/disable
app.patch('/api/cron/jobs/:id', authMiddleware, async (req, res) => {
  try {
    const { id } = req.params;
    if (!validateCronId(id)) {
      return res.status(400).json({ success: false, message: 'Invalid cron job ID' });
    }
    const { enabled } = req.body;
    
    if (typeof enabled === 'boolean') {
      const action = enabled ? 'enable' : 'disable';
      // Try openclaw CLI
      try {
        await execAsync(`${CLI_CMD} cron ${action} ${id}`, { encoding: 'utf-8', timeout: 10000 });
        res.json({ success: true, message: `任务 ${id} 已${enabled ? '启用' : '禁用'}`, id, enabled });
      } catch (cliErr) {
        // Fallback: try to update config directly
        try {
          const config = getOpenclawConfig();
          if (config?.cron?.jobs) {
            const job = config.cron.jobs.find(j => j.id === id);
            if (job) {
              job.enabled = enabled;
              // Note: we don't write config here — change is NOT persisted
              res.json({ success: false, message: `CLI 操作失败，请手动修改配置文件`, requiresManualEdit: true });
            } else {
              res.status(404).json({ success: false, message: `任务 ${id} 不存在` });
            }
          } else {
            res.status(500).json({ success: false, message: `CLI失败: ${cliErr.message}` });
          }
        } catch {
          res.status(500).json({ success: false, message: `操作失败: ${cliErr.message}` });
        }
      }
    } else {
      res.status(400).json({ success: false, message: '需要 enabled 布尔值' });
    }
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// Alias: GET /api/cron/jobs → same handler as GET /api/cron
app.get('/api/cron/jobs', authMiddleware, async (req, res) => {
  try {
    const { stdout } = await execAsync(`${CLI_CMD} cron list --json 2>/dev/null`, { encoding: 'utf-8', timeout: 5000 });
    const data = JSON.parse(stdout);
    res.json({ jobs: parseCronJobs(data), source: 'gateway' });
  } catch (e) {
    res.json({ jobs: [], source: 'error', error: e.message });
  }
});

// Read real gateway logs from journalctl or log files (with time-based cache)
let _gatewayLogsCache = { data: null, ts: 0 };
const GATEWAY_LOGS_CACHE_TTL = 5000; // 5 seconds

async function readGatewayLogs(opts = {}) {
  const { level, search, limit = 200, since } = opts;
  // Use cached raw logs if within TTL (avoid re-reading files/journalctl every request)
  let logs;
  const now = Date.now();
  if (_gatewayLogsCache.data && (now - _gatewayLogsCache.ts) < GATEWAY_LOGS_CACHE_TTL && !since) {
    logs = _gatewayLogsCache.data;
  } else {
    logs = [];
    try {
      // Try journalctl for gateway service logs
      // Try both service names (openclaw-gateway / clawdbot-gateway)
      const svcName = existsSync('/etc/systemd/system/clawdbot-gateway.service')
        || existsSync(join(HOME, '.config/systemd/user/clawdbot-gateway.service'))
        ? 'clawdbot-gateway' : 'openclaw-gateway';
      let cmd = `journalctl -u ${svcName} --no-pager -n 200 --output=short-iso 2>/dev/null`;
      if (since && /^[\d\-T:+. ]+$/.test(since)) cmd += ` --since="${since}"`;
      
      let output = '';
      try {
        const result = await execAsync(cmd, { encoding: 'utf-8', timeout: 5000 });
        output = result.stdout;
      } catch {
        // Fallback: read from log files
        const logPaths = [
          join(HOME, '.openclaw/logs/gateway.log'),
          join(HOME, '.clawdbot/logs/gateway.log'),
          '/tmp/openclaw.log',
          '/tmp/boluo-gui.log',
        ];
        for (const p of logPaths) {
          if (existsSync(p)) {
            try {
              const stat = statSync(p);
              if (stat.size > 50 * 1024 * 1024) continue; // skip files > 50MB
              const content = readFileSync(p, 'utf-8');
              output = content.split('\n').slice(-200).join('\n');
              break;
            } catch { }
          }
        }
      }
      
      // Also read recent JSONL assistant messages as "log" entries
      const agentLogs = getRecentLogs(100);
      
      // Parse output lines
      const lines = output.split('\n').filter(l => l.trim());
      let id = 0;
      for (const line of lines) {
        const tsMatch = line.match(/^(\d{4}-\d{2}-\d{2}T[\d:]+[^\s]*)/);
        const lvlMatch = line.match(/\b(INFO|WARN|ERROR|DEBUG|FATAL)\b/i);
        const entry = {
          id: id++,
          timestamp: tsMatch ? tsMatch[1] : new Date().toISOString(),
          level: lvlMatch ? lvlMatch[1].toUpperCase() : 'INFO',
          message: line.substring(0, 500),
          source: 'gateway'
        };
        logs.push(entry);
      }
      
      // Merge agent logs
      for (const al of agentLogs) {
        logs.push({ id: id++, ...al });
      }
      
      // Sort by timestamp desc
      logs.sort((a, b) => b.timestamp.localeCompare(a.timestamp));
    } catch { }
    
    // Cache raw logs (only when not filtering by 'since')
    if (!since) {
      _gatewayLogsCache = { data: logs, ts: now };
    }
  }
  
  // Filter
  let filtered = logs;
  if (level && level !== 'ALL') {
    filtered = filtered.filter(l => l.level === level.toUpperCase());
  }
  if (search) {
    const s = search.toLowerCase();
    filtered = filtered.filter(l => l.message.toLowerCase().includes(s));
  }
  if (since) {
    const sinceTs = new Date(since).getTime();
    if (!isNaN(sinceTs)) filtered = filtered.filter(l => new Date(l.timestamp).getTime() >= sinceTs);
  }
  
  return filtered.slice(0, Math.min(parseInt(limit) || 200, 500));
}

app.get('/api/logs/list', authMiddleware, async (req, res) => {
  try {
    const { level, search, limit = 200, since } = req.query;
    const logs = await readGatewayLogs({ level, search, limit: parseInt(limit), since });
    res.json({ logs, total: logs.length });
  } catch (err) {
    res.status(500).json({ error: err.message, logs: [], total: 0 });
  }
});

// SSE Logs Stream — real-time log push
const sseClients = new Set();

app.get('/api/logs/stream', authMiddleware, (req, res) => {
  res.writeHead(200, {
    'Content-Type': 'text/event-stream',
    'Cache-Control': 'no-cache',
    'Connection': 'keep-alive',
    'X-Accel-Buffering': 'no',
  });
  
  res.write('event: connected\ndata: {"status":"connected"}\n\n');
  
  // Periodic keepalive comment to prevent proxy/LB timeout
  const keepalive = setInterval(() => {
    try { res.write(': keepalive\n\n'); } catch { clearInterval(keepalive); }
  }, 15000);
  
  const client = { res, level: req.query.level || null };
  sseClients.add(client);
  
  req.on('close', () => { clearInterval(keepalive); sseClients.delete(client); });
});

// Push log events to SSE clients (called from internal log sources)
function pushLogEvent(log) {
  for (const client of sseClients) {
    try {
      if (client.level && client.level !== 'ALL' && log.level !== client.level) continue;
      client.res.write(`event: log\ndata: ${JSON.stringify(log)}\n\n`);
    } catch { sseClients.delete(client); }
  }
}

// Poll for new logs every 10 seconds and push to SSE clients
let lastLogCheck = Date.now();
setInterval(async () => {
  if (sseClients.size === 0) return;
  try {
    const logs = await readGatewayLogs({ since: new Date(lastLogCheck).toISOString(), limit: 20 });
    for (const log of logs) {
      pushLogEvent(log);
    }
    lastLogCheck = Date.now();
  } catch { }
}, 10000);

app.get('/api/nodes', authMiddleware, async (req, res) => {
  // Try to get real node data from openclaw CLI
  try {
    const { stdout } = await execAsync(`${CLI_CMD} node list --json 2>/dev/null`, { encoding: 'utf-8', timeout: 5000 });
    const data = JSON.parse(stdout);
    const nodes = (data.nodes || []).map(n => ({
      id: n.id || n.name,
      name: n.name || n.id,
      status: n.online ? 'online' : 'offline',
      lastHeartbeat: n.lastSeenMs || Date.now(),
      os: n.os || 'unknown',
      uptime: n.uptimeSeconds || 0,
    }));
    res.json({ nodes, source: 'gateway' });
  } catch {
    // Fallback: at least report the current server
    const nodes = [
      {
        id: 'vibe-server',
        name: os.hostname(),
        status: 'online',
        lastHeartbeat: Date.now(),
        os: `${os.platform()} ${os.arch()}`,
        uptime: Math.floor(os.uptime()),
      }
    ];
    res.json({ nodes, source: 'local' });
  }
});

// Notion 数据库/页面查询路由
app.get('/api/notion/:id', authMiddleware, async (req, res) => {
  const { id } = req.params;
  const NOTION_TOKEN = process.env.NOTION_TOKEN;
  if (!NOTION_TOKEN) {
    return res.status(500).json({ success: false, error: '未配置 NOTION_TOKEN 环境变量。请设置: export NOTION_TOKEN=your_token' });
  }
  
  // Validate Notion ID format (UUID with or without dashes)
  if (!/^[a-f0-9-]{32,36}$/i.test(id)) {
    return res.status(400).json({ success: false, error: 'Invalid Notion ID format' });
  }
  
  try {
    // 先尝试查询数据库
    let response = await fetch(`https://api.notion.com/v1/databases/${id}/query`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${NOTION_TOKEN}`,
        'Notion-Version': '2022-06-28',
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ page_size: 10 })
    });
    
    let data = await response.json();
    
    // 如果返回的是 "not found" 或 "validation_error" 说明这不是数据库，尝试获取页面
    // 但如果是 "unauthorized" / "restricted_resource" 则直接返回错误（不做 fallback）
    if (data.object === 'error' && !['unauthorized', 'restricted_resource'].includes(data.code)) {
      response = await fetch(`https://api.notion.com/v1/pages/${id}`, {
        headers: {
          'Authorization': `Bearer ${NOTION_TOKEN}`,
          'Notion-Version': '2022-06-28'
        }
      });
      data = await response.json();
    }
    
    res.json({ success: true, data });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// 获取Discord频道最新消息
app.get('/api/channel-messages', authMiddleware, async (req, res) => {
  // channel 必填，不使用硬编码默认值
  const channelId = req.query.channel;
  if (!channelId) {
    return res.status(400).json({ error: 'channel query parameter is required', messages: [] });
  }
  // Validate channel ID is numeric (Discord snowflake)
  if (!/^\d{17,20}$/.test(channelId)) {
    return res.status(400).json({ error: 'Invalid channel ID format', messages: [] });
  }
  const limit = Math.min(parseInt(req.query.limit) || 15, 50);
  
  try {
    if (!existsSync(CONFIG_PATH)) {
      return res.status(400).json({ error: 'Config not found', messages: [] });
    }
    const config = JSON.parse(readFileSync(CONFIG_PATH, 'utf-8'));
    // 取第一个可用的 Discord account（不再硬编码 'main'）
    const accounts = config.channels?.discord?.accounts || {};
    const firstAccountKey = Object.keys(accounts)[0];
    const account = firstAccountKey ? accounts[firstAccountKey] : null;
    const token = account?.token;
    
    if (!token) {
      return res.status(400).json({ error: 'No Discord bot token configured (check channels.discord.accounts)' });
    }

    const r = await fetch(`https://discord.com/api/v10/channels/${channelId}/messages?limit=${limit}`, {
      headers: { 'Authorization': `Bot ${token}` }
    });
    
    if (r.ok) {
      const data = await r.json();
      // Map bot IDs to display names (reuse `accounts` from above)
      const botIdToName = {};
      for (const [agentId, acc] of Object.entries(accounts)) {
        if (acc.appId) botIdToName[acc.appId] = AGENT_DEPT_MAP[agentId] || acc.displayName || agentId;
      }

      const messages = data.reverse().map(msg => {
        const authorName = msg.author.bot 
          ? (botIdToName[msg.author.id] || msg.author.username)
          : msg.author.global_name || msg.author.username;
        
        // Generate color from author name
        let hash = 0;
        for (let i = 0; i < authorName.length; i++) hash = authorName.charCodeAt(i) + ((hash << 5) - hash);
        const hue = Math.abs(hash) % 360;
        
        return {
          id: msg.id,
          author: authorName,
          content: msg.content || (msg.embeds?.length ? '[嵌入内容]' : '[媒体]'),
          timestamp: new Date(msg.timestamp).toLocaleTimeString('zh-CN', { 
            timeZone: 'Asia/Shanghai', hour: '2-digit', minute: '2-digit' 
          }),
          avatarColor: `hsl(${hue}, 60%, 45%)`
        };
      });
      
      res.json({ messages });
    } else {
      const err = await r.text();
      res.status(r.status).json({ error: err, messages: [] });
    }
  } catch (err) {
    res.status(500).json({ error: err.message, messages: [] });
  }
});

// 发送指令 — 支持 Discord 直连 + agent call + message send 三级兜底
// SEC-31: /api/command rate limiter — 每分钟最多 10 次
const _cmdRateLimit = { count: 0, resetAt: 0 };

app.post('/api/command', authMiddleware, async (req, res) => {
  // Rate limit check
  const now = Date.now();
  if (now > _cmdRateLimit.resetAt) { _cmdRateLimit.count = 0; _cmdRateLimit.resetAt = now + 60000; }
  _cmdRateLimit.count++;
  if (_cmdRateLimit.count > 10) {
    return res.status(429).json({ error: 'Rate limit exceeded (max 10/min)' });
  }

  const { channel, message, botId } = req.body;
  if (!message || typeof message !== 'string') {
    return res.status(400).json({ error: 'Message is required and must be a string' });
  }
  // SEC-36: 限制消息长度，防止超长输入导致内存问题或命令行溢出
  if (message.length > 4000) {
    return res.status(400).json({ error: 'Message too long (max 4000 chars)' });
  }
  
  // SEC-33: 验证 botId 防止原型链污染
  const safeBotId = botId ? sanitizeAgentId(botId) : null;
  const usedBot = safeBotId || 'silijian';
  const agentId = resolveAgentId(usedBot); // 转换为实际 clawdbot agent id
  
  // SEC-34: 审计日志
  console.log(`[AUDIT] /api/command botId=${usedBot} agentId=${agentId} channel=${channel || 'none'} msgLen=${message.length}`);
  
  // 确定回复目标频道
  const targetChannel = channel && /^\d{17,20}$/.test(channel) ? channel : null;

  // 策略1（推荐）: 通过 clawdbot agent 发送指令给目标 agent
  // agent 会处理消息并通过 --deliver 把结果发到 Discord 频道
  try {
    const args = [
      'agent',
      '--agent', agentId,
      '--message', message,
      '--deliver',
      '--reply-channel', 'discord',
      '--json',
      '--timeout', '120'
    ];
    if (targetChannel) {
      args.push('--reply-to', `channel:${targetChannel}`);
      args.push('--reply-account', agentId);
    }
    
    console.log(`[COMMAND] Executing: ${CLI_CMD} ${args.join(' ')}`);
    const { stdout } = await execFileAsync(CLI_CMD, args, { encoding: 'utf-8', timeout: 130000 });
    console.log(`[COMMAND] Agent call result: ${stdout.substring(0, 300)}`);
    
    let result = {};
    try { result = JSON.parse(stdout); } catch {}
    return res.json({ 
      success: true, 
      sentAs: usedBot, 
      method: 'agent-deliver',
      reply: result.reply?.substring?.(0, 500) || stdout.trim().substring(0, 500)
    });
  } catch (agentErr) {
    console.error(`[COMMAND] Agent deliver failed: ${agentErr.message}`);
    
    // 策略2（兜底）: 通过 clawdbot message send 直接发消息到 Discord 频道
    if (targetChannel) {
      try {
        const { stdout } = await execFileAsync(
          CLI_CMD,
          ['message', 'send', '--channel', 'discord', '--account', agentId, 
           '--target', targetChannel, '--message', `📜 圣旨: ${message}`],
          { encoding: 'utf-8', timeout: 15000 }
        );
        console.log(`[COMMAND] Message send result: ${stdout.substring(0, 200)}`);
        return res.json({ success: true, sentAs: usedBot, method: 'message-send', detail: stdout.trim().substring(0, 500) });
      } catch (msgErr) {
        console.error(`[COMMAND] Message send failed: ${msgErr.message}`);
      }
    }
    
    // 策略3（最后兜底）: 用 Discord REST API 直接发
    if (targetChannel) {
      try {
        const config = getOpenclawConfig() || {};
        const accounts = config.channels?.discord?.accounts || {};
        const senderAccount = accounts[agentId] || accounts[usedBot] || accounts['main'] || accounts[Object.keys(accounts)[0]];
        if (senderAccount?.token) {
          const r = await fetch(`https://discord.com/api/v10/channels/${targetChannel}/messages`, {
            method: 'POST',
            headers: { 'Authorization': `Bot ${senderAccount.token}`, 'Content-Type': 'application/json' },
            body: JSON.stringify({ content: `📜 **圣旨** → ${AGENT_DEPT_MAP[usedBot] || usedBot}\n${message}` })
          });
          if (r.ok) {
            const data = await r.json();
            return res.json({ success: true, messageId: data.id, sentAs: usedBot, method: 'discord-rest' });
          }
        }
      } catch (e) {
        console.error(`[COMMAND] Discord REST failed: ${e.message}`);
      }
    }
    
    return res.status(500).json({ error: `All delivery methods failed`, sentAs: usedBot });
  }
});

// 获取bot列表（含状态）— 合并三个数据源：channels.accounts + agents.list + 文件系统
app.get('/api/bots', authMiddleware, (req, res) => {
  try {
    const config = getOpenclawConfig() || {};
    const channels = config.channels || {};
    const defaultModel = config.agents?.defaults?.model?.primary || config.defaultModel || 'claude-opus-4-6';
    const botMap = {};
    
    // 数据源1: channels.*.accounts（Discord/飞书等平台账号）
    for (const [platform, chConf] of Object.entries(channels)) {
      const accounts = chConf?.accounts || {};
      for (const [id, acc] of Object.entries(accounts)) {
        if (!botMap[id]) {
          botMap[id] = {
            id,
            name: AGENT_DEPT_MAP[id] || id,
            displayName: acc.displayName || AGENT_DEPT_MAP[id] || id,
            model: acc.model || defaultModel,
            hasToken: !!acc.token,
            platforms: [],
          };
        }
        const platName = platform === 'lark' ? 'feishu' : platform;
        if (!botMap[id].platforms.includes(platName)) {
          botMap[id].platforms.push(platName);
        }
        if (acc.token) botMap[id].hasToken = true;
      }
    }
    
    // 数据源2: agents.list（网关配置里的 agent 列表，支持数组和对象两种格式）
    const agentsList = config.agents?.list;
    if (agentsList) {
      const entries = Array.isArray(agentsList)
        ? agentsList.map(a => [a.id, a])
        : Object.entries(agentsList);
      for (const [id, agentConf] of entries) {
        if (!id) continue;
        if (!botMap[id]) {
          botMap[id] = {
            id,
            name: AGENT_DEPT_MAP[id] || id,
            displayName: agentConf.displayName || AGENT_DEPT_MAP[id] || id,
            model: agentConf.model?.primary || defaultModel,
            hasToken: true,  // agent 在配置里就算有效
            platforms: [],
          };
        }
        // 补充 model 信息
        if (agentConf.model?.primary && botMap[id].model === defaultModel) {
          botMap[id].model = agentConf.model.primary;
        }
      }
    }
    
    // 数据源3: 文件系统 ~/.openclaw/agents/（已有会话的 agent）
    if (existsSync(AGENTS_DIR)) {
      const agentDirs = readdirSync(AGENTS_DIR, { withFileTypes: true })
        .filter(d => d.isDirectory())
        .map(d => d.name);
      for (const id of agentDirs) {
        if (!botMap[id]) {
          const sessData = getAgentSessionData(id);
          botMap[id] = {
            id,
            name: AGENT_DEPT_MAP[id] || id,
            displayName: AGENT_DEPT_MAP[id] || id,
            model: sessData.model || defaultModel,
            hasToken: true,  // 有会话数据说明 agent 已运行过
            platforms: detectAgentPlatforms(id),
          };
        }
      }
    }
    
    const bots = Object.values(botMap);
    res.json({ bots });
  } catch (err) {
    res.status(500).json({ error: err.message, bots: [] });
  }
});

// 天气城市 API (Open-Meteo, 免费无需key)
// 可通过环境变量 WEATHER_CITIES 自定义，JSON 格式：
// export WEATHER_CITIES='[{"name":"北京","lat":39.90,"lon":116.40,"tz":"Asia/Shanghai"}]'
const DEFAULT_WEATHER_CITIES = [
  { name: '北京', lat: 39.90, lon: 116.40, tz: 'Asia/Shanghai' },
  { name: '上海', lat: 31.23, lon: 121.47, tz: 'Asia/Shanghai' },
  { name: '广州', lat: 23.13, lon: 113.26, tz: 'Asia/Shanghai' },
];
let WEATHER_CITIES = DEFAULT_WEATHER_CITIES;
try {
  if (process.env.WEATHER_CITIES) {
    const parsed = JSON.parse(process.env.WEATHER_CITIES);
    if (Array.isArray(parsed) && parsed.length > 0) WEATHER_CITIES = parsed;
  }
} catch (e) {
  console.warn('[WARN] WEATHER_CITIES 环境变量 JSON 解析失败，使用默认城市');
}

let weatherCache = { data: null, ts: 0 };

app.get('/api/weather/cities', authMiddleware, async (req, res) => {
  if (weatherCache.data && Date.now() - weatherCache.ts < 600000) {
    return res.json(weatherCache.data);
  }
  try {
    const results = await Promise.all(
      WEATHER_CITIES.map(async (city) => {
        try {
          const url = `https://api.open-meteo.com/v1/forecast?latitude=${city.lat}&longitude=${city.lon}&current=temperature_2m,weather_code,relative_humidity_2m,wind_speed_10m,apparent_temperature`;
          const r = await fetch(url, { signal: AbortSignal.timeout(5000) });
          const d = await r.json();
          const cur = d.current || {};
          return {
            name: city.name, tz: city.tz,
            temp: Math.round(cur.temperature_2m ?? 0).toString(),
            feelsLike: Math.round(cur.apparent_temperature ?? 0).toString(),
            humidity: (cur.relative_humidity_2m ?? '?').toString(),
            windSpeed: Math.round(cur.wind_speed_10m ?? 0).toString(),
            desc: wmoDesc(cur.weather_code),
            icon: wmoEmoji(cur.weather_code),
          };
        } catch {
          return { name: city.name, tz: city.tz, temp: '?', desc: '获取失败', icon: '❓' };
        }
      })
    );
    weatherCache = { data: { cities: results }, ts: Date.now() };
    res.json({ cities: results });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

function wmoEmoji(c) {
  if (c === 0) return '☀️'; if (c === 1) return '🌤️'; if (c === 2) return '⛅'; if (c === 3) return '☁️';
  if (c >= 45 && c <= 48) return '🌫️';
  if (c >= 51 && c <= 57) return '🌦️'; if (c >= 61 && c <= 67) return '🌧️';
  if (c >= 71 && c <= 77) return '🌨️'; if (c >= 80 && c <= 82) return '🌧️';
  if (c >= 85 && c <= 86) return '🌨️'; if (c >= 95 && c <= 99) return '⛈️';
  return '🌤️';
}
function wmoDesc(c) {
  if (c === 0) return '晴'; if (c === 1) return '大致晴'; if (c === 2) return '多云'; if (c === 3) return '阴';
  if (c >= 45 && c <= 48) return '雾';
  if (c >= 51 && c <= 55) return '毛毛雨'; if (c === 56 || c === 57) return '冻毛毛雨';
  if (c >= 61 && c <= 65) return '雨'; if (c === 66 || c === 67) return '冻雨';
  if (c >= 71 && c <= 75) return '雪'; if (c === 77) return '雪粒';
  if (c >= 80 && c <= 82) return '阵雨'; if (c >= 85 && c <= 86) return '阵雪';
  if (c === 95) return '雷暴'; if (c >= 96 && c <= 99) return '冰雹雷暴';
  return '未知';
}

// IP位置追踪
const ipLocations = {};

app.get('/api/location/track', authMiddleware, async (req, res) => {
  const clientIp = req.headers['cf-connecting-ip'] || req.headers['x-forwarded-for']?.split(',')[0]?.trim() || req.ip;
  const role = (req.query.role || 'unknown').replace(/[^a-zA-Z0-9_-]/g, '').substring(0, 32);
  
  try {
    const r = await fetch(`http://ip-api.com/json/${clientIp}?lang=zh-CN&fields=status,country,regionName,city,lat,lon,query`, { signal: AbortSignal.timeout(5000) });
    const geo = await r.json();
    if (geo.status === 'success') {
      ipLocations[role] = {
        ip: geo.query,
        city: geo.city,
        region: geo.regionName,
        country: geo.country,
        lat: geo.lat,
        lon: geo.lon,
        lastSeen: Date.now()
      };
    } else {
      // 如果是内网IP，记录但标注
      ipLocations[role] = { ip: clientIp, city: '内网', region: '', country: '', lastSeen: Date.now() };
    }
  } catch {
    ipLocations[role] = { ip: clientIp, city: '未知', region: '', country: '', lastSeen: Date.now() };
  }

  // 限制条目数防止内存泄漏
  const keys = Object.keys(ipLocations);
  if (keys.length > 100) {
    delete ipLocations[keys[0]];
  }

  res.json({ locations: ipLocations });
});

app.get('/api/location/all', authMiddleware, (req, res) => {
  res.json({ locations: ipLocations });
});

// ========== SYSTEM METRICS RING BUFFER ==========
const METRICS_MAX = 100;
const metricsBuffer = [];

function recordMetrics() {
  const cpuLoad = os.loadavg();
  const freeMem = os.freemem();
  const totalMem = os.totalmem();
  metricsBuffer.push({
    timestamp: new Date().toISOString(),
    cpu1m: parseFloat(cpuLoad[0].toFixed(2)),
    cpu5m: parseFloat(cpuLoad[1].toFixed(2)),
    cpu15m: parseFloat(cpuLoad[2].toFixed(2)),
    memUsedPct: parseFloat(((1 - freeMem / totalMem) * 100).toFixed(1)),
    memUsedGB: parseFloat(((totalMem - freeMem) / 1024 / 1024 / 1024).toFixed(2)),
  });
  if (metricsBuffer.length > METRICS_MAX) metricsBuffer.shift();
}

// Record every 30 seconds
setInterval(recordMetrics, 30000);
recordMetrics(); // initial

// ==================== SKILLS MANAGEMENT ====================

// Derive workspace skills dir from config
function getSkillsDirs() {
  const config = getOpenclawConfig();
  const workspace = config?.workspace || join(HOME, 'clawd');
  const localSkillsDir = join(workspace, 'skills');
  // Built-in skills shipped with the package
  const builtinSkillsDir = '/usr/lib/node_modules/openclaw/skills';
  // Alternative: openclaw package path
  const builtinAlt = '/usr/lib/node_modules/openclaw/skills';
  const builtinDir = existsSync(builtinSkillsDir) ? builtinSkillsDir : (existsSync(builtinAlt) ? builtinAlt : null);
  return { localSkillsDir, builtinDir, workspace };
}

function readSkillMeta(skillDir, name) {
  const info = { name, description: '', version: null, source: 'local', installed: false, hasSkillMd: false, files: 0 };

  // Read SKILL.md for description
  const skillMdPath = join(skillDir, 'SKILL.md');
  if (existsSync(skillMdPath)) {
    info.hasSkillMd = true;
    try {
      const content = readFileSync(skillMdPath, 'utf-8');
      // Try YAML frontmatter first (---\n...\n---)
      const fmMatch = content.match(/^---\n([\s\S]*?)\n---/);
      if (fmMatch) {
        const fmBlock = fmMatch[1];
        // Extract description from frontmatter
        const descMatch = fmBlock.match(/^description:\s*(.+)$/m);
        if (descMatch) info.description = descMatch[1].trim().substring(0, 200);
        // Extract name from frontmatter
        const nameMatch = fmBlock.match(/^name:\s*(.+)$/m);
        if (nameMatch) info.displayName = nameMatch[1].trim();
        // Extract emoji
        const metaMatch = fmBlock.match(/"emoji"\s*:\s*"([^"]+)"/);
        if (metaMatch) info.emoji = metaMatch[1];
      }
      // Fallback: first non-heading, non-frontmatter line
      if (!info.description) {
        const bodyStart = fmMatch ? content.indexOf('---', 4) + 3 : 0;
        const body = content.substring(bodyStart);
        const lines = body.split('\n').filter(l => l.trim() && !l.startsWith('#') && !l.startsWith('---'));
        if (lines.length > 0) {
          info.description = lines[0].replace(/^[-*>\s]+/, '').trim().substring(0, 200);
        }
      }
    } catch {}
  }

  // Read _meta.json for version/publisher info (clawdhub installed skills)
  const metaPath = join(skillDir, '_meta.json');
  if (existsSync(metaPath)) {
    try {
      const meta = JSON.parse(readFileSync(metaPath, 'utf-8'));
      info.version = meta.version || null;
      info.slug = meta.slug || name;
      info.ownerId = meta.ownerId || null;
      info.publishedAt = meta.publishedAt || null;
    } catch {}
  }

  // Read .clawdhub/origin.json for install info
  const originPath = join(skillDir, '.clawdhub', 'origin.json');
  if (existsSync(originPath)) {
    try {
      const origin = JSON.parse(readFileSync(originPath, 'utf-8'));
      info.source = 'clawdhub';
      info.installedVersion = origin.installedVersion || null;
      info.installedAt = origin.installedAt || null;
      info.registry = origin.registry || null;
      info.installed = true;
    } catch {}
  }

  // Count files
  try {
    info.files = readdirSync(skillDir).filter(f => !f.startsWith('.')).length;
  } catch {}

  return info;
}

// GET /api/skills — list all skills (local + builtin)
app.get('/api/skills', authMiddleware, (req, res) => {
  try {
    const { localSkillsDir, builtinDir } = getSkillsDirs();
    const skills = [];
    const seen = new Set();

    // 1. Local/workspace skills (higher priority)
    if (existsSync(localSkillsDir)) {
      for (const name of readdirSync(localSkillsDir)) {
        const fullPath = join(localSkillsDir, name);
        if (!statSync(fullPath).isDirectory() || name.startsWith('.')) continue;
        const info = readSkillMeta(fullPath, name);
        info.location = 'workspace';
        info.path = fullPath;
        skills.push(info);
        seen.add(name);
      }
    }

    // 2. Built-in skills (only if not overridden by local)
    if (builtinDir && existsSync(builtinDir)) {
      for (const name of readdirSync(builtinDir)) {
        if (seen.has(name)) continue;
        const fullPath = join(builtinDir, name);
        if (!statSync(fullPath).isDirectory() || name.startsWith('.')) continue;
        const info = readSkillMeta(fullPath, name);
        info.location = 'builtin';
        info.path = fullPath;
        skills.push(info);
        seen.add(name);
      }
    }

    // Sort: workspace first, then alphabetical
    skills.sort((a, b) => {
      if (a.location !== b.location) return a.location === 'workspace' ? -1 : 1;
      return a.name.localeCompare(b.name);
    });

    res.json({
      skills,
      total: skills.length,
      workspace: skills.filter(s => s.location === 'workspace').length,
      builtin: skills.filter(s => s.location === 'builtin').length,
      clawdhub: skills.filter(s => s.source === 'clawdhub').length,
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET /api/skills/:name — get single skill detail
app.get('/api/skills/:name', authMiddleware, (req, res) => {
  try {
    const name = req.params.name;
    if (!name || /[\/\\]/.test(name) || name.includes('..')) {
      return res.status(400).json({ error: 'Invalid skill name' });
    }

    const { localSkillsDir, builtinDir } = getSkillsDirs();
    let skillPath = join(localSkillsDir, name);
    let location = 'workspace';

    if (!existsSync(skillPath) && builtinDir) {
      skillPath = join(builtinDir, name);
      location = 'builtin';
    }

    if (!existsSync(skillPath)) {
      return res.status(404).json({ error: 'Skill not found' });
    }

    const info = readSkillMeta(skillPath, name);
    info.location = location;
    info.path = skillPath;

    // Read full SKILL.md content
    const skillMdPath = join(skillPath, 'SKILL.md');
    if (existsSync(skillMdPath)) {
      try {
        info.skillMdContent = readFileSync(skillMdPath, 'utf-8');
      } catch {}
    }

    // List all files
    try {
      info.fileList = readdirSync(skillPath).filter(f => !f.startsWith('.'));
    } catch { info.fileList = []; }

    res.json(info);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST /api/skills/search — search clawdhub registry
app.post('/api/skills/search', authMiddleware, async (req, res) => {
  try {
    const { query } = req.body;
    if (!query) return res.status(400).json({ error: 'Query required' });
    const safeQuery = query.replace(/[^a-zA-Z0-9_ -]/g, '');
    const { stdout, stderr } = await execAsync(`clawdhub search "${safeQuery}" --no-input 2>&1`, {
      encoding: 'utf-8', timeout: 15000, cwd: getSkillsDirs().workspace,
    });
    // Parse clawdhub search output
    const results = [];
    const lines = stdout.split('\n');
    for (const line of lines) {
      // Format: slug  version  description (or similar)
      const match = line.match(/^(\S+)\s+(\S+)\s+(.*)$/);
      if (match && !match[1].startsWith('─') && !match[1].startsWith('Usage')) {
        results.push({ slug: match[1], version: match[2], description: match[3].trim() });
      }
    }
    res.json({ results, raw: stdout });
  } catch (err) {
    res.status(500).json({ error: err.message, raw: err.stderr || '' });
  }
});

// POST /api/skills/install — install from clawdhub
app.post('/api/skills/install', authMiddleware, async (req, res) => {
  try {
    const { slug } = req.body;
    if (!slug || /[^a-zA-Z0-9_-]/.test(slug)) return res.status(400).json({ error: 'Invalid slug' });
    const { workspace } = getSkillsDirs();
    const { stdout, stderr } = await execAsync(
      `clawdhub install ${slug} --no-input --workdir "${workspace}" 2>&1`,
      { encoding: 'utf-8', timeout: 30000, cwd: workspace }
    );
    res.json({ success: true, output: stdout, slug });
  } catch (err) {
    res.status(500).json({ error: err.message, output: err.stdout || err.stderr || '' });
  }
});

// POST /api/skills/update — update a skill (or all)
app.post('/api/skills/update', authMiddleware, async (req, res) => {
  try {
    const { slug } = req.body; // if empty, update all
    if (slug && /[^a-zA-Z0-9_-]/.test(slug)) return res.status(400).json({ error: 'Invalid slug' });
    const { workspace } = getSkillsDirs();
    const cmd = slug
      ? `clawdhub update ${slug} --no-input --workdir "${workspace}" 2>&1`
      : `clawdhub update --no-input --workdir "${workspace}" 2>&1`;
    const { stdout } = await execAsync(cmd, { encoding: 'utf-8', timeout: 60000, cwd: workspace });
    res.json({ success: true, output: stdout, slug: slug || 'all' });
  } catch (err) {
    res.status(500).json({ error: err.message, output: err.stdout || err.stderr || '' });
  }
});

// POST /api/skills/explore — browse latest skills from registry
app.post('/api/skills/explore', authMiddleware, async (req, res) => {
  try {
    const { workspace } = getSkillsDirs();
    const { stdout } = await execAsync(`clawdhub explore --no-input 2>&1`, {
      encoding: 'utf-8', timeout: 15000, cwd: workspace,
    });
    // Parse explore output
    const results = [];
    const lines = stdout.split('\n');
    for (const line of lines) {
      const match = line.match(/^(\S+)\s+(\S+)\s+(.*)$/);
      if (match && !match[1].startsWith('─') && !match[1].startsWith('Usage') && !match[1].startsWith('Slug')) {
        results.push({ slug: match[1], version: match[2], description: match[3].trim() });
      }
    }
    res.json({ results, raw: stdout });
  } catch (err) {
    res.status(500).json({ error: err.message, raw: err.stderr || '' });
  }
});

// ==================== END SKILLS MANAGEMENT ====================

app.get('/api/system/metrics', authMiddleware, (req, res) => {
  try {
    res.json({ metrics: metricsBuffer, count: metricsBuffer.length, maxSize: METRICS_MAX });
  } catch (err) {
    res.status(500).json({ error: err.message, metrics: [] });
  }
});

const distPath = join(__dirname, '../dist');
app.use(express.static(distPath));

app.get('*', (req, res) => {
  // API 路径返回 JSON 404，不返回 HTML
  if (req.path.startsWith('/api/')) {
    return res.status(404).json({ error: 'API endpoint not found' });
  }
  const indexPath = join(distPath, 'index.html');
  if (existsSync(indexPath)) {
    res.sendFile(indexPath);
  } else {
    res.status(404).json({ error: 'Frontend not built' });
  }
});

// Global error handler — prevents crash on unhandled route errors
app.use((err, req, res, _next) => {
  console.error(`[ERROR] ${req.method} ${req.url}:`, err.message);
  res.status(500).json({ error: 'Internal server error', message: err.message });
});

// Graceful shutdown: close server and WS connections
process.on('SIGTERM', () => {
  console.log('[SHUTDOWN] SIGTERM received, shutting down gracefully');
  server.close();
  wss.close();
  process.exit(0);
});
process.on('SIGINT', () => {
  console.log('[SHUTDOWN] SIGINT received, shutting down gracefully');
  server.close();
  wss.close();
  process.exit(0);
});

// Node.js 官方建议：uncaughtException 后进程状态不确定，应退出
// 配合 systemd/PM2 自动重启
process.on('uncaughtException', (err) => {
  console.error('[FATAL] Uncaught exception — process will exit:', err.message);
  console.error(err.stack);
  // 给日志一点时间写完，然后退出
  setTimeout(() => process.exit(1), 1000);
});
process.on('unhandledRejection', (reason) => {
  console.error('[WARN] Unhandled rejection:', reason);
  // unhandledRejection 不一定需要退出，但记录下来
});

// ========== HTTP SERVER + WEBSOCKET ==========
const server = http.createServer(app);

const wss = new WebSocketServer({ server, path: '/ws' });

wss.on('connection', (ws, req) => {
  // Auth check via query param or header
  const url = new URL(req.url, `http://localhost:${PORT}`);
  const token = url.searchParams.get('token') || req.headers['authorization']?.replace('Bearer ', '');
  if (token !== AUTH_TOKEN) {
    ws.close(4001, 'Unauthorized');
    return;
  }
  
  console.log(`[WS] Client connected (total: ${wss.clients.size})`);
  
  // Send initial data
  try {
    const summary = getCached('dashboard_summary');
    if (summary) ws.send(JSON.stringify({ type: 'dashboard', data: summary }));
  } catch { }
  
  ws.on('close', () => {
    console.log(`[WS] Client disconnected (total: ${wss.clients.size})`);
  });
  
  ws.on('error', (err) => {
    console.error('[WS] Error:', err.message);
  });
});

// Broadcast dashboard summary every 30 seconds
setInterval(async () => {
  if (wss.clients.size === 0) return;
  
  try {
    // Invalidate stale session and dashboard caches so next build uses fresh data
    delete cache['sessions'];
    delete cache['dashboard_summary'];
    
    // Build fresh data using the status endpoint's logic
    const sessData = await buildSessionsData();
    const sessions = sessData.sessions;
    let totalInput = 0, totalOutput = 0;
    const deptActivity = {};
    for (const s of sessions) {
      totalInput += s.inputTokens || 0;
      totalOutput += s.outputTokens || 0;
      if (!deptActivity[s.agentName] || s.updatedAt > deptActivity[s.agentName].updatedAt) {
        deptActivity[s.agentName] = { name: s.agentName, updatedAt: s.updatedAt, messages: s.messageCount, tokens: s.totalTokens };
      }
    }
    const deptRanking = Object.values(deptActivity).sort((a, b) => b.updatedAt - a.updatedAt).slice(0, 10);
    const cpuLoad = os.loadavg();
    const freeMem = os.freemem();
    const totalMem = os.totalmem();
    
    const payload = JSON.stringify({
      type: 'dashboard',
      data: {
        totalInput, totalOutput, totalTokens: totalInput + totalOutput,
        totalSessions: sessData.total, activeSessions: sessData.active,
        deptRanking,
        systemLoad: {
          cpu1m: cpuLoad[0].toFixed(2), cpu5m: cpuLoad[1].toFixed(2), cpu15m: cpuLoad[2].toFixed(2),
          memUsedPct: ((1 - freeMem / totalMem) * 100).toFixed(1),
        },
        lastUpdated: new Date().toISOString(),
      }
    });
    
    for (const client of wss.clients) {
      if (client.readyState === 1) { // OPEN
        try { client.send(payload); } catch { }
      }
    }
  } catch (err) {
    console.error('[WS] Broadcast error:', err.message);
  }
}, 30000);

// SEC-30: Docker 内默认 0.0.0.0（否则容器外无法访问），非 Docker 默认 localhost
const IS_DOCKER = (() => {
  try {
    if (existsSync('/.dockerenv')) return true;
    if (existsSync('/proc/1/cgroup')) return readFileSync('/proc/1/cgroup', 'utf8').includes('docker');
  } catch {}
  return false;
})();
const BIND_HOST = process.env.BOLUO_BIND_HOST || (IS_DOCKER ? '0.0.0.0' : '127.0.0.1');
server.listen(PORT, BIND_HOST, () => {
  console.log(`Boluo GUI running on http://${BIND_HOST}:${PORT} (HTTP + WebSocket)`);
  if (BIND_HOST === '0.0.0.0') {
    console.warn('⚠️  GUI 监听所有网口，确保已配置防火墙或反向代理');
  }
});
