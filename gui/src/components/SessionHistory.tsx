import { useState, useEffect } from "react"
import { useTheme } from "../theme"
import { getAuthToken } from '../auth'

interface Session {
  id: string
  agentId: string
  agentName: string
  channel: string
  updatedAt: number
  messageCount: number
  inputTokens: number
  outputTokens: number
}

interface SessionsResponse {
  sessions: Session[]
  total: number
}

export default function SessionHistory() {
  const [sessions, setSessions] = useState<Session[]>([])
  const [loading, setLoading] = useState(true)
  const { theme } = useTheme()

  const fetchSessions = async () => {
    try {
      const res = await fetch("/api/sessions?limit=15", {
        headers: { 'Authorization': `Bearer ${getAuthToken()}` }
      })
      if (res.ok) {
        const data: SessionsResponse = await res.json()
        setSessions(data.sessions)
      }
    } catch (e) {
      console.error('Failed to fetch sessions:', e)
    }
    setLoading(false)
  }

  useEffect(() => {
    fetchSessions()
  }, [])

  const formatTime = (ts: number) => {
    if (!ts) return '未知'
    const date = new Date(ts)
    const now = new Date()
    const diff = now.getTime() - date.getTime()
    const hours = Math.floor(diff / (1000 * 60 * 60))
    const days = Math.floor(hours / 24)
    if (days > 0) return `${days}天前`
    if (hours > 0) return `${hours}小时前`
    return '刚刚'
  }

  if (loading) {
    return <div className="text-xs text-[#a3a3a3]">加载中...</div>
  }

  return (
    <div className="bg-card rounded-lg p-4">
      <h3 className={`text-sm font-medium mb-3 ${theme === 'light' ? 'text-gray-700' : 'text-[#d4a574]'}`}>
        最近会话
      </h3>
      <div className="space-y-2 max-h-64 overflow-y-auto">
        {sessions.slice(0, 10).map((session) => (
          <div 
            key={session.id}
            className={`flex items-center justify-between text-xs p-2 rounded ${
              theme === 'light' ? 'bg-gray-100' : 'bg-[#16213e]'
            }`}
          >
            <div className="flex items-center gap-2">
              <span className="text-[#d4a574]">{session.agentName}</span>
              <span className={theme === 'light' ? 'text-gray-500' : 'text-[#a3a3a3]'}>
                {session.channel}
              </span>
            </div>
            <div className="flex items-center gap-3">
              <span className={theme === 'light' ? 'text-gray-500' : 'text-[#a3a3a3]'}>
                {formatTime(session.updatedAt)}
              </span>
              <span className="text-[#d4a574]">
                {session.inputTokens + session.outputTokens > 0 
                  ? `${((session.inputTokens + session.outputTokens) / 1000).toFixed(1)}K`
                  : '-'}
              </span>
            </div>
          </div>
        ))}
      </div>
    </div>
  )
}
