import { useState, useEffect } from "react"
import { useTheme } from "../theme"
import { getAuthToken } from '../auth'

interface PendingItem {
  id: string
  type: 'cron' | 'session' | 'node' | 'system'
  title: string
  description: string
  timestamp: string
  priority: 'high' | 'normal' | 'low'
}

interface ProcessedItem extends PendingItem {
  action: 'approved' | 'rejected' | 'ignored'
  processedAt: string
}

export default function MemorialHall() {
  const [pending, setPending] = useState<PendingItem[]>([])
  const [processed, setProcessed] = useState<ProcessedItem[]>([])
  const [loading, setLoading] = useState(true)
  const [activeTab, setActiveTab] = useState<'pending' | 'processed'>('pending')
  const { theme } = useTheme()

  const fetchData = async () => {
    setLoading(true)
    try {
      // 获取 Cron 任务状态
      const cronRes = await fetch('/api/cron', {
        headers: { 'Authorization': `Bearer ${getAuthToken()}` }
      })
      
      const pendingItems: PendingItem[] = []
      
      if (cronRes.ok) {
        const cronData = await cronRes.json()
        const jobs = cronData.jobs || []
        
        // 检查失败的 Cron 任务
        for (const job of jobs) {
          if (job.status === 'error') {
            pendingItems.push({
              id: `cron-${job.id}`,
              type: 'cron',
              title: `Cron 任务失败: ${job.name}`,
              description: `任务调度出错，需要检查配置。上次错误: ${job.status}`,
              timestamp: job.lastRun || new Date().toISOString(),
              priority: 'high'
            })
          }
        }
      }

      // 获取会话状态
      const sessionsRes = await fetch('/api/sessions?limit=20', {
        headers: { 'Authorization': `Bearer ${getAuthToken()}` }
      })
      
      if (sessionsRes.ok) {
        const sessionsData = await sessionsRes.json()
        const sessions = sessionsData.sessions || []
        
        // 检查长时间未活跃的会话
        const now = Date.now()
        for (const session of sessions) {
          const inactiveMs = now - session.updatedAt
          if (inactiveMs > 24 * 60 * 60 * 1000) { // 超过24小时
            pendingItems.push({
              id: `session-${session.id}`,
              type: 'session',
              title: `会话待清理: ${session.agentName}`,
              description: `会话已 ${Math.round(inactiveMs / (1000 * 60 * 60))} 小时未活跃`,
              timestamp: new Date(session.updatedAt).toISOString(),
              priority: 'low'
            })
          }
        }
      }

      // 获取节点状态
      const nodesRes = await fetch('/api/nodes', {
        headers: { 'Authorization': `Bearer ${getAuthToken()}` }
      })
      
      if (nodesRes.ok) {
        const nodesData = await nodesRes.json()
        const nodes = nodesData.nodes || []
        
        // 检查离线节点
        for (const node of nodes) {
          if (node.status === 'offline') {
            pendingItems.push({
              id: `node-${node.id}`,
              type: 'node',
              title: `节点离线: ${node.name}`,
              description: `节点已离线超过1小时，需要检查网络连接`,
              timestamp: new Date(node.lastHeartbeat).toISOString(),
              priority: 'high'
            })
          }
        }
      }

      // 添加一些系统级待办
      if (pendingItems.length === 0) {
        pendingItems.push({
          id: 'system-1',
          type: 'system',
          title: '系统运行正常',
          description: '所有监控项均正常，无需处理',
          timestamp: new Date().toISOString(),
          priority: 'low'
        })
      }

      setPending(pendingItems)
      
      // 模拟已处理记录
      setProcessed([
        {
          id: 'proc-1',
          type: 'cron',
          title: 'Cron 任务恢复: gui-iter',
          description: '任务已自动恢复',
          timestamp: new Date(Date.now() - 3600000).toISOString(),
          priority: 'normal',
          action: 'approved',
          processedAt: new Date(Date.now() - 3500000).toISOString()
        },
        {
          id: 'proc-2',
          type: 'node',
          title: '节点重启: test-node',
          description: '已重启节点服务',
          timestamp: new Date(Date.now() - 7200000).toISOString(),
          priority: 'high',
          action: 'approved',
          processedAt: new Date(Date.now() - 7100000).toISOString()
        }
      ])
      
    } catch (e) {
      console.error('Failed to fetch memorial data:', e)
    }
    setLoading(false)
  }

  useEffect(() => {
    fetchData()
  }, [])

  const handleAction = (item: PendingItem, action: 'approved' | 'rejected' | 'ignored') => {
    // 移出待处理列表
    setPending(prev => prev.filter(p => p.id !== item.id))
    
    // 添加到已处理列表
    const processedItem: ProcessedItem = {
      ...item,
      action,
      processedAt: new Date().toISOString()
    }
    setProcessed(prev => [processedItem, ...prev])
  }

  const getTypeIcon = (type: string) => {
    switch (type) {
      case 'cron': return '⏰'
      case 'session': return '💬'
      case 'node': return '🖥️'
      case 'system': return '⚙️'
      default: return '📋'
    }
  }

  const getPriorityColor = (priority: string) => {
    switch (priority) {
      case 'high': return 'text-red-500 bg-red-500/10'
      case 'normal': return 'text-yellow-500 bg-yellow-500/10'
      case 'low': return 'text-green-500 bg-green-500/10'
      default: return 'text-gray-500 bg-gray-500/10'
    }
  }

  const getActionColor = (action: string) => {
    switch (action) {
      case 'approved': return 'text-green-500'
      case 'rejected': return 'text-red-500'
      case 'ignored': return 'text-gray-500'
      default: return 'text-gray-500'
    }
  }

  const formatTime = (ts: string) => {
    const diff = Date.now() - new Date(ts).getTime()
    const mins = Math.floor(diff / 60000)
    const hours = Math.floor(mins / 60)
    if (hours > 0) return `${hours}小时前`
    if (mins > 0) return `${mins}分钟前`
    return '刚刚'
  }

  if (loading) {
    return <div className="text-[#a3a3a3]">加载中...</div>
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h2 className={`text-lg font-medium ${theme === 'light' ? 'text-gray-800' : 'text-[#d4a574]'}`}>
          📜 奏报厅
        </h2>
        <button
          onClick={fetchData}
          className="px-3 py-1 text-xs border border-[#d4a574] text-[#d4a574] hover:bg-[#d4a574]/10"
        >
          刷新
        </button>
      </div>

      {/* Tab 切换 */}
      <div className="flex gap-2 border-b border-[#d4a574]/30 pb-2">
        <button
          onClick={() => setActiveTab('pending')}
          className={`px-4 py-2 text-sm rounded-t transition-all ${
            activeTab === 'pending'
              ? 'bg-[#d4a574]/20 text-[#d4a574] border-b-2 border-[#d4a574]'
              : 'text-[#a3a3a3] hover:text-[#e5e5e5]'
          }`}
        >
          ⏳ 待处理 ({pending.length})
        </button>
        <button
          onClick={() => setActiveTab('processed')}
          className={`px-4 py-2 text-sm rounded-t transition-all ${
            activeTab === 'processed'
              ? 'bg-[#d4a574]/20 text-[#d4a574] border-b-2 border-[#d4a574]'
              : 'text-[#a3a3a3] hover:text-[#e5e5e5]'
          }`}
        >
          ✅ 已处理 ({processed.length})
        </button>
      </div>

      {/* 待处理事项 */}
      {activeTab === 'pending' && (
        <div className="space-y-4">
          {pending.length === 0 ? (
            <div className={`text-center py-12 ${theme === 'light' ? 'text-gray-500' : 'text-[#a3a3a3]'}`}>
              <div className="text-4xl mb-4">🎉</div>
              <div className="text-lg">暂无待处理事项</div>
              <div className="text-sm mt-2">系统运行正常</div>
            </div>
          ) : (
            pending.map(item => (
              <div
                key={item.id}
                className={`p-4 rounded-lg border ${
                  theme === 'light' 
                    ? 'bg-white border-gray-200' 
                    : 'bg-[#1a1a2e] border-[#d4a574]/20'
                }`}
              >
                <div className="flex items-start justify-between mb-3">
                  <div className="flex items-center gap-3">
                    <span className="text-2xl">{getTypeIcon(item.type)}</span>
                    <div>
                      <div className="font-medium">{item.title}</div>
                      <div className={`text-xs px-2 py-0.5 rounded inline-block mt-1 ${getPriorityColor(item.priority)}`}>
                        {item.priority === 'high' ? '紧急' : item.priority === 'normal' ? '普通' : '低优先级'}
                      </div>
                    </div>
                  </div>
                  <div className="text-xs text-[#a3a3a3]">
                    {formatTime(item.timestamp)}
                  </div>
                </div>
                
                <div className={`text-sm mb-4 ${theme === 'light' ? 'text-gray-600' : 'text-[#a3a3a3]'}`}>
                  {item.description}
                </div>

                {/* 操作按钮 */}
                <div className="flex gap-2">
                  <button
                    onClick={() => handleAction(item, 'approved')}
                    className="px-4 py-1.5 text-sm bg-green-500/20 text-green-500 rounded hover:bg-green-500/30"
                  >
                    ✅ 批准
                  </button>
                  <button
                    onClick={() => handleAction(item, 'rejected')}
                    className="px-4 py-1.5 text-sm bg-red-500/20 text-red-500 rounded hover:bg-red-500/30"
                  >
                    ❌ 拒绝
                  </button>
                  <button
                    onClick={() => handleAction(item, 'ignored')}
                    className="px-4 py-1.5 text-sm bg-gray-500/20 text-gray-500 rounded hover:bg-gray-500/30"
                  >
                    👄 忽略
                  </button>
                </div>
              </div>
            ))
          )}
        </div>
      )}

      {/* 已处理记录 */}
      {activeTab === 'processed' && (
        <div className="space-y-3">
          {processed.length === 0 ? (
            <div className={`text-center py-12 ${theme === 'light' ? 'text-gray-500' : 'text-[#a3a3a3]'}`}>
              暂无处理记录
            </div>
          ) : (
            processed.map(item => (
              <div
                key={item.id}
                className={`p-3 rounded-lg border opacity-60 ${
                  theme === 'light' 
                    ? 'bg-gray-50 border-gray-200' 
                    : 'bg-[#0d0d1a] border-[#d4a574]/10'
                }`}
              >
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <span>{getTypeIcon(item.type)}</span>
                    <span className="text-sm">{item.title}</span>
                  </div>
                  <div className="flex items-center gap-3">
                    <span className={`text-sm ${getActionColor(item.action)}`}>
                      {item.action === 'approved' ? '✅ 已批准' : item.action === 'rejected' ? '❌ 已拒绝' : '👄 已忽略'}
                    </span>
                    <span className="text-xs text-[#a3a3a3]">
                      {formatTime(item.processedAt)}
                    </span>
                  </div>
                </div>
              </div>
            ))
          )}
        </div>
      )}
    </div>
  )
}
