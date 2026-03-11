import { useState, useEffect } from "react"
import { useTheme } from "../theme"
import { getAuthToken } from '../auth'

interface Platform {
  name: string; status: 'connected' | 'disconnected'; channels: number; accounts?: number
}

interface BotChannel {
  id: string; name: string; displayName: string; status: string
  sessions: number; model: string; channel: string
}

export default function Channels() {
  const [platforms, setPlatforms] = useState<Platform[]>([])
  const [botChannels, setBotChannels] = useState<BotChannel[]>([])
  const [loading, setLoading] = useState(true)
  const [selectedPlatform, setSelectedPlatform] = useState('all')
  const { theme } = useTheme()
  const bg = theme === 'light' ? 'bg-white border border-gray-200' : 'bg-[#1a1a2e]'
  const sub = theme === 'light' ? 'text-gray-500' : 'text-[#a3a3a3]'

  const fetchData = async () => {
    setLoading(true)
    try {
      const headers = { Authorization: `Bearer ${getAuthToken()}` }
      const [platformsRes, statusRes] = await Promise.all([
        fetch('/api/platforms', { headers }),
        fetch('/api/status', { headers })
      ])
      
      const platformsData = await platformsRes.json()
      if (platformsData.platforms) setPlatforms(platformsData.platforms)

      const statusData = await statusRes.json()
      const bots = statusData.botAccounts || []
      setBotChannels(bots.map((b: { name: string; displayName: string; status: string; sessions: number; model: string }) => ({
        id: b.name,
        name: b.name,
        displayName: b.displayName || b.name,
        status: b.status,
        sessions: b.sessions || 0,
        model: b.model || '',
        channel: 'Discord'
      })))
    } catch { }
    setLoading(false)
  }

  useEffect(() => { fetchData() }, [])

  const filteredChannels = selectedPlatform === 'all'
    ? botChannels
    : botChannels.filter(c => c.channel === selectedPlatform)

  const onlineCount = botChannels.filter(c => c.status === 'online').length

  if (loading) return <div className={`${sub} p-4 animate-pulse`}>加载中...</div>

  return (
    <div className="space-y-4 sm:space-y-6">
      <div className="flex items-center justify-between">
        <h2 className={`text-lg font-medium ${theme === 'light' ? 'text-gray-800' : 'text-[#d4a574]'}`}>
          📡 频道管理
        </h2>
        <button onClick={fetchData}
          className="px-3 py-1.5 text-xs border border-[#d4a574] text-[#d4a574] hover:bg-[#d4a574]/10 rounded cursor-pointer">
          🔄 刷新
        </button>
      </div>

      {/* 平台概览 */}
      <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
        {platforms.map(p => (
          <div key={p.name} className={`${bg} rounded-lg p-3 sm:p-4 border-l-2 ${
            p.status === 'connected' ? 'border-l-green-500' : 'border-l-gray-500'
          }`}>
            <div className="flex items-center justify-between mb-1">
              <span className="text-sm font-medium">{p.name}</span>
              <span className={`w-2 h-2 rounded-full ${p.status === 'connected' ? 'bg-green-500' : 'bg-red-500'}`} />
            </div>
            <div className={`text-xs ${sub}`}>
              {p.accounts || 0} 账号 · {p.channels} 频道
            </div>
          </div>
        ))}
      </div>

      {/* 统计 */}
      <div className="grid grid-cols-3 gap-3">
        <div className={`${bg} rounded-lg p-3 text-center`}>
          <div className={`text-[10px] uppercase ${sub}`}>总频道</div>
          <div className="font-mono text-xl text-[#d4a574]">{botChannels.length}</div>
        </div>
        <div className={`${bg} rounded-lg p-3 text-center`}>
          <div className={`text-[10px] uppercase ${sub}`}>在线</div>
          <div className="font-mono text-xl text-green-400">{onlineCount}</div>
        </div>
        <div className={`${bg} rounded-lg p-3 text-center`}>
          <div className={`text-[10px] uppercase ${sub}`}>平台</div>
          <div className="font-mono text-xl text-[#d4a574]">{platforms.filter(p => p.status === 'connected').length}</div>
        </div>
      </div>

      {/* 筛选 */}
      <div className="flex gap-2">
        {['all', ...platforms.map(p => p.name)].map(p => (
          <button key={p} onClick={() => setSelectedPlatform(p)}
            className={`px-3 py-1 text-xs rounded border cursor-pointer transition-all ${
              selectedPlatform === p
                ? 'bg-[#d4a574]/20 text-[#d4a574] border-[#d4a574]'
                : `border-[#d4a574]/20 ${sub} hover:border-[#d4a574]/50`
            }`}>
            {p === 'all' ? '全部' : p}
          </button>
        ))}
      </div>

      {/* 频道列表 */}
      <div className={`${bg} rounded-lg overflow-hidden`}>
        <div className={`grid grid-cols-5 text-xs p-3 border-b ${
          theme === 'light' ? 'bg-gray-50 border-gray-200' : 'bg-[#16213e] border-[#d4a574]/20'
        }`}>
          <div>部门名称</div><div>平台</div><div>状态</div><div>会话数</div><div>模型</div>
        </div>
        {filteredChannels.map(ch => (
          <div key={ch.id} className={`grid grid-cols-5 text-xs sm:text-sm p-3 border-b items-center ${
            theme === 'light' ? 'border-gray-100 hover:bg-gray-50' : 'border-[#d4a574]/10 hover:bg-[#16213e]'
          }`}>
            <div className="font-medium text-[#d4a574]">{ch.displayName}</div>
            <div className={sub}>{ch.channel}</div>
            <div>
              <span className={`px-2 py-0.5 text-xs rounded ${
                ch.status === 'online' ? 'bg-green-500/20 text-green-500' : 'bg-gray-500/20 text-gray-500'
              }`}>
                {ch.status === 'online' ? '在线' : '离线'}
              </span>
            </div>
            <div className="font-mono text-[#d4a574]">{ch.sessions}</div>
            <div className={`text-[10px] sm:text-xs truncate ${sub}`}>{ch.model?.replace(/^[^/]+\//, '')}</div>
          </div>
        ))}
        {filteredChannels.length === 0 && (
          <div className={`text-center py-8 ${sub} text-sm`}>暂无频道数据</div>
        )}
      </div>
    </div>
  )
}
