# Web Crawler: High-Level Design

**Asked at:** Google, Microsoft, Amazon, Meta. **Core topics:** the URL frontier, politeness, deduplication at billions scale (URLs and content), DNS, distributing work, traps.

## 1. Clarify the scope

| Question | Assumed answer |
|---|---|
| Purpose? | Feed a search engine index (could also be archiving or data mining; the purpose changes priorities). |
| Content types? | HTML only; store raw pages for the indexer. |
| Scale? | 1 B pages per month, refreshed over time. |
| Freshness? | Popular pages recrawled often (hours to days), the long tail rarely. |
| Politeness? | Obey `robots.txt`; at most one request per host every ~1 s by default. |
| New vs revisit? | Both: discover new URLs from links, and revisit known ones by priority. |

## 2. Requirements

**Functional:** start from seed URLs; fetch pages; extract links; add new URLs to the frontier; store pages; repeat.

**Non-functional:**

- **Scalable:** billions of pages, thousands of fetches per second.
- **Polite:** never overload a site; obey robots.txt.
- **Robust:** malformed HTML, slow servers, crawler traps (infinite calendars, session IDs in URLs), redirects loops.
- **Efficient:** do not fetch the same URL twice in a cycle; do not store duplicate content.
- **Extensible:** new content types, new processing steps.

## 3. Capacity estimates

| Quantity | Math | Result |
|---|---|---|
| Fetch rate | 1 B / (30 x 86,400) | **~400 pages/s** avg, plan for ~1,000/s |
| Page size | ~100 KB average HTML | ingress **~40-100 MB/s** |
| Storage | 1 B x 100 KB | **~100 TB/month** raw (compress ~4x: ~25 TB) |
| URLs seen | ~10 links per page, many duplicates; tens of billions known URLs | a URL set of **~10 B entries**: 10 B x 8-byte hash = 80 GB, or a Bloom filter at ~10 bits/URL ≈ **12.5 GB** for ~1% false positives |
| Hosts | ~100 M+ distinct hosts | per-host queues must be compact |

## 4. Architecture

```text
 seeds --> URL Frontier ----------------------------------------------------------+
            (priority + per-host politeness queues, distributed by host hash)     |
                |                                                                 |
                v                                                                 |
         Fetcher workers --> DNS resolver (cached) --> HTTP fetch (timeouts, max size)
                |                    robots.txt cache (per host, refreshed daily)  |
                v                                                                 |
         Content dedup (hash / SimHash) --duplicate--> drop                        |
                | new content                                                     |
                +--> Page store (S3 / HDFS, compressed, keyed by URL hash)          |
                +--> Link extractor --> URL normalizer --> URL filter (robots,     |
                                        scope, traps) --> URL seen? (Bloom / DB) --+
                                                                    new URLs
                +--> metadata DB: url -> last_crawled, status, content hash, change rate
```

**Distribution:** partition the URL space **by host** (hash of hostname -> crawler node). Each node owns the frontier, politeness state and robots cache for its hosts, so politeness needs no cross-node coordination. Links to hosts owned by another node are forwarded to it (batched).

## 5. Deep dive: the URL frontier

Two goals pull in different directions: **priority** (crawl important pages first) and **politeness** (spread requests per host over time). The Mercator design:

```text
 new URLs --> prioritizer --> front queues F1 (high) ... Fn (low)
                                   |  biased random pick by priority
                                   v
                      back-queue router (one back queue per host)
                                   |
                     back queues B1..Bm, each holding URLs of one host
                                   |
               heap of (next allowed fetch time, back queue)  <-- worker pops the earliest ready host,
                                                                 fetches one URL, pushes the host back
                                                                 with time = now + delay(host)
```

- **Priority** from PageRank-like importance, update frequency, and depth from the seed.
- **Politeness delay** per host: default ~1 s, or a multiple of the last response time (slow server, slow down), or robots.txt `Crawl-delay`.
- The frontier is too big for memory: keep queue heads in memory and spill the rest to disk (RocksDB / files per queue).

## 6. Deep dive: deduplication

| What | How |
|---|---|
| Same URL written differently | **Normalize:** lowercase scheme and host, remove default ports and fragments, resolve `.` and `..`, sort or strip tracking query parameters, consistent trailing slash rules. |
| URL already seen | A **Bloom filter** (fast, small, no false negatives; ~1% false positives means a few URLs are skipped wrongly, acceptable) in front of a durable URL store. |
| Same content at different URLs (mirrors, `?ref=` variants) | Hash the normalized content (exact duplicates); **SimHash / MinHash** for near-duplicates (pages differing only in ads or timestamps). |

## 7. Deep dive: politeness, robots and traps

- Fetch and cache `robots.txt` per host before crawling it; respect `Disallow` and `Crawl-delay`. If robots.txt fails with 5xx, assume disallow for a while.
- **Traps:** cap URL length and path depth; cap pages per host per cycle; detect repeating path segments (`/a/b/a/b/a/b`); limit query-parameter combinations; prefer canonical URLs (`<link rel="canonical">`).
- Timeouts on connect and read; maximum page size; limit redirect chains (~5).

## 8. Deep dive: DNS

DNS lookups (10-200 ms each) become a bottleneck at 1,000 fetches/s. Run local caching resolvers, cache per host respecting TTLs, and resolve asynchronously ahead of fetching (prefetch for hosts near the front of the queue).

## 9. Deep dive: recrawl (freshness)

Track each page's change history. Estimate a change rate (pages that changed in the last few visits get shorter intervals; unchanged pages back off exponentially). Use conditional requests (`If-Modified-Since`, `ETag`) so unchanged pages cost a 304 instead of a full download.

## 10. Failure modes

| Failure | Behavior |
|---|---|
| Crawler node dies | Its host partition is reassigned (consistent hashing); frontier state recovered from disk checkpoints; a few URLs refetched. |
| Site down or slow | Exponential backoff for that host; other hosts unaffected. |
| Page store slow | Fetchers buffer and apply backpressure to the frontier. |
| Bloom filter false positive | A URL is skipped this cycle; acceptable at ~1%. Rebuild periodically. |

## 11. What interviewers look for

- A frontier that handles both priority and per-host politeness.
- URL normalization plus a scalable "seen" set (Bloom filter) and content dedup.
- Partitioning by host to keep politeness local.
- Traps, robots.txt, DNS caching.

## 12. Common mistakes

- A single global FIFO queue (hammers one site, ignores priority).
- BFS with no dedup, or a "seen" set that cannot fit in memory at scale without discussion.
- Ignoring robots.txt and politeness.
- Forgetting traps and redirect loops.

## 13. Follow-ups

1. **JavaScript-rendered pages:** a separate, expensive headless-browser tier for pages that need it.
2. **Focused crawling:** a classifier scores links by topic relevance to set priority.
3. **Incremental index updates:** stream new page versions to the indexer.
4. **Geographic distribution:** crawler nodes near the sites they fetch.

See [LLD.md](LLD.md) for URL normalization, a Bloom filter, a polite frontier and the crawl loop.
