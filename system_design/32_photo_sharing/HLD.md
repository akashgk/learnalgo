# Photo Sharing (Instagram): High-Level Design

**Asked at:** Meta, Snap, Pinterest, Google, Amazon. **Core topics:** direct-to-storage uploads with pre-signed URLs, asynchronous media processing (resized variants), blob storage + CDN, metadata sharding, like and comment counters at extreme write rates (sharded counters), hashtags, stories that expire. (The home feed itself is covered in 06.)

## 1. Clarify the scope

| Question | Assumed answer |
|---|---|
| Features? | Upload photos with captions and hashtags, view a profile grid, like, comment, follow, stories (disappear after 24 h). Home feed: see 06. |
| Scale? | 500 M DAU; 100 M photos uploaded/day; ~5 B likes/day. |
| Photo size? | ~3 MB original; served in several sizes. |
| Latency? | Images load fast worldwide; uploads may take a few seconds to process. |
| Consistency? | Like counts can be approximate for a few seconds; a user's own like must show immediately. |

## 2. Requirements

**Functional:** upload, view, like/unlike, comment, follow, hashtag search, stories.

**Non-functional:** very read-heavy media (CDN), durable storage of originals, high write throughput for likes, availability over strict consistency for counts.

## 3. Capacity estimates

| Quantity | Math | Result |
|---|---|---|
| Uploads | 100 M/day | **~1,200/s** avg |
| Storage | 100 M x (3 MB original + ~0.5 MB variants) | **~350 TB/day**, ~125 PB/year (tiered storage) |
| Likes | 5 B/day | **~58K/s** avg, much higher on viral posts |
| Image views | 500 M x ~200 images/day | **~1.2 M image requests/s**: CDN only |

## 4. Architecture

```text
 Upload:
  app --1. POST /uploads--> Upload service --returns pre-signed URL (expires, size limit, content type)
  app --2. PUT bytes directly--> object storage (originals)
  app --3. POST /posts {uploadId, caption}--> Post service --> posts DB (sharded by post ID / user ID)
  storage event --> processing queue --> workers: validate, strip EXIF location, resize to variants,
                                       moderation checks --> variants to object storage --> CDN
 Read:
  app --> CDN (images by variant URL) ; API --> post metadata (cache) + counts (counter service)
 Engagement:
  like/unlike --> Like service: user-post like set (dedupe) + sharded counters --> async aggregation
  hashtags --> Kafka --> hashtag index (tag -> recent post IDs, and top posts)
 Stories: same upload path; metadata with expiresAt = now + 24 h; TTL deletes; served from cache
```

## 5. Deep dive: uploads

- **Pre-signed URLs** let clients upload straight to object storage; application servers never proxy gigabytes of bytes.
- The URL is scoped: one object key, a content type, a maximum size, a short expiry. The post is created only after the upload is confirmed.
- **Processing** is asynchronous: the post shows a placeholder until variants are ready (usually seconds). Variants (e.g. 150 px thumbnail, 640 px, 1080 px) keep the aspect ratio; the CDN serves the size the device needs.

## 6. Deep dive: counters for likes

A viral post gets thousands of likes per second; one counter row becomes a hot spot.

- **Who liked what** is the source of truth: a `likes(post_id, user_id)` set (wide-column store), which also makes likes idempotent (liking twice does nothing).
- **Sharded counters:** the count is split across N sub-counters (`post:123:likes:shard{k}`), each write increments a random shard; reads sum the shards (cached for a few seconds).
- Or **asynchronous aggregation:** like events go to Kafka; a stream job updates counts in batches.
- The user's own like is shown optimistically by the client.

## 7. Deep dive: storage and data model

```text
users(id, ...)         follows(follower, followee)        (see 06)
posts(id Snowflake, user_id, caption, media_keys, created_at)   sharded by user_id for profile grids
likes(post_id, user_id, created_at)                       partition by post_id
comments(post_id, comment_id, user_id, text)              partition by post_id, clustered by time
hashtag_posts(tag, bucket, post_id)                       recent posts per tag
```

- Originals in object storage with lifecycle rules (infrequent access after 30 days, archive tiers).
- Image URLs contain the variant and a content hash, so CDN caching is permanent (immutable objects).

## 8. Failure modes

| Failure | Behavior |
|---|---|
| Upload interrupted | Pre-signed URL can be retried until expiry; multipart uploads for large videos. |
| Processing backlog | Queue grows; posts show placeholders longer; autoscale workers. |
| Hot post | Counter shards spread writes; CDN absorbs image reads; metadata cached. |
| Story expiry job behind | Reads filter by `expiresAt` anyway (lazy expiry). |

## 9. What interviewers look for

- Direct uploads with pre-signed URLs and asynchronous processing.
- CDN-first image delivery with variants.
- A real answer for like-count hot spots (idempotent like set + sharded or aggregated counters).
- Data model and sharding choices.

## 10. Common mistakes

- Uploading images through application servers.
- Storing images in the database.
- `UPDATE posts SET likes = likes + 1` on every like.
- Synchronous resizing in the upload request.

## 11. Follow-ups

1. **Video (Reels):** see 12 for transcoding and streaming.
2. **Explore page:** recommendations (see 41).
3. **Privacy:** private accounts checked on every read; signed CDN URLs for private media.
4. **Deduplication:** perceptual hashes for re-uploads and moderation.

See [LLD.md](LLD.md) for pre-signed upload tokens, variant sizing, idempotent likes with sharded counters, expiring stories and a hashtag index.
