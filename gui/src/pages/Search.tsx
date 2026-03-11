import { useState } from "react"
import { useTheme } from "../theme"
import { getAuthToken } from '../auth'

type SearchType = 'all' | 'logs' | 'messages' | 'sessions'

interface SearchResult {
  type: 'log' | 'message' | 'session'
  id: string
  content: string
  timestamp: string
  source?: string
}

export default function Search() {
  const [query, setQuery] = useState('')
  const [searchType, setSearchType] = useState<SearchType>('all')
  const [results, setResults] = useState<SearchResult[]>([])
  const [loading, setLoading] = useState(false)
  const [searched, setSearched] = useState(false)
  const { theme } = useTheme()

  const handleSearch = async () => {
    if (!query.trim()) return
    
    setLoading(true)
    setSearched(true)
    const allResults: SearchResult[] = []

    try {
      // 搜索日志
      if (searchType === 'all' || searchType === 'logs') {
        try {
          const logsRes = await fetch('/api/logs?limit=200', {
            headers: { 'Authorization': `Bearer ${getAuthToken()}` }
          })
          const logsData = await logsRes.json()
          const logs = logsData.logs || []
          
          for (const log of logs) {
            if (log.message?.toLowerCase().includes(query.toLowerCase())) {
              allResults.push({
                type: 'log',
                id: String(log.id),
                content: log.message,
                timestamp: log.timestamp,
                source: log.level
              })
            }
          }
        } catch (e) { /* ignore */ }
      }

      // 搜索消息
      if (searchType === 'all' || searchType === 'messages') {
        try {
          const msgsRes = await fetch('/api/messages?limit=100', {
            headers: { 'Authorization': `Bearer ${getAuthToken()}` }
          })
          const msgsData = await msgsRes.json()
          const messages = msgsData.messages || []
          
          for (const msg of messages) {
            if (msg.content?.toLowerCase().includes(query.toLowerCase())) {
              allResults.push({
                type: 'message',
                id: msg.id,
                content: msg.content,
                timestamp: msg.timestamp,
                source: msg.channel
              })
            }
          }
        } catch (e) { /* ignore */ }
      }

      // 搜索会话
      if (searchType === 'all' || searchType === 'sessions') {
        try {
          const sessionsRes = await fetch('/api/sessions?limit=50', {
            headers: { 'Authorization': `Bearer ${getAuthToken()}` }
          })
          const sessionsData = await sessionsRes.json()
          const sessions = sessionsData.sessions || []
          
          for (const session of sessions) {
            const searchableText = `${session.agentName} ${session.channel}`.toLowerCase()
            if (searchableText.includes(query.toLowerCase())) {
              allResults.push({
                type: 'session',
                id: session.id,
                content: `${session.agentName} - ${session.channel}`,
                timestamp: new Date(session.updatedAt).toISOString(),
                source: session.channel
              })
            }
          }
        } catch (e) { /* ignore */ }
      }

      // 按时间排序
      allResults.sort((a, b) => new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime())
      
      // 限制结果数量
      setResults(allResults.slice(0, 100))
    } catch (e) {
      console.error('Search error:', e)
    }

    setLoading(false)
  }

  const typeLabels: Record<SearchType, string> = {
    all: '全部',
    logs: '日志',
    messages: '消息',
    sessions: '会话'
  }

  const typeIcons: Record<string, string> = {
    log: '📋',
    message: '💬',
    session: '🔗'
  }

  const formatTime = (ts: string) => {
    try {
      return new Date(ts).toLocaleString('zh-CN')
    } catch {
      return ts
    }
  }

  return (
    <div className="space-y-6">
      <h2 className={`text-lg font-medium ${theme === 'light' ? 'text-gray-800' : 'text-[#d4a574]'}`}>
        全局搜索
      </h2>

      {/* 搜索框 */}
      <div className={`p-4 rounded-lg border-b-2 ${theme === 'light' ? 'bg-white border-gray-200' : 'bg-[#1a1a2e] border-[#d4a574]'}`}>
        <div className="flex gap-2 mb-4">
          <input
            type="text"
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            onKeyDown={(e) => e.key === 'Enter' && handleSearch()}
            placeholder="输入搜索关键词..."
            className={`flex-1 px-4 py-2 rounded border ${
              theme === 'light' 
                ? 'bg-white border-gray-300' 
                : 'bg-[#0d0d1a] border-[#d4a574]/30'
            } text-[#e5e5e5] placeholder-[#a3a3a3]`}
          />
          <button
            onClick={handleSearch}
            disabled={loading || !query.trim()}
            className="px-6 py-2 bg-[#d4a574] text-[#0d0d1a] font-medium rounded hover:bg-[#c49464] disabled:opacity-50"
          >
            {loading ? '搜索中...' : '搜索'}
          </button>
        </div>

        {/* 类型筛选 */}
        <div className="flex gap-2">
          {(Object.keys(typeLabels) as SearchType[]).map((type) => (
            <button
              key={type}
              onClick={() => setSearchType(type)}
              className={`px-3 py-1 text-xs rounded ${
                searchType === type
                  ? 'bg-[#d4a574]/20 text-[#d4a574] border border-[#d4a574]'
                  : 'border border-[#d4a574]/30 text-[#a3a3a3] hover:border-[#d4a574]'
              }`}
            >
              {typeLabels[type]}
            </button>
          ))}
        </div>
      </div>

      {/* 结果统计 */}
      {searched && (
        <div className="text-sm text-[#a3a3a3]">
          找到 {results.length} 条结果
          {searchType !== 'all' && ` (${typeLabels[searchType]})`}
        </div>
      )}

      {/* 搜索结果 */}
      {results.length > 0 && (
        <div className="space-y-2">
          {results.map((result, idx) => (
            <div
              key={`${result.type}-${result.id}-${idx}`}
              className={`p-3 rounded border ${
                theme === 'light' 
                  ? 'bg-white border-gray-200 hover:shadow' 
                  : 'bg-[#1a1a2e] border-[#d4a574]/20 hover:border-[#d4a574]/40'
              }`}
            >
              <div className="flex items-center gap-2 mb-1">
                <span className="text-sm">{typeIcons[result.type]}</span>
                <span className={`text-xs px-2 py-0.5 rounded ${
                  result.type === 'log' ? 'bg-blue-500/20 text-blue-500' :
                  result.type === 'message' ? 'bg-green-500/20 text-green-500' :
                  'bg-purple-500/20 text-purple-500'
                }`}>
                  {result.type === 'log' ? '日志' : result.type === 'message' ? '消息' : '会话'}
                </span>
                <span className="text-xs text-[#a3a3a3]">
                  {formatTime(result.timestamp)}
                </span>
                {result.source && (
                  <span className="text-xs text-[#a3a3a3]">
                    · {result.source}
                  </span>
                )}
              </div>
              <div className={`text-sm ${theme === 'light' ? 'text-gray-700' : 'text-[#e5e5e5]'}`}>
                {result.content}
              </div>
            </div>
          ))}
        </div>
      )}

      {/* 无结果提示 */}
      {searched && results.length === 0 && !loading && (
        <div className="text-center text-[#a3a3a3] py-8">
          未找到匹配结果
        </div>
      )}

      {/* 初始提示 */}
      {!searched && (
        <div className="text-center text-[#a3a3a3] py-8">
          输入关键词进行全局搜索
        </div>
      )}
    </div>
  )
}
