# Feature Flags and Gradual Rollouts: Low-Level Design

## 1. Scope for the LLD round

- **Flags** with named variations, an on/off switch (off = the off variation), **prerequisites**, **individual targets**, ordered **rules** (attribute conditions), and a default (fallthrough).
- A rule or the default serves either a fixed variation or a **percentage rollout**.
- **Bucketing:** `hash(flagKey + salt + userKey) mod 100000`, deterministic, salted per flag, and **monotonic** when the percentage grows.
- Every evaluation returns the **value and the reason**.
- An **SDK cache** applying versioned updates (stale versions ignored) and a **kill switch**.
- Exposure events deduplicated per (user, flag, variation).

Out of scope: streaming transport, dashboards, experiment statistics (HLD).

## 2. Entities and responsibilities

| Class | Responsibility |
|---|---|
| `User` | Key and attributes. |
| `Condition` | Attribute + operator (`in`, `startsWith`, `versionAtLeast`) + values. |
| `Serve` | A fixed variation or weighted rollout. |
| `Rule` | All conditions must match -> serve. |
| `Flag` | Variations, on/off, prerequisites, targets, rules, fallthrough, salt, version. |
| `bucketOf` | Deterministic bucket in [0, 100000). |
| `Evaluation` | Value + reason. |
| `FlagStore` (the SDK) | Versioned flags in memory; `evaluate`; exposure dedup. |

```text
FlagStore (SDK) --holds--> Flag(version) --evaluate(user)-->
   off? -> offVariation | prerequisite failed? -> offVariation | target? -> variation
   | first matching Rule -> Serve | fallthrough Serve        Serve = variation | rollout(bucketOf(...))
```

## 3. Design decisions and why

- **Evaluation is a pure function of (flag, user):** no network call, no state per user, identical on every server.
- **Fixed evaluation order** (off, prerequisites, targets, rules, fallthrough) and a **reason** for every result, so behavior is explainable.
- **Bucket over 100,000 slots** gives 0.001% granularity; ranges are cumulative, so growing a rollout only adds users.
- **Salt per flag** decorrelates experiments.
- **Versioned updates:** out-of-order stream messages cannot roll a flag back.

## 4. The code

```dart
class User {
  const User(this.key, [this.attributes = const {}]);
  final String key;
  final Map<String, String> attributes;
}

enum Op { isIn, startsWith, versionAtLeast }

class Condition {
  const Condition(this.attribute, this.op, this.values);
  final String attribute;
  final Op op;
  final List<String> values;

  bool matches(User u) {
    final v = attribute == 'key' ? u.key : u.attributes[attribute];
    if (v == null) return false;
    return switch (op) {
      Op.isIn => values.contains(v),
      Op.startsWith => values.any(v.startsWith),
      Op.versionAtLeast => _compareVersions(v, values.single) >= 0,
    };
  }

  static int _compareVersions(String a, String b) {
    final x = a.split('.').map(int.parse).toList(), y = b.split('.').map(int.parse).toList();
    for (var i = 0; i < x.length || i < y.length; i++) {
      final d = (i < x.length ? x[i] : 0) - (i < y.length ? y[i] : 0);
      if (d != 0) return d;
    }
    return 0;
  }
}

class Serve {
  const Serve.variation(this.variation) : rollout = null;
  const Serve.rollout(this.rollout) : variation = null;
  final String? variation;
  final Map<String, int>? rollout; // variation -> weight in 1/1000 of a percent (sum 100000)
}

class Rule {
  const Rule(this.id, this.conditions, this.serve);
  final String id;
  final List<Condition> conditions;
  final Serve serve;
}

class Flag {
  const Flag({
    required this.key,
    required this.version,
    this.on = true,
    this.offVariation = 'off',
    this.prerequisites = const {},
    this.targets = const {},
    this.rules = const [],
    this.fallthrough = const Serve.variation('off'),
    this.salt = '',
  });
  final String key;
  final int version;
  final bool on;
  final String offVariation;
  final Map<String, String> prerequisites; // flag key -> required variation
  final Map<String, Set<String>> targets; // variation -> user keys
  final List<Rule> rules;
  final Serve fallthrough;
  final String salt;
}

int bucketOf(String flagKey, String salt, String userKey) {
  var h = 0x811C9DC5;
  for (final c in '$flagKey.$salt.$userKey'.codeUnits) {
    h = ((h ^ c) * 0x01000193) & 0xFFFFFFFF;
  }
  h ^= h >> 15;
  h = (h * 0x2C1B3C6D) & 0xFFFFFFFF;
  h ^= h >> 12;
  return h % 100000;
}

class Evaluation {
  const Evaluation(this.value, this.reason);
  final String value;
  final String reason;
  @override
  String toString() => '$value ($reason)';
}

class FlagStore {
  final _flags = <String, Flag>{};
  final exposures = <String>{};

  /// Apply an update from the stream; older or equal versions are ignored.
  bool apply(Flag f) {
    final current = _flags[f.key];
    if (current != null && current.version >= f.version) return false;
    _flags[f.key] = f;
    return true;
  }

  Flag? operator [](String key) => _flags[key];

  Evaluation evaluate(String key, User u, {String fallback = 'off'}) {
    final f = _flags[key];
    if (f == null) return Evaluation(fallback, 'flag not found: code default');
    if (!f.on) return Evaluation(f.offVariation, 'flag off');
    for (final MapEntry(key: pre, value: required) in f.prerequisites.entries) {
      if (evaluate(pre, u).value != required) return Evaluation(f.offVariation, 'prerequisite $pre failed');
    }
    for (final MapEntry(key: variation, value: users) in f.targets.entries) {
      if (users.contains(u.key)) return Evaluation(variation, 'individual target');
    }
    for (final rule in f.rules) {
      if (rule.conditions.every((c) => c.matches(u))) return Evaluation(_serve(f, rule.serve, u), 'rule ${rule.id}');
    }
    return Evaluation(_serve(f, f.fallthrough, u), 'fallthrough');
  }

  String _serve(Flag f, Serve s, User u) {
    if (s.variation != null) return s.variation!;
    final bucket = bucketOf(f.key, f.salt, u.key);
    var cumulative = 0;
    for (final MapEntry(key: variation, value: weight) in s.rollout!.entries) {
      cumulative += weight;
      if (bucket < cumulative) return variation;
    }
    return s.rollout!.keys.last;
  }

  /// Record that [u] was exposed to the evaluated variation, once per (user, flag, variation).
  Evaluation evaluateAndTrack(String key, User u) {
    final e = evaluate(key, u);
    exposures.add('${u.key}|$key|${e.value}');
    return e;
  }
}

// ---------- Self-checks ----------

void check(Object? actual, Object? expected) {
  if ('$actual' != '$expected') throw StateError('expected $expected, got $actual');
  print('ok: $actual');
}

Map<String, int> rolloutOf(int percentOn) => {'on': percentOn * 1000, 'off': (100 - percentOn) * 1000};

void main() {
  final sdk = FlagStore();
  sdk.apply(
    Flag(
      key: 'new-checkout',
      version: 1,
      targets: {
        'on': {'qa-tester'},
      },
      rules: [
        const Rule('eu-users', [
          Condition('country', Op.isIn, ['DE', 'FR']),
        ], Serve.variation('eu-variant')),
        const Rule('new-app', [
          Condition('appVersion', Op.versionAtLeast, ['5.2']),
        ], Serve.variation('on')),
      ],
      fallthrough: Serve.rollout(rolloutOf(20)),
      salt: 'a1',
    ),
  );

  // Evaluation order and reasons.
  check([
    sdk.evaluate('new-checkout', const User('qa-tester', {'country': 'DE'})),
    sdk.evaluate('new-checkout', const User('u1', {'country': 'FR'})),
    sdk.evaluate('new-checkout', const User('u2', {'appVersion': '5.10.1'})),
    sdk.evaluate('missing-flag', const User('u3')),
  ], '[on (individual target), eu-variant (rule eu-users), on (rule new-app), off (flag not found: code default)]');
  check(sdk.evaluate('new-checkout', const User('u4', {'appVersion': '5.1.9'})).reason, 'fallthrough');

  // Percentage rollout: ~20%, stable, and monotonic when increased to 50%.
  final users = [for (var i = 0; i < 10000; i++) User('user$i')];
  final at20 = users.where((u) => sdk.evaluate('new-checkout', u).value == 'on').map((u) => u.key).toSet();
  check(at20.length > 1800 && at20.length < 2200, true);
  final at20Again = users.where((u) => sdk.evaluate('new-checkout', u).value == 'on').map((u) => u.key).toSet();
  check(at20Again.length == at20.length && at20Again.containsAll(at20), true);
  sdk.apply(Flag(key: 'new-checkout', version: 2, fallthrough: Serve.rollout(rolloutOf(50)), salt: 'a1'));
  final at50 = users.where((u) => sdk.evaluate('new-checkout', u).value == 'on').map((u) => u.key).toSet();
  check([at50.length > 4700 && at50.length < 5300, at50.containsAll(at20)], [true, true]); // nobody dropped out

  // Different salts bucket independently: overlap of two 20% rollouts is about 4%, not 20%.
  sdk.apply(Flag(key: 'other-experiment', version: 1, fallthrough: Serve.rollout(rolloutOf(20)), salt: 'b7'));
  final other = users.where((u) => sdk.evaluate('other-experiment', u).value == 'on').map((u) => u.key).toSet();
  final overlap = other.intersection(at20).length;
  check(overlap > 250 && overlap < 550, true);

  // Prerequisites and the kill switch.
  sdk.apply(
    const Flag(
      key: 'one-click-pay',
      version: 1,
      prerequisites: {'new-checkout': 'on'},
      fallthrough: Serve.variation('on'),
    ),
  );
  final inRollout = users.firstWhere((u) => at50.contains(u.key));
  final notInRollout = users.firstWhere((u) => !at50.contains(u.key));
  check(
    [sdk.evaluate('one-click-pay', inRollout).value, sdk.evaluate('one-click-pay', notInRollout).reason],
    ['on', 'prerequisite new-checkout failed'],
  );
  sdk.apply(Flag(key: 'new-checkout', version: 3, on: false, fallthrough: Serve.rollout(rolloutOf(50)), salt: 'a1'));
  check(
    [sdk.evaluate('new-checkout', inRollout), sdk.evaluate('one-click-pay', inRollout).value],
    ['off (flag off)', 'off'],
  );

  // Stale stream messages are ignored.
  check(
    sdk.apply(Flag(key: 'new-checkout', version: 2, fallthrough: Serve.rollout(rolloutOf(100)), salt: 'a1')),
    false,
  );
  check(sdk['new-checkout']!.on, false);

  // Exposure events are deduplicated.
  for (var i = 0; i < 3; i++) {
    sdk.evaluateAndTrack('other-experiment', users.first);
  }
  check(sdk.exposures.length, 1);
}
```

## 5. Walkthrough

- `qa-tester` is listed as an individual target, so it gets `on` even though its country matches the EU rule: targets come before rules.
- A French user matches the EU rule; a user on app version 5.10.1 matches `versionAtLeast 5.2` (numeric comparison, so 5.10 > 5.2); 5.1.9 does not and falls through to the 20% rollout.
- About 2,000 of 10,000 users are in the 20% rollout, the same users each time. At 50% about 5,000 are in, including every one of the original 20%.
- A second flag with a different salt picks a different 20%: the overlap is about 400 users (4%), as for independent draws.
- `one-click-pay` requires `new-checkout = on`: users outside the rollout fail the prerequisite. Turning `new-checkout` off (version 3) turns off both flags immediately.
- A delayed version-2 message arriving after version 3 is ignored.
- Three evaluations of the same flag for the same user produce one exposure event.

## 6. Concurrency

- The SDK swaps a whole immutable flag map (or single immutable `Flag` objects) on update; evaluations read without locks.
- Evaluation is pure and thread-safe; exposure recording uses a concurrent set or a per-thread buffer flushed periodically.
- The server orders flag versions per environment, so all SDKs converge to the same rules.

## 7. Extensibility

| Change | Where |
|---|---|
| Segments (reusable user groups) | A `Condition` operator that checks segment membership. |
| Bucketing by organization | Choose the attribute to hash (`bucketBy`) per rollout. |
| JSON or numeric variations | Variation values as JSON; typed accessors in the SDK. |
| Scheduled changes | The server publishes a new version at a given time. |
| Guarded rollouts | Watch error metrics after a version change; auto-publish the previous version. |

## 8. Common mistakes in LLD rounds

- `Random()` for rollouts.
- Recomputing bucket ranges so that growing a rollout reshuffles users.
- Evaluating rules in an undefined order.
- Accepting updates without version checks.

See [HLD.md](HLD.md) for propagation, client-side SDKs and safety practices.
