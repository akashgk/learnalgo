# Aggressive Cows

**Difficulty:** Hard | **Category:** Binary search | **Pattern:** Binary search on the answer ("maximize the minimum") | **Source:** SPOJ AGGRCOW; Striver A2Z. LeetCode 1552 (Magnetic Force Between Two Balls) is the same problem.

## The problem

Stalls are at positions given by an array (unsorted). Place `c` cows in distinct stalls so that the **minimum distance between any two cows is as large as possible**. Return that largest minimum distance.

```
stalls = [1, 2, 8, 4, 9], c = 3      ->  3    (cows at 1, 4, 8 or 1, 4, 9)
stalls = [0, 3, 4, 7, 10, 9], c = 4  ->  3    (0, 3, 7, 10)
```

## Step 1: Sort and look at it

Only the order along the line matters: sort the stalls. `[1, 2, 4, 8, 9]`.

The minimum pairwise distance of a placement is the smallest gap between **consecutive** cows. So we want to choose `c` positions from the sorted list maximizing the smallest consecutive gap.

## Step 2: Brute force

Try every subset of size `c`: `C(n, c)` subsets. Exponential.

## Step 3: Flip the question

**"Can we place `c` cows so that every two consecutive cows are at least `d` apart?"**

Greedy: put the first cow in the first stall. Put each next cow in the first stall at least `d` from the previous cow. If you place `c` cows, the answer is yes.

**Why placing each cow as early as possible is optimal:** by induction, the greedy's i-th cow is at or before the i-th cow of any valid placement. Being further left leaves more room for the rest, never less. So if any placement works, the greedy works too.

**Monotonicity:** if distance `d` is achievable, every smaller distance is achievable (the same placement works). So feasibility over `d` is `true...true false...false`, and we want the **last true**.

## Step 4: "Last true" binary search

This is the mirror of Koko's "first true":

```
while lo < hi:
  mid = lo + (hi - lo + 1) ~/ 2   // round UP
  if feasible(mid): lo = mid       // mid works, maybe larger works too
  else:             hi = mid - 1
```

**Why round up?** With `hi = lo + 1` and rounding down, `mid == lo`. If `feasible(lo)` is true, `lo = mid` changes nothing: infinite loop. Rounding up makes `mid == hi`, so both branches shrink the range.

Bounds: `lo = 1` (any two distinct stalls are at least 1 apart when positions are distinct integers), `hi = last - first` (the largest possible gap, when c = 2).

## Step 5: The code

<!-- CODE:START -->

Full source: [`aggressive_cows.dart`](aggressive_cows.dart) (run it with `dart run`).

```dart
// Aggressive Cows (also: Magnetic Force Between Two Balls).
// Place c cows in stalls (given positions) maximizing the minimum distance between any two cows.
// Sort, then binary search on the answer with a greedy placement check. O(n log n + n log D) time.

int aggressiveCows(List<int> stalls, int cows) {
  final s = [...stalls]..sort();
  var lo = 1, hi = s.last - s.first;
  // canPlace(d) is monotone: true...true false...false. Find the last true.
  while (lo < hi) {
    final mid = lo + (hi - lo + 1) ~/ 2; // round up, or lo = mid could loop forever
    if (_canPlace(s, cows, mid)) {
      lo = mid; // mid works; try larger
    } else {
      hi = mid - 1;
    }
  }
  return lo;
}

/// Greedy: put a cow in the first stall, then in each next stall at least [d] away.
bool _canPlace(List<int> s, int cows, int d) {
  var placed = 1, last = s[0];
  for (var i = 1; i < s.length && placed < cows; i++) {
    if (s[i] - last >= d) {
      placed++;
      last = s[i];
    }
  }
  return placed >= cows;
}
```

<!-- CODE:END -->

### Walkthrough

- The input is copied and sorted so the caller's list is not changed.
- `_canPlace` is the greedy, stopping early once `cows` are placed.
- The search keeps the invariant "`lo` is feasible" (1 is feasible for any `c <= n` with distinct positions) and narrows until `lo == hi`.

## Step 6: Dry run

Sorted `[1, 2, 4, 8, 9]`, c = 3, range [1, 8]:

| lo | hi | mid (rounded up) | greedy placement | feasible? | action |
|---|---|---|---|---|---|
| 1 | 8 | 5 | 1, 8 (next needs >= 13) | no (2 cows) | hi = 4 |
| 1 | 4 | 3 | 1, 4, 8 | yes | lo = 3 |
| 3 | 4 | 4 | 1, 8 (next needs >= 12) | no | hi = 3 |
| 3 | 3 | | | | return **3** |

## Complexity

- Time: **O(n log n)** to sort + **O(n log D)** for the search, D = max - min position.
- Space: **O(n)** for the sorted copy (O(1) if sorting in place is allowed).

## Edge cases

- `c == 2`: the answer is `last - first`.
- `c == n`: the answer is the smallest consecutive gap.
- Duplicate positions: then 0 can be the true answer; with `lo = 1`, the code would return 1 incorrectly. LeetCode 1552 guarantees distinct positions; if duplicates are possible, start at `lo = 0`.

## Common mistakes

- Rounding mid down in a "last true" search (infinite loop).
- Forgetting to sort.
- Checking the distance to the **first** cow instead of the **previous** cow.

## Follow-ups you should be ready for

1. **Return the placement.** Rerun the greedy with the answer.
2. **Minimize the maximum instead.** That is Split Array Largest Sum (more_problems 14): "first true" instead of "last true".
3. **Place k gas stations to minimize the maximum gap (Striver, LeetCode 774).** Binary search on a real-valued answer with a precision threshold.

## What to remember

"Maximize the minimum" is binary search on the answer with a "last true" search (round mid up). The feasibility check places items greedily as early as possible.
