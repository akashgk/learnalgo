# Distributed Key-Value Store: Low-Level Design

## 1. Scope for the LLD round

Two layers, each one class family:

1. **Storage engine on one node (LSM tree):** write-ahead log, sorted memtable, immutable SSTables (newest first), versioned values with **tombstones** for deletes, range reads, **compaction**, and **recovery** by replaying the WAL after a crash.
2. **Replication across nodes:** a ring of nodes, a **preference list** of N replicas per key, quorum writes (W) and reads (R), **last-writer-wins** versions, **sloppy quorum with hinted handoff**, and **read repair**.

Out of scope: gossip, Merkle-tree anti-entropy, vector clocks, networking (HLD).

## 2. Entities and responsibilities

| Class | Responsibility |
|---|---|
| `Versioned` | A version number and a value; `null` value = tombstone. |
| `SsTable` | Immutable sorted keys and values; binary-search lookup. |
| `LsmStore` | WAL, memtable, SSTables; `apply`, `lookup`, `get`, `range`, `flush`, `compact`, `recover`. |
| `Node` | An `LsmStore`, an up/down flag, and hints held for other nodes. |
| `Cluster` | The ring; preference lists; `put`, `delete`, `get` with N/R/W; hinted handoff; read repair. |

```text
Cluster --ring of--> Node --has--> LsmStore --has--> WAL (list of records)
                       |                     --has--> memtable (SplayTreeMap, sorted)
                       +--hints--> (target, key, Versioned)   --has--> SsTable[] (newest first)
```

## 3. Design decisions and why

- **Every write carries a version** assigned by the coordinator; a replica keeps the higher version. This makes writes idempotent and order-independent (a late, older write cannot overwrite a newer one), which hinted handoff and read repair rely on. LWW loses one of two truly concurrent writes; vector clocks would keep both (HLD section 7).
- **Deletes are tombstones**, versioned like writes, so a replica that missed the delete cannot bring the value back during repair.
- **WAL before memtable:** after a crash, replaying the log rebuilds exactly the unflushed writes. Flushing to an SSTable makes the log entries unnecessary, so the log is truncated.
- **Lookup order memtable -> newest SSTable -> oldest** finds the newest version first, because the store only ever accepts higher versions per key.
- **Compaction** merges all SSTables, keeps the newest version per key, and drops tombstones. Dropping tombstones is only safe after every replica has seen them (a grace period in production); the code notes that.
- **Sloppy quorum:** if a preferred replica is down, the write goes to the next healthy node outside the preference list, with a hint naming the intended owner. Writes stay available; reads still use the preference list.

## 4. The code

```dart
import 'dart:collection';

// ---------- Storage engine ----------

class Versioned {
  const Versioned(this.version, this.value);
  final int version;
  final String? value; // null = tombstone
  @override
  String toString() => 'v$version:${value ?? '<deleted>'}';
}

class SsTable {
  SsTable(SplayTreeMap<String, Versioned> sorted) : keys = sorted.keys.toList(), values = sorted.values.toList();
  final List<String> keys;
  final List<Versioned> values;

  Versioned? get(String key) {
    var lo = 0, hi = keys.length - 1;
    while (lo <= hi) {
      final mid = (lo + hi) >> 1;
      final c = keys[mid].compareTo(key);
      if (c == 0) return values[mid];
      if (c < 0) {
        lo = mid + 1;
      } else {
        hi = mid - 1;
      }
    }
    return null;
  }
}

class LsmStore {
  LsmStore({this.memtableLimit = 4});

  final int memtableLimit;
  final wal = <(String, Versioned)>[]; // stands in for an append-only file, fsynced per write
  var _memtable = SplayTreeMap<String, Versioned>();
  var sstables = <SsTable>[]; // newest first

  int get memtableSize => _memtable.length;

  /// Applies a versioned write. Returns false (and does nothing) if a same or newer version exists.
  bool apply(String key, Versioned v) {
    final current = lookup(key);
    if (current != null && current.version >= v.version) return false;
    wal.add((key, v)); // durable first
    _memtable[key] = v;
    if (_memtable.length >= memtableLimit) flush();
    return true;
  }

  Versioned? lookup(String key) {
    final m = _memtable[key];
    if (m != null) return m;
    for (final t in sstables) {
      final v = t.get(key);
      if (v != null) return v;
    }
    return null;
  }

  String? get(String key) => lookup(key)?.value;

  /// Live keys in [from, to), sorted.
  Map<String, String> range(String from, String to) {
    final merged = SplayTreeMap<String, Versioned>();
    for (final source in [...sstables.reversed.map((t) => Map.fromIterables(t.keys, t.values)), _memtable]) {
      source.forEach((k, v) {
        if (k.compareTo(from) >= 0 && k.compareTo(to) < 0 && (merged[k]?.version ?? -1) < v.version) merged[k] = v;
      });
    }
    return {
      for (final e in merged.entries)
        if (e.value.value != null) e.key: e.value.value!,
    };
  }

  void flush() {
    if (_memtable.isEmpty) return;
    sstables.insert(0, SsTable(_memtable));
    _memtable = SplayTreeMap();
    wal.clear(); // everything in the log is now in an SSTable
  }

  /// Full compaction: one SSTable, newest version per key, tombstones dropped.
  /// Production keeps tombstones until a grace period has passed so every replica has seen them.
  void compact() {
    final merged = SplayTreeMap<String, Versioned>();
    for (final t in sstables.reversed) {
      for (var i = 0; i < t.keys.length; i++) {
        if ((merged[t.keys[i]]?.version ?? -1) < t.values[i].version) merged[t.keys[i]] = t.values[i];
      }
    }
    merged.removeWhere((_, v) => v.value == null);
    sstables = merged.isEmpty ? [] : [SsTable(merged)];
  }

  /// Rebuild after a crash: the SSTables survived on disk, the memtable did not; replay the WAL.
  static LsmStore recover(List<SsTable> sstables, List<(String, Versioned)> wal, {int memtableLimit = 4}) {
    final store = LsmStore(memtableLimit: memtableLimit)..sstables = [...sstables];
    for (final (key, v) in wal) {
      store.apply(key, v);
    }
    return store;
  }
}

// ---------- Replication ----------

int stableHash(String s) {
  var h = 0x811C9DC5;
  for (final c in s.codeUnits) {
    h = ((h ^ c) * 0x01000193) & 0xFFFFFFFF;
  }
  h ^= h >> 16;
  h = (h * 0x85EBCA6B) & 0xFFFFFFFF;
  return h ^ (h >> 13);
}

class Node {
  Node(this.id);
  final String id;
  final store = LsmStore(memtableLimit: 1000);
  var up = true;
  final hints = <(String, String, Versioned)>[]; // (intended owner, key, value)
}

class QuorumException implements Exception {
  QuorumException(this.message);
  final String message;
  @override
  String toString() => message;
}

class Cluster {
  Cluster(List<String> ids, {this.n = 3, this.r = 2, this.w = 2})
    : ring = [for (final id in ids) Node(id)]..sort((a, b) => stableHash(a.id).compareTo(stableHash(b.id)));

  final List<Node> ring; // sorted by position (one point per node here; virtual nodes in production)
  final int n;
  final int r;
  final int w;
  var _version = 0; // stands in for a coordinator timestamp

  Node node(String id) => ring.firstWhere((x) => x.id == id);

  int _start(String key) {
    final h = stableHash(key);
    final i = ring.indexWhere((x) => stableHash(x.id) >= h);
    return i < 0 ? 0 : i;
  }

  /// The N nodes that own [key]: clockwise from its hash.
  List<Node> preferenceList(String key) => [for (var i = 0; i < n; i++) ring[(_start(key) + i) % ring.length]];

  void put(String key, String value) => _write(key, Versioned(++_version, value));
  void delete(String key) => _write(key, Versioned(++_version, null));

  void _write(String key, Versioned v) {
    final preferred = preferenceList(key);
    final used = {...preferred};
    var acks = 0;
    var next = (_start(key) + n) % ring.length;
    for (final owner in preferred) {
      if (owner.up) {
        owner.store.apply(key, v);
        acks++;
        continue;
      }
      // Sloppy quorum: the next healthy node outside the preference list stores it with a hint.
      for (var step = 0; step < ring.length; step++, next = (next + 1) % ring.length) {
        final candidate = ring[next];
        if (candidate.up && used.add(candidate)) {
          candidate.store.apply(key, v);
          candidate.hints.add((owner.id, key, v));
          acks++;
          break;
        }
      }
    }
    if (acks < w) throw QuorumException('write acknowledged by $acks of required $w');
  }

  /// Reads the preference list's healthy replicas, needs R answers, returns the newest, repairs stale replicas.
  String? get(String key) {
    final replicas = preferenceList(key).where((x) => x.up).toList();
    if (replicas.length < r) throw QuorumException('only ${replicas.length} of required $r replicas reachable');
    final answers = {for (final x in replicas) x: x.store.lookup(key)};
    Versioned? newest;
    for (final v in answers.values) {
      if (v != null && (newest == null || v.version > newest.version)) newest = v;
    }
    if (newest != null) {
      for (final MapEntry(key: replica, value: v) in answers.entries) {
        if (v == null || v.version < newest.version) replica.store.apply(key, newest); // read repair
      }
    }
    return newest?.value;
  }

  /// Background task: deliver hints to owners that are back.
  int deliverHints() {
    var delivered = 0;
    for (final holder in ring.where((x) => x.up)) {
      holder.hints.removeWhere((hint) {
        final (ownerId, key, v) = hint;
        final owner = node(ownerId);
        if (!owner.up) return false;
        owner.store.apply(key, v);
        delivered++;
        return true;
      });
    }
    return delivered;
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
  // ----- LSM engine -----
  final s = LsmStore(memtableLimit: 3);
  s
    ..apply('apple', const Versioned(1, 'red'))
    ..apply('banana', const Versioned(2, 'yellow'))
    ..apply('cherry', const Versioned(3, 'dark red')); // memtable full -> flushed
  check([s.sstables.length, s.memtableSize, s.wal.length], [1, 0, 0]);
  s
    ..apply('apple', const Versioned(4, 'green')) // newer version shadows the SSTable value
    ..apply('banana', const Versioned(5, null)); // tombstone
  check([s.get('apple'), s.get('banana'), s.get('cherry')], ['green', null, 'dark red']);
  check(s.apply('apple', const Versioned(2, 'stale')), false); // older version ignored
  check(s.range('a', 'c'), {'apple': 'green'});

  // Crash: the memtable is lost; SSTables and the WAL survive. Replay restores the unflushed writes.
  final recovered = LsmStore.recover(s.sstables, s.wal, memtableLimit: 3);
  check([recovered.get('apple'), recovered.get('banana'), recovered.get('cherry')], ['green', null, 'dark red']);

  s
    ..apply('date', const Versioned(6, 'brown')) // third write: flush
    ..apply('elder', const Versioned(7, 'purple'));
  s.flush();
  check(s.sstables.length, 3);
  s.compact();
  check([s.sstables.length, s.sstables.single.keys], [1, '[apple, cherry, date, elder]']); // tombstoned banana gone
  check(s.get('apple'), 'green');

  // ----- Replication: 5 nodes, N = 3, R = 2, W = 2 -----
  final cluster = Cluster(['A', 'B', 'C', 'D', 'E']);
  const key = 'user:42';
  final pref = cluster.preferenceList(key);
  final others = cluster.ring.where((x) => !pref.contains(x)).toList();
  check(pref.length, 3);

  cluster.put(key, 'v1');
  check(pref.map((x) => x.store.get(key)), '(v1, v1, v1)');
  check(cluster.get(key), 'v1');

  // One owner down: the write still reaches 3 nodes (one holds a hint). Hinted handoff repairs it later.
  pref[0].up = false;
  cluster.put(key, 'v2');
  final hintHolders = others.where((x) => x.hints.isNotEmpty).toList();
  check([hintHolders.length, hintHolders.single.store.get(key)], [1, 'v2']);
  check(cluster.get(key), 'v2'); // R = 2 from the two healthy owners
  pref[0].up = true;
  check(pref[0].store.get(key), 'v1'); // stale until repaired
  check(cluster.deliverHints(), 1);
  check(pref[0].store.get(key), 'v2');

  // Read repair: an owner misses a write while down; the next read fixes it.
  pref[1].up = false;
  cluster.put(key, 'v3');
  pref[1].up = true;
  for (final x in cluster.ring) {
    x.hints.clear(); // pretend handoff has not run yet
  }
  check(pref[1].store.get(key), 'v2');
  check(cluster.get(key), 'v3');
  check(pref[1].store.get(key), 'v3'); // repaired by the read

  // Tombstones stop a stale replica from resurrecting a deleted value.
  pref[2].up = false;
  cluster.delete(key);
  pref[2].up = true;
  check(pref[2].store.get(key), 'v3'); // it missed the delete
  check(cluster.get(key), null); // the tombstone (newer version) wins
  check(pref[2].store.lookup(key), 'v4:<deleted>'); // repaired with the tombstone

  // Sloppy quorum keeps writes available with two owners down; strict reads need R owners.
  pref[0].up = false;
  pref[1].up = false;
  cluster.put(key, 'v6'); // pref[2] + two hint holders = 3 acks
  expectThrows<QuorumException>(() => cluster.get(key));
  for (final x in [...others, pref[2]]) {
    x.up = false;
  }
  expectThrows<QuorumException>(() => cluster.put(key, 'v7')); // nobody healthy
}
```

## 5. Walkthrough

- With a memtable limit of 3, the third write flushes the memtable to an SSTable and truncates the WAL. Later writes for `apple` and `banana` live in the memtable and shadow the SSTable. An older version for `apple` is rejected.
- Recovery takes the surviving SSTables and the WAL (two records: new `apple`, `banana` tombstone) and replays them: the same state as before the crash.
- After two more flushes there are three SSTables; compaction merges them into one, keeps the newest `apple`, and drops `banana`'s tombstone.
- With `pref[0]` down, `v2` goes to the two healthy owners and to one node outside the preference list with a hint. When `pref[0]` returns, `deliverHints` hands `v2` over.
- `pref[1]` misses `v3`; a later quorum read sees `v2` and `v3`, returns `v3`, and writes it back to `pref[1]`.
- The delete is version 4 (versions 1-3 were the three puts). `pref[2]` missed it and still has `v3`, but the tombstone's version is higher, so the read returns `null` and repairs `pref[2]` with the tombstone instead of resurrecting `v3`.
- With two owners down, a write still collects 3 acknowledgments (sloppy quorum), but a read cannot reach R = 2 owners.

## 6. Concurrency

- Within a node: the WAL append and memtable insert for one key must be atomic with respect to other writes (a lock per memtable, or a single writer thread with a queue). The memtable is a concurrent skip list in real engines.
- Flush and compaction run in the background: the memtable is swapped for a new one (writers continue), and SSTable lists are replaced atomically (readers keep a reference to the old list).
- Across nodes: version assignment by timestamps means two coordinators can write the same key concurrently; LWW picks one. Vector clocks detect the concurrency instead of hiding it.

## 7. Extensibility

| Change | Where |
|---|---|
| Vector clocks | Replace `int version` with a map; `apply` keeps concurrent siblings. |
| Bloom filters per SSTable | `SsTable.mightContain(key)` checked before the binary search. |
| Leveled compaction | Compact overlapping key ranges level by level instead of everything at once. |
| Per-request consistency | `get(key, r: ...)`, `put(key, value, w: ...)`. |
| Virtual nodes | Several ring points per node; preference list skips duplicates of the same physical node. |

## 8. Common mistakes in LLD rounds

- Deleting keys physically (resurrection by stale replicas).
- Overwriting without versions (an old hint or repair clobbers a newer value).
- Not truncating the WAL after a flush (unbounded log, slow recovery).
- Reading SSTables oldest first.
- Counting a hint holder as a reader of the key.

See [HLD.md](HLD.md) for partitioning, gossip, anti-entropy and the CAP discussion.
