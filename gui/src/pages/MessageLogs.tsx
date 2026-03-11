import { useState, useEffect } from "react"
import type { SystemStatus } from "../types"
import { useTheme } from "../theme"
import { getAuthToken } from '../auth'

interface Props { data: SystemStatus }

interface LogEntry {
  id: number; timestamp: string; level: string; message: string; source?: string
}

const PAGE_SIZE = 50

export default function MessageLogs({ data }: Props) {
  const { theme } = useTheme()
  const [logs, setLogs] = useState<LogEntry[]>([])
  const [loading, setLoading] = useState(true)
  const [search, setSearch] = useState("")
  const [levelFilter, setLevelFilter] = useState("ALL")
  const [page, setPage] = useState(0)
  const bg = theme === 'light' ? 'bg-white border border-gray-200' : 'bg-[#1a1a2e]'
  const sub = theme === 'light' ? 'text-gray-500' : 'text-[#a3a3a3]'

  const fetchLogs = async () => {
    setLoading(true)
    try {
      const params = new URLSearchParams({ limit: '500' })
      if (levelFilter !== 'ALL') params.set('level', levelFilter)
      if (search.trim()) params.set('search', search.trim())

      // Try /api/logs/list first (has filtering), fallback to /api/logs
      let allLogs: LogEntry[] = []
      try {
        const r = await fetch(`/api/logs/list?${params}`, { headers: { Authorization: `Bearer ${getAuthToken()}` } })
        if (r.ok) {
          const d = await r.json()
          allLogs = d.logs || []
        }
      } catch { /* fallback */ }

      if (allLogs.length === 0) {
        // Fallback to /api/logs
        const r = await fetch(`/api/logs?limit=500`, { headers: { Authorization: `Bearer ${getAuthToken()}` } })
        const d = await r.json()
        allLogs = d.logs || []
      }

      // Also merge data.logs from props if available
      if (data.logs && data.logs.length > 0 && allLogs.length === 0) {
        allLogs = data.logs.map((l, i) => ({ ...l, id: i }))
      }

      setLogs(allLogs)
    } catch { }
    setLoading(false)
  }

  useEffect(() => { fetchLogs() }, [levelFilter])

  // Client-side search filtering
  const filtered = logs.filter(log => {
    if (!search.trim()) return true
    const q = search.toLowerCase()
    return log.message?.toLowerCase().includes(q) || log.source?.toLowerCase().includes(q)
  })

  const totalPages = Math.max(1, Math.ceil(filtered.length / PAGE_SIZE))
  const currentPage = Math.min(page, totalPages - 1)
  const paginated = filtered.slice(currentPage * PAGE_SIZE, (currentPage + 1) * PAGE_SIZE)

  const levelColor = (level: string) => {
    switch (level?.toLowerCase()) {
      case "error": return "text-[#ef4444] bg-[#ef4444]/10"
      case "warn": case "warning": return "text-[#eab308] bg-[#eab308]/10"
      case "info": return "text-[#22c55e] bg-[#22c55e]/10"
      case "debug": return "text-[#3b82f6] bg-[#3b82f6]/10"
      default: return `${sub} bg-gray-500/10`
    }
  }

  // Level counts
  const counts = { ALL: logs.length, INFO: 0, WARN: 0, ERROR: 0, DEBUG: 0 }
  for (const log of logs) {
    const l = log.level?.toUpperCase()
    if (l === 'INFO') counts.INFO++
    else if (l === 'WARN' || l === 'WARNING') counts.WARN++
    else if (l === 'ERROR') counts.ERROR++
    else if (l === 'DEBUG') counts.DEBUG++
  }

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h2 className={`text-lg font-medium ${theme === 'light' ? 'text-gray-800' : 'text-[#d4a574]'}`}>
          📋 系统日志
        </h2>
        <button onClick={fetchLogs} disabled={loading}
          className="px-3 py-1.5 text-xs border border-[#d4a574] text-[#d4a574] hover:bg-[#d4a574]/10 rounded cursor-pointer">
          {loading ? '⏳' : '🔄 刷新'}
        </button>
      </div>

      {/* 筛选栏 */}
      <div className="flex flex-wrap gap-2">
        {/* 级别筛选 */}
        {(['ALL', 'INFO', 'WARN', 'ERROR', 'DEBUG'] as const).map(level => (
          <button key={level} onClick={() => { setLevelFilter(level); setPage(0) }}
            className={`px-2.5 py-1.5 text-[10px] sm:text-xs rounded border cursor-pointer transition-all ${
              levelFilter === level
                ? 'bg-[#d4a574]/20 text-[#d4a574] border-[#d4a574]'
                : `border-[#d4a574]/20 ${sub} hover:border-[#d4a574]/50`
            }`}>
            {level} ({counts[level]})
          </button>
        ))}
        {/* 搜索 */}
        <input type="text" value={search}
          onChange={e => { setSearch(e.target.value); setPage(0) }}
          onKeyDown={e => e.key === 'Enter' && fetchLogs()}
          placeholder="搜索日志..."
          className={`flex-1 min-w-[120px] px-3 py-1.5 text-xs rounded border ${
            theme === 'light' ? 'bg-white border-gray-300' : 'bg-[#0d0d1a] border-[#d4a574]/20'
          } focus:outline-none focus:border-[#d4a574]`} />
      </div>

      {/* 日志列表 */}
      <div className={`${bg} rounded-lg overflow-hidden divide-y ${theme === 'light' ? 'divide-gray-100' : 'divide-[#d4a574]/10'}`}>
        {loading && paginated.length === 0 ? (
          <div className={`px-4 py-8 text-center ${sub} text-sm animate-pulse`}>加载中...</div>
        ) : paginated.length === 0 ? (
          <div className={`px-4 py-8 text-center ${sub} text-sm`}>暂无日志</div>
        ) : (
          paginated.map((log, i) => (
            <div key={`${currentPage}-${i}`}
              className={`px-3 sm:px-4 py-2 sm:py-2.5 text-xs sm:text-sm ${theme === 'light' ? 'hover:bg-gray-50' : 'hover:bg-[#16213e]'} transition-all`}>
              <div className="flex items-start gap-2 sm:gap-3">
                <span className={`font-mono text-[10px] sm:text-xs whitespace-nowrap flex-shrink-0 ${sub}`}>
                  {log.timestamp}
                </span>
                <span className={`text-[10px] sm:text-xs uppercase font-mono px-1.5 py-0.5 rounded flex-shrink-0 ${levelColor(log.level)}`}>
                  {log.level}
                </span>
                {log.source && (
                  <span className="text-[10px] sm:text-xs text-[#d4a574] font-mono flex-shrink-0">[{log.source}]</span>
                )}
                <span className={`break-all ${theme === 'light' ? 'text-gray-700' : 'text-[#e5e5e5]'}`}>{log.message}</span>
              </div>
            </div>
          ))
        )}
      </div>

      {/* 分页 */}
      {totalPages > 1 && (
        <div className="flex items-center justify-between text-xs sm:text-sm">
          <span className={sub}>
            {filtered.length} 条记录，第 <span className="font-mono text-[#d4a574]">{currentPage + 1}</span>/<span className="font-mono text-[#d4a574]">{totalPages}</span> 页
          </span>
          <div className="flex gap-2">
            <button onClick={() => setPage(Math.max(0, currentPage - 1))} disabled={currentPage === 0}
              className={`px-3 py-1 ${bg} border border-[#d4a574]/30 ${sub} hover:text-[#d4a574] disabled:opacity-30 cursor-pointer rounded`}>
              上一页
            </button>
            <button onClick={() => setPage(Math.min(totalPages - 1, currentPage + 1))} disabled={currentPage >= totalPages - 1}
              className={`px-3 py-1 ${bg} border border-[#d4a574]/30 ${sub} hover:text-[#d4a574] disabled:opacity-30 cursor-pointer rounded`}>
              下一页
            </button>
          </div>
        </div>
      )}
    </div>
  )
}
