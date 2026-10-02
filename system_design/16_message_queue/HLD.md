# Distributed Message Queue (Kafka / SQS / RabbitMQ): High-Level Design

**Asked at:** LinkedIn, Uber, Amazon, Confluent, Microsoft, Goldman Sachs. **Core topics:** append-only partitioned logs, offsets, consumer groups, replication with in-sync replicas and the high watermark, delivery semantics (at-most-once, at-least-once, effectively-once), ordering, retention, backpressure.

## 1. Clarify the scope

| Question | Assumed answer |
|---|---|
| Queue (each message to one consumer, deleted when acked) or log (retained, replayable, many independent readers)? | **Log** (Kafka-style); queue semantics come from consumer groups. Mention SQS-style queues as the alternative. |
| Ordering? | Per key (per partition), not global. |
| Delivery? | At-least-once by default; effectively-once as a follow-up. |
| Scale? | 1 M messages/s in, 3 M/s out (several consumer groups), ~1 KB messages. |
| Retention? | 7 days, or by size. |
| Durability? | No acknowledged message lost if one broker dies. |

## 2. Requirements

**Functional:** producers publish to topics (optionally with a key); consumers in groups read and commit progress; multiple groups read the same topic independently; replay from an offset.

**Non-functional:** high throughput, low latency (ms), durability via replication, horizontal scalability, ordering per key, fault tolerance (broker failure, consumer failure).

## 3. Capacity estimates

| Quantity | Math | Result |
|---|---|---|
| Ingress | 1 M msg/s x 1 KB | **~1 GB/s** |
| Egress | 3 consumer groups | **~3 GB/s** (+ replication traffic 2 GB/s for RF 3) |
| Storage | 1 GB/s x 86,400 x 7 days x RF 3 | **~1.8 PB** |
| Brokers | ~100 MB/s sustained per broker write budget, plus disk | **~30-50 brokers**, sized by disk and network |
| Partitions | throughput per partition ~10 MB/s; parallelism needed by consumers | **hundreds to thousands per topic cluster-wide** |

## 4. Core model

```text
topic "orders", 3 partitions, each an append-only log:
  P0: [0][1][2][3][4][5]...      offsets are positions in one partition
  P1: [0][1][2]...
  P2: [0][1][2][3]...
producer: partition = hash(key) % 3 (same key -> same partition -> ordered); no key -> round robin / sticky
consumer group "billing": each partition consumed by exactly one member; committed offset per partition
consumer group "analytics": reads the same partitions independently with its own offsets
```

## 5. API

```text
produce(topic, key?, value, headers) -> (partition, offset)         acks = 0 | 1 | all
fetch(topic, partition, offset, maxBytes) -> records               (long poll)
commit(group, topic, partition, offset)
joinGroup / heartbeat / leaveGroup                                   (membership, rebalancing)
admin: createTopic(name, partitions, replicationFactor, retention)
```

## 6. Architecture

```text
 producers --> brokers (each partition has a leader broker + followers on other brokers)
                 |   leader appends to its log segment files; followers fetch and append
                 |   high watermark = highest offset replicated to all in-sync replicas (ISR)
                 v
 consumers <-- fetch from leader up to the high watermark
 controller (KRaft/ZooKeeper quorum): broker membership, partition leadership, ISR changes
 group coordinator (a broker): group membership, partition assignment, committed offsets (__consumer_offsets topic)
```

## 7. Deep dive: the log on disk

- Each partition is a directory of **segment files** (e.g. 1 GB each) named by base offset, plus a sparse offset index and a time index.
- Writes are sequential appends; reads are sequential scans from an offset. The OS page cache serves recent data; **zero-copy** (`sendfile`) sends file bytes straight to the socket.
- **Retention:** delete whole old segments (time or size based). **Compaction** (for changelog topics): keep only the latest value per key.
- Batching and compression per batch are what make 1 GB/s possible.

## 8. Deep dive: replication and durability

- Replication factor 3: one leader, two followers. Followers fetch from the leader like consumers.
- **ISR (in-sync replicas):** followers caught up within a time bound. A lagging follower drops out of the ISR.
- **High watermark (HW):** the highest offset present on every ISR member. Consumers only see messages below the HW, so a leader failover never "un-publishes" a message a consumer already read.
- **acks:** `0` (fire and forget), `1` (leader wrote it; lost if the leader dies before followers copy), `all` (all ISR members wrote it; with `min.insync.replicas = 2`, survives one broker loss).
- **Leader election:** the controller picks a new leader from the ISR. Unclean election (from outside the ISR) trades data loss for availability: off by default.

## 9. Deep dive: consumer groups

- The coordinator assigns partitions to group members (range, round robin, or sticky assignment). More members than partitions leaves some idle: partitions cap parallelism.
- **Rebalance** when a member joins, leaves or stops heartbeating. Cooperative (incremental) rebalancing avoids stopping the whole group.
- **Offsets:** consumers commit the next offset to read. Commit **after** processing = at-least-once (a crash replays some messages). Commit **before** processing = at-most-once (a crash skips some).

## 10. Deep dive: delivery semantics

| Semantics | How |
|---|---|
| At-most-once | Commit first, then process. |
| At-least-once (default) | Process, then commit; consumers must be idempotent (dedupe by message key or ID). |
| Effectively-once | **Idempotent producer** (producer ID + sequence number per partition; the broker drops duplicates from retries) + **transactions** (write output and commit offsets atomically in read-process-write pipelines). Effects outside Kafka still need idempotent consumers. |

## 11. Failure modes

| Failure | Behavior |
|---|---|
| Leader broker dies | Controller elects a new leader from the ISR; producers and consumers refresh metadata and retry. |
| Follower slow | Removed from ISR; `acks=all` continues with remaining ISR (if at least `min.insync.replicas`). |
| Consumer crash | Heartbeats stop; rebalance gives its partitions to others; they resume from the last committed offsets (replays since then). |
| Producer retry after timeout | Idempotent producer deduplicates. |
| Slow consumers | Messages accumulate (lag) within retention; no backpressure on producers: monitor lag. |

## 12. What interviewers look for

- Partitioned append-only log with offsets; why it is fast (sequential I/O, batching, page cache, zero-copy).
- Ordering per partition via keys, not global ordering.
- Consumer groups and offset commits, with the delivery semantics they produce.
- Replication with ISR, high watermark and acks.

## 13. Common mistakes

- Promising global ordering at high throughput.
- Deleting messages when consumed (then multiple consumer groups and replay are impossible).
- Claiming exactly-once delivery without idempotence.
- Ignoring what consumers see during leader failover (the high watermark's purpose).

## 14. Follow-ups

1. **Delayed / scheduled messages:** separate delay topics per interval, or a timing wheel.
2. **Dead-letter topics** for messages that repeatedly fail processing.
3. **Tiered storage:** old segments in object storage for long retention.
4. **Queue semantics with per-message acks** (SQS): visibility timeouts and redelivery per message instead of offsets.

See [LLD.md](LLD.md) for segmented partition logs, partitioning by key, replication with a high watermark, idempotent producers and consumer groups with offset commits.
