import { useState, useEffect, useRef } from "react"
import {
  LineChart, Line, XAxis, YAxis, Tooltip, ResponsiveContainer, CartesianGrid,
  PieChart, Pie, Cell,
} from "recharts"
import type { SystemStatus } from "../types"
import { useTheme } from "../theme"
import { getAuthToken } from '../auth'

interface Props { data: SystemStatus }

interface MetricPoint {
  timestamp: string
  cpu1m: number; cpu5m: number; cpu15m: number
  memUsedPct: number; memUsedGB: number
}

interface HealthInfo {
  status: string; version: string; uptimeFormatted: string; systemUptime: string
  memory: { used: number; total: number; rss: number }
  cpu: string[]
  gateway: string; endpoints: number
  cache: { hits: number; misses: number; keys: number }
}

function fmt(n: number): string {
  if (n >= 1_000_000_000) return (n / 1_000_000_000).toFixed(2) + " GB"
  if (n >= 1_000_000) return (n / 1_000_000).toFixed(1) + " MB"
  if (n >= 1_000) return (n / 1_000).toFixed(1) + " KB"
  return n + " B"
}

function loadColor(pct: number): string {
  if (pct >= 80) return 'text-red-400'
  if (pct >= 50) return 'text-yellow-400'
  return 'text-green-400'
}

// Ring/donut chart for disk/memory
function RingChart({ value, max, label, color }: { value: number; max: number; label: string; color: string }) {
  const { theme } = useTheme()
  const pct = max > 0 ? (value / max * 100) : 0
  const data = [
    { name: 'used', value: value },
    { name: 'free', value: Math.max(0, max - value) },
  ]
  const colors = [color, theme === 'light' ? '#e5e7eb' : '#0d0d1a']

  return (
    <div className="relative">
      <ResponsiveContainer width="100%" height={140}>
        <PieChart>
          <Pie data={data} cx="50%" cy="50%" innerRadius={40} outerRadius={55} paddingAngle={2} dataKey="value" startAngle={90} endAngle={-270}>
            {data.map((_, i) => <Cell key={i} fill={colors[i]} />)}
          </Pie>
        </PieChart>
      </ResponsiveContainer>
      <div className="absolute inset-0 flex items-center justify-center pointer-events-none">
        <div className="text-center">
          <div className={`font-mono text-sm ${loadColor(pct)}`}>{pct.toFixed(0)}%</div>
          <div className="text-[9px] text-[#a3a3a3]">{label}</div>
        </div>
      </div>
    </div>
  )
}

export default function SystemHealth({ data }: Props) {
  const { theme } = useTheme()
  const [metrics, setMetrics] = useState<MetricPoint[]>([])
  const [health, setHealth] = useState<HealthInfo | null>(null)
  const timerRef = useRef<ReturnType<typeof setInterval> | null>(null)
  const bg = theme === 'light' ? 'bg-white border border-gray-200' : 'bg-[#1a1a2e]'
  const sub = theme === 'light' ? 'text-gray-500' : 'text-[#a3a3a3]'

  const fetchMetrics = async () => {
    try {
      const h = { headers: { Authorization: `Bearer ${getAuthToken()}` } }
      const [mRes, hRes] = await Promise.all([
        fetch('/api/system/metrics', h),
        fetch('/api/health', h),
      ])
      if (mRes.ok) {
        const d = await mRes.json()
        setMetrics(d.metrics || [])
      }
      if (hRes.ok) {
        const d = await hRes.json()
        setHealth(d)
      }
    } catch {}
  }

  useEffect(() => {
    fetchMetrics()
    timerRef.current = setInterval(fetchMetrics, 30000)
    return () => { if (timerRef.current) clearInterval(timerRef.current) }
  }, [])

  // Format metrics for chart
  const chartData = metrics.map(m => ({
    time: new Date(m.timestamp).toLocaleTimeString('zh-CN', { hour: '2-digit', minute: '2-digit', hour12: false }),
    cpu1m: +(Number(m.cpu1m) * 100).toFixed(1),
    cpu5m: +(Number(m.cpu5m) * 100).toFixed(1),
    memPct: +Number(m.memUsedPct).toFixed(1),
  }))

  const latestMetric = metrics.length > 0 ? metrics[metrics.length - 1] : null
  const cpuPct = Number(latestMetric ? latestMetric.cpu1m : (data.cpuLoad?.[0] ?? 0)) * 100
  const memPct = Number(latestMetric?.memUsedPct ?? 0)
  const memGB = Number(latestMetric?.memUsedGB ?? 0)

  return (
    <div className="space-y-4 sm:space-y-6">
      {/* 进程信息卡片 */}
      <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
        <div className={`${bg} rounded-lg p-3`}>
          <div className={`text-[10px] uppercase ${sub}`}>⏱ 系统运行</div>
          <div className="font-mono text-sm text-[#d4a574] mt-1">{health?.systemUptime || data.uptime}</div>
        </div>
        <div className={`${bg} rounded-lg p-3`}>
          <div className={`text-[10px] uppercase ${sub}`}>📦 版本</div>
          <div className="font-mono text-sm text-[#d4a574] mt-1">{health?.version || '-'}</div>
        </div>
        <div className={`${bg} rounded-lg p-3`}>
          <div className={`text-[10px] uppercase ${sub}`}>🔌 端点数</div>
          <div className="font-mono text-sm text-[#d4a574] mt-1">{health?.endpoints || '-'}</div>
        </div>
        <div className={`${bg} rounded-lg p-3`}>
          <div className={`text-[10px] uppercase ${sub}`}>🌐 Gateway</div>
          <div className={`font-mono text-sm mt-1 ${health?.gateway === 'connected' || data.gateway?.status === 'ready' ? 'text-green-400' : 'text-red-400'}`}>
            {health?.gateway || data.gateway?.status} · {data.gateway?.ping}ms
          </div>
        </div>
      </div>

      {/* 平台信息 */}
      <div className={`${bg} rounded-lg p-3 sm:p-4`}>
        <div className="flex flex-wrap gap-4 text-xs">
          <span className={sub}>🖥 {data.platform}</span>
          <span className={sub}>💾 RSS: {fmt(data.memoryUsage?.rss || 0)}</span>
          <span className={sub}>📊 Heap: {fmt(data.memoryUsage?.heapUsed || 0)} / {fmt(data.memoryUsage?.heapTotal || 0)}</span>
          <span className={sub}>🔗 Sessions: {data.totalSessions}</span>
        </div>
      </div>

      {/* 实时指标环形图 */}
      <div className="grid grid-cols-3 gap-3">
        <div className={`${bg} rounded-lg p-3`}>
          <h3 className={`text-[10px] uppercase tracking-wider mb-1 text-center ${sub}`}>📊 CPU</h3>
          <RingChart value={cpuPct} max={100} label="CPU 1m" color={cpuPct >= 80 ? '#ef4444' : cpuPct >= 50 ? '#eab308' : '#22c55e'} />
        </div>
        <div className={`${bg} rounded-lg p-3`}>
          <h3 className={`text-[10px] uppercase tracking-wider mb-1 text-center ${sub}`}>💾 内存</h3>
          <RingChart value={memPct} max={100} label={`${memGB.toFixed(1)}GB`} color={memPct >= 80 ? '#ef4444' : memPct >= 50 ? '#eab308' : '#d4a574'} />
        </div>
        <div className={`${bg} rounded-lg p-3`}>
          <h3 className={`text-[10px] uppercase tracking-wider mb-1 text-center ${sub}`}>📂 缓存</h3>
          <div className="flex flex-col items-center justify-center h-[140px] gap-2">
            <div className="text-2xl font-mono text-[#d4a574]">{health?.cache?.keys ?? '-'}</div>
            <div className={`text-[10px] ${sub}`}>缓存键</div>
            <div className="flex gap-3 text-[10px]">
              <span className="text-green-400">命中 {health?.cache?.hits ?? 0}</span>
              <span className="text-red-400">未中 {health?.cache?.misses ?? 0}</span>
            </div>
          </div>
        </div>
      </div>

      {/* CPU/内存折线图 */}
      {chartData.length > 1 && (
        <div className={`${bg} rounded-lg p-3 sm:p-4`}>
          <div className="flex items-center justify-between mb-3">
            <h3 className={`text-[10px] sm:text-xs uppercase tracking-wider ${sub}`}>📈 CPU & 内存趋势</h3>
            <span className={`text-[10px] ${sub}`}>每30秒采样 · {chartData.length}点</span>
          </div>
          <ResponsiveContainer width="100%" height={200}>
            <LineChart data={chartData}>
              <CartesianGrid strokeDasharray="3 3" stroke={theme === 'light' ? '#e5e7eb' : '#333'} />
              <XAxis dataKey="time" tick={{ fontSize: 9, fill: '#a3a3a3' }} />
              <YAxis tick={{ fontSize: 9, fill: '#a3a3a3' }} domain={[0, 100]} tickFormatter={v => `${v}%`} width={35} />
              <Tooltip
                contentStyle={{
                  backgroundColor: theme === 'light' ? '#fff' : '#1a1a2e',
                  border: '1px solid #d4a574',
                  borderRadius: 8, fontSize: 11,
                }}
                formatter={(v: unknown) => [`${Number(v).toFixed(1)}%`]}
              />
              <Line type="monotone" dataKey="cpu1m" stroke="#22c55e" strokeWidth={2} dot={false} name="CPU 1m" />
              <Line type="monotone" dataKey="cpu5m" stroke="#3b82f6" strokeWidth={1.5} dot={false} name="CPU 5m" strokeDasharray="4 2" />
              <Line type="monotone" dataKey="memPct" stroke="#d4a574" strokeWidth={2} dot={false} name="内存%" />
            </LineChart>
          </ResponsiveContainer>
          <div className="flex justify-center gap-4 mt-2 text-[10px]">
            <span className="flex items-center gap-1"><span className="w-3 h-0.5 bg-green-500 inline-block" /> CPU 1m</span>
            <span className="flex items-center gap-1"><span className="w-3 h-0.5 bg-blue-500 inline-block" /> CPU 5m</span>
            <span className="flex items-center gap-1"><span className="w-3 h-0.5 bg-[#d4a574] inline-block" /> 内存</span>
          </div>
        </div>
      )}

      {/* Gateway + Server详细信息 */}
      <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
        <div className={`${bg} rounded-lg p-3 sm:p-4`}>
          <h3 className={`text-[10px] sm:text-xs uppercase tracking-wider mb-3 ${sub}`}>🌐 Gateway 状态</h3>
          <div className="space-y-2 text-xs">
            <div className="flex justify-between">
              <span className={sub}>状态</span>
              <span className={`font-mono ${data.gateway?.status === 'ready' ? 'text-green-400' : 'text-red-400'}`}>
                {data.gateway?.status}
              </span>
            </div>
            <div className="flex justify-between">
              <span className={sub}>Ping</span>
              <span className="font-mono text-[#d4a574]">{data.gateway?.ping}ms</span>
            </div>
            <div className="flex justify-between">
              <span className={sub}>Guilds</span>
              <span className="font-mono text-[#d4a574]">{data.gateway?.guilds}</span>
            </div>
          </div>
        </div>
        <div className={`${bg} rounded-lg p-3 sm:p-4`}>
          <h3 className={`text-[10px] sm:text-xs uppercase tracking-wider mb-3 ${sub}`}>📦 Node.js 进程</h3>
          <div className="space-y-2 text-xs">
            <div className="flex justify-between">
              <span className={sub}>Heap 使用</span>
              <span className="font-mono text-[#d4a574]">
                {fmt(data.memoryUsage?.heapUsed || 0)} / {fmt(data.memoryUsage?.heapTotal || 0)}
              </span>
            </div>
            <div className="flex justify-between">
              <span className={sub}>RSS</span>
              <span className="font-mono text-[#d4a574]">{fmt(data.memoryUsage?.rss || 0)}</span>
            </div>
            <div className="flex justify-between">
              <span className={sub}>External</span>
              <span className="font-mono text-[#d4a574]">{fmt(data.memoryUsage?.external || 0)}</span>
            </div>
            <div className="flex justify-between">
              <span className={sub}>服务运行</span>
              <span className="font-mono text-[#d4a574]">{health?.uptimeFormatted || '-'}</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
