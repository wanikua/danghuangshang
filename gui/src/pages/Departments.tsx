import { useState, useEffect } from "react"
import type { SystemStatus, BotAccount } from "../types"
import { useTheme } from "../theme"
import { getAuthToken } from '../auth'

interface Props { data: SystemStatus }

function fmt(n: number): string {
  if (n >= 1_000_000) return (n / 1_000_000).toFixed(2) + "M"
  if (n >= 1_000) return (n / 1_000).toFixed(1) + "K"
  return n.toString()
}

function relTime(ts: number) {
  if (!ts) return '未知'
  const diff = Date.now() - ts
  const m = Math.floor(diff / 60000), h = Math.floor(m / 60), d = Math.floor(h / 24)
  if (d > 0) return `${d}天前`
  if (h > 0) return `${h}小时前`
  if (m > 0) return `${m}分钟前`
  return '刚刚'
}

interface DeptActivity {
  agentId: string; updatedAt: number; messageCount: number; channel: string
}

interface RecentMsg {
  id: string; role: string; content: string; timestamp: string
}

export default function Departments({ data }: Props) {
  const { theme } = useTheme()
  const [expandedBot, setExpandedBot] = useState<string | null>(null)
  const [activities, setActivities] = useState<Record<string, DeptActivity>>({})
  const [recentMsgs, setRecentMsgs] = useState<Record<string, RecentMsg[]>>({})
  const [msgsLoading, setMsgsLoading] = useState<string | null>(null)
  const bg = theme === 'light' ? 'bg-white border border-gray-200' : 'bg-[#1a1a2e]'
  const sub = theme === 'light' ? 'text-gray-500' : 'text-[#a3a3a3]'

  // Fetch activity data from sessions
  useEffect(() => {
    fetch('/api/sessions?limit=100', { headers: { Authorization: `Bearer ${getAuthToken()}` } })
      .then(r => r.json())
      .then(d => {
        const map: Record<string, DeptActivity> = {}
        for (const s of (d.sessions || [])) {
          const id = s.agentId
          if (!map[id] || s.updatedAt > map[id].updatedAt) {
            map[id] = { agentId: id, updatedAt: s.updatedAt, messageCount: s.messageCount, channel: s.channel }
          }
        }
        setActivities(map)
      })
      .catch(() => {})
  }, [])

  const toggleBot = async (botName: string) => {
    if (expandedBot === botName) {
      setExpandedBot(null)
      return
    }
    setExpandedBot(botName)
    
    if (!recentMsgs[botName]) {
      setMsgsLoading(botName)
      try {
        // Find the session ID for this bot
        const r = await fetch('/api/sessions?limit=100', { headers: { Authorization: `Bearer ${getAuthToken()}` } })
        const d = await r.json()
        const session = (d.sessions || []).find((s: DeptActivity & { id: string }) => s.agentId === botName)
        if (session) {
          const mr = await fetch(`/api/sessions/${encodeURIComponent(session.id)}/messages?limit=6`, {
            headers: { Authorization: `Bearer ${getAuthToken()}` }
          })
          const md = await mr.json()
          setRecentMsgs(prev => ({ ...prev, [botName]: md.messages || [] }))
        } else {
          setRecentMsgs(prev => ({ ...prev, [botName]: [] }))
        }
      } catch { setRecentMsgs(prev => ({ ...prev, [botName]: [] })) }
      setMsgsLoading(null)
    }
  }

  const statusText = (status: string) => {
    switch (status) {
      case 'online': return '在线'
      case 'offline': return '离线'
      case 'busy': return '忙碌'
      default: return status
    }
  }

  const statusStyle = (status: string) => {
    switch (status) {
      case 'online': return 'bg-green-500/20 text-green-500'
      case 'offline': return 'bg-gray-500/20 text-gray-500'
      case 'busy': return 'bg-yellow-500/20 text-yellow-500'
      default: return 'bg-gray-500/20 text-gray-500'
    }
  }

  const onlineCount = data.botAccounts.filter(b => b.status === 'online').length
  const totalTokens = data.botAccounts.reduce((s, b) => s + b.totalTokens, 0)
  const totalSessions = data.botAccounts.reduce((s, b) => s + b.sessions, 0)

  return (
    <div className="space-y-4 sm:space-y-6">
      <h2 className={`text-lg font-medium ${theme === 'light' ? 'text-gray-800' : 'text-[#d4a574]'}`}>
        🏛️ 部门管理
      </h2>

      {/* 统计 */}
      <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
        {[
          { l: '总部门', v: data.botAccounts.length, icon: '🏛️' },
          { l: '在线', v: onlineCount, icon: '🟢' },
          { l: '总会话', v: totalSessions, icon: '💬' },
          { l: '总Token', v: fmt(totalTokens), icon: '🔥' },
        ].map(c => (
          <div key={c.l} className={`${bg} rounded-lg p-3`}>
            <div className={`text-[10px] uppercase ${sub}`}>{c.icon} {c.l}</div>
            <div className="font-mono text-lg sm:text-xl text-[#d4a574]">{c.v}</div>
          </div>
        ))}
      </div>

      {/* 部门卡片列表 */}
      <div className="space-y-2">
        {data.botAccounts.map((bot: BotAccount) => {
          const activity = activities[bot.name]
          const isExpanded = expandedBot === bot.name
          const msgs = recentMsgs[bot.name]
          
          return (
            <div key={bot.name} className={`${bg} rounded-lg overflow-hidden`}>
              {/* 主行 */}
              <button onClick={() => toggleBot(bot.name)}
                className={`w-full p-3 sm:p-4 text-left cursor-pointer transition-all ${
                  theme === 'light' ? 'hover:bg-gray-50' : 'hover:bg-[#16213e]'
                }`}>
                <div className="flex items-center justify-between mb-1">
                  <div className="flex items-center gap-2 sm:gap-3">
                    <span className={`w-2 h-2 rounded-full flex-shrink-0 ${
                      bot.status === 'online' ? 'bg-green-500' : 'bg-red-500'
                    }`} />
                    <span className="text-sm sm:text-base font-medium">{bot.displayName || bot.name}</span>
                    <span className={`text-[10px] px-1.5 py-0.5 rounded ${statusStyle(bot.status)}`}>
                      {statusText(bot.status)}
                    </span>
                  </div>
                  <span className={`text-xs ${sub} transform transition-transform ${isExpanded ? 'rotate-180' : ''}`}>
                    ▼
                  </span>
                </div>
                <div className="flex flex-wrap items-center gap-3 sm:gap-4 text-[10px] sm:text-xs">
                  <span className={sub}>💬 {bot.sessions} 会话</span>
                  <span className="text-[#d4a574] font-mono">🔥 {fmt(bot.totalTokens)}</span>
                  <span className={sub}>📥 {fmt(bot.inputTokens)} / 📤 {fmt(bot.outputTokens)}</span>
                  {activity && (
                    <span className={sub}>🕐 {relTime(activity.updatedAt)}</span>
                  )}
                </div>
              </button>

              {/* 展开详情 */}
              {isExpanded && (
                <div className={`border-t p-3 sm:p-4 ${theme === 'light' ? 'border-gray-200 bg-gray-50' : 'border-[#d4a574]/10 bg-[#16213e]'}`}>
                  {/* 详细信息 */}
                  <div className="grid grid-cols-2 sm:grid-cols-3 gap-3 mb-4 text-xs">
                    <div><span className={sub}>内部名称: </span><span className="font-mono">{bot.name}</span></div>
                    <div><span className={sub}>模型: </span><span className="font-mono">{bot.model?.replace(/^[^/]+\//, '')}</span></div>
                    <div><span className={sub}>输入Token: </span><span className="font-mono text-[#d4a574]">{bot.inputTokens.toLocaleString()}</span></div>
                    <div><span className={sub}>输出Token: </span><span className="font-mono text-[#d4a574]">{bot.outputTokens.toLocaleString()}</span></div>
                    <div><span className={sub}>总Token: </span><span className="font-mono text-[#d4a574]">{bot.totalTokens.toLocaleString()}</span></div>
                    {activity && <div><span className={sub}>最近活跃: </span><span>{relTime(activity.updatedAt)}</span></div>}
                  </div>

                  {/* 最近消息 */}
                  <div>
                    <h4 className={`text-xs font-medium mb-2 ${sub}`}>📜 最近消息</h4>
                    {msgsLoading === bot.name ? (
                      <div className={`text-xs ${sub} animate-pulse py-2`}>加载中...</div>
                    ) : msgs && msgs.length > 0 ? (
                      <div className="space-y-1.5 max-h-48 overflow-auto">
                        {msgs.map((msg, i) => (
                          <div key={msg.id || i} className={`p-2 rounded text-xs ${
                            theme === 'light' ? 'bg-white' : 'bg-[#0d0d1a]'
                          }`}>
                            <div className="flex items-center gap-2 mb-0.5">
                              <span className={`text-[10px] px-1 py-0.5 rounded ${
                                msg.role === 'user' ? 'bg-blue-500/20 text-blue-400' : 'bg-green-500/20 text-green-400'
                              }`}>{msg.role === 'user' ? '用户' : '助手'}</span>
                              {msg.timestamp && <span className={`text-[10px] ${sub}`}>{new Date(msg.timestamp).toLocaleString('zh-CN')}</span>}
                            </div>
                            <div className="break-words whitespace-pre-wrap leading-relaxed">
                              {msg.content?.substring(0, 200)}{msg.content && msg.content.length > 200 ? '...' : ''}
                            </div>
                          </div>
                        ))}
                      </div>
                    ) : (
                      <div className={`text-xs ${sub} py-2`}>暂无消息记录</div>
                    )}
                  </div>
                </div>
              )}
            </div>
          )
        })}
      </div>
    </div>
  )
}
