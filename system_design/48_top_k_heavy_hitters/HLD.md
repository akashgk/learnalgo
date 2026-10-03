# Top-K Heavy Hitters / Trending (top songs, trending hashtags, most-viewed products): High-Level Design

**Asked at:** Google, Meta, Amazon, Twitter/X, Spotify, TikTok. **Core topics:** exact vs approximate counting at stream scale, Count-Min Sketch, Space-Saving / Misra-Gries, windowed top-k, distributed aggregation and its pitfalls, reconciling fast approximate results with slow exact ones.

## 1. Clarify the scope

| Question | Assumed answer |
|---|---|
| Events? | Plays/views/searches with an item ID: ~1 M events/s. |
| Distinct items? | Hundreds of millions (long tail). |
| Output? | Top 100 items for the last 1 minute, 1 hour, 1 day; refreshed every few seconds to a minute. |
| Accuracy? | Approximate is fine for real-time trending; exact daily numbers for reporting can come later. |

## 2. Requirements

**Functional:** ingest events; maintain top-k per window; serve top-k queries quickly.

**Non-functional:** bounded memory regardless of distinct items, high throughput, low query latency, fault tolerance, an accuracy guarantee that can be stated.

## 3. Capacity estimates

| Quantity | Math | Result |
|---|---|---|
| Events | 1 M/s | ~86 B/day |
| Exact counts per day | 300 M distinct items x (16 B key + 8 B count + overhead) | **~10-20 GB** per window: possible on big machines, expensive to keep per minute |
| Count-Min Sketch | width 2,000,000 x depth 5 x 4 B | **40 MB**, with error ≤ 0.0001% of total events per item (w = e/ε) |
| Space-Saving with 10,000 counters | | **< 1 MB**, guarantees any item above total/10,000 is tracked |

## 4. Approaches

| Approach | Memory | Guarantee |
|---|---|---|
| Exact hash map + heap | O(distinct items) | exact; costly at scale |
| **Count-Min Sketch + heap of candidates** | O(width x depth) | counts overestimate by at most ε x N with probability 1 - δ (w = ⌈e/ε⌉, d = ⌈ln 1/δ⌉); never underestimates |
| **Space-Saving (Metwally) / Misra-Gries** | O(k / ε) counters | every item with frequency > N/m appears among m counters; per-item error bounded |
| Sampling | small | rough; misses mid-frequency items |

## 5. Architecture

```text
 producers --> Kafka (events, partitioned by item ID)
                  |
       stream workers (per partition): Space-Saving or CMS + candidate heap per 1-minute bucket
                  |  every N seconds: emit local top-k' (k' > k, e.g. 10x) per bucket
                  v
       aggregator: merge partitions' lists per bucket; combine last 60 buckets for "1 hour" (ring buffer)
                  |
       top-k store (Redis) --> API --> clients
 batch (daily): exact counts from the event archive (MapReduce/Spark) for reports and corrections
```

**Partition by item ID:** each item's events go to one worker, so per-partition counts are complete and merging local top-k lists is exact for items in them. If events were partitioned randomly, an item could be moderately frequent everywhere yet in no local top-k: merging top-k lists would then miss global heavy hitters (send top-k' with k' ≫ k, or merge sketches instead).

## 6. Windows

- **Tumbling buckets** (per minute) kept in a ring; "last hour" = merge of 60 buckets. Sketches merge by adding counters (same dimensions and hash functions).
- **Decay** (exponentially weighted counts) is an alternative for "trending" (recent velocity matters more than totals).
- Trending is often **relative**: compare the current rate to the item's baseline (z-score), not just raw counts, or everything popular is always "trending".

## 7. Failure modes

| Failure | Behavior |
|---|---|
| Worker crash | Replay from Kafka offsets with checkpointed sketch state (see 27). |
| Hot item skews a partition | Pre-aggregate in producers; or split the key with a suffix and merge. |
| Late events | Accept into the right bucket within a grace period; ignore after. |

## 8. What interviewers look for

- Recognizing that exact counting does not scale per window, and naming an approximate structure with its guarantee.
- Correct distributed merging (partition by key, or merge sketches).
- Windowing with buckets and merges.

## 9. Common mistakes

- Merging per-node top-k lists from randomly partitioned streams.
- Claiming Count-Min Sketch underestimates (it only overestimates).
- Recomputing the hour's top-k from raw events every minute.

## 10. Follow-ups

1. **Distinct counts** (unique listeners): HyperLogLog per item.
2. **Personalized trending:** per region or per community.
3. **Spam resistance:** cap contributions per user before counting.

See [LLD.md](LLD.md) for a Count-Min Sketch with a candidate heap, the Space-Saving algorithm, mergeable per-minute buckets for a sliding window, and accuracy checks against exact counts on skewed data.
