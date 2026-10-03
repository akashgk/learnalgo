# Social News with Voting and Comments (Reddit / Hacker News): High-Level Design

**Asked at:** Reddit, Meta, Twitter/X, Quora, Stack Overflow, Discord. **Core topics:** idempotent votes at high write rates, score counters, time-decayed ranking ("hot"), confidence-based comment ranking (Wilson score), nested comment trees, caching front pages, vote manipulation.

## 1. Clarify the scope

| Question | Assumed answer |
|---|---|
| Features? | Communities, posts, up/down votes, nested comments with votes, front page (hot/new/top), user karma. |
| Scale? | 50 M DAU; 1 M posts/day; 10 M comments/day; 100 M votes/day; read-heavy front pages. |
| Consistency? | Vote counts can lag seconds; a user's own vote must be reflected immediately for them. |
| Abuse? | Bots and vote rings exist; mitigations matter. |

## 2. Requirements

**Functional:** create posts and comments; vote (and change or remove a vote); list posts by hot/new/top; show a comment tree sorted by "best"; karma.

**Non-functional:** fast reads (cached listings), high vote throughput, idempotent votes, eventual consistency for counts and rankings, protection against manipulation.

## 3. Capacity estimates

| Quantity | Math | Result |
|---|---|---|
| Votes | 100 M/day | **~1,200/s** avg, much higher on viral threads |
| Front page reads | 50 M x 20 loads/day | **~12K/s**: served from cache |
| Vote records | 100 M/day x 30 B | **~3 GB/day** |
| Comment tree of a big thread | 50K comments | must load lazily (top levels first) |

## 4. Architecture

```text
 clients --> CDN (logged-out pages) --> API
   vote --> Vote service: upsert (user, item) -> {-1, 0, +1} (idempotent), emit delta event --> Kafka
              --> score aggregator: apply deltas to item counters (ups, downs) in batches --> items DB / cache
              --> ranking workers: recompute hot score for changed posts; update listing sorted sets per community
   read listing --> Redis sorted set (community:hot) -> post IDs -> post cache
   read thread --> comment service: top-level comments by "best", children lazily ("load more")
 anti-abuse: rate limits, vote weighting by account age/reputation, ring detection offline, vote fuzzing on display
```

## 5. Deep dive: votes

- Store the vote per (user, item); a new vote replaces the old one. The **delta** (new - old) updates the counters, so changing an upvote to a downvote moves the score by 2 and repeating a vote changes nothing.
- Counters (`ups`, `downs`) are updated asynchronously in batches (hot items get sharded counters, see 32).

## 6. Deep dive: ranking

- **Hot (Reddit):** `sign(s) x log10(max(|s|, 1)) + (t - epoch) / 45000` where s = ups - downs and t is the post time in seconds. Logarithmic votes plus linear time: the first 10 votes count as much as the next 90; a post needs 10x the votes to compete with one 12.5 hours newer. The score changes only when votes change (time is the post's creation time), so it can be stored and indexed.
- **Hacker News:** `(points - 1) / (age_hours + 2)^1.8`: decays with age continuously, so it must be recomputed periodically.
- **Best comments:** the **lower bound of the Wilson score interval** for the fraction of upvotes: confident about many votes, cautious about few (1 up / 0 down ranks below 100 up / 10 down).
- **Top:** raw score within a time range; **controversial:** many votes, balanced up/down.

## 7. Deep dive: comment trees

- Store comments with `parent_id` and a **materialized path** (`0001.0042.0007`) or closure table to fetch subtrees in one query.
- Render by levels: top N children of each node by "best", with "load more" links; limit depth; cache rendered trees for hot threads.

## 8. Failure modes

| Failure | Behavior |
|---|---|
| Vote storm on one post | Sharded counters, batched aggregation; listing updates throttled. |
| Aggregator lag | Scores slightly stale; user's own vote shown from their vote record. |
| Cache cold for a hot listing | Rebuild from the sorted set; request coalescing. |

## 9. What interviewers look for

- Idempotent votes with deltas.
- A concrete ranking formula and why it works (log of votes, time term, Wilson bound for comments).
- Storing hot scores in sorted sets per community; caching listings.
- Comment tree storage and lazy loading.

## 10. Common mistakes

- Sorting comments by net score (new comments with 1 upvote outrank or underrank unfairly) or by ratio (1/1 = 100%).
- Recomputing rankings over all posts on every request.
- Counting repeated votes.

## 11. Follow-ups

1. **Personalized front page:** merge subscribed communities' listings (fan-out on read, see 06).
2. **Vote fuzzing:** display slightly noisy counts to confuse bots.
3. **Moderation queues** and removed-content handling.

See [LLD.md](LLD.md) for idempotent votes, the hot formula, the Wilson lower bound, a comment tree with "best" ordering and lazy children, and community listings.
