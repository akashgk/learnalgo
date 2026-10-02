# System Design

Ten system design problems that come up again and again in interviews. Each folder has two files:

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

Suggested order: 01, 02, 03 (building blocks used by the others), then 06, 05, 07, 09, 08, 10. Parking lot (04) is the classic pure LLD question; do it early if your loop has an LLD round.

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
| Consistent hashing | 03 (and any sharded store) |
| Idempotency keys | 05, 07, 08, 09 |
| Conditional update / compare-and-set | 01 (aliases), 08 (driver reservation), 09 (seat holds) |
| Async processing through a queue | 01 (analytics), 06 (fan-out), 07 (all deliveries) |
| Precompute for reads | 06 (timelines), 10 (top-k per prefix) |
| Time-based expiry, checked lazily | 03 (TTL), 09 (holds) |
| State machines | 05 (message status), 08 (trips), 09 (holds and bookings) |
| Rate limiting | 02, used by 01 and 07 |

**A note on accuracy:** capacity numbers in each HLD are assumptions chosen to make the math concrete, not real company figures. Technology choices (Cassandra, Redis, Kafka) are common, defensible answers, not the only correct ones; interviewers care about the reasoning and trade-offs more than product names.
