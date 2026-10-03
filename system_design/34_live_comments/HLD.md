# Live Comments (Facebook Live / Twitch chat / YouTube live chat): High-Level Design

**Asked at:** Meta, Twitch (Amazon), Google, TikTok, Discord. **Core topics:** real-time fan-out to millions of viewers, subscription-based routing through gateway servers, why per-viewer fan-out in the core fails, rate limiting and moderation, sampling for huge streams, catch-up for new viewers.

## 1. Clarify the scope

| Question | Assumed answer |
|---|---|
| Who sees comments? | Everyone watching the same live video, in near real time. |
| Scale? | Most streams have < 100 viewers; the biggest have 5 M concurrent viewers and 10K+ comments/s. |
| Latency? | Comments appear within ~1-2 s. |
| Ordering? | Roughly by time; strict global order is not required. |
| Durability? | Comments are stored for replay (VOD) but delivery is best effort. |
| Moderation? | Banned words, slow mode, per-user limits, moderator deletes. |

## 2. Requirements

**Functional:** post a comment to a live video; receive comments in real time; new viewers see recent comments; moderators delete comments and ban users.

**Non-functional:** low latency, massive fan-out, graceful degradation for huge streams (nobody can read 10K comments/s), availability over strict delivery guarantees.

## 3. Capacity estimates

| Quantity | Math | Result |
|---|---|---|
| Concurrent viewers (platform) | | **~50 M** WebSocket connections |
| Gateway servers | ~100K connections each | **~500 servers** |
| Biggest stream | 5 M viewers x 10K comments/s if delivered to everyone | **50 B deliveries/s**: impossible and useless; must sample |
| Typical stream | 100 viewers x 1 comment/s | trivial |

## 4. Architecture

```text
 viewer --WebSocket--> Gateway server G (holds ~100K connections; knows which videos its viewers watch)
                           |   subscribe(video) once per gateway, not per viewer
                           v
                     Channel registry: video -> set of gateways with at least one viewer
 poster --> Comment service: auth, rate limit, moderation, assign ID/time, persist (Cassandra by video, time)
                           |
                           v
                     Pub/sub (per-video channel) --one message per subscribed gateway--> gateways
                           gateways fan out to their local viewers of that video (in memory)
 new viewer --> recent comments buffer (last N per video, Redis) --> then live stream
```

**Key idea:** the publishing path sends a comment to each **gateway** that has viewers of the video, not to each viewer. A video with 5 M viewers spread over 500 gateways costs 500 messages per comment in the core; each gateway does its local fan-out.

## 5. Deep dive: subscriptions

- When the first viewer of video V connects to gateway G, G subscribes to V in the registry; when the last one leaves, G unsubscribes.
- The registry can be a pub/sub system (Redis pub/sub, Kafka topics, or a custom in-memory broker partitioned by video).
- Viewers of the same popular video can be steered to the same gateways (consistent hashing on video ID when choosing a gateway) to reduce the number of gateways per video.

## 6. Deep dive: huge streams

- **Sampling:** above a threshold, each viewer receives at most ~5-10 comments/s: a sample of the stream, prioritizing comments from friends, the streamer, moderators, and paid/highlighted messages.
- **Aggregation:** emoji reactions are counted and sent as periodic totals, not individual events.
- **Slow mode / followers-only mode** for posters on huge streams.

## 7. Deep dive: moderation and abuse

- Synchronous checks before publishing: banned words, per-user rate limit (token bucket, see 02), slow mode, banned users.
- Asynchronous ML moderation; a deleted comment is broadcast as a delete event so clients remove it.

## 8. Failure modes

| Failure | Behavior |
|---|---|
| Gateway dies | Viewers reconnect elsewhere; the new gateway subscribes and replays recent comments from the buffer. |
| Pub/sub partition overload | Partition channels by video; shed load by sampling earlier. |
| Comment store slow | Publish first, persist asynchronously (best effort for VOD replay). |

## 9. What interviewers look for

- Two-level fan-out (core to gateways, gateways to viewers) with subscription tracking.
- Recognizing that very large streams must be sampled.
- Rate limiting and moderation in the posting path.
- Catch-up for late joiners.

## 10. Common mistakes

- Pushing each comment to every viewer from a central service.
- Polling the database for new comments.
- Requiring strict ordering or guaranteed delivery for chat.

## 11. Follow-ups

1. **Replay with VOD:** comments stored with video timestamps and replayed in sync.
2. **Reactions at scale:** periodic counters.
3. **Multi-region:** regional gateways and pub/sub, cross-region replication of comments.

See [LLD.md](LLD.md) for the gateway-level subscription registry, local fan-out, a recent-comments buffer, per-user rate limits, moderation and sampling.
