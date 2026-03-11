import { useState, useEffect } from "react"
import { useTheme } from "../theme"
import { getAuthToken } from '../auth'

interface CronJob {
  id: string
  name: string
  schedule: string
  enabled: boolean
  nextRun: string | null
  lastRun: string | null
  status: string
  agent: string
}

export default function CronJobs() {
  const [jobs, setJobs] = useState<CronJob[]>([])
  const [loading, setLoading] = useState(true)
  const [running, setRunning] = useState<string | null>(null)
  const { theme } = useTheme()

  const fetchJobs = async () => {
    try {
      const res = await fetch("/api/cron", {
        headers: { 'Authorization': `Bearer ${getAuthToken()}` }
      })
      if (res.ok) {
        const data = await res.json()
        setJobs(data.jobs || [])
      }
    } catch (e) {
      console.error('Failed to fetch cron jobs:', e)
    }
    setLoading(false)
  }

  const runJob = async (id: string) => {
    setRunning(id)
    try {
      await fetch(`/api/cron/run/${id}`, {
        method: 'POST',
        headers: { 'Authorization': `Bearer ${getAuthToken()}` }
      })
    } catch (e) {
      console.error('Failed to run job:', e)
    }
    setRunning(null)
  }

  useEffect(() => {
    fetchJobs()
  }, [])

  const formatNextRun = (ts: string | null) => {
    if (!ts) return 'N/A'
    return new Date(ts).toLocaleString('zh-CN')
  }

  if (loading) {
    return <div className="text-[#a3a3a3]">加载中...</div>
  }

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h2 className={`text-lg font-medium ${theme === 'light' ? 'text-gray-800' : 'text-[#d4a574]'}`}>
          定时任务管理
        </h2>
        <button
          onClick={fetchJobs}
          className="px-3 py-1 text-xs border border-[#d4a574] text-[#d4a574] hover:bg-[#d4a574]/10"
        >
          刷新
        </button>
      </div>

      <div className={`rounded-lg overflow-hidden ${theme === 'light' ? 'bg-white' : 'bg-[#1a1a2e]'}`}>
        <div className={`grid grid-cols-7 text-xs p-3 border-b ${theme === 'light' ? 'bg-gray-100 border-gray-200' : 'bg-[#16213e] border-[#d4a574]/20'}`}>
          <div>任务名称</div>
          <div>Agent</div>
          <div>调度规则</div>
          <div>状态</div>
          <div>下次执行</div>
          <div>上次执行</div>
          <div>操作</div>
        </div>

        {jobs.map((job) => (
          <div 
            key={job.id}
            className={`grid grid-cols-7 text-xs p-3 border-b items-center ${
              theme === 'light' 
                ? 'border-gray-100 hover:bg-gray-50' 
                : 'border-[#d4a574]/10 hover:bg-[#16213e]'
            }`}
          >
            <div className="font-medium">{job.name}</div>
            <div className="text-[#a3a3a3]">{job.agent || '-'}</div>
            <div className="font-mono text-[#a3a3a3]">{job.schedule}</div>
            <div>
              <span className={`px-2 py-0.5 rounded text-xs ${
                job.status === 'ok' 
                  ? 'bg-green-500/20 text-green-500' 
                  : job.status === 'error'
                  ? 'bg-red-500/20 text-red-500'
                  : 'bg-gray-500/20 text-gray-500'
              }`}>
                {job.status === 'ok' ? '正常' : job.status === 'error' ? '错误' : job.enabled ? '启用' : '禁用'}
              </span>
            </div>
            <div className="text-[#a3a3a3]">{formatNextRun(job.nextRun)}</div>
            <div className="text-[#a3a3a3]">{formatNextRun(job.lastRun)}</div>
            <div>
              <button
                onClick={() => runJob(job.id)}
                disabled={running === job.id}
                className="px-2 py-1 text-xs border border-[#d4a574] text-[#d4a574] hover:bg-[#d4a574]/10 disabled:opacity-50"
              >
                {running === job.id ? '执行中...' : '立即执行'}
              </button>
            </div>
          </div>
        ))}

        {jobs.length === 0 && (
          <div className="text-xs text-[#a3a3a3] p-4 text-center">
            暂无定时任务
          </div>
        )}
      </div>
    </div>
  )
}
