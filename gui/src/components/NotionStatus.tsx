import { useState, useEffect } from "react"
import { useTheme } from "../theme"
import { getAuthToken } from '../auth'

interface NotionStatus {
  status: string
  lastSync: string
  pagesLinked: number
  lastError: string | null
}

export default function NotionStatus() {
  const [status, setStatus] = useState<NotionStatus | null>(null)
  const [loading, setLoading] = useState(false)
  const { theme } = useTheme()

  const fetchStatus = async () => {
    try {
      const res = await fetch("/api/notion", {
        headers: { 'Authorization': `Bearer ${getAuthToken()}` }
      })
      if (res.ok) {
        const data = await res.json()
        setStatus(data)
      }
    } catch (e) {
      console.error('Failed to fetch Notion status:', e)
    }
  }

  const triggerSync = async () => {
    setLoading(true)
    try {
      await fetch("/api/notion/sync", {
        method: 'POST',
        headers: { 'Authorization': `Bearer ${getAuthToken()}` }
      })
      await fetchStatus()
    } catch (e) {
      console.error('Failed to trigger sync:', e)
    }
    setLoading(false)
  }

  useEffect(() => {
    fetchStatus()
    const interval = setInterval(fetchStatus, 60000)
    return () => clearInterval(interval)
  }, [])

  if (!status) return null

  const lastSyncTime = new Date(status.lastSync).toLocaleString('zh-CN')
  const isSuccess = status.status === 'success'

  return (
    <div className={`flex items-center gap-4 text-xs ${theme === 'light' ? 'text-gray-600' : 'text-[#a3a3a3]'}`}>
      <span>Notion:</span>
      <span className={isSuccess ? 'text-green-500' : 'text-yellow-500'}>
        {isSuccess ? '✓' : '⚠'}
      </span>
      <span>{lastSyncTime}</span>
      <button
        onClick={triggerSync}
        disabled={loading}
        className="px-2 py-0.5 text-xs border border-[#d4a574] text-[#d4a574] hover:bg-[#d4a574]/10 disabled:opacity-50"
      >
        {loading ? '同步中...' : '同步'}
      </button>
    </div>
  )
}
