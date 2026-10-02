# Typeahead / Search Autocomplete: High-Level Design

**Asked at:** Google, Amazon, LinkedIn, Microsoft, Uber. **Core topics:** tries with precomputed top-k, very low latency at very high QPS, offline aggregation pipelines, caching at every layer, freshness for trending queries.

## 1. Clarify the scope

| Question | Assumed answer |
|---|---|
| What is suggested? | Popular past search queries that start with the typed prefix (not documents). |
| How many suggestions? | Top 5 (or 10) by popularity. |
| Matching? | Prefix match, lowercase; no spelling correction in the core design. |
| Personalization? | Out of scope at first; follow-up. |
| Freshness? | Trending queries should appear within ~minutes to an hour; general popularity updated daily. |
| Scale? | 500 M DAU, ~10 searches each, ~6 keystrokes per search that hit the service. |
| Latency? | p99 < ~100 ms end to end; the service itself < ~10 ms. |
| Languages? | Assume one language first; the design generalizes per locale. |

## 2. Requirements

**Functional:** `suggest(prefix) -> top k queries`; record executed searches so popularity updates.

**Non-functional:** very low latency, very high availability (degrade to no suggestions, never break search), eventually consistent popularity, filter offensive suggestions.

## 3. Capacity estimates

| Quantity | Math | Result |
|---|---|---|
| Suggest requests | 500 M x 10 x 6 / 86,400 | **~350K/s** avg, ~1 M/s peak |
| Search log events | 500 M x 10 / 86,400 | **~60K/s** (one per executed search) |
| Distinct queries kept | after dropping rare ones (seen < N times) | **~100 M** |
| Trie size | ~100 M queries x ~20 chars, shared prefixes; plus top-k lists per node | **tens of GB**; shard or keep only top ~10 M queries per serving node |
| Top-k cache | prefixes of length 1-3 are few and extremely hot | thousands of entries cover a large share of traffic |

Reads are ~6x the writes and need millisecond latency: **precompute** answers per prefix; never compute top-k at query time.

## 4. API

```text
GET /suggest?q=new%20yo&k=5&locale=en-US
  200 { "suggestions": ["new york", "new york times", "new york weather", ...] }
  Cache-Control: max-age=300     (browser and CDN cache short prefixes)
```

The client debounces (only request after ~100 ms without typing), cancels stale requests, and caches results per prefix locally.

## 5. Core data structure

A **trie** where each node stores the **top k completions** for its prefix, precomputed.

```text
            (root)
             |
             n  top: [new york, netflix, news, nike, new york times]
             |
             e  top: [new york, netflix, news, new york times, new jersey]
            / \
           w   t  top: [netflix, netflix login, ...]
           |
          ...
```

- Query = walk down the prefix (O(length of prefix)) and return the stored list: O(p) with no search over the subtree.
- Cost: memory (k entries per node) and more work on updates, since a query's count change touches every node on its path. That trade is right for a read-heavy system.
- Alternative storage: a key-value map `prefix -> top k` (prefixes up to length ~20) in Redis or Cassandra. Simpler to shard and replicate, larger. Many real systems serve this way.

## 6. Architecture

```text
 Online path:
   browser (debounce, local cache) --> CDN (caches short prefixes) --> Suggest service --> in-memory trie
                                                                         (replicated, read-only snapshot)
 Data path:
   search service --> search log events --> Kafka --+--> batch: daily aggregation (Spark)
                                                    |       count queries over a window with time decay,
                                                    |       filter (min count, blocklist), build trie snapshot
                                                    |       --> blob storage --> suggest servers load it (blue/green)
                                                    |
                                                    +--> streaming: trending (Flink), counts per 5-15 min
                                                            --> small "trending" trie or boost list merged at query time
```

## 7. Deep dives

**Building the trie (offline).** Aggregate `(query, count)` from logs with time decay (recent searches weigh more: for example a weekly half-life). Drop rare queries (privacy and noise), apply blocklists. Build bottom up: each node's top k = best k among its own terminal count and its children's top-k lists. Serialize, ship to all servers, swap atomically.

**Freshness.** Rebuilding the whole trie takes time, so serve a combination: the big daily snapshot plus a small, frequently rebuilt trending structure from the streaming pipeline, merged at query time (merge two sorted lists of k). This is the usual answer to "how does a breaking news query show up quickly?".

**Sharding.** If one machine cannot hold the trie: shard by prefix ranges (`a-f`, `g-m`, ...), adjusted by traffic, not alphabet size (far more queries start with `s` than `x`). Replicate each shard for throughput and availability. The router sends a request to the shard owning its first characters.

**Caching layers.** Browser (per session), CDN (short prefixes are identical for millions of users), service-level cache for the hottest prefixes. The one- and two-letter prefixes are a tiny set and carry a large share of traffic.

**Filtering.** Blocklists for offensive, dangerous or legally problematic completions, applied at build time and re-checked at serve time (so a newly blocked term disappears without waiting for a rebuild).

**Personalization (follow-up).** Blend global suggestions with the user's own recent queries (stored per user, fetched in parallel) and location-based popularity.

## 8. Scaling and failure modes

| Concern | Answer |
|---|---|
| 1 M requests/s | Read-only in-memory tries, horizontally replicated; CDN and browser caches absorb short prefixes. |
| Snapshot build fails | Keep serving the previous snapshot; alert. |
| Bad snapshot (empty, corrupted) | Validate (size, sample queries) before swapping; roll back to the previous version. |
| Suggest service down | The search box still works without suggestions (fail soft). |
| Hot prefix after an event | Trending pipeline and cache handle it; the trie itself is read-only, so no write contention. |

## 9. What interviewers look for

- Trie with **precomputed top k per node** and the reasoning (read-heavy, latency).
- Separating the online serving path from the offline/streaming data pipeline.
- Freshness strategy for trending queries.
- Caching at the client and CDN, debouncing on the client.
- Sharding by traffic-balanced prefix ranges.

## 10. Common mistakes

- DFS over the subtree on every keystroke to find the top k.
- Updating the serving trie synchronously on every search (write contention on the hottest nodes, for little benefit).
- A SQL `LIKE 'prefix%'` query at 1 M QPS.
- Forgetting the client side (debounce, cancel, cache).
- No filtering of offensive suggestions.

## 11. Follow-ups

1. **Spelling tolerance:** fuzzy matching with edit distance on the trie (bounded), or a separate "did you mean" service.
2. **Multi-word / middle-of-query matching:** index suffixes or tokens, not only full-query prefixes.
3. **Ranking beyond counts:** click-through rate on suggestions, freshness, personalization, learned ranking.
4. **Multiple languages:** one trie per locale; Unicode normalization.

See [LLD.md](LLD.md) for a trie with top-k per node, incremental updates, and blending a trending list.
