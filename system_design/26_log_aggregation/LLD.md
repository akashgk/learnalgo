# Log Aggregation and Search: Low-Level Design

## 1. Scope for the LLD round

- **Parse** logfmt lines (`key=value`, `key="quoted value"`) into records with timestamp, service, level, message and extra fields.
- **Redact** personal data and secrets before storage: emails, card numbers, and sensitive field names (`password`, `token`, ...).
- **Store** records in **time-partitioned chunks** per service and hour; each chunk keeps a set of message tokens (a cheap "could this chunk match?" summary).
- **Query** by time range, service, level and a text term, newest first, with a limit; chunks that cannot match are skipped without scanning.
- **Retention** deletes whole chunks. **Per-service rate limits** drop excess non-error lines and count drops.
- **Log patterns:** collapse variable parts (numbers, IPs, IDs) into `<*>` and count templates.

Out of scope: agents, Kafka, compression, distribution (HLD).

## 2. Entities and responsibilities

| Class | Responsibility |
|---|---|
| `parseLogfmt` | Line -> key/value map. |
| `Redactor` | Masks emails, card numbers, sensitive fields. |
| `LogRecord` | Timestamp, service, level, message, fields. |
| `Chunk` | Records of one service in one time window, plus their token set. |
| `LogStore` | Ingest (parse, validate, redact, rate limit), chunks, query, retention, patterns. |
| `templateOf` | Message -> pattern with `<*>` placeholders. |

```text
raw line --parseLogfmt--> fields --Redactor--> LogRecord --rate limit--> LogStore.chunks[(service, hourStart)]
query(from, to, service, level, text) --> candidate chunks by key --> skip if text not in chunk.tokens --> scan --> newest first
```

## 3. Design decisions and why

- **Chunk key = (service, time window).** Both are in almost every query, so they prune most data before any scanning, and retention is a whole-chunk delete.
- **Label-style indexing, not a full inverted index:** only service and level are structured filters; text search scans chunks, but a per-chunk token set skips chunks that cannot contain the term (a Bloom filter in production).
- **Redact at ingest, before storage:** data that was never stored cannot leak from backups or search results.
- **Rate limiting per service per minute, never dropping errors:** a crash-looping service cannot drown the pipeline, and the lines that matter most survive. Drops are counted so the loss is visible.
- **Patterns by token masking:** a cheap version of log-clustering algorithms (Drain); good enough to see which message shapes spike.

## 4. The code

```dart
// ---------- Parsing and redaction ----------

final _pair = RegExp(r'(\w+)=("(?:[^"\\]|\\.)*"|\S+)');

Map<String, String> parseLogfmt(String line) => {
  for (final m in _pair.allMatches(line))
    m[1]!: m[2]!.startsWith('"') ? m[2]!.substring(1, m[2]!.length - 1).replaceAll(r'\"', '"') : m[2]!,
};

class Redactor {
  static final _email = RegExp(r'[\w.+-]+@[\w-]+\.[\w.]+');
  static final _card = RegExp(r'\b(?:\d[ -]?){13,16}\b');
  static const sensitiveFields = {'password', 'token', 'secret', 'authorization', 'api_key'};

  static String text(String s) => s.replaceAll(_email, '<email>').replaceAll(_card, '<card>');

  static Map<String, String> fields(Map<String, String> f) => {
    for (final e in f.entries) e.key: sensitiveFields.contains(e.key.toLowerCase()) ? '<redacted>' : text(e.value),
  };
}

// ---------- Records and chunks ----------

class LogRecord {
  LogRecord(this.t, this.service, this.level, this.message, this.fields);
  final int t;
  final String service;
  final String level;
  final String message;
  final Map<String, String> fields;
  @override
  String toString() => '$t $service $level $message';
}

List<String> tokens(String s) => s.toLowerCase().split(RegExp(r'[^a-z0-9]+')).where((t) => t.isNotEmpty).toList();

class Chunk {
  Chunk(this.service, this.start);
  final String service;
  final int start;
  final records = <LogRecord>[];
  final tokenSet = <String>{};
}

class LogStore {
  LogStore({this.chunkSec = 3600, this.retentionSec = 7 * 86400, this.maxPerMinutePerService = 1000});

  final int chunkSec;
  final int retentionSec;
  final int maxPerMinutePerService;
  final chunks = <(String, int), Chunk>{};
  final _minuteCounts = <(String, int), int>{};
  final dropped = <String, int>{};
  var rejectedMalformed = 0;
  var chunksScanned = 0;

  /// Returns true if the line was stored.
  bool ingest(String line) {
    final f = parseLogfmt(line);
    final t = int.tryParse(f.remove('ts') ?? '');
    final service = f.remove('service'), level = f.remove('level'), msg = f.remove('msg');
    if (t == null || service == null || level == null || msg == null) {
      rejectedMalformed++;
      return false;
    }
    final minute = (service, t ~/ 60);
    final count = (_minuteCounts[minute] ?? 0) + 1;
    _minuteCounts[minute] = count;
    if (count > maxPerMinutePerService && level != 'error') {
      dropped[service] = (dropped[service] ?? 0) + 1;
      return false;
    }
    final record = LogRecord(t, service, level, Redactor.text(msg), Redactor.fields(f));
    final chunk = chunks.putIfAbsent((service, t - t % chunkSec), () => Chunk(service, t - t % chunkSec));
    chunk.records.add(record);
    chunk.tokenSet.addAll(tokens(record.message));
    return true;
  }

  List<LogRecord> query({
    required int from,
    required int to,
    String? service,
    String? level,
    String? text,
    int limit = 100,
  }) {
    chunksScanned = 0;
    final term = text?.toLowerCase();
    final hits = <LogRecord>[];
    for (final c in chunks.values) {
      if (service != null && c.service != service) continue;
      if (c.start > to || c.start + chunkSec <= from) continue; // outside the time range
      if (term != null && !c.tokenSet.contains(term)) continue; // cannot match: skip without scanning
      chunksScanned++;
      hits.addAll(
        c.records.where(
          (r) =>
              r.t >= from &&
              r.t <= to &&
              (level == null || r.level == level) &&
              (term == null || tokens(r.message).contains(term)),
        ),
      );
    }
    hits.sort((a, b) => b.t.compareTo(a.t));
    return hits.take(limit).toList();
  }

  int applyRetention(int now) {
    final old = chunks.keys.where((k) => k.$2 + chunkSec <= now - retentionSec).toList();
    old.forEach(chunks.remove);
    return old.length;
  }

  List<(String, int)> patterns(String service) {
    final counts = <String, int>{};
    for (final c in chunks.values.where((c) => c.service == service)) {
      for (final r in c.records) {
        final p = templateOf(r.message);
        counts[p] = (counts[p] ?? 0) + 1;
      }
    }
    return [for (final e in counts.entries) (e.key, e.value)]
      ..sort((a, b) => a.$2 != b.$2 ? b.$2.compareTo(a.$2) : a.$1.compareTo(b.$1));
  }
}

/// Words containing digits (IDs, numbers, IPs, durations) become <*>.
String templateOf(String message) => message.split(' ').map((w) => RegExp(r'\d').hasMatch(w) ? '<*>' : w).join(' ');

// ---------- Self-checks ----------

void check(Object? actual, Object? expected) {
  if ('$actual' != '$expected') throw StateError('expected $expected, got $actual');
  print('ok: $actual');
}

void main() {
  // Parsing and redaction.
  const line =
      'ts=100 service=checkout level=error msg="payment failed for alice@example.com" '
      'card="4111 1111 1111 1111" token=abc123 order=42';
  final fields = parseLogfmt(line);
  check(fields['msg'], 'payment failed for alice@example.com');
  check(Redactor.fields(fields), {
    'ts': '100',
    'service': 'checkout',
    'level': 'error',
    'msg': 'payment failed for <email>',
    'card': '<card>',
    'token': '<redacted>',
    'order': '42',
  });

  final store = LogStore(maxPerMinutePerService: 5, retentionSec: 86400);
  check(store.ingest(line), true);
  check(store.ingest('service=checkout msg="no timestamp"'), false);
  check(store.rejectedMalformed, 1);

  // Three hours of logs for two services.
  for (var h = 0; h < 3; h++) {
    final t = 3600 * h + 200;
    store
      ..ingest('ts=$t service=checkout level=info msg="order ${100 + h} placed"')
      ..ingest('ts=${t + 1} service=checkout level=error msg="db timeout after ${30 * (h + 1)}ms"')
      ..ingest('ts=${t + 2} service=search level=info msg="query took ${h + 5}ms"');
  }
  check(store.chunks.length, 6); // 2 services x 3 hours

  // Filters, newest first; a time range touches only its chunk; a text term skips chunks without it.
  check(store.query(from: 0, to: 99999, service: 'checkout', level: 'error', text: 'timeout'), [
    '7401 checkout error db timeout after 90ms',
    '3801 checkout error db timeout after 60ms',
    '201 checkout error db timeout after 30ms',
  ]);
  check(store.query(from: 3600, to: 7199, service: 'search'), ['3802 search info query took 6ms']);
  store.query(from: 0, to: 99999, text: 'timeout');
  check(store.chunksScanned, 3); // only checkout chunks contain "timeout"
  check(store.query(from: 0, to: 99999, text: 'payment').single.message, 'payment failed for <email>');

  // Rate limit: 5 lines per service per minute; errors always pass.
  var stored = 0;
  for (var i = 0; i < 10; i++) {
    if (store.ingest('ts=${20000 + i} service=noisy level=debug msg="retrying connection $i"')) stored++;
  }
  final errorKept = store.ingest('ts=20030 service=noisy level=error msg="giving up"');
  check([stored, store.dropped['noisy'], errorKept], [5, 5, true]);

  // Patterns.
  final p = LogStore();
  for (final m in ['user 17 logged in from 10.0.0.1', 'user 99 logged in from 10.0.0.7', 'payment 123 failed']) {
    p.ingest('ts=1 service=auth level=info msg="$m"');
  }
  check(p.patterns('auth'), '[(user <*> logged in from <*>, 2), (payment <*> failed, 1)]');

  // Retention removes whole chunks older than a day.
  check(store.applyRetention(3600 * 25), 2); // the hour-0 chunks of checkout and search
  check(store.query(from: 0, to: 3599).isEmpty, true);
}
```

## 5. Walkthrough

- The sample line parses into seven fields; redaction masks the email inside the message, the card number, and the `token` field by name.
- A line without `ts` is rejected and counted.
- Six chunks result from two services over three hours. The `timeout` query returns the three checkout errors newest first. A query for hour 1 of `search` touches only that chunk. A text search for `timeout` scans only the three checkout chunks: the search chunks' token sets do not contain the term.
- The noisy service sends 10 debug lines within one minute: 5 are stored and 5 dropped (and counted); the error line is kept despite the limit.
- Two login messages differing only in user ID and IP collapse into one pattern with count 2.
- With one day of retention at t = 25 h, the two chunks of hour 0 (the stored payment error is in checkout's hour-0 chunk) are deleted.

## 6. Concurrency

- Ingest workers own partitions (by service hash), so each chunk has one writer; appends need no locks across workers.
- Sealed chunks (window over) are immutable and can be compressed and uploaded; queries read sealed chunks without locks and the open chunk under a short lock (or a snapshot of its length).
- Rate-limit counters per service live with the worker owning that service's partition.

## 7. Extensibility

| Change | Where |
|---|---|
| JSON logs | Another parser producing the same field map. |
| Bloom filter per chunk | Replace `tokenSet` with a fixed-size filter (see 11). |
| Full-text index | Per-chunk inverted index (see 22) for faster text queries. |
| Live tail | A subscription list checked in `ingest`. |
| Logs to metrics | Count matches of a rule per minute and emit a series (see 25). |

## 8. Common mistakes in LLD rounds

- Redacting at query time (the secret is already stored).
- Indexing high-cardinality fields as labels.
- Retention by scanning and deleting individual lines.
- Rate limits that also drop errors.
- Queries without a time range scanning everything.

See [HLD.md](HLD.md) for the pipeline, storage tiers and indexing trade-offs.
