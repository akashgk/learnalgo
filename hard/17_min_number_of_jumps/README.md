# Min Number Of Jumps

**Difficulty:** Hard | **Category:** Dynamic Programming | **Pattern:** DP O(n^2) -> greedy level expansion O(n)

## The problem

Each element of an array is the **maximum** number of positions you may jump forward from that index. Starting at index 0, return the minimum number of jumps needed to reach the last index. Assume it is always reachable.

```
[3, 4, 2, 1, 2, 3, 7, 1, 1, 1, 3]  ->  4     (0 -> 1 -> 5 -> 6 -> 10, for example)
```

## Step 1: DP solution

`jumps[i]` = the fewest jumps to reach index `i`. `jumps[0] = 0`. For every `i`, for every earlier `j` that can reach `i` (`j + array[j] >= i`), `jumps[i] = min(jumps[j] + 1)`.

**O(n^2) time, O(n) space.** Present this first.

## Step 2: See the problem as BFS

Group indices by the fewest jumps needed to reach them:

- 0 jumps: `{0}`.
- 1 jump: everything reachable from index 0: `[1, 3]`.
- 2 jumps: everything newly reachable from `[1, 3]`: from index 1 (value 4) up to index 5.
- ...

These groups are exactly **BFS levels**, and each level is a **contiguous range** of indices. So we do not need a queue: just track where the current level ends and how far the next level reaches.

## Step 3: The greedy scan

- `farthest` = the farthest index reachable from anything seen so far.
- `currentEnd` = the last index of the current level.
- Scan `i` from 0 to `n - 2` (you never jump **from** the last index):
  - update `farthest = max(farthest, i + array[i])`;
  - when `i == currentEnd`, the current level is fully scanned: take one more jump and set `currentEnd = farthest`.

## Step 4: The code

<!-- CODE:START -->

Full source: [`min_number_of_jumps.dart`](min_number_of_jumps.dart) (run it with `dart run`).

```dart
// Min Number Of Jumps: array[i] is the max jump length from i. Min jumps to reach the end.
// Greedy BFS by levels: each "level" is the range reachable with j jumps. O(n) time, O(1) space.

int minNumberOfJumps(List<int> array) {
  if (array.length <= 1) return 0;
  var jumps = 0, currentEnd = 0, farthest = 0;
  for (var i = 0; i < array.length - 1; i++) {
    if (i + array[i] > farthest) farthest = i + array[i];
    if (i == currentEnd) {
      // Finished scanning everything reachable with `jumps` jumps; take one more.
      jumps++;
      currentEnd = farthest;
      if (currentEnd >= array.length - 1) break;
    }
  }
  return jumps;
}
```

<!-- CODE:END -->

### Walkthrough

- `if (array.length <= 1) return 0;` already at the end.
- The loop runs to `length - 2`.
- `if (i == currentEnd)`: every index reachable with the current number of jumps has been considered; jump once more.
- Early `break` once the new level reaches the end.

## Step 5: Dry run

`[3, 4, 2, 1, 2, 3, 7, 1, 1, 1, 3]` (last index 10):

| i | i + a[i] | farthest | i == currentEnd? | jumps | currentEnd |
|---|---|---|---|---|---|
| 0 | 3 | 3 | yes | 1 | 3 |
| 1 | 5 | 5 | | | |
| 2 | 4 | 5 | | | |
| 3 | 4 | 5 | yes | 2 | 5 |
| 4 | 6 | 6 | | | |
| 5 | 8 | 8 | yes | 3 | 8 |
| 6 | 13 | 13 | | | |
| 7, 8 | 8, 9 | 13 | at 8: yes | 4 | 13 (>= 10: stop) |

Answer: 4.

## Complexity

| Approach | Time | Space |
|---|---|---|
| DP | O(n^2) | O(n) |
| Greedy levels | O(n) | O(1) |

## Common mistakes

- Looping to the last index (counts an extra jump when `currentEnd` lands exactly on it).
- Greedily jumping to the **largest value** instead of tracking the farthest reach (not optimal).

## Follow-ups

1. **Jump Game II (LeetCode #45):** identical.
2. **Jump Game (#55):** can you reach the end at all? Track `farthest`; fail if `i > farthest`.
3. **Jump Game III / IV (#1306, #1345):** general BFS on an explicit graph.

## What to remember

When BFS levels are contiguous ranges, you can run BFS with two numbers instead of a queue: the end of the current level and the farthest reach of the next.
