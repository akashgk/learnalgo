# News Feed (Twitter / Instagram / Facebook home timeline): High-Level Design

**Asked at:** Meta, Twitter/X, LinkedIn, Amazon, Google. **Core topics:** fan-out on write vs fan-out on read, the celebrity problem, timeline caches, pagination, ranking.

## 1. Clarify the scope

| Question | Assumed answer |
|---|---|
| Content? | Posts with text and media links. |
| Social graph? | Follow (directed), like Twitter or Instagram. |
| Feed order? | Reverse chronological first; ranking as a follow-up. |
| Scale? | 300 M DAU, each opens the feed ~10 times a day; 50 M new posts per day. |
| Follow counts? | Median ~200 followees; a few accounts have 100 M+ followers. |
| Latency? | Feed load p99 < ~300 ms. |
| Freshness? | A new post may take a few seconds to appear in followers' feeds. |

## 2. Requirements

**Functional:** publish a post; follow/unfollow; get the home feed (posts from people I follow), paginated, newest first.

**Non-functional:** fast feed reads (read-heavy), high availability, eventual consistency is acceptable, handles celebrities without melting down.

## 3. Capacity estimates

| Quantity | Math | Result |
|---|---|---|
| Feed reads | 300 M x 10 / 86,400 | **~35K/s** avg, ~100K/s peak |
| Post writes | 50 M / 86,400 | **~600/s** avg, ~2K/s peak |
| Fan-out deliveries (push everything) | 600/s x ~200 avg followers | **~120K timeline inserts/s** (and one celebrity post = 100 M inserts) |
| Timeline cache | 300 M users x 800 post IDs x 8 B | **~2 TB** of IDs (Redis cluster); store IDs only |
| Post storage | 50 M x 1 KB metadata | **50 GB/day**; media separately in blob storage + CDN |

Reads outnumber writes ~60:1, so precomputing feeds is attractive, but the fan-out numbers show why celebrities need special treatment.

## 4. API

```text
POST /posts                      { text, mediaIds[] }            -> { postId }
POST /users/{id}/follow          DELETE /users/{id}/follow
GET  /feed?cursor=<opaque>&limit=20  -> { posts: [...], nextCursor }
```

The cursor encodes the last seen `(timestamp, postId)`, not a page number: new posts arriving at the top must not shift pages and cause duplicates.

## 5. Data model

```text
posts       post_id (time-sortable, e.g. Snowflake: timestamp + machine + seq), author_id, text, media, created_at
            -> sharded by post_id; plus an index author_id -> recent post_ids (user timeline)
follows     (follower_id, followee_id)        -- two tables for both directions:
            followers_of(followee_id -> follower_ids), following_of(follower_id -> followee_ids)
timelines   Redis: feed:{user_id} -> sorted set / list of post_ids, capped at ~800
```

**Time-sortable IDs** (Snowflake) let us sort and paginate by ID alone, and merge lists from many sources cheaply.

## 6. The core decision: fan-out on write vs on read

| | Fan-out on write (push) | Fan-out on read (pull) |
|---|---|---|
| On post | insert the post ID into every follower's cached timeline | store the post once |
| On feed read | read one precomputed list: very fast | fetch recent posts of every followee and merge: slow for users following many accounts |
| Cost | write amplification = follower count; wasted work for inactive followers | read amplification = followee count, on every load |
| Celebrity with 100 M followers | 100 M inserts per post: minutes of lag, huge load | trivial |

**Hybrid (the expected answer):**

- Normal authors: **push** to followers' timelines (and only to followers active in the last ~30 days).
- Celebrities (followers above a threshold, say 100K): **do not push**. At read time, fetch recent posts from the celebrities the user follows (few per user, and their recent posts are extremely cache-hot) and **merge** them with the precomputed timeline.

## 7. Architecture

```text
            +--> Post service --> Posts DB (sharded) + Media (S3 + CDN)
 client --> API gateway
            |        \--> post event --> Kafka --> Fan-out workers --+--> Timeline cache (Redis, feed:{user})
            |                                       |               |
            |                                 Graph service         +--(skip if author is a celebrity)
            |                              (followers_of, cached)
            |
            +--> Feed service --> 1. read feed:{me} from Redis (pushed post IDs)
                                  2. read my followed celebrities' recent post IDs (cache)
                                  3. merge by ID (time order), take a page
                                  4. hydrate: batch get posts + authors + counts (caches)
                                  5. (optional) rank
```

## 8. Deep dives

**Fan-out workers.** Consume post events from Kafka, page through the author's followers (in batches of a few thousand), and `ZADD`/`LPUSH` to each timeline with trimming (`LTRIM` to 800). Asynchronous, so posting returns immediately. Workers scale horizontally by partition.

**Hydration.** The timeline holds IDs only; the feed service batch-fetches post objects (`MGET` from a post cache), author profiles, and like counts. Keeps the timeline cache small and lets edits and deletes show up immediately.

**Deletes and unfollows.** Do not scrub millions of timelines: filter at read time (deleted posts fail hydration; unfollowed authors are filtered against the current follow set) and let entries age out.

**Cold users.** A user inactive for months has no cached timeline; build it on demand with fan-out on read (pull from followees) and cache it.

**Pagination.** Cursor = last post ID served. Next page = entries with ID less than the cursor. Stable even as new posts arrive at the top.

**Ranking (follow-up).** Fetch a few hundred candidates (as above), score them with a model (engagement probability, recency, author affinity), return the top N. Ranking makes caching per-page harder: cache the candidate list, re-rank cheaply.

## 9. Scaling and failure modes

| Concern | Answer |
|---|---|
| Celebrity posts | Hybrid model (no push above the threshold). |
| Redis timeline loss | Rebuild on demand from the follow graph and posts (pull path). Timelines are a cache, not the source of truth. |
| Fan-out lag spikes | Kafka buffers; prioritize active users; monitor consumer lag. |
| Hot posts (viral) | Post objects cached and replicated; like counts aggregated asynchronously (approximate is fine). |
| Graph service load | Follower lists are paged and cached; the fan-out reads them sequentially. |

## 10. What interviewers look for

- Push vs pull trade-off, with numbers, ending in the hybrid.
- Storing IDs in timelines and hydrating at read time.
- Cursor-based pagination.
- Treating the timeline cache as rebuildable.

## 11. Common mistakes

- Pure fan-out on write with no celebrity handling (one post -> 100 M writes).
- Pure fan-out on read for every request at 100K reads/s.
- Offset pagination (`page=3`) on a feed that changes constantly.
- Storing full post objects in every follower's timeline.

## 12. Follow-ups

1. **Ranked feed:** candidate generation + ranking service; A/B testing.
2. **Notifications for new posts:** separate pipeline (see 07 Notification System).
3. **Ads injection:** merge ad slots at fixed positions after ranking.
4. **Edits:** hydration reads the latest version, so timelines need no change.

See [LLD.md](LLD.md) for the classes: posts, follow graph, the hybrid fan-out and cursor pagination.
