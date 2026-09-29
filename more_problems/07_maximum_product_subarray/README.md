# Maximum Product Subarray

**Difficulty:** Medium | **Category:** Arrays / Dynamic Programming | **Pattern:** Kadane with max and min | **Source:** LeetCode 152; Striver A2Z, NeetCode 150

## The problem

Find the largest product of a non-empty contiguous subarray. Values can be negative or zero.

```
[2, 3, -2, 4]       ->  6     ([2, 3])
[-2, 0, -1]         ->  0
[-2, 3, -4]         ->  24    (the whole array: two negatives cancel)
[2, -5, -2, -4, 3]  ->  24    ([-2, -4, 3])
```

## Step 1: Why plain Kadane fails

Kadane's algorithm for maximum **sum** keeps "the best sum of a subarray ending here" and the rule is `bestHere = max(x, bestHere + x)`. The analogous product rule `max(x, bestHere * x)` breaks on `[-2, 3, -4]`:

- after -2: best ending here = -2
- after 3: max(3, -6) = 3
- after -4: max(-4, 3 * -4 = -12) = -4

It never finds 24. The product of the whole array is `(-2) * 3 * (-4) = 24`, but at the 3 we threw away the "very negative" subarray `[-2, 3] = -6`, which was exactly the one we needed: **multiplying a very negative number by a negative number gives a very positive one**.

## Step 2: Brute force

All subarrays with a running product: O(n^2) time, O(1) space.

## Step 3: Track the minimum too

For each position, keep **two** values:

- `maxHere`: the largest product of a subarray ending here.
- `minHere`: the smallest (most negative) product of a subarray ending here.

A subarray ending at `x` is either `[x]` alone or extends a subarray ending at the previous index. Extending the **max** by `x` is best when `x > 0`; extending the **min** by `x` is best when `x < 0`. Rather than branching on the sign, take all three candidates:

```
candidates = x, maxHere * x, minHere * x
maxHere = max(candidates), minHere = min(candidates)
```

**Zeros** handle themselves: all three candidates become 0 or `x`, so both extremes restart at 0. The next element then effectively starts a new subarray (the candidate `x` beats `0 * x` whenever `x > 0`).

**Why is tracking just these two enough?** Multiplying by `x` is monotonic: increasing if `x > 0`, decreasing if `x < 0`. So the max of `{p * x}` over all products `p` of subarrays ending at the previous index is attained at the max or the min of those `p`. No other value can win.

## Step 4: The code

<!-- CODE:START -->

Full source: [`maximum_product_subarray.dart`](maximum_product_subarray.dart) (run it with `dart run`).

```dart
// Maximum Product Subarray: the largest product of a non-empty contiguous subarray.
// Kadane-style DP tracking both the max and the min product ending here
// (a negative number turns the min into the max). O(n) time, O(1) space.

int maxProduct(List<int> nums) {
  var maxHere = nums[0], minHere = nums[0], best = nums[0];
  for (var i = 1; i < nums.length; i++) {
    final x = nums[i];
    // Candidates for a subarray ending at i: start fresh at x, or extend either extreme.
    final a = x, b = maxHere * x, c = minHere * x;
    maxHere = _max3(a, b, c);
    minHere = _min3(a, b, c);
    if (maxHere > best) best = maxHere;
  }
  return best;
}

int _max3(int a, int b, int c) => a > b ? (a > c ? a : c) : (b > c ? b : c);
int _min3(int a, int b, int c) => a < b ? (a < c ? a : c) : (b < c ? b : c);
```

<!-- CODE:END -->

### Walkthrough

- All three start at `nums[0]`: the only subarray ending at index 0 is `[nums[0]]`. Starting `best` at 0 would be wrong for `[-2]`.
- `a, b, c` are computed from the **old** `maxHere` and `minHere` before either is overwritten. Updating `maxHere` first and then using it in `minHere` is a classic bug.
- `_max3` and `_min3` are small helpers so the loop body reads like the math.

## Step 5: Dry run

`[2, -5, -2, -4, 3]`:

| element | candidate x | maxHere * x | minHere * x | new maxHere | new minHere | best |
|---|---|---|---|---|---|---|
| 2 (start) | | | | 2 | 2 | 2 |
| -5 | -5 | -10 | -10 | -5 | -10 | 2 |
| -2 | -2 | 10 | 20 | 20 | -2 | 20 |
| -4 | -4 | -80 | 8 | 8 | -80 | 20 |
| 3 | 3 | 24 | -240 | 24 | -240 | **24** |

At `-2`, the very negative `-10` (from `[2, -5]`) became `20`. At `-4`, the max 8 is `(-2) * (-4)`, then `* 3` gives 24.

## Complexity

- Time: **O(n)**.
- Space: **O(1)**.

## Edge cases

| Input | Expected | Why |
|---|---|---|
| `[-2]` | -2 | non-empty subarray required |
| `[-2, 0, -1]` | 0 | zero beats every negative product |
| `[0, 2]` | 2 | restart after the zero |

## Common mistakes

- Only tracking the max.
- Overwriting `maxHere` before computing `minHere`.
- Initializing `best` to 0 (wrong for all-negative single-element input) or to a huge negative constant while forgetting the first element.

## Follow-ups you should be ready for

1. **Alternative O(n) idea: prefix and suffix products.** The answer is the max over all prefix products and suffix products, restarting at zeros. It works because, between zeros, the best subarray always touches one end: with an even count of negatives the whole segment is best; with an odd count you drop everything up to the first negative, or everything from the last negative on.
2. **Return the subarray.** Also track the start index of the subarray behind `maxHere` and `minHere` (it can swap when `x < 0`).
3. **Overflow.** In fixed-width languages products explode quickly; LeetCode guarantees the answer fits in 32 bits, but intermediate values need care.

## What to remember

When a sign flip can turn the worst into the best, keep both extremes. Kadane for products = Kadane with a max and a min.
