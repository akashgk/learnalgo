# URL Shortener (TinyURL / bit.ly): High-Level Design

**Asked at:** almost everywhere as a warm-up or first system design round. **Core topics:** ID generation, read-heavy caching, key-value storage, redirects.

## 1. Clarify the scope (first 5 minutes)

Ask, then write the answers down:

| Question | Assumed answer |
|---|---|
| Core features? | Create a short link for a long URL; redirect a short link to its long URL. |
| Custom aliases (`bit.ly/my-sale`)? | Yes, optional. |
| Expiration? | Optional per link; default never. |
| Analytics (click counts)? | Yes, but can be eventually consistent (minutes of delay is fine). |
| Same long URL twice: same short link? | Not required. Each request may get a new code (simpler, and different users may want separate analytics). |
| Who uses it? | Public API and web UI. Authentication only for link management, not for redirects. |
| Can links be edited or deleted? | Deleted, yes; edited, no (out of scope). |

## 2. Requirements

**Functional**

1. `shorten(longUrl, alias?, ttl?) -> shortUrl`
2. `GET /{code}` redirects to the long URL.
3. Per-link click counts.

**Non-functional**

- **Very read-heavy:** assume 100 reads per write.
- **Low redirect latency:** the redirect is in the user's critical path. Target p99 below ~50 ms inside our system.
- **High availability for redirects:** a broken short link breaks every page that embeds it. Writes can be slightly less available.
- **Durability:** a created link must never be lost or remapped to a different URL.
- **Short codes:** as short as possible; ideally not trivially enumerable.

## 3. Capacity estimates

These are assumptions to size the system; say them out loud and round aggressively.

| Quantity | Assumption / math | Result |
|---|---|---|
| New links | 100 M per day | 100,000,000 / 86,400 ≈ **1,160 writes/s** (peak ~3x: ~3.5K/s) |
| Redirects | 100 : 1 read/write ratio | 10 B per day ≈ **116K reads/s** (peak ~350K/s) |
| Records over 5 years | 100 M x 365 x 5 | **182.5 B links** |
| Size per record | code, long URL (avg ~400 B), timestamps, owner | ~500 B |
| Storage over 5 years | 182.5 B x 500 B | **~91 TB** (before replication) |
| Code length | base62 with 7 characters: 62^7 | **3.52 trillion** codes, about 19x the 182.5 B needed |
| Cache | hottest links; if ~1 B distinct links are hit per day and we cache 20% | 200 M x 500 B = **~100 GB**, a small Redis cluster |
| Redirect bandwidth | 116K/s x ~500 B | **~58 MB/s** |

Conclusions that drive the design: reads dominate (cache everything hot), the data is huge but simple key -> value (a distributed key-value store fits), and 7 base62 characters are enough.

## 4. API

```text
POST /api/v1/links
  body: { "longUrl": "https://...", "alias": "my-sale"?, "ttlSeconds": 86400? }
  201: { "code": "a9X3kQ2", "shortUrl": "https://sho.rt/a9X3kQ2", "expiresAt": "..."? }
  400 invalid URL, 409 alias taken, 429 rate limited

GET /{code}
  302 Location: <longUrl>      (or 301, see the deep dive)
  404 unknown code, 410 expired

GET /api/v1/links/{code}/stats   -> { "clicks": 1234, ... }   (owner only)
DELETE /api/v1/links/{code}                                     (owner only)
```

Rate-limit `POST` per API key and per IP: link shorteners are abused by spammers (see 02 Rate Limiter).

## 5. Data model

One main table, accessed only by `code`:

```text
links
  code        string   PRIMARY KEY      (7 chars, or the custom alias)
  long_url    string
  owner_id    string?
  created_at  timestamp
  expires_at  timestamp?                (DB-level TTL if supported)
```

Clicks live elsewhere (analytics store, see below), so the hot `links` row is never written on reads.

**Which database?** The access pattern is a single-key lookup, no joins, no multi-row transactions, ~91 TB growing forever. A horizontally partitioned key-value or wide-column store (DynamoDB, Cassandra, or sharded MySQL keyed by `code`) fits. Partition by `code` (hash), which spreads load evenly. A relational database works too if sharded; the important part is that every query hits one shard.

## 6. Architecture

```text
                          +--------------------+
   client --HTTPS-->  LB  |  API servers        |----> ID allocator (ranges of counters)
                       \  |  (stateless)        |
                        \ +---------+----------+
                         \          |  write link
                          \         v
                           \   +-----------+        replicated, partitioned by code
                            \  | links DB  |  (Cassandra / DynamoDB / sharded SQL)
                             \ +-----------+
                              \      ^ cache miss
     GET /{code} -----------> Redirect servers ---> Redis cache (code -> longUrl)
                                     |
                                     +--- click event (async) ---> Kafka ---> stream aggregator ---> analytics DB
```

- **Write path:** API server validates the URL, gets a new ID (or checks the alias), writes the row, returns the short URL.
- **Read path:** redirect server checks the cache, falls back to the database on a miss (and fills the cache), returns the redirect, and **asynchronously** publishes a click event. The redirect never waits for analytics.

## 7. Deep dive: generating the code

The heart of the problem. Requirements: unique, short, fast, works across many servers.

| Approach | How | Pros | Cons |
|---|---|---|---|
| Hash the URL | MD5/SHA of the long URL, take 7 base62 chars | stateless; same URL -> same code | collisions must be detected and resolved (append a salt, retry); still needs a DB check |
| Random code | 7 random base62 chars, insert-if-absent | stateless, not enumerable | a DB round trip to check; retries get more likely as the space fills (at 182.5 B / 3.5 T ≈ 5% full, ~5% of inserts retry once) |
| **Global counter + base62** | each new link gets the next integer; encode it in base62 | no collisions ever; simple | a single counter is a bottleneck and single point of failure; codes are sequential (guessable) |
| **Counter ranges (recommended)** | an allocator (ZooKeeper / a small DB table) hands each API server a block of, say, 1 M IDs; servers allocate locally from their block | no collisions, no per-request coordination; one allocator call per million links | a server crash wastes the rest of its block (harmless: 3.5 T codes); codes are still sequential within a block |
| Key Generation Service | pre-generate unique random codes offline into a table; servers fetch batches | fast, non-sequential | another service to run; must mark keys as used atomically |

**Recommended answer:** counter ranges + base62, and if enumeration is a concern (people scraping all links by incrementing codes), pass the counter through a reversible scrambling step before encoding: for example, multiply by a large odd constant modulo 62^7, which is a bijection on the code space, so codes stay unique and collision-free but no longer look sequential. State the trade-off: scrambling hides order but is not cryptographic security; private links need an unguessable random token.

**Custom aliases** bypass the generator: insert with a conditional write (`INSERT ... IF NOT EXISTS` / DynamoDB `attribute_not_exists`) and return 409 if taken. Reserve aliases that could collide with generated codes (for example, require aliases to contain a character not in the generated alphabet, or a different length).

## 8. Deep dive: the redirect

- **301 (permanent) vs 302 (temporary).** 301 lets browsers and proxies cache the mapping, so repeat clicks never reach us: less load, but we lose click analytics and cannot change or expire the link for those clients. 302 means every click hits our servers: accurate analytics, expiry works. Most commercial shorteners use 302 (or 307) for this reason. Say the trade-off; pick 302 if analytics matters.
- **Cache:** code -> long URL in Redis with LRU eviction. Links never change, so caching is trivially consistent; only deletes and expirations need care (delete from the cache on delete; store the expiry with the cached value). The hit ratio is high because popularity is heavily skewed.
- **CDN / edge:** for extremely hot links, the redirect itself can be served at the edge with a short cache lifetime.

## 9. Deep dive: analytics

Never increment a counter in the `links` row on every click: that turns a read-heavy table into a write-heavy one and creates hot rows for viral links.

Instead: redirect servers publish `{code, timestamp, referrer, country}` events to Kafka; a stream processor (Flink / Spark Streaming / Kafka Streams) aggregates counts per code per minute and writes to an analytics store (ClickHouse / Cassandra counters / a time-series DB). Stats are minutes behind, which the requirements allow.

## 10. Scaling and failure modes

| Concern | Answer |
|---|---|
| Hot link (goes viral) | Cache absorbs it; replicate hot keys across cache nodes or serve from the edge. |
| Cache node failure | Misses go to the DB; the DB must survive a burst (read replicas, request coalescing so one miss per key reaches the DB). |
| DB growth (91 TB) | Partition by hash of `code`; add nodes and rebalance (consistent hashing in Cassandra/DynamoDB). |
| ID allocator down | Servers still have their current blocks (1 M IDs each): minutes to hours of headroom. Run the allocator replicated (ZooKeeper / etcd). |
| Expired links | DB TTL deletes them; redirect checks `expires_at` anyway (TTL deletion is lazy in many stores). |
| Abuse (spam, phishing) | Rate limit creation; check long URLs against a malicious-URL list (asynchronously, and disable links later if flagged). |
| Multi-region | Links are immutable, so asynchronous replication is safe: a link created in one region may take seconds to resolve in another. Route reads to the nearest region. |

## 11. What interviewers look for

- Back-of-envelope numbers that **lead to decisions** (read-heavy -> cache; 182 B rows -> partitioned KV store; 62^7 -> 7 characters).
- A clear, collision-free ID generation scheme with its trade-offs.
- The 301 vs 302 discussion.
- Analytics kept off the redirect's critical path.

## 12. Common mistakes

- Hashing the URL and ignoring collisions.
- A single auto-increment counter in one database for all servers, with no plan for its failure.
- Updating click counts synchronously on the redirect path.
- Forgetting that custom aliases can collide with generated codes.

## 13. Follow-ups

1. **Same long URL should return the same short link.** Add a secondary index `long_url_hash -> code`; check it before creating. Doubles the write cost.
2. **Private / unguessable links.** Use 10+ random characters from a cryptographically secure generator.
3. **Link previews and safety checks.** Asynchronous worker fetches the target page metadata and scans it.
4. **Per-user dashboards.** Index links by `owner_id` in a separate table (`owner_id, created_at -> code`).

See [LLD.md](LLD.md) for the class design and a runnable implementation of the core service.
