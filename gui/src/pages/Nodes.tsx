import { useState, useEffect } from "react"
import { useTheme } from "../theme"
import { getAuthToken } from '../auth'

interface Node {
  id: string
  name: string
  status: 'online' | 'offline'
  lastHeartbeat: number
  os: string
  uptime: number
}

export default function Nodes() {
  const [nodes, setNodes] = useState<Node[]>([])
  const [loading, setLoading] = useState(true)
  const { theme } = useTheme()

  const fetchNodes = async () => {
    try {
      const res = await fetch("/api/nodes", {
        headers: { 'Authorization': `Bearer ${getAuthToken()}` }
      })
      if (res.ok) {
        const data = await res.json()
        setNodes(data.nodes || [])
      }
    } catch (e) {
      console.error('Failed to fetch nodes:', e)
    }
    setLoading(false)
  }

  useEffect(() => {
    fetchNodes()
    const interval = setInterval(fetchNodes, 30000)
    return () => clearInterval(interval)
  }, [])

  const formatUptime = (seconds: number) => {
    if (!seconds) return 'N/A'
    const days = Math.floor(seconds / 86400)
    const hours = Math.floor((seconds % 86400) / 3600)
    const mins = Math.floor((seconds % 3600) / 60)
    if (days > 0) return `${days}天 ${hours}小时`
    if (hours > 0) return `${hours}小时 ${mins}分钟`
    return `${mins}分钟`
  }

  const formatHeartbeat = (ts: number) => {
    const diff = Date.now() - ts
    const secs = Math.floor(diff / 1000)
    if (secs < 60) return `${secs}秒前`
    const mins = Math.floor(secs / 60)
    if (mins < 60) return `${mins}分钟前`
    const hours = Math.floor(mins / 60)
    return `${hours}小时前`
  }

  if (loading) {
    return <div className="text-[#a3a3a3]">加载中...</div>
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h2 className={`text-lg font-medium ${theme === 'light' ? 'text-gray-800' : 'text-[#d4a574]'}`}>
          节点状态
        </h2>
        <button
          onClick={fetchNodes}
          className="px-3 py-1 text-xs border border-[#d4a574] text-[#d4a574] hover:bg-[#d4a574]/10"
        >
          刷新
        </button>
      </div>

      <div className={`rounded-lg overflow-hidden ${theme === 'light' ? 'bg-white' : 'bg-[#1a1a2e]'}`}>
        <div className={`grid grid-cols-5 text-xs p-3 border-b ${theme === 'light' ? 'bg-gray-100 border-gray-200' : 'bg-[#16213e] border-[#d4a574]/20'}`}>
          <div>节点名称</div>
          <div>操作系统</div>
          <div>状态</div>
          <div>运行时长</div>
          <div>最后心跳</div>
        </div>

        {nodes.map((node) => (
          <div 
            key={node.id}
            className={`grid grid-cols-5 text-xs p-3 border-b items-center ${
              theme === 'light' 
                ? 'border-gray-100 hover:bg-gray-50' 
                : 'border-[#d4a574]/10 hover:bg-[#16213e]'
            }`}
          >
            <div className="font-medium">{node.name}</div>
            <div className="text-[#a3a3a3]">{node.os}</div>
            <div>
              <span className={`px-2 py-0.5 rounded text-xs ${
                node.status === 'online' 
                  ? 'bg-green-500/20 text-green-500' 
                  : 'bg-gray-500/20 text-gray-500'
              }`}>
                {node.status === 'online' ? '在线' : '离线'}
              </span>
            </div>
            <div className="font-mono text-[#d4a574]">
              {formatUptime(node.uptime)}
            </div>
            <div className="text-[#a3a3a3]">
              {formatHeartbeat(node.lastHeartbeat)}
            </div>
          </div>
        ))}

        {nodes.length === 0 && (
          <div className="text-xs text-[#a3a3a3] p-4 text-center">
            暂无节点数据
          </div>
        )}
      </div>
    </div>
  )
}
