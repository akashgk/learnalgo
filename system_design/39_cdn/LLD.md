# Content Delivery Network: Low-Level Design

## 1. Scope for the LLD round

- **Cache key normalization:** host + path + sorted query parameters without tracking parameters + a normalized `Accept-Encoding` (the `Vary` dimension).
- **Cache-Control parsing:** `no-store` and `private` are never cached; `s-maxage` beats `max-age`; `stale-while-revalidate`.
- **Cache node** (edge or shield) with a **byte-bounded LRU**, HIT / MISS / STALE results, and **request coalescing**: concurrent misses for one key share a single upstream fetch.
- **Stale-while-revalidate:** serve the stale copy immediately and refresh in the background.
- **Tiered caching:** edges use a shield node as their upstream; the shield uses the origin.
- **Purge** by key or by **tag** (surrogate keys).

Out of scope: TLS, anycast/DNS routing, disk tiers (HLD).

## 2. Entities and responsibilities

| Class | Responsibility |
|---|---|
| `cacheKey` | Canonical key from URL and request headers. |
| `parseCacheControl` | Store?, TTL, stale window. |
| `OriginResponse` | Status, body, headers. |
| `Upstream` (interface) | `fetch(key, url)`: implemented by the origin and by cache nodes. |
| `Origin` | Fake origin server with versioned content and a call counter. |
| `CacheNode` | LRU storage, freshness logic, coalescing, background refresh, purge. |

```text
user --> CacheNode(edge) --miss--> CacheNode(shield) --miss--> Origin
            |  inflight: key -> Future (one fetch per key at a time)
            |  entries: LinkedHashMap (LRU order), bounded by total bytes
            +- HIT (fresh) | STALE (serve, refresh in background) | MISS (fetch, then store if cacheable)
```

## 3. Design decisions and why

- **Normalize the key** so equivalent requests share an entry (parameter order, tracking parameters) while genuinely different responses (encodings) do not.
- **Cache nodes implement the same interface as the origin,** so tiers compose: an edge does not know whether its upstream is a shield or the origin.
- **Coalescing with a map of in-flight futures:** the first miss starts the fetch; later misses await the same future. The entry is removed when the fetch completes.
- **Stale-while-revalidate** trades a few seconds of staleness for no user ever waiting on an expired popular object.
- **LRU by bytes,** not entry count: one large video segment should count more than a small icon.
- **Tags on entries** so a single purge can drop every object related to a product.

## 4. The code

```dart
import 'dart:async';
import 'dart:collection';

// ---------- Keys and headers ----------

const trackingParams = {'utm_source', 'utm_medium', 'utm_campaign', 'fbclid', 'gclid'};

String cacheKey(String url, Map<String, String> requestHeaders) {
  final u = Uri.parse(url);
  final params = [
    for (final e in u.queryParametersAll.entries)
      if (!trackingParams.contains(e.key))
        for (final v in e.value) '${e.key}=$v',
  ]..sort();
  final ae = requestHeaders['accept-encoding'] ?? '';
  final encoding = ae.contains('br') ? 'br' : (ae.contains('gzip') ? 'gzip' : 'identity');
  return '${u.host}${u.path}${params.isEmpty ? '' : '?${params.join('&')}'}|$encoding';
}

({bool store, int maxAge, int swr}) parseCacheControl(String? header) {
  final d = <String, String>{};
  for (final part in (header ?? '').split(',')) {
    final kv = part.trim().split('=');
    if (kv.first.isNotEmpty) d[kv.first.toLowerCase()] = kv.length > 1 ? kv[1] : '';
  }
  final store = !d.containsKey('no-store') && !d.containsKey('private');
  final maxAge = int.tryParse(d['s-maxage'] ?? d['max-age'] ?? '0') ?? 0;
  return (store: store && maxAge > 0, maxAge: maxAge, swr: int.tryParse(d['stale-while-revalidate'] ?? '0') ?? 0);
}

// ---------- Origin and cache nodes ----------

class Clock {
  int nowSec = 0;
}

class OriginResponse {
  const OriginResponse(this.status, this.body, [this.headers = const {}]);
  final int status;
  final String body;
  final Map<String, String> headers;
}

abstract interface class Upstream {
  Future<OriginResponse> fetch(String key, String url);
}

class Origin implements Upstream {
  final content = <String, (String, String)>{}; // path -> (body, cache-control)
  final tags = <String, String>{};
  var calls = 0;

  @override
  Future<OriginResponse> fetch(String key, String url) async {
    calls++;
    await Future<void>.delayed(const Duration(milliseconds: 1)); // network latency
    final path = Uri.parse(url).path;
    final c = content[path];
    if (c == null) return const OriginResponse(404, 'not found');
    return OriginResponse(200, c.$1, {'cache-control': c.$2, 'surrogate-key': tags[path] ?? ''});
  }
}

class _Entry {
  _Entry(this.response, this.storedAt, this.maxAge, this.swr);
  final OriginResponse response;
  final int storedAt;
  final int maxAge;
  final int swr;
  int get size => response.body.length;
  Set<String> get tags => (response.headers['surrogate-key'] ?? '').split(' ').where((t) => t.isNotEmpty).toSet();
}

class CacheNode implements Upstream {
  CacheNode(this.name, this.upstream, this.clock, {this.capacityBytes = 1 << 20});
  final String name;
  final Upstream upstream;
  final Clock clock;
  final int capacityBytes;
  final _entries = LinkedHashMap<String, _Entry>(); // iteration order = LRU order
  final _inflight = <String, Future<OriginResponse>>{};
  var _bytes = 0;
  final stats = <String, int>{'HIT': 0, 'MISS': 0, 'STALE': 0};
  final _refreshes = <Future<void>>[];

  Future<(String, OriginResponse)> get(String url, Map<String, String> headers) async {
    final key = cacheKey(url, headers);
    final (status, res) = await _lookup(key, url);
    stats[status] = stats[status]! + 1;
    return (status, res);
  }

  /// As an upstream for a lower tier (edge -> shield).
  @override
  Future<OriginResponse> fetch(String key, String url) async => (await _lookup(key, url)).$2;

  Future<(String, OriginResponse)> _lookup(String key, String url) async {
    final e = _entries.remove(key);
    if (e != null) {
      _entries[key] = e; // most recently used
      final age = clock.nowSec - e.storedAt;
      if (age < e.maxAge) return ('HIT', e.response);
      if (age < e.maxAge + e.swr) {
        _refreshes.add(_fetchAndStore(key, url).then((_) {})); // refresh in the background
        return ('STALE', e.response);
      }
    }
    return ('MISS', await _fetchAndStore(key, url));
  }

  Future<OriginResponse> _fetchAndStore(String key, String url) => _inflight.putIfAbsent(key, () async {
    try {
      final res = await upstream.fetch(key, url);
      final policy = parseCacheControl(res.headers['cache-control']);
      if (res.status == 200 && policy.store) _store(key, _Entry(res, clock.nowSec, policy.maxAge, policy.swr));
      return res;
    } finally {
      _inflight.remove(key); // the next miss after this completes starts a new fetch
    }
  });

  void _store(String key, _Entry e) {
    purgeKey(key);
    _entries[key] = e;
    _bytes += e.size;
    while (_bytes > capacityBytes && _entries.isNotEmpty) {
      purgeKey(_entries.keys.first); // evict least recently used
    }
  }

  void purgeKey(String key) {
    final e = _entries.remove(key);
    if (e != null) _bytes -= e.size;
  }

  int purgeTag(String tag) {
    final keys = [
      for (final e in _entries.entries)
        if (e.value.tags.contains(tag)) e.key,
    ];
    keys.forEach(purgeKey);
    return keys.length;
  }

  Future<void> settle() => Future.wait(_refreshes);
  int get bytes => _bytes;
  bool contains(String url, Map<String, String> headers) => _entries.containsKey(cacheKey(url, headers));
}

// ---------- Self-checks ----------

void check(Object? actual, Object? expected) {
  if ('$actual' != '$expected') throw StateError('expected $expected, got $actual');
  print('ok: $actual');
}

Future<void> main() async {
  // Keys and headers.
  check(
    cacheKey('https://shop.com/p?b=2&a=1&utm_source=mail', {'accept-encoding': 'gzip, br'}),
    'shop.com/p?a=1&b=2|br',
  );
  check(parseCacheControl('public, max-age=60, s-maxage=300, stale-while-revalidate=30'), (
    store: true,
    maxAge: 300,
    swr: 30,
  ));
  check([parseCacheControl('private, max-age=60').store, parseCacheControl('no-store').store], [false, false]);

  final clock = Clock();
  final origin = Origin()
    ..content['/logo.png'] = ('LOGO-v1', 'max-age=60, stale-while-revalidate=30')
    ..content['/me'] = ('alice profile', 'private, max-age=60')
    ..content['/p/42'] = ('product 42', 'max-age=600')
    ..content['/p/42/img'] = ('img 42', 'max-age=600');
  origin.tags['/p/42'] = 'product:42';
  origin.tags['/p/42/img'] = 'product:42';
  final edge = CacheNode('edge', origin, clock);
  const h = {'accept-encoding': 'gzip'};

  // Miss then hit; parameter order and tracking parameters do not matter.
  check((await edge.get('https://cdn.com/logo.png?v=1&utm_source=x', h)).$1, 'MISS');
  check((await edge.get('https://cdn.com/logo.png?v=1', h)).$1, 'HIT');
  check(origin.calls, 1);

  // Request coalescing: 50 simultaneous misses -> one origin fetch.
  final results = await Future.wait([for (var i = 0; i < 50; i++) edge.get('https://cdn.com/p/42', h)]);
  check([origin.calls, results.every((r) => r.$2.body == 'product 42')], [2, true]);

  // Stale-while-revalidate: after 60 s the stale copy is served at once and refreshed in the background.
  origin.content['/logo.png'] = ('LOGO-v2', 'max-age=60, stale-while-revalidate=30');
  clock.nowSec = 70;
  final stale = await edge.get('https://cdn.com/logo.png?v=1', h);
  check([stale.$1, stale.$2.body], ['STALE', 'LOGO-v1']);
  await edge.settle();
  final fresh = await edge.get('https://cdn.com/logo.png?v=1', h);
  check([fresh.$1, fresh.$2.body, origin.calls], ['HIT', 'LOGO-v2', 3]);

  // Beyond the stale window, the user waits for a real miss.
  clock.nowSec = 70 + 60 + 30;
  check((await edge.get('https://cdn.com/logo.png?v=1', h)).$1, 'MISS');

  // Private responses are never stored in a shared cache.
  await edge.get('https://cdn.com/me', h);
  await edge.get('https://cdn.com/me', h);
  check(edge.contains('https://cdn.com/me', h), false);

  // Tiered caching: two edges miss, the shield fetches from the origin once.
  final shieldOrigin = Origin()..content['/video/seg1'] = ('SEGMENT', 'max-age=3600');
  final shield = CacheNode('shield', shieldOrigin, clock);
  final paris = CacheNode('paris', shield, clock), berlin = CacheNode('berlin', shield, clock);
  await paris.get('https://cdn.com/video/seg1', h);
  await berlin.get('https://cdn.com/video/seg1', h);
  check([shieldOrigin.calls, paris.stats['MISS'], berlin.stats['MISS']], [1, 1, 1]);

  // Purge by tag removes every object of product 42.
  await edge.get('https://cdn.com/p/42/img', h);
  check([edge.purgeTag('product:42'), edge.contains('https://cdn.com/p/42', h)], [2, false]);

  // Byte-bounded LRU: the least recently used object is evicted first.
  final small = CacheNode(
    'small',
    Origin()
      ..content.addAll({
        '/a': ('a' * 400, 'max-age=60'),
        '/b': ('b' * 400, 'max-age=60'),
        '/c': ('c' * 400, 'max-age=60'),
      }),
    clock,
    capacityBytes: 1000,
  );
  await small.get('https://x.com/a', h);
  await small.get('https://x.com/b', h);
  await small.get('https://x.com/a', h); // a is now most recently used
  await small.get('https://x.com/c', h); // evicts b
  check([small.contains('https://x.com/a', h), small.contains('https://x.com/b', h), small.bytes], [true, false, 800]);
}
```

## 5. Walkthrough

- `?v=1&utm_source=x` and `?v=1` produce the same key, so the second request is a hit.
- Fifty concurrent requests for `/p/42` arrive while nothing is cached; the first creates the in-flight future and the other 49 await it: one origin call.
- At t = 70 the logo is 10 s past its 60 s TTL but inside the 30 s stale window: the user gets `LOGO-v1` immediately while a background fetch stores `LOGO-v2`, which the next request receives as a hit.
- At t = 160 the entry is beyond `max-age + stale-while-revalidate`, so it is a normal miss.
- `/me` is `private` and is fetched twice without ever being stored.
- Paris and Berlin both miss, but their upstream is the shield, which asks the origin only once.
- Purging the tag `product:42` removes the product page and its image together.
- With a 1,000-byte budget, touching `a` before adding `c` makes `b` the least recently used, so `b` is evicted.

## 6. Concurrency

- In a real edge server (multi-threaded or an event loop per core), the in-flight map is the coalescing point; with threads it needs a lock or a concurrent map with `computeIfAbsent`.
- Background refreshes are coalesced through the same in-flight map, so a burst of stale hits causes one refresh.
- Purges from the control plane are applied by each server independently; a request racing with a purge may get the old object once.

## 7. Extensibility

| Change | Where |
|---|---|
| `stale-if-error` | On upstream failure, return the expired entry if within the window. |
| Conditional revalidation | Send `If-None-Match`; a `304` refreshes `storedAt` without a body. |
| Disk tier | A second, larger LRU behind the RAM one. |
| Consistent hashing inside a PoP | Route each key to one server (see 03) before this cache. |
| Edge rules | Per-customer overrides of TTL and key rules applied before `_lookup`. |

## 8. Common mistakes in LLD rounds

- Caching `private` or `Set-Cookie` responses in a shared cache.
- Letting every concurrent miss go to the origin.
- Entry-count limits for objects of wildly different sizes.
- Forgetting to remove the in-flight entry after a failed fetch (all later requests hang on the failure).

See [HLD.md](HLD.md) for routing to PoPs, origin shields and invalidation strategies.
