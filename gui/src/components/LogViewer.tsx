import { useState, useEffect, useRef } from "react"
import { useTheme } from "../theme"
import { getAuthToken } from '../auth'

interface LogEntry {
  id: number
  timestamp: string
  level: string
  message: string
  source: string
}

export default function LogViewer() {
  const [logs, setLogs] = useState<LogEntry[]>([])
  const [loading, setLoading] = useState(true)
  const [level, setLevel] = useState('ALL')
  const [search, setSearch] = useState('')
  const [autoRefresh, setAutoRefresh] = useState(false)
  const [timeRange, setTimeRange] = useState('all') // all, 1h, 6h, 24h
  const [levelStats, setLevelStats] = useState({ info: 0, warn: 0, error: 0 })
  const { theme } = useTheme()
  const logContainerRef = useRef<HTMLDivElement>(null)

  const fetchLogs = async () => {
    try {
      const params = new URLSearchParams()
      if (level !== 'ALL') params.set('level', level)
      if (search) params.set('search', search)
      params.set('limit', '500')
      
      const res = await fetch(`/api/logs/list?${params}`, {
        headers: { 'Authorization': `Bearer ${getAuthToken()}` }
      })
      if (res.ok) {
        const data = await res.json()
        let filteredLogs = data.logs || []
        
        // 时间过滤
        if (timeRange !== 'all') {
          const now = Date.now()
          const ranges: Record<string, number> = {
            '1h': 3600000,
            '6h': 21600000,
            '24h': 86400000
          }
          const cutoff = now - (ranges[timeRange] || 0)
          filteredLogs = filteredLogs.filter((l: LogEntry) => {
            const logTime = new Date(l.timestamp).getTime()
            return logTime > cutoff
          })
        }
        
        setLogs(filteredLogs)
        
        // 统计各级别数量
        const stats = { info: 0, warn: 0, error: 0 }
        filteredLogs.forEach((l: LogEntry) => {
          if (l.level === 'INFO') stats.info++
          else if (l.level === 'WARN' || l.level === 'WARNING') stats.warn++
          else if (l.level === 'ERROR') stats.error++
        })
        setLevelStats(stats)
      }
    } catch (e) {
      console.error('Failed to fetch logs:', e)
    }
    setLoading(false)
  }

  useEffect(() => {
    fetchLogs()
  }, [level])

  // 自动刷新
  useEffect(() => {
    let interval: ReturnType<typeof setInterval>
    if (autoRefresh) {
      interval = setInterval(fetchLogs, 3000)
    }
    return () => clearInterval(interval)
  }, [autoRefresh, timeRange])

  const getLevelColor = (lvl: string) => {
    switch (lvl) {
      case 'ERROR': return 'text-red-500'
      case 'WARN': case 'WARNING': return 'text-yellow-500'
      case 'DEBUG': return 'text-blue-500'
      default: return 'text-green-500'
    }
  }

  const formatTime = (ts: string) => {
    try {
      return new Date(ts).toLocaleTimeString('zh-CN')
    } catch {
      return ts
    }
  }

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between flex-wrap gap-2">
        <h2 className={`text-lg font-medium ${theme === 'light' ? 'text-gray-800' : 'text-[#d4a574]'}`}>
          实时日志
        </h2>
        
        <div className="flex items-center gap-2 flex-wrap">
          {/* 时间范围选择 */}
          <select
            value={timeRange}
            onChange={(e) => setTimeRange(e.target.value)}
            className={`px-2 py-1 text-xs border rounded ${
              theme === 'light' 
                ? 'bg-white border-gray-300' 
                : 'bg-[#16213e] border-[#d4a574]/30'
            }`}
          >
            <option value="all">全部时间</option>
            <option value="1h">最近1小时</option>
            <option value="6h">最近6小时</option>
            <option value="24h">最近24小时</option>
          </select>

          {/* 级别过滤 */}
          <select
            value={level}
            onChange={(e) => setLevel(e.target.value)}
            className={`px-2 py-1 text-xs border rounded ${
              theme === 'light' 
                ? 'bg-white border-gray-300' 
                : 'bg-[#16213e] border-[#d4a574]/30'
            }`}
          >
            <option value="ALL">全部</option>
            <option value="INFO">INFO</option>
            <option value="WARN">WARN</option>
            <option value="ERROR">ERROR</option>
          </select>

          {/* 搜索 */}
          <input
            type="text"
            placeholder="搜索日志..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            onKeyDown={(e) => e.key === 'Enter' && fetchLogs()}
            className={`px-2 py-1 text-xs border rounded w-32 ${
              theme === 'light' 
                ? 'bg-white border-gray-300' 
                : 'bg-[#16213e] border-[#d4a574]/30'
            }`}
          />

          {/* 刷新按钮 */}
          <button
            onClick={fetchLogs}
            className="px-2 py-1 text-xs border border-[#d4a574] text-[#d4a574] hover:bg-[#d4a574]/10"
          >
            刷新
          </button>

          {/* 导出按钮 */}
          <button
            onClick={() => {
              const csv = [
                '时间,级别,来源,消息',
                ...logs.map(l => `"${l.timestamp}","${l.level}","${l.source}","${l.message.replace(/"/g, '""')}"`)
              ].join('\n')
              const blob = new Blob(['\ufeff' + csv], { type: 'text/csv;charset=utf-8;' })
              const url = URL.createObjectURL(blob)
              const a = document.createElement('a')
              a.href = url
              a.download = `logs_${new Date().toISOString().split('T')[0]}.csv`
              a.click()
              URL.revokeObjectURL(url)
            }}
            className="px-2 py-1 text-xs border border-[#d4a574]/30 text-[#d4a574] hover:bg-[#d4a574]/10"
          >
            导出CSV
          </button>

          {/* 自动刷新 */}
          <button
            onClick={() => setAutoRefresh(!autoRefresh)}
            className={`px-2 py-1 text-xs border rounded ${
              autoRefresh 
                ? 'bg-[#d4a574]/20 border-[#d4a574] text-[#d4a574]' 
                : 'border-[#d4a574]/30 text-[#a3a3a3]'
            }`}
          >
            {autoRefresh ? '自动刷新中' : '自动刷新'}
          </button>
        </div>
      </div>

      {/* 日志级别统计 */}
      <div className="grid grid-cols-3 gap-4">
        <div className={`p-3 rounded border ${
          theme === 'light' ? 'bg-green-50 border-green-200' : 'bg-green-500/10 border-green-500/30'
        }`}>
          <div className="text-xs text-[#a3a3a3]">INFO</div>
          <div className="text-xl font-mono text-green-500">{levelStats.info}</div>
        </div>
        <div className={`p-3 rounded border ${
          theme === 'light' ? 'bg-yellow-50 border-yellow-200' : 'bg-yellow-500/10 border-yellow-500/30'
        }`}>
          <div className="text-xs text-[#a3a3a3]">WARN</div>
          <div className="text-xl font-mono text-yellow-500">{levelStats.warn}</div>
        </div>
        <div className={`p-3 rounded border ${
          theme === 'light' ? 'bg-red-50 border-red-200' : 'bg-red-500/10 border-red-500/30'
        }`}>
          <div className="text-xs text-[#a3a3a3]">ERROR</div>
          <div className="text-xl font-mono text-red-500">{levelStats.error}</div>
        </div>
      </div>

      {/* 日志列表 */}
      <div 
        ref={logContainerRef}
        className={`rounded-lg overflow-auto max-h-[60vh] font-mono text-xs ${
          theme === 'light' ? 'bg-gray-900' : 'bg-[#0d0d1a]'
        }`}
      >
        {loading ? (
          <div className="p-4 text-[#a3a3a3]">加载中...</div>
        ) : (
          <div className="divide-y divide-[#d4a574]/10">
            {logs.map((log) => (
              <div 
                key={log.id} 
                className="p-2 hover:bg-[#d4a574]/5 flex gap-2"
              >
                <span className="text-[#a3a3a3] flex-shrink-0">
                  {formatTime(log.timestamp)}
                </span>
                <span className={`flex-shrink-0 w-12 ${getLevelColor(log.level)}`}>
                  [{log.level}]
                </span>
                <span className={`${theme === 'light' ? 'text-gray-300' : 'text-[#e5e5e5]'}`}>
                  {log.message}
                </span>
              </div>
            ))}
            
            {logs.length === 0 && (
              <div className="p-4 text-[#a3a3a3] text-center">
                暂无日志
              </div>
            )}
          </div>
        )}
      </div>

      <div className="text-xs text-[#a3a3a3]">
        共 {logs.length} 条日志
      </div>
    </div>
  )
}
