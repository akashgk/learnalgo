# URL Shortener: Low-Level Design

The HLD decides **where** things run. The LLD designs **the code inside one service**: classes, interfaces, responsibilities, error handling, and how the design stays testable and extensible. Interviewers expect clean object-oriented design, the SOLID principles applied with judgment, and working code for the core flow.

## 1. Scope for the LLD round

- Shorten a long URL, with an optional custom alias and an optional time-to-live.
- Resolve a code to its long URL (counting the click), failing clearly for unknown or expired codes.
- Pluggable code generation (counter + base62, or random), pluggable storage, and a pluggable clock for tests.

Out of scope: HTTP layer, persistence technology, distributed ID allocation (HLD topics).

## 2. Entities and responsibilities

| Class | Responsibility |
|---|---|
| `ShortLink` | The data: code, long URL, creation and expiry time, click count. |
| `CodeGenerator` (interface) | Produce candidate codes. Implementations: `CounterCodeGenerator` (base62 of an increasing counter, never collides), `RandomCodeGenerator` (random base62, may collide). |
| `LinkRepository` (interface) | Store and look up links by code. `InMemoryLinkRepository` for this round; a database-backed one in production. |
| `Clock` (interface) | The current time. `FakeClock` makes expiry testable. |
| `UrlValidator` | Accept only absolute http(s) URLs. |
| `UrlShortener` | The service: orchestrates validation, generation (with collision retries), storage, and resolution. |
| Exceptions | `InvalidUrlException`, `AliasTakenException`, `LinkNotFoundException`, `LinkExpiredException`. |

```text
UrlShortener ----uses----> CodeGenerator      (CounterCodeGenerator | RandomCodeGenerator)
     |  \------uses------> LinkRepository     (InMemoryLinkRepository | DbLinkRepository)
     |   \-----uses------> Clock              (SystemClock | FakeClock)
     |    \----uses------> UrlValidator
     v
  ShortLink
```

## 3. Design decisions and why

- **Dependency injection of generator, repository and clock (Dependency Inversion).** The service depends on interfaces, so tests use a fake clock and an in-memory store, and production swaps in a database repository without touching the service.
- **Strategy pattern for code generation.** Counter-based and random generation are interchangeable strategies; the service handles collisions the same way for both (insert-if-absent with a bounded retry).
- **`saveIfAbsent` instead of `exists` + `save`.** Checking and then inserting is a race when two requests pick the same code concurrently. An atomic conditional insert is what databases offer (`INSERT ... IF NOT EXISTS`), so the repository interface mirrors it.
- **Typed exceptions** for each failure. The HTTP layer maps them to 400 / 409 / 404 / 410 without parsing messages.
- **Custom aliases are validated** to a different character rule (they must contain a `-` or be at least 8 characters) so they can never collide with generated 7-character codes. This is one simple way to partition the code space; mention alternatives.

## 4. The code

A complete, runnable program. `main()` exercises every path and throws if any check fails.

```dart
import 'dart:math';

// ---------- Domain ----------

class ShortLink {
  ShortLink({required this.code, required this.longUrl, required this.createdAt, this.expiresAt});

  final String code;
  final String longUrl;
  final DateTime createdAt;
  final DateTime? expiresAt;
  int clicks = 0;

  bool isExpired(DateTime now) => expiresAt != null && !now.isBefore(expiresAt!);
}

class InvalidUrlException implements Exception {
  InvalidUrlException(this.url);
  final String url;
  @override
  String toString() => 'InvalidUrlException: $url';
}

class AliasTakenException implements Exception {
  AliasTakenException(this.alias);
  final String alias;
}

class LinkNotFoundException implements Exception {
  LinkNotFoundException(this.code);
  final String code;
}

class LinkExpiredException implements Exception {
  LinkExpiredException(this.code);
  final String code;
}

// ---------- Ports (interfaces) ----------

abstract interface class Clock {
  DateTime now();
}

class SystemClock implements Clock {
  @override
  DateTime now() => DateTime.now();
}

class FakeClock implements Clock {
  FakeClock(this._now);
  DateTime _now;
  @override
  DateTime now() => _now;
  void advance(Duration d) => _now = _now.add(d);
}

abstract interface class CodeGenerator {
  String next();
}

abstract interface class LinkRepository {
  /// Atomically stores [link] unless its code is taken. Returns false if the code already exists.
  bool saveIfAbsent(ShortLink link);
  ShortLink? find(String code);
  void delete(String code);
}

// ---------- Code generation ----------

const _alphabet = '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';

/// Base62 encoding of a non-negative integer, left-padded to [width] characters.
String base62(int value, {int width = 7}) {
  final chars = <String>[];
  var v = value;
  do {
    chars.add(_alphabet[v % 62]);
    v ~/= 62;
  } while (v > 0);
  while (chars.length < width) {
    chars.add('0');
  }
  return chars.reversed.join();
}

/// Counter-based: unique by construction. In production the counter comes from a block of IDs
/// leased from a central allocator (see HLD section 7).
class CounterCodeGenerator implements CodeGenerator {
  CounterCodeGenerator({int start = 0}) : _next = start;
  int _next;
  @override
  String next() => base62(_next++);
}

/// Random 7-character codes: not enumerable, but may collide, so the caller must retry.
class RandomCodeGenerator implements CodeGenerator {
  RandomCodeGenerator([Random? random]) : _random = random ?? Random.secure();
  final Random _random;
  @override
  String next() => List.generate(7, (_) => _alphabet[_random.nextInt(62)]).join();
}

// ---------- Storage ----------

class InMemoryLinkRepository implements LinkRepository {
  final _links = <String, ShortLink>{};
  @override
  bool saveIfAbsent(ShortLink link) {
    if (_links.containsKey(link.code)) return false;
    _links[link.code] = link;
    return true;
  }

  @override
  ShortLink? find(String code) => _links[code];
  @override
  void delete(String code) => _links.remove(code);
}

// ---------- Service ----------

class UrlValidator {
  bool isValid(String url) {
    final uri = Uri.tryParse(url);
    return uri != null && uri.hasAuthority && (uri.scheme == 'http' || uri.scheme == 'https');
  }
}

class UrlShortener {
  UrlShortener({
    required CodeGenerator generator,
    required LinkRepository repository,
    required Clock clock,
    UrlValidator? validator,
    this.maxAttempts = 5,
  }) : _generator = generator,
       _repository = repository,
       _clock = clock,
       _validator = validator ?? UrlValidator();

  final CodeGenerator _generator;
  final LinkRepository _repository;
  final Clock _clock;
  final UrlValidator _validator;
  final int maxAttempts;

  static final _aliasPattern = RegExp(r'^[A-Za-z0-9-]{3,30}$');

  /// Returns the code of a new short link.
  String shorten(String longUrl, {String? alias, Duration? ttl}) {
    if (!_validator.isValid(longUrl)) throw InvalidUrlException(longUrl);
    final now = _clock.now();
    final expiresAt = ttl == null ? null : now.add(ttl);

    if (alias != null) {
      // Aliases must not look like generated 7-character codes: require a '-' or length >= 8.
      final looksGenerated = !alias.contains('-') && alias.length < 8;
      if (!_aliasPattern.hasMatch(alias) || looksGenerated) throw InvalidUrlException(alias);
      final link = ShortLink(code: alias, longUrl: longUrl, createdAt: now, expiresAt: expiresAt);
      if (!_repository.saveIfAbsent(link)) throw AliasTakenException(alias);
      return alias;
    }

    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final link = ShortLink(code: _generator.next(), longUrl: longUrl, createdAt: now, expiresAt: expiresAt);
      if (_repository.saveIfAbsent(link)) return link.code;
      // Collision (possible with random codes): try another code.
    }
    throw StateError('could not allocate a unique code after $maxAttempts attempts');
  }

  /// Returns the long URL and counts the click.
  String resolve(String code) {
    final link = _repository.find(code);
    if (link == null) throw LinkNotFoundException(code);
    if (link.isExpired(_clock.now())) throw LinkExpiredException(code);
    link.clicks++; // in production: publish a click event instead (HLD section 9)
    return link.longUrl;
  }

  int clicks(String code) => _repository.find(code)?.clicks ?? 0;
}

// ---------- Demo and self-checks ----------

/// A generator that returns scripted codes, to force a collision in the test.
class ScriptedGenerator implements CodeGenerator {
  ScriptedGenerator(this._codes);
  final List<String> _codes;
  var _i = 0;
  @override
  String next() => _codes[_i++];
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
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
  check(base62(0), '0000000');
  check(base62(61), '000000Z');
  check(base62(62), '0000010');
  check(base62(3521614606207), 'ZZZZZZZ'); // 62^7 - 1, the largest 7-character code

  final clock = FakeClock(DateTime.utc(2026));
  final service = UrlShortener(
    generator: CounterCodeGenerator(start: 125),
    repository: InMemoryLinkRepository(),
    clock: clock,
  );

  final code = service.shorten('https://example.com/a/very/long/path?q=1');
  check(code, '0000021'); // 125 = 2 * 62 + 1
  check(service.resolve(code), 'https://example.com/a/very/long/path?q=1');
  service.resolve(code);
  check(service.clicks(code), 2);

  expectThrows<InvalidUrlException>(() => service.shorten('not a url'));
  expectThrows<InvalidUrlException>(() => service.shorten('ftp://example.com'));
  expectThrows<LinkNotFoundException>(() => service.resolve('nope'));

  check(service.shorten('https://example.com/sale', alias: 'big-sale'), 'big-sale');
  expectThrows<AliasTakenException>(() => service.shorten('https://example.com/x', alias: 'big-sale'));
  expectThrows<InvalidUrlException>(() => service.shorten('https://example.com/x', alias: 'abc1234'));

  final temp = service.shorten('https://example.com/temp', ttl: const Duration(hours: 1));
  clock.advance(const Duration(minutes: 59));
  check(service.resolve(temp), 'https://example.com/temp');
  clock.advance(const Duration(minutes: 1));
  expectThrows<LinkExpiredException>(() => service.resolve(temp));

  // Random generation with a forced collision: the first candidate is taken, the second is used.
  final repo = InMemoryLinkRepository();
  final collide = UrlShortener(
    generator: ScriptedGenerator(['aaaaaaa', 'aaaaaaa', 'bbbbbbb']),
    repository: repo,
    clock: clock,
  );
  check(collide.shorten('https://a.com'), 'aaaaaaa');
  check(collide.shorten('https://b.com'), 'bbbbbbb');

  final random = UrlShortener(generator: RandomCodeGenerator(Random(1)), repository: repo, clock: clock);
  check(random.shorten('https://c.com').length, 7);
}
```

## 5. Walkthrough of the important parts

- **`base62`** builds digits least-significant first and reverses them; padding keeps every code exactly 7 characters (sorted codes then sort numerically, which is handy for range scans and debugging).
- **`shorten`** validates first (fail fast), handles aliases separately (no generator involved, conflict -> `AliasTakenException`), and otherwise tries up to `maxAttempts` generated codes with `saveIfAbsent`.
- **`resolve`** separates "not found" from "expired" so the HTTP layer can answer 404 vs 410.
- **`FakeClock`** turns expiry into a deterministic test: advance 59 minutes, still valid; one more minute, expired (`!now.isBefore(expiresAt)` makes the boundary inclusive).

## 6. Concurrency

- `CounterCodeGenerator` must hand out each number once. In a multi-threaded runtime, use an atomic increment (`AtomicLong.getAndIncrement` in Java). In Dart, a single isolate runs one task at a time, so the plain increment is safe there; across isolates or servers, use leased ID blocks.
- `saveIfAbsent` must be atomic in the real repository (a conditional insert), otherwise two concurrent requests could both "win" the same code.
- `clicks++` is a read-modify-write: in a real system, never do this on the hot row; publish an event (HLD section 9).

## 7. Extensibility

| Change | Where |
|---|---|
| Database storage | new `LinkRepository` implementation |
| Non-enumerable sequential codes | new `CodeGenerator` that scrambles the counter (multiply by an odd constant mod 62^7) |
| Same long URL returns the same code | a `findByLongUrl` method on the repository, checked in `shorten` |
| Link deletion by owner | `owner` field on `ShortLink`, ownership check in a `delete` method |
| Click analytics | inject a `ClickEventPublisher` and call it in `resolve` instead of `clicks++` |

## 8. Common mistakes in LLD rounds

- One giant class that validates, generates, stores and formats URLs (no separation of responsibilities).
- `if (!repo.exists(code)) repo.save(...)`: a race under concurrency.
- Using `DateTime.now()` directly inside the service (untestable expiry).
- Returning `null` for every failure instead of distinct errors.

See [HLD.md](HLD.md) for the distributed design around this service.
