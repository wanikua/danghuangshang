#!/bin/bash
# Boluo GUI Server Keepalive
# Ensures node server/index.js stays running on port 18795

SERVER_DIR="$(cd "$(dirname "$0")/gui" && pwd)"
LOG_FILE="/tmp/boluo-gui.log"
PID_FILE="/tmp/boluo-gui.pid"
CHECK_INTERVAL=15

start_server() {
  echo "$(date): Starting Boluo GUI server..." >> "$LOG_FILE"
  cd "$SERVER_DIR" || exit 1
  nohup node index.js >> "$LOG_FILE" 2>&1 &
  local pid=$!
  echo "$pid" > "$PID_FILE"
  echo "$(date): Server started with PID $pid" >> "$LOG_FILE"
}

is_running() {
  # Check if port 18795 is listening (ss -> lsof -> curl fallback)
  if command -v ss &>/dev/null; then
    ss -tlnp 2>/dev/null | grep -q ':18795 ' && return 0
  elif command -v lsof &>/dev/null; then
    lsof -i :18795 -sTCP:LISTEN &>/dev/null && return 0
  else
    curl -sf http://localhost:18795/api/health &>/dev/null && return 0
  fi
  return 1
}

cleanup() {
  echo "$(date): Keepalive shutting down..." >> "$LOG_FILE"
  if [ -f "$PID_FILE" ]; then
    kill "$(cat "$PID_FILE")" 2>/dev/null
    rm -f "$PID_FILE"
  fi
  exit 0
}

trap cleanup SIGTERM SIGINT

echo "$(date): Keepalive started (check every ${CHECK_INTERVAL}s)" >> "$LOG_FILE"

while true; do
  if ! is_running; then
    echo "$(date): Server not running, restarting..." >> "$LOG_FILE"
    # [M-12] Kill any zombie processes on the port (use fuser, fallback to ss+awk)
    if command -v fuser &>/dev/null; then
      fuser -k 18795/tcp 2>/dev/null
    else
      ss -tlnp 2>/dev/null | grep ':18795 ' | grep -oP 'pid=\K[0-9]+' | xargs kill 2>/dev/null
    fi
    sleep 1
    start_server
    sleep 3
  fi
  sleep "$CHECK_INTERVAL"
done
