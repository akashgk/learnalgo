# Distributed Cache: Low-Level Design

## 1. Scope for the LLD round

- A single-node cache with `get`, `set` (optional TTL), `delete`, and `getOrLoad` (cache-aside).
- O(1) operations and a fixed capacity, with a **pluggable eviction policy**: LRU and LFU.
- TTL expiry: lazy on read, plus an explicit sweep.
- A **consistent hash ring** with virtual nodes, and a cluster client that routes keys to nodes.
- Hit, miss and eviction counters.

Out of scope: networking, replication, persistence (HLD sections 5 and 8).

## 2. Entities and responsibilities

| Class | Responsibility |
|---|---|
| `Clock` / `FakeClock` | Current time in ms; fake for tests. |
| `EvictionPolicy<K>` (interface) | Tracks key usage; names the victim when the cache is full. |
| `LruPolicy<K>` | Hash map + hand-written doubly linked list; evicts the least recently used key. |
| `LfuPolicy<K>` | Frequency buckets; evicts the least frequently used key, LRU among ties. |
| `LocalCache<K, V>` | Storage, capacity, TTL, stats; delegates ordering decisions to the policy. |
| `HashRing` | Consistent hashing with virtual nodes; `nodeFor(key)`. |
| `CacheCluster` | Owns a ring and one `LocalCache` per node; routes every call. |

```text
CacheCluster --uses--> HashRing
     |
     +--has many--> LocalCache<K,V> --uses--> EvictionPolicy<K> (interface) <-- LruPolicy, LfuPolicy
                         |
                         +--uses--> Clock
```

## 3. Design decisions and why

- **Strategy for eviction.** The cache never knows how victims are chosen, so LRU, LFU, FIFO or random are drop-in replacements (Open/Closed). The policy receives three events: insert, access, remove.
- **The policy only stores keys**, the cache stores values. Single responsibility, and each structure stays simple.
- **LRU with an explicit doubly linked list**, not a library ordered map: interviewers usually want to see `unlink` and `pushFront`. Head = most recent, tail = victim.
- **LFU in O(1)**: `key -> count` plus `count -> insertion-ordered set of keys` plus `minFreq`. An access moves a key from bucket f to f + 1.
- **TTL is stored with the entry** as an absolute expiry time. Expired entries are removed when read (lazy) or by `purgeExpired()` (what a background sampler would call).
- **`V extends Object`**, so `null` unambiguously means "miss".
- **Stable hash for the ring** (FNV-1a plus a mixing step). Never use a language's default `hashCode` for routing: it may differ between processes, and every client must agree.

## 4. The code

```dart
// ---------- Time ----------

abstract interface class Clock {
  int nowMs();
}

class FakeClock implements Clock {
  FakeClock([this._now = 0]);
  int _now;
  @override
  int nowMs() => _now;
  void advance(int ms) => _now += ms;
}

// ---------- Eviction policies ----------

abstract interface class EvictionPolicy<K> {
  void onInsert(K key);
  void onAccess(K key);
  void onRemove(K key);

  /// The key to evict. Only called when at least one key is tracked.
  K victim();
}

class _Node<K> {
  _Node(this.key);
  final K key;
  _Node<K>? prev;
  _Node<K>? next;
}

class LruPolicy<K> implements EvictionPolicy<K> {
  final _nodes = <K, _Node<K>>{};
  _Node<K>? _head; // most recently used
  _Node<K>? _tail; // least recently used

  void _unlink(_Node<K> n) {
    if (n.prev == null) {
      _head = n.next;
    } else {
      n.prev!.next = n.next;
    }
    if (n.next == null) {
      _tail = n.prev;
    } else {
      n.next!.prev = n.prev;
    }
    n.prev = null;
    n.next = null;
  }

  void _pushFront(_Node<K> n) {
    n.next = _head;
    _head?.prev = n;
    _head = n;
    _tail ??= n;
  }

  @override
  void onInsert(K key) {
    final node = _Node(key);
    _nodes[key] = node;
    _pushFront(node);
  }

  @override
  void onAccess(K key) {
    final node = _nodes[key]!;
    _unlink(node);
    _pushFront(node);
  }

  @override
  void onRemove(K key) {
    final node = _nodes.remove(key);
    if (node != null) _unlink(node);
  }

  @override
  K victim() => _tail!.key;

  /// Most recent first; for tests and debugging.
  List<K> order() => [for (var n = _head; n != null; n = n.next) n.key];
}

class LfuPolicy<K> implements EvictionPolicy<K> {
  final _count = <K, int>{};
  final _buckets = <int, Set<K>>{}; // Dart's default Set keeps insertion order
  var _minFreq = 0;

  void _addTo(int freq, K key) => _buckets.putIfAbsent(freq, () => <K>{}).add(key);

  void _removeFrom(int freq, K key) {
    final bucket = _buckets[freq]!..remove(key);
    if (bucket.isEmpty) _buckets.remove(freq);
  }

  @override
  void onInsert(K key) {
    _count[key] = 1;
    _addTo(1, key);
    _minFreq = 1;
  }

  @override
  void onAccess(K key) {
    final f = _count[key]!;
    _removeFrom(f, key);
    if (_minFreq == f && !_buckets.containsKey(f)) _minFreq = f + 1;
    _count[key] = f + 1;
    _addTo(f + 1, key);
  }

  @override
  void onRemove(K key) {
    final f = _count.remove(key);
    if (f == null) return;
    _removeFrom(f, key);
    if (f == _minFreq && !_buckets.containsKey(f)) {
      // Rare path (delete or expiry of the last min-frequency key): rescan distinct frequencies.
      _minFreq = _buckets.isEmpty ? 0 : _buckets.keys.reduce((a, b) => a < b ? a : b);
    }
  }

  @override
  K victim() => _buckets[_minFreq]!.first;
}

// ---------- Single-node cache ----------

class _Entry<V> {
  _Entry(this.value, this.expiresAtMs);
  final V value;
  final int? expiresAtMs;
}

class LocalCache<K, V extends Object> {
  LocalCache({required this.capacity, required EvictionPolicy<K> policy, required Clock clock})
    : _policy = policy,
      _clock = clock {
    if (capacity <= 0) throw ArgumentError.value(capacity, 'capacity', 'must be positive');
  }

  final int capacity;
  final EvictionPolicy<K> _policy;
  final Clock _clock;
  final _entries = <K, _Entry<V>>{};
  var hits = 0;
  var misses = 0;
  var evictions = 0;

  int get size => _entries.length;

  bool _expired(_Entry<V> e) => e.expiresAtMs != null && _clock.nowMs() >= e.expiresAtMs!;

  V? get(K key) {
    final e = _entries[key];
    if (e == null || _expired(e)) {
      if (e != null) _remove(key);
      misses++;
      return null;
    }
    hits++;
    _policy.onAccess(key);
    return e.value;
  }

  void set(K key, V value, {Duration? ttl}) {
    final expiresAt = ttl == null ? null : _clock.nowMs() + ttl.inMilliseconds;
    if (_entries.containsKey(key)) {
      _entries[key] = _Entry(value, expiresAt);
      _policy.onAccess(key);
      return;
    }
    if (_entries.length >= capacity) {
      _remove(_policy.victim());
      evictions++;
    }
    _entries[key] = _Entry(value, expiresAt);
    _policy.onInsert(key);
  }

  bool delete(K key) => _remove(key);

  /// Cache-aside: return the cached value, or load it, cache it and return it.
  V getOrLoad(K key, V Function() load, {Duration? ttl}) {
    final cached = get(key);
    if (cached != null) return cached;
    final value = load();
    set(key, value, ttl: ttl);
    return value;
  }

  /// Active expiry; a real server samples a few keys per tick instead of scanning all.
  int purgeExpired() {
    final dead = [
      for (final e in _entries.entries)
        if (_expired(e.value)) e.key,
    ];
    dead.forEach(_remove);
    return dead.length;
  }

  bool _remove(K key) {
    if (_entries.remove(key) == null) return false;
    _policy.onRemove(key);
    return true;
  }
}

// ---------- Consistent hashing ----------

const _mask32 = 0xFFFFFFFF;

/// FNV-1a over UTF-16 code units, then the murmur3 finalizer to spread similar strings.
int stableHash(String s) {
  var h = 0x811C9DC5;
  for (final unit in s.codeUnits) {
    h = ((h ^ unit) * 0x01000193) & _mask32;
  }
  h ^= h >> 16;
  h = (h * 0x85EBCA6B) & _mask32;
  h ^= h >> 13;
  h = (h * 0xC2B2AE35) & _mask32;
  h ^= h >> 16;
  return h;
}

class HashRing {
  HashRing({this.virtualNodes = 150});

  final int virtualNodes;
  final _points = <int>[]; // sorted hash positions
  final _owner = <int, String>{}; // position -> physical node
  final _nodes = <String>{};

  Set<String> get nodes => Set.unmodifiable(_nodes);

  void addNode(String node) {
    if (!_nodes.add(node)) return;
    for (var i = 0; i < virtualNodes; i++) {
      final p = stableHash('$node#$i');
      if (_owner.containsKey(p)) continue; // astronomically rare collision: skip this point
      _owner[p] = node;
      _points.add(p);
    }
    _points.sort();
  }

  void removeNode(String node) {
    if (!_nodes.remove(node)) return;
    _points.removeWhere((p) => _owner[p] == node);
    _owner.removeWhere((_, owner) => owner == node);
  }

  /// First point clockwise from hash(key), wrapping around. O(log P) by binary search.
  String nodeFor(String key) {
    if (_points.isEmpty) throw StateError('ring has no nodes');
    final h = stableHash(key);
    var lo = 0, hi = _points.length;
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      if (_points[mid] < h) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    return _owner[_points[lo == _points.length ? 0 : lo]]!;
  }
}

// ---------- Cluster client ----------

class CacheCluster {
  CacheCluster({required this.capacityPerNode, required this.clock});

  final int capacityPerNode;
  final Clock clock;
  final ring = HashRing();
  final _caches = <String, LocalCache<String, String>>{};

  void addNode(String node) {
    _caches[node] = LocalCache(capacity: capacityPerNode, policy: LruPolicy<String>(), clock: clock);
    ring.addNode(node);
  }

  void removeNode(String node) {
    ring.removeNode(node);
    _caches.remove(node);
  }

  LocalCache<String, String> _cacheFor(String key) => _caches[ring.nodeFor(key)]!;

  String? get(String key) => _cacheFor(key).get(key);
  void set(String key, String value, {Duration? ttl}) => _cacheFor(key).set(key, value, ttl: ttl);
  bool delete(String key) => _cacheFor(key).delete(key);
}

// ---------- Self-checks ----------

void check(Object? actual, Object? expected) {
  if ('$actual' != '$expected') throw StateError('expected $expected, got $actual');
  print('ok: $actual');
}

void main() {
  final clock = FakeClock();

  // LRU: capacity 3; touching 'a' makes 'b' the victim.
  final lru = LruPolicy<String>();
  final cache = LocalCache<String, int>(capacity: 3, policy: lru, clock: clock);
  cache
    ..set('a', 1)
    ..set('b', 2)
    ..set('c', 3);
  check(cache.get('a'), 1);
  check(lru.order(), ['a', 'c', 'b']);
  cache.set('d', 4); // evicts b
  check(cache.get('b'), null);
  check([cache.get('a'), cache.get('c'), cache.get('d')], [1, 3, 4]);
  check(cache.evictions, 1);
  cache.set('c', 30); // update counts as a use
  check(lru.order(), ['c', 'd', 'a']);
  check(cache.delete('a'), true);
  check(cache.delete('a'), false);
  check(lru.order(), ['c', 'd']);

  // TTL: lazy expiry on read and an explicit sweep.
  final ttlCache = LocalCache<String, String>(capacity: 10, policy: LruPolicy<String>(), clock: clock);
  ttlCache
    ..set('session', 'x', ttl: const Duration(seconds: 30))
    ..set('forever', 'y')
    ..set('short', 'z', ttl: const Duration(seconds: 5));
  clock.advance(5000);
  check(ttlCache.get('short'), null); // expires exactly at 5000 ms
  check(ttlCache.get('session'), 'x');
  clock.advance(25000);
  check(ttlCache.purgeExpired(), 1);
  check([ttlCache.size, ttlCache.get('forever')], [1, 'y']);

  // LFU: the least frequently used key is evicted; ties go to the oldest.
  final lfu = LocalCache<String, int>(capacity: 2, policy: LfuPolicy<String>(), clock: clock);
  lfu
    ..set('x', 1)
    ..set('y', 2);
  lfu.get('x');
  lfu.set('z', 3); // y has freq 1, x has freq 2 -> evict y
  check([lfu.get('x'), lfu.get('y'), lfu.get('z')], [1, null, 3]);
  lfu.delete('z'); // min frequency must be recomputed
  lfu
    ..set('w', 4)
    ..set('v', 5); // w (freq 1) evicted, x (freq 3) stays
  check([lfu.get('x'), lfu.get('w'), lfu.get('v')], [1, null, 5]);

  // Cache-aside: the loader runs only on a miss.
  var loads = 0;
  final users = LocalCache<String, String>(capacity: 10, policy: LruPolicy<String>(), clock: clock);
  String loadUser() {
    loads++;
    return 'Ada';
  }

  check(users.getOrLoad('user:1', loadUser), 'Ada');
  check(users.getOrLoad('user:1', loadUser), 'Ada');
  check([loads, users.hits, users.misses], [1, 1, 1]);

  // Consistent hashing: balanced load, and adding a node moves only keys to the new node.
  final ring = HashRing()
    ..addNode('A')
    ..addNode('B')
    ..addNode('C');
  final keys = [for (var i = 0; i < 30000; i++) 'key-$i'];
  final before = {for (final k in keys) k: ring.nodeFor(k)};
  final load = <String, int>{};
  for (final n in before.values) {
    load[n] = (load[n] ?? 0) + 1;
  }
  check(load.values.every((c) => c > 8000 && c < 12000), true); // ideal is 10000 each

  ring.addNode('D');
  final moved = keys.where((k) => ring.nodeFor(k) != before[k]).toList();
  check(moved.every((k) => ring.nodeFor(k) == 'D'), true);
  final movedShare = moved.length / keys.length;
  check(movedShare > 0.18 && movedShare < 0.32, true); // ideal is 1/4

  ring.removeNode('D');
  check(keys.every((k) => ring.nodeFor(k) == before[k]), true); // removal restores the old mapping

  // Modulo hashing for contrast: going from 3 to 4 buckets moves about 3/4 of keys.
  final moduloMoved = keys.where((k) => stableHash(k) % 3 != stableHash(k) % 4).length / keys.length;
  check(moduloMoved > 0.7, true);

  // Cluster: losing one node only loses that node's keys.
  final cluster = CacheCluster(capacityPerNode: 1000, clock: clock)
    ..addNode('n1')
    ..addNode('n2')
    ..addNode('n3');
  for (var i = 0; i < 300; i++) {
    cluster.set('k$i', 'v$i');
  }
  final onN2 = [for (var i = 0; i < 300; i++) 'k$i'].where((k) => cluster.ring.nodeFor(k) == 'n2').toSet();
  cluster.removeNode('n2');
  var survived = 0;
  for (var i = 0; i < 300; i++) {
    final hit = cluster.get('k$i') != null;
    check(hit, !onN2.contains('k$i'));
    if (hit) survived++;
  }
  check(survived, 300 - onN2.length);
}
```

## 5. Walkthrough

- **LRU:** `get('a')` moves `a` to the head, so the order is `a, c, b` and `b` (the tail) is the victim when `d` arrives. Updating an existing key is a use, so it moves to the head too.
- **TTL:** expiry is an absolute timestamp; the entry is treated as gone at exactly `expiresAt`. `purgeExpired` removes `session` without anyone reading it.
- **LFU:** `x` was read once, so it has frequency 2 and survives; `y` (frequency 1) is evicted. Deleting `z`, the only key at the minimum frequency (2 after its read), empties that bucket, so `minFreq` is recomputed (to 3).
- **Ring:** with 150 virtual nodes per server, 30,000 keys split close to evenly. Adding `D` moves roughly a quarter of keys, and **every** moved key moves to `D`: no key moves between old nodes. Modulo hashing moves about three quarters.
- **Cluster:** removing `n2` only turns `n2`'s keys into misses.

## 6. Concurrency

- A single-threaded event loop per node (the Redis model) needs no locks: each command runs to completion.
- With threads: one lock per cache is simplest; for throughput, shard the cache into N independent segments by key hash, each with its own lock and its own LRU list (Java's old `ConcurrentHashMap` idea). A global LRU list under a single lock is the usual bottleneck.
- `getOrLoad` under concurrency needs **single flight**: keep a map `key -> in-flight future` so concurrent misses for the same key wait on one load instead of stampeding the DB.
- The ring is read on every call and changed rarely: build a new immutable ring and swap the reference (copy-on-write) instead of locking readers.

## 7. Extensibility

| Change | Where |
|---|---|
| New eviction policy (FIFO, random, ARC) | New `EvictionPolicy` implementation. |
| Memory-based capacity (bytes, not entries) | Track `sizeOf(value)`; evict in a loop until under the limit. |
| Replication | `CacheCluster.set` also writes to the next distinct node on the ring. |
| Weighted nodes | `addNode(node, weight)` places `weight x virtualNodes` points. |
| Eviction listeners (write-behind, metrics) | Callback from `_remove` with the reason (evicted / expired / deleted). |

## 8. Common mistakes in LLD rounds

- Using a library LinkedHashMap and being unable to explain how it works.
- An O(n) eviction scan ("find the entry with the oldest timestamp").
- Forgetting that `set` on an existing key must not evict anything.
- Not removing expired or evicted keys from the policy's own structures (memory leak, wrong victims).
- `hashCode`-based routing that differs across processes.

See [HLD.md](HLD.md) for partitioning, replication, cache patterns and hot keys.
