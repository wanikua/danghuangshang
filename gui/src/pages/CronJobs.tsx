import { useState, useEffect } from "react"
import { useTheme } from "../theme"
import { getAuthToken } from '../auth'

interface CronJob {
  id: string
  name: string
  schedule: string
  enabled: boolean
  nextRun: string
  lastRun: string
  status: string
  agent: string
}

function relTime(ts: string) {
  if (!ts) return '未运行'
  const diff = Date.now() - new Date(ts).getTime()
  const m = Math.floor(diff / 60000), h = Math.floor(m / 60), d = Math.floor(h / 24)
  if (d > 0) return `${d}天前`
  if (h > 0) return `${h}小时前`
  if (m > 0) return `${m}分钟前`
  return '刚刚'
}

function statusStyle(status: string): { color: string; bg: string; label: string } {
  switch (status) {
    case 'ok': case 'success': return { color: 'text-green-400', bg: 'bg-green-500/20', label: '成功' }
    case 'error': case 'failed': return { color: 'text-red-400', bg: 'bg-red-500/20', label: '失败' }
    case 'running': return { color: 'text-blue-400', bg: 'bg-blue-500/20', label: '运行中' }
    default: return { color: 'text-gray-400', bg: 'bg-gray-500/20', label: status || '未知' }
  }
}

export default function CronJobs() {
  const { theme } = useTheme()
  const [jobs, setJobs] = useState<CronJob[]>([])
  const [loading, setLoading] = useState(true)
  const [toast, setToast] = useState<{ msg: string; type: 'success' | 'error' } | null>(null)
  const [actionLoading, setActionLoading] = useState<string | null>(null)

  const bg = theme === 'light' ? 'bg-white border border-gray-200' : 'bg-[#1a1a2e]'
  const sub = theme === 'light' ? 'text-gray-500' : 'text-[#a3a3a3]'

  const showToast = (msg: string, type: 'success' | 'error' = 'success') => {
    setToast({ msg, type })
    setTimeout(() => setToast(null), 3000)
  }

  const fetchJobs = async () => {
    try {
      const r = await fetch('/api/cron', { headers: { Authorization: `Bearer ${getAuthToken()}` } })
      if (r.ok) {
        const d = await r.json()
        setJobs(d.jobs || [])
      }
    } catch {}
    setLoading(false)
  }

  useEffect(() => { fetchJobs() }, [])

  const handleRun = async (jobId: string, jobName: string) => {
    setActionLoading(jobId)
    try {
      const r = await fetch(`/api/cron/${jobId}/run`, {
        method: 'POST',
        headers: { Authorization: `Bearer ${getAuthToken()}` },
      })
      if (r.ok) {
        showToast(`✅ ${jobName} 已触发运行`)
        setTimeout(fetchJobs, 2000)
      } else {
        showToast(`❌ 运行失败: ${r.statusText}`, 'error')
      }
    } catch (e: any) {
      showToast(`❌ 运行失败: ${e.message}`, 'error')
    }
    setActionLoading(null)
  }

  const handleToggle = async (jobId: string, jobName: string, currentEnabled: boolean) => {
    setActionLoading(jobId)
    try {
      const r = await fetch(`/api/cron/${jobId}/toggle`, {
        method: 'POST',
        headers: { Authorization: `Bearer ${getAuthToken()}`, 'Content-Type': 'application/json' },
        body: JSON.stringify({ enabled: !currentEnabled }),
      })
      if (r.ok) {
        showToast(`✅ ${jobName} 已${currentEnabled ? '禁用' : '启用'}`)
        fetchJobs()
      } else {
        showToast(`❌ 操作失败`, 'error')
      }
    } catch {
      showToast(`❌ 操作失败`, 'error')
    }
    setActionLoading(null)
  }

  // Stats
  const totalJobs = jobs.length
  const enabledJobs = jobs.filter(j => j.enabled).length
  const errorJobs = jobs.filter(j => j.status === 'error').length
  const okJobs = jobs.filter(j => j.status === 'ok' || j.status === 'success').length

  if (loading) return (
    <div className={`${sub} p-4 text-center`}>
      <div className="animate-pulse">加载定时任务中...</div>
    </div>
  )

  return (
    <div className="space-y-4 relative">
      {/* Toast */}
      {toast && (
        <div className={`fixed top-4 right-4 z-50 px-4 py-2 rounded-lg shadow-lg text-sm animate-[fadeIn_0.3s] ${
          toast.type === 'success'
            ? (theme === 'light' ? 'bg-green-50 border border-green-200 text-green-700' : 'bg-green-500/20 border border-green-500/50 text-green-400')
            : (theme === 'light' ? 'bg-red-50 border border-red-200 text-red-700' : 'bg-red-500/20 border border-red-500/50 text-red-400')
        }`}>
          {toast.msg}
        </div>
      )}

      {/* 统计 */}
      <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
        <div className={`${bg} rounded-lg p-3`}>
          <div className={`text-[10px] uppercase ${sub}`}>总任务</div>
          <div className="font-mono text-lg sm:text-2xl text-[#d4a574]">{totalJobs}</div>
        </div>
        <div className={`${bg} rounded-lg p-3`}>
          <div className={`text-[10px] uppercase ${sub}`}>已启用</div>
          <div className="font-mono text-lg sm:text-2xl text-green-400">{enabledJobs}</div>
        </div>
        <div className={`${bg} rounded-lg p-3`}>
          <div className={`text-[10px] uppercase ${sub}`}>运行成功</div>
          <div className="font-mono text-lg sm:text-2xl text-green-400">{okJobs}</div>
        </div>
        <div className={`${bg} rounded-lg p-3`}>
          <div className={`text-[10px] uppercase ${sub}`}>运行失败</div>
          <div className="font-mono text-lg sm:text-2xl text-red-400">{errorJobs}</div>
        </div>
      </div>

      {/* 刷新 */}
      <div className="flex justify-end">
        <button onClick={fetchJobs}
          className="px-3 py-1.5 text-xs border border-[#d4a574]/30 text-[#d4a574] rounded hover:bg-[#d4a574]/10 cursor-pointer">
          ↻ 刷新
        </button>
      </div>

      {/* 任务列表 */}
      <div className="space-y-2">
        {jobs.length === 0 && (
          <div className={`text-center py-8 ${sub}`}>暂无定时任务</div>
        )}
        {jobs.map(job => {
          const st = statusStyle(job.status)
          const isLoading = actionLoading === job.id

          return (
            <div key={job.id} className={`${bg} rounded-lg p-3 sm:p-4 transition-all ${isLoading ? 'opacity-60' : ''}`}>
              <div className="flex items-start justify-between gap-2">
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2 flex-wrap">
                    <span className="text-sm font-medium">{job.name}</span>
                    <span className={`text-[9px] px-1.5 py-0.5 rounded ${st.bg} ${st.color}`}>
                      {st.label}
                    </span>
                    {!job.enabled && (
                      <span className="text-[9px] px-1.5 py-0.5 rounded bg-gray-500/20 text-gray-400">已禁用</span>
                    )}
                  </div>
                  <div className={`text-[10px] sm:text-xs mt-1 ${sub}`}>
                    <span className="font-mono" title="定时规则">🕐 {job.schedule}</span>
                    <span className="mx-2">·</span>
                    <span title="执行Agent">👤 {job.agent}</span>
                  </div>
                  <div className={`text-[10px] mt-1 flex flex-wrap gap-3 ${sub}`}>
                    <span>上次: {relTime(job.lastRun)}</span>
                    <span>下次: {job.nextRun ? new Date(job.nextRun).toLocaleTimeString('zh-CN', { hour: '2-digit', minute: '2-digit' }) : '-'}</span>
                  </div>
                </div>

                {/* Actions */}
                <div className="flex items-center gap-2 flex-shrink-0">
                  {/* Enable/Disable toggle */}
                  <button
                    onClick={() => handleToggle(job.id, job.name, job.enabled)}
                    disabled={isLoading}
                    className={`relative w-10 h-5 rounded-full transition-colors cursor-pointer ${
                      job.enabled
                        ? 'bg-green-500/30 border border-green-500/50'
                        : (theme === 'light' ? 'bg-gray-200' : 'bg-gray-700')
                    }`}
                    title={job.enabled ? '点击禁用' : '点击启用'}
                  >
                    <span className={`absolute top-0.5 w-4 h-4 rounded-full transition-transform ${
                      job.enabled ? 'translate-x-5 bg-green-400' : 'translate-x-0.5 bg-gray-400'
                    }`} />
                  </button>

                  {/* Manual run */}
                  <button
                    onClick={() => handleRun(job.id, job.name)}
                    disabled={isLoading}
                    className="px-2 py-1 text-[10px] border border-[#d4a574]/30 text-[#d4a574] rounded hover:bg-[#d4a574]/10 cursor-pointer disabled:opacity-50"
                    title="手动运行"
                  >
                    {isLoading ? '...' : '▶ 运行'}
                  </button>
                </div>
              </div>
            </div>
          )
        })}
      </div>
    </div>
  )
}
