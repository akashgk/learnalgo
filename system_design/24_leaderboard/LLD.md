# Real-Time Leaderboard: Low-Level Design

## 1. Scope for the LLD round

- A **skip list with spans**, the structure behind Redis sorted sets: insert, delete, **rank of an element** and **element at a rank** in O(log n) expected time.
- Order: higher score first; equal scores ordered by who reached the score first (a sequence number), then by member name.
- **Leaderboard** facade: `addPoints`, `rank`, `top(k)`, `around(member, n)`, `remove`.
- **Windowed boards**: all-time, monthly and daily boards updated together, keyed by period.
- Randomized cross-check against a sorted list.

Out of scope: persistence and event replay, sharding (HLD).

## 2. Entities and responsibilities

| Class | Responsibility |
|---|---|
| `_Node` | Member, score, tie-break sequence, forward pointers and span per level. |
| `RankedSkipList` | Ordered structure with `insert`, `delete`, `rankOf`, `atRank`. |
| `Leaderboard` | Hash map member -> (score, tie) plus the skip list; the public operations. |
| `LeaderboardService` | Boards per period (`all`, `month:2025-01`, `day:2025-01-02`); routes updates to all windows. |

```text
LeaderboardService --has many (by period key)--> Leaderboard --has--> Map<member, (score, tie)>
                                                             --has--> RankedSkipList (_Node levels with spans)
```

## 3. Design decisions and why

- **Hash map + skip list** (exactly Redis's ZSET): the map answers "what is this member's score" in O(1), the skip list answers order questions in O(log n).
- **Spans** store how many level-0 nodes each forward pointer jumps over. Summing spans along a search path gives the rank without walking the bottom level.
- **A score change is delete + insert**, because the node's position changes.
- **Tie-break by sequence number** (time of reaching the score): deterministic and fair; a player who reaches 150 first keeps the better rank.
- **Random levels with p = 1/4** (as in Redis): about 1.33 pointers per node on average.
- **Windows as separate boards**, not filters: a daily board is small and fast, and a new period starts empty without deleting anything.

## 4. The code

```dart
import 'dart:math';

class _Node {
  _Node(this.member, this.score, this.tie, int levels)
    : next = List<_Node?>.filled(levels, null),
      span = List<int>.filled(levels, 0);
  final String member;
  final int score;
  final int tie;
  final List<_Node?> next;
  final List<int> span;
}

class RankedSkipList {
  RankedSkipList({Random? random}) : _random = random ?? Random(42);

  static const maxLevel = 32;
  final Random _random;
  final _head = _Node('', 0, 0, maxLevel);
  var _level = 1;
  var length = 0;

  /// True if [n] sorts before (member, score, tie): higher score first, then lower tie, then name.
  bool _before(_Node n, String member, int score, int tie) =>
      n.score > score || (n.score == score && (n.tie < tie || (n.tie == tie && n.member.compareTo(member) < 0)));

  int _randomLevel() {
    var level = 1;
    while (level < maxLevel && _random.nextInt(4) == 0) {
      level++;
    }
    return level;
  }

  void insert(String member, int score, int tie) {
    final update = List<_Node>.filled(maxLevel, _head);
    final rank = List<int>.filled(maxLevel, 0);
    var x = _head;
    for (var i = _level - 1; i >= 0; i--) {
      rank[i] = i == _level - 1 ? 0 : rank[i + 1];
      while (x.next[i] != null && _before(x.next[i]!, member, score, tie)) {
        rank[i] += x.span[i];
        x = x.next[i]!;
      }
      update[i] = x;
    }
    final level = _randomLevel();
    if (level > _level) {
      for (var i = _level; i < level; i++) {
        rank[i] = 0;
        update[i] = _head;
        _head.span[i] = length;
      }
      _level = level;
    }
    final node = _Node(member, score, tie, level);
    for (var i = 0; i < level; i++) {
      node.next[i] = update[i].next[i];
      update[i].next[i] = node;
      node.span[i] = update[i].span[i] - (rank[0] - rank[i]);
      update[i].span[i] = rank[0] - rank[i] + 1;
    }
    for (var i = level; i < _level; i++) {
      update[i].span[i]++; // pointers above the new node now jump over one more element
    }
    length++;
  }

  bool delete(String member, int score, int tie) {
    final update = List<_Node>.filled(maxLevel, _head);
    var x = _head;
    for (var i = _level - 1; i >= 0; i--) {
      while (x.next[i] != null && _before(x.next[i]!, member, score, tie)) {
        x = x.next[i]!;
      }
      update[i] = x;
    }
    final target = x.next[0];
    if (target == null || target.member != member) return false;
    for (var i = 0; i < _level; i++) {
      if (update[i].next[i] == target) {
        update[i].span[i] += target.span[i] - 1;
        update[i].next[i] = target.next[i];
      } else {
        update[i].span[i]--;
      }
    }
    while (_level > 1 && _head.next[_level - 1] == null) {
      _level--;
    }
    length--;
    return true;
  }

  /// 1-based rank, or null.
  int? rankOf(String member, int score, int tie) {
    var x = _head, rank = 0;
    for (var i = _level - 1; i >= 0; i--) {
      while (x.next[i] != null && (_before(x.next[i]!, member, score, tie) || x.next[i]!.member == member)) {
        rank += x.span[i];
        x = x.next[i]!;
      }
      if (x.member == member && x != _head) return rank;
    }
    return null;
  }

  /// Element at 1-based [rank], or null.
  (String, int)? atRank(int rank) {
    if (rank < 1 || rank > length) return null;
    var x = _head, traversed = 0;
    for (var i = _level - 1; i >= 0; i--) {
      while (x.next[i] != null && traversed + x.span[i] <= rank) {
        traversed += x.span[i];
        x = x.next[i]!;
      }
      if (traversed == rank) return (x.member, x.score);
    }
    return null;
  }
}

class Leaderboard {
  final _entries = <String, (int, int)>{}; // member -> (score, tie)
  final _list = RankedSkipList();
  var _sequence = 0;

  int get size => _list.length;
  int? scoreOf(String member) => _entries[member]?.$1;

  int addPoints(String member, int delta) {
    final old = _entries[member];
    if (old != null) _list.delete(member, old.$1, old.$2);
    final score = (old?.$1 ?? 0) + delta;
    final tie = ++_sequence; // reached this score now
    _entries[member] = (score, tie);
    _list.insert(member, score, tie);
    return score;
  }

  bool remove(String member) {
    final old = _entries.remove(member);
    return old != null && _list.delete(member, old.$1, old.$2);
  }

  int? rank(String member) {
    final e = _entries[member];
    return e == null ? null : _list.rankOf(member, e.$1, e.$2);
  }

  List<(String, int)> range(int fromRank, int toRank) => [
    for (var r = max(1, fromRank); r <= min(toRank, size); r++) _list.atRank(r)!,
  ];

  List<(String, int)> top(int k) => range(1, k);

  List<(String, int)> around(String member, int n) {
    final r = rank(member);
    return r == null ? [] : range(r - n, r + n);
  }
}

class LeaderboardService {
  final boards = <String, Leaderboard>{};

  List<String> _keys(DateTime t) {
    String two(int v) => v.toString().padLeft(2, '0');
    return ['all', 'month:${t.year}-${two(t.month)}', 'day:${t.year}-${two(t.month)}-${two(t.day)}'];
  }

  void addPoints(String member, int delta, DateTime at) {
    for (final key in _keys(at)) {
      boards.putIfAbsent(key, Leaderboard.new).addPoints(member, delta);
    }
  }

  Leaderboard board(String key) => boards[key] ?? Leaderboard();
}

// ---------- Self-checks ----------

void check(Object? actual, Object? expected) {
  if ('$actual' != '$expected') throw StateError('expected $expected, got $actual');
  print('ok: $actual');
}

void main() {
  final lb = Leaderboard()
    ..addPoints('alice', 100)
    ..addPoints('bob', 200)
    ..addPoints('carol', 150)
    ..addPoints('dave', 150); // same score as carol, reached later
  check(lb.top(3), '[(bob, 200), (carol, 150), (dave, 150)]');
  check(lb.rank('alice'), 4);
  lb.addPoints('alice', 60);
  check([lb.rank('alice'), lb.scoreOf('alice')], [2, 160]);
  check(lb.around('carol', 1), '[(alice, 160), (carol, 150), (dave, 150)]');
  check(lb.top(10).length, 4);
  check([lb.remove('bob'), lb.rank('alice'), lb.rank('bob')], [true, 1, null]);

  // Randomized cross-check against a sorted list.
  final rng = Random(7);
  final board = Leaderboard();
  final reference = <String, (int, int)>{};
  var seq = 0;
  int cmp((String, (int, int)) a, (String, (int, int)) b) {
    if (a.$2.$1 != b.$2.$1) return b.$2.$1.compareTo(a.$2.$1);
    if (a.$2.$2 != b.$2.$2) return a.$2.$2.compareTo(b.$2.$2);
    return a.$1.compareTo(b.$1);
  }

  for (var op = 0; op < 5000; op++) {
    final member = 'p${rng.nextInt(400)}';
    if (rng.nextInt(10) == 0) {
      board.remove(member);
      reference.remove(member);
    } else {
      final delta = rng.nextInt(50);
      board.addPoints(member, delta);
      reference[member] = ((reference[member]?.$1 ?? 0) + delta, ++seq);
    }
    if (op % 250 == 0 || op == 4999) {
      final sorted = [for (final e in reference.entries) (e.key, e.value)]..sort(cmp);
      for (var i = 0; i < sorted.length; i++) {
        if (board.rank(sorted[i].$1) != i + 1) throw StateError('rank mismatch at op $op');
      }
      final expectedTop = [for (final s in sorted.take(10)) (s.$1, s.$2.$1)];
      if ('${board.top(10)}' != '$expectedTop' || board.size != sorted.length) throw StateError('top mismatch');
    }
  }
  print('ok: ${board.size} members match a sorted reference after 5000 operations');

  // Windows: daily boards are independent; the monthly board sums the month.
  final service = LeaderboardService()
    ..addPoints('alice', 30, DateTime.utc(2025, 1, 1))
    ..addPoints('bob', 50, DateTime.utc(2025, 1, 1))
    ..addPoints('alice', 40, DateTime.utc(2025, 1, 2))
    ..addPoints('bob', 10, DateTime.utc(2025, 2, 1));
  check(service.board('day:2025-01-01').top(2), '[(bob, 50), (alice, 30)]');
  check(service.board('day:2025-01-02').top(2), '[(alice, 40)]');
  check(service.board('month:2025-01').top(2), '[(alice, 70), (bob, 50)]');
  check(service.board('all').top(2), '[(alice, 70), (bob, 60)]');
}
```

## 5. Walkthrough

- Carol and Dave both have 150; Carol reached it first (smaller sequence number), so she ranks 2nd and Dave 3rd.
- Alice gains 60 points: her node is deleted and re-inserted with score 160 and a new sequence number; her rank becomes 2.
- `around('carol', 1)` returns ranks 2 to 4 using `atRank`, which follows spans down the levels.
- After removing Bob, Alice is first. A removed member has no rank.
- 5,000 random updates and removals over 400 players: every rank and the top 10 match a fully sorted reference at checkpoints.
- On the window boards, January 1st and 2nd are separate, the January board sums both days for Alice (70), and Bob's February points only reach the all-time board.

## 6. Concurrency

- Redis executes each command atomically on one thread, so `ZINCRBY` is safe from many game servers at once. An in-process version needs a lock around delete + insert (they must look like one operation to readers).
- Multi-board updates are not atomic across boards; replaying the score event log repairs any partial failure.
- Reads that page through ranks (`top`, `around`) see a moment-in-time view only if done in one command; across commands, ranks may shift.

## 7. Extensibility

| Change | Where |
|---|---|
| Lowest-is-best boards (race times) | Flip the comparison in `_before`. |
| Percentile for the long tail | A score histogram alongside the skip list. |
| Friends leaderboard | Look up friends' scores in `_entries`, sort that small list. |
| Persistence | Append each `addPoints` to a log; rebuild boards by replay. |

## 8. Common mistakes in LLD rounds

- Updating a score in place without moving the node.
- Computing rank by walking level 0 (O(n)).
- Not handling ties deterministically.
- Forgetting to adjust spans of pointers that pass over an inserted or deleted node.

See [HLD.md](HLD.md) for the service architecture, durability and sharding very large boards.
