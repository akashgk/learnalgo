# Web Crawler: Low-Level Design

## 1. Scope for the LLD round

- **URL normalization** so one page has one key (case, default ports, fragments, dot segments, tracking parameters).
- A **Bloom filter** for "have we seen this URL?", sized from the expected count and false-positive rate.
- A **polite frontier**: one FIFO queue per host and a schedule of when each host may be fetched next. Never two requests to one host closer than its delay.
- **robots.txt**: `Disallow` prefixes and `Crawl-delay` for `User-agent: *`.
- **Content deduplication** by hash: a page whose content was already stored is counted as a duplicate, and its links are not followed.
- **Depth limit** (defends against infinite link chains such as calendars) and a page budget.

Out of scope: real HTTP, DNS, distribution across machines, near-duplicate detection (HLD).

## 2. Entities and responsibilities

| Class | Responsibility |
|---|---|
| `normalizeUrl` | Canonical absolute URL, or `null` for unsupported links (mailto, javascript, malformed). |
| `BloomFilter` | Probabilistic set: no false negatives, tunable false positives, ~10 bits per item. |
| `RobotsRules` | Parsed `Disallow` prefixes and crawl delay; `allows(path)`. |
| `PoliteFrontier` | Per-host queues, per-host next-allowed time, an ordered set of ready times. |
| `Web` (interface) | `fetch(url)` returns a `Page` or `null`. A fake in tests, HTTP in production. |
| `Crawler` | The loop: pop, fetch, dedup, store, extract, normalize, filter, enqueue. |

```text
Crawler --uses--> PoliteFrontier (host -> Queue<url>, SplayTreeSet<(readyAt, host)>)
        --uses--> BloomFilter (URLs seen)       --uses--> Set<int> (content hashes)
        --uses--> RobotsRules per host          --uses--> Web (interface), Clock
```

## 3. Design decisions and why

- **Queue per host + schedule of hosts** (the back-queue half of the Mercator frontier). Popping always gives a URL whose host is allowed now, so politeness is structural, not a check that can be forgotten. A global FIFO would hit one host repeatedly.
- **Mark URLs seen when enqueued**, not when fetched, so the same URL found on two pages is queued once.
- **Bloom filter instead of a hash set** to show the memory trade-off; the false-positive rate is a parameter. At this test's size a `Set<String>` would be fine; at 10 B URLs it would not.
- **Content hash checked before extracting links:** duplicates (mirrors, URL variants) do not multiply the crawl.
- **Robots fetched once per host** when the host is first seen and cached; crawl delay overrides the default.
- **The clock jumps to the next ready time** when nothing is ready, so tests are instant and deterministic, and the fetch log proves politeness.

## 4. The code

```dart
import 'dart:collection';
import 'dart:math';
import 'dart:typed_data';

// ---------- URLs ----------

/// Canonical absolute http(s) URL, or null if the link is not crawlable.
String? normalizeUrl(String raw, {String? base}) {
  Uri u;
  try {
    u = base == null ? Uri.parse(raw.trim()) : Uri.parse(base).resolve(raw.trim());
  } on FormatException {
    return null;
  }
  final scheme = u.scheme.toLowerCase();
  if ((scheme != 'http' && scheme != 'https') || u.host.isEmpty) return null;
  u = u.normalizePath(); // resolves "." and ".."
  final defaultPort = scheme == 'http' ? 80 : 443;
  final port = u.hasPort && u.port != defaultPort ? ':${u.port}' : '';
  final path = u.path.isEmpty ? '/' : u.path;
  final params = [
    for (final e in u.queryParametersAll.entries)
      if (!e.key.startsWith('utm_'))
        for (final v in e.value) '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(v)}',
  ]..sort();
  return '$scheme://${u.host.toLowerCase()}$port$path${params.isEmpty ? '' : '?${params.join('&')}'}';
}

String hostOf(String url) => Uri.parse(url).host;

int fnv1a(String s, [int seed = 0x811C9DC5]) {
  var h = seed;
  for (final c in s.codeUnits) {
    h = ((h ^ c) * 0x01000193) & 0xFFFFFFFF;
  }
  return h;
}

// ---------- Bloom filter ----------

class BloomFilter {
  BloomFilter({required int expectedItems, required double falsePositiveRate})
    : bitCount = (-expectedItems * log(falsePositiveRate) / (ln2 * ln2)).ceil(),
      hashCount = max(1, (-log(falsePositiveRate) / ln2).round()) {
    _words = Uint32List((bitCount + 31) >> 5);
  }

  final int bitCount;
  final int hashCount;
  late final Uint32List _words;

  /// Double hashing: index_i = h1 + i * h2 (Kirsch and Mitzenmacher).
  Iterable<int> _indexes(String s) sync* {
    final h1 = fnv1a(s), h2 = fnv1a(s, 0x9747B28C) | 1;
    for (var i = 0; i < hashCount; i++) {
      yield (h1 + i * h2) % bitCount;
    }
  }

  void add(String s) {
    for (final i in _indexes(s)) {
      _words[i >> 5] |= 1 << (i & 31);
    }
  }

  bool mightContain(String s) => _indexes(s).every((i) => _words[i >> 5] & (1 << (i & 31)) != 0);
}

// ---------- robots.txt ----------

class RobotsRules {
  RobotsRules(this.disallow, this.crawlDelayMs);
  final List<String> disallow;
  final int? crawlDelayMs;

  static final allowAll = RobotsRules(const [], null);

  /// Minimal parser: only the `User-agent: *` group, `Disallow` prefixes and `Crawl-delay` seconds.
  factory RobotsRules.parse(String text) {
    final disallow = <String>[];
    int? delay;
    var inStarGroup = false;
    for (final line in text.split('\n')) {
      final i = line.indexOf(':');
      if (i < 0) continue;
      final key = line.substring(0, i).trim().toLowerCase(), value = line.substring(i + 1).trim();
      if (key == 'user-agent') inStarGroup = value == '*';
      if (!inStarGroup) continue;
      if (key == 'disallow' && value.isNotEmpty) disallow.add(value);
      if (key == 'crawl-delay') delay = ((double.tryParse(value) ?? 0) * 1000).round();
    }
    return RobotsRules(disallow, delay);
  }

  bool allows(String path) => !disallow.any(path.startsWith);
}

// ---------- Frontier ----------

class PoliteFrontier {
  final _queues = <String, Queue<(String, int)>>{}; // host -> (url, depth)
  final _nextAllowed = <String, int>{};
  final _schedule = SplayTreeSet<(int, String)>((a, b) => a.$1 != b.$1 ? a.$1.compareTo(b.$1) : a.$2.compareTo(b.$2));

  bool get isEmpty => _queues.isEmpty;
  int? get nextReadyAt => _schedule.isEmpty ? null : _schedule.first.$1;

  void add(String url, int depth) {
    final host = hostOf(url);
    final queue = _queues[host];
    if (queue != null) {
      queue.add((url, depth));
      return;
    }
    _queues[host] = Queue()..add((url, depth));
    _schedule.add((_nextAllowed[host] ?? 0, host)); // a host keeps its politeness gap even after its queue drained
  }

  /// A URL whose host may be fetched at [now], or null. [delayOf] gives the gap before that host's next fetch.
  (String, int)? pop(int now, int Function(String host) delayOf) {
    if (_schedule.isEmpty || _schedule.first.$1 > now) return null;
    final (_, host) = _schedule.first;
    _schedule.remove(_schedule.first);
    final queue = _queues[host]!;
    final item = queue.removeFirst();
    _nextAllowed[host] = now + delayOf(host);
    if (queue.isEmpty) {
      _queues.remove(host);
    } else {
      _schedule.add((_nextAllowed[host]!, host));
    }
    return item;
  }
}

// ---------- Crawler ----------

class Page {
  const Page(this.body, [this.links = const []]);
  final String body;
  final List<String> links;
}

abstract interface class Web {
  Page? fetch(String url);
}

class FakeClock {
  int nowMs = 0;
}

class Crawler {
  Crawler({
    required this.web,
    required this.clock,
    this.maxPages = 1000,
    this.maxDepth = 5,
    this.defaultDelayMs = 1000,
    int expectedUrls = 100000,
  }) : _seen = BloomFilter(expectedItems: expectedUrls, falsePositiveRate: 0.001);

  final Web web;
  final FakeClock clock;
  final int maxPages;
  final int maxDepth;
  final int defaultDelayMs;
  final BloomFilter _seen;
  final _frontier = PoliteFrontier();
  final _contentHashes = <int>{};
  final _robots = <String, RobotsRules>{};

  final fetchLog = <(int, String)>[];
  final stored = <String>[];
  final duplicates = <String>[];
  final failed = <String>[];
  final blocked = <String>[];

  void seed(String url) {
    final n = normalizeUrl(url);
    if (n != null && !_seen.mightContain(n)) _enqueue(n, 0);
  }

  int _delayOf(String host) => _robots[host]?.crawlDelayMs ?? defaultDelayMs;

  void _enqueue(String url, int depth) {
    _seen.add(url);
    final uri = Uri.parse(url);
    final rules = _robots.putIfAbsent(uri.host, () {
      final page = web.fetch('${uri.scheme}://${uri.host}/robots.txt');
      return page == null ? RobotsRules.allowAll : RobotsRules.parse(page.body);
    });
    if (!rules.allows(uri.path)) {
      blocked.add(url);
      return;
    }
    _frontier.add(url, depth);
  }

  void run() {
    while (stored.length + duplicates.length < maxPages) {
      final next = _frontier.pop(clock.nowMs, _delayOf);
      if (next == null) {
        final t = _frontier.nextReadyAt;
        if (t == null) break; // nothing left
        clock.nowMs = t; // wait for the earliest host
        continue;
      }
      _process(next.$1, next.$2);
    }
  }

  void _process(String url, int depth) {
    fetchLog.add((clock.nowMs, url));
    final page = web.fetch(url);
    if (page == null) {
      failed.add(url);
      return;
    }
    if (!_contentHashes.add(fnv1a(page.body))) {
      duplicates.add(url); // same content already stored: do not follow its links
      return;
    }
    stored.add(url);
    if (depth >= maxDepth) return;
    for (final link in page.links) {
      final n = normalizeUrl(link, base: url);
      if (n == null || _seen.mightContain(n)) continue;
      _enqueue(n, depth + 1);
    }
  }
}

// ---------- Test web ----------

class FakeWeb implements Web {
  FakeWeb(this.pages);
  final Map<String, Page> pages;

  @override
  Page? fetch(String url) {
    final cal = RegExp(r'^http://a\.com/cal/(\d+)$').firstMatch(url);
    if (cal != null) {
      final n = int.parse(cal[1]!); // an infinite chain of distinct pages: a crawler trap
      return Page('calendar page $n', ['/cal/${n + 1}']);
    }
    return pages[url];
  }
}

// ---------- Self-checks ----------

void check(Object? actual, Object? expected) {
  if ('$actual' != '$expected') throw StateError('expected $expected, got $actual');
  print('ok: $actual');
}

void main() {
  // Normalization.
  check(normalizeUrl('HTTP://Example.COM:80/a/./b/../c?b=2&a=1&utm_source=x#top'), 'http://example.com/a/c?a=1&b=2');
  check(normalizeUrl('https://example.com:8443'), 'https://example.com:8443/');
  check(normalizeUrl('../img?x=1', base: 'http://a.com/docs/page'), 'http://a.com/img?x=1');
  check([normalizeUrl('mailto:me@a.com'), normalizeUrl('javascript:void(0)')], [null, null]);

  // Bloom filter: sizing, no false negatives, false positives near the target.
  final bloom = BloomFilter(expectedItems: 1000, falsePositiveRate: 0.01);
  check([bloom.bitCount, bloom.hashCount], [9586, 7]);
  for (var i = 0; i < 1000; i++) {
    bloom.add('http://site.com/page/$i');
  }
  check(List.generate(1000, (i) => bloom.mightContain('http://site.com/page/$i')).every((b) => b), true);
  final falsePositives = List.generate(20000, (i) => bloom.mightContain('http://other.com/$i')).where((b) => b).length;
  check(falsePositives / 20000 < 0.02, true);

  // robots.txt parsing.
  final rules = RobotsRules.parse(
    'User-agent: googlebot\nDisallow: /\n\nUser-agent: *\nDisallow: /private\nCrawl-delay: 2',
  );
  check([rules.allows('/private/x'), rules.allows('/public'), rules.crawlDelayMs], [false, true, 2000]);

  // A small web with robots rules, duplicate content, a broken link and an infinite calendar.
  final web = FakeWeb({
    'http://a.com/robots.txt': const Page('User-agent: *\nDisallow: /private\nCrawl-delay: 2'),
    'http://a.com/': const Page('home', [
      '/about',
      'http://b.com/',
      '/private/x',
      '/about#team', // same page as /about
      'HTTP://A.COM/about?utm_source=mail', // same page as /about
      'mailto:hi@a.com',
      '/cal/1',
    ]),
    'http://a.com/about': const Page('about', ['/']),
    'http://b.com/': const Page('b home', ['/copy', '/missing']),
    'http://b.com/copy': const Page('home'), // identical content to http://a.com/
  });
  final clock = FakeClock();
  final crawler = Crawler(web: web, clock: clock, maxDepth: 3)..seed('http://a.com');
  crawler.run();

  check(crawler.stored, [
    'http://a.com/',
    'http://b.com/',
    'http://a.com/about',
    'http://a.com/cal/1',
    'http://a.com/cal/2',
    'http://a.com/cal/3',
  ]);
  check(crawler.duplicates, ['http://b.com/copy']);
  check(crawler.failed, ['http://b.com/missing']);
  check(crawler.blocked, ['http://a.com/private/x']);

  // Politeness: a.com (Crawl-delay 2 s) and b.com (default 1 s) never get requests closer than their delay.
  List<int> timesFor(String host) => [
    for (final (t, url) in crawler.fetchLog)
      if (hostOf(url) == host) t,
  ];
  check(timesFor('a.com'), [0, 2000, 4000, 6000, 8000]);
  check(timesFor('b.com'), [0, 1000, 2000]);

  // Page budget.
  final small = Crawler(web: web, clock: FakeClock(), maxPages: 2)..seed('http://a.com/');
  small.run();
  check(small.stored, ['http://a.com/', 'http://b.com/']);
}
```

## 5. Walkthrough

- The home page links to `/about` three ways (plain, with a fragment, uppercase host plus a tracking parameter). All three normalize to `http://a.com/about`, so it is queued once.
- `/private/x` is rejected by robots.txt at enqueue time; `mailto:` is not crawlable.
- `b.com` has no robots.txt, so it uses the 1 s default. At t = 0 both hosts are ready; `a.com` (fetched first) must wait 2 s, so `b.com/` runs at 0 and `b.com/copy` at 1000. That page's content equals `a.com/`'s, so it is a duplicate and its links are not followed.
- The calendar would never end; the depth limit (3) stops it after `/cal/3`.
- The fetch log shows a.com at 0, 2000, 4000, ... exactly its crawl delay apart.

## 6. Concurrency

- Many fetcher threads share the frontier: `pop` must be atomic (one lock, or partition hosts across threads so each host belongs to one thread, which also keeps politeness trivially correct).
- The Bloom filter's `add` is a set of bit ORs: safe with atomic word updates; a "check then add" race can enqueue a URL twice, which is harmless (a second fetch at worst; the content hash catches it).
- Network I/O dominates, so a few hundred concurrent fetches per machine with async I/O; the CPU work (parsing, hashing) runs in a worker pool.

## 7. Extensibility

| Change | Where |
|---|---|
| Priority (important pages first) | Front queues by priority feeding these per-host back queues (Mercator). |
| Adaptive politeness | `delayOf(host)` = k x last response time. |
| Near-duplicate detection | Replace the content hash with SimHash and a Hamming-distance check. |
| More content types (PDF) | A `ContentHandler` per MIME type for link extraction and storage. |
| Distribution | Route each URL to the node owning `hash(host)`; each node runs this crawler for its hosts. |

## 8. Common mistakes in LLD rounds

- One global queue with a `sleep` per request (slow and still not polite per host).
- Comparing raw URL strings (duplicates through case, fragments, parameters).
- Marking URLs seen only after fetching (the same URL gets queued many times).
- No defense against traps.
- A Bloom filter without stating its false-positive consequence (some URLs never crawled).

See [HLD.md](HLD.md) for distribution, DNS, storage and recrawl policy.
