# Distributed Unique ID Generator: Low-Level Design

## 1. Scope for the LLD round

- A **Snowflake generator** with a configurable bit layout (time, worker, sequence bits summing to 63), a custom epoch, and `decode`.
- **Sequence exhaustion:** after 4,096 IDs in one millisecond, wait for the next millisecond.
- **Clock rollback:** wait if the clock is a few milliseconds behind the last used timestamp; refuse if it is far behind.
- A **range allocator** (ticket server) and a block-based generator, as the coordination-light alternative.
- A **worker ID registry** with leases, so two generators never share a worker ID.

Out of scope: the network service wrapper, persistence of the registry (HLD).

## 2. Entities and responsibilities

| Class | Responsibility |
|---|---|
| `Clock` / `FakeClock` | Current milliseconds; the fake also implements `sleep` by advancing time. |
| `IdLayout` | Bit widths; masks and maximum values; validation. |
| `SnowflakeGenerator` | `next()`, `decode(id)`; last timestamp and sequence state. |
| `ClockMovedBackwardsException` | Raised when the clock is behind by more than the tolerance. |
| `RangeAllocator` | Central counter handing out disjoint blocks. |
| `BlockIdGenerator` | Serves IDs from its current block; refills when empty. |
| `WorkerIdRegistry` | Leases worker IDs to owners; renew, release, expiry. |

```text
WorkerIdRegistry --leases workerId--> SnowflakeGenerator --uses--> Clock, IdLayout
RangeAllocator  --hands blocks to--> BlockIdGenerator (one per app instance)
```

## 3. Design decisions and why

- **Layout as a value object** with validation, so variants (5+5 datacenter/machine bits, 10 ms ticks) are configuration.
- **Sleeping is injected** (`sleep(ms)`), so waiting on exhaustion and rollback is testable without real time.
- **Monotonic per generator:** the generator never issues a timestamp lower than its last one, which, with a unique worker ID, guarantees uniqueness.
- **Tolerance for small rollbacks** (wait them out) but not large ones (fail loudly): waiting seconds would stall callers; issuing IDs would risk duplicates.
- **Blocks for the range allocator** amortize the central call: one allocator call per `blockSize` IDs.
- **Leases, not permanent assignment,** so worker IDs from dead nodes are reclaimed, and a node that cannot renew must stop.

## 4. The code

```dart
// ---------- Time ----------

abstract interface class Clock {
  int nowMs();
}

class FakeClock implements Clock {
  FakeClock(this.ms);
  int ms;
  var sleptMs = 0;
  @override
  int nowMs() => ms;
  void sleep(int d) {
    ms += d;
    sleptMs += d;
  }
}

// ---------- Snowflake ----------

class IdLayout {
  IdLayout({this.timeBits = 41, this.workerBits = 10, this.sequenceBits = 12}) {
    if (timeBits + workerBits + sequenceBits != 63) throw ArgumentError('bits must sum to 63 (sign bit stays 0)');
  }
  final int timeBits;
  final int workerBits;
  final int sequenceBits;

  int get maxWorker => (1 << workerBits) - 1;
  int get sequenceMask => (1 << sequenceBits) - 1;
  int get maxTime => (1 << timeBits) - 1;
}

class ClockMovedBackwardsException implements Exception {
  ClockMovedBackwardsException(this.behindMs);
  final int behindMs;
}

class SnowflakeGenerator {
  SnowflakeGenerator({
    required this.workerId,
    required this.clock,
    required this.sleep,
    IdLayout? layout,
    this.epochMs = 1735689600000, // 2025-01-01T00:00:00Z
    this.maxBackwardMs = 5,
  }) : layout = layout ?? IdLayout() {
    if (workerId < 0 || workerId > this.layout.maxWorker) throw ArgumentError.value(workerId, 'workerId');
  }

  final int workerId;
  final Clock clock;
  final void Function(int ms) sleep;
  final IdLayout layout;
  final int epochMs;
  final int maxBackwardMs;
  var _lastTime = -1;
  var _sequence = 0;

  int _now() => clock.nowMs() - epochMs;

  int next() {
    var now = _now();
    if (now < _lastTime) {
      final behind = _lastTime - now;
      if (behind > maxBackwardMs) throw ClockMovedBackwardsException(behind);
      sleep(behind); // small rollback: wait it out
      now = _now();
      if (now < _lastTime) throw ClockMovedBackwardsException(_lastTime - now);
    }
    if (now == _lastTime) {
      _sequence = (_sequence + 1) & layout.sequenceMask;
      if (_sequence == 0) {
        while (now <= _lastTime) {
          sleep(1); // all sequence numbers used in this millisecond
          now = _now();
        }
      }
    } else {
      _sequence = 0;
    }
    if (now > layout.maxTime) throw StateError('epoch exhausted');
    _lastTime = now;
    return (now << (layout.workerBits + layout.sequenceBits)) | (workerId << layout.sequenceBits) | _sequence;
  }

  ({int timestampMs, int worker, int sequence}) decode(int id) => (
    timestampMs: (id >> (layout.workerBits + layout.sequenceBits)) + epochMs,
    worker: (id >> layout.sequenceBits) & layout.maxWorker,
    sequence: id & layout.sequenceMask,
  );
}

// ---------- Range allocation ----------

class RangeAllocator {
  RangeAllocator({required this.blockSize});
  final int blockSize;
  var _next = 1;
  var calls = 0;

  /// In production: `UPDATE counters SET next = next + :block WHERE name = ? RETURNING next` in one transaction.
  (int, int) allocate() {
    calls++;
    final start = _next;
    _next += blockSize;
    return (start, _next - 1);
  }
}

class BlockIdGenerator {
  BlockIdGenerator(this.allocator);
  final RangeAllocator allocator;
  var _current = 0, _end = -1;

  int next() {
    if (_current > _end) {
      final (start, end) = allocator.allocate();
      _current = start;
      _end = end;
    }
    return _current++;
  }
}

// ---------- Worker ID leases ----------

class LeaseLostException implements Exception {}

class WorkerIdRegistry {
  WorkerIdRegistry({required this.maxWorkers, required this.leaseMs, required this.clock});
  final int maxWorkers;
  final int leaseMs;
  final Clock clock;
  final _leases = <int, (String, int)>{}; // workerId -> (owner, expiresAt)

  bool _free(int id) {
    final lease = _leases[id];
    return lease == null || lease.$2 <= clock.nowMs();
  }

  /// Smallest free (or expired) worker ID. In production: a compare-and-set in etcd/ZooKeeper.
  int acquire(String owner) {
    for (var id = 0; id < maxWorkers; id++) {
      if (_free(id)) {
        _leases[id] = (owner, clock.nowMs() + leaseMs);
        return id;
      }
    }
    throw StateError('no free worker IDs');
  }

  void renew(String owner, int id) {
    final lease = _leases[id];
    if (lease == null || lease.$1 != owner || lease.$2 <= clock.nowMs()) throw LeaseLostException();
    _leases[id] = (owner, clock.nowMs() + leaseMs);
  }

  void release(String owner, int id) {
    if (_leases[id]?.$1 == owner) _leases.remove(id);
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
  const epoch = 1735689600000;
  final clock = FakeClock(epoch + 1000);
  SnowflakeGenerator gen(int worker) => SnowflakeGenerator(workerId: worker, clock: clock, sleep: clock.sleep);

  // Layout and decoding.
  final g7 = gen(7);
  final first = g7.next();
  check(g7.decode(first), (timestampMs: epoch + 1000, worker: 7, sequence: 0));
  check(first, (1000 << 22) | (7 << 12));
  check(((1 << 41) / (365.25 * 86400000)).toStringAsFixed(1), '69.7'); // years of IDs from the epoch
  expectThrows<ArgumentError>(() => IdLayout(timeBits: 41, workerBits: 10, sequenceBits: 13));
  expectThrows<ArgumentError>(() => gen(1024));

  // Three generators, interleaved, time advancing: all unique and increasing per generator.
  final gens = [gen(1), gen(2), gen(3)];
  final seen = <int>{};
  final last = [-1, -1, -1];
  for (var i = 0; i < 30000; i++) {
    if (i % 100 == 0) clock.ms++;
    final k = i % 3;
    final id = gens[k].next();
    if (!seen.add(id) || id <= last[k]) throw StateError('duplicate or out of order');
    last[k] = id;
  }
  check(seen.length, 30000);

  // Sequence exhaustion: the 4097th ID in one millisecond waits for the next millisecond.
  final burstClock = FakeClock(epoch + 5000);
  final burst = SnowflakeGenerator(workerId: 1, clock: burstClock, sleep: burstClock.sleep);
  final ids = List.generate(4097, (_) => burst.next());
  check(
    [burst.decode(ids[4095]).sequence, burst.decode(ids[4096]).timestampMs - epoch, burstClock.sleptMs],
    [4095, 5001, 1],
  );

  // Clock rollback: small -> wait; large -> refuse.
  burstClock.ms -= 3;
  final afterSmall = burst.next();
  check([afterSmall > ids.last, burstClock.sleptMs], [true, 4]);
  burstClock.ms -= 100;
  expectThrows<ClockMovedBackwardsException>(burst.next);

  // Range allocation: disjoint blocks, one central call per block.
  final allocator = RangeAllocator(blockSize: 100);
  final a = BlockIdGenerator(allocator), b = BlockIdGenerator(allocator);
  final blockIds = <int>{};
  for (var i = 0; i < 250; i++) {
    blockIds
      ..add(a.next())
      ..add(b.next());
  }
  check([blockIds.length, allocator.calls], [500, 6]); // a: 3 blocks, b: 3 blocks
  check([a.next(), b.next()], [451, 551]); // blocks were requested in alternation

  // Worker ID leases.
  final regClock = FakeClock(0);
  final registry = WorkerIdRegistry(maxWorkers: 2, leaseMs: 10000, clock: regClock);
  check([registry.acquire('host-a'), registry.acquire('host-b')], [0, 1]);
  expectThrows<StateError>(() => registry.acquire('host-c'));
  regClock.ms = 5000;
  registry.renew('host-b', 1); // b renews; a stays silent
  regClock.ms = 10000;
  check(registry.acquire('host-c'), 0); // a's lease expired; ID 0 reused
  expectThrows<LeaseLostException>(() => registry.renew('host-a', 0)); // a must stop generating
  registry.release('host-b', 1);
  check(registry.acquire('host-d'), 1);
}
```

## 5. Walkthrough

- Worker 7 at epoch + 1000 ms produces `1000 << 22 | 7 << 12`; decoding returns the same three fields.
- `2^41` milliseconds is 69.7 years, which is why the epoch is set near launch time instead of 1970.
- The three-generator run produces 30,000 IDs with no duplicates and strictly increasing IDs per generator, even with 100 IDs per millisecond per tick.
- In one millisecond, sequences 0 to 4095 are used; the 4097th ID sleeps 1 ms and carries timestamp 5001.
- Moving the clock back 3 ms makes the generator sleep 3 ms and continue; moving it back 100 ms raises an exception.
- Range allocation: the two block generators alternate, so the allocator hands out 1-100 (a), 101-200 (b), 201-300 (a), 301-400 (b), 401-500 (a), 501-600 (b). After 250 IDs each, a has used 1-100, 201-300 and 401-450 (next: 451) and b has used 101-200, 301-400 and 501-550 (next: 551). IDs are unique but not time-ordered across generators.
- Worker leases: when `host-a` stops renewing, its ID returns to the pool after 10 s and `host-a`'s late renewal fails.

## 6. Concurrency

- `next()` mutates `_lastTime` and `_sequence`: guard it with a lock (or use one generator per thread with distinct worker IDs). It is a few nanoseconds of work, so a lock is fine.
- The range allocator's increment must be atomic in its database (`UPDATE ... RETURNING`).
- Lease acquisition is a compare-and-set in the coordination service; renewals happen on a background timer well before expiry.

## 7. Extensibility

| Change | Where |
|---|---|
| Datacenter + machine bits | Split `workerBits` in `IdLayout` and compose the worker ID. |
| 10 ms ticks (longer lifetime) | Divide `_now()` by 10; adjust `decode`. |
| Hide creation order publicly | Map IDs through a keyed reversible permutation before exposing them. |
| Shard routing | Reserve bits for a logical shard ID. |

## 8. Common mistakes in LLD rounds

- Resetting the sequence to 0 on every call within the same millisecond.
- Busy-waiting forever when the clock goes back hours.
- Forgetting the sign bit (negative IDs in signed 64-bit columns).
- Hard-coding the worker ID.

See [HLD.md](HLD.md) for the comparison of approaches and the coordination design.
