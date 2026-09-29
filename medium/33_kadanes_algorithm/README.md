# Kadane's Algorithm

**Difficulty:** Medium | **Category:** Famous Algorithms | **Pattern:** DP on "best ending here"

## The problem

Given a non-empty array of integers (possibly negative), return the maximum sum of any **non-empty contiguous** subarray.

```
[3, 5, -9, 1, 3, -2, 3, 4, 7, 2, -9, 6, 3, 1, -5, 4]  ->  19   ([1, 3, -2, 3, 4, 7, 2, -9, 6, 3, 1])
[-1, -2, -3]                                          ->  -1
```

## Step 1: Work an example by hand

Walk left to right keeping a running sum of "the current stretch":

- `3`, then `3 + 5 = 8`, then `8 - 9 = -1`.
- At this point the stretch sums to -1. Should the next element `1` extend this stretch? Extending gives `-1 + 1 = 0`; starting fresh gives `1`. A negative running sum can only **hurt** whatever comes next, so drop it and start fresh at `1`.

That single observation is Kadane's algorithm.

## Step 2: Brute force

All subarrays with running sums: O(n^2). (Without running sums, O(n^3).)

## Step 3: The DP view

The key trick is choosing the right subproblem. "Best subarray within the first i elements" is hard to extend. Instead:

**Subproblem:** `E[i]` = the best sum of a subarray that **ends exactly at index i** (it must include `a[i]`).

A subarray ending at `i` is either just `[a[i]]`, or it extends a subarray ending at `i - 1`. The best extension uses the best such subarray, `E[i-1]`:

```
E[i] = max(a[i], E[i-1] + a[i])
answer = max over all i of E[i]
```

`E[i-1] + a[i] < a[i]` exactly when `E[i-1] < 0`: the "drop a negative running sum" rule from Step 1.

Since `E[i]` only needs `E[i-1]`, keep one variable. O(n) time, O(1) space.

"Ending at i" formulations appear all over DP: Longest Increasing Subsequence, Max Sum Increasing Subsequence, longest valid parentheses, and more.

## Step 4: The code

<!-- CODE:START -->

Full source: [`kadanes_algorithm.dart`](kadanes_algorithm.dart) (run it with `dart run`).

```dart
// Kadane's Algorithm: maximum sum of a non-empty contiguous subarray.
// bestEndingHere = max(x, bestEndingHere + x). O(n) time, O(1) space.

int kadanesAlgorithm(List<int> array) {
  var endingHere = array[0], best = array[0];
  for (var i = 1; i < array.length; i++) {
    final x = array[i];
    endingHere = x > endingHere + x ? x : endingHere + x;
    if (endingHere > best) best = endingHere;
  }
  return best;
}
```

<!-- CODE:END -->

### Walkthrough

- `endingHere` is `E[i]`; `best` is the maximum seen so far. Both start at `array[0]`, not 0.
- `endingHere = x > endingHere + x ? x : endingHere + x;` is the recurrence (start fresh or extend).
- `if (endingHere > best) best = endingHere;` tracks the answer.

## Step 5: Dry run (first part of the example)

| x | endingHere | best |
|---|---|---|
| 3 | 3 | 3 |
| 5 | 8 | 8 |
| -9 | -1 | 8 |
| 1 | 1 (fresh start beats 0) | 8 |
| 3 | 4 | 8 |
| -2 | 2 | 8 |
| 3 | 5 | 8 |
| 4 | 9 | 9 |
| 7 | 16 | 16 |
| 2 | 18 | 18 |
| -9 | 9 | 18 |
| 6 | 15 | 18 |
| 3 | 18 | 18 |
| 1 | 19 | **19** |
| -5 | 14 | 19 |
| 4 | 18 | 19 |

## Complexity

- **Time: O(n)**.
- **Space: O(1)**.

## Common mistakes

- Initializing `best = 0`: an all-negative array would return 0 (the empty subarray), but the problem requires a non-empty subarray. The answer for `[-1, -2, -3]` is -1.
- Resetting to 0 instead of to `a[i]` when the running sum goes negative (same all-negative bug).

## Follow-ups

1. **Return the subarray's indices:** remember where the current stretch started; update the saved start/end whenever `best` improves.
2. **Maximum Sum Circular Subarray (LeetCode #918):** answer is `max(kadane, total - minSubarray)`, except when all numbers are negative (then just kadane).
3. **Maximum Product Subarray (#152):** track both the max and the min product ending here, because multiplying by a negative swaps them.
4. **2D version (max-sum rectangle):** fix a pair of rows, collapse the columns between them into one array of sums, run Kadane: O(rows^2 * cols).
5. **Best Time to Buy and Sell Stock (#121):** Kadane on day-to-day price differences.

## What to remember

Define the DP state as "best answer that ends exactly here". Extend the previous best or start fresh, whichever is larger.
