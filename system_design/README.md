# System Design

Thirty system design problems that come up again and again in interviews. Each folder has two files:

- **`HLD.md` (high-level design):** scope questions, requirements, capacity estimates, API, data model, an architecture diagram, deep dives on the hard parts, failure modes, what interviewers look for, common mistakes, follow-ups.
- **`LLD.md` (low-level design):** scope for the LLD round, the classes and their responsibilities, a class diagram, design decisions (patterns, SOLID), **one complete runnable Dart program** with self-checks, a walkthrough, concurrency notes, an extensibility table, common mistakes.

The code in every `LLD.md` is verified: `dart run tool/check_lld.dart` extracts each program, checks formatting, runs `dart analyze --fatal-infos` with the repo's strict settings, and runs it. CI does the same on every push.

## The problems

| # | Problem | HLD focus | LLD focus |
|---|---|---|---|
| 01 | [URL Shortener](01_url_shortener/) | ID generation (counter ranges + base62), read-heavy caching, 301 vs 302, async analytics | Code generator strategies, repository with insert-if-absent, aliases, expiry |
| 02 | [Rate Limiter](02_rate_limiter/) | Algorithms compared, atomic Redis updates (Lua), fail open vs closed | Fixed window, sliding log, sliding counter, token bucket behind one interface; rules |
| 03 | [Distributed Cache](03_distributed_cache/) | Consistent hashing, replication, cache-aside, hot keys, stampedes | O(1) LRU (hand-written linked list), O(1) LFU, TTL, hash ring with virtual nodes |
| 04 | [Parking Lot](04_parking_lot/) | Multi-garage service, offline-capable gates, reservations without overbooking | Spots, levels, tickets; allocation and pricing strategies; display board observer |
| 05 | [Chat System](05_chat_system/) | WebSockets, session registry, per-conversation sequence numbers, offline sync, presence | Conversations, idempotent send, delivery/read watermarks, multi-device, push fallback |
| 06 | [News Feed](06_news_feed/) | Fan-out on write vs read, the celebrity problem, timeline cache, cursor pagination | Snowflake IDs, hybrid fan-out, capped timelines, read-time filtering |
| 07 | [Notification System](07_notification_system/) | Queues per priority and channel, idempotency, retries, provider failover | Channel senders, templates, preferences, priority queue, backoff, dead letters |
| 08 | [Ride Sharing](08_ride_sharing/) | Location ingestion at 1M+/s, geospatial indexes, matching, trip state machine, surge | Grid index, driver reservation, decline/timeout, trip transitions, fare strategy |
| 09 | [Movie Ticket Booking](09_movie_ticket_booking/) | No double booking under contention, holds with expiry, payment edge cases, flash sales | All-or-nothing holds, lazy expiry, payment window, refund on lost seats, cancellation |
| 10 | [Typeahead / Autocomplete](10_typeahead_autocomplete/) | Trie with top-k per node, offline + streaming pipelines, caching, sharding | Trie with incremental top-k, recompute on removal, trending blend, blocklist |
| 11 | [Web Crawler](11_web_crawler/) | URL frontier (priority + politeness), dedup at billions scale, DNS, traps, recrawl | URL normalization, Bloom filter, per-host polite frontier, robots.txt, content dedup |
| 12 | [Video Streaming](12_video_streaming/) | Resumable upload, parallel transcoding DAG, adaptive bitrate (HLS/DASH), CDN egress math | Chunked upload session, transcoding job planner with retries, playlists, bitrate selectors |
| 13 | [File Storage and Sync](13_file_storage_sync/) | Chunking + content-addressed dedup, metadata vs blocks, journal cursors, conflicts | Fixed vs content-defined chunking, block store, journal with `baseRev`, conflicted copies |
| 14 | [Payment System](14_payment_system/) | Idempotency end to end, double-entry ledger, PSP timeouts, reconciliation | Idempotency store, payment state machine with `unknown`, zero-sum ledger, refunds, webhooks |
| 15 | [Distributed Key-Value Store](15_key_value_store/) | Quorums (N, R, W), LWW vs vector clocks, hinted handoff, Merkle trees, LSM trees | LSM engine (WAL, memtable, SSTables, compaction, recovery), quorum coordinator, read repair |
| 16 | [Distributed Message Queue](16_message_queue/) | Partitioned logs, consumer groups, ISR and high watermark, delivery semantics | Segmented log, key partitioner, range assignment and rebalancing, replication, idempotent producer |
| 17 | [Collaborative Editor](17_collaborative_editor/) | OT vs CRDT, one owner per document, op log + snapshots, presence | OT transform for insert/delete, server and client state machines, randomized convergence test |
| 18 | [Elevator System](18_elevator_system/) | Local control vs cloud monitoring, dispatching, safety layers, modes | LOOK scheduling, cost-based dispatcher, hall/car calls, out-of-service reassignment |
| 19 | [Distributed Job Scheduler](19_job_scheduler/) | Exactly-once triggering, leases and heartbeats, retries, misfires, top-of-hour spikes | Cron parser and `next()`, idempotent run IDs, leases with fencing, backoff, misfire policies |
| 20 | [Expense Sharing (Splitwise)](20_expense_sharing/) | Derived balances with a zero-sum invariant, edits with versions, simplification | Split strategies with exact rounding, net and pairwise balances, edits, greedy simplification |
| 21 | [Unique ID Generator](21_unique_id_generator/) | Snowflake vs UUID vs ticket servers, bit layout, worker ID leases, clock skew | Configurable Snowflake, sequence exhaustion, clock rollback, range allocator, lease registry |
| 22 | [Search Engine](22_search_engine/) | Inverted index, indexing pipeline, document vs term partitioning, scatter-gather, ranking | Analyzer, positional index, AND/OR/phrase queries, BM25, sharded search with global statistics |
| 23 | [Proximity Service](23_proximity_service/) | Geohash vs quadtree vs S2, precision from radius, cell caching, read-heavy scaling | Geohash encode/neighbors, prefix-scan index, quadtree, both checked against brute force |
| 24 | [Leaderboard](24_leaderboard/) | Sorted sets, rank in O(log n), time windows, durability via event log, huge boards | Skip list with rank spans (Redis ZSET), ties by time, windowed boards, randomized cross-check |
| 25 | [Metrics Monitoring](25_metrics_monitoring/) | Time-series model, cardinality, pull vs push, TSDB storage, downsampling, alerting | Series identity, label index, `rate` with resets, `sum by`, downsampling, alert state machine |
| 26 | [Log Aggregation](26_log_aggregation/) | Agents and Kafka buffering, full-text vs label indexing, tiers, retention, redaction | Logfmt parsing, PII redaction, time-partitioned chunks, chunk skipping, rate limits, patterns |
| 27 | [Ad Click Aggregation](27_ad_click_aggregation/) | Event time, watermarks, late data, exactly-once via checkpoints, reconciliation | Dedup, tumbling windows, watermark firing, late output, checkpoint/restore with idempotent sink |
| 28 | [Stock Exchange](28_stock_exchange/) | Order book, deterministic single-threaded matching, sequencer, replication by replay | Price-time priority book, limit/market/IOC, partial fills, cancels, journal replay |
| 29 | [Hotel Reservation](29_hotel_reservation/) | Inventory per room type per night, optimistic vs pessimistic locking, overbooking | Versioned per-night inventory, all-or-nothing commits, retries, idempotency, weekend pricing |
| 30 | [E-Commerce Checkout](30_ecommerce_checkout/) | Saga vs 2PC, inventory reservations, flash sales, order state machine | Pricing, reservations with expiry, saga orchestrator with compensations and resumable log |

Suggested order: 01, 02, 03 (building blocks used by the others), then 06, 05, 07, 09, 08, 10. Then the infrastructure set: 15 (key-value store), 16 (message queue), 19 (job scheduler), 11 (web crawler); then the product set: 13, 12, 14, 17.

Pure LLD questions: 04 (parking lot), 18 (elevator), 20 (expense sharing). Do them early if your loop has an LLD round.

## How to run a high-level design interview (45 minutes)

1. **Clarify scope (5 min).** Features in and out, users, scale, latency, consistency needs. Write the answers down. Interviewers grade this; jumping straight to boxes is the most common failure.
2. **Estimate (3-5 min).** Requests per second, storage, bandwidth, memory for caches. Round aggressively. Every number should lead to a decision ("116K reads/s, so cache"; "4 bookings/s average, so the problem is contention, not volume").
3. **API and data model (5 min).** The few endpoints that matter; the main tables or keys and how they are partitioned.
4. **High-level architecture (10 min).** Clients, gateway, services, storage, caches, queues. Walk through the main read and write paths end to end.
5. **Deep dives (15 min).** The one or two parts that make this problem hard (ID generation, fan-out, double booking, matching). Compare options in a table and pick one with a reason.
6. **Failures and scaling (5 min).** What breaks first, what happens when each component fails, hot keys, multi-region.

## How to run a low-level design interview (45-60 minutes)

1. **Pin down requirements** as a short list, including what is out of scope.
2. **Find the entities** (nouns) and their responsibilities (verbs). One reason to change per class.
3. **Draw relationships** (has-a, uses, is-a). Prefer composition; use inheritance only when behavior differs.
4. **Identify what varies** and put it behind an interface: pricing, allocation, eviction, channels, algorithms (Strategy). Notifications to many listeners (Observer). Wrapping behavior (Decorator). Lifecycles (state machine with an explicit transition table).
5. **Write the core code:** the facade's main methods, with typed exceptions for invalid operations.
6. **Discuss concurrency:** what is the critical section, and how would you make it atomic (locks, compare-and-set, conditional updates)?
7. **Show extensibility:** for each likely new requirement, which class changes and which do not.

Habits that appear in every LLD here: an injected `Clock` (time-dependent logic is testable), integer cents for money, idempotency keys for operations that clients retry, and state machines for anything with a lifecycle.

## Numbers worth knowing

Approximate, for estimates only. Real values depend on hardware and change over time; say "roughly" in the interview.

| Quantity | Value |
|---|---|
| Seconds per day | 86,400 (round to ~100K for quick math) |
| 1 M requests/day | ~12/s |
| 100 M requests/day | ~1,200/s |
| 1 B requests/day | ~12K/s |
| Peak vs average | 2-3x (more for events and launches) |
| L1 cache / main memory reference | ~1 ns / ~100 ns |
| Read 1 MB sequentially from memory | ~10 us (order of magnitude) |
| SSD random read | ~100 us |
| Round trip inside a data center | ~0.5 ms |
| Round trip across a continent / ocean | ~30-80 ms / ~100-150 ms |
| Redis / Memcached node | ~100K simple ops/s |
| Relational database node | ~1K-10K writes/s (depends heavily on the workload) |
| Kafka partition | ~10 MB/s or more per partition |
| WebSocket connections per tuned server | hundreds of thousands to ~1 M |

## Patterns that come up across problems

| Pattern | Where |
|---|---|
| Cache-aside with delete-on-write | 01, 03, 06 |
| Consistent hashing | 03, 15 (and any sharded store) |
| Idempotency keys | 05, 07, 08, 09, 14, 16, 19, 20 |
| Conditional update / compare-and-set | 01 (aliases), 08 (driver reservation), 09 (seat holds) |
| Async processing through a queue | 01 (analytics), 06 (fan-out), 07 (all deliveries), 12 (transcoding), 19 (runs) |
| Precompute for reads | 06 (timelines), 10 (top-k per prefix) |
| Time-based expiry, checked lazily | 03 (TTL), 09 (holds) |
| State machines | 05 (message status), 08 (trips), 09 (holds and bookings), 14 (payments), 19 (runs) |
| Rate limiting | 02, used by 01 and 07 |
| Append-only logs with offsets or cursors | 13 (sync journal), 14 (ledger), 15 (WAL), 16 (partitions), 17 (op log) |
| Leases and fencing | 19 (worker leases with attempt numbers); 16 (consumer group generations, described) |
| Content addressing / hashing for dedup | 11 (content hash), 13 (blocks) |
| Bloom filters | 11 (seen URLs), 15 (SSTables) |

**A note on accuracy:** capacity numbers in each HLD are assumptions chosen to make the math concrete, not real company figures. Technology choices (Cassandra, Redis, Kafka) are common, defensible answers, not the only correct ones; interviewers care about the reasoning and trade-offs more than product names.
