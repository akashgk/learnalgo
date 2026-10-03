# Online Multiplayer Turn-Based Game: Low-Level Design

## 1. Scope for the LLD round

- **Board:** N x N, K in a row to win (classic tic-tac-toe is 3 and 3); win check in **O(K)** around the last move.
- **Game:** two players, alternating turns, **every move validated** (game over, whose turn, bounds, occupied); duplicate move messages ignored by move number; **turn timer** with forfeit; a move log.
- **Elo ratings** after each game.
- **Matchmaker:** pairs the closest-rated waiting players whose rating window allows it; the window **widens with waiting time**.

Out of scope: networking, persistence of the move log, spectators (HLD).

## 2. Entities and responsibilities

| Class | Responsibility |
|---|---|
| `Mark` | X or O. |
| `Board` | Cells, placement, win detection through the last move, full-board check. |
| `GameStatus` | In progress, X won, O won, draw. |
| `Game` | Players, turn, clock, validation, timeout, log. |
| `elo` | Rating update for one game. |
| `Matchmaker` | Waiting pool, widening windows, pairing. |

```text
Matchmaker --pairs--> Game(playerX, playerO) --has--> Board(n, k)
Game.move(player, r, c, now, moveNumber): timeout? -> validate -> Board.place -> win/draw? -> switch turn
game over --> elo(ratingX, ratingO, result)
```

## 3. Design decisions and why

- **Win check only through the last move:** a new line can only include the newly placed mark, so counting in 4 directions from it is enough: O(K) per move instead of O(N^2).
- **The server owns the rules:** `Game.move` is the only way to change the board; everything a client sends is validated.
- **Move numbers make moves idempotent:** a resent message for an already applied move is ignored instead of being rejected as "not your turn".
- **Timeouts checked lazily** on every action (and by a periodic sweep in production), using the server's clock.
- **Widening windows:** quick, close matches for most players; outliers still get a game after waiting.

## 4. The code

```dart
import 'dart:math';

enum Mark { x, o }

class Board {
  Board(this.n, this.k) : _cells = List<Mark?>.filled(n * n, null);
  final int n;
  final int k;
  final List<Mark?> _cells;
  var filled = 0;

  Mark? at(int r, int c) => _cells[r * n + c];
  bool inBounds(int r, int c) => r >= 0 && c >= 0 && r < n && c < n;
  bool get isFull => filled == n * n;

  void place(int r, int c, Mark m) {
    _cells[r * n + c] = m;
    filled++;
  }

  int _run(int r, int c, int dr, int dc, Mark m) {
    var count = 0;
    for (var i = r + dr, j = c + dc; inBounds(i, j) && at(i, j) == m; i += dr, j += dc) {
      count++;
    }
    return count;
  }

  /// Does the mark at (r, c) complete K in a row? Only lines through (r, c) can have changed.
  bool winsAt(int r, int c) {
    final m = at(r, c)!;
    for (final (dr, dc) in const [(0, 1), (1, 0), (1, 1), (1, -1)]) {
      if (1 + _run(r, c, dr, dc, m) + _run(r, c, -dr, -dc, m) >= k) return true;
    }
    return false;
  }
}

enum GameStatus { inProgress, xWon, oWon, draw }

class MoveRejected implements Exception {
  MoveRejected(this.reason);
  final String reason;
  @override
  String toString() => reason;
}

class Game {
  Game(this.id, this.playerX, this.playerO, {int n = 3, int k = 3, this.turnSeconds = 30, int startedAt = 0})
    : board = Board(n, k),
      _turnStartedAt = startedAt;

  final String id;
  final String playerX;
  final String playerO;
  final int turnSeconds;
  final Board board;
  var status = GameStatus.inProgress;
  var turn = Mark.x;
  var moveNumber = 0;
  int _turnStartedAt;
  final log = <String>[];

  String playerOf(Mark m) => m == Mark.x ? playerX : playerO;

  void checkTimeout(int now) {
    if (status == GameStatus.inProgress && now - _turnStartedAt > turnSeconds) {
      status = turn == Mark.x ? GameStatus.oWon : GameStatus.xWon;
      log.add('${playerOf(turn)} timed out');
    }
  }

  void move(String player, int r, int c, {required int now, int? number}) {
    if (number != null && number <= moveNumber) return; // duplicate delivery of an applied move
    checkTimeout(now);
    if (status != GameStatus.inProgress) throw MoveRejected('game is over');
    if (player != playerOf(turn)) throw MoveRejected('not your turn');
    if (!board.inBounds(r, c)) throw MoveRejected('out of bounds');
    if (board.at(r, c) != null) throw MoveRejected('cell occupied');
    board.place(r, c, turn);
    moveNumber++;
    log.add('$moveNumber. $player ($r,$c)');
    if (board.winsAt(r, c)) {
      status = turn == Mark.x ? GameStatus.xWon : GameStatus.oWon;
    } else if (board.isFull) {
      status = GameStatus.draw;
    } else {
      turn = turn == Mark.x ? Mark.o : Mark.x;
      _turnStartedAt = now;
    }
  }
}

/// Elo with factor [k]. [scoreA] is 1 for an A win, 0.5 for a draw, 0 for a loss.
(int, int) elo(int ra, int rb, double scoreA, {int k = 32}) {
  final expectedA = 1 / (1 + pow(10, (rb - ra) / 400));
  final delta = k * (scoreA - expectedA);
  return ((ra + delta).round(), (rb - delta).round());
}

class Matchmaker {
  Matchmaker({this.baseWindow = 50, this.widenPerSecond = 10});
  final int baseWindow;
  final int widenPerSecond;
  final _waiting = <(String, int, int)>[]; // (player, rating, joinedAt), in join order

  void join(String player, int rating, int now) => _waiting.add((player, rating, now));
  int get waiting => _waiting.length;

  int _window((String, int, int) p, int now) => baseWindow + widenPerSecond * (now - p.$3);

  /// Pairs the longest-waiting players first with their closest acceptable opponent.
  List<(String, String)> tick(int now) {
    final pairs = <(String, String)>[];
    var i = 0;
    while (i < _waiting.length) {
      final p = _waiting[i];
      (String, int, int)? best;
      for (final q in _waiting) {
        if (identical(q, p)) continue;
        final diff = (p.$2 - q.$2).abs();
        if (diff <= max(_window(p, now), _window(q, now)) && (best == null || diff < (p.$2 - best.$2).abs())) best = q;
      }
      if (best == null) {
        i++;
        continue;
      }
      pairs.add((p.$1, best.$1));
      _waiting
        ..remove(p)
        ..remove(best);
    }
    return pairs;
  }
}

// ---------- Self-checks ----------

void check(Object? actual, Object? expected) {
  if ('$actual' != '$expected') throw StateError('expected $expected, got $actual');
  print('ok: $actual');
}

String reject(void Function() f) {
  try {
    f();
    return 'accepted';
  } on MoveRejected catch (e) {
    return e.reason;
  }
}

void main() {
  // Classic 3x3: X completes the top row.
  final g = Game('g1', 'xena', 'oscar');
  var t = 0;
  void play(Game game, List<(int, int)> moves) {
    for (final (r, c) in moves) {
      game.move(game.playerOf(game.turn), r, c, now: t += 5);
    }
  }

  play(g, [(0, 0), (1, 0), (0, 1), (1, 1), (0, 2)]);
  check(g.status, GameStatus.xWon);
  check(reject(() => g.move('oscar', 2, 2, now: t)), 'game is over');

  // Diagonal win for O and a draw.
  final g2 = Game('g2', 'a', 'b', startedAt: t);
  play(g2, [(0, 1), (0, 0), (0, 2), (1, 1), (2, 1), (2, 2)]);
  check(g2.status, GameStatus.oWon);
  final g3 = Game('g3', 'a', 'b', startedAt: t);
  play(g3, [(0, 0), (0, 1), (0, 2), (1, 1), (1, 0), (1, 2), (2, 1), (2, 0), (2, 2)]);
  check(g3.status, GameStatus.draw);

  // 5x5, four in a row: three on the anti-diagonal is not enough, four is.
  final big = Game('g4', 'a', 'b', n: 5, k: 4, startedAt: t);
  play(big, [(0, 4), (0, 0), (1, 3), (0, 1), (2, 2), (4, 4)]);
  check(big.status, GameStatus.inProgress);
  play(big, [(3, 1)]);
  check(big.status, GameStatus.xWon);

  // Validation and duplicate messages.
  final v = Game('g5', 'xena', 'oscar', startedAt: t);
  check(
    [reject(() => v.move('oscar', 0, 0, now: t)), reject(() => v.move('xena', 3, 0, now: t))],
    ['not your turn', 'out of bounds'],
  );
  v.move('xena', 1, 1, now: t, number: 1);
  v.move('xena', 1, 1, now: t, number: 1); // resent message: ignored, not an error
  check([v.moveNumber, reject(() => v.move('oscar', 1, 1, now: t, number: 2))], [1, 'cell occupied']);

  // Turn timer: O does not move within 30 seconds and forfeits.
  v.checkTimeout(t + 31);
  check([v.status, v.log.last], [GameStatus.xWon, 'oscar timed out']);

  // Elo.
  check(
    [elo(1500, 1500, 1), elo(1600, 1400, 1), elo(1400, 1600, 1), elo(1500, 1500, 0.5)],
    [(1516, 1484), (1608, 1392), (1424, 1576), (1500, 1500)],
  );

  // Matchmaking with widening windows.
  final mm = Matchmaker()
    ..join('ann', 1500, 0)
    ..join('ben', 1520, 0)
    ..join('cat', 1800, 0);
  check(mm.tick(0), '[(ann, ben)]'); // cat has nobody within 50
  mm.join('dan', 1700, 10);
  check(mm.tick(10), '[(cat, dan)]'); // cat's window has grown to 150 after 10 s
  mm.join('eve', 2300, 10);
  check([mm.tick(20), mm.waiting], ['[]', 1]);
}
```

## 5. Walkthrough

- X takes the top row on the fifth move; any later move is rejected because the game is over.
- O wins on the main diagonal in game 2; game 3 fills the board with no line: draw.
- On 5 x 5 with K = 4, X has three on the anti-diagonal ((0,4), (1,3), (2,2)) and the game continues; (3,1) makes four. Only the four lines through (3,1) were examined.
- O moving first, or X playing off the board, are rejected. A resent copy of move 1 is silently ignored; O's attempt at the occupied center is rejected.
- O does not move within 30 seconds: X wins by forfeit, and the log records it.
- Elo: equal players exchange 16 points; the favorite (1600) gains only 8 for an expected win; an upset gains 24; a draw between equals changes nothing.
- Ann (1500) and Ben (1520) pair immediately. Cat (1800) waits; after 10 s her window is 150, so Dan (1700) pairs with her. Eve (2300) has nobody in range.

## 6. Concurrency

- Each game is owned by one game server shard and processed on one thread/actor, so moves for a game are serialized and need no locks.
- The matchmaker runs per mode/region on a single coordinator (or partitions the rating space), so a player cannot be paired twice.
- Rating updates after a game are applied once per game ID (idempotent), even if the game-over event is delivered twice.

## 7. Extensibility

| Change | Where |
|---|---|
| Chess or Connect Four | A different `Board` with its own move legality and end detection; `Game` keeps turns, timers and logs. |
| Whole-game clocks (blitz) | Per-player remaining time instead of a per-turn limit. |
| Spectators | Publish each log entry to subscribers (see 34). |
| Glicko ratings | Track rating deviation; replace `elo`. |
| Avoid rematches | Matchmaker remembers recent opponents and skips them. |

## 8. Common mistakes in LLD rounds

- Scanning the full board for a winner after each move.
- Hard-coding 3 x 3.
- Accepting moves without checking whose turn it is.
- Treating a duplicated network message as an illegal move.

See [HLD.md](HLD.md) for game servers, durability and matchmaking at scale.
