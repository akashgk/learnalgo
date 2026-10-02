# News Feed: Low-Level Design

## 1. Scope for the LLD round

- Users publish posts and follow other users.
- Home feed: posts from followees and the user's own posts, newest first, **cursor-paginated**.
- **Hybrid fan-out:** posts by normal authors are pushed into followers' timeline caches; posts by celebrities (followers above a threshold) are pulled and merged at read time.
- Timeline caches are **capped**.
- Following someone backfills their recent posts; unfollows and deletes are filtered at read time.
- **Time-sortable IDs** (Snowflake style), so ordering and pagination need only the ID.

Out of scope: ranking, media, distributed workers (HLD).

## 2. Entities and responsibilities

| Class | Responsibility |
|---|---|
| `SnowflakeIds` | 64-bit IDs: `timestamp ms | machine | sequence`; increasing in time. |
| `Post` | ID, author, text. |
| `PostStore` | Posts by ID, plus each author's posts in order. |
| `FollowGraph` | Both directions: followers of X, followees of X. |
| `TimelineCache` | Per user, a capped list of post IDs in descending order. |
| `FeedPage` | Posts plus `nextCursor`. |
| `FeedService` | Publish (fan-out policy), follow/unfollow, delete, `feed(user, cursor, limit)`. |

```text
FeedService --uses--> PostStore, FollowGraph, TimelineCache, SnowflakeIds
     |
     publish: author has < threshold followers ? push ID into each follower's TimelineCache : nothing
     feed:    TimelineCache(user)  merge  recent posts of followed celebrities  -> filter -> page
```

## 3. Design decisions and why

- **Timelines store IDs, not posts.** Small cache entries; edits and deletes are visible immediately because posts are fetched (hydrated) at read time.
- **The celebrity check happens at publish time** by follower count. The read path asks the graph for the user's followed celebrities: few per user, and their posts are hot in any cache.
- **Read-time filtering** for deletes and unfollows: removing a post from millions of timelines is expensive; skipping it during hydration is free.
- **Cursor = the last post ID returned.** The next page asks for IDs strictly below it. New posts at the top never shift later pages (offset pagination would repeat items).
- **Snowflake-style IDs**: comparing IDs compares creation times (to the millisecond), with the sequence breaking ties. No separate timestamp sort needed when merging sources.
- **Separate stores behind small classes** so each can be swapped for Redis / a database without touching `FeedService`.

## 4. The code

```dart
// ---------- IDs ----------

abstract interface class Clock {
  int nowMs();
}

class FakeClock implements Clock {
  FakeClock(this._now);
  int _now;
  @override
  int nowMs() => _now;
  void advance(int ms) => _now += ms;
}

/// 41 bits of milliseconds since a custom epoch, 10 bits of machine ID, 12 bits of sequence.
class SnowflakeIds {
  SnowflakeIds({required this.clock, required this.machineId, this.epochMs = 1704067200000}) {
    if (machineId < 0 || machineId > 1023) throw ArgumentError.value(machineId, 'machineId');
  }

  final Clock clock;
  final int machineId;
  final int epochMs;
  var _lastMs = -1;
  var _seq = 0;

  int next() {
    var ms = clock.nowMs() - epochMs;
    if (ms < _lastMs) ms = _lastMs; // clock went backwards: never reuse an earlier timestamp
    if (ms == _lastMs) {
      _seq = (_seq + 1) & 0xFFF;
      if (_seq == 0) ms = _lastMs + 1; // 4096 IDs in one ms: borrow the next millisecond
    } else {
      _seq = 0;
    }
    _lastMs = ms;
    return (ms << 22) | (machineId << 12) | _seq;
  }

  static int timestampOf(int id, {int epochMs = 1704067200000}) => (id >> 22) + epochMs;
}

// ---------- Stores ----------

class Post {
  const Post(this.id, this.authorId, this.text);
  final int id;
  final String authorId;
  final String text;
  @override
  String toString() => '$authorId: $text';
}

class PostStore {
  final _byId = <int, Post>{};
  final _byAuthor = <String, List<int>>{}; // ascending IDs

  void save(Post p) {
    _byId[p.id] = p;
    _byAuthor.putIfAbsent(p.authorId, () => []).add(p.id);
  }

  Post? get(int id) => _byId[id];

  bool delete(int id) {
    final p = _byId.remove(id);
    if (p == null) return false;
    _byAuthor[p.authorId]!.remove(id);
    return true;
  }

  /// Newest first, IDs below [beforeId] (exclusive), at most [limit].
  List<int> recentByAuthor(String authorId, {int? beforeId, required int limit}) {
    final ids = _byAuthor[authorId] ?? const <int>[];
    final out = <int>[];
    for (var i = ids.length - 1; i >= 0 && out.length < limit; i--) {
      if (beforeId == null || ids[i] < beforeId) out.add(ids[i]);
    }
    return out;
  }
}

class FollowGraph {
  final _followers = <String, Set<String>>{};
  final _followees = <String, Set<String>>{};

  bool follow(String follower, String followee) {
    if (follower == followee) return false;
    _followers.putIfAbsent(followee, () => {}).add(follower);
    return _followees.putIfAbsent(follower, () => {}).add(followee);
  }

  bool unfollow(String follower, String followee) {
    _followers[followee]?.remove(follower);
    return _followees[follower]?.remove(followee) ?? false;
  }

  Set<String> followersOf(String user) => _followers[user] ?? const {};
  Set<String> followeesOf(String user) => _followees[user] ?? const {};
}

class TimelineCache {
  TimelineCache({required this.maxEntries});
  final int maxEntries;
  final _timelines = <String, List<int>>{}; // descending IDs

  /// Insert keeping descending order (fan-out can deliver slightly out of order), then trim.
  void add(String userId, int postId) {
    final list = _timelines.putIfAbsent(userId, () => []);
    var lo = 0, hi = list.length;
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      if (list[mid] > postId) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    if (lo < list.length && list[lo] == postId) return; // already there
    list.insert(lo, postId);
    if (list.length > maxEntries) list.removeRange(maxEntries, list.length);
  }

  List<int> idsBefore(String userId, int? beforeId) =>
      (_timelines[userId] ?? const <int>[]).where((id) => beforeId == null || id < beforeId).toList();

  int sizeOf(String userId) => _timelines[userId]?.length ?? 0;
}

// ---------- Feed service ----------

class FeedPage {
  const FeedPage(this.posts, this.nextCursor);
  final List<Post> posts;
  final int? nextCursor; // null: no more pages
}

class FeedService {
  FeedService({
    required SnowflakeIds ids,
    required this.celebrityThreshold,
    int timelineSize = 800,
    this.backfillOnFollow = 20,
  }) : _ids = ids,
       timelines = TimelineCache(maxEntries: timelineSize);

  final SnowflakeIds _ids;
  final int celebrityThreshold;
  final int backfillOnFollow;
  final posts = PostStore();
  final graph = FollowGraph();
  final TimelineCache timelines;
  var fanoutWrites = 0;

  bool isCelebrity(String user) => graph.followersOf(user).length >= celebrityThreshold;

  Post publish(String authorId, String text) {
    final post = Post(_ids.next(), authorId, text);
    posts.save(post);
    timelines.add(authorId, post.id); // own posts appear in own feed
    if (!isCelebrity(authorId)) {
      // In production: an event on a queue, consumed by fan-out workers in batches.
      for (final follower in graph.followersOf(authorId)) {
        timelines.add(follower, post.id);
        fanoutWrites++;
      }
    }
    return post;
  }

  void follow(String follower, String followee) {
    if (!graph.follow(follower, followee) || isCelebrity(followee)) return;
    for (final id in posts.recentByAuthor(followee, limit: backfillOnFollow)) {
      timelines.add(follower, id);
    }
  }

  void unfollow(String follower, String followee) => graph.unfollow(follower, followee);

  bool deletePost(int postId) => posts.delete(postId);

  FeedPage feed(String userId, {int? cursor, int limit = 20}) {
    final followees = graph.followeesOf(userId);
    // 1. Pushed IDs, 2. pulled celebrity IDs. Taking `limit + 1` per celebrity is enough for one page.
    final candidates = <int>{
      ...timelines.idsBefore(userId, cursor),
      for (final celeb in followees.where(isCelebrity))
        ...posts.recentByAuthor(celeb, beforeId: cursor, limit: limit + 1),
    }.toList()..sort((a, b) => b.compareTo(a));

    // 3. Hydrate and filter: deleted posts and unfollowed authors disappear here.
    final page = <Post>[];
    for (final id in candidates) {
      final post = posts.get(id);
      if (post == null) continue;
      if (post.authorId != userId && !followees.contains(post.authorId)) continue;
      page.add(post);
      if (page.length == limit) break;
    }
    // A full page may have more after it; a short page is the end.
    return FeedPage(page, page.length == limit ? page.last.id : null);
  }
}

// ---------- Self-checks ----------

void check(Object? actual, Object? expected) {
  if ('$actual' != '$expected') throw StateError('expected $expected, got $actual');
  print('ok: $actual');
}

void main() {
  // IDs: increasing, decodable, unique within one millisecond and across a clock step back.
  final idClock = FakeClock(1704067200000 + 5000);
  final gen = SnowflakeIds(clock: idClock, machineId: 7);
  final a = gen.next(), b = gen.next();
  idClock.advance(-3); // clock skew
  final c = gen.next();
  check([a < b, b < c], [true, true]);
  check(SnowflakeIds.timestampOf(a), 1704067205000);
  check((a >> 12) & 0x3FF, 7);

  final clock = FakeClock(1704067200000);
  final feed = FeedService(ids: SnowflakeIds(clock: clock, machineId: 1), celebrityThreshold: 3, timelineSize: 5);
  void tick() => clock.advance(1000);

  // alice follows bob, carol and celeb; celeb has 3 followers, so celeb is a celebrity.
  for (final f in ['alice', 'fan1', 'fan2']) {
    feed.follow(f, 'celeb');
  }
  feed
    ..follow('alice', 'bob')
    ..follow('alice', 'carol');
  check(feed.isCelebrity('celeb'), true);

  final bob1 = feed.publish('bob', 'bob 1');
  tick();
  final celeb1 = feed.publish('celeb', 'celeb 1');
  tick();
  feed.publish('carol', 'carol 1');
  tick();

  // Push vs pull: celeb's post is not in alice's cached timeline, but it is in her feed.
  check(feed.timelines.idsBefore('alice', null).contains(celeb1.id), false);
  check(feed.fanoutWrites, 2); // bob -> alice, carol -> alice; nothing for celeb's 3 followers
  check(feed.feed('alice').posts, ['carol: carol 1', 'celeb: celeb 1', 'bob: bob 1']);

  // Cursor pagination is stable even when new posts arrive between pages.
  final page1 = feed.feed('alice', limit: 2);
  check(page1.posts, ['carol: carol 1', 'celeb: celeb 1']);
  feed.publish('bob', 'bob 2 (new, should not shift page 2)');
  tick();
  final page2 = feed.feed('alice', cursor: page1.nextCursor, limit: 2);
  check(
    [page2.posts, page2.nextCursor],
    [
      ['bob: bob 1'],
      null,
    ],
  );

  // Unfollow and delete are filtered at read time.
  feed.unfollow('alice', 'carol');
  feed.deletePost(bob1.id);
  check(feed.feed('alice').posts, ['bob: bob 2 (new, should not shift page 2)', 'celeb: celeb 1']);

  // Own posts appear in own feed; following backfills recent posts.
  feed.publish('dave', 'dave 1');
  tick();
  feed.follow('dave', 'bob');
  check(feed.feed('dave').posts, ['dave: dave 1', 'bob: bob 2 (new, should not shift page 2)']);

  // Timeline cache is capped (size 5 here); older entries fall off.
  for (var i = 0; i < 7; i++) {
    feed.publish('bob', 'spam $i');
    tick();
  }
  check(feed.timelines.sizeOf('alice'), 5);
  check(feed.feed('alice', limit: 3).posts, ['bob: spam 6', 'bob: spam 5', 'bob: spam 4']);
}
```

## 5. Walkthrough

- `celeb` reaches 3 followers, the threshold, so `publish('celeb')` writes to no timelines. Alice's feed still shows it because `feed` pulls her followed celebrities' recent posts and merges by ID.
- Page 1 ends at celeb's post; the cursor is that post's ID. A new post from Bob arrives at the top, but page 2 asks for IDs below the cursor, so it returns exactly `bob 1` and stops (a short page means no more).
- After the unfollow and delete, Carol's post and `bob 1` vanish from the feed without touching any timeline.
- The cap is per timeline: Alice's cache keeps only the 5 newest IDs. In production the cap (~800) is far larger than anyone scrolls in one session; older pages fall back to the pull path.

**Known simplification:** when a celebrity drops below the threshold (or a normal user crosses it), past posts were distributed under the old rule. Real systems handle this by running the read-time merge for users near the threshold, or by re-fanning out recent posts on the transition.

## 6. Concurrency

- Fan-out is asynchronous: `publish` enqueues an event and returns. Workers may insert IDs out of order, which `TimelineCache.add` tolerates (sorted insert) and makes idempotent (duplicate check), so redelivery from the queue is harmless.
- Timelines in Redis: `ZADD feed:{user} id id` + `ZREMRANGEBYRANK` to trim; each command is atomic.
- `SnowflakeIds.next` must be synchronized (or one generator per thread with distinct machine IDs).

## 7. Extensibility

| Change | Where |
|---|---|
| Ranking | After candidate collection, score and sort with a `Ranker` interface instead of by ID. |
| Only push to active followers | Filter followers by last-active time in `publish`; inactive users get the pull path. |
| Distributed fan-out | Replace the loop with a queue publish; a worker runs the same loop in batches. |
| Ads | A `FeedDecorator` that inserts ad slots into the page. |
| Mute / block | Extra read-time filter in `feed`. |

## 8. Common mistakes in LLD rounds

- One method that queries every followee's posts on every feed load (pure pull) without discussing the cost.
- Offset pagination.
- Forgetting the user's own posts.
- Deleting from every timeline synchronously.
- Timestamps as IDs or sort keys without a tiebreaker (two posts in the same millisecond).

See [HLD.md](HLD.md) for the service architecture and capacity math.
