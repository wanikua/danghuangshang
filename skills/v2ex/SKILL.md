---
name: v2ex
description: V2EX API 2.0 integration for accessing V2EX forum data, notifications, topics, nodes, and member profiles
license: MIT
compatibility: opencode
metadata:
  audience: developers
  category: api-integration
  provider: v2ex.com
---

## Overview

This skill provides integration with V2EX API 2.0 Beta, allowing you to access V2EX forum functionality including notifications, topics, nodes, and member information.

## Authentication

V2EX API 2.0 requires a Personal Access Token for authentication.

1. Visit https://www.v2ex.com/settings/tokens to create a token
2. Use the token in the Authorization header: `Authorization: Bearer <your-token>`
3. Store your token securely (e.g., in environment variables)

## API Base URL

```
https://www.v2ex.com/api/v2/
```

## Available Endpoints

### Notifications

#### Get Latest Notifications
```
GET /notifications
```

Optional parameters:
- `p` - Page number (default: 1)

Example:
```bash
curl -H "Authorization: Bearer <token>" \
  "https://www.v2ex.com/api/v2/notifications?p=1"
```

#### Delete a Notification
```
DELETE /notifications/:notification_id
```

Example:
```bash
curl -X DELETE \
  -H "Authorization: Bearer <token>" \
  "https://www.v2ex.com/api/v2/notifications/123456"
```

### Member

#### Get Your Profile
```
GET /member
```

Example:
```bash
curl -H "Authorization: Bearer <token>" \
  "https://www.v2ex.com/api/v2/member"
```

### Token

#### Get Current Token Info
```
GET /token
```

Example:
```bash
curl -H "Authorization: Bearer <token>" \
  "https://www.v2ex.com/api/v2/token"
```

### Nodes

#### Get Node Information
```
GET /nodes/:node_name
```

Example:
```bash
curl -H "Authorization: Bearer <token>" \
  "https://www.v2ex.com/api/v2/nodes/programmer"
```

#### Get Topics in a Node
```
GET /nodes/:node_name/topics
```

Example:
```bash
curl -H "Authorization: Bearer <token>" \
  "https://www.v2ex.com/api/v2/nodes/programmer/topics"
```

### Topics

#### Get Hot Topics (Classic API)
```
GET https://www.v2ex.com/api/topics/hot.json
```

Returns the currently trending topics across all nodes. **No authentication required.**

Example:
```bash
curl -s "https://www.v2ex.com/api/topics/hot.json"
```

#### Get Latest Topics (Classic API)
```
GET https://www.v2ex.com/api/topics/latest.json
```

Returns the most recent topics across all nodes. **No authentication required.**

Example:
```bash
curl -s "https://www.v2ex.com/api/topics/latest.json"
```

#### Get Topic Details (API v2)
```
GET /topics/:topic_id
```

Example:
```bash
curl -H "Authorization: Bearer <token>" \
  "https://www.v2ex.com/api/v2/topics/12345"
```

#### Get Topic Replies (API v2)
```
GET /topics/:topic_id/replies
```

Example:
```bash
curl -H "Authorization: Bearer <token>" \
  "https://www.v2ex.com/api/v2/topics/12345/replies"
```

## Rate Limiting

Default rate limit: 600 requests per hour per IP

Rate limit headers in responses:
- `X-Rate-Limit-Limit` - Total allowed requests
- `X-Rate-Limit-Reset` - Unix timestamp when limit resets
- `X-Rate-Limit-Remaining` - Remaining requests in current window

Note: CDN-cached requests only consume rate limit on the first request.

## Common Workflows

### Check New Notifications
1. Call `GET /notifications` to fetch latest notifications
2. Parse the response for unread items
3. Optionally delete notifications after reading

### Browse Hot Topics
1. Call `GET /api/topics/hot.json` to get trending topics (no token required)
2. Parse response to see popular discussions across all nodes
3. Use topic URLs or IDs to view details on V2EX website

### Browse Node Topics
1. Call `GET /nodes/:node_name/topics` to get topics
2. Use topic IDs to fetch detailed information with `GET /topics/:topic_id`
3. Fetch replies with `GET /topics/:topic_id/replies`

### Monitor Specific Topics
1. Store topic IDs of interest
2. Periodically poll `GET /topics/:topic_id` for updates
3. Check `GET /topics/:topic_id/replies` for new comments

## Response Format

All API responses are in JSON format. Common fields include:
- `success` - Boolean indicating request success
- `message` - Error message if request failed
- Data fields specific to each endpoint

## Error Handling

Common HTTP status codes:
- `200` - Success
- `401` - Unauthorized (invalid or missing token)
- `403` - Forbidden (insufficient permissions)
- `404` - Not found
- `429` - Rate limit exceeded
- `500` - Server error

## Best Practices

1. Store Personal Access Tokens securely (environment variables, not in code)
2. Handle rate limits by checking headers and implementing backoff
3. Cache responses when appropriate to reduce API calls
4. Use pagination for endpoints that support it
5. Handle errors gracefully with user-friendly messages

## References

- V2EX API Documentation: https://www.v2ex.com/help/api
- Personal Access Tokens: https://www.v2ex.com/settings/tokens
- V2EX API Node: https://www.v2ex.com/go/v2ex-api

## Example Implementation (Python)

```python
import os
import requests

class V2EXClient:
    BASE_URL = "https://www.v2ex.com/api/v2"
    
    def __init__(self, token=None):
        self.token = token or os.environ.get('V2EX_TOKEN')
        if not self.token:
            raise ValueError("V2EX token is required")
        self.headers = {
            "Authorization": f"Bearer {self.token}"
        }
    
    def get_notifications(self, page=1):
        """Get latest notifications"""
        response = requests.get(
            f"{self.BASE_URL}/notifications",
            headers=self.headers,
            params={"p": page}
        )
        response.raise_for_status()
        return response.json()
    
    def delete_notification(self, notification_id):
        """Delete a specific notification"""
        response = requests.delete(
            f"{self.BASE_URL}/notifications/{notification_id}",
            headers=self.headers
        )
        response.raise_for_status()
        return response.json()
    
    def get_member(self):
        """Get current member profile"""
        response = requests.get(
            f"{self.BASE_URL}/member",
            headers=self.headers
        )
        response.raise_for_status()
        return response.json()
    
    def get_node(self, node_name):
        """Get node information"""
        response = requests.get(
            f"{self.BASE_URL}/nodes/{node_name}",
            headers=self.headers
        )
        response.raise_for_status()
        return response.json()
    
    def get_node_topics(self, node_name):
        """Get topics in a node"""
        response = requests.get(
            f"{self.BASE_URL}/nodes/{node_name}/topics",
            headers=self.headers
        )
        response.raise_for_status()
        return response.json()
    
    def get_topic(self, topic_id):
        """Get topic details"""
        response = requests.get(
            f"{self.BASE_URL}/topics/{topic_id}",
            headers=self.headers
        )
        response.raise_for_status()
        return response.json()
    
    def get_topic_replies(self, topic_id):
        """Get replies for a topic"""
        response = requests.get(
            f"{self.BASE_URL}/topics/{topic_id}/replies",
            headers=self.headers
        )
        response.raise_for_status()
        return response.json()
    
    def get_hot_topics(self):
        """Get trending topics across all nodes (classic API, no token required)"""
        response = requests.get("https://www.v2ex.com/api/topics/hot.json")
        response.raise_for_status()
        return response.json()
    
    def get_latest_topics(self):
        """Get latest topics across all nodes (classic API, no token required)"""
        response = requests.get("https://www.v2ex.com/api/topics/latest.json")
        response.raise_for_status()
        return response.json()

# Usage example
if __name__ == "__main__":
    client = V2EXClient()
    
    # Get notifications
    notifications = client.get_notifications()
    print(f"You have {len(notifications.get('result', []))} notifications")
    
    # Get member profile
    member = client.get_member()
    print(f"Hello, {member.get('result', {}).get('username')}!")
    
    # Get node info
    node = client.get_node("python")
    print(f"Node: {node.get('result', {}).get('title')}")
    
    # Get topics from a node
    topics = client.get_node_topics("python")
    for topic in topics.get('result', []):
        print(f"- {topic.get('title')}")
    
    # Get hot topics (no token required)
    hot_topics = client.get_hot_topics()
    print("\n🔥 Hot Topics:")
    for topic in hot_topics[:5]:
        print(f"- [{topic['node']['title']}] {topic['title']} ({topic['replies']} replies)")
```

## Testing with REST Client

You can use VS Code's REST Client extension to test the API:

```http
### Get hot topics (classic API, no auth required)
GET https://www.v2ex.com/api/topics/hot.json

### Get latest topics (classic API, no auth required)
GET https://www.v2ex.com/api/topics/latest.json

### Get notifications
GET https://www.v2ex.com/api/v2/notifications
Authorization: Bearer <your-token>

### Get member profile
GET https://www.v2ex.com/api/v2/member
Authorization: Bearer <your-token>

### Get node info
GET https://www.v2ex.com/api/v2/nodes/programmer
Authorization: Bearer <your-token>

### Get topic
GET https://www.v2ex.com/api/v2/topics/12345
Authorization: Bearer <your-token>
```
