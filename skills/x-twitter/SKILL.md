---
name: twitter-openclaw
description: Interact with Twitter/X — read tweets, search, post, like, retweet, and manage your timeline.
user-invocable: true
metadata: {"openclaw":{"emoji":"🐦‍⬛","skillKey":"twitter-openclaw","primaryEnv":"TWITTER_BEARER_TOKEN","requires":{"bins":["twclaw"],"env":["TWITTER_BEARER_TOKEN"]},"install":[{"id":"npm","kind":"node","package":"twclaw","bins":["twclaw"],"label":"Install twclaw (npm)"}]}}
---

# twitter-openclaw 🐦‍⬛

Interact with Twitter/X posts, timelines, and users from OpenClaw.

## Authentication

Requires a Twitter API Bearer Token set as `TWITTER_BEARER_TOKEN`.

Optionally set `TWITTER_API_KEY` and `TWITTER_API_SECRET` for write operations (post, like, retweet).

Run `twclaw auth-check` to verify credentials.

## Commands

### Reading

```bash
twclaw read <tweet-url-or-id>          # Read a single tweet with full metadata
twclaw thread <tweet-url-or-id>        # Read full conversation thread
twclaw replies <tweet-url-or-id> -n 20 # List replies to a tweet
twclaw user <@handle>                  # Show user profile info
twclaw user-tweets <@handle> -n 20     # User's recent tweets
```

### Timelines

```bash
twclaw home -n 20                      # Home timeline
twclaw mentions -n 10                  # Your mentions
twclaw likes <@handle> -n 10           # User's liked tweets
```

### Search

```bash
twclaw search "query" -n 10            # Search tweets
twclaw search "from:elonmusk AI" -n 5  # Search with operators
twclaw search "#trending" --recent     # Recent tweets only
twclaw search "query" --popular        # Popular tweets only
```

### Trending

```bash
twclaw trending                        # Trending topics worldwide
twclaw trending --woeid 23424977       # Trending in specific location
```

### Posting

```bash
twclaw tweet "hello world"                          # Post a tweet
twclaw reply <tweet-url-or-id> "great thread!"      # Reply to a tweet
twclaw quote <tweet-url-or-id> "interesting take"   # Quote tweet
twclaw tweet "look at this" --media image.png        # Tweet with media
```

### Engagement

```bash
twclaw like <tweet-url-or-id>          # Like a tweet
twclaw unlike <tweet-url-or-id>        # Unlike a tweet
twclaw retweet <tweet-url-or-id>       # Retweet
twclaw unretweet <tweet-url-or-id>     # Undo retweet
twclaw bookmark <tweet-url-or-id>      # Bookmark a tweet
twclaw unbookmark <tweet-url-or-id>    # Remove bookmark
```

### Following

```bash
twclaw follow <@handle>                # Follow user
twclaw unfollow <@handle>              # Unfollow user
twclaw followers <@handle> -n 20       # List followers
twclaw following <@handle> -n 20       # List following
```

### Lists

```bash
twclaw lists                           # Your lists
twclaw list-timeline <list-id> -n 20   # Tweets from a list
twclaw list-add <list-id> <@handle>    # Add user to list
twclaw list-remove <list-id> <@handle> # Remove user from list
```

## Output Options

```bash
--json          # JSON output
--plain         # Plain text, no formatting
--no-color      # Disable ANSI colors
-n <count>      # Number of results (default: 10)
--cursor <val>  # Pagination cursor for next page
--all           # Fetch all pages (use with caution)
```

## Guidelines for OpenClaw

- When reading tweets, always show: author, handle, text, timestamp, engagement counts.
- For threads, present tweets in chronological order.
- When searching, summarize results concisely with key metrics.
- Before posting/liking/retweeting, confirm the action with the user.
- Rate limits apply — space out bulk operations.
- Use `--json` when you need to process output programmatically.

## Troubleshooting

### 401 Unauthorized
Check that `TWITTER_BEARER_TOKEN` is set and valid.

### 429 Rate Limited
Wait and retry. Twitter API has strict rate limits per 15-minute window.

---

**TL;DR**: Read, search, post, and engage on Twitter/X. Always confirm before write actions.
