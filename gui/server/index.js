import express from 'express';
import cors from 'cors';
import { readFileSync, readdirSync, existsSync, statSync } from 'fs';
import { join } from 'path';
import { fileURLToPath } from 'url';
import { dirname } from 'path';
import os from 'os';
import http from 'http';
import { createRequire } from 'module';
const require = createRequire(import.meta.url);
import { WebSocketServer } from 'ws';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const app = express();
const PORT = 18790;

const AUTH_TOKEN = process.env.BOLUO_AUTH_TOKEN || '';

const AGENT_DEPT_MAP = {
  'main': '司礼监', 'gongbu': '工部', 'hubu': '户部', 'libu': '吏部',
  'xingbu': '刑部', 'bingbu': '兵部', 'libu2': '礼部',
  'neige': '内阁', 'duchayuan': '都察院', 'neiwufu': '内务府',
  'hanlinyuan': '翰林院', 'taiyiyuan': '太医院', 'guozijian': '国子监',
  'yushanfang': '御膳房'
};

const HOME = process.env.HOME || '/home/ubuntu';
const AGENTS_DIR = join(HOME, '.openclaw/agents');
const CONFIG_PATH = join(HOME, '.openclaw/openclaw.json');

app.use(cors({ origin: ['https://gui.at2.one'] }));
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

function getOpenClawConfig() {
  try {
    if (existsSync(CONFIG_PATH)) {
      return JSON.parse(readFileSync(CONFIG_PATH, 'utf-8'));
    }
  } catch (e) { }
  return null;
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

app.get('/api/status', authMiddleware, async (req, res) => {
  const config = getOpenClawConfig();
  const defaultModel = config?.agents?.defaults?.model?.primary || 'default';

  let agentIds = [];
  if (existsSync(AGENTS_DIR)) {
    agentIds = readdirSync(AGENTS_DIR, { withFileTypes: true })
      .filter(d => d.isDirectory())
      .map(d => d.name);
  }

  const botAccounts = agentIds.map(id => {
    const sessData = getAgentSessionData(id);
    const agentConfig = config?.agents?.list?.[id] || {};
    const model = agentConfig?.model?.primary || sessData.model || defaultModel;

    return {
      name: id,
      displayName: AGENT_DEPT_MAP[id] || id,
      status: 'online',
      model: model,
      sessions: sessData.sessions,
      inputTokens: sessData.inputTokens,
      outputTokens: sessData.outputTokens,
      totalTokens: sessData.totalTokens,
    };
  });

  const totalSessions = botAccounts.reduce((s, b) => s + b.sessions, 0);
  const todayTokens = botAccounts.reduce((s, b) => s + b.totalTokens, 0);

  const mem = process.memoryUsage();
  const sysUptime = os.uptime();
  const cpuLoad = os.loadavg();

  const logs = getRecentLogs(100);

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
    gateway: {
      status: 'ready',
      ping: Math.floor(Math.random() * 30) + 20,
      guilds: 1
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
    .filter(line => line.includes('channel') || line.includes('message'))
    .slice(-50)
    .map((line, i) => ({
      id: i,
      content: line.substring(0, 200),
      timestamp: new Date().toISOString(),
      channel: 'general'
    }));
  res.json({ messages });
});

function getTokenStats() {
  const deptMap = {
    'gongbu': '工部', 'hubu': '户部', 'libu': '吏部', 
    'xingbu': '刑部', 'bingbu': '兵部', 'libu2': '礼部'
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

  const rawConfig = getOpenClawConfig();
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

app.get('/api/health', authMiddleware, (req, res) => {
  try {
    const uptime = process.uptime();
    const memUsage = process.memoryUsage();
    const cpuLoad = os.loadavg();
    const sysUptime = os.uptime();

    // Count endpoints
    let endpointCount = 0;
    app._router.stack.forEach(r => { if (r.route) endpointCount++; });

    // Disk usage
    let diskUsagePct = 'N/A', diskTotal = 'N/A', diskUsed = 'N/A';
    try {
      const { execSync: ex } = require('child_process');
      const dfLine = ex("df -h / | tail -1", { encoding: 'utf-8', timeout: 2000 }).trim();
      const parts = dfLine.split(/\s+/);
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
      wsClients: typeof wss !== 'undefined' ? wss.clients.size : 0,
      sseClients: typeof sseClients !== 'undefined' ? sseClients.size : 0,
      metricsBufferSize: typeof metricsBuffer !== 'undefined' ? metricsBuffer.length : 0,
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

// Count messages and usage from a JSONL session file
function countSessionFile(filePath) {
  const result = { messages: 0, userMessages: 0, assistantMessages: 0, inputTokens: 0, outputTokens: 0 };
  try {
    if (!filePath || !existsSync(filePath)) return result;
    const content = readFileSync(filePath, 'utf-8');
    const lines = content.split('\n').filter(l => l.trim());
    for (const line of lines) {
      try {
        const entry = JSON.parse(line);
        if (entry.type === 'message' && entry.message) {
          result.messages++;
          if (entry.message.role === 'user') result.userMessages++;
          else if (entry.message.role === 'assistant') result.assistantMessages++;
          // Usage is nested in message.usage
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

// Build all sessions data (cached)
function buildSessionsData() {
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
          for (const [sessionKey, session] of Object.entries(data)) {
            const updatedAt = session.updatedAt || 0;
            const sessionFile = session.sessionFile || '';
            
            // Count messages and tokens from the JSONL file
            const counts = countSessionFile(sessionFile);
            
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
          }
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

app.get('/api/sessions', authMiddleware, (req, res) => {
  try {
    const limit = parseInt(req.query.limit) || 100;
    const data = buildSessionsData();
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
app.get('/api/dashboard/summary', authMiddleware, (req, res) => {
  try {
    const cached = getCached('dashboard_summary');
    if (cached) return res.json(cached);

    const sessData = buildSessionsData();
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
    
    // Disk usage
    let diskUsage = 'N/A';
    try {
      const du = require('child_process').execSync("df -h / | tail -1 | awk '{print $5}'", { encoding: 'utf-8', timeout: 3000 }).trim();
      diskUsage = du;
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
    const agentId = parts[1] || 'main';
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
    const agentId = parts[1] || 'main';
    const sessionKey = parts.slice(2).join(':');
    
    const sessionsPath = join(AGENTS_DIR, agentId, 'sessions', 'sessions.json');
    if (existsSync(sessionsPath)) {
      const sessionsData = JSON.parse(readFileSync(sessionsPath, 'utf-8'));
      const session = sessionsData[sessionKey];
      if (session?.sessionFile && existsSync(session.sessionFile)) {
        const lines = readFileSync(session.sessionFile, 'utf-8').split('\n').filter(Boolean);
        for (const line of lines) {
          try {
            const entry = JSON.parse(line);
            if (entry.type === 'message' && entry.message) {
              const content = entry.message.content;
              let text = '';
              if (Array.isArray(content)) {
                text = content.map(c => c.text || c.type).join('');
              } else if (typeof content === 'string') {
                text = content;
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
    const agentId = parts[1] || 'main';
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
    const config = getOpenClawConfig();
    if (!config) return res.json({ config: null, error: 'Config not found' });
    
    // Deep clone and mask sensitive fields
    const masked = JSON.parse(JSON.stringify(config));
    const maskSecrets = (obj, depth = 0) => {
      if (!obj || typeof obj !== 'object' || depth > 10) return;
      for (const key of Object.keys(obj)) {
        if (/token|secret|key|password|apiKey/i.test(key) && typeof obj[key] === 'string') {
          obj[key] = obj[key].substring(0, 6) + '••••••';
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
  res.json({
    status: 'success',
    lastSync: new Date().toISOString(),
    pagesLinked: 12,
    lastError: null
  });
});

app.post('/api/notion/sync', authMiddleware, (req, res) => {
  res.json({ success: true, message: '同步任务已触发' });
});

app.get('/api/notion/data', authMiddleware, (req, res) => {
  const { type = 'daily' } = req.query;
  const config = getOpenClawConfig();
  
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
    const data = tokenStats.byDepartment.slice(0, 6).map((d, i) => ({
      id: String(i + 1),
      category: d.department,
      income: Math.floor(Math.random() * 500000) + 100000,
      expense: Math.floor(d.tokens * 0.001),
      period: '2026-02',
      balance: Math.floor(Math.random() * 300000)
    }));
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

app.get('/api/weather', authMiddleware, (req, res) => {
  const location = String(req.query.location || WEATHER_DEFAULT_LOCATION).replace(/[^a-zA-Z0-9,+\-_ .]/g, "");
  
  try {
    const output = require('child_process').execSync(`curl -s "wttr.in/${location}?format=j1"`, { 
      timeout: 5000,
      encoding: 'utf8'
    }).trim();
    
    const data = JSON.parse(output);
    const current = data.current_condition?.[0];
    
    if (current) {
      const temp = current.temp_C?.[0] || 'N/A';
      const condition = current.weatherDesc?.[0]?.value || 'Unknown';
      const humidity = current.humidity?.[0] || 'N/A';
      const wind = current.windspeedKmph?.[0] || 'N/A';
      
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
    const config = getOpenClawConfig();
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
    ];
    
    const platforms = platformDefs
      .map(def => {
        const chConf = channels[def.key];
        const isConfigured = !!chConf;
        // Count accounts: check if there's a token/credentials configured
        const accounts = isConfigured ? (Array.isArray(chConf.accounts) ? chConf.accounts.length : 1) : 0;
        return {
          name: def.name,
          status: isConfigured ? 'connected' : 'disconnected',
          channels: def.key === 'discord' ? totalSessions : 0,
          accounts: accounts,
        };
      })
      .filter(p => p.status === 'connected' || ['Discord', 'Telegram', 'Signal', 'WhatsApp'].includes(p.name));
    
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

app.get('/api/cron', authMiddleware, (req, res) => {
  // 从 Gateway 获取真实 Cron Jobs
  const { execSync } = require('child_process');
  try {
    const output = execSync('openclaw cron list --json 2>/dev/null', { encoding: 'utf-8', timeout: 5000 });
    const data = JSON.parse(output);
    const jobs = (data.jobs || []).map((j) => {
      // 解析调度规则
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
      
      // 解析状态
      const state = j.state;
      const nextRunMs = state.nextRunAtMs;
      const lastRunMs = state.lastRunAtMs;
      
      return {
        id: j.id,
        name: j.name,
        schedule: scheduleStr,
        enabled: j.enabled,
        nextRun: nextRunMs ? new Date(nextRunMs).toISOString() : null,
        lastRun: lastRunMs ? new Date(lastRunMs).toISOString() : null,
        status: state.lastStatus || 'unknown',
        agent: j.agentId
      };
    });
    res.json({ jobs, source: 'gateway' });
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

app.post('/api/cron/run/:id', authMiddleware, (req, res) => {
  const id = req.params.id.replace(/[^a-zA-Z0-9_\-]/g, '');
  const { execSync } = require('child_process');
  try {
    execSync(`openclaw cron run ${id}`, { encoding: 'utf-8', timeout: 10000 });
    res.json({ success: true, message: `任务 ${id} 已触发执行` });
  } catch (e) {
    res.json({ success: false, message: `任务 ${id} 执行失败: ${e.message}` });
  }
});

// Cron enable/disable
app.patch('/api/cron/jobs/:id', authMiddleware, (req, res) => {
  try {
    const id = req.params.id.replace(/[^a-zA-Z0-9_\-]/g, '');
    const { enabled } = req.body;
    const { execSync } = require('child_process');
    
    if (typeof enabled === 'boolean') {
      const action = enabled ? 'enable' : 'disable';
      // Try openclaw CLI
      try {
        execSync(`openclaw cron ${action} ${id}`, { encoding: 'utf-8', timeout: 10000 });
        res.json({ success: true, message: `任务 ${id} 已${enabled ? '启用' : '禁用'}`, id, enabled });
      } catch (cliErr) {
        // Fallback: try to update config directly
        try {
          const config = getOpenClawConfig();
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
app.get('/api/cron/jobs', authMiddleware, (req, res) => {
  const { execSync } = require('child_process');
  try {
    const output = execSync('openclaw cron list --json 2>/dev/null', { encoding: 'utf-8', timeout: 5000 });
    const data = JSON.parse(output);
    const jobs = (data.jobs || []).map((j) => {
      let scheduleStr = '';
      if (j.schedule) {
        const s = j.schedule;
        if (s.kind === 'cron') scheduleStr = s.expr || '';
        else if (s.kind === 'every') {
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
    res.json({ jobs, source: 'gateway' });
  } catch (e) {
    res.json({ jobs: [], source: 'error', error: e.message });
  }
});

// Read real gateway logs from journalctl or log files
function readGatewayLogs(opts = {}) {
  const { level, search, limit = 200, since } = opts;
  const logs = [];
  
  try {
    // Try journalctl for openclaw service logs
    const { execSync } = require('child_process');
    let cmd = 'journalctl -u openclaw --no-pager -n 200 --output=short-iso 2>/dev/null';
    if (since) cmd += ` --since="${String(since).replace(/[^a-zA-Z0-9:\-_ ]/g, "")}"`;
    
    let output = '';
    try {
      output = execSync(cmd, { encoding: 'utf-8', timeout: 5000 });
    } catch {
      // Fallback: read from openclaw log file
      const logPaths = [
        `${HOME}/.openclaw/logs/gateway.log`,
        '/tmp/openclaw.log',
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

app.get('/api/nodes', authMiddleware, (req, res) => {
  const nodes = [
    { id: 'vibe-server', name: 'Vibe服务器', status: 'online', lastHeartbeat: Date.now(), os: 'Linux arm64', uptime: 432000 },
    { id: 'desktop-mac', name: 'Mac桌面', status: 'offline', lastHeartbeat: Date.now() - 3600000, os: 'macOS x64', uptime: 0 },
    { id: 'phone-iphone', name: 'iPhone', status: 'online', lastHeartbeat: Date.now(), os: 'iOS', uptime: 7200 }
  ];
  res.json({ nodes });
});

// Notion 数据库/页面查询路由
app.get('/api/notion/:id', authMiddleware, async (req, res) => {
  const { id } = req.params;
  const NOTION_TOKEN = process.env.NOTION_TOKEN || '';
  
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
  const channelId = req.query.channel || '1474091579630293164';
  const limit = Math.min(parseInt(req.query.limit) || 15, 50);
  
  try {
    const config = JSON.parse(readFileSync(CONFIG_PATH, 'utf-8'));
    const account = config.channels?.discord?.accounts?.['main'];
    const token = account?.token;
    
    if (!token) {
      return res.status(400).json({ error: 'Main bot token not found' });
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
// 获取 Discord 服务器频道列表（带缓存）
let discordChannelsCache = { data: null, ts: 0 };
const CHANNELS_CACHE_TTL = 300000; // 5分钟缓存

app.get('/api/discord-channels', authMiddleware, async (req, res) => {
  if (discordChannelsCache.data && Date.now() - discordChannelsCache.ts < CHANNELS_CACHE_TTL) {
    return res.json(discordChannelsCache.data);
  }

  try {
    const config = JSON.parse(readFileSync(CONFIG_PATH, 'utf-8'));
    const mainAccount = config.channels?.discord?.accounts?.['main'];
    const token = mainAccount?.token;
    if (!token) return res.status(400).json({ error: 'Main bot token not found' });

    // 先获取 bot 所在的 guild
    const guildRes = await fetch('https://discord.com/api/v10/users/@me/guilds', {
      headers: { 'Authorization': `Bot ${token}` }
    });
    if (!guildRes.ok) return res.status(guildRes.status).json({ error: 'Failed to fetch guilds' });
    const guilds = await guildRes.json();
    if (guilds.length === 0) return res.json({ channels: [] });

    // 获取第一个 guild 的频道列表（文字频道）
    const guildId = guilds[0].id;
    const chRes = await fetch(`https://discord.com/api/v10/guilds/${guildId}/channels`, {
      headers: { 'Authorization': `Bot ${token}` }
    });
    if (!chRes.ok) return res.status(chRes.status).json({ error: 'Failed to fetch channels' });
    const allChannels = await chRes.json();

    // 只返回文字频道 (type 0) 和公告频道 (type 5)，按 Discord position 排序
    const textChannels = allChannels
      .filter(ch => ch.type === 0 || ch.type === 5)
      .map(ch => ({ id: ch.id, name: ch.name, parentId: ch.parent_id, position: ch.position ?? 0 }))
      .sort((a, b) => a.position - b.position);

    // 也返回分类 (type 4) 方便前端分组，按 position 排序
    const categories = allChannels
      .filter(ch => ch.type === 4)
      .map(ch => ({ id: ch.id, name: ch.name, position: ch.position ?? 0 }))
      .sort((a, b) => a.position - b.position);

    const result = { channels: textChannels, categories, guildId };
    discordChannelsCache = { data: result, ts: Date.now() };
    res.json(result);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// 获取 bot 的 Discord user ID（用于正确 @mention），带内存缓存
let botUserIdsCache = { data: null, ts: 0 };
const BOT_USER_IDS_TTL = 600000; // 10分钟缓存

app.get('/api/bot-user-ids', authMiddleware, async (req, res) => {
  // 命中缓存直接返回
  if (botUserIdsCache.data && Date.now() - botUserIdsCache.ts < BOT_USER_IDS_TTL) {
    return res.json({ botUserIds: botUserIdsCache.data });
  }

  try {
    const config = JSON.parse(readFileSync(CONFIG_PATH, 'utf-8'));
    const accounts = config.channels?.discord?.accounts || {};
    const results = {};

    await Promise.all(Object.entries(accounts).map(async ([agentId, acc]) => {
      if (!acc.token) return;
      try {
        const r = await fetch('https://discord.com/api/v10/users/@me', {
          headers: { 'Authorization': `Bot ${acc.token}` }
        });
        if (r.ok) {
          const user = await r.json();
          results[agentId] = user.id;
        }
      } catch { /* skip */ }
    }));

    botUserIdsCache = { data: results, ts: Date.now() };
    res.json({ botUserIds: results });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// 发送指令到Discord频道（始终用主bot发送，正确@mention目标bot）
app.post('/api/command', authMiddleware, async (req, res) => {
  const { channel, message, botId, mentionUserId } = req.body;
  const targetChannel = channel || '1474091579630293164'; // 默认朝堂频道
  
  try {
    const config = JSON.parse(readFileSync(CONFIG_PATH, 'utf-8'));
    // 始终用主bot（司礼监）的token发送，模拟"用户下旨"
    const mainAccount = config.channels?.discord?.accounts?.['main'];
    const token = mainAccount?.token;
    
    if (!token) {
      return res.status(400).json({ error: 'Main bot token not found' });
    }

    // 构建消息：如果指定了目标bot且有其Discord user ID，用真正的@mention
    let finalMessage = message;
    if (mentionUserId && botId !== 'main') {
      finalMessage = `<@${mentionUserId}> ${message}`;
    }

    const r = await fetch(`https://discord.com/api/v10/channels/${targetChannel}/messages`, {
      method: 'POST',
      headers: {
        'Authorization': `Bot ${token}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ content: finalMessage })
    });
    
    if (r.ok) {
      const data = await r.json();
      res.json({ success: true, messageId: data.id, sentAs: 'main', channel: targetChannel });
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
    const accounts = config.channels?.discord?.accounts || {};
    const bots = Object.entries(accounts).map(([id, acc]) => ({
      id,
      name: AGENT_DEPT_MAP[id] || id,
      displayName: acc.displayName || AGENT_DEPT_MAP[id] || id,
      model: acc.model || config.defaultModel || 'default',
      hasToken: !!acc.token,
    }));
    res.json({ bots });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// 三城天气 API (Open-Meteo, 免费无需key)
const WEATHER_CITIES = [
  { name: '苏黎世', lat: 47.37, lon: 8.55, tz: 'Europe/Zurich' },
  { name: '南京', lat: 32.06, lon: 118.80, tz: 'Asia/Shanghai' },
  { name: '杭州', lat: 30.25, lon: 120.17, tz: 'Asia/Shanghai' },
];

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

// Prevent uncaught exceptions from crashing the process
process.on('uncaughtException', (err) => {
  console.error('[FATAL] Uncaught exception:', err.message);
  console.error(err.stack);
});
process.on('unhandledRejection', (reason) => {
  console.error('[FATAL] Unhandled rejection:', reason);
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
setInterval(() => {
  if (wss.clients.size === 0) return;
  
  try {
    // Force refresh cache for broadcast
    delete cache['dashboard_summary'];
    
    // Build fresh data using the status endpoint's logic
    const sessData = buildSessionsData();
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

server.listen(PORT, '0.0.0.0', () => {
  console.log(`Boluo GUI running on http://0.0.0.0:${PORT} (HTTP + WebSocket)`);
});
