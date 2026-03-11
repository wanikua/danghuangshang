import { useState, useEffect, useCallback } from "react"
import type { SystemStatus } from "../types"
import { getAuthToken } from '../auth'

const REFRESH_INTERVAL = 30000

export function useStatus() {
  const [data, setData] = useState<SystemStatus | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [lastUpdated, setLastUpdated] = useState<Date | null>(null)

  const fetchStatus = useCallback(async () => {
    try {
      const res = await fetch("/api/status", {
        headers: {
          'Authorization': `Bearer ${getAuthToken()}`
        }
      })
      if (!res.ok) throw new Error(`HTTP ${res.status}: ${res.statusText}`)
      const json = await res.json()
      setData(json)
      setError(null)
      setLastUpdated(new Date())
    } catch (err) {
      setError(err instanceof Error ? err.message : "Unknown error")
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    fetchStatus()
    const interval = setInterval(fetchStatus, REFRESH_INTERVAL)
    return () => clearInterval(interval)
  }, [fetchStatus])

  return { data, loading, error, lastUpdated, refresh: fetchStatus }
}
