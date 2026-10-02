# Video Streaming (YouTube / Netflix): High-Level Design

**Asked at:** Google, Netflix, Amazon, Meta, Microsoft. **Core topics:** resumable uploads, the transcoding pipeline, adaptive bitrate streaming (HLS/DASH), CDNs, metadata at scale, view counting.

## 1. Clarify the scope

| Question | Assumed answer |
|---|---|
| YouTube (user uploads) or Netflix (studio catalog)? | YouTube-like: anyone uploads; everyone watches. (Netflix: fewer uploads, heavy pre-positioning in ISPs.) |
| Features? | Upload, transcode, watch with adaptive quality on any device, video metadata page, view counts. Comments, recommendations, live streaming are follow-ups. |
| Scale? | 500 M daily active viewers watching ~5 videos each; 500 hours of video uploaded per minute. |
| Video lengths and quality? | Up to hours; renditions from 240p to 4K. |
| Start latency? | Playback starts in < ~2 s; no rebuffering on decent networks. |
| Availability after upload? | Minutes is acceptable (transcoding takes time). |

## 2. Requirements

**Functional:** upload (resumable), process into multiple resolutions and formats, stream with quality adapting to the network, show metadata, count views.

**Non-functional:** very high read bandwidth, low start latency worldwide, high availability for playback, durable storage of originals, cost efficiency (storage and egress dominate the bill).

## 3. Capacity estimates

| Quantity | Math | Result |
|---|---|---|
| Uploads | 500 h/min x 60 x 24 | **720K hours/day** |
| Original storage | ~1 GB per hour of HD source | **~720 TB/day** of originals |
| Transcoded storage | all renditions together ≈ 1-2x the source size | another **~1 PB/day**; storage grows by hundreds of PB per year |
| Views | 500 M x 5 | **2.5 B views/day** ≈ 29K starts/s |
| Egress | 29K concurrent starts/s x ~10 min avg ≈ 17 M concurrent streams x ~3 Mbps | **~50 Tbps** at peak-ish load: only possible through CDNs |
| Transcoding compute | 720K hours/day x several renditions, each encode ~1x realtime per core | **millions of core-hours/day** |

Conclusions: egress must come from CDN edges, not origin; transcoding is a massive parallel batch workload; storage needs tiering (popular vs long tail).

## 4. API

```text
POST /videos                         { title, description, size, contentType } -> { videoId, uploadId, chunkSize }
PUT  /uploads/{uploadId}/chunks/{n}  (bytes, checksum)       -- resumable; client retries only missing chunks
POST /uploads/{uploadId}/complete    -> 202, processing starts
GET  /videos/{id}                    -> metadata + status + manifest URL (when ready)
GET  {cdn}/videos/{id}/master.m3u8   -> renditions list;  {cdn}/videos/{id}/720p/seg_00042.ts  -> 4-second segments
POST /videos/{id}/views              (batched beacons from the player)
```

## 5. Data model

```text
videos(id, owner_id, title, description, duration, status: uploading|processing|ready|failed, created_at)
renditions(video_id, resolution, bitrate, codec, manifest_path, status)
upload_sessions(upload_id, video_id, size, chunk_size, received_chunks bitmap, expires_at)
view_counts(video_id, count)    -- approximate, aggregated from a stream
Blob storage: originals/{videoId}, segments/{videoId}/{rendition}/{n}
```

Metadata: sharded SQL or a wide-column store by `video_id`, heavily cached. Blobs: object storage (S3/GCS) behind CDNs.

## 6. Architecture

```text
 Upload path:
   client --chunks--> Upload service --> Blob store (originals)
                          | complete
                          v
                   Processing orchestrator (DAG) --> queue --> transcoding workers (thousands)
                          |    split into segments, encode each segment x each rendition in parallel,
                          |    thumbnails, content checks (copyright, policy)
                          v
                   segments + manifests --> Blob store --> pushed/pulled into CDN
                          |
                   Metadata DB: status = ready

 Watch path:
   player --> API (metadata, manifest URL, signed) --> CDN edge --(miss)--> regional cache --> origin blob store
   player --> view beacons --> Kafka --> stream aggregation --> view_counts, analytics, recommendations
```

## 7. Deep dive: transcoding pipeline

- **Split, encode in parallel, stitch:** cut the original into GOP-aligned chunks (a few seconds each); each (chunk, rendition) is an independent task. A 2-hour video becomes thousands of tasks that finish in minutes instead of hours.
- **DAG orchestration:** split -> encode tasks -> assemble manifests -> mark ready, plus side branches (thumbnails, captions, checks). Tasks are idempotent and retried on failure; a failed rendition can be retried alone.
- **Renditions (the "ladder"):** e.g. 240p/400 kbps, 360p/800 kbps, 480p/1.4 Mbps, 720p/3 Mbps, 1080p/5 Mbps, 4K/15 Mbps; codecs H.264 (compatibility), VP9/AV1 (smaller files, more CPU to encode). Popular videos can be re-encoded later with expensive codecs; the long tail keeps cheap ones (encode cost vs egress savings).
- **Fast availability:** publish low resolutions first, add higher ones as they finish.

## 8. Deep dive: adaptive bitrate streaming

- Each rendition is cut into small **segments** (2-6 s) with a **manifest** (HLS `.m3u8` or DASH `.mpd`) listing them; a master manifest lists the renditions.
- The **player** chooses the rendition per segment: throughput-based (recent download speed x safety factor), buffer-based (more buffer allows higher quality), or hybrids. It switches quality between segments seamlessly.
- Segments are plain HTTP objects: perfect for CDN caching and range requests. Startup: begin with a low bitrate, ramp up.

## 9. Deep dive: CDN and storage

- **CDN:** popular content cached at edges (and inside ISPs: Netflix Open Connect). Popularity follows a power law: a small fraction of videos carries most views.
- **Long tail:** served from regional caches or origin; cheaper storage classes for rarely watched videos (with higher first-byte latency accepted).
- **Signed URLs** with expiry for access control and to prevent hotlinking; DRM for premium content.
- **Pre-positioning:** for predictable demand (a new season), push to edges before release.

## 10. Deep dive: view counts

Player sends heartbeats; a stream processor deduplicates (per user/session/video, short window), applies validity rules (watched N seconds, not a bot), and increments counters in batches. Counts are approximate and lag by seconds to minutes. Never `UPDATE videos SET views = views + 1` per view: hot rows for viral videos.

## 11. Failure modes

| Failure | Behavior |
|---|---|
| Upload interrupted | Resume from missing chunks (session tracks received chunks). |
| Transcoding worker dies | Task times out and is retried elsewhere (idempotent output paths). |
| CDN edge down | DNS / anycast routes to the next edge; origin shielded by regional caches. |
| Origin overload (viral video) | Request coalescing at caches: one fetch per segment per cache tier. |
| Corrupt source | Processing fails with a clear status; owner notified. |

## 12. What interviewers look for

- Separate upload/processing path and watch path.
- Parallel chunked transcoding with a DAG, and why.
- Adaptive bitrate with segments and manifests.
- CDN-first delivery with the egress math.
- Asynchronous, approximate view counting.

## 13. Common mistakes

- Serving video bytes from application servers.
- Transcoding a whole long video serially on one machine.
- One fixed quality (no ABR).
- Synchronous view counter updates.
- Ignoring cost (storage tiers, codec choice by popularity).

## 14. Follow-ups

1. **Live streaming:** ingest (RTMP/SRT), real-time transcoding, low-latency HLS with short segments; no time for a full DAG.
2. **Recommendations:** separate system fed by the view stream.
3. **Copyright detection:** audio/video fingerprints matched against a reference database during processing.
4. **Offline downloads:** encrypted segments with license expiry.

See [LLD.md](LLD.md) for resumable uploads, the transcoding job planner, bitrate selection and manifest generation.
