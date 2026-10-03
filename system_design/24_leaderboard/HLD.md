# Real-Time Leaderboard (gaming, contests, fitness apps): High-Level Design

**Asked at:** Amazon, Microsoft, Riot/Activision/EA, LeetCode, Strava. **Core topics:** sorted sets (Redis ZSET / skip lists), rank queries in O(log n), time-windowed boards, ties, sharding a single huge leaderboard, persistence and recovery.

## 1. Clarify the scope

| Question | Assumed answer |
|---|---|
| Boards? | Per game: all-time, monthly, daily. (Per-region and friends-only as follow-ups.) |
| Operations? | Add points for a user; top N; a user's rank; users around a user's rank. |
| Scale? | 50 M daily active players, 25 M on the monthly board; ~1 B score updates/day at peak events. |
| Freshness? | Real-time: a player sees the new rank immediately after a match. |
| Ties? | Equal scores: whoever reached the score first ranks higher. |

## 2. Requirements

**Functional:** `addPoints(user, n)`, `top(k)`, `rank(user)`, `around(user, n)`, window rollover.

**Non-functional:** low latency (< 10 ms per operation), high write throughput, durability of scores (they matter to players), availability during events.

## 3. Capacity estimates

| Quantity | Math | Result |
|---|---|---|
| Score updates | ~1 B/day | **~12K/s** avg, **~100K/s** peak |
| Rank reads | after every match + browsing | similar order |
| Memory per board entry | member ID (~16 B) + score + skip-list pointers (~2 levels avg) | **~60-100 B** |
| Monthly board | 25 M x ~100 B | **~2.5 GB**: one Redis instance holds it |

One board fits in one node's memory; throughput (100K ops/s) is near one Redis node's limit, so plan replicas for reads and sharding for the largest boards.

## 4. Why a sorted set

| Approach | Update | Rank of a user | Top k |
|---|---|---|---|
| SQL `ORDER BY score` + `COUNT(*) WHERE score > x` | O(log n) | O(n) count at 25 M rows: too slow per request | fine with an index |
| **Sorted set (skip list + hash map)** | **O(log n)** | **O(log n)** via span counts | O(log n + k) |
| Balanced tree with subtree sizes (order statistic tree) | O(log n) | O(log n) | O(log n + k) |

Redis: `ZINCRBY board:monthly:2025-01 50 user42`, `ZREVRANK board:... user42`, `ZREVRANGE board:... 0 9 WITHSCORES`.

**Ties by time:** encode `score * 2^k + (MAX_TIME - timestamp)` into the sorted value, or keep a tie-break key as the skip list does in the LLD.

## 5. Architecture

```text
 game servers --(match result)--> Score service --(1) append to score events (Kafka / DB, durable)
                                           |     --(2) ZINCRBY on each window's board (all-time, monthly, daily)
                                           v
                                    Redis cluster (one sorted set per board; replicas for reads)
 clients --> Leaderboard API --> top k (cached a few seconds), rank(user), around(user)
 Daily/monthly windows: new keys per period; old keys expire after archiving final standings to the DB
 Recovery: rebuild a board by replaying score events (or from periodic snapshots + events since)
```

The **score event log is the source of truth**; Redis is a fast, rebuildable view. Players' scores are never stored only in memory.

## 6. Deep dive: one huge board (hundreds of millions of players)

- **Shard by score range:** shard 1 holds scores 0-999, shard 2 1000-1999, ... A user's rank = (number of users in higher shards, from per-shard counts) + rank within its shard. Updates crossing a boundary move the user between shards. Ranges must be tuned to the score distribution.
- **Approximate ranks for the long tail:** exact for the top 10K; for others, "top 37%" from a score histogram (buckets with counts). Players far from the top do not need an exact number.
- Hash sharding by user does not work for ranks: every rank query would need all shards.

## 7. Failure modes

| Failure | Behavior |
|---|---|
| Redis primary fails | Replica promoted; a few seconds of updates may be lost from the view and are replayed from the event log. |
| Duplicate match result (retries) | Score events carry a match ID; the score service applies each once. |
| Window rollover at midnight | New key per period; the client asks for the current period's key; no mass deletes. |

## 8. What interviewers look for

- Why a database `COUNT(*)` rank does not scale, and the sorted-set answer.
- Time windows as separate keys.
- Durability: event log + rebuildable cache.
- Sharding approach for the very large case, including approximate ranks.

## 9. Common mistakes

- Recomputing and storing every user's rank after each update (O(n) writes).
- Sharding by user ID and then needing scatter-gather for every rank.
- Forgetting tie-breaking (unstable ranks between refreshes).
- Treating Redis as the only copy of scores.

## 10. Follow-ups

1. **Friends leaderboard:** fetch friends' scores (small set) and sort on the fly.
2. **Anti-cheat:** validate scores server-side; flag outliers before they hit the public board.
3. **Prizes at period end:** snapshot the final top N to the database with the period key.

See [LLD.md](LLD.md) for a skip list with rank spans (the Redis ZSET structure), the leaderboard facade with ties and windows, and a brute-force cross-check.
