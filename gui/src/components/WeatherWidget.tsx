import { useState, useEffect } from "react"
import { useTheme } from "../theme"
import { getAuthToken } from '../auth'

interface WeatherData {
  location: string
  weather: string
  details?: {
    temp: string
    condition: string
    humidity: string
    wind: string
  }
  timestamp: string
}

const DEFAULT_LOCATIONS = ['Beijing', 'Shanghai', 'Guangzhou', 'Shenzhen', 'Hangzhou', 'Chengdu']

export default function WeatherWidget() {
  const [weather, setWeather] = useState<WeatherData | null>(null)
  const [loading, setLoading] = useState(true)
  const [expanded, setExpanded] = useState(false)
  const [showSettings, setShowSettings] = useState(false)
  const { theme } = useTheme()

  // 从 localStorage 读取天气位置配置
  const [location, setLocation] = useState(() => {
    return localStorage.getItem('weather_location') || 'Beijing'
  })
  
  const [editLocation, setEditLocation] = useState(location)
  
  const fetchWeather = async (loc: string) => {
    try {
      const res = await fetch(`/api/weather?location=${encodeURIComponent(loc)}`, {
        headers: { 'Authorization': `Bearer ${getAuthToken()}` }
      })
      if (res.ok) {
        const data = await res.json()
        setWeather(data)
      }
    } catch (e) {
      console.error('Failed to fetch weather:', e)
    }
    setLoading(false)
  }

  const handleSaveLocation = () => {
    setLocation(editLocation)
    localStorage.setItem('weather_location', editLocation)
    setShowSettings(false)
    fetchWeather(editLocation)
  }

  useEffect(() => {
    fetchWeather(location)
    // 每30分钟刷新一次
    const interval = setInterval(() => fetchWeather(location), 30 * 60 * 1000)
    return () => clearInterval(interval)
  }, [location])

  if (loading) {
    return (
      <div className={`text-xs ${theme === 'light' ? 'text-gray-500' : 'text-[#a3a3a3]'}`}>
        天气加载中...
      </div>
    )
  }

  // 解析天气图标
  const getWeatherEmoji = (condition: string | undefined) => {
    const c = (condition || '').toLowerCase()
    if (c.includes('sun') || c.includes('clear')) return '☀️'
    if (c.includes('cloud') || c.includes('overcast')) return '☁️'
    if (c.includes('rain') || c.includes('drizzle')) return '🌧️'
    if (c.includes('snow')) return '❄️'
    if (c.includes('thunder') || c.includes('storm')) return '⛈️'
    if (c.includes('fog') || c.includes('mist')) return '🌫️'
    return '🌤️'
  }

  return (
    <div className="relative">
      <div 
        className="flex items-center gap-2 cursor-pointer"
        onClick={() => setExpanded(!expanded)}
      >
        <span className="text-lg">{getWeatherEmoji(weather?.details?.condition)}</span>
        <div className="flex flex-col">
          <span className={`text-xs font-medium ${theme === 'light' ? 'text-gray-700' : 'text-[#d4a574]'}`}>
            {weather?.location || location}
          </span>
          <span className={`text-xs ${theme === 'light' ? 'text-gray-500' : 'text-[#a3a3a3]'}`}>
            {weather?.weather || '暂无数据'}
          </span>
        </div>
        {/* 设置按钮 */}
        <button 
          className={`ml-1 text-xs ${theme === 'light' ? 'text-gray-400' : 'text-[#a3a3a3]'} hover:text-[#d4a574]`}
          onClick={(e) => {
            e.stopPropagation()
            setShowSettings(!showSettings)
            setEditLocation(location)
          }}
        >
          ⚙️
        </button>
      </div>
      
      {/* 展开详情 */}
      {expanded && weather?.details && (
        <div className={`absolute top-full left-0 mt-1 p-2 rounded shadow-lg z-50 ${
          theme === 'light' ? 'bg-white border border-gray-200' : 'bg-[#1a1a2e] border border-[#d4a574]/30'
        }`}>
          <div className={`text-xs space-y-1 ${theme === 'light' ? 'text-gray-600' : 'text-[#a3a3a3]'}`}>
            <div>🌡️ 温度: {weather.details.temp}°C</div>
            <div>💧 湿度: {weather.details.humidity}</div>
            <div>💨 风速: {weather.details.wind}</div>
          </div>
        </div>
      )}

      {/* 位置设置 */}
      {showSettings && (
        <div className={`absolute top-full right-0 mt-1 p-2 rounded shadow-lg z-50 w-40 ${
          theme === 'light' ? 'bg-white border border-gray-200' : 'bg-[#1a1a2e] border border-[#d4a574]/30'
        }`}>
          <div className={`text-xs mb-2 ${theme === 'light' ? 'text-gray-600' : 'text-[#a3a3a3]'}`}>
            选择城市:
          </div>
          <select 
            value={editLocation}
            onChange={(e) => setEditLocation(e.target.value)}
            className={`w-full text-xs p-1 rounded mb-2 ${
              theme === 'light' ? 'bg-gray-100 text-gray-700' : 'bg-[#0d0d1a] text-[#e5e5e5]'
            }`}
          >
            {DEFAULT_LOCATIONS.map(loc => (
              <option key={loc} value={loc}>{loc}</option>
            ))}
          </select>
          <div className="flex gap-1">
            <button 
              onClick={handleSaveLocation}
              className="flex-1 text-xs bg-[#d4a574] text-black px-2 py-1 rounded hover:bg-[#c9a96e]"
            >
              保存
            </button>
            <button 
              onClick={() => setShowSettings(false)}
              className={`flex-1 text-xs px-2 py-1 rounded ${
                theme === 'light' ? 'bg-gray-200 text-gray-700' : 'bg-[#0d0d1a] text-[#a3a3a3]'
              }`}
            >
              取消
            </button>
          </div>
        </div>
      )}
    </div>
  )
}
