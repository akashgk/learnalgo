# Burst Balloons

**Difficulty:** Hard | **Category:** Dynamic Programming | **Pattern:** Interval DP on the last action | **Source:** LeetCode 312; Striver A2Z, NeetCode 150

## The problem

Balloons with values `nums`. Bursting balloon `i` earns `left * nums[i] * right`, where `left` and `right` are the values of its **current** neighbors (balloons already burst no longer count as neighbors). Beyond the ends, treat the value as 1. Burst all balloons; maximize the total.

```
[3, 1, 5, 8]  ->  167
burst 1: 3*1*5 = 15   -> [3, 5, 8]
burst 5: 3*5*8 = 120  -> [3, 8]
burst 3: 1*3*8 = 24   -> [8]
burst 8: 1*8*1 = 8    -> []
total 167
```

## Step 1: Brute force

Try every order: n! orders. Exponential.

## Step 2: Why "which balloon first?" fails

The natural DP would split on the **first** balloon to burst. But after bursting `k` first, its old neighbors become **adjacent**, so the left part and the right part are no longer independent: the coins for a balloon in the left part may depend on a balloon in the right part. The subproblems do not separate.

## Step 3: Split on the balloon burst LAST

Consider an open interval `(l, r)`: all balloons strictly between `l` and `r`, where `l` and `r` themselves are still present. Pick `k` to be the **last** balloon burst in that interval.

- While the balloons between `l` and `k` are being burst, `k` is still there. So that group is bounded by `l` and `k` on both sides: an independent subproblem `(l, k)`.
- Same for `(k, r)`.
- When `k` finally bursts, everything else in `(l, r)` is gone, so its neighbors are exactly `l` and `r`: it earns `a[l] * a[k] * a[r]`.

```
dp[l][r] = max over l < k < r of  dp[l][k] + a[l] * a[k] * a[r] + dp[k][r]
```

Pad the array with a 1 at each end, `a = [1, ...nums, 1]`. Those two boundary balloons are never burst. The answer is `dp[0][n - 1]` over the padded array.

This "choose the last operation" trick is the key idea for a family of interval DPs (Matrix Chain Multiplication, Minimum Cost to Cut a Stick, Striver's "partition DP" section).

## Step 4: Fill order

`dp[l][r]` needs shorter intervals, so loop by interval length `len = r - l` from 2 (one balloon inside) up to `n - 1`.

## Step 5: The code

<!-- CODE:START -->

Full source: [`burst_balloons.dart`](burst_balloons.dart) (run it with `dart run`).

```dart
// Burst Balloons: bursting balloon i earns left * nums[i] * right, where left/right are its current
// neighbors (1 beyond the ends). Maximize total coins.
// Interval DP on the LAST balloon burst in each open interval. O(n^3) time, O(n^2) space.

int maxCoins(List<int> nums) {
  final a = [1, ...nums, 1]; // padding: the boundaries act as balloons worth 1 that are never burst
  final n = a.length;
  // dp[l][r] = best coins from bursting every balloon strictly between l and r.
  final dp = List.generate(n, (_) => List<int>.filled(n, 0));
  for (var len = 2; len < n; len++) {
    for (var l = 0; l + len < n; l++) {
      final r = l + len;
      for (var k = l + 1; k < r; k++) {
        // k is burst last in (l, r): at that moment its neighbors are exactly l and r.
        final coins = dp[l][k] + a[l] * a[k] * a[r] + dp[k][r];
        if (coins > dp[l][r]) dp[l][r] = coins;
      }
    }
  }
  return dp[0][n - 1];
}
```

<!-- CODE:END -->

### Walkthrough

- `a` is the padded array; `n` is its length.
- `dp[l][r]` stays 0 when `r = l + 1` (no balloons inside).
- Three nested loops: length, left end, last balloon.

## Step 6: Dry run

Padded `a = [1, 3, 1, 5, 8, 1]` (indices 0..5). The filled table `dp[l][r]`:

| l \ r | 2 | 3 | 4 | 5 |
|---|---|---|---|---|
| 0 | 3 | 30 | 159 | **167** |
| 1 | | 15 | 135 | 159 |
| 2 | | | 40 | 48 |
| 3 | | | | 40 |

For the full interval `(0, 5)`, the best last balloon is `k = 4` (value 8): `dp[0][4] + 1 * 8 * 1 + dp[4][5] = 159 + 8 + 0 = 167`. And `dp[1][3] = 15` is "burst the 1 between 3 and 5": `3 * 1 * 5`.

## Complexity

- Time: **O(n^3)**.
- Space: **O(n^2)**.

## Edge cases

- Empty: 0.
- One balloon: its value (`1 * x * 1`).
- Zeros: a zero balloon earns nothing and multiplies its neighbors' products by zero when it is a neighbor; the DP handles it without special cases.

## Common mistakes

- Splitting on the first balloon burst.
- Forgetting the padding (boundary neighbors are 1).
- Using closed intervals and mixing up which endpoints are still present.

## Follow-ups you should be ready for

1. **Matrix Chain Multiplication (Striver).** `dp[i][j] = min over k of dp[i][k] + dp[k][j] + dims[i] * dims[k] * dims[j]`: the same recurrence shape.
2. **Minimum Cost to Cut a Stick (LeetCode 1547).** Add the stick ends as boundaries, split on the **first** cut (here the first cut separates the stick into independent pieces).
3. **Top-down version.** Memoized recursion on `(l, r)` is often easier to write under pressure.

## What to remember

When an action changes the neighbors of what remains, split the interval on the action taken **last**: its neighbors are then fixed as the interval's endpoints, and the two sides become independent.
