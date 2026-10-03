# Online Multiplayer Turn-Based Game (tic-tac-toe, chess, Words with Friends): High-Level Design

**Asked at:** Microsoft, Amazon, Meta, Riot, Zynga, chess.com, and as the "design tic-tac-toe" LLD question. **Core topics:** matchmaking by skill, authoritative game servers, real-time move delivery, reconnection, turn timers, rating systems (Elo), spectators and cheating.

## 1. Clarify the scope

| Question | Assumed answer |
|---|---|
| Game? | Turn-based board games (tic-tac-toe on N x N with K in a row; the design carries over to chess). |
| Modes? | Ranked matchmaking, play with a friend (invite link), spectators. |
| Scale? | 1 M concurrent players; ~500K games in progress. |
| Latency? | Moves appear to the opponent within ~200 ms. |
| Fairness? | Server-authoritative: clients cannot make illegal moves or change the result. |

## 2. Requirements

**Functional:** queue for a match, get paired with a similar-skill opponent, play with per-turn time limits, win/draw/forfeit detection, rating updates, rematch, reconnect after a dropped connection, game history.

**Non-functional:** low latency, no lost games on server failure (game state durable per move), anti-cheat basics, horizontal scaling.

## 3. Capacity estimates

| Quantity | Math | Result |
|---|---|---|
| Concurrent games | 500K | each game is tiny state (a board + clocks) |
| Moves | 500K games x 1 move / 10 s | **~50K moves/s** |
| WebSocket connections | 1 M | ~10-20 game gateway servers at 50-100K connections each |
| Game history | 5 M games/day x ~1 KB | **~5 GB/day** |

## 4. Architecture

```text
 client --WebSocket--> gateway --(route by game ID)--> Game server shard (authoritative, in memory)
                                                         | validate move, update board and clocks,
                                                         | detect end, append move to the game log
                                                         v
                                               game log (Redis stream / Cassandra) for recovery
 client --> Matchmaking service: queue per mode; pairs by rating window; creates a game on a game shard
 game end --> Rating service (Elo/Glicko) --> leaderboard (see 24); history store
 spectators subscribe to the game's move stream (pub/sub, see 34)
```

## 5. Deep dives

- **Authoritative server:** the client only sends intentions ("place at row 2, col 1"); the server checks turn, bounds, occupancy, and timers, then broadcasts the result. Clients render; they never decide outcomes.
- **Win detection:** after each move, check only lines through the last move (4 directions), O(K) instead of scanning the board.
- **Durability:** append each accepted move to a log; if a game server dies, another loads the log and resumes; clients reconnect via the gateway using the game ID.
- **Timers:** per-turn or per-game clocks maintained by the server; a timeout forfeits.
- **Matchmaking:** players wait in a pool; pair players whose ratings are within a window that **widens with waiting time** (fast matches for common ratings, eventually a match for outliers). Avoid immediate rematches against the same opponent in ranked play.
- **Ratings:** Elo: expected score `E = 1 / (1 + 10^((Rb - Ra) / 400))`; new rating `Ra + K (S - E)`. Glicko adds rating uncertainty.

## 6. Failure modes

| Failure | Behavior |
|---|---|
| Player disconnects | Grace period to reconnect; their clock keeps running; forfeit on timeout. |
| Game server crash | Reload state from the move log on another server; clients reconnect. |
| Duplicate move messages | Moves carry a move number; duplicates are ignored. |
| Matchmaking backlog | Widen windows faster; show estimated wait. |

## 7. What interviewers look for

- (HLD) Matchmaking with widening windows, authoritative servers, durable move logs, reconnection.
- (LLD) Clean board/game/player classes, O(K) win detection, validation of every move, timers, rating updates.

## 8. Common mistakes

- Trusting the client to report wins.
- Scanning the whole board after each move.
- No handling of disconnects and timeouts.

## 9. Follow-ups

1. **Real-time games** (shooters): client prediction, server reconciliation, tick rates; very different from turn-based.
2. **Tournaments:** brackets and scheduling.
3. **Cheat detection in chess:** engine-move similarity analysis offline.

See [LLD.md](LLD.md) for an N x N, K-in-a-row board with O(K) win checks, a game with turn validation and timeouts, Elo updates and a matchmaker with widening windows.
