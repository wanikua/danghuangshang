#!/usr/bin/env node

const args = process.argv.slice(2);
const command = args[0];
const subarg = args[1];

// Parse flags
const flags = {};
for (let i = 0; i < args.length; i++) {
  if (args[i].startsWith('--')) {
    const key = args[i].slice(2);
    flags[key] = (i + 1 < args.length && !args[i + 1]?.startsWith('--')) ? args[i + 1] : true;
  }
  if (args[i] === '-n' && args[i + 1]) flags.n = parseInt(args[i + 1]);
}

const json = flags.json || false;
const count = flags.n || 10;

// ── Mock data ──────────────────────────────────────────────────────────

const mockUsers = {
  '@elonmusk': { name: 'Elon Musk', handle: '@elonmusk', followers: 195_000_000, following: 820, bio: 'Mars & Cars, Chips & Dips', verified: true },
  '@openai': { name: 'OpenAI', handle: '@openai', followers: 4_200_000, following: 150, bio: 'Creating safe AGI.', verified: true },
  '@steipete': { name: 'Peter Steinberger', handle: '@steipete', followers: 45_000, following: 1_200, bio: 'Building OpenClaw 🦞', verified: true },
  '@github': { name: 'GitHub', handle: '@github', followers: 3_800_000, following: 300, bio: 'How people build software.', verified: true },
};

function mockTweet(id, author, text, extra = {}) {
  return {
    id,
    author: author.replace('@', ''),
    handle: author,
    text,
    created_at: new Date(Date.now() - Math.random() * 86400000 * 7).toISOString(),
    likes: Math.floor(Math.random() * 50000),
    retweets: Math.floor(Math.random() * 10000),
    replies: Math.floor(Math.random() * 2000),
    bookmarks: Math.floor(Math.random() * 500),
    ...extra,
  };
}

const mockTweets = [
  mockTweet('1893001', '@elonmusk', 'The future of AI is incredibly exciting. We are building things that will change everything.'),
  mockTweet('1893002', '@openai', 'Introducing our latest research on reasoning models. Blog post in thread. 🧵'),
  mockTweet('1893003', '@steipete', 'Just shipped a massive OpenClaw update — 50 new skills, faster inference, and better memory. Try it!'),
  mockTweet('1893004', '@github', 'GitHub Copilot now supports multi-file editing. The future of dev is here.'),
  mockTweet('1893005', '@elonmusk', 'Starship flight test 7 was a success. Next stop: Mars.'),
  mockTweet('1893006', '@openai', 'We are hiring researchers across safety, alignment, and capabilities. Apply now.'),
  mockTweet('1893007', '@steipete', 'OpenClaw can now order food, control your lights, and manage your calendar. All locally. 🦞'),
  mockTweet('1893008', '@github', 'Over 100 million developers now call GitHub home. Thank you.'),
  mockTweet('1893009', '@elonmusk', 'FSD v13 rolling out this week. Biggest neural net update yet.'),
  mockTweet('1893010', '@openai', 'GPT-5 is coming. Stay tuned.'),
];

const mockTrending = [
  { rank: 1, topic: '#AI', tweets: '2.1M' },
  { rank: 2, topic: '#OpenClaw', tweets: '450K' },
  { rank: 3, topic: 'Starship', tweets: '380K' },
  { rank: 4, topic: '#CodingTwitter', tweets: '290K' },
  { rank: 5, topic: 'GPT-5', tweets: '1.8M' },
  { rank: 6, topic: '#OpenSource', tweets: '210K' },
  { rank: 7, topic: 'GitHub Copilot', tweets: '175K' },
  { rank: 8, topic: '#TypeScript', tweets: '140K' },
  { rank: 9, topic: 'Mars', tweets: '320K' },
  { rank: 10, topic: '#DevOps', tweets: '95K' },
];

// ── Formatters ─────────────────────────────────────────────────────────

function fmtTweet(t) {
  if (json) return JSON.stringify(t, null, 2);
  return [
    `${t.author} (${t.handle}) · ${new Date(t.created_at).toLocaleDateString()}`,
    t.text,
    `❤️ ${t.likes.toLocaleString()}  🔁 ${t.retweets.toLocaleString()}  💬 ${t.replies.toLocaleString()}  🔖 ${t.bookmarks.toLocaleString()}`,
    `ID: ${t.id}`,
    '---',
  ].join('\n');
}

function fmtUser(u) {
  if (json) return JSON.stringify(u, null, 2);
  return [
    `${u.name} (${u.handle}) ${u.verified ? '✓' : ''}`,
    u.bio,
    `Followers: ${u.followers.toLocaleString()} · Following: ${u.following.toLocaleString()}`,
    '---',
  ].join('\n');
}

// ── Commands ───────────────────────────────────────────────────────────

function checkAuth() {
  if (!process.env.TWITTER_BEARER_TOKEN) {
    console.error('Error: TWITTER_BEARER_TOKEN is not set.');
    console.error('Set it with: export TWITTER_BEARER_TOKEN=your_token');
    process.exit(1);
  }
}

switch (command) {
  case 'auth-check': {
    if (process.env.TWITTER_BEARER_TOKEN) {
      console.log('✓ TWITTER_BEARER_TOKEN is set');
      console.log(`Token: ${process.env.TWITTER_BEARER_TOKEN.slice(0, 8)}...`);
      console.log(process.env.TWITTER_API_KEY ? '✓ TWITTER_API_KEY is set (write ops enabled)' : '⚠ TWITTER_API_KEY not set (read-only mode)');
    } else {
      console.error('✗ TWITTER_BEARER_TOKEN is NOT set');
      process.exit(1);
    }
    break;
  }

  case 'read': {
    checkAuth();
    const id = subarg?.replace(/.*status\//, '').replace(/\D/g, '') || '1893001';
    const tweet = mockTweets.find(t => t.id === id) || mockTweet(id, '@elonmusk', 'This is the requested tweet content. [mock data]');
    console.log(fmtTweet(tweet));
    break;
  }

  case 'thread': {
    checkAuth();
    const threadTweets = [
      mockTweet('1893002', '@openai', 'Introducing our latest research on reasoning models. Blog post in thread. 🧵'),
      mockTweet('1893002a', '@openai', '1/ We trained a new model that can reason step-by-step through complex problems.'),
      mockTweet('1893002b', '@openai', '2/ It achieves state-of-the-art on math, coding, and science benchmarks.'),
      mockTweet('1893002c', '@openai', '3/ Read the full paper and try the model: https://openai.com/research [mock]'),
    ];
    threadTweets.forEach(t => console.log(fmtTweet(t)));
    break;
  }

  case 'replies': {
    checkAuth();
    const replyTweets = Array.from({ length: Math.min(count, 5) }, (_, i) =>
      mockTweet(`r${i}`, ['@dev_jane', '@ai_bob', '@coder42', '@techfan', '@oss_lover'][i], [
        'This is amazing! Can\'t wait to try it.',
        'How does this compare to the previous version?',
        'Incredible work by the team 👏',
        'Any benchmarks on real-world tasks?',
        'Open source when?',
      ][i])
    );
    replyTweets.forEach(t => console.log(fmtTweet(t)));
    break;
  }

  case 'user': {
    checkAuth();
    const handle = subarg?.startsWith('@') ? subarg : `@${subarg}`;
    const user = mockUsers[handle] || { name: handle.slice(1), handle, followers: 1234, following: 567, bio: 'Twitter user. [mock data]', verified: false };
    console.log(fmtUser(user));
    break;
  }

  case 'user-tweets': {
    checkAuth();
    const handle = subarg?.startsWith('@') ? subarg : `@${subarg || 'elonmusk'}`;
    const tweets = mockTweets.filter(t => t.handle === handle).slice(0, count);
    if (tweets.length === 0) {
      console.log(fmtTweet(mockTweet('u1', handle, 'Latest thoughts from this account. [mock data]')));
    } else {
      tweets.forEach(t => console.log(fmtTweet(t)));
    }
    break;
  }

  case 'home': {
    checkAuth();
    mockTweets.slice(0, count).forEach(t => console.log(fmtTweet(t)));
    break;
  }

  case 'mentions': {
    checkAuth();
    const mentions = [
      mockTweet('m1', '@dev_jane', '@you Great post! Totally agree with your take on AI agents.'),
      mockTweet('m2', '@coder42', '@you Have you tried the new OpenClaw update? It\'s wild.'),
      mockTweet('m3', '@techfan', '@you Thanks for the recommendation!'),
    ];
    mentions.slice(0, count).forEach(t => console.log(fmtTweet(t)));
    break;
  }

  case 'likes': {
    checkAuth();
    mockTweets.slice(0, count).forEach(t => console.log(fmtTweet(t)));
    break;
  }

  case 'search': {
    checkAuth();
    const query = subarg || '';
    const results = mockTweets.filter(t =>
      t.text.toLowerCase().includes(query.toLowerCase()) ||
      t.handle.toLowerCase().includes(query.toLowerCase())
    );
    if (results.length === 0) {
      // Return some generic results
      mockTweets.slice(0, Math.min(count, 3)).forEach(t => console.log(fmtTweet(t)));
    } else {
      results.slice(0, count).forEach(t => console.log(fmtTweet(t)));
    }
    console.log(`\n${results.length || 3} results for "${query}"`);
    break;
  }

  case 'trending': {
    checkAuth();
    if (json) {
      console.log(JSON.stringify(mockTrending, null, 2));
    } else {
      mockTrending.forEach(t => console.log(`${t.rank}. ${t.topic} — ${t.tweets} tweets`));
    }
    break;
  }

  case 'tweet': {
    checkAuth();
    const text = subarg || '';
    if (!text) { console.error('Error: tweet text required.'); process.exit(1); }
    const newId = Date.now().toString().slice(-7);
    console.log(`✓ Tweet posted successfully!`);
    console.log(fmtTweet(mockTweet(newId, '@you', text)));
    break;
  }

  case 'reply': {
    checkAuth();
    const replyTo = subarg;
    const replyText = args[2] || '';
    if (!replyTo || !replyText) { console.error('Error: usage: twclaw reply <tweet-id> "text"'); process.exit(1); }
    const newId = Date.now().toString().slice(-7);
    console.log(`✓ Reply posted to ${replyTo}`);
    console.log(fmtTweet(mockTweet(newId, '@you', replyText)));
    break;
  }

  case 'quote': {
    checkAuth();
    const quoteId = subarg;
    const quoteText = args[2] || '';
    if (!quoteId || !quoteText) { console.error('Error: usage: twclaw quote <tweet-id> "text"'); process.exit(1); }
    const newId = Date.now().toString().slice(-7);
    console.log(`✓ Quote tweet posted for ${quoteId}`);
    console.log(fmtTweet(mockTweet(newId, '@you', quoteText)));
    break;
  }

  case 'like': {
    checkAuth();
    console.log(`✓ Liked tweet ${subarg}`);
    break;
  }

  case 'unlike': {
    checkAuth();
    console.log(`✓ Unliked tweet ${subarg}`);
    break;
  }

  case 'retweet': {
    checkAuth();
    console.log(`✓ Retweeted ${subarg}`);
    break;
  }

  case 'unretweet': {
    checkAuth();
    console.log(`✓ Removed retweet ${subarg}`);
    break;
  }

  case 'bookmark': {
    checkAuth();
    console.log(`✓ Bookmarked tweet ${subarg}`);
    break;
  }

  case 'unbookmark': {
    checkAuth();
    console.log(`✓ Removed bookmark for tweet ${subarg}`);
    break;
  }

  case 'follow': {
    checkAuth();
    console.log(`✓ Now following ${subarg}`);
    break;
  }

  case 'unfollow': {
    checkAuth();
    console.log(`✓ Unfollowed ${subarg}`);
    break;
  }

  case 'followers': {
    checkAuth();
    const handle = subarg?.startsWith('@') ? subarg : '@you';
    Object.values(mockUsers).slice(0, count).forEach(u => console.log(fmtUser(u)));
    break;
  }

  case 'following': {
    checkAuth();
    Object.values(mockUsers).slice(0, count).forEach(u => console.log(fmtUser(u)));
    break;
  }

  case 'lists': {
    checkAuth();
    const lists = [
      { id: 'lst-1', name: 'AI Researchers', members: 42 },
      { id: 'lst-2', name: 'Dev Tools', members: 28 },
      { id: 'lst-3', name: 'Tech News', members: 15 },
    ];
    if (json) { console.log(JSON.stringify(lists, null, 2)); }
    else { lists.forEach(l => console.log(`${l.id} — ${l.name} (${l.members} members)`)); }
    break;
  }

  case 'list-timeline': {
    checkAuth();
    mockTweets.slice(0, count).forEach(t => console.log(fmtTweet(t)));
    break;
  }

  case 'list-add': {
    checkAuth();
    console.log(`✓ Added ${args[2]} to list ${subarg}`);
    break;
  }

  case 'list-remove': {
    checkAuth();
    console.log(`✓ Removed ${args[2]} from list ${subarg}`);
    break;
  }

  default: {
    console.log(`twclaw — Twitter/X CLI for OpenClaw

Usage: twclaw <command> [options]

Commands:
  auth-check                   Verify credentials
  read <id>                    Read a tweet
  thread <id>                  Read full thread
  replies <id>                 List replies
  user <@handle>               Show user profile
  user-tweets <@handle>        User's tweets
  home                         Home timeline
  mentions                     Your mentions
  likes <@handle>              User's likes
  search "query"               Search tweets
  trending                     Trending topics
  tweet "text"                 Post a tweet
  reply <id> "text"            Reply to a tweet
  quote <id> "text"            Quote tweet
  like/unlike <id>             Like/unlike
  retweet/unretweet <id>       Retweet/undo
  bookmark/unbookmark <id>     Bookmark/remove
  follow/unfollow <@handle>    Follow/unfollow
  followers/following <@handle> Social graph
  lists                        Your lists
  list-timeline <id>           List tweets
  list-add <id> <@handle>      Add to list
  list-remove <id> <@handle>   Remove from list

Options:
  --json      JSON output
  --plain     Plain text
  -n <count>  Number of results (default: 10)
  --cursor    Pagination cursor
`);
    break;
  }
}
