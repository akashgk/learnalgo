# Ad Click Event Aggregation: Low-Level Design

## 1. Scope for the LLD round

- A single stream operator that counts clicks per ad per **1-minute tumbling window in event time**.
- **Deduplication** by click ID, with the dedup state expired after a TTL so it does not grow forever.
- **Watermark** = max event time seen - allowed lateness. A window is emitted when the watermark passes its end. Out-of-order events inside the lateness bound are counted; events for already-emitted windows go to a **late** side output.
- **Sink** that upserts by `(adId, windowStart)`, and **top N** ads per minute from it.
- **Checkpoint and restore:** snapshot state together with the input offset; after a crash, restore and replay from that offset. The upserting sink makes the final results identical to a run without the crash.

Out of scope: Kafka, parallelism across partitions, fraud filtering (HLD).

## 2. Entities and responsibilities

| Class | Responsibility |
|---|---|
| `Click` | `clickId`, `adId`, `eventTime` (seconds). |
| `ResultSink` | Upsert by `(adId, windowStart)`; counts writes; `topN`. |
| `Checkpoint` | Offset, max event time, open windows, dedup state (deep copies). |
| `ClickAggregator` | `process`, watermark, window firing, late output, `flush`, `snapshot`, `restore`. |

```text
events[offset] --> ClickAggregator.process
                     | dedup (clickId -> eventTime, TTL)
                     | window start = eventTime - eventTime % 60
                     | already emitted? -> late[]          else open[(ad, start)]++
                     | new max event time -> watermark -> emit windows with end <= watermark --> ResultSink.upsert
snapshot() = (offset, maxEventTime, open, seen)    restore(snapshot) + replay from offset
```

## 3. Design decisions and why

- **Event time, not arrival time,** determines the window: billing must not change because the pipeline was slow.
- **The watermark is derived from the data** (max event time - lateness), so the operator itself decides when a window is complete. Larger lateness = more complete, later results.
- **Late events are kept, not silently dropped:** they go to a side output for corrections or reconciliation.
- **Dedup state has a TTL** tied to the watermark: a duplicate arriving hours later is a reconciliation problem, not a reason to keep every click ID forever.
- **Exactly-once results = at-least-once processing + deterministic operator + idempotent sink.** After a restore, windows may be emitted twice with the same count; the upsert makes the second write harmless.

## 4. The code

```dart
import 'dart:math';

class Click {
  const Click(this.clickId, this.adId, this.eventTime);
  final String clickId;
  final String adId;
  final int eventTime;
}

class ResultSink {
  final rows = <(String, int), int>{};
  var writes = 0;

  void upsert(String adId, int windowStart, int count) {
    rows[(adId, windowStart)] = count; // idempotent: the same key and count can be written any number of times
    writes++;
  }

  List<(String, int)> topN(int windowStart, int n) {
    final inWindow = [
      for (final e in rows.entries)
        if (e.key.$2 == windowStart) (e.key.$1, e.value),
    ]..sort((a, b) => a.$2 != b.$2 ? b.$2.compareTo(a.$2) : a.$1.compareTo(b.$1));
    return inWindow.take(n).toList();
  }
}

class Checkpoint {
  Checkpoint(this.offset, this.maxEventTime, this.open, this.seen);
  final int offset;
  final int maxEventTime;
  final Map<(String, int), int> open;
  final Map<String, int> seen;
}

class ClickAggregator {
  ClickAggregator(this.sink, {this.windowSec = 60, this.allowedLatenessSec = 120, this.dedupTtlSec = 600});

  final ResultSink sink;
  final int windowSec;
  final int allowedLatenessSec;
  final int dedupTtlSec;

  var offset = 0; // events consumed: what a Kafka consumer would commit with the checkpoint
  var maxEventTime = -1 << 40;
  var _open = <(String, int), int>{};
  var _seen = <String, int>{};
  final late = <Click>[];
  var duplicates = 0;

  int get watermark => maxEventTime - allowedLatenessSec;

  void process(Click c) {
    offset++;
    if (_seen.containsKey(c.clickId)) {
      duplicates++;
      return;
    }
    _seen[c.clickId] = c.eventTime;
    final start = c.eventTime - c.eventTime % windowSec;
    if (start + windowSec <= watermark) {
      late.add(c); // its window was already emitted
      return;
    }
    _open[(c.adId, start)] = (_open[(c.adId, start)] ?? 0) + 1;
    if (c.eventTime > maxEventTime) {
      maxEventTime = c.eventTime;
      _emitClosedWindows();
      _seen.removeWhere((_, t) => t < watermark - dedupTtlSec);
    }
  }

  void _emitClosedWindows({bool all = false}) {
    final closed = _open.keys.where((k) => all || k.$2 + windowSec <= watermark).toList()
      ..sort((a, b) => a.$2 != b.$2 ? a.$2.compareTo(b.$2) : a.$1.compareTo(b.$1));
    for (final k in closed) {
      sink.upsert(k.$1, k.$2, _open.remove(k)!);
    }
  }

  /// End of input (or a final flush in tests).
  void flush() => _emitClosedWindows(all: true);

  Checkpoint snapshot() => Checkpoint(offset, maxEventTime, Map.of(_open), Map.of(_seen));

  static ClickAggregator restore(Checkpoint cp, ResultSink sink) => ClickAggregator(sink)
    ..offset = cp.offset
    ..maxEventTime = cp.maxEventTime
    .._open = Map.of(cp.open)
    .._seen = Map.of(cp.seen);
}

// ---------- Self-checks ----------

void check(Object? actual, Object? expected) {
  if ('$actual' != '$expected') throw StateError('expected $expected, got $actual');
  print('ok: $actual');
}

void main() {
  // A small, hand-checked stream.
  final sink = ResultSink();
  final agg = ClickAggregator(sink);
  for (final c in const [
    Click('c1', 'ad1', 5),
    Click('c2', 'ad1', 30),
    Click('c3', 'ad2', 50),
    Click('c4', 'ad1', 65),
    Click('c1', 'ad1', 5), // duplicate delivery
    Click('c5', 'ad1', 10), // out of order but within the allowed lateness
    Click('c6', 'ad3', 250), // watermark -> 130: windows [0,60) and [60,120) close
    Click('c7', 'ad1', 20), // window [0,60) already emitted: late
  ]) {
    agg.process(c);
  }
  check(agg.watermark, 130);
  check(sink.rows, {('ad1', 0): 3, ('ad2', 0): 1, ('ad1', 60): 1});
  check([agg.duplicates, agg.late.map((c) => c.clickId)], [1, '(c7)']);
  agg.flush();
  check(sink.rows[('ad3', 240)], 1);
  check(sink.topN(0, 2), '[(ad1, 3), (ad2, 1)]');

  // Exactly-once results across a crash: checkpoint, keep going, crash, restore, replay.
  final rng = Random(3);
  final events = <Click>[];
  for (var i = 0; i < 3000; i++) {
    final t = i ~/ 5 + rng.nextInt(90) - 45; // roughly increasing, up to 45 s out of order
    events.add(Click('k$i', 'ad${rng.nextInt(30)}', max(0, t)));
    if (rng.nextInt(20) == 0) events.add(Click('k$i', 'ad0', 0)); // duplicate of k$i (same ID)
  }

  final cleanSink = ResultSink();
  final clean = ClickAggregator(cleanSink);
  events.forEach(clean.process);
  clean.flush();

  final crashSink = ResultSink();
  var worker = ClickAggregator(crashSink);
  for (var i = 0; i < 1200; i++) {
    worker.process(events[i]);
  }
  final cp = worker.snapshot(); // committed together with offset 1200
  for (var i = 1200; i < 2100; i++) {
    worker.process(events[i]); // results emitted to the sink, then the worker dies
  }
  final writesBeforeCrash = crashSink.writes;
  worker = ClickAggregator.restore(cp, crashSink);
  for (var i = worker.offset; i < events.length; i++) {
    worker.process(events[i]); // replay from the checkpointed offset
  }
  worker.flush();

  check(
    crashSink.rows.length == cleanSink.rows.length &&
        crashSink.rows.entries.every((e) => cleanSink.rows[e.key] == e.value),
    true,
  );
  check(crashSink.writes > cleanSink.writes, true); // some windows were written twice, harmlessly
  check(writesBeforeCrash > 0, true);
  final counted = cleanSink.rows.values.fold(0, (a, b) => a + b) + clean.late.length;
  check(counted + clean.duplicates, events.length); // every event is counted, late, or a duplicate
}
```

## 5. Walkthrough

- `c1`, `c2`, `c5` fall in ad1's window `[0, 60)`; `c5` arrives after `c4` (time 65) but the watermark is still negative, so it counts.
- The duplicate `c1` is detected by ID.
- `c6` at time 250 moves the watermark to 130; windows ending at or before 130 are emitted: ad1@0 = 3, ad2@0 = 1, ad1@60 = 1.
- `c7` (time 20) arrives after its window was emitted: it goes to the late output.
- The randomized run: 3,000 clicks with up to 45 s of disorder and about 5% duplicates. The crashed run restores the state from offset 1,200, replays everything after it, and ends with exactly the same rows as the clean run. It wrote more times (re-emitted windows), which the upserting sink absorbs. Every event is accounted for as counted, late, or duplicate.

## 6. Concurrency

- Partition the stream by `adId`; each partition has one aggregator instance, so state is never shared. Watermarks are per partition; a downstream operator merging partitions uses the minimum watermark.
- Checkpoints are taken at consistent cut points (barrier markers flow through the stream in Flink), so the snapshot and the offsets match exactly.
- The sink must tolerate concurrent upserts for different keys; same-key writes carry the same value after replay.

## 7. Extensibility

| Change | Where |
|---|---|
| Correct late events | Emit an updated count for the late event's window (the sink upserts). |
| Country dimension | Key windows by `(adId, country, start)`. |
| Sliding windows | Assign each event to every window covering it. |
| Hot ads | Pre-aggregate with `adId#k` sub-keys, then combine. |
| Two-phase commit sink | Transactional writes committed when the checkpoint completes. |

## 8. Common mistakes in LLD rounds

- Using arrival time for windows.
- Emitting windows on a timer instead of the watermark (missing out-of-order events).
- Unbounded dedup state.
- An appending (non-idempotent) sink combined with replay (double counting).

See [HLD.md](HLD.md) for the pipeline, top-N at scale and reconciliation.
