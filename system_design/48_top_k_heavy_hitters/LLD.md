# Top-K Heavy Hitters: Low-Level Design

## 1. Scope for the LLD round

- **Count-Min Sketch** sized from an error bound ε and failure probability δ (`width = ⌈e/ε⌉`, `depth = ⌈ln(1/δ)⌉`); `add`, `estimate` (minimum over rows, never below the true count), and `merge`.
- **CMS + candidate set** for top-k: keep the k items with the highest estimates seen so far.
- **Space-Saving** with m counters: deterministic guarantees (`count - error ≤ true ≤ count`; every item above N/m is tracked).
- **Windowed top-k:** one sketch and candidate set per minute in a ring; "last W minutes" merges buckets.
- Validation against exact counts on Zipf-distributed (heavily skewed) data.

Out of scope: distribution across workers, persistence (HLD).

## 2. Entities and responsibilities

| Class | Responsibility |
|---|---|
| `CountMinSketch` | Fixed-size counter table with d hash rows. |
| `CmsTopK` | Sketch + bounded candidate map of current leaders. |
| `SpaceSaving` | m (count, error) counters with min-eviction. |
| `WindowedTopK` | Per-minute buckets; merged queries over recent minutes. |
| `ZipfSampler` | Skewed test data. |

```text
event --> CountMinSketch.add (d counters incremented) --> estimate = min of d counters --> candidate map (size k)
event --> SpaceSaving: tracked? count++ : (free slot ? (1, 0) : replace min (c) with (c + 1, error c))
minute buckets [CMS + candidates] x 60 --> top over last W = merge sketches, re-estimate the union of candidates
```

## 3. Design decisions and why

- **Count-Min Sketch:** memory independent of the number of distinct items; collisions only add, so estimates never undercount; the error bound is εN with probability 1 - δ.
- **Candidates alongside the sketch:** a sketch can estimate any item but cannot list items; the candidate map remembers who might be on top.
- **Space-Saving:** simplest structure with deterministic guarantees, and the recorded `error` tells how uncertain each count is.
- **Mergeable buckets:** sketches with the same dimensions and hash seeds merge by adding counters, which makes sliding windows (and distributed aggregation) cheap.

## 4. The code

```dart
import 'dart:math';

int _hash(String s, int seed) {
  var h = 0x811C9DC5 ^ (seed * 0x9E3779B1);
  for (final c in s.codeUnits) {
    h = ((h ^ c) * 0x01000193) & 0xFFFFFFFF;
  }
  h ^= h >> 16;
  h = (h * 0x85EBCA6B) & 0xFFFFFFFF;
  return h ^ (h >> 13);
}

class CountMinSketch {
  CountMinSketch(this.width, this.depth) : _table = List.generate(depth, (_) => List.filled(width, 0));

  factory CountMinSketch.withError(double epsilon, double delta) =>
      CountMinSketch((e / epsilon).ceil(), log(1 / delta).ceil());

  final int width;
  final int depth;
  final List<List<int>> _table;
  var total = 0;

  void add(String item, [int n = 1]) {
    total += n;
    for (var row = 0; row < depth; row++) {
      _table[row][_hash(item, row) % width] += n;
    }
  }

  int estimate(String item) {
    var best = 1 << 62;
    for (var row = 0; row < depth; row++) {
      best = min(best, _table[row][_hash(item, row) % width]);
    }
    return best;
  }

  void merge(CountMinSketch other) {
    if (other.width != width || other.depth != depth) throw ArgumentError('sketch shapes differ');
    for (var r = 0; r < depth; r++) {
      for (var c = 0; c < width; c++) {
        _table[r][c] += other._table[r][c];
      }
    }
    total += other.total;
  }
}

class CmsTopK {
  CmsTopK(this.k, this.sketch);
  final int k;
  final CountMinSketch sketch;
  final candidates = <String, int>{};

  void add(String item) {
    sketch.add(item);
    final est = sketch.estimate(item);
    if (candidates.containsKey(item) || candidates.length < k) {
      candidates[item] = est;
      return;
    }
    final weakest = candidates.entries.reduce((a, b) => a.value <= b.value ? a : b);
    if (est > weakest.value) {
      candidates
        ..remove(weakest.key)
        ..[item] = est;
    }
  }

  List<(String, int)> top() =>
      [for (final e in candidates.entries) (e.key, sketch.estimate(e.key))]
        ..sort((a, b) => a.$2 != b.$2 ? b.$2.compareTo(a.$2) : a.$1.compareTo(b.$1));
}

class SpaceSaving {
  SpaceSaving(this.m);
  final int m;
  final _counters = <String, (int, int)>{}; // item -> (count, error)

  void add(String item) {
    final c = _counters[item];
    if (c != null) {
      _counters[item] = (c.$1 + 1, c.$2);
    } else if (_counters.length < m) {
      _counters[item] = (1, 0);
    } else {
      final victim = _counters.entries.reduce((a, b) => a.value.$1 <= b.value.$1 ? a : b);
      _counters.remove(victim.key);
      _counters[item] = (victim.value.$1 + 1, victim.value.$1); // may have occurred up to `min` times before
    }
  }

  (int, int)? countOf(String item) => _counters[item];

  List<(String, int)> top(int k) => ([
    for (final e in _counters.entries) (e.key, e.value.$1),
  ]..sort((a, b) => a.$2 != b.$2 ? b.$2.compareTo(a.$2) : a.$1.compareTo(b.$1))).take(k).toList();
}

class WindowedTopK {
  WindowedTopK({required this.k, required this.width, required this.depth, this.minutes = 60});
  final int k, width, depth, minutes;
  final _buckets = <int, CmsTopK>{}; // minute -> bucket

  void add(String item, int minute) {
    _buckets.putIfAbsent(minute, () => CmsTopK(k, CountMinSketch(width, depth))).add(item);
    _buckets.removeWhere((m, _) => m <= minute - minutes); // ring: forget old minutes
  }

  List<(String, int)> top({required int now, required int lastMinutes}) {
    final merged = CountMinSketch(width, depth);
    final candidates = <String>{};
    for (final MapEntry(key: m, value: b) in _buckets.entries) {
      if (m > now - lastMinutes && m <= now) {
        merged.merge(b.sketch);
        candidates.addAll(b.candidates.keys);
      }
    }
    return ([
      for (final c in candidates) (c, merged.estimate(c)),
    ]..sort((a, b) => a.$2 != b.$2 ? b.$2.compareTo(a.$2) : a.$1.compareTo(b.$1))).take(k).toList();
  }
}

// ---------- Test data ----------

class ZipfSampler {
  ZipfSampler(int n, double s, this._rng) {
    var sum = 0.0;
    for (var i = 1; i <= n; i++) {
      sum += 1 / pow(i, s);
      _cdf.add(sum);
    }
    _total = sum;
  }
  final Random _rng;
  final _cdf = <double>[];
  late final double _total;

  String next() {
    final x = _rng.nextDouble() * _total;
    var lo = 0, hi = _cdf.length - 1;
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      if (_cdf[mid] < x) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    return 'item$lo';
  }
}

// ---------- Self-checks ----------

void check(Object? actual, Object? expected) {
  if ('$actual' != '$expected') throw StateError('expected $expected, got $actual');
  print('ok: $actual');
}

void main() {
  final sketch = CountMinSketch.withError(0.001, 0.01);
  check([sketch.width, sketch.depth], [2719, 5]);

  // 200,000 Zipf-distributed events over 20,000 items.
  final sampler = ZipfSampler(20000, 1.1, Random(42));
  final events = List.generate(200000, (_) => sampler.next());
  final exact = <String, int>{};
  for (final e in events) {
    exact[e] = (exact[e] ?? 0) + 1;
  }
  List<String> exactTop(int k) => ([
    for (final e in exact.entries) (e.key, e.value),
  ]..sort((a, b) => a.$2 != b.$2 ? b.$2.compareTo(a.$2) : a.$1.compareTo(b.$1))).take(k).map((x) => x.$1).toList();

  // Count-Min Sketch: never underestimates; the error bound holds for (almost) every item.
  final cmsTop = CmsTopK(10, sketch);
  events.forEach(cmsTop.add);
  final bound = 0.001 * events.length;
  check(exact.entries.every((e) => sketch.estimate(e.key) >= e.value), true);
  final withinBound = exact.entries.where((e) => sketch.estimate(e.key) - e.value <= bound).length / exact.length;
  check(withinBound >= 0.99, true);
  check(cmsTop.top().map((x) => x.$1).toSet().containsAll(exactTop(10)), true);

  // Space-Saving with 200 counters: exact top-10 found, and each counter brackets the truth.
  final ss = SpaceSaving(200);
  events.forEach(ss.add);
  check(ss.top(10).map((x) => x.$1).toList(), exactTop(10));
  for (final item in exactTop(50)) {
    final c = ss.countOf(item);
    if (c != null && (c.$1 - c.$2 > exact[item]! || exact[item]! > c.$1)) throw StateError('bound violated for $item');
  }
  final threshold = events.length ~/ 200;
  check(exact.entries.where((e) => e.value > threshold).every((e) => ss.countOf(e.key) != null), true);

  // Merging sketches equals sketching the union.
  final a = CountMinSketch(500, 4), b = CountMinSketch(500, 4), both = CountMinSketch(500, 4);
  for (var i = 0; i < events.length; i++) {
    (i.isEven ? a : b).add(events[i]);
    both.add(events[i]);
  }
  a.merge(b);
  check(exactTop(20).every((item) => a.estimate(item) == both.estimate(item)), true);

  // Sliding windows: a song that broke out in the last 5 minutes leads the 5-minute chart, not the hour.
  final charts = WindowedTopK(k: 3, width: 1000, depth: 4);
  for (var minute = 0; minute < 60; minute++) {
    for (var i = 0; i < 100; i++) {
      charts.add('evergreen', minute);
    }
    for (var i = 0; i < 40; i++) {
      charts.add('steady', minute);
    }
    if (minute >= 55) {
      for (var i = 0; i < 300; i++) {
        charts.add('breakout', minute);
      }
    }
  }
  check(charts.top(now: 59, lastMinutes: 5).first, (('breakout', 1500)));
  check(charts.top(now: 59, lastMinutes: 60).first.$1, 'evergreen');
}
```

## 5. Walkthrough

- ε = 0.001 and δ = 0.01 give a 2,719 x 5 table: 13,595 counters for 20,000 distinct items, and a fixed size whatever the number of items.
- On 200,000 Zipf events, every estimate is at least the true count, at least 99% of items are within 200 (0.1% of N) of the truth, and the sketch's candidate set contains the exact top 10.
- Space-Saving with 200 counters returns exactly the true top 10 in order; every tracked item's true count lies within `[count - error, count]`; every item with more than N/200 occurrences is tracked.
- Two half-stream sketches merged give the same estimates as one sketch over everything.
- In the chart, "breakout" gets 300 plays per minute only in the last 5 minutes: it leads the 5-minute window (1,500 plays), while "evergreen" (100 per minute for an hour) leads the 60-minute window.

## 6. Concurrency

- Per partition, one worker updates its sketch (no sharing). Partition by item ID so each item's counts are complete in one place.
- Snapshots of sketches are immutable copies merged by an aggregator; counters are only added, so merges are order-independent.
- With shared sketches across threads, counter increments can be atomic adds; the estimate is still an upper bound.

## 7. Extensibility

| Change | Where |
|---|---|
| Conservative update | Increment only rows equal to the current minimum (smaller overestimates). |
| Time decay | Multiply counters by a factor each minute instead of tumbling buckets. |
| Distinct users per item | A HyperLogLog per tracked candidate. |
| Trending score | Compare the window's estimate with the item's long-term baseline. |

## 8. Common mistakes in LLD rounds

- Using a sketch without a way to know which items to report (no candidates).
- Different hash seeds or widths across sketches that need merging.
- Forgetting that estimates only overestimate (useful for safe upper bounds).
- Space-Saving without the error term (counts look exact but are not).

See [HLD.md](HLD.md) for distributed aggregation and windowing at scale.
