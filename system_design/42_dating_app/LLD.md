# Dating App: Low-Level Design

## 1. Scope for the LLD round

- **Profiles** with age, gender, location and preferences (genders of interest, age range, maximum distance).
- **Mutual compatibility:** A appears in B's deck only if each satisfies the other's preferences.
- **Deck building:** compatible profiles, excluding self, already swiped, matched, unmatched and blocked users; ranked by distance, then recent activity.
- **Swipes:** idempotent per (swiper, target); **daily like limit**; a **match** is created when likes are mutual, exactly once even if both like at the same moment (canonical pair key).
- **Unmatch** (no rematch) and **block** (mutual, absolute).
- **Distance display with location fuzzing.**

Out of scope: the geo index (see 23), chat (see 05), ranking models (HLD).

## 2. Entities and responsibilities

| Class | Responsibility |
|---|---|
| `Profile` | Attributes, preferences, location, last active time. |
| `distanceKm`, `fuzzedDistanceText` | Exact distance (server only) and the privacy-preserving display. |
| `compatible` | Both users' preferences satisfied. |
| `SwipeOutcome` | Recorded, duplicate, limit reached, or matched. |
| `DatingService` | Decks, swipes, matches, limits, unmatch, block, notifications. |

```text
buildDeck(u) = profiles.where(compatible both ways && not excluded) sorted by (distance, -lastActive, id)
swipe(a, b, like) = writeSwipe(a, b) ; checkMatch(a, b): like(b -> a) exists ? matches.add(pairKey(a, b)) : nothing
```

## 3. Design decisions and why

- **Two-sided filtering:** showing someone who would never see you back wastes both users' swipes.
- **Swipes keyed by (swiper, target):** the reverse lookup that detects a match is a single map read.
- **Write first, then check, with an idempotent match key:** if A and B like each other at the same time, both checks may succeed; the set of pair keys guarantees one match and one notification per user.
- **Unmatched and blocked pairs** live in their own sets, consulted by decks and swipes.
- **Location fuzzing:** distances are computed from coordinates snapped to a ~1 km grid and rounded up, so repeated queries cannot triangulate an exact position.

## 4. The code

```dart
import 'dart:math';

enum Gender { man, woman, nonbinary }

class Profile {
  Profile(
    this.id, {
    required this.age,
    required this.gender,
    required this.interestedIn,
    required this.minAge,
    required this.maxAge,
    required this.maxDistanceKm,
    required this.lat,
    required this.lng,
    this.lastActive = 0,
  });
  final String id;
  final int age;
  final Gender gender;
  final Set<Gender> interestedIn;
  final int minAge;
  final int maxAge;
  final double maxDistanceKm;
  final double lat;
  final double lng;
  int lastActive;
}

double distanceKm(double lat1, double lng1, double lat2, double lng2) {
  double rad(double d) => d * pi / 180;
  final h = pow(sin(rad(lat2 - lat1) / 2), 2) + cos(rad(lat1)) * cos(rad(lat2)) * pow(sin(rad(lng2 - lng1) / 2), 2);
  return 2 * 6371 * asin(sqrt(h));
}

double profileDistance(Profile a, Profile b) => distanceKm(a.lat, a.lng, b.lat, b.lng);

/// Snap both locations to a 0.01-degree grid (~1 km), then round up to whole km (minimum 1).
String fuzzedDistanceText(Profile a, Profile b) {
  double snap(double v) => (v * 100).round() / 100;
  final d = distanceKm(snap(a.lat), snap(a.lng), snap(b.lat), snap(b.lng));
  return '${max(1, d.ceil())} km away';
}

bool _accepts(Profile viewer, Profile other) =>
    other.age >= viewer.minAge &&
    other.age <= viewer.maxAge &&
    viewer.interestedIn.contains(other.gender) &&
    profileDistance(viewer, other) <= viewer.maxDistanceKm;

bool compatible(Profile a, Profile b) => _accepts(a, b) && _accepts(b, a);

String pairKey(String a, String b) => a.compareTo(b) < 0 ? '$a:$b' : '$b:$a';

enum SwipeOutcome { recorded, duplicate, limitReached, matched }

class BlockedException implements Exception {}

class DatingService {
  DatingService({this.dailyLikeLimit = 100});
  final int dailyLikeLimit;
  final profiles = <String, Profile>{};
  final _swipes = <(String, String), bool>{}; // (swiper, target) -> liked?
  final matches = <String>{};
  final _unmatched = <String>{};
  final _blocked = <String>{};
  final _likesPerDay = <(String, int), int>{};
  final notifications = <String>[];

  void add(Profile p) => profiles[p.id] = p;

  bool _excluded(String u, String other) {
    final key = pairKey(u, other);
    return _swipes.containsKey((u, other)) ||
        matches.contains(key) ||
        _unmatched.contains(key) ||
        _blocked.contains(key);
  }

  List<String> buildDeck(String user, {int size = 10}) {
    final me = profiles[user]!;
    final candidates =
        profiles.values.where((p) => p.id != user && !_excluded(user, p.id) && compatible(me, p)).toList()
          ..sort((a, b) {
            final d = profileDistance(me, a).compareTo(profileDistance(me, b));
            if (d != 0) return d;
            return a.lastActive != b.lastActive ? b.lastActive.compareTo(a.lastActive) : a.id.compareTo(b.id);
          });
    return [for (final p in candidates.take(size)) p.id];
  }

  /// Step 1 of a swipe: durable write keyed by (swiper, target).
  SwipeOutcome writeSwipe(String user, String target, {required bool like, required int day}) {
    if (user == target) throw ArgumentError('cannot swipe on yourself');
    if (_blocked.contains(pairKey(user, target))) throw BlockedException();
    if (_swipes.containsKey((user, target))) return SwipeOutcome.duplicate;
    if (like) {
      final used = _likesPerDay[(user, day)] ?? 0;
      if (used >= dailyLikeLimit) return SwipeOutcome.limitReached;
      _likesPerDay[(user, day)] = used + 1;
    }
    _swipes[(user, target)] = like;
    return SwipeOutcome.recorded;
  }

  /// Step 2: if the other person already liked us, create the match (idempotent by pair key).
  bool checkMatch(String user, String target) {
    if (_swipes[(user, target)] != true || _swipes[(target, user)] != true) return false;
    final key = pairKey(user, target);
    if (_unmatched.contains(key) || !matches.add(key)) return false;
    notifications
      ..add('$user matched with $target')
      ..add('$target matched with $user');
    return true;
  }

  SwipeOutcome swipe(String user, String target, {required bool like, int day = 0}) {
    final outcome = writeSwipe(user, target, like: like, day: day);
    if (outcome != SwipeOutcome.recorded) return outcome;
    return like && checkMatch(user, target) ? SwipeOutcome.matched : SwipeOutcome.recorded;
  }

  void unmatch(String a, String b) {
    final key = pairKey(a, b);
    if (matches.remove(key)) _unmatched.add(key);
  }

  void block(String a, String b) {
    final key = pairKey(a, b);
    matches.remove(key);
    _blocked.add(key);
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
  const sfLat = 37.7749, sfLng = -122.4194;
  Profile p(
    String id,
    int age,
    Gender g,
    Set<Gender> wants,
    int minA,
    int maxA,
    double km,
    double dLat, {
    int active = 0,
  }) => Profile(
    id,
    age: age,
    gender: g,
    interestedIn: wants,
    minAge: minA,
    maxAge: maxA,
    maxDistanceKm: km,
    lat: sfLat + dLat,
    lng: sfLng,
    lastActive: active,
  );

  final s = DatingService(dailyLikeLimit: 3)
    ..add(p('alice', 28, Gender.woman, {Gender.man}, 25, 35, 10, 0))
    ..add(p('bob', 30, Gender.man, {Gender.woman}, 25, 32, 10, 0.02, active: 5)) // ~2.2 km away
    ..add(p('ben', 31, Gender.man, {Gender.woman}, 25, 35, 10, 0.02, active: 9)) // same distance, more recent
    ..add(p('carl', 40, Gender.man, {Gender.woman}, 25, 45, 10, 0.01)) // too old for alice
    ..add(p('dan', 29, Gender.man, {Gender.man}, 25, 35, 10, 0.01)) // not interested in women
    ..add(p('eric', 33, Gender.man, {Gender.woman}, 30, 40, 10, 0.03)) // alice too young for him
    ..add(p('fred', 27, Gender.man, {Gender.woman}, 20, 35, 100, 0.5)); // ~55 km: beyond alice's 10 km

  // Two-sided filtering and ranking (distance, then most recently active).
  check(s.buildDeck('alice'), ['ben', 'bob']);

  // Swipes and matching.
  check(s.swipe('alice', 'bob', like: true), SwipeOutcome.recorded);
  check(s.swipe('alice', 'bob', like: true), SwipeOutcome.duplicate);
  check(s.swipe('bob', 'alice', like: true), SwipeOutcome.matched);
  check([s.matches, s.notifications], ['{alice:bob}', '[bob matched with alice, alice matched with bob]']);
  check(s.buildDeck('alice'), ['ben']); // swiped and matched profiles are gone

  // Simultaneous likes: both writes land before either check; exactly one match.
  final race = DatingService()
    ..add(p('x', 30, Gender.woman, {Gender.man}, 18, 99, 50, 0))
    ..add(p('y', 30, Gender.man, {Gender.woman}, 18, 99, 50, 0));
  race
    ..writeSwipe('x', 'y', like: true, day: 0)
    ..writeSwipe('y', 'x', like: true, day: 0);
  check(
    [race.checkMatch('x', 'y'), race.checkMatch('y', 'x'), race.matches.length, race.notifications.length],
    [true, false, 1, 2],
  );

  // Daily like limit (passes are unlimited).
  final limited = DatingService(dailyLikeLimit: 3);
  for (var i = 0; i < 6; i++) {
    limited.add(p('m$i', 30, Gender.man, {Gender.woman}, 18, 99, 50, 0));
  }
  limited.add(p('w', 30, Gender.woman, {Gender.man}, 18, 99, 50, 0));
  check([for (var i = 0; i < 4; i++) limited.swipe('w', 'm$i', like: true)].last, SwipeOutcome.limitReached);
  check(
    [limited.swipe('w', 'm4', like: false), limited.swipe('w', 'm3', like: true, day: 1)],
    [SwipeOutcome.recorded, SwipeOutcome.recorded],
  );

  // Unmatch: no rematch, never shown again.
  s.unmatch('alice', 'bob');
  check([s.matches.isEmpty, s.checkMatch('bob', 'alice'), s.buildDeck('bob').contains('alice')], [true, false, false]);

  // Block: absolute in both directions.
  s.block('ben', 'alice');
  check(s.buildDeck('alice'), '[]');
  expectThrows<BlockedException>(() => s.swipe('alice', 'ben', like: true));

  // Location privacy: displayed distance comes from snapped coordinates, rounded up.
  check(fuzzedDistanceText(s.profiles['alice']!, s.profiles['bob']!), '3 km away');
  check(profileDistance(s.profiles['alice']!, s.profiles['bob']!).toStringAsFixed(2), '2.22');
}
```

## 5. Walkthrough

- Alice's deck contains Ben and Bob only. Carl is outside her age range, Dan is not interested in women, Eric's range starts at 30 (Alice is 28), Fred is ~55 km away. Ben and Bob are equally far; Ben was active more recently, so he comes first.
- Alice's repeated like is a duplicate; Bob's like back creates the match and two notifications; both disappear from Alice's deck.
- In the race, both likes are written before either side checks. The first check creates the match; the second finds the pair key already present: one match, two notifications.
- With a limit of 3 likes per day, the 4th like is refused, a pass still works, and the next day the like goes through.
- After unmatching, the pair cannot match again and they never reappear in each other's decks.
- After Ben blocks Alice, her deck is empty and swiping on Ben throws.
- Bob is 2.22 km away; Alice sees "3 km away" (snapped and rounded up).

## 6. Concurrency

- Swipe writes and match checks happen on different servers for A and B; correctness comes from the unique pair key (`INSERT ... IF NOT EXISTS` on `matches(pair_key)`), not from locks.
- Daily like counters are atomic increments with a conditional limit (Redis `INCR` and compare, or a Lua script).
- Deck building runs asynchronously and may include someone who swiped meanwhile; the swipe path rechecks exclusions.

## 7. Extensibility

| Change | Where |
|---|---|
| Geo index for candidates | Replace the full scan in `buildDeck` with a geohash query (see 23). |
| Learned ranking | Score candidates by predicted mutual-like probability before sorting. |
| Super likes / boosts | Priority fields used by the deck ranking of the target user. |
| Rewind | Keep the last pass per user; allow deleting it once. |
| Women-message-first (Bumble) | A rule on the chat created after a match. |

## 8. Common mistakes in LLD rounds

- One-sided preference filtering.
- Creating the match only on the second swiper's request without handling simultaneity.
- Counting duplicate swipe requests against the like limit.
- Returning raw coordinates or exact distances.

See [HLD.md](HLD.md) for deck precomputation, storage at swipe scale and safety.
