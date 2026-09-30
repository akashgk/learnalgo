# House Robber II

**Difficulty:** Medium | **Category:** 1-D Dynamic Programming | **Pattern:** Break the circle into two lines | **Source:** LeetCode 213; NeetCode 150, Blind 75

## The problem

Houses are arranged in a **circle**. You cannot rob two adjacent houses, and the first and last houses are adjacent. Maximize the total.

```
[2, 3, 2]         ->  3   (2 + 2 would use the first and last house)
[1, 2, 3, 1]      ->  4
[2, 7, 9, 3, 1]   ->  11  (2 + 9; the straight-line answer 2 + 9 + 1 = 12 uses both ends)
```

## Step 1: Recall House Robber I (a line)

AlgoExpert medium 28 Max Subset Sum No Adjacent:

```
best[i] = max(best[i-1], best[i-2] + nums[i])
```

skip house `i`, or rob it and add the best up to two houses back. O(n) time, O(1) space with two variables.

## Step 2: What the circle changes

The only new constraint is "not both house 0 and house n - 1". Split on that:

- **Case A:** house n - 1 is not robbed. Then the problem is a line: houses `0..n-2`.
- **Case B:** house 0 is not robbed. The line is houses `1..n-1`.

Every valid circular choice avoids at least one of the two ends, so it is counted in case A or case B (possibly both). And every choice in either case is valid on the circle. So:

```
answer = max(robLine(0..n-2), robLine(1..n-1))
```

With one house, both ranges are empty; handle `n == 1` separately.

## Step 3: The code

<!-- CODE:START -->

Full source: [`house_robber_ii.dart`](house_robber_ii.dart) (run it with `dart run`).

```dart
// House Robber II: houses in a CIRCLE; adjacent houses cannot both be robbed, and the first and last
// houses are adjacent. Maximize the loot.
// The first and last house cannot both be taken, so the answer is the better of two straight-line
// problems: houses 0..n-2 and houses 1..n-1. O(n) time, O(1) space.

int rob(List<int> nums) {
  if (nums.length == 1) return nums[0];
  final skipLast = _robLine(nums, 0, nums.length - 2);
  final skipFirst = _robLine(nums, 1, nums.length - 1);
  return skipLast > skipFirst ? skipLast : skipFirst;
}

/// House Robber I on nums[lo..hi]: best = max(skip this house, take it + best two back).
int _robLine(List<int> nums, int lo, int hi) {
  var twoBack = 0, oneBack = 0;
  for (var i = lo; i <= hi; i++) {
    final take = twoBack + nums[i];
    final here = take > oneBack ? take : oneBack;
    twoBack = oneBack;
    oneBack = here;
  }
  return oneBack;
}
```

<!-- CODE:END -->

### Walkthrough

- `_robLine(nums, lo, hi)` is House Robber I on a sub-range, with two rolling variables.
- The special case `nums.length == 1` returns the single house.

## Step 4: Dry run

`[2, 7, 9, 3, 1]`:

| range | houses | best |
|---|---|---|
| 0..3 | 2 7 9 3 | 2 + 9 = 11 |
| 1..4 | 7 9 3 1 | 7 + 3 = 10 (or 9 + 1 = 10) |

Answer **11**.

## Complexity

- Time: **O(n)** (two linear passes).
- Space: **O(1)**.

## Edge cases

- One house: its value.
- Two houses: the larger one.

## Common mistakes

- Running House Robber I on the whole array (can use both ends).
- Excluding both ends at once (misses answers that use one end).
- Forgetting the single-house case (both ranges would be empty and return 0).

## Follow-ups you should be ready for

1. **House Robber III (LeetCode 337).** Houses on a binary tree: each node returns (best if robbed, best if not).
2. **Circular maximum subarray (LeetCode 918).** Another circle-breaking trick: max of the normal answer and total minus the minimum subarray.

## What to remember

To handle a circle, find the one constraint the circle adds, and split into cases that each reduce to the straight-line problem.
