# Photo Sharing: Low-Level Design

## 1. Scope for the LLD round

- **Pre-signed upload grants:** the server signs (user, object key, content type, maximum size, expiry); the storage side verifies the signature and the constraints. Tampering with any field invalidates it.
- **Variant sizing:** fit the image inside 150 / 640 / 1080 px boxes keeping the aspect ratio, never upscaling.
- **Likes:** an idempotent per-post set of user IDs plus a **sharded counter** for the count; the counter always matches the set.
- **Stories** that expire 24 hours after posting (filtered lazily, purged in the background).
- **Hashtag index:** tags extracted from captions, newest posts first.

Out of scope: the feed (06), real cryptography (HMAC-SHA256 in production), moderation (HLD).

## 2. Entities and responsibilities

| Class | Responsibility |
|---|---|
| `UploadGrant`, `UploadSigner` | Issue and verify scoped, expiring upload permissions. |
| `variantSizes` | Output dimensions per variant. |
| `ShardedCounter` | Count spread over N shards; random shard per increment; sum on read. |
| `LikeService` | Like set per post; counter per post; like/unlike idempotent. |
| `StoryService` | Stories with expiry; active stories per user; purge. |
| `HashtagIndex` | Tag extraction and per-tag recent posts. |

```text
client --grant(user, type, size)--> UploadSigner --signed URL--> client --PUT bytes--> storage: verify(grant)
post created --> variantSizes() for processing workers --> HashtagIndex.add(caption)
like/unlike --> LikeService: Set<user> per post (truth) + ShardedCounter (fast, contention-free count)
```

## 3. Design decisions and why

- **Signed grants instead of server-side proxying:** the upload goes straight to storage; the signature makes the grant unforgeable and binds every constraint to it.
- **Verify size and type at storage time,** not only when issuing: the client could lie.
- **The like set is the truth, the counter is derived:** idempotency comes from the set ("liking twice" is a no-op), and the counter only changes when the set changes.
- **Sharded counter:** each increment touches one of N shards, so N writers rarely contend; reading costs N small reads (cached).
- **Lazy expiry for stories:** reads filter by `expiresAt`, so correctness does not depend on the purge job.

## 4. The code

```dart
import 'dart:math';

// ---------- Upload grants ----------

/// Stand-in for HMAC-SHA256 over the canonical string.
String sign(String data, String secret) {
  var h = 0x811C9DC5;
  for (final c in '$secret|$data|$secret'.codeUnits) {
    h = ((h ^ c) * 0x01000193) & 0xFFFFFFFF;
  }
  return h.toRadixString(16).padLeft(8, '0');
}

class UploadGrant {
  const UploadGrant(this.userId, this.key, this.contentType, this.maxBytes, this.expiresAt, this.signature);
  final String userId;
  final String key;
  final String contentType;
  final int maxBytes;
  final int expiresAt;
  final String signature;

  String get canonical => '$userId|$key|$contentType|$maxBytes|$expiresAt';
  String get url => 'https://media.example.com/$key?exp=$expiresAt&max=$maxBytes&sig=$signature';

  UploadGrant copyWith({int? maxBytes}) =>
      UploadGrant(userId, key, contentType, maxBytes ?? this.maxBytes, expiresAt, signature);
}

class UploadRejected implements Exception {
  UploadRejected(this.reason);
  final String reason;
  @override
  String toString() => reason;
}

class UploadSigner {
  UploadSigner(this._secret);
  final String _secret;
  var _next = 1;

  UploadGrant grant(String userId, String contentType, int maxBytes, {required int now, int ttlSec = 600}) {
    if (!const {'image/jpeg', 'image/png', 'image/heic'}.contains(contentType))
      throw UploadRejected('type not allowed');
    final key = 'originals/$userId/${_next++}';
    final unsigned = UploadGrant(userId, key, contentType, maxBytes, now + ttlSec, '');
    return UploadGrant(userId, key, contentType, maxBytes, now + ttlSec, sign(unsigned.canonical, _secret));
  }

  /// What the storage service checks when the bytes arrive.
  void verify(UploadGrant g, {required int now, required int bytes, required String contentType}) {
    if (sign(g.canonical, _secret) != g.signature) throw UploadRejected('bad signature');
    if (now > g.expiresAt) throw UploadRejected('expired');
    if (bytes > g.maxBytes) throw UploadRejected('too large');
    if (contentType != g.contentType) throw UploadRejected('content type mismatch');
  }
}

// ---------- Variants ----------

(int, int) fitWithin(int w, int h, int box) {
  final longest = max(w, h);
  if (longest <= box) return (w, h); // never upscale
  return ((w * box / longest).round(), (h * box / longest).round());
}

Map<String, (int, int)> variantSizes(int w, int h) => {
  for (final MapEntry(key: name, value: box) in const {'thumb': 150, 'medium': 640, 'full': 1080}.entries)
    name: fitWithin(w, h, box),
};

// ---------- Likes ----------

class ShardedCounter {
  ShardedCounter(int shards, this._random) : _shards = List.filled(shards, 0), writesPerShard = List.filled(shards, 0);
  final List<int> _shards;
  final List<int> writesPerShard;
  final Random _random;

  void add(int delta) {
    final i = _random.nextInt(_shards.length); // spread writers over shards
    _shards[i] += delta;
    writesPerShard[i]++;
  }

  int get value => _shards.fold(0, (a, b) => a + b);
}

class LikeService {
  LikeService({this.shardsPerCounter = 8, int seed = 1}) : _random = Random(seed);
  final int shardsPerCounter;
  final Random _random;
  final _likedBy = <String, Set<String>>{};
  final _counters = <String, ShardedCounter>{};

  ShardedCounter _counter(String post) => _counters.putIfAbsent(post, () => ShardedCounter(shardsPerCounter, _random));

  bool like(String post, String user) {
    final added = _likedBy.putIfAbsent(post, () => {}).add(user);
    if (added) _counter(post).add(1); // only real changes move the count
    return added;
  }

  bool unlike(String post, String user) {
    final removed = _likedBy[post]?.remove(user) ?? false;
    if (removed) _counter(post).add(-1);
    return removed;
  }

  int count(String post) => _counters[post]?.value ?? 0;
  bool hasLiked(String post, String user) => _likedBy[post]?.contains(user) ?? false;
  int exactCount(String post) => _likedBy[post]?.length ?? 0;
  ShardedCounter? counterOf(String post) => _counters[post];
}

// ---------- Stories and hashtags ----------

class Story {
  Story(this.id, this.userId, this.createdAt) : expiresAt = createdAt + 24 * 3600;
  final String id;
  final String userId;
  final int createdAt;
  final int expiresAt;
}

class StoryService {
  final _stories = <Story>[];
  void add(Story s) => _stories.add(s);
  List<String> active(String userId, int now) => [
    for (final s in _stories)
      if (s.userId == userId && now < s.expiresAt) s.id,
  ];
  int purge(int now) {
    final before = _stories.length;
    _stories.removeWhere((s) => now >= s.expiresAt);
    return before - _stories.length;
  }
}

class HashtagIndex {
  final _byTag = <String, List<(int, String)>>{};
  static List<String> extract(String caption) =>
      {for (final m in RegExp(r'#(\w+)').allMatches(caption)) m[1]!.toLowerCase()}.toList();

  void add(String postId, String caption, int createdAt) {
    for (final tag in extract(caption)) {
      _byTag.putIfAbsent(tag, () => []).add((createdAt, postId));
    }
  }

  List<String> recent(String tag, {int limit = 10}) {
    final posts = [...?_byTag[tag.toLowerCase()]]..sort((a, b) => b.$1.compareTo(a.$1));
    return [for (final p in posts.take(limit)) p.$2];
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
  // Upload grants.
  final signer = UploadSigner('server-secret');
  final g = signer.grant('u1', 'image/jpeg', 5000000, now: 1000);
  check(g.url.startsWith('https://media.example.com/originals/u1/1?exp=1600&max=5000000&sig='), true);
  signer.verify(g, now: 1200, bytes: 3000000, contentType: 'image/jpeg');
  String reason(void Function() f) {
    try {
      f();
      return 'accepted';
    } on UploadRejected catch (e) {
      return e.reason;
    }
  }

  check(
    [
      reason(() => signer.verify(g, now: 1601, bytes: 1, contentType: 'image/jpeg')),
      reason(() => signer.verify(g, now: 1200, bytes: 6000000, contentType: 'image/jpeg')),
      reason(() => signer.verify(g, now: 1200, bytes: 1, contentType: 'image/png')),
      reason(
        () => signer.verify(g.copyWith(maxBytes: 999999999), now: 1200, bytes: 6000000, contentType: 'image/jpeg'),
      ),
    ],
    ['expired', 'too large', 'content type mismatch', 'bad signature'],
  );
  expectThrows<UploadRejected>(() => signer.grant('u1', 'application/x-sh', 10, now: 0));

  // Variants keep the aspect ratio and never upscale.
  check(variantSizes(4000, 3000), {'thumb': (150, 113), 'medium': (640, 480), 'full': (1080, 810)});
  check(variantSizes(600, 900), {'thumb': (100, 150), 'medium': (427, 640), 'full': (600, 900)});

  // Likes: idempotent, and the sharded counter always equals the set size.
  final likes = LikeService();
  check([likes.like('p1', 'alice'), likes.like('p1', 'alice'), likes.like('p1', 'bob')], [true, false, true]);
  check(
    [likes.count('p1'), likes.unlike('p1', 'carol'), likes.unlike('p1', 'alice'), likes.count('p1')],
    [2, false, true, 1],
  );
  final rng = Random(4);
  for (var i = 0; i < 5000; i++) {
    final user = 'u${rng.nextInt(800)}';
    if (rng.nextInt(4) == 0) {
      likes.unlike('viral', user);
    } else {
      likes.like('viral', user);
    }
  }
  final counter = likes.counterOf('viral')!;
  check(likes.count('viral') == likes.exactCount('viral'), true);
  check(counter.writesPerShard.every((w) => w > 100), true); // writes were spread across all 8 shards

  // Stories expire after 24 hours.
  final stories = StoryService()
    ..add(Story('s1', 'alice', 0))
    ..add(Story('s2', 'alice', 20 * 3600))
    ..add(Story('s3', 'bob', 1000));
  check(stories.active('alice', 23 * 3600), ['s1', 's2']);
  check(stories.active('alice', 24 * 3600), ['s2']);
  check([stories.purge(25 * 3600), stories.active('bob', 25 * 3600)], [2, '[]']);

  // Hashtags.
  final tags = HashtagIndex()
    ..add('p1', 'Sunset at the beach #Sunset #travel', 100)
    ..add('p2', 'Morning run #fitness', 200)
    ..add('p3', 'Another #sunset, #sunset again', 300);
  check(HashtagIndex.extract('Another #sunset, #sunset again'), ['sunset']);
  check(
    [tags.recent('SUNSET'), tags.recent('travel'), tags.recent('cats')],
    [
      ['p3', 'p1'],
      ['p1'],
      <String>[],
    ],
  );
}
```

## 5. Walkthrough

- The grant for `u1` expires at 1600 and allows 5 MB of JPEG. A valid upload at 1200 passes. Uploading after expiry, more bytes, a different type, or with a grant whose `max` was edited to a huge value all fail; the last one because the signature no longer matches the fields.
- A 4000 x 3000 photo becomes 150 x 113, 640 x 480 and 1080 x 810. A 600 x 900 portrait is not upscaled for `full`.
- Alice liking twice changes nothing the second time; unliking someone who never liked is a no-op.
- After 5,000 random likes and unlikes on a "viral" post, the sharded count equals the size of the like set, and every one of the 8 shards received writes.
- Stories: at 23 h both of Alice's stories are visible; at exactly 24 h, `s1` is gone. The purge at 25 h removes `s1` and `s3`.
- Hashtags are case-insensitive and deduplicated per post; `#sunset` returns p3 then p1 (newest first).

## 6. Concurrency

- Likes: the set insert is the idempotency check, so it must be atomic (`INSERT ... IF NOT EXISTS` in Cassandra, `SADD` in Redis returns whether it was new). Increment the counter only when the insert reported a change; if the counter write fails, a periodic reconcile job recomputes counts from the set.
- Sharded counters exist precisely so concurrent increments rarely touch the same shard; each shard update is an atomic `INCRBY`.
- Grants need no shared state: verification is a pure function of the grant and the secret.

## 7. Extensibility

| Change | Where |
|---|---|
| Real signatures | HMAC-SHA256 with key rotation (key ID in the grant). |
| More variants / WebP and AVIF | Extend `variantSizes` and the encoder list in processing workers. |
| Approximate counts at extreme scale | Aggregate like events in a stream job; show "1.2M". |
| Top posts per hashtag | Score by engagement and recency instead of time only. |
| Close-friends stories | An audience list checked in `active`. |

## 8. Common mistakes in LLD rounds

- Counting likes without a set (double counting on retries).
- Trusting client-reported size and type.
- Upscaling small images.
- Relying only on a cron job to hide expired stories.

See [HLD.md](HLD.md) for the upload pipeline, storage tiers and CDN delivery.
