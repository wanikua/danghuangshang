import { useState, useEffect } from "react"
import { useTheme } from "../theme"
import { getAuthToken } from '../auth'

interface BotAccount {
  name: string
  displayName: string
  status: string
  model: string
  sessions: number
  totalTokens: number
}

// 像素小人 SVG 组件
const PixelAvatar = ({ status, dept }: { status: string; dept: string }) => {
  const isOnline = status === 'online'
  const colors: Record<string, string> = {
    'gongbu': '#d4a574', // 工部 - 金色
    'hubu': '#22c55e',   // 户部 - 绿色
    'xingbu': '#ef4444', // 刑部 - 红色
    'bingbu': '#3b82f6', // 兵部 - 蓝色
    'libu': '#f59e0b',   // 吏部 - 橙色
    'libu2': '#8b5cf6',  // 礼部 - 紫色
    'duchayuan': '#14b8a6', // 都察院 - 青色
    'default': '#a3a3a3'
  }
  const color = colors[dept] || colors.default
  
  return (
    <svg width="48" height="48" viewBox="0 0 16 16" className="pixel-art">
      {/* 身体 */}
      <rect x="5" y="6" width="6" height="6" fill={color} />
      {/* 头 */}
      <rect x="4" y="2" width="8" height="5" fill={color} />
      {/* 眼睛 */}
      <rect x="5" y="3" width="2" height="2" fill={isOnline ? '#22c55e' : '#ef4444'} />
      <rect x="9" y="3" width="2" height="2" fill={isOnline ? '#22c55e' : '#ef4444'} />
      {/* 状态指示 */}
      <rect x="6" y="12" width="4" height="2" fill={isOnline ? '#22c55e' : '#6b7280'} />
    </svg>
  )
}

// 像素风格装饰
const PixelDecoration = ({ type }: { type: string }) => {
  if (type === 'computer') {
    return (
      <svg width="32" height="24" viewBox="0 0 16 12" className="pixel-art opacity-60">
        <rect x="1" y="2" width="14" height="8" fill="#4b5563" />
        <rect x="2" y="3" width="12" height="6" fill="#1f2937" />
        <rect x="5" y="10" width="6" height="2" fill="#4b5563" />
        <rect x="3" y="12" width="10" height="1" fill="#6b7280" />
      </svg>
    )
  }
  if (type === 'plant') {
    return (
      <svg width="16" height="24" viewBox="0 0 8 12" className="pixel-art opacity-60">
        <rect x="3" y="8" width="2" height="4" fill="#92400e" />
        <rect x="1" y="2" width="6" height="6" fill="#22c55e" />
        <rect x="2" y="1" width="4" height="2" fill="#16a34a" />
      </svg>
    )
  }
  if (type === 'clock') {
    return (
      <svg width="24" height="24" viewBox="0 0 12 12" className="pixel-art opacity-60">
        <rect x="1" y="1" width="10" height="10" fill="#374151" />
        <rect x="2" y="2" width="8" height="8" fill="#1f2937" />
        <rect x="5" y="2" width="2" height="4" fill="#d4a574" />
        <rect x="5" y="5" width="3" height="2" fill="#d4a574" />
        <rect x="2" y="5" width="1" height="1" fill="#d4a574" />
      </svg>
    )
  }
  return null
}

export default function Office() {
  const [bots, setBots] = useState<BotAccount[]>([])
  const [loading, setLoading] = useState(true)
  const { theme } = useTheme()

  const fetchData = async () => {
    try {
      const res = await fetch('/api/status', {
        headers: { 'Authorization': `Bearer ${getAuthToken()}` }
      })
      if (res.ok) {
        const data = await res.json()
        setBots(data.botAccounts || [])
      }
    } catch (e) {
      console.error('Failed to fetch office data:', e)
    }
    setLoading(false)
  }

  useEffect(() => {
    fetchData()
  }, [])

  const onlineBots = bots.filter(b => b.status === 'online')
  const totalSessions = bots.reduce((s, b) => s + b.sessions, 0)
  const totalTokens = bots.reduce((s, b) => s + b.totalTokens, 0)

  // 格式化 Token
  const formatTokens = (n: number) => {
    if (n >= 1000000) return (n / 1000000).toFixed(1) + 'M'
    if (n >= 1000) return (n / 1000).toFixed(0) + 'K'
    return n.toString()
  }

  if (loading) {
    return <div className="text-[#a3a3a3] p-4">加载中...</div>
  }

  return (
    <div className="space-y-6">
      <h2 className={`text-lg font-medium ${theme === 'light' ? 'text-gray-800' : 'text-[#d4a574]'}`}>
        🏢 像素办公室
      </h2>

      {/* 顶部统计 */}
      <div className="grid grid-cols-3 gap-4">
        <div className="bg-[#1a1a2e] p-4 rounded-lg border-b-2 border-[#d4a574] text-center">
          <div className="text-3xl mb-1">👥</div>
          <div className="text-2xl font-mono text-[#d4a574]">{onlineBots.length}</div>
          <div className="text-xs text-[#a3a3a3]">在线部门</div>
        </div>
        <div className="bg-[#1a1a2e] p-4 rounded-lg border-b-2 border-[#d4a574] text-center">
          <div className="text-3xl mb-1">💬</div>
          <div className="text-2xl font-mono text-[#d4a574]">{totalSessions}</div>
          <div className="text-xs text-[#a3a3a3]">活跃会话</div>
        </div>
        <div className="bg-[#1a1a2e] p-4 rounded-lg border-b-2 border-[#d4a574] text-center">
          <div className="text-3xl mb-1">⚡</div>
          <div className="text-2xl font-mono text-[#d4a574]">{formatTokens(totalTokens)}</div>
          <div className="text-xs text-[#a3a3a3]">今日消耗</div>
        </div>
      </div>

      {/* 像素办公室场景 */}
      <div className={`relative rounded-lg overflow-hidden ${
        theme === 'light' ? 'bg-gray-100' : 'bg-[#0d0d1a]'
      }`} style={{ minHeight: '400px' }}>
        {/* 背景网格 */}
        <div className="absolute inset-0 opacity-10" 
          style={{ 
            backgroundImage: 'linear-gradient(#4b5563 1px, transparent 1px), linear-gradient(90deg, #4b5563 1px, transparent 1px)',
            backgroundSize: '16px 16px'
          }} 
        />
        
        {/* 地板 */}
        <div className="absolute bottom-0 left-0 right-0 h-24 bg-gradient-to-t from-[#1f2937] to-transparent" />
        
        {/* 标题 */}
        <div className="absolute top-4 left-4">
          <h3 className="text-[#d4a574] text-sm font-pixel">🏢 菠萝王朝办公室</h3>
        </div>

        {/* 装饰 - 电脑 */}
        <div className="absolute top-20 left-8">
          <PixelDecoration type="computer" />
        </div>

        {/* 装饰 - 植物 */}
        <div className="absolute top-20 right-8">
          <PixelDecoration type="plant" />
        </div>

        {/* 装饰 - 时钟 */}
        <div className="absolute top-4 right-4">
          <PixelDecoration type="clock" />
        </div>

        {/* 部门工位 - 3x4 网格 */}
        <div className="absolute inset-0 p-8 flex items-center justify-center">
          <div className="grid grid-cols-4 gap-6">
            {bots.slice(0, 8).map((bot) => (
              <div 
                key={bot.name}
                className={`flex flex-col items-center p-2 rounded ${
                  bot.status === 'online' 
                    ? 'bg-[#1f2937]/80' 
                    : 'bg-[#1f2937]/40 opacity-50'
                }`}
              >
                <PixelAvatar status={bot.status} dept={bot.name} />
                <div className="mt-2 text-xs text-center">
                  <div className={`font-medium ${bot.status === 'online' ? 'text-[#d4a574]' : 'text-gray-500'}`}>
                    {bot.displayName}
                  </div>
                  <div className="text-[#a3a3a3]">
                    {bot.sessions} 会话
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* 底部状态栏 */}
        <div className="absolute bottom-0 left-0 right-0 h-8 bg-[#1f2937] border-t border-[#374151] flex items-center justify-between px-4">
          <div className="text-xs text-[#a3a3a3]">
            🕐 {new Date().toLocaleTimeString('zh-CN', { hour: '2-digit', minute: '2-digit' })}
          </div>
          <div className="text-xs text-[#a3a3a3]">
            📊 {bots.length} 部门 · {totalSessions} 会话 · {formatTokens(totalTokens)} Tokens
          </div>
        </div>
      </div>

      {/* 部门详细列表 */}
      <div className={`rounded-lg overflow-hidden ${theme === 'light' ? 'bg-white' : 'bg-[#1a1a2e]'}`}>
        <div className={`grid grid-cols-5 text-xs p-3 border-b ${
          theme === 'light' ? 'bg-gray-100 border-gray-200' : 'bg-[#16213e] border-[#d4a574]/20'
        }`}>
          <div>部门</div>
          <div>状态</div>
          <div>模型</div>
          <div>会话</div>
          <div>Token</div>
        </div>

        {bots.map((bot) => (
          <div 
            key={bot.name}
            className={`grid grid-cols-5 text-xs p-3 border-b ${
              theme === 'light' ? 'border-gray-100' : 'border-[#d4a574]/10'
            }`}
          >
            <div className="font-medium flex items-center gap-2">
              <PixelAvatar status={bot.status} dept={bot.name} />
              <span>{bot.displayName}</span>
            </div>
            <div>
              <span className={`px-2 py-0.5 rounded text-xs ${
                bot.status === 'online' 
                  ? 'bg-green-500/20 text-green-500' 
                  : 'bg-gray-500/20 text-gray-500'
              }`}>
                {bot.status === 'online' ? '🟢 在线' : '🔴 离线'}
              </span>
            </div>
            <div className="text-[#a3a3a3] font-mono">{bot.model}</div>
            <div className="text-[#a3a3a3]">{bot.sessions}</div>
            <div className="font-mono text-[#d4a574]">{formatTokens(bot.totalTokens)}</div>
          </div>
        ))}
      </div>
    </div>
  )
}
