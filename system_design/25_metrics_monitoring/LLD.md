# Metrics Monitoring and Alerting: Low-Level Design

## 1. Scope for the LLD round

- **Series identity**: metric name + label set, independent of label order.
- **In-memory TSDB**: append samples (rejecting out-of-order ones), an **inverted index** from `label=value` to series, **label matchers** (`=`, `!=`, `=~` regex).
- **Cardinality limit** per metric.
- **Query functions**: `rate` over a window with **counter-reset** handling, `sum by (label)`, latest value.
- **Downsampling** (min, max, sum, count per step) and **retention**.
- **Alert rules** with a `for` duration and the state machine inactive -> pending -> firing -> resolved, notifying only on transitions.

Out of scope: compression, disk blocks, distribution, notification routing (HLD).

## 2. Entities and responsibilities

| Class | Responsibility |
|---|---|
| `seriesKey` | Canonical string for name + sorted labels. |
| `Sample`, `Series` | Timestamped values; one series per key. |
| `Matcher` | One label condition. |
| `Tsdb` | Storage, index, `append`, `select`, `applyRetention`, cardinality checks. |
| `rate`, `sumBy`, `downsample` | Query functions. |
| `AlertRule`, `AlertEvaluator` | Rule definition; per-series state; notifications on state changes. |

```text
Tsdb --has many--> Series (samples, append-only)        AlertEvaluator --has many--> AlertRule
  |  index: "label=value" -> {seriesKey}                       |   per (rule, series): state, since
  +-- select(name, matchers) --> rate / sumBy / downsample      +--> notifications: FIRING / RESOLVED
```

## 3. Design decisions and why

- **Canonical key with sorted labels**, so `{host=a, dc=x}` and `{dc=x, host=a}` are one series.
- **Inverted index on label pairs**, the same idea as a search engine: start from the metric name's posting set and filter by the other matchers.
- **Append-only with in-order timestamps:** this is what lets real TSDBs use delta-of-delta compression; late samples are rejected (or sent to a separate out-of-order buffer).
- **Rate computes increases pairwise** and treats a drop as a counter reset (the process restarted from 0), so a restart does not produce a large negative rate.
- **Downsampling keeps min, max, sum and count**, from which averages and extremes stay exact at the coarser resolution.
- **Alert state per series** with a start time for `pending`; notify only on transitions into `firing` and back, which deduplicates repeated evaluations.

## 4. The code

```dart
import 'dart:math';

String seriesKey(String name, Map<String, String> labels) {
  final keys = labels.keys.toList()..sort();
  return '$name{${keys.map((k) => '$k="${labels[k]}"').join(',')}}';
}

class Sample {
  const Sample(this.t, this.v);
  final int t; // seconds
  final double v;
}

class Series {
  Series(this.name, this.labels) : key = seriesKey(name, labels);
  final String name;
  final Map<String, String> labels;
  final String key;
  final samples = <Sample>[];
}

enum MatchType { equal, notEqual, regex }

class Matcher {
  Matcher(this.label, this.type, this.value);
  final String label;
  final MatchType type;
  final String value;

  bool matches(Map<String, String> labels) {
    final actual = labels[label] ?? '';
    return switch (type) {
      MatchType.equal => actual == value,
      MatchType.notEqual => actual != value,
      MatchType.regex => RegExp('^(?:$value)\$').hasMatch(actual),
    };
  }
}

class CardinalityLimitException implements Exception {}

class OutOfOrderSampleException implements Exception {}

class Tsdb {
  Tsdb({this.maxSeriesPerMetric = 10000, this.retentionSec = 15 * 86400});
  final int maxSeriesPerMetric;
  final int retentionSec;
  final series = <String, Series>{};
  final _index = <String, Set<String>>{}; // "label=value" (and "__name__=metric") -> series keys

  void append(String name, Map<String, String> labels, int t, double v) {
    final key = seriesKey(name, labels);
    var s = series[key];
    if (s == null) {
      if ((_index['__name__=$name']?.length ?? 0) >= maxSeriesPerMetric) throw CardinalityLimitException();
      s = series[key] = Series(name, Map.unmodifiable(labels));
      for (final pair in ['__name__=$name', for (final e in labels.entries) '${e.key}=${e.value}']) {
        _index.putIfAbsent(pair, () => {}).add(key);
      }
    }
    if (s.samples.isNotEmpty && t <= s.samples.last.t) throw OutOfOrderSampleException();
    s.samples.add(Sample(t, v));
  }

  List<Series> select(String name, [List<Matcher> matchers = const []]) {
    var keys = _index['__name__=$name'] ?? const <String>{};
    // Use the index for equality matchers, then filter the rest.
    for (final m in matchers.where((m) => m.type == MatchType.equal)) {
      keys = keys.intersection(_index['${m.label}=${m.value}'] ?? const <String>{});
    }
    return [
      for (final k in keys.toList()..sort())
        if (matchers.every((m) => m.matches(series[k]!.labels))) series[k]!,
    ];
  }

  void applyRetention(int now) {
    final cutoff = now - retentionSec;
    for (final s in series.values) {
      s.samples.removeWhere((x) => x.t < cutoff);
    }
    final empty = series.values.where((s) => s.samples.isEmpty).toList();
    for (final s in empty) {
      series.remove(s.key);
      for (final set in _index.values) {
        set.remove(s.key);
      }
    }
  }
}

// ---------- Query functions ----------

/// Per-second increase of a counter over [from, to]; a decrease means the counter was reset to 0.
double? rate(Series s, int from, int to) {
  final w = s.samples.where((x) => x.t >= from && x.t <= to).toList();
  if (w.length < 2) return null;
  var increase = 0.0;
  for (var i = 1; i < w.length; i++) {
    final d = w[i].v - w[i - 1].v;
    increase += d >= 0 ? d : w[i].v; // reset: count from 0
  }
  return increase / (w.last.t - w.first.t);
}

double? latest(Series s, int at) {
  double? v;
  for (final x in s.samples) {
    if (x.t > at) break;
    v = x.v;
  }
  return v;
}

Map<String, double> sumBy(String label, Map<Series, double?> values) {
  final out = <String, double>{};
  values.forEach((s, v) {
    if (v != null) out[s.labels[label] ?? ''] = (out[s.labels[label] ?? ''] ?? 0) + v;
  });
  return out;
}

class Bucket {
  Bucket(this.start);
  final int start;
  double minV = double.infinity, maxV = double.negativeInfinity, sum = 0;
  int count = 0;
  double get avg => sum / count;
  @override
  String toString() => '$start:min=$minV,max=$maxV,avg=$avg,n=$count';
}

List<Bucket> downsample(Series s, int stepSec) {
  final buckets = <int, Bucket>{};
  for (final x in s.samples) {
    final b = buckets.putIfAbsent(x.t - x.t % stepSec, () => Bucket(x.t - x.t % stepSec));
    b
      ..minV = min(b.minV, x.v)
      ..maxV = max(b.maxV, x.v)
      ..sum += x.v
      ..count += 1;
  }
  return buckets.values.toList()..sort((a, b) => a.start.compareTo(b.start));
}

// ---------- Alerting ----------

enum AlertState { inactive, pending, firing }

class AlertRule {
  AlertRule({required this.name, required this.metric, required this.threshold, required this.forSec});
  final String name;
  final String metric;
  final double threshold;
  final int forSec;
}

class AlertEvaluator {
  AlertEvaluator(this.db, this.rules);
  final Tsdb db;
  final List<AlertRule> rules;
  final _state = <String, (AlertState, int)>{}; // "rule|series" -> (state, since)
  final notifications = <String>[];

  AlertState stateOf(AlertRule r, Series s) => _state['${r.name}|${s.key}']?.$1 ?? AlertState.inactive;

  void evaluate(int now) {
    for (final rule in rules) {
      for (final s in db.select(rule.metric)) {
        final id = '${rule.name}|${s.key}';
        final (state, since) = _state[id] ?? (AlertState.inactive, now);
        final v = latest(s, now);
        final breaching = v != null && v > rule.threshold;
        if (!breaching) {
          if (state == AlertState.firing) notifications.add('RESOLVED ${rule.name} ${s.labels} at $now');
          _state.remove(id);
        } else if (state == AlertState.inactive) {
          _state[id] = (AlertState.pending, now);
        } else if (state == AlertState.pending && now - since >= rule.forSec) {
          _state[id] = (AlertState.firing, since);
          notifications.add('FIRING ${rule.name} ${s.labels} at $now');
        }
      }
    }
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
  final db = Tsdb(maxSeriesPerMetric: 5);

  // Series identity ignores label order; samples must be in time order.
  db
    ..append('cpu', {'host': 'a', 'dc': 'x'}, 0, 10)
    ..append('cpu', {'dc': 'x', 'host': 'a'}, 10, 20);
  check([db.series.length, db.series.keys.first], [1, 'cpu{dc="x",host="a"}']);
  expectThrows<OutOfOrderSampleException>(() => db.append('cpu', {'host': 'a', 'dc': 'x'}, 5, 1));

  // Counters: rate per series with a reset, then sum by service.
  const req = 'http_requests_total';
  final points = {
    ('checkout', '200'): [0.0, 100, 200, 10, 110], // the process restarted between t=20 and t=30
    ('checkout', '500'): [0.0, 5, 10, 15, 20],
    ('search', '200'): [0.0, 40, 80, 120, 160],
  };
  points.forEach((k, values) {
    for (var i = 0; i < values.length; i++) {
      db.append(req, {'service': k.$1, 'status': k.$2}, i * 10, values[i].toDouble());
    }
  });
  final checkout200 = db.select(req, [
    Matcher('service', MatchType.equal, 'checkout'),
    Matcher('status', MatchType.equal, '200'),
  ]).single;
  check(rate(checkout200, 0, 40), 7.75); // (100 + 100 + 10 + 100) / 40
  check(db.select(req, [Matcher('status', MatchType.regex, '5..')]).map((s) => s.labels['service']), '(checkout)');
  check(db.select(req, [Matcher('service', MatchType.notEqual, 'checkout')]).length, 1);
  final rates = {for (final s in db.select(req)) s: rate(s, 0, 40)};
  check(sumBy('service', rates), {'checkout': 8.25, 'search': 4.0});

  // Cardinality: the 6th distinct series of one metric is refused.
  for (var i = 0; i < 4; i++) {
    db.append('latency', {'route': '/r$i'}, 0, 1);
  }
  db.append('latency', {'route': '/r4'}, 0, 1);
  expectThrows<CardinalityLimitException>(() => db.append('latency', {'route': '/r5'}, 0, 1));
  db.append('latency', {'route': '/r4'}, 10, 2); // existing series still accept samples

  // Downsampling 10 s samples into 60 s buckets.
  final temp = Tsdb();
  for (var t = 0; t < 120; t += 10) {
    temp.append('temp', {'room': 'lab'}, t, t < 60 ? 20.0 + t / 10 : 30.0);
  }
  check(
    downsample(temp.select('temp').single, 60),
    '[0:min=20.0,max=25.0,avg=22.5,n=6, 60:min=30.0,max=30.0,avg=30.0,n=6]',
  );

  // Retention drops old samples and empty series.
  final short = Tsdb(retentionSec: 100)
    ..append('old', {}, 0, 1)
    ..append('mixed', {}, 0, 1)
    ..append('mixed', {}, 150, 2);
  short.applyRetention(200);
  check([short.series.keys.toList(), short.select('mixed').single.samples.length], ['[mixed{}]', 1]);

  // Alerts: CPU > 80 for 120 s. Host a stays high and fires once; host b spikes briefly and never fires.
  final mon = Tsdb();
  final cpu = {
    'a': {0: 50.0, 30: 90.0, 60: 95.0, 90: 85.0, 120: 88.0, 150: 90.0, 180: 70.0, 210: 60.0},
    'b': {0: 50.0, 30: 50.0, 60: 90.0, 90: 50.0, 120: 50.0, 150: 50.0, 180: 50.0, 210: 50.0},
  };
  cpu.forEach((host, values) => values.forEach((t, v) => mon.append('cpu', {'host': host}, t, v)));
  final rule = AlertRule(name: 'HighCpu', metric: 'cpu', threshold: 80, forSec: 120);
  final evaluator = AlertEvaluator(mon, [rule]);
  final hostA = mon.select('cpu', [Matcher('host', MatchType.equal, 'a')]).single;
  final timeline = <String>[];
  for (var t = 0; t <= 210; t += 30) {
    evaluator.evaluate(t);
    timeline.add(evaluator.stateOf(rule, hostA).name);
  }
  check(timeline, '[inactive, pending, pending, pending, pending, firing, inactive, inactive]');
  check(evaluator.notifications, ['FIRING HighCpu {host: a} at 150', 'RESOLVED HighCpu {host: a} at 180']);
}
```

## 5. Walkthrough

- Both label orders produce `cpu{dc="x",host="a"}`. A sample at t = 5 after t = 10 is rejected.
- The checkout/200 counter drops from 200 to 10 at t = 30 (a restart). Rate counts the 10 as an increase from 0: (100 + 100 + 10 + 100) / 40 s = 7.75/s. Adding checkout/500 (20/40 = 0.5/s) gives 8.25/s for checkout; search is 160/40 = 4/s.
- The regex matcher `status=~"5.."` is anchored, as in PromQL, so it matches `500` only.
- With a limit of 5 series per metric, the sixth `route` value is refused, while existing series keep accepting samples.
- Downsampling: the first minute (20 to 25) has min 20, max 25, average 22.5 over 6 samples.
- Retention at t = 200 with 100 s keeps only samples from t = 100 on: `old` disappears; `mixed` keeps one sample.
- Host a breaches at t = 30 (pending); at t = 150, 120 s have passed, so it fires once; at t = 180 it is resolved. Host b breaches only at t = 60, goes back to inactive at t = 90 and never notifies: the `for` duration absorbed the spike.

## 6. Concurrency

- Ingestion: series are independent; shard the head block by series hash, one writer per shard (lock-free appends).
- Queries read immutable chunks plus the current head chunk under a short read lock (or copy-on-write of the head).
- Alert evaluation runs on a schedule in one process per rule group; the state map is local to it. Redundant evaluators send duplicates that Alertmanager deduplicates by alert identity.

## 7. Extensibility

| Change | Where |
|---|---|
| Compression | Encode samples per chunk with delta-of-delta timestamps and XOR values. |
| Percentiles | Histogram bucket series and a `histogramQuantile` function. |
| Alert grouping and routing | A notifier that batches by labels (team, severity) and applies silences. |
| Recording rules | Precompute expensive queries into new series every interval. |
| Out-of-order ingestion | A small per-series buffer merged on flush. |

## 8. Common mistakes in LLD rounds

- Treating counters as gauges (negative rates after restarts).
- Label sets as unordered maps used directly as keys.
- Notifying on every evaluation while firing (alert spam).
- No cardinality protection.
- Unanchored regex matchers.

See [HLD.md](HLD.md) for collection, storage tiers, compaction and the alerting pipeline.
