import express from 'express';
import cors from 'cors';
import { readFileSync, readdirSync, existsSync, statSync, createReadStream } from 'fs';
import { readFile } from 'fs/promises';
import { join } from 'path';
import { fileURLToPath } from 'url';
import { dirname } from 'path';
import readline from 'readline';
import os from 'os';
import http from 'http';
import { createRequire } from 'module';
const require = createRequire(import.meta.url);
import { WebSocketServer } from 'ws';
import { exec as _exec } from 'child_process';
import { promisify } from 'util';
const execAsync = promisify(_exec);

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// 检测可用的 CLI 命令（openclaw 优先，clawdbot 兜底）
let CLI_CMD = 'openclaw';
try {
  const { stdout } = await execAsync('which openclaw 2>/dev/null || which clawdbot 2>/dev/null', { encoding: 'utf-8', timeout: 3000 });
  CLI_CMD = stdout.trim().includes('openclaw') ? 'openclaw' : 'clawdbot';
} catch { CLI_CMD = 'clawdbot'; }

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
  'hanlinyuan': '翰林院', 'taiyiyuan': '太医院', 'guozijian': '国子监',
  'yushanfang': '御膳房'
};

const HOME = process.env.HOME || '/home/ubuntu';
// 兼容 openclaw 和 clawdbot 两种安装方式
const OPENCLAW_DIR = join(HOME, '.openclaw');
const CLAWDBOT_DIR = join(HOME, '.clawdbot');
const STATE_DIR = existsSync(OPENCLAW_DIR) ? OPENCLAW_DIR : CLAWDBOT_DIR;
const AGENTS_DIR = join(STATE_DIR, 'agents');
const CONFIG_PATH = existsSync(join(OPENCLAW_DIR, 'openclaw.json'))
  ? join(OPENCLAW_DIR, 'openclaw.json')
  : join(CLAWDBOT_DIR, 'clawdbot.json');

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

function getClawdbotConfig() {
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
                  timestamp: new Date(file.mtime).toLocaleString('zh-CN', { timeZone: 'Asia/Shanghai' }),
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
  const config = getClawdbotConfig();
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
  const config = getClawdbotConfig();
  const defaultModel = config?.agents?.defaults?.model?.primary || 'minimax/MiniMax-M2.5';

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

  // Measure real gateway ping
  let gatewayPing = -1;
  let gatewayStatus = 'unknown';
  try {
    const pingStart = Date.now();
    const pingRes = await fetch('http://localhost:18789/health', { signal: AbortSignal.timeout(3000) });
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
  const deptMap = {
    'silijian': '司礼监', 'main': '司礼监',
    'gongbu': '工部', 'hubu': '户部', 'libu': '礼部',
    'xingbu': '刑部', 'bingbu': '兵部', 'libu2': '吏部',
    'neige': '内阁', 'duchayuan': '都察院', 'hanlinyuan': '翰林院'
  };

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

  const rawConfig = getClawdbotConfig();
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
            countSessionFile(session.sessionFile || '')
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
            if (bestFile) {
              const lines = readFileSync(bestFile, 'utf-8').split('\n').filter(l => l.trim());
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
    const agentId = sanitizeAgentId(parts[1]) || 'main';
    if (!sanitizeAgentId(agentId)) return res.status(400).json({ error: 'Invalid agent ID', timeline: [] });
    const sessionKey = parts.slice(2).join(':');
    
    const sessionsPath = join(AGENTS_DIR, agentId, 'sessions', 'sessions.json');
    if (!existsSync(sessionsPath)) return res.json({ timeline: [] });
    
    const sessionsData = JSON.parse(readFileSync(sessionsPath, 'utf-8'));
    const session = sessionsData[sessionKey];
    if (!session?.sessionFile || !existsSync(session.sessionFile)) return res.json({ timeline: [] });
    
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
    const agentId = sanitizeAgentId(parts[1]) || 'main';
    if (!sanitizeAgentId(agentId)) return res.status(400).json({ error: 'Invalid agent ID', messages: [], total: 0, page: 1, totalPages: 0 });
    const sessionKey = parts.slice(2).join(':');
    
    const sessionsPath = join(AGENTS_DIR, agentId, 'sessions', 'sessions.json');
    if (existsSync(sessionsPath)) {
      const sessionsData = JSON.parse(readFileSync(sessionsPath, 'utf-8'));
      const session = sessionsData[sessionKey];
      if (session?.sessionFile && existsSync(session.sessionFile)) {
        // Q2: 大文件保护 — 超过 10MB 的 JSONL 只读最后 2MB（避免 OOM）
        const fileStat = statSync(session.sessionFile);
        const MAX_FULL_READ = 10 * 1024 * 1024; // 10MB
        const TAIL_READ = 2 * 1024 * 1024; // 2MB
        let content;
        if (fileStat.size > MAX_FULL_READ && !search) {
          // 只读尾部，避免内存爆炸
          const fd = require('fs').openSync(session.sessionFile, 'r');
          const buf = Buffer.alloc(TAIL_READ);
          require('fs').readSync(fd, buf, 0, TAIL_READ, fileStat.size - TAIL_READ);
          require('fs').closeSync(fd);
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
    const agentId = sanitizeAgentId(parts[1]) || 'main';
    if (!sanitizeAgentId(agentId)) return res.status(400).json({ error: 'Invalid agent ID' });
    const sessionKey = parts.slice(2).join(':');
    
    const sessionsPath = join(AGENTS_DIR, agentId, 'sessions', 'sessions.json');
    if (!existsSync(sessionsPath)) return res.json({ error: 'Session not found' });
    
    const sessionsData = JSON.parse(readFileSync(sessionsPath, 'utf-8'));
    const session = sessionsData[sessionKey];
    if (!session?.sessionFile || !existsSync(session.sessionFile)) return res.json({ error: 'Session file not found' });
    
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
    
    const content = readFileSync(bestSession.sessionFile, 'utf-8');
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
    const config = getClawdbotConfig();
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
  const config = getClawdbotConfig();
  
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
      tenure: `${2024 + i}年任职`
    }));
    res.json({ type: 'personnel', data, lastSync: new Date().toISOString() });
  } else {
    res.json({ type, data: [], lastSync: new Date().toISOString() });
  }
});

const WEATHER_DEFAULT_LOCATION = process.env.WEATHER_LOCATION || 'Beijing';

app.get('/api/weather', authMiddleware, async (req, res) => {
  // SEC-01: 白名单过滤 location，用 fetch 替代 execAsync(curl) 防止命令注入
  const location = (req.query.location || WEATHER_DEFAULT_LOCATION)
    .replace(/[^a-zA-Z0-9\s,.\-\u4e00-\u9fff]/g, '');
  
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
    const config = getClawdbotConfig();
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
      { id: 'heartbeat-check', name: '心跳检查', schedule: '*/30 * * * *', enabled: true, nextRun: new Date().toISOString() },
      { id: 'notion-sync', name: 'Notion同步', schedule: '0 2 * * *', enabled: true, nextRun: new Date().toISOString() },
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
      // Try clawdbot CLI
      try {
        await execAsync(`${CLI_CMD} cron ${action} ${id}`, { encoding: 'utf-8', timeout: 10000 });
        res.json({ success: true, message: `任务 ${id} 已${enabled ? '启用' : '禁用'}`, id, enabled });
      } catch (cliErr) {
        // Fallback: try to update config directly
        try {
          const config = getClawdbotConfig();
          if (config?.cron?.jobs) {
            const job = config.cron.jobs.find(j => j.id === id);
            if (job) {
              job.enabled = enabled;
              // Note: we don't write config here — that requires gateway restart
              res.json({ success: true, message: `任务 ${id} 状态更新（需重启生效）`, id, enabled, pending: true });
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

function readGatewayLogs(opts = {}) {
  const { level, search, limit = 200, since } = opts;
  // Use cached raw logs if within TTL (avoid re-reading files/journalctl every request)
  let logs;
  const now = Date.now();
  if (_gatewayLogsCache.data && (now - _gatewayLogsCache.ts) < GATEWAY_LOGS_CACHE_TTL && !since) {
    logs = _gatewayLogsCache.data;
  } else {
    logs = [];
    try {
      // Try journalctl for gateway service logs (openclaw or clawdbot)
      const { execSync } = require('child_process');
      const svcName = CLI_CMD === 'openclaw' ? 'openclaw-gateway' : 'clawdbot-gateway';
      let cmd = `journalctl -u ${svcName} --no-pager -n 200 --output=short-iso 2>/dev/null`;
      if (since) cmd += ` --since="${since}"`;
      
      let output = '';
      try {
        output = execSync(cmd, { encoding: 'utf-8', timeout: 5000 });
      } catch {
        // Fallback: read from log files
        const logPaths = [
          join(HOME, '.openclaw/logs/gateway.log'),
          join(HOME, '.clawdbot/logs/gateway.log'),
          '/tmp/clawdbot.log',
          '/tmp/boluo-gui.log',
        ];
        for (const p of logPaths) {
          if (existsSync(p)) {
            try { output = readFileSync(p, 'utf-8').split('\n').slice(-200).join('\n'); break; } catch { }
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
  
  return filtered.slice(0, parseInt(limit) || 200);
}

app.get('/api/logs/list', authMiddleware, (req, res) => {
  try {
    const { level, search, limit = 200, since } = req.query;
    const logs = readGatewayLogs({ level, search, limit: parseInt(limit), since });
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
  
  const client = { res, level: req.query.level || null };
  sseClients.add(client);
  
  req.on('close', () => { sseClients.delete(client); });
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
setInterval(() => {
  if (sseClients.size === 0) return;
  try {
    const logs = readGatewayLogs({ since: new Date(lastLogCheck).toISOString(), limit: 20 });
    for (const log of logs) {
      pushLogEvent(log);
    }
    lastLogCheck = Date.now();
  } catch { }
}, 10000);

app.get('/api/nodes', authMiddleware, async (req, res) => {
  // Try to get real node data from clawdbot CLI
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
    
    // 如果返回错误说明是页面而非数据库，尝试获取页面
    if (data.object === 'error') {
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
      // Map bot IDs to display names
      const accounts = config.channels?.discord?.accounts || {};
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

// 发送指令到Discord频道
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
  // SEC-32: channel 必填，不使用硬编码默认值
  if (!channel) {
    return res.status(400).json({ error: 'Channel ID is required' });
  }
  const targetChannel = channel;
  // Validate channel ID is numeric (Discord snowflake)
  if (!/^\d{17,20}$/.test(targetChannel)) {
    return res.status(400).json({ error: 'Invalid channel ID format' });
  }
  
  // SEC-33: 验证 botId 防止原型链污染
  const safeBotId = botId ? sanitizeAgentId(botId) : null;
  
  // 读取bot token - 使用指定的botId发送
  try {
    if (!existsSync(CONFIG_PATH)) {
      return res.status(400).json({ error: 'Config not found' });
    }
    const config = JSON.parse(readFileSync(CONFIG_PATH, 'utf-8'));
    const accounts = config.channels?.discord?.accounts || {};
    // Try target bot first, fall back to first available account
    let account = safeBotId ? accounts[safeBotId] : null;
    let usedBot = safeBotId || 'unknown';
    if (!account?.token) {
      const firstKey = Object.keys(accounts)[0];
      account = firstKey ? accounts[firstKey] : null;
      usedBot = firstKey || 'none';
    }
    const token = account?.token;
    
    // SEC-34: 审计日志
    console.log(`[AUDIT] /api/command botId=${usedBot} channel=${targetChannel} msgLen=${message.length}`);
    
    if (!token) {
      return res.status(400).json({ error: `Bot ${botId} token not found` });
    }

    const r = await fetch(`https://discord.com/api/v10/channels/${targetChannel}/messages`, {
      method: 'POST',
      headers: {
        'Authorization': `Bot ${token}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ content: message })
    });
    
    if (r.ok) {
      const data = await r.json();
      res.json({ success: true, messageId: data.id, sentAs: usedBot });
    } else {
      const err = await r.text();
      res.status(r.status).json({ error: err });
    }
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// 获取bot列表（含状态）
app.get('/api/bots', authMiddleware, (req, res) => {
  try {
    const config = JSON.parse(readFileSync(CONFIG_PATH, 'utf-8'));
    const channels = config.channels || {};
    const botMap = {};
    
    // Collect bots from all platform channels
    for (const [platform, chConf] of Object.entries(channels)) {
      const accounts = chConf?.accounts || {};
      for (const [id, acc] of Object.entries(accounts)) {
        if (!botMap[id]) {
          botMap[id] = {
            id,
            name: AGENT_DEPT_MAP[id] || id,
            displayName: acc.displayName || AGENT_DEPT_MAP[id] || id,
            model: acc.model || config.defaultModel || 'claude-opus-4-6',
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
  const role = req.query.role || 'unknown'; // 'emperor' or 'queen'
  
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
    // Force refresh cache for broadcast
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
const IS_DOCKER = existsSync('/.dockerenv') || (existsSync('/proc/1/cgroup') && readFileSync('/proc/1/cgroup', 'utf8').includes('docker'));
const BIND_HOST = process.env.BOLUO_BIND_HOST || (IS_DOCKER ? '0.0.0.0' : '127.0.0.1');
server.listen(PORT, BIND_HOST, () => {
  console.log(`Boluo GUI running on http://${BIND_HOST}:${PORT} (HTTP + WebSocket)`);
  if (BIND_HOST === '0.0.0.0') {
    console.warn('⚠️  GUI 监听所有网口，确保已配置防火墙或反向代理');
  }
});
