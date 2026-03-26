#!/bin/bash
LOG="/tmp/oauth-refresh.log"

echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) Starting OAuth token refresh..." >> "$LOG"

REFRESH_TOKEN=$(python3 /home/ubuntu/clawd/scripts/extract-refresh-token.py)

if [ -z "$REFRESH_TOKEN" ]; then
    echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) ERROR: No refresh token found" >> "$LOG"
    exit 1
fi

RESPONSE=$(curl -s -X POST "https://platform.claude.com/v1/oauth/token" \
    -H "Content-Type: application/json" \
    -d "{\"grant_type\":\"refresh_token\",\"refresh_token\":\"$REFRESH_TOKEN\",\"client_id\":\"9d1c250a-e61b-44d9-88ed-5944d1962f5e\",\"scope\":\"user:profile user:inference user:sessions:claude_code user:mcp_servers\"}")

echo "$RESPONSE" > /tmp/oauth-response.json

python3 /home/ubuntu/clawd/scripts/update-oauth-token.py
STATUS=$?

if [ $STATUS -eq 0 ]; then
    echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) Token refreshed successfully" >> "$LOG"
else
    echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) ERROR: Token update failed" >> "$LOG"
fi

rm -f /tmp/oauth-response.json
