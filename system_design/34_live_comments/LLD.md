# Live Comments: Low-Level Design

## 1. Scope for the LLD round

- **Gateways** hold viewer connections and know which videos their viewers watch.
- A **channel registry** maps each video to the set of gateways that have at least one viewer of it: subscribe on the first local viewer, unsubscribe when the last one leaves.
- **Publishing** sends one message per subscribed gateway; each gateway fans out locally.
- **Posting rules:** banned users, banned words, and slow mode (minimum seconds between one user's comments per video).
- **Recent-comments buffer** per video for new viewers.
- **Sampling** for busy streams: each viewer receives at most N ordinary comments per second; comments from the streamer and the viewer's friends always get through.

Out of scope: WebSockets, persistence, multi-region pub/sub (HLD).

## 2. Entities and responsibilities

| Class | Responsibility |
|---|---|
| `Comment` | ID, video, author, text, time. |
| `Viewer` | ID, friends, received comments, per-second delivery count. |
| `Gateway` | Local viewers per video; local fan-out with sampling; delivery counter. |
| `ChannelRegistry` | Video -> subscribed gateways. |
| `CommentRejected` | Reason a comment was not published. |
| `CommentService` | Join/leave, post (moderation), publish (counts core messages), recent buffer. |

```text
poster --> CommentService.post: banned? bad words? slow mode? --> recent buffer --> publish
publish: for gateway in registry[video] (one core message each) --> Gateway.deliver --> local viewers (sampled)
```

## 3. Design decisions and why

- **Subscribe gateways, not viewers:** the core cost per comment is the number of gateways with viewers (hundreds), not the number of viewers (millions).
- **Reference counting by viewers per gateway** drives subscribe/unsubscribe, so idle gateways stop receiving a video's traffic.
- **Sampling at the gateway,** close to the viewer, using information the core does not have (who this viewer's friends are).
- **Priority beats sampling:** the streamer's and friends' comments are what viewers care about most.
- **Moderation before publishing:** a rejected comment never fans out.

## 4. The code

```dart
import 'dart:collection';

class Comment {
  const Comment(this.id, this.videoId, this.userId, this.text, this.t);
  final String id;
  final String videoId;
  final String userId;
  final String text;
  final int t; // seconds
  @override
  String toString() => '$userId: $text';
}

class Viewer {
  Viewer(this.id, {Set<String>? friends}) : friends = friends ?? {};
  final String id;
  final Set<String> friends;
  final received = <Comment>[];
  var _second = -1;
  var _countThisSecond = 0;
}

class Gateway {
  Gateway(this.id, {this.maxPerViewerPerSecond = 1000});
  final String id;
  final int maxPerViewerPerSecond;
  final _viewers = <String, Map<String, Viewer>>{}; // video -> viewers on this gateway
  var deliveries = 0;
  var sampledOut = 0;

  int viewersOf(String video) => _viewers[video]?.length ?? 0;

  /// Returns true if this was the first local viewer of [video].
  bool add(String video, Viewer v) {
    final local = _viewers.putIfAbsent(video, () => {});
    local[v.id] = v;
    return local.length == 1;
  }

  /// Returns true if that was the last local viewer of [video].
  bool remove(String video, String viewerId) {
    final local = _viewers[video];
    if (local == null || local.remove(viewerId) == null) return false;
    if (local.isEmpty) _viewers.remove(video);
    return local.isEmpty;
  }

  void deliver(Comment c, {required String streamerId}) {
    for (final v in (_viewers[c.videoId] ?? const <String, Viewer>{}).values) {
      if (v._second != c.t) {
        v._second = c.t;
        v._countThisSecond = 0;
      }
      final priority = c.userId == streamerId || v.friends.contains(c.userId) || c.userId == v.id;
      if (!priority && v._countThisSecond >= maxPerViewerPerSecond) {
        sampledOut++;
        continue;
      }
      if (!priority) v._countThisSecond++;
      v.received.add(c);
      deliveries++;
    }
  }
}

class ChannelRegistry {
  final _subs = <String, Set<Gateway>>{};
  void subscribe(String video, Gateway g) => _subs.putIfAbsent(video, () => {}).add(g);
  void unsubscribe(String video, Gateway g) {
    _subs[video]?.remove(g);
    if (_subs[video]?.isEmpty ?? false) _subs.remove(video);
  }

  Set<Gateway> gatewaysFor(String video) => _subs[video] ?? const {};
}

class CommentRejected implements Exception {
  CommentRejected(this.reason);
  final String reason;
  @override
  String toString() => reason;
}

class CommentService {
  CommentService({this.recentLimit = 50, this.bannedWords = const {}});
  final int recentLimit;
  final Set<String> bannedWords;
  final registry = ChannelRegistry();
  final streamers = <String, String>{}; // video -> streamer
  final slowModeSec = <String, int>{};
  final bannedUsers = <String, Set<String>>{}; // video -> users
  final _recent = <String, Queue<Comment>>{};
  final _lastPost = <(String, String), int>{};
  var coreMessages = 0;
  var _nextId = 1;

  List<Comment> join(Gateway g, String video, Viewer v) {
    if (g.add(video, v)) registry.subscribe(video, g);
    return List.of(_recent[video] ?? const <Comment>[]); // catch-up for the new viewer
  }

  void leave(Gateway g, String video, String viewerId) {
    if (g.remove(video, viewerId)) registry.unsubscribe(video, g);
  }

  Comment post(String user, String video, String text, int now) {
    if (bannedUsers[video]?.contains(user) ?? false) throw CommentRejected('banned');
    final words = text.toLowerCase().split(RegExp(r'\W+'));
    if (words.any(bannedWords.contains)) throw CommentRejected('blocked word');
    final last = _lastPost[(user, video)];
    final slow = slowModeSec[video] ?? 0;
    if (last != null && now - last < slow) throw CommentRejected('slow mode: wait ${slow - (now - last)}s');
    _lastPost[(user, video)] = now;

    final c = Comment('c${_nextId++}', video, user, text, now);
    final recent = _recent.putIfAbsent(video, Queue.new)..add(c);
    if (recent.length > recentLimit) recent.removeFirst();
    for (final g in registry.gatewaysFor(video)) {
      coreMessages++; // one message per gateway, however many viewers it has
      g.deliver(c, streamerId: streamers[video] ?? '');
    }
    return c;
  }
}

// ---------- Self-checks ----------

void check(Object? actual, Object? expected) {
  if ('$actual' != '$expected') throw StateError('expected $expected, got $actual');
  print('ok: $actual');
}

void main() {
  final service = CommentService(recentLimit: 3, bannedWords: {'spamword'});
  service.streamers['v1'] = 'streamer';
  final g1 = Gateway('g1'), g2 = Gateway('g2'), g3 = Gateway('g3');
  for (var i = 0; i < 1000; i++) {
    service.join(g1, 'v1', Viewer('a$i'));
  }
  for (var i = 0; i < 500; i++) {
    service.join(g2, 'v1', Viewer('b$i'));
  }
  service.join(g3, 'v2', Viewer('c0')); // a different video

  // Two core messages, 1,500 local deliveries; g3 receives nothing.
  service.post('a0', 'v1', 'hello everyone', 0);
  check([service.coreMessages, g1.deliveries + g2.deliveries, g3.deliveries], [2, 1500, 0]);

  // The last viewer leaving a gateway unsubscribes it.
  for (var i = 0; i < 500; i++) {
    service.leave(g2, 'v1', 'b$i');
  }
  check(service.registry.gatewaysFor('v1').map((g) => g.id), '(g1)');
  service.post('a1', 'v1', 'still here', 1);
  check(service.coreMessages, 3);

  // Catch-up: a new viewer gets the most recent comments (buffer of 3).
  service
    ..post('a2', 'v1', 'third', 2)
    ..post('a3', 'v1', 'fourth', 3);
  check(service.join(g2, 'v1', Viewer('late')), ['a1: still here', 'a2: third', 'a3: fourth']);

  // Moderation.
  service.slowModeSec['v1'] = 5;
  service.bannedUsers['v1'] = {'troll'};
  String attempt(String user, String text, int t) {
    try {
      service.post(user, 'v1', text, t);
      return 'ok';
    } on CommentRejected catch (e) {
      return e.reason;
    }
  }

  check(
    [
      attempt('troll', 'hi', 10),
      attempt('a5', 'buy SPAMWORD now', 10),
      attempt('a6', 'first', 10),
      attempt('a6', 'second', 12),
      attempt('a6', 'third', 15),
    ],
    ['banned', 'blocked word', 'ok', 'slow mode: wait 3s', 'ok'],
  );

  // Sampling: at most 2 ordinary comments per viewer per second; friends and the streamer always get through.
  final busy = CommentService();
  busy.streamers['big'] = 'streamer';
  final gw = Gateway('gw', maxPerViewerPerSecond: 2);
  final fan = Viewer('fan', friends: {'bestie'});
  busy.join(gw, 'big', fan);
  for (var i = 0; i < 5; i++) {
    busy.post('stranger$i', 'big', 'msg $i', 100);
  }
  busy
    ..post('bestie', 'big', 'hey fan!', 100)
    ..post('streamer', 'big', 'thanks for watching', 100)
    ..post('stranger9', 'big', 'next second', 101);
  check(fan.received, [
    'stranger0: msg 0',
    'stranger1: msg 1',
    'bestie: hey fan!',
    'streamer: thanks for watching',
    'stranger9: next second',
  ]);
  check(gw.sampledOut, 3);
}
```

## 5. Walkthrough

- Video v1 has 1,000 viewers on g1 and 500 on g2. One comment costs 2 core messages (one per gateway) and 1,500 local deliveries; g3, whose viewer watches v2, gets nothing.
- When all of g2's viewers leave, g2 unsubscribes; the next comment costs one core message.
- A late joiner receives the last three comments from the buffer.
- Moderation: a banned user and a blocked word are rejected; with 5-second slow mode, a second comment after 2 seconds is rejected (wait 3 s) and one after 5 seconds is accepted.
- Sampling: in second 100, the fan receives the first two strangers' comments; the other three are sampled out, but the friend's and the streamer's comments are delivered. In second 101 the budget resets.

## 6. Concurrency

- Each gateway runs an event loop per core; its local viewer maps are owned by one loop, so fan-out needs no locks.
- Subscribe/unsubscribe races (last viewer leaves while a new one joins) are resolved by doing both through the gateway's own event loop and making registry operations idempotent.
- The comment service can process posts for different videos in parallel; per-user slow-mode state is keyed by (user, video).

## 7. Extensibility

| Change | Where |
|---|---|
| Comment deletion | Publish a delete event through the same path; clients remove the comment. |
| Reactions | Count per video per second; publish totals instead of events. |
| Gateway affinity | Route viewers of the same video to the same gateways (fewer core messages). |
| Smarter sampling | Score comments (likes, author reputation) instead of first-come. |

## 8. Common mistakes in LLD rounds

- One subscription per viewer in the central pub/sub.
- Forgetting to unsubscribe idle gateways.
- Sampling that drops the streamer's own messages.
- Moderation after fan-out.

See [HLD.md](HLD.md) for the architecture, huge streams and failure handling.
