import { useState, useEffect, useRef } from "react"
import { useTheme } from "../theme"
import { getAuthToken } from '../auth'

interface Bot {
  id: string; name: string; displayName: string; model: string; hasToken: boolean
}

interface DiscordChannel {
  id: string; name: string; parentId?: string; position?: number
}

interface Category {
  id: string; name: string; position?: number
}

const COLORS: Record<string, { bg: string; hat: string }> = {
  main:       { bg: '#d4a574', hat: '#b8894d' },
  neige:      { bg: '#ef4444', hat: '#b91c1c' },
  duchayuan:  { bg: '#22c55e', hat: '#15803d' },
  gongbu:     { bg: '#3b82f6', hat: '#1d4ed8' },
  hubu:       { bg: '#eab308', hat: '#a16207' },
  bingbu:     { bg: '#ef4444', hat: '#991b1b' },
  libu2:      { bg: '#ec4899', hat: '#be185d' },
  xingbu:     { bg: '#8b5cf6', hat: '#6d28d9' },
  libu:       { bg: '#06b6d4', hat: '#0e7490' },
  neiwufu:    { bg: '#f97316', hat: '#c2410c' },
  hanlinyuan: { bg: '#14b8a6', hat: '#0f766e' },
  taiyiyuan:  { bg: '#f472b6', hat: '#db2777' },
  guozijian:  { bg: '#a78bfa', hat: '#7c3aed' },
  yushanfang: { bg: '#fbbf24', hat: '#b45309' },
}

function PixelPerson({ bot, selected, online, onClick, rank }: {
  bot: Bot; selected: boolean; online: boolean; onClick: () => void; rank?: 'emperor' | 'minister' | 'official'
}) {
  const c = COLORS[bot.id] || { bg: '#888', hat: '#666' }
  const size = rank === 'emperor' ? 'scale-125' : rank === 'minister' ? 'scale-110' : ''
  
  return (
    <button
      onClick={onClick}
      className={`group flex flex-col items-center gap-1 p-1.5 sm:p-2 rounded-lg transition-all cursor-pointer relative
        ${selected ? 'bg-[#d4a574]/20 ring-2 ring-[#d4a574] shadow-lg shadow-[#d4a574]/20' : 'hover:bg-white/5'}
        ${!online ? 'opacity-30 grayscale' : ''}`}
    >
      {/* 选中光环 */}
      {selected && (
        <div className="absolute -inset-0.5 rounded-lg bg-[#d4a574]/10 animate-pulse" />
      )}
      
      <div className={`relative ${size} transition-transform group-hover:scale-110`}>
        {/* 官帽 */}
        <div className="flex justify-center">
          <div className="w-8 h-1.5 rounded-t-sm" style={{ backgroundColor: c.hat }} />
        </div>
        <div className="flex justify-center -mt-px">
          <div className="w-5 h-1" style={{ backgroundColor: c.hat, filter: 'brightness(1.2)' }} />
        </div>
        
        {/* 头 */}
        <div className="flex justify-center">
          <div className="w-6 h-5 rounded-sm relative" style={{ backgroundColor: '#fcd9b6' }}>
            {/* 眼 */}
            <div className="absolute top-1.5 left-1 w-1 h-1 rounded-full bg-[#1a1a2e]" />
            <div className="absolute top-1.5 right-1 w-1 h-1 rounded-full bg-[#1a1a2e]" />
            {/* 嘴 */}
            <div className="absolute bottom-1 left-1/2 -translate-x-1/2 w-2 h-0.5 rounded-full bg-[#d4956b]" />
          </div>
        </div>
        
        {/* 身 */}
        <div className="flex justify-center -mt-px">
          <div className="w-8 h-6 rounded-b-sm relative overflow-hidden" style={{ backgroundColor: c.bg }}>
            {/* 腰带 */}
            <div className="absolute top-0 left-0 right-0 h-1" style={{ backgroundColor: c.hat }} />
            {/* 衣襟 */}
            <div className="absolute top-1 left-1/2 -translate-x-1/2 w-0.5 h-5" style={{ backgroundColor: c.hat }} />
          </div>
        </div>

        {/* 在线状态 */}
        <div className={`absolute -top-1 -right-1 w-2.5 h-2.5 rounded-full border-2 border-[#0d0d1a] z-10
          ${online ? 'bg-green-400 shadow-sm shadow-green-400/50' : 'bg-gray-600'}`} />
      </div>
      
      {/* 名字 */}
      <span className={`text-[9px] sm:text-[10px] leading-tight text-center w-full truncate
        ${selected ? 'text-[#d4a574] font-bold' : online ? 'text-[#e5e5e5]' : 'text-[#666]'}`}>
        {bot.displayName}
      </span>
    </button>
  )
}

interface ChannelMessage {
  id: string; author: string; content: string; timestamp: string; avatarColor?: string
}

export default function Court() {
  const { theme } = useTheme()
  const [bots, setBots] = useState<Bot[]>([])
  const [selectedBot, setSelectedBot] = useState<string | null>(null)
  const [command, setCommand] = useState('')
  const [sending, setSending] = useState(false)
  const [messages, setMessages] = useState<{ bot: string; text: string; time: string; ok: boolean; channel?: string }[]>([])
  const [channelMessages, setChannelMessages] = useState<ChannelMessage[]>([])
  const [loadingMessages, setLoadingMessages] = useState(false)
  const [discordChannels, setDiscordChannels] = useState<DiscordChannel[]>([])
  const [categories, setCategories] = useState<Category[]>([])
  const [selectedChannel, setSelectedChannel] = useState<string>('')
  const [botUserIds, setBotUserIds] = useState<Record<string, string>>({})
  const [senderName, setSenderName] = useState(() => localStorage.getItem('court_sender_name') || '皇上')
  const logRef = useRef<HTMLDivElement>(null)
  const msgRef = useRef<HTMLDivElement>(null)
  const bg = theme === 'light' ? 'bg-white border border-gray-200' : 'bg-[#1a1a2e]'
  const sub = theme === 'light' ? 'text-gray-500' : 'text-[#a3a3a3]'

  const activeChannel = selectedChannel || discordChannels[0]?.id || ''

  const fetchChannelMessages = async () => {
    if (!activeChannel) return
    setLoadingMessages(true)
    try {
      const r = await fetch(`/api/channel-messages?channel=${activeChannel}&limit=15`, {
        headers: { Authorization: `Bearer ${getAuthToken()}` }
      })
      const d = await r.json()
      setChannelMessages(d.messages || [])
      setTimeout(() => msgRef.current?.scrollTo(0, msgRef.current.scrollHeight), 100)
    } catch { /* ignore */ }
    setLoadingMessages(false)
  }

  useEffect(() => {
    // 加载 bots
    fetch('/api/bots', { headers: { Authorization: `Bearer ${getAuthToken()}` } })
      .then(r => r.json()).then(d => setBots(d.bots || [])).catch(() => {})
    // 加载频道列表
    fetch('/api/discord-channels', { headers: { Authorization: `Bearer ${getAuthToken()}` } })
      .then(r => r.json()).then(d => {
        const channels = d.channels || []
        setDiscordChannels(channels)
        setCategories(d.categories || [])
        // 自动选中第一个频道，避免 select value 不匹配
        if (channels.length > 0 && !selectedChannel) {
          setSelectedChannel(channels[0].id)
        }
      }).catch(() => {})
    // 加载 bot user IDs（用于正确 @mention）
    fetch('/api/bot-user-ids', { headers: { Authorization: `Bearer ${getAuthToken()}` } })
      .then(r => r.json()).then(d => setBotUserIds(d.botUserIds || {})).catch(() => {})
  }, [])

  // 频道变化时刷新消息
  useEffect(() => {
    if (!activeChannel) return
    fetchChannelMessages()
    const interval = setInterval(fetchChannelMessages, 15000)
    return () => clearInterval(interval)
  }, [activeChannel])

  const sendCommand = async () => {
    if (!command.trim() || !activeChannel) return
    const target = selectedBot || 'main'
    const botName = bots.find(b => b.id === target)?.displayName || target
    const channelName = discordChannels.find(c => c.id === activeChannel)?.name || activeChannel
    const mentionUserId = target !== 'main' ? botUserIds[target] : undefined
    setSending(true)
    try {
      const r = await fetch('/api/command', {
        method: 'POST',
        headers: { Authorization: `Bearer ${getAuthToken()}`, 'Content-Type': 'application/json' },
        body: JSON.stringify({
          channel: activeChannel,
          message: command,
          botId: target,
          mentionUserId,
          username: senderName || '皇上'
        })
      })
      const d = await r.json()
      setMessages(prev => [...prev, {
        bot: botName, text: command,
        time: new Date().toLocaleTimeString('zh-CN', { hour: '2-digit', minute: '2-digit' }),
        ok: d.success,
        channel: channelName
      }])
      if (d.success) {
        setCommand('')
        setTimeout(fetchChannelMessages, 1500)
      }
    } catch {
      setMessages(prev => [...prev, { bot: botName, text: command, time: new Date().toLocaleTimeString('zh-CN'), ok: false, channel: channelName }])
    }
    setSending(false)
    setTimeout(() => logRef.current?.scrollTo(0, logRef.current.scrollHeight), 100)
  }

  const core = bots.filter(b => ['main', 'neige', 'duchayuan'].includes(b.id))
  const liubu = bots.filter(b => ['gongbu', 'hubu', 'bingbu', 'libu2', 'xingbu', 'libu'].includes(b.id))
  const others = bots.filter(b => !['main', 'neige', 'duchayuan', 'gongbu', 'hubu', 'bingbu', 'libu2', 'xingbu', 'libu'].includes(b.id))

  return (
    <div className="space-y-4">
      {/* 朝堂 */}
      <div className="rounded-lg overflow-hidden shadow-2xl">
        {/* 匾额 */}
        <div className="relative">
          <div className="bg-gradient-to-b from-[#8b0000] via-[#6b0000] to-[#4a0000] p-4 text-center border-b-4 border-[#ffd700]/30">
            {/* 装饰柱 */}
            <div className="absolute left-2 sm:left-4 top-0 bottom-0 w-2 bg-gradient-to-b from-[#ffd700]/40 via-[#ffd700]/20 to-[#ffd700]/40" />
            <div className="absolute right-2 sm:right-4 top-0 bottom-0 w-2 bg-gradient-to-b from-[#ffd700]/40 via-[#ffd700]/20 to-[#ffd700]/40" />
            
            <div className="text-[#ffd700] text-xl sm:text-2xl font-bold tracking-[0.5em]"
                 style={{ textShadow: '0 0 20px rgba(255,215,0,0.3), 2px 2px 4px rgba(0,0,0,0.5)', fontFamily: 'serif' }}>
              菠萝朝堂
            </div>
            <div className="text-[#ffd700]/40 text-xs mt-1 tracking-[0.3em]">PINEAPPLE IMPERIAL COURT</div>
          </div>
        </div>

        {/* 朝堂内部 */}
        <div className="relative" style={{ 
          background: `linear-gradient(180deg, 
            ${theme === 'light' ? '#f5e6d0' : '#1a1510'} 0%, 
            ${theme === 'light' ? '#e8d0a8' : '#12100a'} 50%,
            ${theme === 'light' ? '#dcc49e' : '#0d0d1a'} 100%)`
        }}>
          {/* 地砖纹理 */}
          <div className="absolute inset-0 opacity-5" style={{
            backgroundImage: 'repeating-linear-gradient(0deg, transparent, transparent 39px, #d4a574 39px, #d4a574 40px), repeating-linear-gradient(90deg, transparent, transparent 39px, #d4a574 39px, #d4a574 40px)',
            backgroundSize: '40px 40px'
          }} />

          <div className="relative p-4 sm:p-6">
            {/* 御座区 */}
            <div className="text-center mb-4">
              <div className="inline-block px-4 py-0.5 rounded-full bg-[#ffd700]/10 border border-[#ffd700]/20 mb-3">
                <span className="text-[10px] sm:text-xs text-[#ffd700]/70 tracking-wider">👑 御 座</span>
              </div>
              <div className="flex justify-center gap-2 sm:gap-4">
                {core.map(bot => (
                  <PixelPerson key={bot.id} bot={bot} rank="emperor"
                    selected={selectedBot === bot.id} online={bot.hasToken}
                    onClick={() => setSelectedBot(selectedBot === bot.id ? null : bot.id)} />
                ))}
              </div>
            </div>

            {/* 金色分隔线 */}
            <div className="flex items-center gap-2 my-3">
              <div className="flex-1 h-px bg-gradient-to-r from-transparent via-[#d4a574]/30 to-transparent" />
              <span className="text-[#d4a574]/30 text-xs">◆</span>
              <div className="flex-1 h-px bg-gradient-to-r from-transparent via-[#d4a574]/30 to-transparent" />
            </div>

            {/* 六部 */}
            <div className="text-center mb-4">
              <div className="inline-block px-4 py-0.5 rounded-full bg-[#d4a574]/5 border border-[#d4a574]/10 mb-3">
                <span className="text-[10px] sm:text-xs text-[#d4a574]/50 tracking-wider">🏛️ 六 部</span>
              </div>
              <div className="flex justify-center flex-wrap gap-1.5 sm:gap-3">
                {liubu.map(bot => (
                  <PixelPerson key={bot.id} bot={bot} rank="minister"
                    selected={selectedBot === bot.id} online={bot.hasToken}
                    onClick={() => setSelectedBot(selectedBot === bot.id ? null : bot.id)} />
                ))}
              </div>
            </div>

            {/* 分隔线 */}
            <div className="flex items-center gap-2 my-3">
              <div className="flex-1 h-px bg-gradient-to-r from-transparent via-[#d4a574]/20 to-transparent" />
              <span className="text-[#d4a574]/20 text-xs">◇</span>
              <div className="flex-1 h-px bg-gradient-to-r from-transparent via-[#d4a574]/20 to-transparent" />
            </div>

            {/* 诸院 */}
            <div className="text-center">
              <div className="inline-block px-4 py-0.5 rounded-full bg-[#d4a574]/5 border border-[#d4a574]/10 mb-3">
                <span className="text-[10px] sm:text-xs text-[#d4a574]/40 tracking-wider">📚 诸 院</span>
              </div>
              <div className="flex justify-center flex-wrap gap-1.5 sm:gap-3">
                {others.map(bot => (
                  <PixelPerson key={bot.id} bot={bot} rank="official"
                    selected={selectedBot === bot.id} online={bot.hasToken}
                    onClick={() => setSelectedBot(selectedBot === bot.id ? null : bot.id)} />
                ))}
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* 指挥台 */}
      <div className={`${bg} rounded-lg p-3 sm:p-4`}>
        <div className="flex items-center gap-2 mb-3 flex-wrap">
          <span>📜</span>
          <h3 className="text-xs sm:text-sm font-medium text-[#d4a574]">
            {selectedBot ? `下旨 → ${bots.find(b => b.id === selectedBot)?.displayName}` : '颁旨'}
          </h3>
          {selectedBot && (
            <button onClick={() => setSelectedBot(null)} className={`text-[10px] px-2 py-0.5 rounded border border-[#d4a574]/20 ${sub} hover:text-[#d4a574] cursor-pointer`}>✕</button>
          )}
          <span className={`text-[10px] ${sub}`}>→</span>
          {/* 频道选择器 */}
          <select
            value={selectedChannel}
            onChange={e => setSelectedChannel(e.target.value)}
            className={`text-[11px] sm:text-xs px-2 py-1 rounded border ${
              theme === 'light' ? 'bg-gray-50 border-gray-200' : 'bg-[#0d0d1a] border-[#d4a574]/20 text-[#e5e5e5]'
            } focus:outline-none focus:border-[#d4a574] cursor-pointer`}
          >
            {discordChannels.length === 0 ? (
              <option value="">加载中...</option>
            ) : (
              <>
                {/* 按分类分组 */}
                {categories.map(cat => {
                  const children = discordChannels
                    .filter(ch => ch.parentId === cat.id)
                    .sort((a, b) => (a.position ?? 0) - (b.position ?? 0))
                  if (children.length === 0) return null
                  return (
                    <optgroup key={cat.id} label={cat.name}>
                      {children.map(ch => (
                        <option key={ch.id} value={ch.id}>#{ch.name}</option>
                      ))}
                    </optgroup>
                  )
                })}
                {/* 无分类的频道 */}
                {discordChannels.filter(ch => !ch.parentId).map(ch => (
                  <option key={ch.id} value={ch.id}>#{ch.name}</option>
                ))}
              </>
            )}
          </select>
        </div>

        {/* 身份设置 + 提示 */}
        <div className={`text-[10px] ${sub} mb-2 flex items-center gap-1.5 flex-wrap`}>
          <span>👤</span>
          <span>身份：</span>
          <input
            type="text"
            value={senderName}
            onChange={e => {
              setSenderName(e.target.value)
              localStorage.setItem('court_sender_name', e.target.value)
            }}
            placeholder="皇上"
            className={`text-[11px] w-20 px-1.5 py-0.5 rounded border ${
              theme === 'light' ? 'bg-gray-50 border-gray-200' : 'bg-[#0d0d1a] border-[#d4a574]/20 text-[#e5e5e5]'
            } focus:outline-none focus:border-[#d4a574]`}
          />
          {selectedBot && selectedBot !== 'main' && (
            <>
              <span>→</span>
              <span>
                将以「{senderName || '皇上'}」身份在 #{discordChannels.find(c => c.id === activeChannel)?.name || '...'}
                @{bots.find(b => b.id === selectedBot)?.displayName}
                {botUserIds[selectedBot] ? '' : ' ⚠️ 无法@mention'}
              </span>
            </>
          )}
        </div>

        <div className="flex flex-wrap gap-1.5 mb-3">
          {[
            { label: '📊 状态', cmd: '报告当前状态' },
            { label: '📋 摘要', cmd: '汇报今日工作摘要' },
            { label: '🔥 Token', cmd: '报告今日Token消耗' },
            { label: '🔄 刷新', cmd: '刷新所有数据' },
          ].map(q => (
            <button key={q.label} onClick={() => setCommand(q.cmd)}
              className={`text-[10px] sm:text-xs px-2 sm:px-3 py-1.5 rounded border border-[#d4a574]/20 ${sub} hover:text-[#d4a574] hover:border-[#d4a574]/40 cursor-pointer transition-all`}>
              {q.label}
            </button>
          ))}
        </div>

        <div className="flex gap-2">
          <input type="text" value={command} onChange={e => setCommand(e.target.value)}
            onKeyDown={e => e.key === 'Enter' && !sending && sendCommand()}
            placeholder="输入圣旨..."
            className={`flex-1 px-3 py-2.5 text-sm rounded border ${theme === 'light' ? 'bg-gray-50 border-gray-200' : 'bg-[#0d0d1a] border-[#d4a574]/20'} focus:outline-none focus:border-[#d4a574]`} />
          <button onClick={sendCommand} disabled={sending || !command.trim() || !activeChannel}
            className="px-4 sm:px-6 py-2.5 bg-gradient-to-r from-[#d4a574] to-[#c49464] text-[#0d0d1a] text-sm font-bold rounded hover:brightness-110 disabled:opacity-40 cursor-pointer transition-all shadow-lg shadow-[#d4a574]/20">
            {sending ? '⏳' : '📜 下旨'}
          </button>
        </div>
      </div>

      {/* 朝堂最新消息 */}
      <div className={`${bg} rounded-lg p-3 sm:p-4`}>
        <div className="flex items-center justify-between mb-3">
          <h3 className={`text-[10px] sm:text-xs uppercase tracking-wider ${sub}`}>
            💬 #{discordChannels.find(c => c.id === activeChannel)?.name || '...'} 最新消息
          </h3>
          <button
            onClick={fetchChannelMessages}
            disabled={loadingMessages}
            className={`text-[10px] px-2 py-0.5 rounded border border-[#d4a574]/20 ${sub} hover:text-[#d4a574] cursor-pointer`}
          >
            {loadingMessages ? '⏳' : '🔄 刷新'}
          </button>
        </div>
        <div ref={msgRef} className="max-h-72 overflow-y-auto space-y-2">
          {channelMessages.length === 0 ? (
            <div className={`text-center text-xs py-4 ${sub}`}>
              {loadingMessages ? '加载中...' : '暂无消息'}
            </div>
          ) : (
            channelMessages.map((msg) => (
              <div key={msg.id} className={`flex items-start gap-2 text-xs p-2 rounded ${
                theme === 'light' ? 'bg-gray-50' : 'bg-[#0d0d1a]/50'
              }`}>
                <div className="w-6 h-6 rounded-full flex items-center justify-center text-[10px] font-bold flex-shrink-0"
                  style={{ backgroundColor: msg.avatarColor || '#d4a574', color: '#0d0d1a' }}>
                  {msg.author?.[0] || '?'}
                </div>
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2">
                    <span className="font-medium text-[#d4a574] truncate">{msg.author}</span>
                    <span className={`text-[10px] ${sub} flex-shrink-0`}>{msg.timestamp}</span>
                  </div>
                  <div className={`mt-0.5 break-words ${theme === 'light' ? 'text-gray-700' : 'text-[#e5e5e5]'}`}>
                    {msg.content?.substring(0, 300)}{msg.content?.length > 300 ? '...' : ''}
                  </div>
                </div>
              </div>
            ))
          )}
        </div>
      </div>

      {/* 旨意记录 */}
      {messages.length > 0 && (
        <div className={`${bg} rounded-lg p-3 sm:p-4`}>
          <h3 className={`text-[10px] sm:text-xs uppercase tracking-wider mb-2 ${sub}`}>📋 旨意记录</h3>
          <div ref={logRef} className="max-h-48 overflow-y-auto space-y-1.5">
            {messages.map((m, i) => (
              <div key={i} className={`flex items-start gap-2 text-xs ${m.ok ? '' : 'opacity-50'}`}>
                <span className={`text-[10px] ${sub} w-10 flex-shrink-0`}>{m.time}</span>
                <span className={m.ok ? 'text-green-400' : 'text-red-400'}>{m.ok ? '✅' : '❌'}</span>
                <span className="text-[#d4a574] flex-shrink-0 font-medium">{m.bot}</span>
                {m.channel && <span className={`text-[10px] ${sub}`}>#{m.channel}</span>}
                <span className={sub}>: {m.text}</span>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  )
}
