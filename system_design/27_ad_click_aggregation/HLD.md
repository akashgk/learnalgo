# Ad Click Event Aggregation: High-Level Design

**Asked at:** Google, Meta, Amazon, TikTok, Pinterest, Criteo. **Core topics:** stream processing, event time vs processing time, windows and watermarks, late and duplicate events, exactly-once results with checkpoints, top-N queries, reconciliation with batch.

## 1. Clarify the scope

| Question | Assumed answer |
|---|---|
| Input? | Click events `{clickId, adId, userId, country, eventTime}` from ad servers / tracking pixels. |
| Outputs? | Clicks per ad per minute (billing and dashboards); top 100 ads per minute; filters by country. |
| Scale? | 1 B clicks/day; peak ~50K/s; 2 M active ads. |
| Latency? | Aggregates available within a few minutes. |
| Correctness? | Billing depends on it: no double counting, no lost clicks; late events (up to minutes) must count. |

## 2. Requirements

**Functional:** count clicks per ad per minute (event time); top N per minute; filterable by a few dimensions; queryable for the last 90 days.

**Non-functional:** exactly-once results despite failures, tolerance of late and out-of-order events, high throughput, fault tolerance, auditability (raw events kept for recomputation).

## 3. Capacity estimates

| Quantity | Math | Result |
|---|---|---|
| Events | 1 B/day | **~12K/s** avg, 50K/s peak |
| Raw storage | 1 B x 100 B | **~100 GB/day** (kept for replays and audits) |
| Aggregates | 2 M ads x 1,440 minutes (only ads with clicks produce rows) | at most a few hundred million rows/day; much less in practice |

## 4. Architecture

```text
 ad servers --> log/click service --> Kafka "clicks" (partitioned by adId; retention 7 days)
                                          |
                     +--------------------+----------------------+
                     v                                           v
     Stream aggregation (Flink): dedup by clickId,       raw event archive (object storage)
     filter fraud, key by (adId, minute) in EVENT time,          |
     tumbling 1-minute windows, watermarks,               daily batch job recomputes the same
     checkpoints (state + Kafka offsets)                  aggregates (reconciliation, corrections)
                     |
                     v
     Kafka "aggregates" --> sink (upsert by (adId, minute)) --> OLAP store (ClickHouse/Druid/Pinot)
                                                                     |
                                              query API: per-ad counts, top N, filters, dashboards
```

## 5. Deep dive: event time, windows and watermarks

- **Event time** (when the click happened) decides the window, not processing time (when it arrived). Otherwise a delay in the pipeline moves clicks into the wrong minute.
- **Tumbling windows** of 1 minute per ad. A **watermark** = "we believe all events up to time W have arrived", typically max event time seen minus an allowed lateness (e.g. 2 minutes). A window `[t, t+60)` is emitted when the watermark passes `t+60`.
- **Late events** (behind the watermark, window already emitted): send to a side output; either update the aggregate (emit a correction, if the sink upserts) or leave them for the daily reconciliation.
- Trade-off: larger allowed lateness = more complete results, later.

## 6. Deep dive: exactly-once

- Kafka consumer offsets and operator state (open windows, dedup set) are **checkpointed together** (Flink's distributed snapshots). After a crash, restore the checkpoint and **replay** from its offsets.
- Replays can re-emit window results. Make the sink **idempotent** (upsert keyed by `(adId, windowStart)`) or transactional (two-phase commit to Kafka). Then the stored results are exactly-once even though processing was at-least-once.
- **Duplicates at the source** (pixel fired twice, client retries): deduplicate by `clickId` within a time window (state with TTL).

## 7. Deep dive: top N and hot ads

- Top 100 per minute: per-partition top-N heaps, merged by a final operator.
- Hot ads (a viral campaign) create a hot key: pre-aggregate with a random sub-key (`adId#k`) in a first stage, then combine.
- Dimension filters (country, device): either aggregate by `(adId, minute, country)` (more rows, flexible) or predefine a small set of dimension rollups.

## 8. Reconciliation (Lambda vs Kappa)

- Billing needs the right number eventually. A daily batch job recomputes aggregates from the raw archive and compares; differences above a threshold trigger corrections and investigation.
- Kappa architecture: one streaming codebase; recompute by replaying the event log through the same job. Lambda: separate batch and streaming paths (two codebases).

## 9. Failure modes

| Failure | Behavior |
|---|---|
| Aggregation worker crash | Restore last checkpoint, replay from saved offsets; idempotent sink absorbs re-emits. |
| Kafka partition lag | Watermarks wait for the slowest partition; idle partitions must not stall the watermark (idleness detection). |
| Sink down | Results buffer in Kafka "aggregates" topic. |
| Bug in aggregation logic | Fix and replay from the raw archive. |

## 10. What interviewers look for

- Event time, watermarks and late data handling.
- Exactly-once results: checkpoints + replay + idempotent sink.
- Deduplication of clicks.
- Reconciliation against raw data.

## 11. Common mistakes

- Windowing by processing time.
- Claiming exactly-once delivery without explaining checkpoints and idempotent writes.
- Updating a database counter per click (hot rows, no recomputation).
- Not keeping raw events.

## 12. Follow-ups

1. **Click fraud filtering:** rules and models before aggregation (bursts from one IP, bots).
2. **Impressions and CTR:** join with impression streams (windowed joins).
3. **Sliding windows** (clicks in the last 5 minutes, updated every minute).

See [LLD.md](LLD.md) for deduplication, event-time tumbling windows with a watermark, late-event handling, top-N, and checkpoint/restore with an idempotent sink.
