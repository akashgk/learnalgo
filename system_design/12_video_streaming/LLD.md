# Video Streaming: Low-Level Design

## 1. Scope for the LLD round

Three components an interviewer can ask you to code, each small:

1. **Resumable upload session:** fixed-size chunks, any order, checksums, idempotent retries, "which chunks are missing?".
2. **Transcoding job planner:** split a video into segments x renditions; workers claim tasks (lowest rendition first); retries; the video becomes **playable** when the lowest rendition is done and **ready** when every rendition is done or permanently failed.
3. **Playback:** HLS master and media playlists from finished renditions, a throughput estimator, and two **bitrate selection strategies** (throughput-based and buffer-based).

Out of scope: real encoding, CDN, DRM (HLD).

## 2. Entities and responsibilities

| Class | Responsibility |
|---|---|
| `UploadSession` | Chunk bookkeeping and validation; assembles the file once complete. |
| `Rendition` | Name, resolution, bitrate (one rung of the ladder). |
| `TranscodeTask` | One (segment, rendition) unit of work with status and attempts. |
| `TranscodeJob` | All tasks of one video; claim / complete / fail; derives rendition and video status. |
| `Playlists` | HLS master playlist (renditions) and media playlist (segments). |
| `ThroughputEstimator` | Exponentially weighted moving average of measured download speed. |
| `BitrateSelector` (interface) | `ThroughputSelector`, `BufferBasedSelector`. |

```text
UploadSession --(complete file)--> TranscodeJob --has many--> TranscodeTask (segment x Rendition)
                                        |
                                        +--ready renditions--> Playlists (master + media .m3u8)
Player: ThroughputEstimator + BitrateSelector (interface) <-- ThroughputSelector, BufferBasedSelector
```

## 3. Design decisions and why

- **Chunks are identified by index and validated by size and checksum.** A retried chunk with the same content is accepted again (idempotent); different content for a received index is rejected. The server can always answer "missing chunks", which is what makes resuming possible.
- **Tasks per (segment, rendition):** maximal parallelism, and a failure costs one small task, not a whole video.
- **Claim order: lowest rendition first.** The video becomes playable as early as possible; higher qualities are added later.
- **Status is derived from task states**, never stored separately and then forgotten. One method computes it.
- **Bounded retries** per task; a rendition whose task exhausts its attempts is marked failed, and the video is still served without it, unless it is the lowest rendition (then nothing can play).
- **Bitrate selection is a strategy**: players experiment with these heavily, and the rest of the player does not change.

## 4. The code

```dart
// ---------- Upload ----------

int checksum(List<int> bytes) {
  var h = 0x811C9DC5;
  for (final b in bytes) {
    h = ((h ^ b) * 0x01000193) & 0xFFFFFFFF;
  }
  return h;
}

class UploadException implements Exception {
  UploadException(this.message);
  final String message;
  @override
  String toString() => message;
}

class UploadSession {
  UploadSession({required this.totalBytes, required this.chunkSize})
    : chunkCount = (totalBytes + chunkSize - 1) ~/ chunkSize;

  final int totalBytes;
  final int chunkSize;
  final int chunkCount;
  final _chunks = <int, List<int>>{};

  int expectedSize(int index) => index == chunkCount - 1 ? totalBytes - chunkSize * (chunkCount - 1) : chunkSize;

  void putChunk(int index, List<int> bytes, int sum) {
    if (index < 0 || index >= chunkCount) throw UploadException('chunk $index out of range');
    if (bytes.length != expectedSize(index)) throw UploadException('chunk $index has wrong size');
    if (checksum(bytes) != sum) throw UploadException('chunk $index checksum mismatch');
    final existing = _chunks[index];
    if (existing != null && checksum(existing) != sum) throw UploadException('chunk $index already received');
    _chunks[index] = List.unmodifiable(bytes);
  }

  List<int> get missingChunks => [
    for (var i = 0; i < chunkCount; i++)
      if (!_chunks.containsKey(i)) i,
  ];

  bool get isComplete => _chunks.length == chunkCount;

  List<int> assemble() {
    if (!isComplete) throw UploadException('missing chunks: $missingChunks');
    return [for (var i = 0; i < chunkCount; i++) ..._chunks[i]!];
  }
}

// ---------- Transcoding ----------

class Rendition {
  const Rendition(this.name, this.width, this.height, this.kbps);
  final String name;
  final int width;
  final int height;
  final int kbps;
  @override
  String toString() => name;
}

enum TaskStatus { pending, running, done, failed }

class TranscodeTask {
  TranscodeTask(this.segment, this.rendition);
  final int segment;
  final Rendition rendition;
  TaskStatus status = TaskStatus.pending;
  int attempts = 0;
  String get id => '${rendition.name}#$segment';
}

enum VideoStatus { processing, playable, ready, failed }

class TranscodeJob {
  TranscodeJob({
    required this.videoId,
    required this.durationSec,
    required List<Rendition> ladder,
    this.segmentSec = 4,
    this.maxAttempts = 3,
  }) : ladder = [...ladder]..sort((a, b) => a.kbps.compareTo(b.kbps)) {
    segmentCount = (durationSec / segmentSec).ceil();
    for (final r in this.ladder) {
      for (var s = 0; s < segmentCount; s++) {
        final t = TranscodeTask(s, r);
        _tasks[t.id] = t; // insertion order = lowest rendition first, then by segment
      }
    }
  }

  final String videoId;
  final double durationSec;
  final List<Rendition> ladder;
  final int segmentSec;
  final int maxAttempts;
  late final int segmentCount;
  final _tasks = <String, TranscodeTask>{};

  int get taskCount => _tasks.length;

  /// Next pending task, lowest rendition first. In production: a queue with visibility timeouts.
  TranscodeTask? claim() {
    for (final t in _tasks.values) {
      if (t.status == TaskStatus.pending) {
        t
          ..status = TaskStatus.running
          ..attempts += 1;
        return t;
      }
    }
    return null;
  }

  void complete(String taskId) => _tasks[taskId]!.status = TaskStatus.done;

  void fail(String taskId) {
    final t = _tasks[taskId]!;
    t.status = t.attempts >= maxAttempts ? TaskStatus.failed : TaskStatus.pending;
  }

  Iterable<TranscodeTask> _of(Rendition r) => _tasks.values.where((t) => t.rendition == r);

  bool isRenditionDone(Rendition r) => _of(r).every((t) => t.status == TaskStatus.done);
  bool isRenditionFailed(Rendition r) => _of(r).any((t) => t.status == TaskStatus.failed);

  List<Rendition> get readyRenditions => ladder.where(isRenditionDone).toList();

  VideoStatus get status {
    if (isRenditionFailed(ladder.first)) return VideoStatus.failed;
    final settled = ladder.every((r) => isRenditionDone(r) || isRenditionFailed(r));
    if (settled) return VideoStatus.ready;
    return isRenditionDone(ladder.first) ? VideoStatus.playable : VideoStatus.processing;
  }
}

// ---------- Playlists ----------

class Playlists {
  static String master(List<Rendition> renditions) => [
    '#EXTM3U',
    for (final r in renditions) ...[
      '#EXT-X-STREAM-INF:BANDWIDTH=${r.kbps * 1000},RESOLUTION=${r.width}x${r.height}',
      '${r.name}/index.m3u8',
    ],
  ].join('\n');

  static String media(double durationSec, int segmentSec) {
    final count = (durationSec / segmentSec).ceil();
    return [
      '#EXTM3U',
      '#EXT-X-TARGETDURATION:$segmentSec',
      for (var i = 0; i < count; i++) ...[
        '#EXTINF:${(i == count - 1 ? durationSec - segmentSec * i : segmentSec).toStringAsFixed(3)},',
        'seg_$i.ts',
      ],
      '#EXT-X-ENDLIST',
    ].join('\n');
  }
}

// ---------- Bitrate selection ----------

class ThroughputEstimator {
  ThroughputEstimator({this.alpha = 0.5});
  final double alpha;
  double? kbps;

  void onSegmentDownloaded({required int bytes, required int millis}) {
    final sample = bytes * 8 / millis; // bits per ms == kbps
    kbps = kbps == null ? sample : alpha * sample + (1 - alpha) * kbps!;
  }
}

class PlayerState {
  const PlayerState({required this.throughputKbps, required this.bufferSec});
  final double throughputKbps;
  final double bufferSec;
}

abstract interface class BitrateSelector {
  Rendition choose(List<Rendition> ladder, PlayerState state);
}

/// Highest rendition whose bitrate fits within a safety fraction of the measured throughput.
class ThroughputSelector implements BitrateSelector {
  ThroughputSelector({this.safety = 0.8});
  final double safety;

  @override
  Rendition choose(List<Rendition> ladder, PlayerState s) =>
      ladder.lastWhere((r) => r.kbps <= s.throughputKbps * safety, orElse: () => ladder.first);
}

/// Buffer-based (BBA-style): below the reservoir play the lowest, above reservoir + cushion the highest,
/// and map linearly in between. Ignores noisy throughput measurements entirely.
class BufferBasedSelector implements BitrateSelector {
  BufferBasedSelector({this.reservoirSec = 5, this.cushionSec = 20});
  final double reservoirSec;
  final double cushionSec;

  @override
  Rendition choose(List<Rendition> ladder, PlayerState s) {
    if (s.bufferSec <= reservoirSec) return ladder.first;
    if (s.bufferSec >= reservoirSec + cushionSec) return ladder.last;
    final fraction = (s.bufferSec - reservoirSec) / cushionSec;
    return ladder[(fraction * (ladder.length - 1)).floor()];
  }
}

// ---------- Self-checks ----------

void check(Object? actual, Object? expected) {
  if ('$actual' != '$expected') throw StateError('expected $expected, got $actual');
  print('ok: $actual');
}

void expectThrows<T extends Object>(void Function() f) {
  try {
    f();
  } on T {
    print('ok: threw $T');
    return;
  }
  throw StateError('expected $T');
}

void main() {
  // Resumable upload: 10 bytes in chunks of 4 -> chunks of 4, 4, 2.
  final file = List.generate(10, (i) => i * 7);
  List<int> chunk(int i) => file.sublist(i * 4, i * 4 + 4 > 10 ? 10 : i * 4 + 4);
  final upload = UploadSession(totalBytes: 10, chunkSize: 4);
  check([upload.chunkCount, upload.expectedSize(2)], [3, 2]);
  upload.putChunk(2, chunk(2), checksum(chunk(2))); // out of order is fine
  check(upload.missingChunks, [0, 1]);
  expectThrows<UploadException>(() => upload.putChunk(0, chunk(0), 12345)); // corrupted in transit
  expectThrows<UploadException>(() => upload.putChunk(1, [1, 2], checksum([1, 2]))); // wrong size
  upload.putChunk(0, chunk(0), checksum(chunk(0)));
  upload.putChunk(0, chunk(0), checksum(chunk(0))); // retry of the same chunk: accepted
  expectThrows<UploadException>(() => upload.putChunk(0, [9, 9, 9, 9], checksum([9, 9, 9, 9])));
  expectThrows<UploadException>(upload.assemble);
  upload.putChunk(1, chunk(1), checksum(chunk(1)));
  check(upload.assemble(), file);

  // Transcoding: a 10 s video in 4 s segments -> 3 segments x 3 renditions.
  const p240 = Rendition('240p', 426, 240, 400);
  const p480 = Rendition('480p', 854, 480, 1400);
  const p720 = Rendition('720p', 1280, 720, 3000);
  final job = TranscodeJob(videoId: 'v1', durationSec: 10, ladder: [p720, p240, p480]);
  check([job.segmentCount, job.taskCount, job.status], [3, 9, VideoStatus.processing]);

  final firstThree = [for (var i = 0; i < 3; i++) job.claim()!];
  check(firstThree.map((t) => t.id), '(240p#0, 240p#1, 240p#2)'); // lowest rendition first
  firstThree.forEach((t) => job.complete(t.id));
  check([job.status, job.readyRenditions], [VideoStatus.playable, '[240p]']);
  check(
    Playlists.master(job.readyRenditions),
    '#EXTM3U\n#EXT-X-STREAM-INF:BANDWIDTH=400000,RESOLUTION=426x240\n240p/index.m3u8',
  );

  // Retries: a task that fails twice and then succeeds; another that exhausts its attempts.
  var t = job.claim()!; // 480p#0
  job.fail(t.id);
  t = job.claim()!;
  check([t.id, t.attempts], ['480p#0', 2]);
  job.complete(t.id);
  while (true) {
    final next = job.claim();
    if (next == null) break;
    if (next.id == '720p#1') {
      job.fail(next.id); // fails on every attempt
    } else {
      job.complete(next.id);
    }
  }
  check([job.isRenditionFailed(p720), job.status, job.readyRenditions], [true, VideoStatus.ready, '[240p, 480p]']);

  // The lowest rendition failing means nothing can play.
  final broken = TranscodeJob(videoId: 'v2', durationSec: 4, ladder: [p240], maxAttempts: 1);
  broken.fail(broken.claim()!.id);
  check(broken.status, VideoStatus.failed);

  check(
    Playlists.media(10, 4),
    '#EXTM3U\n#EXT-X-TARGETDURATION:4\n#EXTINF:4.000,\nseg_0.ts\n#EXTINF:4.000,\nseg_1.ts\n'
    '#EXTINF:2.000,\nseg_2.ts\n#EXT-X-ENDLIST',
  );

  // Bitrate selection.
  final est = ThroughputEstimator()..onSegmentDownloaded(bytes: 1000000, millis: 2000); // 4000 kbps
  est.onSegmentDownloaded(bytes: 250000, millis: 2000); // 1000 kbps sample
  check(est.kbps, 2500.0);
  final ladder = [p240, p480, p720];
  final byThroughput = ThroughputSelector();
  check([
    for (final kbps in [300.0, 2000.0, 3700.0, 3800.0])
      byThroughput.choose(ladder, PlayerState(throughputKbps: kbps, bufferSec: 10)),
  ], '[240p, 480p, 480p, 720p]');
  final byBuffer = BufferBasedSelector();
  check([
    for (final buf in [2.0, 12.0, 16.0, 30.0]) byBuffer.choose(ladder, PlayerState(throughputKbps: 0, bufferSec: buf)),
  ], '[240p, 240p, 480p, 720p]');
}
```

## 5. Walkthrough

- The upload accepts chunk 2 first, rejects a corrupted chunk and a wrong-sized one, accepts a retried identical chunk, rejects a conflicting rewrite, and only assembles when nothing is missing.
- Ladder order is normalized (sorted by bitrate), so the first claims are all 240p segments; after three completions the video is `playable` with a one-entry master playlist.
- `480p#0` fails once and is reclaimed with `attempts = 2`. `720p#1` fails three times and is marked failed; the video is `ready` with 240p and 480p only. A failed lowest rendition makes the video `failed`.
- The 10 s video's media playlist ends with a 2-second segment.
- Throughput: the estimate after samples of 4,000 and 1,000 kbps with alpha 0.5 is 2,500 kbps. With a 0.8 safety factor, 720p (3,000 kbps) needs at least 3,750 kbps measured. Buffer-based: 12 s of buffer is 35% of the way through the cushion (index floor(0.35 x 2) = 0: 240p), 16 s is 55% (index 1: 480p), 30 s is past the cushion (720p).

## 6. Concurrency

- Upload chunks arrive in parallel: per-session state needs a lock or an atomic "set bit in received bitmap" plus a conditional write of the chunk object (`If-None-Match` style).
- Task claiming across thousands of workers: a queue with **visibility timeouts** (a claimed task reappears if the worker dies), and idempotent outputs (the segment path is deterministic, so a duplicate encode overwrites with identical bytes).
- Deriving status from tasks under concurrency: either a transaction over the task rows or counters per rendition updated atomically when tasks finish.

## 7. Extensibility

| Change | Where |
|---|---|
| New codec (AV1) for popular videos | Extra renditions added to the job later; the player sees them in the master playlist. |
| Thumbnails, captions, checks | More task types in the job's DAG, with their own dependencies. |
| DASH as well as HLS | Another playlist writer. |
| Hybrid ABR (throughput and buffer) | A new `BitrateSelector` combining both. |
| Priority for popular uploaders | Order `claim` by job priority before rendition. |

## 8. Common mistakes in LLD rounds

- Upload as a single request with no way to resume.
- One task per video (no parallelism, a failure redoes everything).
- Storing a status flag that drifts from the real task states.
- Choosing bitrate from a single noisy throughput sample.
- Forgetting the final, shorter segment in the playlist.

See [HLD.md](HLD.md) for the processing pipeline, CDN delivery and view counting.
