# Rate Limiter: Low-Level Design

## 1. Scope for the LLD round

- A `RateLimiter` interface with several interchangeable algorithms: fixed window, sliding window log, sliding window counter, token bucket.
- Per-key state (each user or API key is limited separately).
- Rules per endpoint, and a request must pass every rule that applies.
- Deterministic tests through an injected clock.

Out of scope: the distributed store (HLD sections 6 and 7). The single-process classes here are what a Lua script or a gateway plugin would implement.

## 2. Entities and responsibilities

| Class | Responsibility |
|---|---|
| `Clock` | Current time in milliseconds; `FakeClock` for tests. |
| `RateLimiter` (interface) | `bool tryAcquire(String key)`. |
| `FixedWindowLimiter` | Counter per key per window. |
| `SlidingWindowLogLimiter` | Queue of timestamps per key; exact. |
| `SlidingWindowCounterLimiter` | Current and previous window counts per key; weighted estimate. |
| `TokenBucketLimiter` | Tokens and last-refill time per key; allows bursts. |
| `Rule` | Which requests it applies to, how to derive the key, and which limiter enforces it. |
| `RateLimitService` | Evaluates all matching rules for a request and returns a `Decision`. |

```text
RateLimitService --has many--> Rule --uses--> RateLimiter (interface)
                                                 ^   ^   ^   ^
                       FixedWindow  SlidingLog  SlidingCounter  TokenBucket
                                     all use --> Clock
```

## 3. Design decisions and why

- **Strategy pattern:** every algorithm implements `RateLimiter`, so rules can mix algorithms and new ones plug in without touching the service (Open/Closed principle).
- **State per key inside each limiter**, in a map. In production, this map is replaced by Redis hashes; keeping the per-key state small (two numbers for buckets and counters) is what makes that cheap.
- **Integer milliseconds from an injected clock:** no wall-clock reads inside algorithms, so every edge case (window boundaries, refills) is testable exactly.
- **Check all rules before consuming from any?** Simplest correct approach used here: evaluate rules in order and stop at the first rejection. A rejected request may still have consumed quota from earlier rules; mention this trade-off (an exact version needs a two-phase "peek then commit", which Redis Lua can do atomically).

## 4. The code

```dart
import 'dart:collection';

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

// ---------- Algorithms ----------

abstract interface class RateLimiter {
  bool tryAcquire(String key);
}

/// At most [limit] requests per aligned window of [windowMs]. Simple, but allows up to 2x [limit]
/// across a window boundary.
class FixedWindowLimiter implements RateLimiter {
  FixedWindowLimiter({required this.limit, required this.windowMs, required this.clock});
  final int limit, windowMs;
  final Clock clock;
  final _state = <String, (int window, int count)>{};

  @override
  bool tryAcquire(String key) {
    final window = clock.nowMs() ~/ windowMs;
    final (w, count) = _state[key] ?? (window, 0);
    final current = w == window ? count : 0; // a new window resets the count
    if (current >= limit) return false;
    _state[key] = (window, current + 1);
    return true;
  }
}

/// Exact: keeps the timestamps of accepted requests within the last [windowMs].
/// Memory O(limit) per key.
class SlidingWindowLogLimiter implements RateLimiter {
  SlidingWindowLogLimiter({required this.limit, required this.windowMs, required this.clock});
  final int limit, windowMs;
  final Clock clock;
  final _logs = <String, Queue<int>>{};

  @override
  bool tryAcquire(String key) {
    final now = clock.nowMs();
    final log = _logs.putIfAbsent(key, Queue<int>.new);
    while (log.isNotEmpty && log.first <= now - windowMs) {
      log.removeFirst(); // outside the window
    }
    if (log.length >= limit) return false;
    log.addLast(now);
    return true;
  }
}

/// Approximation with two counters: count = previous * (portion of the previous window still inside the
/// sliding window) + current. Assumes requests in the previous window were evenly spread.
class SlidingWindowCounterLimiter implements RateLimiter {
  SlidingWindowCounterLimiter({required this.limit, required this.windowMs, required this.clock});
  final int limit, windowMs;
  final Clock clock;
  final _state = <String, (int window, int previous, int current)>{};

  @override
  bool tryAcquire(String key) {
    final now = clock.nowMs();
    final window = now ~/ windowMs;
    var (w, previous, current) = _state[key] ?? (window, 0, 0);
    if (window == w + 1) {
      (previous, current) = (current, 0); // moved into the next window
    } else if (window > w + 1) {
      (previous, current) = (0, 0); // idle for more than a whole window
    }
    final elapsedInWindow = now - window * windowMs;
    final previousWeight = (windowMs - elapsedInWindow) / windowMs;
    final estimated = previous * previousWeight + current;
    if (estimated >= limit) {
      _state[key] = (window, previous, current);
      return false;
    }
    _state[key] = (window, previous, current + 1);
    return true;
  }
}

/// Bucket of [capacity] tokens refilled continuously at [refillPerSecond]. Each request takes one token.
/// Allows bursts up to [capacity] and a long-run rate of [refillPerSecond].
class TokenBucketLimiter implements RateLimiter {
  TokenBucketLimiter({required this.capacity, required this.refillPerSecond, required this.clock});
  final int capacity;
  final double refillPerSecond;
  final Clock clock;
  final _state = <String, (double tokens, int lastMs)>{};

  @override
  bool tryAcquire(String key) {
    final now = clock.nowMs();
    final (tokens, last) = _state[key] ?? (capacity.toDouble(), now);
    // Lazy refill: add the tokens earned since the last request, capped at capacity.
    final refilled = (tokens + (now - last) * refillPerSecond / 1000).clamp(0, capacity).toDouble();
    if (refilled < 1) {
      _state[key] = (refilled, now);
      return false;
    }
    _state[key] = (refilled - 1, now);
    return true;
  }
}

// ---------- Rules and service ----------

class Request {
  Request({required this.endpoint, required this.apiKey, required this.ip});
  final String endpoint, apiKey, ip;
}

class Rule {
  Rule({required this.name, required this.appliesTo, required this.keyOf, required this.limiter});
  final String name;
  final bool Function(Request) appliesTo;
  final String Function(Request) keyOf;
  final RateLimiter limiter;
}

class Decision {
  Decision.allowed() : allowed = true, rejectedBy = null;
  Decision.rejected(this.rejectedBy) : allowed = false;
  final bool allowed;
  final String? rejectedBy;
}

class RateLimitService {
  RateLimitService(this.rules);
  final List<Rule> rules;

  Decision check(Request request) {
    for (final rule in rules) {
      if (!rule.appliesTo(request)) continue;
      if (!rule.limiter.tryAcquire('${rule.name}:${rule.keyOf(request)}')) {
        return Decision.rejected(rule.name);
      }
    }
    return Decision.allowed();
  }
}

// ---------- Self-checks ----------

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

List<bool> burst(RateLimiter limiter, String key, int n) => [for (var i = 0; i < n; i++) limiter.tryAcquire(key)];

void main() {
  // Fixed window: 3 per second, and the boundary weakness.
  final c1 = FakeClock(500);
  final fixed = FixedWindowLimiter(limit: 3, windowMs: 1000, clock: c1);
  check(burst(fixed, 'u', 4), [true, true, true, false]);
  c1.advance(499); // t = 999, still the same window
  check(fixed.tryAcquire('u'), false);
  c1.advance(1); // t = 1000: new window, 3 more allowed right after the previous 3
  check(burst(fixed, 'u', 3), [true, true, true]);
  check(fixed.tryAcquire('other'), true); // keys are independent

  // Sliding window log: exactly 3 within any 1000 ms.
  final c2 = FakeClock(0);
  final log = SlidingWindowLogLimiter(limit: 3, windowMs: 1000, clock: c2);
  check(burst(log, 'u', 3), [true, true, true]);
  c2.advance(999);
  check(log.tryAcquire('u'), false); // the first request is still inside the window
  c2.advance(1); // t = 1000: the requests at t = 0 leave the window
  check(burst(log, 'u', 4), [true, true, true, false]);

  // Sliding window counter: 10 in the previous window, halfway through the current one.
  final c3 = FakeClock(0);
  final counter = SlidingWindowCounterLimiter(limit: 10, windowMs: 1000, clock: c3);
  check(burst(counter, 'u', 10).every((x) => x), true);
  c3.advance(1500); // previous window had 10, weight 0.5 -> estimate 5 + current
  check(burst(counter, 'u', 6), [true, true, true, true, true, false]);
  c3.advance(1500); // t = 3000: more than a whole idle window, state resets
  check(burst(counter, 'u', 10).every((x) => x), true);

  // Token bucket: burst of 5, then 2 tokens per second.
  final c4 = FakeClock(0);
  final bucket = TokenBucketLimiter(capacity: 5, refillPerSecond: 2, clock: c4);
  check(burst(bucket, 'u', 6), [true, true, true, true, true, false]);
  c4.advance(500); // +1 token
  check(burst(bucket, 'u', 2), [true, false]);
  c4.advance(10000); // refill is capped at capacity
  check(burst(bucket, 'u', 6), [true, true, true, true, true, false]);

  // Service with two rules: per-key global limit and a stricter per-IP login limit.
  final c5 = FakeClock(0);
  final service = RateLimitService([
    Rule(
      name: 'login-by-ip',
      appliesTo: (r) => r.endpoint == '/login',
      keyOf: (r) => r.ip,
      limiter: FixedWindowLimiter(limit: 2, windowMs: 60000, clock: c5),
    ),
    Rule(
      name: 'global-by-key',
      appliesTo: (_) => true,
      keyOf: (r) => r.apiKey,
      limiter: TokenBucketLimiter(capacity: 3, refillPerSecond: 1, clock: c5),
    ),
  ]);
  Request req(String endpoint, String key, String ip) => Request(endpoint: endpoint, apiKey: key, ip: ip);
  check(service.check(req('/login', 'k1', '1.1.1.1')).allowed, true);
  check(service.check(req('/login', 'k2', '1.1.1.1')).allowed, true);
  check(service.check(req('/login', 'k3', '1.1.1.1')).rejectedBy, 'login-by-ip');
  check(service.check(req('/search', 'k1', '1.1.1.1')).allowed, true); // k1 token 2 of 3
  check(service.check(req('/search', 'k1', '9.9.9.9')).allowed, true); // k1 token 3 of 3, IP does not matter
  check(service.check(req('/search', 'k1', '9.9.9.9')).rejectedBy, 'global-by-key');
  c5.advance(1000); // one token back
  check(service.check(req('/search', 'k1', '9.9.9.9')).allowed, true);
}
```

## 5. Walkthrough

- **Fixed window** stores `(window index, count)`. A different window index means the old count no longer applies. The test shows the classic weakness: 3 requests at t = 500 and 3 more at t = 1000, so 6 within 500 ms for a limit of 3 per second.
- **Sliding window log** evicts timestamps `<= now - window` from the front of a queue; the queue length is the exact count. Memory grows with the limit.
- **Sliding window counter** rolls `current` into `previous` when the window advances, and resets both after a full idle window. At t = 1500, the previous window (10 requests) overlaps the sliding window by half, so the estimate starts at 5 and 5 more requests fit.
- **Token bucket** refills lazily on each request: no timers. The refill is capped at `capacity`, which is what limits bursts after idle periods.
- **`RateLimitService`** namespaces keys by rule name, so two rules never share state for the same user.

## 6. Concurrency

Every `tryAcquire` is a read-modify-write on per-key state. In a multithreaded server, guard each key (striped locks, or `ConcurrentHashMap.compute` in Java) or make the state update a single atomic step. In the distributed version, that atomic step is the Redis Lua script (HLD section 6). Dart isolates do not share memory, so within one isolate these classes are safe as written.

## 7. Extensibility

| Change | Where |
|---|---|
| Redis-backed state | Implement `RateLimiter` with one Lua script call per `tryAcquire`; the service is unchanged. |
| Return `Retry-After` | Make `tryAcquire` return a result with `remaining` and `retryAfterMs` (token bucket: `(1 - tokens) / rate`). |
| Weighted requests (an expensive call costs 5 tokens) | `tryAcquire(key, cost)`. |
| Memory cleanup | Evict keys idle for more than one window (TTL in Redis; a periodic sweep in memory). |
| Rules from configuration | Build `Rule` objects from a config file; reload atomically by swapping the list. |

## 8. Common mistakes in LLD rounds

- One class with an `if (algorithm == "token")` switch instead of a strategy interface.
- Timer threads that refill buckets every second for every key (wasteful); lazy refill is enough.
- Forgetting to cap tokens at capacity.
- Sharing one counter across different rules for the same user.

See [HLD.md](HLD.md) for the distributed design.
