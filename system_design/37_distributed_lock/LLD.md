# Distributed Lock Service: Low-Level Design

## 1. Scope for the LLD round

- Named locks held under a **lease** (TTL in ms on the server's clock); **renew** extends it; expiry frees the lock automatically.
- `tryAcquire` returns a **grant** with a **fencing token** (a global, strictly increasing number) or nothing; acquiring a lock you already hold returns your existing grant.
- **Release** and **renew** succeed only for the current holder presenting the current token.
- A **FIFO wait queue** per lock: when the lock is released or expires, exactly the next waiter is granted and notified (no herd).
- A **fenced storage** resource that rejects writes carrying a token older than the newest it has seen, demonstrating the GC-pause scenario.

Out of scope: Raft replication of the lock state, client sessions and networking (HLD).

## 2. Entities and responsibilities

| Class | Responsibility |
|---|---|
| `Clock` | Server time in ms. |
| `Grant` | Lock name, owner, fencing token, expiry. |
| `_LockState` | Current grant and the wait queue for one lock. |
| `LockService` | Acquire, wait, renew, release, expire, notify. |
| `FencedStorage` | Remembers the highest token; rejects stale writers. |

```text
LockService: name -> _LockState(grant?, waiters: Queue<(owner, ttl)>)      nextToken (global, monotonic)
   release / expiry --> pop next waiter --> new Grant(token+1) --> onGranted(grant)
client --write(key, value, token)--> FencedStorage (token >= highest seen ? accept : reject)
```

## 3. Design decisions and why

- **Leases, not permanent ownership:** a crashed or partitioned holder cannot block others forever.
- **Server-side expiry checks on every operation** (lazy) plus `tick` (eager hand-off to waiters): correctness does not depend on a background timer firing on time.
- **Owner + token required for release/renew:** a client whose lease expired cannot release (or extend) a lock that now belongs to someone else.
- **Global monotonic tokens** (like etcd revisions): any later grant of any lock has a higher number, so resources can compare tokens safely.
- **FIFO queue with single notification:** fairness, and only one client wakes up per release.
- **Fencing at the resource:** the only place that can stop a paused ex-holder from writing.

## 4. The code

```dart
import 'dart:collection';

class Clock {
  int nowMs = 0;
}

class Grant {
  Grant(this.lock, this.owner, this.token, this.expiresAt);
  final String lock;
  final String owner;
  final int token;
  int expiresAt;
  @override
  String toString() => '$lock:$owner#$token';
}

class _LockState {
  Grant? grant;
  final waiters = Queue<(String, int)>(); // (owner, ttlMs)
}

class LockService {
  LockService(this.clock);
  final Clock clock;
  final _locks = <String, _LockState>{};
  var _nextToken = 1;
  void Function(Grant)? onGranted;

  _LockState _state(String name) => _locks.putIfAbsent(name, _LockState.new);

  Grant _grant(String name, String owner, int ttlMs) =>
      _state(name).grant = Grant(name, owner, _nextToken++, clock.nowMs + ttlMs);

  /// Expires the current grant if its lease is over and hands the lock to the next waiter.
  void _expire(String name) {
    final s = _state(name);
    final g = s.grant;
    if (g != null && g.expiresAt <= clock.nowMs) {
      s.grant = null;
      _handOff(name);
    }
  }

  void _handOff(String name) {
    final s = _state(name);
    if (s.grant != null || s.waiters.isEmpty) return;
    final (owner, ttl) = s.waiters.removeFirst();
    onGranted?.call(_grant(name, owner, ttl));
  }

  Grant? holderOf(String name) {
    _expire(name);
    return _state(name).grant;
  }

  Grant? tryAcquire(String name, String owner, {int ttlMs = 10000}) {
    _expire(name);
    final current = _state(name).grant;
    if (current == null) return _grant(name, owner, ttlMs);
    return current.owner == owner ? current : null;
  }

  /// Acquire now, or join the FIFO queue and be notified through [onGranted] later.
  Grant? acquireOrWait(String name, String owner, {int ttlMs = 10000}) {
    final g = tryAcquire(name, owner, ttlMs: ttlMs);
    if (g != null) return g;
    final s = _state(name);
    if (!s.waiters.any((w) => w.$1 == owner)) s.waiters.add((owner, ttlMs));
    return null;
  }

  bool renew(Grant g, {int ttlMs = 10000}) {
    _expire(g.lock);
    final current = _state(g.lock).grant;
    if (current == null || current.owner != g.owner || current.token != g.token) return false;
    current.expiresAt = clock.nowMs + ttlMs;
    return true;
  }

  bool release(Grant g) {
    _expire(g.lock);
    final s = _state(g.lock);
    if (s.grant == null || s.grant!.owner != g.owner || s.grant!.token != g.token) return false;
    s.grant = null;
    _handOff(g.lock);
    return true;
  }

  /// Background sweep: expire leases and hand locks to waiters.
  void tick() => _locks.keys.toList().forEach(_expire);
}

class FencedStorage {
  var highestToken = 0;
  final data = <String, String>{};
  final rejected = <String>[];

  bool write(String key, String value, int token) {
    if (token < highestToken) {
      rejected.add('$value#$token');
      return false;
    }
    highestToken = token;
    data[key] = value;
    return true;
  }
}

// ---------- Self-checks ----------

void check(Object? actual, Object? expected) {
  if ('$actual' != '$expected') throw StateError('expected $expected, got $actual');
  print('ok: $actual');
}

void main() {
  final clock = Clock();
  final locks = LockService(clock);
  final notified = <String>[];
  locks.onGranted = (g) => notified.add('$g');

  // Mutual exclusion, re-acquire by the holder, owner-checked release.
  final a = locks.tryAcquire('job', 'A', ttlMs: 5000)!;
  check([a, locks.tryAcquire('job', 'B'), identical(locks.tryAcquire('job', 'A'), a)], ['job:A#1', null, true]);
  check(locks.release(Grant('job', 'B', a.token, 0)), false); // B cannot release A's lock

  // Leases: renewal keeps the lock; silence lets it expire.
  clock.nowMs = 4000;
  check(locks.renew(a, ttlMs: 5000), true); // now valid until 9000
  clock.nowMs = 8000;
  check(locks.holderOf('job')?.owner, 'A');
  clock.nowMs = 9000;
  check(locks.holderOf('job'), null); // expired
  check([locks.renew(a), locks.release(a)], [false, false]); // an expired holder can do neither

  // FIFO waiters: one notification per release, tokens keep increasing.
  final b0 = locks.acquireOrWait('job', 'B')!;
  check(locks.acquireOrWait('job', 'C'), null);
  check(locks.acquireOrWait('job', 'D'), null);
  check(locks.acquireOrWait('job', 'C'), null); // already queued: no duplicate
  locks.release(b0);
  check(notified, ['job:C#3']);
  final c = locks.holderOf('job')!;
  locks.release(c);
  check([notified.last, locks.holderOf('job')!.owner], ['job:D#4', 'D']);

  // The GC-pause scenario: only fencing at the resource prevents the corruption.
  final storage = FencedStorage();
  final service = LockService(Clock());
  final granted = <Grant>[];
  service.onGranted = granted.add;
  final p = service.acquireOrWait('ledger', 'P', ttlMs: 3000)!;
  check(storage.write('balance', 'P wrote 100', p.token), true);
  service.acquireOrWait('ledger', 'Q', ttlMs: 3000); // Q waits
  service.clock.nowMs = 3500; // P is frozen in a GC pause; its lease runs out
  service.tick();
  final q = granted.single;
  check([q.owner, q.token > p.token], ['Q', true]);
  check(storage.write('balance', 'Q wrote 250', q.token), true);
  // P wakes up still believing it holds the lock.
  check([service.renew(p), storage.write('balance', 'P wrote 90', p.token)], [false, false]);
  check([storage.data['balance'], storage.rejected], ['Q wrote 250', '[P wrote 90#1]']);

  // Tokens are global and monotonic across different locks.
  final other = service.tryAcquire('other-lock', 'R')!;
  check(other.token > q.token, true);
}
```

## 5. Walkthrough

- A holds `job` with token 1; B is refused; A re-acquiring gets the same grant; B cannot release A's lock.
- A renews at 4000 (valid until 9000), so at 8000 it still holds the lock. At 9000 nobody holds it; A's late renew and release both fail.
- B acquires with token 2. C and D queue (C's second attempt is not duplicated). B's release hands the lock to C (token 3) with one notification; C's release hands it to D (token 4).
- GC pause: P holds `ledger` with token 1 and writes. Q waits. P freezes past its 3-second lease; the sweep grants Q token 2; Q writes. When P wakes, its renew fails and its write with token 1 is rejected by the storage, which has seen token 2. The balance stays Q's value.
- A grant on a different lock gets a higher token still.

## 6. Concurrency

- In production every mutating operation (`tryAcquire`, `renew`, `release`, expiry) is a command in the replicated log of a consensus group; the state machine above is applied identically on every replica, which is what makes grants linearizable.
- Expiry decisions use the leader's clock; after a leader change, leases are conservatively extended by the election time so no lease ends early.
- The fenced resource must make "compare token and write" atomic (a conditional update in its database).

## 7. Extensibility

| Change | Where |
|---|---|
| Shared (read) locks | Track a set of readers; writers wait until it empties. |
| Sessions instead of per-lock TTLs | One keep-alive per client renews all its grants. |
| Leader election | `acquireOrWait('leader/service')`; the holder is the leader. |
| Lock with a deadline | Waiters time out of the queue after a maximum wait. |

## 8. Common mistakes in LLD rounds

- Releasing by lock name only (a stale client releases someone else's lock).
- Using the client's clock for expiry.
- Waking all waiters on release.
- Per-lock counters for tokens that reset (tokens must never repeat).

See [HLD.md](HLD.md) for consensus, Redlock's limitations and alternatives to locking.
