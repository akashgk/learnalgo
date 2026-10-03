# Search Engine (Google-style web search, or search inside a product): High-Level Design

**Asked at:** Google, Microsoft (Bing), Amazon (product search), LinkedIn, Elastic. **Core topics:** the inverted index, indexing pipeline, partitioning the index (by document vs by term), query processing with scatter-gather, ranking (BM25, link signals, learning to rank), caching, freshness.

## 1. Clarify the scope

| Question | Assumed answer |
|---|---|
| Corpus? | Web pages from the crawler (see 11): ~10 B documents. (Product search: ~100 M items, same design at smaller scale.) |
| Queries? | Free-text keywords; optional phrases in quotes; top 10 results with snippets. |
| Traffic? | ~100K queries/s at peak. |
| Latency? | p99 < ~200 ms end to end. |
| Freshness? | News within minutes; the bulk of the web within days. |
| Ranking? | Text relevance + page quality (links) + learned model. |

## 2. Requirements

**Functional:** index documents; answer keyword and phrase queries with ranked results and snippets; update and delete documents.

**Non-functional:** low latency at very high QPS, high availability (serve partial results rather than fail), scalable to billions of documents, relevant results, fresh index for important content.

## 3. Capacity estimates

| Quantity | Math | Result |
|---|---|---|
| Documents | 10 B x ~10 KB text after extraction | **~100 TB** of text |
| Index size | inverted index with positions ≈ 30-50% of text, compressed | **~30-50 TB** |
| Shards | ~50-100 GB index per machine (in RAM/SSD) | **~500-1,000 shards**, each replicated many times for QPS |
| Query fan-out | every query hits every document shard | 100K QPS x 1,000 shards = **100 M shard lookups/s** → heavy caching and replication |

## 4. The core data structure: the inverted index

```text
term       -> postings list (sorted by doc ID): (docId, termFrequency, [positions])
"search"   -> (3, 2, [4, 17]), (8, 1, [2]), (12, 5, [...]), ...
"engine"   -> (3, 1, [5]), (12, 1, [9]), ...
plus per-document: length, quality score (PageRank), URL, title
```

- **AND query:** intersect sorted postings lists (start with the shortest; skip pointers make it sublinear).
- **Phrase query:** intersect, then check positions are consecutive.
- **Compression:** store gaps between doc IDs (delta encoding) with variable-byte or bit-packed codes.

## 5. Indexing pipeline

```text
 crawler pages --> parse/extract text --> language detect --> tokenize, normalize (lowercase, unicode),
   stem/lemmatize, drop/keep stopwords --> build per-segment inverted index (in batches, MapReduce-style)
   --> merge segments --> publish new index version to serving shards
 Fresh content: a small real-time index (updated in seconds) searched alongside the big batch index.
 Deletes: tombstone bitmap per segment; purged on merge.
```

## 6. Partitioning the index

| | Document-partitioned (recommended) | Term-partitioned |
|---|---|---|
| Shard holds | full index for a subset of documents | full postings for a subset of terms |
| Query | sent to all shards (scatter), top-k merged (gather) | sent only to shards owning the query's terms |
| Pros | even load; adding documents is local; a slow shard only loses some results | fewer shards per query |
| Cons | every query touches every shard | multi-term queries move huge postings lists between machines; hot terms create hot shards |

Real systems use document partitioning with many replicas per shard, plus tiering (a small tier of high-quality documents is searched first; the long tail only if needed).

## 7. Query path

```text
 user --> front end --> query cache (popular queries) --hit--> results
                     --> query understanding: spelling correction, synonyms, intent
                     --> root aggregator --scatter--> leaf shards (each: retrieve candidates with AND/OR,
                                                      score with BM25 + static quality, keep local top-k)
                                         <--gather--- merge local top-k lists into global top-k
                     --> re-rank top few hundred with an ML model (click features, freshness, personalization)
                     --> fetch snippets from a document store --> results page
```

**Global statistics:** BM25 uses document frequencies and corpus size. Each shard computing its own IDF makes scores incomparable across shards; use global statistics (precomputed, or gathered per query).

**Tail latency:** with 1,000 shards, one slow shard delays every query. Use hedged requests (send to a second replica after a short delay), timeouts with partial results, and replicas.

## 8. Ranking

1. **Text relevance:** BM25 (term frequency with saturation, inverse document frequency, length normalization), field weights (title > body), proximity of query terms.
2. **Static quality:** PageRank-style link analysis, spam scores, domain authority.
3. **Learning to rank:** a model over hundreds of features trained on clicks and human ratings, applied to the top candidates only (expensive).

## 9. Failure modes

| Failure | Behavior |
|---|---|
| Shard replica down | Other replicas serve it; load balancer removes the dead one. |
| All replicas of a shard slow | Return results without that shard (slightly incomplete). |
| Bad index build | Validate before publishing; keep the previous version to roll back. |
| Query spike | Result cache absorbs repeated queries; degrade expensive re-ranking. |

## 10. What interviewers look for

- The inverted index and how AND/phrase queries execute on it.
- Document vs term partitioning, with scatter-gather.
- BM25 or TF-IDF explained, and the need for global statistics.
- Separating the batch index from a real-time index for freshness.
- Tail latency at high fan-out.

## 11. Common mistakes

- `LIKE '%term%'` scans or a database full-text index at web scale.
- Forgetting that each query hits all document shards (and the cost).
- Running the expensive ranking model over all matches.
- Per-shard IDF without acknowledging the inconsistency.

## 12. Follow-ups

1. **Autocomplete:** see 10.
2. **Spelling correction:** edit-distance candidates scored by query-log frequency.
3. **Semantic search:** embedding vectors and approximate nearest neighbor indexes (HNSW) alongside the inverted index.
4. **Personalization:** re-ranking features from the user's history.

See [LLD.md](LLD.md) for a tokenizer, an inverted index with positions, BM25 scoring, AND and phrase queries, and a sharded scatter-gather search with global statistics.
