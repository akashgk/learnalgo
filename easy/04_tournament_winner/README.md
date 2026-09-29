# Tournament Winner

**Difficulty:** Easy | **Category:** Arrays | **Pattern:** Hash map counting

## Problem
A round-robin tournament is described by a list of `[homeTeam, awayTeam]` pairs and a parallel `results` list where `1` means the home team won and `0` means the away team won. A win is worth 3 points and there are no ties. Exactly one team has the most points. Return its name.

```
competitions = [["HTML","C#"], ["C#","Python"], ["Python","HTML"]], results = [0, 0, 1]  ->  "Python"
```

## Building up the logic
1. You need "points per team", which is a key -> count mapping. That is a hash map.
2. Naive: fill the map, then scan it for the max. That is two passes, still O(n + k).
3. Better: keep the current leader while updating. A team's score only goes up, so the leader can only change to the team that just scored. Compare only that team with the leader.
4. Name the magic number (`homeTeamWon = 1`). Interviewers notice readability.

## Complexity
- Time: O(n) where n is the number of competitions.
- Space: O(k) where k is the number of teams.

## Edge cases
- Single competition.
- The empty-string sentinel leader starts at 0 points, so the first winner always takes the lead.

## Interview notes
- Dart note: `final [home, away] = competitions[i];` is a Dart 3 list pattern. It throws if the inner list does not have exactly two elements, which is a reasonable contract check.
- `Map.update(..., ifAbsent: ...)` does the insert-or-increment in one call and returns the new value.
