# API Gateway: Low-Level Design

## 1. Scope for the LLD round

- **Routing:** patterns with path parameters (`/users/:id`) and prefix wildcards (`/static/*`); the most specific matching route wins.
- **Middleware pipeline:** API-key authentication (401 missing, 403 unknown), per-key **token-bucket rate limiting** (429), then routing (404).
- **Load balancing:** round robin over a service's instances, skipping instances whose **circuit breaker** is open.
- **Circuit breaker** per instance: closed -> open after N consecutive failures -> half-open after a cool-down -> closed on a successful trial (or open again on failure).
- **Retries** only for idempotent methods (GET), on a different instance; POST failures return 502 immediately.
- **Sticky canary routing:** a stable hash of the user decides whether they see the canary version.

Out of scope: TLS, request transformation, telemetry export, the control plane (HLD).

## 2. Entities and responsibilities

| Class | Responsibility |
|---|---|
| `Request`, `Response` | Method, path, headers; status, body, headers. |
| `Route`, `Router` | Pattern parsing, matching with parameters, specificity ordering. |
| `TokenBucket` | Per-key rate limit with lazy refill. |
| `CircuitBreaker` | Per-instance state machine. |
| `Instance` | A backend: ID, handler, breaker. |
| `Gateway` | The pipeline: auth, limits, routing, canary, balancing, calls, retries. |

```text
Request --> auth (api key -> user) --> TokenBucket[key] --> Router.match --> canary? (hash(user) % 100 < weight)
        --> pick instance: round robin, skip open breakers --> call --> success / failure updates breaker
        --> failure and GET? retry on the next instance : 502
```

## 3. Design decisions and why

- **Specificity ordering** (more segments, then more literal segments, wildcards last) so adding a specific route never gets shadowed by a general one, regardless of registration order.
- **Pipeline order:** cheap rejections first (auth, rate limit) before routing and upstream calls.
- **Breaker per instance** (not per service): one bad instance is isolated while healthy ones keep serving.
- **Retry only idempotent methods,** at most once, on another instance: retrying a POST can create duplicates; unbounded retries amplify outages.
- **Canary by hash of user ID:** a user sees one version consistently; the percentage is a configuration value.

## 4. The code

```dart
// ---------- Requests and routing ----------

class Request {
  Request(this.method, this.path, {Map<String, String>? headers}) : headers = headers ?? {};
  final String method;
  final String path;
  final Map<String, String> headers;
}

class Response {
  const Response(this.status, [this.body = '', this.headers = const {}]);
  final int status;
  final String body;
  final Map<String, String> headers;
  @override
  String toString() => '$status $body';
}

class Route {
  Route(this.pattern, this.service) : segments = pattern.split('/').where((s) => s.isNotEmpty).toList();
  final String pattern;
  final String service;
  final List<String> segments;

  bool get isPrefix => segments.isNotEmpty && segments.last == '*';
  int get literals => segments.where((s) => !s.startsWith(':') && s != '*').length;

  Map<String, String>? match(List<String> path) {
    if (isPrefix ? path.length < segments.length - 1 : path.length != segments.length) return null;
    final params = <String, String>{};
    for (var i = 0; i < segments.length; i++) {
      final s = segments[i];
      if (s == '*') return params;
      if (s.startsWith(':')) {
        params[s.substring(1)] = path[i];
      } else if (s != path[i]) {
        return null;
      }
    }
    return params;
  }
}

class Router {
  final _routes = <Route>[];

  void add(Route r) {
    _routes
      ..add(r)
      ..sort((a, b) {
        if (a.isPrefix != b.isPrefix) return a.isPrefix ? 1 : -1; // exact-length patterns first
        if (a.segments.length != b.segments.length) return b.segments.length.compareTo(a.segments.length);
        return b.literals.compareTo(a.literals);
      });
  }

  (Route, Map<String, String>)? match(String path) {
    final parts = path.split('/').where((s) => s.isNotEmpty).toList();
    for (final r in _routes) {
      final params = r.match(parts);
      if (params != null) return (r, params);
    }
    return null;
  }
}

// ---------- Rate limiting and circuit breaking ----------

class Clock {
  int nowMs = 0;
}

class TokenBucket {
  TokenBucket(this.capacity, this.refillPerSec, this.clock) : _tokens = capacity.toDouble(), _last = clock.nowMs;
  final int capacity;
  final double refillPerSec;
  final Clock clock;
  double _tokens;
  int _last;

  bool tryTake() {
    final now = clock.nowMs;
    _tokens = (_tokens + (now - _last) / 1000 * refillPerSec).clamp(0, capacity).toDouble();
    _last = now;
    if (_tokens < 1) return false;
    _tokens -= 1;
    return true;
  }
}

enum BreakerState { closed, open, halfOpen }

class CircuitBreaker {
  CircuitBreaker(this.clock, {this.failureThreshold = 3, this.cooldownMs = 10000});
  final Clock clock;
  final int failureThreshold;
  final int cooldownMs;
  var state = BreakerState.closed;
  var _failures = 0;
  var _openedAt = 0;

  bool allowRequest() {
    if (state == BreakerState.open && clock.nowMs - _openedAt >= cooldownMs) state = BreakerState.halfOpen;
    return state != BreakerState.open;
  }

  void onSuccess() {
    _failures = 0;
    state = BreakerState.closed;
  }

  void onFailure() {
    _failures++;
    if (state == BreakerState.halfOpen || _failures >= failureThreshold) {
      state = BreakerState.open;
      _openedAt = clock.nowMs;
    }
  }
}

class Instance {
  Instance(this.id, this.handler, Clock clock) : breaker = CircuitBreaker(clock);
  final String id;
  Response Function(Request) handler;
  final CircuitBreaker breaker;
  var calls = 0;
}

// ---------- Gateway ----------

int stableHash(String s) {
  var h = 0x811C9DC5;
  for (final c in s.codeUnits) {
    h = ((h ^ c) * 0x01000193) & 0xFFFFFFFF;
  }
  return h;
}

class Gateway {
  Gateway({
    required this.clock,
    required this.router,
    required this.services,
    required this.apiKeys,
    this.ratePerKey = 10,
    this.canary = const {},
  });

  final Clock clock;
  final Router router;
  final Map<String, List<Instance>> services;
  final Map<String, String> apiKeys; // key -> user ID
  final int ratePerKey;
  final Map<String, (String, int)> canary; // service -> (canary service, percent)
  final _buckets = <String, TokenBucket>{};
  final _cursor = <String, int>{};

  Response handle(Request req) {
    final key = req.headers['x-api-key'];
    if (key == null) return const Response(401, 'missing api key');
    final user = apiKeys[key];
    if (user == null) return const Response(403, 'unknown api key');
    if (!_buckets.putIfAbsent(key, () => TokenBucket(ratePerKey, ratePerKey.toDouble(), clock)).tryTake()) {
      return const Response(429, 'rate limited', {'retry-after': '1'});
    }
    final match = router.match(req.path);
    if (match == null) return const Response(404, 'no route');
    var service = match.$1.service;
    final c = canary[service];
    if (c != null && stableHash(user) % 100 < c.$2) service = c.$1;

    final attempts = req.method == 'GET' ? 2 : 1; // retry idempotent requests once
    for (var attempt = 0; attempt < attempts; attempt++) {
      final instance = _pick(service);
      if (instance == null) return const Response(503, 'no healthy instance');
      instance.calls++;
      final res = instance.handler(req);
      if (res.status < 500) {
        instance.breaker.onSuccess();
        return Response(res.status, res.body, {'x-instance': instance.id, 'x-params': '${match.$2}'});
      }
      instance.breaker.onFailure();
    }
    return const Response(502, 'upstream failed');
  }

  /// Round robin over instances whose breaker allows traffic.
  Instance? _pick(String service) {
    final list = services[service] ?? const <Instance>[];
    for (var i = 0; i < list.length; i++) {
      final idx = ((_cursor[service] ?? 0) + i) % list.length;
      if (list[idx].breaker.allowRequest()) {
        _cursor[service] = idx + 1;
        return list[idx];
      }
    }
    return null;
  }
}

// ---------- Self-checks ----------

void check(Object? actual, Object? expected) {
  if ('$actual' != '$expected') throw StateError('expected $expected, got $actual');
  print('ok: $actual');
}

void main() {
  final clock = Clock();
  Response ok(Request r) => Response(200, 'ok ${r.method}');
  Response fail(Request r) => const Response(503, 'down');
  Instance inst(String id) => Instance(id, ok, clock);
  final users = [inst('u1'), inst('u2'), inst('u3')];
  final router = Router()
    ..add(Route('/static/*', 'cdn'))
    ..add(Route('/users/:id', 'users'))
    ..add(Route('/users/:id/orders', 'orders'))
    ..add(Route('/users/me', 'profile'));
  final gw = Gateway(
    clock: clock,
    router: router,
    services: {
      'users': users,
      'orders': [inst('o1')],
      'profile': [inst('p1')],
      'cdn': [inst('c1')],
      'checkout': [inst('k1')],
      'checkout-v2': [inst('k2')],
    },
    apiKeys: {'key-a': 'alice', 'key-b': 'bob'},
    canary: {'checkout': ('checkout-v2', 10)},
  );
  final routerFor = Router()..add(Route('/checkout', 'checkout'));
  Request get(String path, [String key = 'key-a']) => Request('GET', path, headers: {'x-api-key': key});

  // Routing: specificity beats registration order.
  check(router.match('/users/42')!.$1.service, 'users');
  check(router.match('/users/42/orders')!.$2, {'id': '42'});
  check([router.match('/users/me')!.$1.service, router.match('/static/css/app.css')!.$1.service], ['profile', 'cdn']);

  // Auth and 404.
  check([
    gw.handle(Request('GET', '/users/1')),
    gw.handle(get('/users/1', 'stolen')),
    gw.handle(get('/nothing/here')),
  ], '[401 missing api key, 403 unknown api key, 404 no route]');

  // Round robin.
  check([for (var i = 0; i < 3; i++) gw.handle(get('/users/$i')).headers['x-instance']], ['u1', 'u2', 'u3']);

  // Retries: a GET hitting a failing instance is retried on the next one; a POST is not.
  users[0].handler = fail;
  final retried = gw.handle(get('/users/7'));
  check([retried.status, retried.headers['x-instance']], [200, 'u2']);
  clock.nowMs += 1000;
  gw.handle(get('/users/8')); // u3
  final post = gw.handle(Request('POST', '/users/9', headers: {'x-api-key': 'key-a'})); // u1 again, fails
  check(post.status, 502);

  // Circuit breaker: the third consecutive failure opens u1's circuit; it is skipped until the cool-down.
  gw.handle(get('/users/10')); // u2
  gw.handle(get('/users/11')); // u3
  gw.handle(get('/users/12')); // u1 fails (3rd failure) -> open; retried on u2
  check(users[0].breaker.state, BreakerState.open);
  final callsBefore = users[0].calls;
  clock.nowMs += 1000;
  for (var i = 0; i < 6; i++) {
    gw.handle(get('/users/x$i'));
  }
  check(users[0].calls, callsBefore); // no traffic while open
  users[0].handler = ok; // instance recovered
  clock.nowMs += 10000; // cool-down over: half-open allows a trial
  for (var i = 0; i < 3; i++) {
    gw.handle(get('/users/y$i'));
  }
  check([users[0].breaker.state, users[0].calls > callsBefore], [BreakerState.closed, true]);

  // Rate limit: 10 requests per second per key.
  clock.nowMs += 5000;
  final statuses = [for (var i = 0; i < 12; i++) gw.handle(get('/users/r', 'key-b')).status];
  check([statuses.where((s) => s == 200).length, statuses.last], [10, 429]);

  // Canary: about 10% of users, and always the same users.
  final canaryGw = Gateway(
    clock: clock,
    router: routerFor,
    services: gw.services,
    apiKeys: {for (var i = 0; i < 1000; i++) 'k$i': 'user$i'},
    canary: {'checkout': ('checkout-v2', 10)},
  );
  String version(int i) => canaryGw.handle(get('/checkout', 'k$i')).headers['x-instance']!;
  final onCanary = [for (var i = 0; i < 1000; i++) i].where((i) => version(i) == 'k2').toList();
  check(onCanary.length > 70 && onCanary.length < 130, true);
  clock.nowMs += 1000;
  check(onCanary.every((i) => version(i) == 'k2'), true); // sticky
}
```

## 5. Walkthrough

- `/users/me` matches the literal route even though `/users/:id` was registered first; `/users/42/orders` goes to the orders service with `id = 42`; `/static/...` falls to the prefix route.
- Missing and unknown keys are rejected before routing; unknown paths get 404.
- Three GETs rotate u1, u2, u3.
- With u1 failing, a GET is retried on u2 (200). A POST that lands on u1 fails with 502 and is not retried.
- After three consecutive failures u1's breaker opens. For the next six requests u1 gets no calls. After the 10 s cool-down a trial request reaches u1, which has recovered, and the breaker closes.
- Key `key-b` gets 10 requests in a second; the 11th and 12th are rejected with 429.
- About 10% of 1,000 users land on `checkout-v2`, and they stay there on later requests.

## 6. Concurrency

- Gateway nodes are stateless except for local caches, rate-limit buckets and breaker state; buckets and breakers are per node (approximate) or shared through Redis for global limits.
- Breaker and bucket updates are tiny critical sections: atomics or a lock per key.
- Configuration (routes, weights) is swapped atomically as an immutable snapshot, so in-flight requests finish with the old table.

## 7. Extensibility

| Change | Where |
|---|---|
| JWT auth | A middleware verifying signatures with cached public keys. |
| Least-outstanding-requests balancing | A `LoadBalancer` strategy using in-flight counters. |
| Retry budget | Count retries per service per window; stop retrying above the budget. |
| Request transformation | Middleware that rewrites headers/paths per route. |
| Per-route timeouts | Route configuration; enforce around the upstream call. |

## 8. Common mistakes in LLD rounds

- First-registered-wins routing.
- Retrying everything, including POST.
- One global breaker for a whole service when only one instance is bad.
- Random canary assignment per request.

See [HLD.md](HLD.md) for the data/control plane split, security and failure handling.
