# Tournament Winner

**Difficulty:** Easy | **Category:** Arrays | **Pattern:** Hash map counting

## The problem

Teams play a round-robin tournament. You get:

- `competitions`: a list of `[homeTeam, awayTeam]` pairs;
- `results`: a list of the same length, where `results[i] == 1` means the home team won competition `i` and `0` means the away team won.

A win is worth 3 points. There are no ties, and exactly one team finishes with the most points. Return that team's name.

```
competitions = [["HTML", "C#"], ["C#", "Python"], ["Python", "HTML"]]
results      = [0, 0, 1]
-> "Python"
```

Round 1: away team C# wins. Round 2: away team Python wins. Round 3: home team Python wins. Python has 6 points, C# 3, HTML 0.

### Clarifying questions

- Can a team play itself? (No.)
- Is the winner guaranteed unique? (Yes. If not, you would ask for a tie-break rule.)
- Are team names case-sensitive? (Assume yes.)

## Step 1: Work an example by hand

On paper you would keep a scoreboard: a table from team name to points. For each match, find the winner, add 3 to their row. At the end, pick the row with the most points.

A "table from name to value" is a **hash map**. That is the whole data structure question answered.

## Step 2: Straightforward solution

1. Build the scoreboard: for each competition, add 3 to the winner.
2. Scan the scoreboard for the maximum.

Both steps are linear, so this is already O(n + k) where n is the number of competitions and k the number of teams. There is no slow brute force to improve on; the interesting part is doing it cleanly and in one pass.

## Step 3: Refine: track the leader as you go

Points only ever increase. So after each match, the only team whose standing changed is the winner of that match. The leader can therefore only change to **that** team. Compare just that one team against the current leader after each update, and you never need the second pass.

This matters little for performance (both are O(n)), but it demonstrates an important habit: **ask what can change after each step, and only re-check that.**

## Step 4: The code

<!-- CODE:START -->

Full source: [`tournament_winner.dart`](tournament_winner.dart) (run it with `dart run`).

```dart
// Tournament Winner
// Tally points per team in a map, tracking the leader as we go. O(n) time, O(k) space.

const homeTeamWon = 1;

String tournamentWinner(List<List<String>> competitions, List<int> results) {
  final points = <String, int>{};
  var leader = '';
  points[leader] = 0;
  for (var i = 0; i < competitions.length; i++) {
    final [home, away] = competitions[i];
    final winner = results[i] == homeTeamWon ? home : away;
    final score = points.update(winner, (p) => p + 3, ifAbsent: () => 3);
    if (score > points[leader]!) leader = winner;
  }
  return leader;
}
```

<!-- CODE:END -->

### Walkthrough

- `const homeTeamWon = 1;` gives the magic number a name. Interviewers notice readability details like this.
- `var leader = ''; points[leader] = 0;` is a **sentinel**: an imaginary team with 0 points, so the first real winner (3 points) always becomes leader and we never need an "is the map empty?" check.
- `final [home, away] = competitions[i];` is a Dart 3 list pattern. It unpacks the pair and throws if the inner list does not have exactly two elements.
- `results[i] == homeTeamWon ? home : away` picks the winner.
- `points.update(winner, (p) => p + 3, ifAbsent: () => 3)` adds 3 points, or inserts 3 for a first win, and returns the new score.
- `if (score > points[leader]!) leader = winner;` is the only comparison needed per match (Step 3).

## Step 5: Dry run

| i | match | result | winner | points after | leader |
|---|---|---|---|---|---|
| start | | | | {"": 0} | "" |
| 0 | HTML vs C# | 0 | C# | {"": 0, C#: 3} | C# |
| 1 | C# vs Python | 0 | Python | {..., C#: 3, Python: 3} | C# (3 is not > 3) |
| 2 | Python vs HTML | 1 | Python | {..., Python: 6} | Python |

## Complexity

- **Time: O(n)**: one pass over the competitions, O(1) average map work per match.
- **Space: O(k)**: one map entry per team (plus the sentinel).

## Edge cases

- A single competition: the winner of that match.
- Ties during the tournament (as at step 1 above) do not matter, because the final winner is unique. With strict `>`, the earlier leader keeps the lead on a tie.

## Common mistakes

- Mixing up the meaning of `1` and `0` in `results`.
- Initializing `leader` to the first competition's home team without giving it a points entry, which causes a null lookup.
- Recomputing the maximum over the whole map after every match: correct, but O(n * k).

## Follow-ups

1. **Return the full standings sorted by points.** Sort the map entries: O(k log k).
2. **Ties are possible; break them by name.** Compare `(score, name)` pairs.
3. **Streaming results, and "who leads right now?" queries.** The running-leader approach already answers that in O(1). If a team's score could also go **down** (penalties), the leader could be anyone, and you would need a max-heap or a sorted structure keyed by score.

## What to remember

"Count things by key" means a hash map. When values only increase, the maximum can only change to the key that was just updated.
